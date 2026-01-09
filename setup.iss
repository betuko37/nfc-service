; Script de Inno Setup para NFC Service v2.0
; Compilar con Inno Setup Compiler

#define MyAppName "NFC Service"
#define MyAppVersion "2.0"
#define MyAppPublisher "NFC Solutions"
#define MyAppExeName "nfc-service.exe"

[Setup]
AppId={{8F4A2C1B-E3D5-4F6A-9B8C-7D0E1F2A3B4C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=Instalador_NFC_Service
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
; Archivo principal y scripts
Source: "nfc-service.js"; DestDir: "{app}"; Flags: ignoreversion
Source: "package.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "watchdog.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "instalar-servicio.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "desinstalar-servicio.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "iniciar-nfc.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "iniciar-oculto.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "diagnostico.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "resumen-instalacion.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "console.html"; DestDir: "{app}"; Flags: ignoreversion

; Carpeta node_modules REQUERIDA para bindings nativos
Source: "node_modules\*"; DestDir: "{app}\node_modules"; Flags: ignoreversion recursesubdirs createallsubdirs

; Node.js portable (no requiere instalación de Node en el sistema)
Source: "node-portable\node.exe"; DestDir: "{app}\node"; Flags: ignoreversion
Source: "node-portable\node_modules\*"; DestDir: "{app}\node\node_modules"; Flags: ignoreversion recursesubdirs createallsubdirs

; Archivos del Driver (se copian a temporal para instalar)
Source: "ACS_Unified_Driver_MSI_Win_4280_P\*"; DestDir: "{tmp}\Driver"; Flags: ignoreversion recursesubdirs createallsubdirs

[Run]
; Paso 1: Instalar Driver (Interactivo)
Filename: "{tmp}\Driver\Setup.exe"; StatusMsg: "Ejecutando instalador de controladores..."; Flags: waituntilterminated

; Paso 2: Instalar servicio con watchdog (pasamos parametro para evitar pause)
Filename: "{app}\instalar-servicio.bat"; Parameters: "silent"; StatusMsg: "Registrando e iniciando el servicio..."; Flags: waituntilterminated runhidden

; Paso 3: Mostrar resumen de instalación
Filename: "{app}\resumen-instalacion.bat"; Description: "Ver resumen de instalación"; Flags: postinstall nowait shellexec

[UninstallRun]
; Ejecutar desinstalador del servicio antes de borrar archivos
Filename: "taskkill.exe"; Parameters: "/F /IM node.exe /T"; Flags: runhidden waituntilterminated; RunOnceId: "StopNode"
Filename: "{app}\desinstalar-servicio.bat"; Parameters: "silent"; Flags: waituntilterminated runhidden; RunOnceId: "DelService"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Icons]
Name: "{commonprograms}\{#MyAppName}"; Filename: "http://localhost:3001/console"
Name: "{commondesktop}\{#MyAppName}"; Filename: "http://localhost:3001/console"; Tasks: desktopicon
