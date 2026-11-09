; Inno Setup script -> real Windows installer (0xcl-modern-vlc-setup.exe)
; Build:  iscc packaging\0xcl.iss   (expects the deployed app in .\dist)
#define MyAppName "0xcl Modern VLC"
#define MyAppVersion "1.0.0"
#define MyAppExe "0xcl.exe"

[Setup]
AppId={{6F1B7E52-9C1D-4B7A-8E0B-0C1A5D5B7A10}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=0xcl
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=..\installer
OutputBaseFilename=0xcl-modern-vlc-setup
SetupIconFile=0xcl.ico
UninstallDisplayIcon={app}\{#MyAppExe}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"
Name: "assoc"; Description: "Open common video/audio files with {#MyAppName}"; GroupDescription: "File associations:"; Flags: unchecked

[Files]
Source: "..\dist\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; Tasks: desktopicon

[Registry]
Root: HKA; Subkey: "Software\Classes\0xcl.Media"; ValueType: string; ValueData: "{#MyAppName} media file"; Flags: uninsdeletekey; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\0xcl.Media\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExe}"" ""%1"""; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\.mp4\OpenWithProgids"; ValueName: "0xcl.Media"; ValueType: string; ValueData: ""; Flags: uninsdeletevalue; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\.mkv\OpenWithProgids"; ValueName: "0xcl.Media"; ValueType: string; ValueData: ""; Flags: uninsdeletevalue; Tasks: assoc
Root: HKA; Subkey: "Software\Classes\.mp3\OpenWithProgids"; ValueName: "0xcl.Media"; ValueType: string; ValueData: ""; Flags: uninsdeletevalue; Tasks: assoc

[Run]
Filename: "{app}\{#MyAppExe}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
