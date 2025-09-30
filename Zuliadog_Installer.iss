; ========================================
; Script de Inno Setup para Zuliadog
; Versión: 1.0.0 - Con dependencias de Visual C++
; ========================================

#define MyAppName "Zuliadog"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Zuliadog Veterinaria"
#define MyAppExeName "zuliadog.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir={userdocs}\..\Downloads\Zuliadog
OutputBaseFilename=Zuliadog_Veterinaria_Setup_v{#MyAppVersion}
SetupIconFile=C:\Users\after\Documents\Zuliadog\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.17763

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un icono en el escritorio"; GroupDescription: "Iconos adicionales:"; Flags: unchecked

[Files]
; Archivos de la aplicación
Source: "C:\Users\after\Documents\Zuliadog\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\after\Documents\Zuliadog\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\after\Documents\Zuliadog\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon


[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
function InitializeSetup: Boolean;
begin
  Result := True;
  MsgBox('Asegúrate de cerrar Zuliadog si está ejecutándose antes de continuar con la instalación.', 
         mbInformation, MB_OK);
end;

function InitializeUninstall: Boolean;
begin
  Result := True;
  MsgBox('Se eliminarán todos los archivos de Zuliadog.', mbInformation, MB_OK);
end;
