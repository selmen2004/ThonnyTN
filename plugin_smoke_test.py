#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ThonnyTN plugin smoke test.

Why this file exists
--------------------
Thonny does not use entry points to find third-party plugins. It scans the
``thonnycontrib`` namespace package exactly like this (thonny/workbench.py,
``_load_plugins_from_path``, verified against thonny 5.0.0):

    for _, module_name, _ in sorted(pkgutil.iter_modules(path, prefix), ...):
        if module_name in OBSOLETE_PLUGINS: ...
        else:
            try:
                m = importlib.import_module(module_name)
                if hasattr(m, "load_plugin"): modules.append(m)
            except Exception:
                logger.exception("Failed loading plugin '" + module_name + "'")

    for m in sorted(modules, ...):
        getattr(m, "load_plugin")()

Two consequences that make this test necessary:

1. An import error in a plugin is swallowed and only written to
   ``frontend.log``. A release that ships a plugin broken by a Thonny API
   change would install "successfully" and silently lose the feature.
2. ``load_plugin()`` is called *outside* the try/except, so an error there is
   not silent: it aborts Thonny's start-up on every student machine.

So the test does three things, mirroring Thonny's own loader:

  stage 1  discovery  -- is every expected plugin found under the module name
                          Thonny will compute from ``thonnycontrib.__path__``?
  stage 2  import     -- does importing it raise? (prints the traceback Thonny
                          would have hidden in the log)
  stage 3  load       -- does ``load_plugin()`` run against a stubbed workbench?

Exit code is 0 only when every expected plugin passes all three stages, which
is the gate the release workflow needs.

Usage
-----
    python plugin_smoke_test.py                 # offline, uses installed dists
    python plugin_smoke_test.py --report-only   # never fails, just prints
    python plugin_smoke_test.py --expect a,b    # only these plugins required
    python plugin_smoke_test.py --import numpy,PyQt5   # plain libs too

Run it with the *same interpreter Thonny will run under* (the build python of
the distribution), not with a random system python.

``--expect`` exists for the installer: the student may legitimately uncheck a
component (themes, autosave, ...), and a gate that cries failure on a valid
choice is a gate that gets switched off. When it is given, only the listed
distributions are *required*; everything else still gets import + load checked
if it turns up. Without it, every entry of EXPECTED_PLUGINS is required, which
is what the release workflow wants.
"""

import argparse
import importlib
import pkgutil
import sys
import traceback
from unittest.mock import MagicMock


# Distribution name -> the module name Thonny will import.
# Keys are pip/PyPI names, values are the thonnycontrib submodules actually
# found in the shipped wheels (verified against the wheels of 2026-10-08).
# Keeping both makes a renamed module fail loudly instead of being quietly
# skipped -- an import error is only a line in frontend.log for Thonny.
# Note the irregular names the plugins really ship under: a hyphen
# ("thonny-autosave"), a leading digit ("202theme") and inconsistent
# underscores. They import fine via importlib, but only Thonny's own loader
# path proves it, which is why the list is spelled out rather than derived.
EXPECTED_PLUGINS = {
    # editor plugins (composants "editors" du installeur)
    "thonny-autosave": "thonnycontrib.thonny-autosave",
    "thonny-loaduiautocomplete": "thonnycontrib.pyqt_loadui_autocomplete",
    "thonny-tunisiaschools": "thonnycontrib.tunisiaschools",
    "thonny-friendly": "thonnycontrib.thonny_friendly",
    "thonnyTN-block-highlight": "thonnycontrib.block_highlight",
    # themes
    "thonny-onedark": "thonnycontrib.onedark",
    "thonny-202": "thonnycontrib.202theme",
    "thonny-dracula": "thonnycontrib.dracula",
}

# Bundled locally, not on PyPI (the wheel lives next to the .iss files).
OPTIONAL_PLUGINS = {
    "thonny-palestine-flag": "thonnycontrib.thonny_palestine_flag",
}


def _discover():
    """Return {module_name: ok} for everything Thonny's loader would see."""
    import thonnycontrib  # namespace package created by the plugin wheels

    found = {}
    for _, module_name, _ in pkgutil.iter_modules(thonnycontrib.__path__, "thonnycontrib."):
        found[module_name] = True
    return found


def _real_workbench_surface():
    """
    Attribute names a plugin may legitimately use on the workbench.

    Built from the installed Thonny itself: ``dir(Workbench)`` gives the methods
    and class attributes (inherited ones included), and the ``self.<name> =``
    assignments found in **every class of its MRO that has Python source** give
    the instance attributes such as ``tk`` and ``event_bindings`` -- dir() on a
    class cannot see those. Annotated assignments (``self.x: T = ...``) count
    too. So if a future Thonny renames or drops an API a plugin relies on, this
    surface shrinks and the test starts failing instead of quietly mocking the
    hole away.
    """
    import inspect
    import re

    from thonny.workbench import Workbench

    assignment = re.compile(r"self\.([A-Za-z_]\w*)\s*(?::[^=\n]+)?=")
    surface = set(dir(Workbench))
    for klass in Workbench.__mro__:
        try:
            source = inspect.getsource(klass)
        except (OSError, TypeError):  # built-in / C extension (tk.Tk), no source
            continue
        surface |= set(assignment.findall(source))
    return surface


class _StubWorkbench:
    """
    Workbench stand-in: records calls, and refuses attribute names that the
    installed Thonny does not actually expose.

    ``load_plugin()`` needs a workbench but not a Tk display; this keeps the
    test runnable in a headless CI job. Attribute chains below a valid name
    (``workbench.tk.call(...)``) stay mocked, so the guarantee is about the
    first level of Thonny's API -- which is where a version bump breaks.
    """

    def __init__(self, surface):
        self._surface = surface
        self._children = {}
        self.calls = []

    def __getattr__(self, name):
        # Only reached for names this stub does not hold itself, so the
        # bookkeeping attributes set in __init__ resolve normally.
        if name not in self._surface:
            raise AttributeError(
                "Workbench n'a pas d'attribut %r (API supprimee ou renomee ?)" % name
            )
        self.calls.append(name)
        if name not in self._children:
            self._children[name] = MagicMock(name="workbench.%s" % name)
        return self._children[name]

    def get_option(self, *args, **kwargs):
        self.calls.append("get_option")
        return ""

    def set_default(self, *args, **kwargs):
        self.calls.append("set_default")
        return None


def _stub_workbench():
    return _StubWorkbench(_real_workbench_surface())


def _verify_detector():
    """
    Prove this test can actually fail, so a green run means something.

    Two mutation checks: a workbench attribute Thonny does not have must raise
    (otherwise the stub is just a mock and renamed APIs slip through), and a
    plugin module that is not installed must be reported missing (otherwise
    discovery is vacuous). Returns a list of problems, empty when healthy.
    """
    problems = []

    stub = _stub_workbench()
    try:
        stub.certainement_pas_une_api_thonny
    except AttributeError:
        pass
    else:
        problems.append("le stub accepte des attributs inexistants: le test ne "
                        "peut pas detecter une API renommee")

    if "add_command" not in _real_workbench_surface():
        problems.append("surface du workbench vide ou megeneree: "
                        "dir(Workbench) et les affectations self.x de son MRO "
                        "n'ont rien donne d'exploitable")

    discovered = _discover()
    if "thonnycontrib.ce_module_n_existe_pas" in discovered:
        problems.append("la decouverte pretend voir un module absent")

    return problems


def _check_plain_imports(modules) -> list:
    """
    Verify plain libraries the installer was asked to install.

    A component like ``bac_sc`` ships no Thonny plugin at all -- just numpy and
    PyQt5 -- so plugin discovery cannot prove it installed. An import is the
    whole of what can be proved, and it is the same thing a student's ``import
    numpy`` will do; the failure mode being guarded against is pip silently
    installing nothing because a wheel was missing from the offline bundle.
    """
    problems = []
    for module in modules:
        try:
            importlib.import_module(module)
        except Exception as exc:
            print("  %-32s IMPORT ECHOUE" % module)
            traceback.print_exc()
            problems.append((module, "import leve %s: %s"
                             % (type(exc).__name__, exc)))
        else:
            print("  %-32s ok" % module)
    return problems


def run(report_only: bool = False, expect=None, plain_imports=()) -> int:
    print("python  : %s" % sys.version.replace("\n", " "))
    try:
        import thonny

        try:
            from importlib.metadata import version as _v

            thonny_version = _v("thonny")
        except Exception:
            thonny_version = getattr(thonny, "__version__", "?")
        print("thonny  : %s  (%s)" % (thonny_version, thonny.__file__))
    except Exception:
        print("thonny  : IMPORT FAILED")
        traceback.print_exc()
        return 1 if not report_only else 0

    try:
        discovered = _discover()
    except Exception:
        print("thonnycontrib namespace introuvable -- aucun plugin installe")
        traceback.print_exc()
        return 1 if not report_only else 0

    print("thonnycontrib modules visibles par Thonny : %d" % len(discovered))
    for name in sorted(discovered):
        print("    %s" % name)

    detector_problems = _verify_detector()
    if detector_problems:
        print()
        print("ECHEC -- le test lui-meme est panne, son resultat ne veut rien dire:")
        for problem in detector_problems:
            print("    %s" % problem)
        return 1 if not report_only else 0
    print("controle du detecteur : ok (le test sait echouer)")
    print()

    all_known = dict(EXPECTED_PLUGINS)
    all_known.update(OPTIONAL_PLUGINS)

    if expect is None:
        required = dict(EXPECTED_PLUGINS)
    else:
        # A name the test does not know would silently drop a plugin from the
        # gate -- exactly the drift -- so it is an error, not a warning.
        unknown = sorted(set(expect) - set(all_known))
        if unknown:
            print("ECHEC -- noms de distribution inconnus dans --expect : %s"
                  % ", ".join(unknown))
            print("           noms connus : %s" % ", ".join(sorted(all_known)))
            return 1 if not report_only else 0
        required = {d: all_known[d] for d in expect if d in all_known}

    optional = {d: m for d, m in all_known.items() if d not in required}

    failures = []
    checked = 0
    for dist, expected_module in required.items():
        checked += 1
        status = _check_one(dist, expected_module, discovered, required=True)
        if status:
            failures.append((dist, status))

    # Deselected by the student: still checked when present (a broken plugin that
    # happens to be installed is a broken Thonny), but allowed to be missing.
    for dist, expected_module in optional.items():
        checked += 1
        status = _check_one(dist, expected_module, discovered, required=False)
        if status:
            failures.append((dist, status))

    if plain_imports:
        print()
        print("bibliotheques hors plugin (composants non « editors ») :")
        failures.extend(_check_plain_imports(plain_imports))

    print()
    if failures:
        print("ECHEC -- %d probleme(s):" % len(failures))
        for dist, why in failures:
            print("    %-32s %s" % (dist, why))
    elif required:
        print("OK -- %d plugins installes, importes et charges (%d requis)"
              % (checked, len(required)))
    else:
        print("OK -- aucun plugin requis; rien d'incoherent a signaler")

    if failures and not report_only:
        return 1
    return 0


def _check_one(dist: str, expected_module: str, discovered: dict, required: bool):
    """Return None when the plugin is healthy, otherwise a short reason."""
    import thonny

    if expected_module not in discovered:
        if not required:
            print("  %-32s absent (facultatif, ignore)" % dist)
            return None
        print("  %-32s NON DETECTE par Thonny" % dist)
        return "module %s introuvable dans thonnycontrib" % expected_module

    # This is what Thonny does: replace the global, then import.
    previous = getattr(thonny, "_workbench", None)
    thonny._workbench = _stub_workbench()
    try:
        try:
            module = importlib.import_module(expected_module)
        except Exception:
            print("  %-32s ERREUR D'IMPORT" % dist)
            traceback.print_exc()
            return "import leve %s" % sys.exc_info()[0].__name__

        if not hasattr(module, "load_plugin"):
            print("  %-32s charge mais SANS load_plugin()" % dist)
            return "Thonny importerait le module sans jamais l'activer"

        try:
            module.load_plugin()
        except Exception:
            print("  %-32s load_plugin() LEVE UNE ERREUR" % dist)
            traceback.print_exc()
            return "load_plugin leve %s" % sys.exc_info()[0].__name__

        print("  %-32s ok" % dist)
        return None
    finally:
        thonny._workbench = previous


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument("--report-only", action="store_true",
                        help="afficher le rapport sans rendre un code de sortie non nul")
    parser.add_argument("--expect", metavar="DIST[,DIST...]", default=None,
                        help="limiter les plugins obligatoires a cette liste "
                             "(utilisé par l'installateur selon les composants cochés)")
    parser.add_argument("--import", dest="plain_imports", metavar="MOD[,MOD...]",
                        default="",
                        help="bibliothèques sans plugin à importer de force "
                             "(composant « bac_sc » : numpy, PyQt5)")
    args = parser.parse_args()
    expect = None
    if args.expect is not None:
        expect = [name.strip() for name in args.expect.split(",") if name.strip()]
    plain = [name for name in args.plain_imports.split(",") if name.strip()]
    return run(report_only=args.report_only, expect=expect, plain_imports=plain)


if __name__ == "__main__":
    sys.exit(main())
