(* ---------------------------------------------------------------------------
  VERIFIER SOI-MEME L'INSTALLATION  (item 9 du plan d'upgrade)

  Pourquoi ce fichier existe
  --------------------------
  Chaque ligne [Run] de l'installateur lance un « pip install --no-index » et
  redirige sa sortie vers {tmp}\innosetup.log — un fichier que Setup detruit en
  se terminant. Un paquet qui n'a pas pu s'installer ne laisse donc aucun signe
  visible : Thonny demarre quand meme, et le plugin absent ne figure que dans
  frontend.log. L'enseignant en conclut « l'installateur est casse », et personne
  ne sait quel paquet manque.

  Ce module rejoue le chargeur de plugins de Thonny (plugin_smoke_test.py) juste
  apres la derniere ligne [Run] et ecrit le resultat — reussi ou non — a un
  endroit durable.

  Mesure locale du 2026-10-15, Inno Setup 6.7.3 installe, installateurs de test
  construits et executes pour l'occasion. Trois points contredisent l'intuition ;
  ne les revise pas sans refaire le test :

   1. ssPostInstall part apres TOUTES les lignes [Run] : c'est la premiere etape
      ou le Python et les paquets sont reellement en place.
   2. La, Inno a deja ecrit « Installation process succeeded » et deja cree la cle
      de desinstallation. « Abort » ne change rien : code de sortie 0, mesure.
      RaiseException affiche une boite modale MEME sous /VERYSILENT et ne finit
      jamais (processus tue au bout de 25 s). Il n'existe ni RaiseInstallException
      ni variable de code de sortie en [Code].
      => on ne peut ni annuler ni revenir en arriere ; on peut seulement rendre
         l'echec impossible a manquer.
   3. MsgBox n'est PAS supprime par /SUPPRESSMSGBOXES (doc Inno : « message boxes
      are not suppressible ») : il bloquerait un deploiement GPO/SCCM.
      SuppressibleMsgBox, lui, renvoie sa valeur par defaut sans rien afficher.

  Limite assumee : en tres silencieux, l'echec ne change toujours pas le code de
  sortie de Setup. Les preuves exploitables sont le rapport, le journal /LOG et la
  valeur InstallCheck de la cle de registre. Le vrai filet reste le portillon
  « Smoke test des plugins » du workflow CI, qui ne doit jamais laisser partir un
  installateur casse.

  Pièges de syntaxe rencontres (pour les eviter a l'avenir) :
   - un commentaire { ... } se termine au premier « } » : ecrire les commentaires
     de ce fichier en ( * ... * ) ou en //, sinon « {tmp} » dans un commentaire
     casse la compilation ;
   - une ligne qui commence par « # » est une directive ISPP : ne jamais commencer
     une continuation par #13#10, d'ou la constante CRLF ;
   - ce fichier est en UTF-8 avec BOM, comme le .iss : les accents francais sont
     visibles dans les dialogues.
  --------------------------------------------------------------------------- *)

const
  VerificationRegKey = 'Software\ThonnyTN';
  VerificationScript = 'plugin_smoke_test.py';
  VerificationFolder = 'ThonnyTN';
  CRLF = #13#10;

function VerificationReportDir: String;
begin
  // CreateAppDir=no : il n'y a pas de {app}. Le rapport est écrit à côté du
  // Python installé. En mode administrateur élevé, {localappdata} est celui du
  // compte élevé — le même que celui de l'enseignant dans le cas courant d'un
  // lycée (une session, un compte), et de toute façon le chemin complet est
  // rappelé dans le dialogue d'erreur et dans le journal.
  Result := ExpandConstant('{localappdata}\') + VerificationFolder + '\';
end;

function InterpreterFromPep514(Root: Integer; const RootName: String): String;
var
  InstallPath, Candidate: String;
begin
  Result := '';
  // La clé PEP 514 est « Software\Python\PythonCore\<serie>\InstallPath » ;
  // {#major}.{#minor} est substitué à la compilation, pas à l'exécution.
  InstallPath := '';
  if not RegQueryStringValue(Root,
       'Software\Python\PythonCore\{#major}.{#minor}\InstallPath', '',
       InstallPath) then
    exit;
  Candidate := RemoveBackslashUnlessRoot(InstallPath) + '\python.exe';
  Log('[vérification] candidat PEP 514 ' + RootName + ' : ' + Candidate);
  if FileExists(Candidate) then
    Result := Candidate;
end;

function FindInstalledInterpreter(out Exe: String; out Params: String): String;
var
  Candidate: String;
begin
  Result := '';
  Exe := '';
  Params := '';

  // 1. L'interpréteur visé par les raccourcis Start et bureau : c'est exactement
  //    celui dont on doit prouver qu'il sait lancer Thonny. Le [Icons] du .iss
  //    construit le même chemin.
  Candidate := ExpandConstant(
    '{localappdata}\Programs\Python\Python{#PythonStrictVersion}\python.exe');
  Log('[vérification] candidat 1 (Python livré par l''installateur) : ' + Candidate);
  if FileExists(Candidate) then
  begin
    Exe := Candidate;
    Result := 'répertoire d''installation par défaut';
    exit;
  end;

  // 2. PEP 514 : couvre « décocher python_installer et utiliser mon Python déjà
  //    présent », ainsi qu'un Setup élevé qui installerait le Python livré dans
  //    un autre profil que celui dont {localappdata} tient compte ici.
  Candidate := InterpreterFromPep514(HKCU, 'HKCU');
  if Candidate = '' then
    Candidate := InterpreterFromPep514(HKLM64, 'HKLM64');
  if Candidate = '' then
    Candidate := InterpreterFromPep514(HKLM32, 'HKLM32');
  if Candidate <> '' then
  begin
    Exe := Candidate;
    Result := 'registre PEP 514';
    exit;
  end;

  // 3. Dernier recours : le lanceur « py » employé par les lignes [Run].
  Candidate := ExpandConstant('{win}\py.exe');
  Log('[vérification] candidat 3 (lanceur py) : ' + Candidate);
  if FileExists(Candidate) then
  begin
    Exe := Candidate;
    Params := '-3';
    Result := 'lanceur py.exe';
  end;
end;

function ComponentPlugins: String;
var
  List: String;
begin
  // Le nom des composants vient de la section [Components] du .iss ; les noms de
  // distributions viennent des lignes [Run]. Cette liste est le seul endroit où
  // les deux se recroisent : si un composant change de paquet, le test le
  // réclame sous un nom que le test ne connaît pas, et le test échoue au lieu
  // de vérifier silencieusement autre chose.
  //
  // Sans cette liste, l'enseignant qui décoche « Thèmes » aurait un échec de
  // vérification alors que son installation est correcte -- et la première
  // chose qu'on fait d'un contrôle qui crie faux, c'est l'enlever.
  List := '';
  if WizardIsComponentSelected('editors\thonny_autosave') then
    List := List + ',thonny-autosave';
  if WizardIsComponentSelected('editors\thonny_loaduiautocomplete') then
    List := List + ',thonny-loaduiautocomplete';
  if WizardIsComponentSelected('editors\thonny_tunisiaschools') then
    List := List + ',thonny-tunisiaschools';
  if WizardIsComponentSelected('editors\friendly') then
    List := List + ',thonny-friendly';
  if WizardIsComponentSelected('editors\highlight') then
    List := List + ',thonnyTN-block-highlight';
  if WizardIsComponentSelected('editors\themes') then
    List := List + ',thonny-onedark,thonny-202,thonny-dracula';
  if WizardIsComponentSelected('editors\ps_flag_thonny') then
    List := List + ',thonny-palestine-flag';
  Result := Copy(List, 2, Length(List));
end;

function ComponentLibraries: String;
begin
  // Le composant du bac n'embarque aucun plugin Thonny : la découverte de
  // thonnycontrib ne peut donc rien prouver sur lui. Un import est tout ce qu'on
  // peut exiger, et c'est exactement ce que fera l'élève.
  if WizardIsComponentSelected('bac_sc') then
    Result := 'numpy,PyQt5'
  else
    Result := '';
end;

procedure KeepPipLog;
var
  PipLog: String;
begin
  // Le journal des « pip install » meurt avec {tmp} : sans cette copie, un échec
  // n'aurait plus aucune cause documentée.
  PipLog := ExpandConstant('{tmp}\innosetup.log');
  if FileExists(PipLog) then
    if FileCopy(PipLog, VerificationReportDir + 'pip-install.log', False) then
      Log('[vérification] journal pip copié à côté du rapport')
    else
      Log('[vérification] journal pip non copié');
end;

procedure WriteVerificationReport(const Report: String; Lines: TArrayOfString);
begin
  if not ForceDirectories(ExtractFilePath(Report)) then
    Log('[vérification] IMPOSSIBLE de créer ' + ExtractFilePath(Report));
  if SaveStringsToUTF8File(Report, Lines, False) then
    Log('[vérification] rapport écrit : ' + Report)
  else
    Log('[vérification] IMPOSSIBLE d''écrire le rapport ' + Report);
  KeepPipLog;
end;

procedure FailVerification(const Reason: String; Lines: TArrayOfString);
var
  Report: String;
  Count: Integer;
begin
  Report := VerificationReportDir + 'install-check.log';
  Count := GetArrayLength(Lines);
  SetArrayLength(Lines, Count + 1);
  Lines[Count] := '-- RAISON -- ' + Reason;
  WriteVerificationReport(Report, Lines);

  // Marqueur lisible par un script de déploiement. Best effort : le rucher HKCU
  // est celui du compte qui lance Setup.
  if not RegWriteStringValue(HKCU, VerificationRegKey, 'InstallCheck',
       'échec : ' + Reason) then
    Log('[vérification] valeur de registre InstallCheck non écrite');

  Log('[vérification] ÉCHEC : ' + Reason);
  // Le texte reste utile quand la boite est supprimée : le chemin du rapport est
  // aussi écrit dans le journal /LOG.
  SuppressibleMsgBox(
    'Vérification de l''installation : ÉCHEC.' + CRLF + CRLF + Reason + CRLF + CRLF +
    'ThonnyTN est installé, mais son contenu n''a pas pu être vérifié : un éditeur ' +
    'ou un plugin peut manquer sans que vous le voyiez.' + CRLF +
    'Rapport détaillé : ' + Report + CRLF + CRLF +
    'Réinstallez, ou signalez ce rapport à votre référent informatique, avant de ' +
    'distribuer cette machine.',
    mbCriticalError, MB_OK, IDOK);
end;

procedure VerifyInstallation;
var
  Script, Report, Exe, Params, Reason, UsedBy: String;
  RC, Count, ErrCount, I: Integer;
  Ran: Boolean;
  Outp: TExecOutput;
  Lines: TArrayOfString;
begin
  if not WizardIsComponentSelected('editors') then
  begin
    Log('[vérification] composant « editors » décoché : rien à vérifier.');
    exit;
  end;

  Report := VerificationReportDir + 'install-check.log';
  Script := ExpandConstant('{tmp}\') + VerificationScript;
  SetArrayLength(Lines, 0);

  // Repartir propre : un rapport de la version précédente ferait croire à une
  // vérification réussie.
  DeleteFile(Report);

  if not FileExists(Script) then
  begin
    // Un installateur sans son harnais de test doit le dire, pas réussir en
    // silence.
    SetArrayLength(Lines, 1);
    Lines[0] := 'Le script de vérification (' + VerificationScript +
      ') est absent de l''installateur.';
    FailVerification(Lines[0], Lines);
    exit;
  end;

  UsedBy := FindInstalledInterpreter(Exe, Params);
  if Exe = '' then
  begin
    SetArrayLength(Lines, 1);
    Lines[0] := 'Aucun interpréteur Python trouvé : impossible de vérifier que ' +
      'Thonny et ses plugins sont installés.';
    FailVerification(Lines[0], Lines);
    exit;
  end;

  Log('[vérification] interpréteur retenu (' + UsedBy + ') : ' + Exe);
  // Le chemin du script AVANT les options : tout ce qui précède le fichier est
  // lu par l''interpréteur lui-même. Mesuré : « python --expect ... script.py »
  // renvoie « Unknown option: --expect » avec le code 2, ce qui ferait échouer
  // toute vérification pour une raison sans rapport avec les plugins.
  //
  // Pas de -X utf8 : Inno décode la sortie console avec la page de codes du
  // système ; forcer UTF-8 produirait des accents illisibles dans le rapport.
  //
  // Les deux listes viennent des composants cochés : le test ne réclame que ce
  // que l'installateur a réellement promis d'installer.
  Params := Params + ' "' + Script + '" --expect "';
  Params := Params + ComponentPlugins + '"';
  if ComponentLibraries <> '' then
    Params := Params + ' --import "' + ComponentLibraries + '"';

  Ran := False;
  try
    Ran := ExecAndCaptureOutput(Exe, Params, ExtractFilePath(Script),
      SW_SHOWNORMAL, ewWaitUntilTerminated, RC, Outp);
  except
    Ran := False;
    Reason := 'ExecAndCaptureOutput a levé une exception : ' + GetExceptionMessage;
    Log('[vérification] ' + Reason);
  end;

  if not Ran then
  begin
    if Reason = '' then
      Reason := 'Le test de vérification n''a pas pu être lancé (' + Exe + ').';
    SetArrayLength(Lines, 1);
    Lines[0] := Reason;
    FailVerification(Reason, Lines);
    exit;
  end;

  Count := GetArrayLength(Outp.StdOut);
  ErrCount := GetArrayLength(Outp.StdErr);
  SetArrayLength(Lines, Count + ErrCount + 1);
  for I := 0 to Count - 1 do
    Lines[I] := Outp.StdOut[I];
  for I := 0 to ErrCount - 1 do
    Lines[Count + I] := '[stderr] ' + Outp.StdErr[I];
  Lines[Count + ErrCount] := '-- code de sortie : ' + IntToStr(RC) +
    '   interpréteur : ' + Exe;

  if RC = 0 then
  begin
    WriteVerificationReport(Report, Lines);
    if not RegWriteStringValue(HKCU, VerificationRegKey, 'InstallCheck', 'ok') then
      Log('[vérification] valeur de registre InstallCheck non écrite');
    Log('[vérification] OK : Thonny et ses plugins se chargent.');
  end
  else
  begin
    WriteVerificationReport(Report, Lines);
    if not RegWriteStringValue(HKCU, VerificationRegKey, 'InstallCheck',
         'échec : code ' + IntToStr(RC)) then
      Log('[vérification] valeur de registre InstallCheck non écrite');
    Log('[vérification] ÉCHEC : code de sortie ' + IntToStr(RC));
    SuppressibleMsgBox(
      'Vérification de l''installation : ÉCHEC.' + CRLF + CRLF +
      'Le test des plugins Thonny a échoué (code de sortie ' + IntToStr(RC) + ').' +
      CRLF + 'Les lignes en cause sont dans le rapport.' + CRLF + CRLF +
      'Rapport détaillé : ' + Report + CRLF + CRLF +
      'ThonnyTN est installé, mais un éditeur ou un plugin peut manquer sans que ' +
      'vous le voyiez : signalez ce rapport à votre référent informatique.',
      mbCriticalError, MB_OK, IDOK);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // ssPostInstall est la seule étape où les lignes [Run] sont toutes terminées
  // (mesuré le 2026-10-15) : c'est donc là, et pas ailleurs, que le test des
  // plugins peut porter sur l'installation réelle.
  if CurStep = ssPostInstall then
    VerifyInstallation;
end;
