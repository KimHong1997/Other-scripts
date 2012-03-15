;
; LimeSurvey InnoSetup Script on XAMPP
; Copyright (C) 2007 The LimeSurvey Project Team / Shubham Sachdeva
; All rights reserved.
; License: GNU/GPL License v2 or later
; LimeSurvey is free software. This version may have been modified pursuant
; to the GNU General Public License, and as distributed it includes or
; is derivative of works licensed under the GNU General Public License or
; other free or open source software licenses.
; 

#define MyAppName "LimeSurvey on XAMPP"
#define MyAppExeName "xampp-control.exe"

[Setup]
AppName=LimeSurvey on XAMPP
AppVersion=1.92
AppVerName=LimeSurvey v1.92 on XAMPP
AppPublisher=LimeSurvey
AppPublisherURL=http://www.limesurvey.org
AppSupportURL=http://www.limesurvey.org
AppUpdatesURL=http://www.limesurvey.org
DefaultDirName=C:\xampp
DefaultGroupName=LimeSurvey on XAMPP
AllowNoIcons=yes
LicenseFile={#BASEPATH}\license.txt
InfoAfterFile={#BASEPATH}\info_file_after_installation.txt
OutputDir={#BASEPATH}\installer file
OutputBaseFilename=setup
;Following line is disabled because on older Wine versions it creates a problem
;SetupIconFile={#BASEPATH}\limesurvey_logo_ico.ico
WizardImageBackColor=clWhite
WizardSmallImageFile={#BASEPATH}\limesurvey_logo_bmp.bmp
WizardImageFile={#BASEPATH}\limesurvey_logo_vertical_bmp.bmp
Compression=lzma/ultra
SolidCompression=yes
InternalCompressLevel=ultra

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "basque"; MessagesFile: "compiler:Languages\Basque.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "catalan"; MessagesFile: "compiler:Languages\Catalan.isl"
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "finnish"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "hungarian"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "norwegian"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "serbiancyrillic"; MessagesFile: "compiler:Languages\SerbianCyrillic.isl"
Name: "serbianlatin"; MessagesFile: "compiler:Languages\SerbianLatin.isl"
Name: "slovak"; MessagesFile: "compiler:Languages\Slovak.isl"
Name: "slovenian"; MessagesFile: "compiler:Languages\Slovenian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BASEPATH}\xampp\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#LSSOURCEPATH}\*"; DestDir: "{app}\htdocs"; Excludes: ".git,.gitignore"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
Name: "{app}\htdocs\upload"; Flags: uninsneveruninstall
Name: "{app}\mysql\data"; Flags: uninsneveruninstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]

//----------------------------------------------
// Start Apache and MySql services
//----------------------------------------------  
procedure StartServices;
var
  ResultCode: Integer;
begin
  if not Exec(ExpandConstant('{app}\start_services.bat'), '', '', SW_SHOW,
              ewWaitUntilTerminated, ResultCode) then
  begin
    MsgBox('Unable to start Mysql and Apache!', mbInformation, MB_OK);
  end;
  DeleteFile(ExpandConstant('{app}\start_services.bat'));
end;


//----------------------------------------------
// Launch browser with LimeSurvey back-end url
//----------------------------------------------
procedure StartBrowser;
var 
  browser: String;
  ini: String;
  ResultCode: Integer;
begin
  // default browser searched is FF
  browser := ExpandConstant('{pf}\Mozilla Firefox\firefox.exe');
  ini := ExpandConstant('{pf}');
    if FileExists (browser)  then
    begin
      if not Exec(browser, 'localhost/admin/admin.php', '', SW_SHOW,
        ewNoWait, ResultCode) then
      begin
        MsgBox('Unable to start Firefox. Please start manually!', mbInformation, MB_OK);
      end;
    end else
    begin
      GetOpenFileName('Please choose your default browser.', browser, 'ini','exe files (*.exe)|*.exe|All files (*.*)|*.*' ,'exe');
      if not Exec(browser, 'localhost/admin/admin.php', '', SW_SHOW,
            ewNoWait, ResultCode) then
      begin
        MsgBox('Unable to start the selected browser. Please start manually!', mbInformation, MB_OK);
      end;
    end
    
end;


//----------------------------------------------
// Delete install directory after installation
//----------------------------------------------
procedure DeleteInstallDirectory;
var
  cf: String;
begin
  cf := ExpandConstant('{app}\htdocs\admin\install');
  if not DelTree(cf, True, True, True)  then
    begin
      MsgBox('Unable to delete admin/install directory. Please remove it manually!', mbInformation, MB_OK);
    end;
    
end;
  

//----------------------------------------------
// Execute above procedures before last screen!
//----------------------------------------------
function NextButtonClick(CurPageID: Integer): Boolean;
begin
  if CurPageID = wpInfoAfter then 
  begin
    StartServices;
    StartBrowser;
    DeleteInstallDirectory;
  end;
  Result := True;
end;


//----------------------------------------------
// Configure Uninstallation process
//----------------------------------------------
procedure InitializeUninstallProgressForm;
var
  cf: String;
  ResultCode: Integer;
begin      
  Exec(ExpandConstant('{app}\stop_services.bat'), '', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
     
  //should we care about retaining limesurvey specific data?
  if MsgBox('Would you like to delete LimeSurvey specific files and data as well?',mbConfirmation,MB_YESNO) = IDYES then
  begin
    cf := ExpandConstant('{app}\htdocs');
    if not DelTree(cf, True, True, True)  then
    begin
      MsgBox('Unable to delete limesurvey specific files. Please remove them manually!', mbInformation, MB_OK);
    end;

    cf := ExpandConstant('{app}\mysql\data');
    if not DelTree(cf, True, True, True)  then
    begin
      MsgBox('Unable to delete limesurvey specific data. Please remove it manually!', mbInformation, MB_OK);
    end;
  end;
  
end;