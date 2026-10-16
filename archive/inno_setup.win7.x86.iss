; Give AppVer and SourceFolder from command line, eg:
; "C:\Program Files (x86)\Inno Setup 5\iscc" /dAppVer=1.13 /dSourceFolder=build inno_setup.iss 
#define AppVer "0.0.10"
#define InstallerPrefix "thonnyTN-3.7.6x86"
#define SourceFolder "build"
#define AppUserModelID "Thonny.Thonny"
#define ThonnyPyProgID "Thonny.py"
#define JupyterIpynbProgID "Jupyter.ipynb"
#define AppUserModelID2 "Thonny.Jupyter"


#define MyAppExeName "Jupyter-lab.exe"
#define MyAppAssocName "JupyterLab Notebook"
#define MyAppAssocExt ".ipynb"
#define MyAppAssocKey StringChange(MyAppAssocName, " ", "") + MyAppAssocExt


[Setup]
AppId=Thonny.tn
AppName=Thonny pour Lycées Tunisiens
AppVersion={#AppVer}
AppVerName=ThonnyTN {#AppVer} - 3.7.6x86 Selmen Edit
;AppComments string is displayed on the "Support" dialog of the Add/Remove Programs Control Panel applet
AppComments=Thonny est un editeur python pour débutants , ceci est une version adapté aux lycées tunisiens.
AppPublisher=Selmen Arous
AppPublisherURL=https://thonny.org
AppSupportURL=https://thonny.org
AppUpdatesURL=https://thonny.org


; Actual privileges depend on how user started the installer
PrivilegesRequired=admin
;PrivilegesRequiredOverridesAllowed=commandline dialog
ChangesAssociations=yes
;Python 3.7.6 needs windows 7 at least
MinVersion=6.1

; to install esp32 drivers
;ArchitecturesInstallIn64BitMode=x64 


; Will show important info on welcome page
DisableWelcomePage=no

DisableProgramGroupPage=auto
DefaultGroupName=ThonnyTN

; Note that DefaultDirName can be overridden with installer's /DIR=... parameter
DefaultDirName={autopf}\ThonnyTN
DisableDirPage=auto
DirExistsWarning=auto
UsePreviousAppDir=yes

DisableReadyPage=no
AlwaysShowDirOnReadyPage=yes
Encryption=yes
Password=python

; Request extra space for precompiling libraries
ExtraDiskSpaceRequired=25000000
OutputDir=dist
OutputBaseFilename={#InstallerPrefix}-{#AppVer}
;Compression=lzma2/ultra
SolidCompression=yes

LicenseFile=license-for-win-installer.txt
WizardImageFile=screenshot_with_logo_semidark.bmp
WizardSmallImageFile=small_logo.bmp 


; Signing
; Certum Unizeto provides free certs for open source
; http://www.certum.eu/certum/cert,offer_en_open_source_cs.xml
; http://pete.akeo.ie/2011/11/free-code-signing-certificate-for-open.html
; http://blog.ksoftware.net/2011/07/exporting-your-code-signing-certificate-to-a-pfx-file-from-firefox/
; http://certhelp.ksoftware.net/support/solutions/articles/17157-how-do-i-export-my-code-signing-certificate-from-internet-explorer-or-chrome-
; http://blog.ksoftware.net/2011/07/how-to-automate-code-signing-with-innosetup-and-ksign/
; https://www.digicert.com/code-signing/signcode-signtool-command-line.htm
; http://www.jrsoftware.org/ishelp/index.php?topic=setup_signtool
;
; signtool prefix to be configured in Tools => Configure sign tools:
; $qC:\Program Files (x86)\kSign\signtool.exe$q sign /f $qcertfile.p12$q /p password $p
//SignTool=signtool /tr http://timestamp.digicert.com /td sha256 /fd sha256 /d $qInstaller for Thonny {#AppVer}$q /du $qhttps://thonny.org$q $f


[Languages]
Name: "Francais"; MessagesFile: "compiler:Languages\French.isl"

[InstallDelete]
; Clean old installation before copying new files
; (list specific subdirectories to avoid disaster when user selects a wrong directory for installation)
Type: filesandordirs; Name: "{app}\DLLs"
Type: filesandordirs; Name: "{app}\Doc"
Type: filesandordirs; Name: "{app}\include"
Type: filesandordirs; Name: "{app}\Lib"
Type: filesandordirs; Name: "{app}\libs"
Type: filesandordirs; Name: "{app}\Scripts"
Type: filesandordirs; Name: "{app}\tcl"
Type: filesandordirs; Name: "{app}\Tools"
Type: filesandordirs; Name: "{app}\python*"

[Tasks]
Name: CreateDesktopIcon; Description: "Créer icone pour Thonny";
Name: CreatePyQt5Icon; Description: "Créer icone pour Qt5 Designer";
Name: CreatePyQt6Icon; Description: "Créer icone pour Qt6 Designer";
Name: CreateJupyterIcon; Description: "Créer icone pour JupyterLab";
Name: InstallESP32Driver; Description: "Installer le pilote ESP32";

[Files]
Source: "{#SourceFolder}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "{#SourceFolder}\..\drivers\*" ; DestDir: "{app}\drivers"; Flags: ignoreversion recursesubdirs
Source: "{#SourceFolder}\..\esp32-20210902-v1.17.bin"; DestDir: "{app}\firmware"; Flags: ignoreversion
;Source: "{#SourceFolder}\thonny.exe"; DestDir: "{app}"; Flags: ignoreversion
;Source: "{#SourceFolder}\python.exe"; DestDir: "{app}"; Flags: ignoreversion
;Source: "{#SourceFolder}\jupyter_app_icon_161280.ico"; DestDir: "{app}"; Flags: ignoreversion
;Source: "{#SourceFolder}\Scripts\jupyter-lab.exe"; DestDir: "{app}\Scripts"; Flags: ignoreversion



[Icons]
Name: "{group}\Thonny"; Filename: "{app}\thonny.exe"; IconFilename: "{app}\thonny.exe"

Name: "{autodesktop}\Thonny"; Filename: "{app}\thonny.exe"; IconFilename: "{app}\thonny.exe"; Tasks: CreateDesktopIcon

Name: "{autodesktop}\JupyterLab"; Filename: "{app}\python.exe ";Parameters: "-m jupyter lab"; IconFilename: "{app}\jupyter_app_icon_161280.ico"; Tasks: CreateJupyterIcon
Name: "{autodesktop}\Designer Qt5"; Filename: "{app}\Lib\site-packages\qt5_applications\Qt\bin\designer.exe"; IconFilename: "{app}\Lib\site-packages\qt5_applications\Qt\bin\designer.exe"; Tasks: CreatePyQt5Icon
;Name: "{autodesktop}\Designer Qt6"; Filename: "{app}\Lib\site-packages\qt6_applications\Qt\bin\designer.exe"; IconFilename: "{app}\Lib\site-packages\qt6_applications\Qt\bin\designer.exe"; Tasks: CreatePyQt6Icon


[Registry]
; Register the application
; http://msdn.microsoft.com/en-us/library/windows/desktop/ee872121%28v=vs.85%29.aspx
; https://docs.microsoft.com/en-us/windows/desktop/shell/app-registration
; TODO: investigate also SupportedProtocols subkey of this key
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\thonny.exe"; ValueType: string; ValueName: "";                 ValueData: "{app}\thonny.exe"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\thonny.exe";                       ValueType: string; ValueName: "";                 ValueData: "Thonny";  Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\thonny.exe";                       ValueType: string; ValueName: "FriendlyAppName";  ValueData: "Thonny";  Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\thonny.exe";                       ValueType: string; ValueName: "AppUserModelID";   ValueData: "{#AppUserModelID}";  Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\thonny.exe\SupportedTypes";        ValueType: string; ValueName: ".py";              ValueData: "";        Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\thonny.exe\SupportedTypes";        ValueType: string; ValueName: ".pyw";             ValueData: "";        Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\thonny.exe\shell\open\command";    ValueType: string; ValueName: "";                 ValueData: """{app}\thonny.exe"" ""%1"""; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\thonny.exe\shell\Editer avec Thonny\command";   ValueType: string; ValueName: "";      ValueData: """{app}\thonny.exe"" ""%1"""; Flags: uninsdeletekey

; register jupyterlab
;Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\jupyter.exe"; ValueType: string; ValueName: "";                 ValueData: "{app}\Scripts\jupyter.exe"; Flags: uninsdeletekey
;Root: HKA; Subkey: "Software\Classes\Applications\jupyter.exe";                       ValueType: string; ValueName: "";                 ValueData: "JupyterLab";  Flags: uninsdeletekey
;Root: HKA; Subkey: "Software\Classes\Applications\jupyter.exe";                       ValueType: string; ValueName: "FriendlyAppName";  ValueData: "Jupyter Lab";  Flags: uninsdeletekey
;Root: HKA; Subkey: "Software\Classes\Applications\jupyter.exe";                       ValueType: string; ValueName: "AppUserModelID";   ValueData: "{#AppUserModelID2}";  Flags: uninsdeletekey
;Root: HKA; Subkey: "Software\Classes\Applications\jupyter.exe\SupportedTypes";        ValueType: string; ValueName: ".ipynb";              ValueData: "";        Flags: uninsdeletekey
;Root: HKA; Subkey: "Software\Classes\Applications\jupyter.exe\shell\open\command";    ValueType: string; ValueName: "";                 ValueData: """{app}\Scripts\jupyter.exe"" lab ""%1"""; Flags: uninsdeletekey
;Root: HKA; Subkey: "Software\Classes\Applications\jupyter.exe\shell\Ouvrir avec Jupyter Lab\command";   ValueType: string; ValueName: "";      ValueData: """{app}\Scripts\jupyter.exe"" lab ""%1"""; Flags: uninsdeletekey


Root: HKA; Subkey: "Software\Classes\{#MyAppAssocExt}\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppAssocKey}"; ValueData: ""; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\{#MyAppAssocExt}"; ValueType: string; ValueName: ""; ValueData: "Ipynb.File"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\{#MyAppAssocKey}"; ValueType: string; ValueName: ""; ValueData: "{#MyAppAssocName}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#MyAppAssocKey}\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\jupyter_app_icon_161280.ico"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#MyAppAssocKey}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Scripts\{#MyAppExeName}"" ""%1"""; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}\SupportedTypes"; ValueType: string; ValueName: "{#MyAppAssocExt}"; ValueData: ""; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Applications\{#MyAppExeName}"; ValueType: string; ValueName: "FriendlyAppName"; ValueData: "Jupyter Lab"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Ipynb.File";  ValueType: string;ValueName:""; ValueData: "Notebook Jupyter";Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Ipynb.File\shell";  ValueType: string;ValueName:""; ValueData: "";Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Ipynb.File\shell\open";  ValueType: string;ValueName:""; ValueData: "";Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Ipynb.File\shell\open\command";  ValueType: string;ValueName:""; ValueData: "";Flags: uninsdeletekey  


; Add link to Thonny under existing Python.File ProgID
Root: HKA; Subkey: "Software\Classes\Python.File\shell\Editer avec Thonny"; ValueType: none; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Python.File\shell\Editer avec Thonny\command"; ValueType: string; ValueName: ""; ValueData: """{app}\thonny.exe"" ""%1""";  Flags: uninsdeletekey

; Create separate ProgID (Thonny.py) which represents Thonny's ability to handle Python files
; These settings will be used when user chooses Thonny as default program for opening *.py files
Root: HKA; Subkey: "Software\Classes\{#ThonnyPyProgID}"; ValueType: string; ValueName: "";                 ValueData: "Python file";  Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#ThonnyPyProgID}"; ValueType: string; ValueName: "FriendlyTypeName"; ValueData: "Python file";  Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#ThonnyPyProgID}"; ValueType: string; ValueName: "AppUserModelID"; ValueData: "{#AppUserModelID}";  Flags: uninsdeletekey

; Create separate ProgID (Jupyter.ipynb) which represents Thonny's ability to handle jupyter files
; These settings will be used when user chooses Thonny as default program for opening jupyter files
Root: HKA; Subkey: "Software\Classes\{#JupyterIpynbProgID}"; ValueType: string; ValueName: "";                 ValueData: "Jupyter Lab file";  Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#JupyterIpynbProgID}"; ValueType: string; ValueName: "FriendlyTypeName"; ValueData: "Jupyter Lab file";  Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#JupyterIpynbProgID}"; ValueType: string; ValueName: "AppUserModelID"; ValueData: "{#AppUserModelID}";  Flags: uninsdeletekey

  
;Root: HKA; Subkey: "Software\Classes\{#ThonnyPyProgID}"; ValueType: string; ValueName: "EditFlags"; TODO: https://docs.microsoft.com/en-us/windows/desktop/api/Shlwapi/ne-shlwapi-filetypeattributeflags

Root: HKA; Subkey: "Software\Classes\{#ThonnyPyProgID}\shell\open\command";     ValueType: string; ValueName: ""; ValueData: """{app}\thonny.exe"" ""%1""";  Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#JupyterIpynbProgID}\shell\open\command";     ValueType: string; ValueName: ""; ValueData: """{app}\python.exe  -m jupyter lab %1""";  Flags: uninsdeletekey

; Relate this ProgID with *.py and *.pyw extensions
; https://docs.microsoft.com/en-us/windows/desktop/shell/how-to-include-an-application-on-the-open-with-dialog-box
Root: HKA; Subkey: "Software\Classes\.py\OpenWithProgIds";  ValueType: string; ValueName: "{#ThonnyPyProgID}";   Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\.pyw\OpenWithProgIds"; ValueType: string; ValueName: "{#ThonnyPyProgID}";   Flags: uninsdeletevalue

; Relate this ProgID with *.py and *.pyw extensions
; https://docs.microsoft.com/en-us/windows/desktop/shell/how-to-include-an-application-on-the-open-with-dialog-box
Root: HKA; Subkey: "Software\Classes\.ipynb\OpenWithProgIds";  ValueType: string; ValueName: "{#JupyterIpynbProgID}";   Flags: uninsdeletevalue

; Add "Python file" to Explorer's "New" context menu (don't remove on uninstallation)
Root: HKA; Subkey: "Software\Classes\.py\ShellNew";  ValueType: string; ValueData: "Python.File";  
Root: HKA; Subkey: "Software\Classes\.py\ShellNew";  ValueType: string; ValueName: "NullFile"; ValueData: "";  

; Add "Python file" to Explorer's "New" context menu (don't remove on uninstallation)
Root: HKA; Subkey: "Software\Classes\.ipynb\ShellNew";  ValueType: string; ValueData: "Ipynb.File";  
Root: HKA; Subkey: "Software\Classes\.ipynb\ShellNew";  ValueType: string; ValueName: "NullFile"; ValueData: "";  

[Run]
;Filename: "{app}\pythonw.exe"; Parameters: "-m compileall ."; StatusMsg: "Compilation de bibliothèque standard... (prend du temps)"
;Filename: "{cmd}"; Parameters: "/k echo """"{app}\python.exe"" ""{app}\patch.py"" ""{app}\Scripts\"" G:\dev\python\thonny\thonny\packaging\windows\py376x86\ ""{app}"" >patch3.txt"; StatusMsg: "Patch des executables en cours  ... 1/2"

Filename: "{app}\pythonw.exe"; Parameters: """{app}\patch.py"" ""{app}\Scripts"" G:\dev\python\thonny\thonny\packaging\windows\py376x86 ""{app}"""; StatusMsg: "Patch des executables en cours  ... 1/2"
Filename: "{app}\pythonw.exe"; Parameters: """{app}\patch.py"" ""{app}\Scripts"" G:\dev\python\thonny\thonny\packaging\windows\build ""{app}"""; StatusMsg: "Patch des executables en cours  ... 2/2"

Filename: "{app}\drivers\dpinst32.exe"; Parameters: "/S"; WorkingDir: {app}\drivers; StatusMsg: "Installation de pilote ESP32 ..."; Tasks:InstallESP32Driver


[UninstallDelete]
Type: filesandordirs; Name: "{app}\*"
Type: filesandordirs; Name: "{app}"

[Messages]
FinishedHeadingLabel=C'est fini!



[Code]

var
  QuoteLabel: TLabel;
  Upgraded : Boolean;
  ESP32Page : TOutputProgressWizardPage;

function StartedForAllUsers(): Boolean;
begin
    Result := IsAdminInstallMode();
end;

function StartedForThisUser(): Boolean;
begin
    Result := not IsAdminInstallMode();
end;

function InstalledForAllUsers(): Boolean;
begin
    Result := RegKeyExists(HKEY_LOCAL_MACHINE, 'Software\Classes\Applications\thonny.exe');
end;

function InstalledForThisUser(): Boolean;
begin
    Result := RegKeyExists(HKEY_CURRENT_USER, 'Software\Classes\Applications\thonny.exe');
end;


function GetRandomQuote(): String;
var
    Quotes: array[0..9] of string;
begin
    Quotes[0] := 'Ninety-ninety rule: The first 90 percent of the code accounts for the first 90 percent of the development time. The remaining 10 percent of the code accounts for the other 90 percent of the development time.'#13#10'– Tom Cargill ';
    Quotes[1] := 'Now is better than never.'#13#10'– Tim Peters ';
    Quotes[2] := 'Give someone a program, frustrate them for a day; teach them how to program, frustrate them for a lifetime.'#13#10#13#10'– David Leinweber ';
    Quotes[3] := 'Talk is cheap. Show me the code.'#13#10#13#10'– Linus Torvalds ';
    Quotes[4] := 'Every great developer you know got there by solving problems they were unqualified to solve until they actually did it.'#13#10#13#10'– Patrick McKenzie ';
    Quotes[5] := 'Formal education will make you a living. Self-education will make you a fortune.'#13#10#13#10'– Jim Rohn ';
    Quotes[6] := 'First do it, then do it right, then do it better.'#13#10#13#10'– Addy Osmani ';
    Quotes[7] := 'If you want to set off and go develop some grand new thing, you don''t need millions of dollars of capitalization. You need enough pizza and Diet Coke to stick in your refrigerator, a cheap PC to work on and the dedication to go through with it.'#13#10'– John Carmack ';
    Quotes[8] := 'Computers are useless. They can only give you answers.'#13#10#13#10'– Pablo Picasso ';
    Quotes[9] := 'The best way to predict the future is to invent it.'#13#10#13#10'– Alan Kay ';

    Result := Quotes[StrToInt(GetDateTimeString('ss', #0, #0)) mod Length(Quotes)];
end;

procedure InitializeWizard;
var
  DualWarningLabel: TLabel;
begin
  WizardForm.LicenseMemo.Font.Name:='Consolas'
  WizardForm.PasswordEdit.Text := 'python'
  Upgraded := False;
  WizardForm.WelcomeLabel1.Caption := 'Bienvenue dans Thonny pour lycées tunisiens!';

  DualWarningLabel := TLabel.Create(WizardForm);

  if StartedForAllUsers() then
  begin
    WizardForm.WelcomeLabel2.Caption := 'Cette assistant va installer {#AppVer} pour tous les utilisateurs.';
    if InstalledForThisUser() then
    begin    
      DualWarningLabel.Caption := 'Warning!'
          + ''#13#10''
          + ''#13#10''
          + 'Looks like you have already installed Thonny for your account. In order to avoid confusion, you may want to cancel this wizard and uninstall single-user Thonny first.';
    end
    else if InstalledForAllUsers() then
    begin
      WizardForm.WelcomeLabel2.Caption := 'Cette assistant va mettre à jour {#AppVer} pour tous les utilisateurs.';
      Upgraded := True;
    end;
  end
  else  // single user
  begin
    WizardForm.WelcomeLabel2.Caption := 'Cette assistant va installer {#AppVer} pour votre compte';
    if InstalledForAllUsers() then
    begin    
      DualWarningLabel.Caption := 'Warning!'
        + ''#13#10''
        + ''#13#10''
        + 'Looks like Thonny is already installed for all users. In order to avoid confusion, you may want to cancel this wizard and uninstall all-users Thonny first.';
    end
    else if InstalledForThisUser() then
    begin
      WizardForm.WelcomeLabel2.Caption := 'Cette assistant va mettre à jour  {#AppVer} pour votre compte.';
      Upgraded := True;
    end;

  end;


  WizardForm.WelcomeLabel2.AutoSize := True;

  DualWarningLabel.Parent := WizardForm.WelcomePage;
  DualWarningLabel.AutoSize := True;
  DualWarningLabel.WordWrap := True;
  DualWarningLabel.Left := WizardForm.WelcomeLabel2.Left;
  DualWarningLabel.Width := WizardForm.WelcomeLabel2.Width;
  DualWarningLabel.Font.Style := [fsBold];
  //DualWarningLabel.Color := clRed;
  DualWarningLabel.Top := WizardForm.WelcomePage.Height - DualWarningLabel.Height - ScaleY(20);
  
  // Quotes
  QuoteLabel := TLabel.Create(WizardForm);
  QuoteLabel.Caption := GetRandomQuote();

  QuoteLabel.Parent := WizardForm.FinishedPage;

  // make accepting license the default
  WizardForm.LicenseAcceptedRadio.Checked := True;

end;

function NextButtonClick(CurPageID: Integer): Boolean;
var rpt: Boolean;
TmpFileName,Command: string;
ExecStdout :AnsiString;
ResultCode : Integer;
I, Max: Integer;
  
begin
  if (CurPageID = wpSelectDir) and (pos('&', WizardDirValue) > 1) then
  begin
    MsgBox('Directory paths containing "&" are known to cause problems in Thonny'
          + ''#13#10''
          + 'Please choose another directory!', mbError, MB_OK);
    Result := False
  end
  else
  if CurPageID = wpFinished then 
  begin
        ESP32Page := CreateOutputProgressPage('Firmware Micropython ESP32', 'Vous pouvez installer le firmware pour programmer la carte en utilisant le language Python');
        
          
        ESP32Page.Show;

        TmpFileName := ExpandConstant('{tmp}') + '\~flash_results.txt';
        
        repeat
          rpt:=MsgBox('Voulez vous installer le firmware Micropython(v1.17) sur votre carte ESP32 ?'+#13#10+'NB:Brancher la carte puis appuiez sur le bouton EN 2 secondes puis clickez sur Oui ' , mbConfirmation, MB_YESNO) = idYes;
          
          
           
          if rpt  then
          begin
              ESP32Page.SetText(' Formatage de mémoire ... (environ 13 secondes)' ,'Veuillez patienter') ;
              ESP32Page.SetProgress(1,103);
              Command :=Format('"%s" /S /C ""%s" %s > "%s""', [ExpandConstant('{cmd}'),ExpandConstant('{app}')+'/'+ 'python.exe', '-m esptool erase_flash', TmpFilename]);
              if(Exec(ExpandConstant('{cmd}'), Command, '', SW_HIDE, ewWaitUntilTerminated , ResultCode) and LoadStringFromFile(TmpFileName, ExecStdout) )   then
              begin

                  //MsgBox(ExecStdout, mbInformation, MB_OK);
                  //Successfull erase
                  if (pos('Chip erase completed successfully ',String(ExecStdout)  )<> 0)   then 
                  begin
                     ESP32Page.SetText('Formatage Terminé. Flashage en cours... (environ 90 secondes)' ,'Veuillez patienter') ;
                     ESP32Page.SetProgress(14,103);
                     Command :=Format('"%s" /S /C ""%s" %s > "%s""', [ExpandConstant('{cmd}'), ExpandConstant('{app}')+'/'+ 'python.exe', '-m esptool write_flash --flash_mode keep --flash_size detect 0x1000 '+ ExpandConstant('{app}')+'/firmware/esp32-20210902-v1.17.bin', TmpFilename]);
                     if ( Exec(ExpandConstant('{cmd}'), Command, '', SW_HIDE, ewWaitUntilTerminated , ResultCode) and LoadStringFromFile(TmpFileName, ExecStdout))   then
                     begin
                          if (pos('Hash of data verified.',String(ExecStdout)  )<> 0)   then 
                          begin
                              ESP32Page.SetText('Le firmware est bien installé' ,'Vous avez une autre carte ?') ;
                              ESP32Page.SetProgress(103,103);
                          end
                          else 
                              ESP32Page.SetText('Erreur' ,'Problème de flashage.ٍVeuillez rééssayer .' ) ;
                              
                     end;   
                        
                  end
                  else
                       ESP32Page.SetText('Erreur de formatage , appuiez sur le bouton EN sur la carte pour passer en mode BOOT' ,'Veuillez réessayez') ;

                  
                  DeleteFile(TmpFileName);
              end
              else MsgBox('Erreur ' +  SysErrorMessage(ResultCode) , mbInformation, MB_OK);  
                
            


          end;
        until rpt  = False;
       
      ESP32Page.Hide;
    

    end;
 
    Result := True
  
end;

procedure CurPageChanged(CurPageID: Integer);
var rpt: Boolean;
TmpFileName, ExecStdout: string;
ResultCode : Integer;
begin
    if CurPageID=wpPassword then        PostMessage(WizardForm.NextButton.Handle, $0111+$BC00, 0, 0);
    if CurPageID = wpFinished then
    begin
      if Upgraded then
        WizardForm.FinishedLabel.Caption := 'Thonny est mis à jour.'
      else
        WizardForm.FinishedLabel.Caption := 'Thonny est installé.'
      end;
      WizardForm.FinishedLabel.Caption := WizardForm.FinishedLabel.Caption 
        + ' Run it via shortcut or right-click a *.py file and select "Edit with Thonny".';

      WizardForm.FinishedLabel.AutoSize := True;

      QuoteLabel.WordWrap := True;
      QuoteLabel.Width := round(WizardForm.FinishedLabel.Width * 0.8);
      QuoteLabel.AutoSize := True;
      
      // for some reason AutoSize doesn't work for longer quotes -- they are cropped from the bottom
      QuoteLabel.Height := ScaleY(60);
      if Length(QuoteLabel.Caption) > 100 then
      begin
        QuoteLabel.Height := ScaleY(80);
      end;
      QuoteLabel.Left := WizardForm.FinishedLabel.Left + (WizardForm.FinishedLabel.Width - QuoteLabel.Width);
      QuoteLabel.Alignment := taRightJustify;
      //QuoteLabel.Font.Style := [fsItalic]; // causes cropping in leftmost letters
      
      QuoteLabel.Top := WizardForm.FinishedPage.Height - QuoteLabel.Height - ScaleY(20);
    end;

     
           

end.