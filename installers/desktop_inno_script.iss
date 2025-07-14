#define MyAppName "دوائي - Admin Portal"
#define MyAppVersion "1.5"
#define MyAppPublisher "Alaa"
#define MyAppExeName "med_ad_admin.exe"

[Setup]
AppId={{8FDC5A31-AD56-45C7-A699-BBA35D03D873}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
OutputDir=C:\Users\Mahmood\Desktop\New folder\med_ad_admin\installers
OutputBaseFilename=Doa2i_Admin_Setup
SetupIconFile=C:\Users\Mahmood\Desktop\New folder\med_ad_admin\assets\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
UseSetupLdr=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "C:\Users\Mahmood\Desktop\New folder\med_ad_admin\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\Mahmood\Desktop\New folder\med_ad_admin\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Flags: nowait postinstall skipifsilent
