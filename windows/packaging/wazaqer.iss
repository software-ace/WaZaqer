; The EXE installer (Inno Setup 6). Built by the release workflow from the
; Flutter bundle; paths here are relative to this file.
;   iscc /DAppVersion=1.0.0 /DSourceDir=<bundle> /DOutputDir=<dir> /DOutputName=<name> wazaqer.iss
; Uninstalling keeps your settings, favourites and reading progress.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
; Fixed: later versions find and upgrade this install by it.
AppId={{7c27e13f-bcf8-499e-a2a7-c7504075980b}
AppName=WaZaqer
AppVersion={#AppVersion}
AppPublisher=software-ace
AppPublisherURL=https://github.com/software-ace/WaZaqer
DefaultDirName={autopf}\WaZaqer
DisableProgramGroupPage=yes
; Installs for just you without admin rights, or for everyone if you choose.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename={#OutputName}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\wazaqer.exe
LicenseFile=..\..\LICENSE
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\WaZaqer"; Filename: "{app}\wazaqer.exe"; AppUserModelID: "ace.software.wazaqer"
Name: "{autodesktop}\WaZaqer"; Filename: "{app}\wazaqer.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\wazaqer.exe"; Description: "{cm:LaunchProgram,WaZaqer}"; Flags: nowait postinstall skipifsilent
