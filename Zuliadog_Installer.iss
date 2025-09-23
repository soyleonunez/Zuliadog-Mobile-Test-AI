; ========================================
; Script de Inno Setup para Zuliadog
; Versión: 1.0.0
; ========================================

#define MyAppName "Zuliadog"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Zuliadog Veterinaria"
#define MyAppExeName "zuliadog.exe"

[Setup]
; Información básica de la aplicación
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://zuliadog.com
AppSupportURL=https://zuliadog.com/support
AppUpdatesURL=https://zuliadog.com/updates
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=installer
OutputBaseFilename=Zuliadog_Setup_{#MyAppVersion}
SetupIconFile=
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DisableProgramGroupPage=yes
DisableReadyPage=no
DisableFinishedPage=no
MinVersion=10.0.17763

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un icono en el escritorio"; GroupDescription: "Iconos adicionales:"; Flags: unchecked
Name: "quicklaunchicon"; Description: "Crear un icono en la barra de inicio rápido"; GroupDescription: "Iconos adicionales:"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
; Archivo principal de la aplicación
Source: "build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Ejecutar {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Evento antes de la instalación - mensaje simple
function InitializeSetup: Boolean;
begin
  Result := True;
  // Mostrar mensaje informativo
  MsgBox('Asegúrate de cerrar Zuliadog si está ejecutándose antes de continuar con la instalación.', 
         mbInformation, MB_OK);
end;

// Evento antes de la desinstalación - mensaje simple
function InitializeUninstall: Boolean;
begin
  Result := True;
  // Mostrar mensaje informativo
  MsgBox('Asegúrate de cerrar Zuliadog si está ejecutándose antes de continuar con la desinstalación.', 
         mbInformation, MB_OK);
end;
