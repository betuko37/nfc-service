; Script de Inno Setup para Instalador NFC Service
; Compilar con Inno Setup Compiler

#define MyAppName "NFC Service ACR122U"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "NFC Service"
#define MyAppURL "http://localhost:3001"
#define MyAppExeName "nfc-service.js"

[Setup]
AppId={{A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=dist
OutputBaseFilename=Instalador-NFC-Service
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Archivos del servicio NFC
Source: "nfc-service.js"; DestDir: "{app}"; Flags: ignoreversion
Source: "nfc-service-oculto-node.vbs"; DestDir: "{app}"; Flags: ignoreversion; DestName: "nfc-service-oculto.vbs"
Source: "console.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "package.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "node_modules\*"; DestDir: "{app}\node_modules"; Flags: recursesubdirs createallsubdirs ignoreversion

; Drivers ACS - Copiar toda la carpeta
Source: "ACS_Unified_Driver_MSI_Win_4280_P\*"; DestDir: "{tmp}\ACS_Driver"; Flags: recursesubdirs createallsubdirs deleteafterinstall

; Scripts BAT
Source: "iniciar-servicio-node.bat"; DestDir: "{app}"; Flags: ignoreversion; DestName: "iniciar-servicio.bat"
Source: "verificar-servicio.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "diagnostico-servicio.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Iniciar Servicio"; Filename: "{app}\iniciar-servicio-node.bat"
Name: "{group}\Consola de Logs"; Filename: "http://localhost:3001/console"
Name: "{group}\Verificar Servicio"; Filename: "{app}\verificar-servicio.bat"
Name: "{group}\Diagnostico Servicio"; Filename: "{app}\diagnostico-servicio.bat"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Run]
; Paso 1: Instalar drivers ACS (silencioso)
Filename: "{tmp}\ACS_Driver\Setup.exe"; Parameters: "/S"; StatusMsg: "Paso 1/3: Instalando drivers ACS ACR122U..."; Flags: runhidden waituntilterminated; WorkingDir: "{tmp}\ACS_Driver"

; Paso 2 y 3 se hacen en el código para mejor control

[Code]
var
  StartupShortcutCreated: Boolean;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  VbsPath: String;
  StartupFolder: String;
  ShortcutPath: String;
  PowerShellCmd: String;
  ServicePath: String;
begin
  // Después de instalar los archivos
  if CurStep = ssPostInstall then
  begin
    ServicePath := ExpandConstant('{app}\{#MyAppExeName}');
    VbsPath := ExpandConstant('{app}\nfc-service-oculto.vbs');
    StartupFolder := ExpandConstant('{userstartup}');
    ShortcutPath := StartupFolder + '\NFC-Service.lnk';
    
    // Verificar que el ejecutable existe
    if not FileExists(ServicePath) then
    begin
      MsgBox('Error: No se encuentra el archivo ' + ServicePath, mbError, MB_OK);
      Exit;
    end;
    
    // Crear acceso directo en Startup para inicio automático
    PowerShellCmd := '$WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut(''' + ShortcutPath + '''); $SC.TargetPath = ''' + VbsPath + '''; $SC.WorkingDirectory = ''' + ExpandConstant('{app}') + '''; $SC.WindowStyle = 7; $SC.Description = ''Servicio NFC ACR122U''; $SC.Save()';
    
    Exec('powershell.exe', 
      '-ExecutionPolicy Bypass -Command "' + PowerShellCmd + '"',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    
    if ResultCode = 0 then
      StartupShortcutCreated := True;
    
    // PASO 2: Iniciar el servicio usando Node.js
    // Verificar que Node.js esté instalado
    Exec('node.exe', '--version', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    
    if ResultCode <> 0 then
    begin
      MsgBox('Node.js no está instalado o no está en el PATH.' + #13#10 + #13#10 + 
             'Por favor instala Node.js desde: https://nodejs.org/' + #13#10 + #13#10 +
             'El servicio se configurará pero deberás instalar Node.js para que funcione.', 
             mbInformation, MB_OK);
    end
    else
    begin
      // Iniciar el servicio usando el VBS que ejecuta Node.js
      Exec('cscript.exe', 
        '//nologo "' + VbsPath + '"',
        ExpandConstant('{app}'), SW_HIDE, ewNoWait, ResultCode);
      Sleep(3000);
    end;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  ResultCode: Integer;
  i: Integer;
  ServiceRunning: Boolean;
  PortActive: Boolean;
  VbsPath: String;
begin
  // Cuando llega a la página final, verificar que el servicio esté corriendo
  if CurPageID = wpFinished then
  begin
    VbsPath := ExpandConstant('{app}\nfc-service-oculto.vbs');
    
    // Esperar un poco más
    Sleep(3000);
    
    // Verificar si el servicio está corriendo (puerto 3001)
    ServiceRunning := False;
    for i := 1 to 10 do
    begin
      Exec('netstat.exe', '-ano | findstr ":3001"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      if ResultCode = 0 then
      begin
        ServiceRunning := True;
        Break;
      end;
      Sleep(1000);
    end;
    
    // Si el proceso está corriendo, verificar que el puerto esté activo
    PortActive := False;
    if ServiceRunning then
    begin
      for i := 1 to 10 do
      begin
        Exec('netstat.exe', '-ano | findstr ":3001"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        if ResultCode = 0 then
        begin
          PortActive := True;
          Break;
        end;
        Sleep(1000);
      end;
    end;
    
    // Si el servicio está corriendo y el puerto está activo, abrir la consola
    if ServiceRunning and PortActive then
    begin
      Sleep(2000); // Esperar un poco más para que el servidor HTTP esté completamente listo
      Exec('rundll32.exe', 'url.dll,FileProtocolHandler http://localhost:3001/console', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
    end
    else
    begin
      // Si no está corriendo, intentar iniciarlo de nuevo y mostrar mensaje
      if not ServiceRunning then
      begin
        // Intentar iniciar de nuevo
        Exec('cscript.exe', 
          '//nologo "' + VbsPath + '"',
          ExpandConstant('{app}'), SW_HIDE, ewNoWait, ResultCode);
        Sleep(5000);
        
        // Verificar una vez más (puerto)
        Exec('netstat.exe', '-ano | findstr ":3001"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        if ResultCode = 0 then
        begin
          Sleep(3000);
          Exec('rundll32.exe', 'url.dll,FileProtocolHandler http://localhost:3001/console', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
        end
        else
        begin
          MsgBox('El servicio NFC no se pudo iniciar automáticamente.' + #13#10 + #13#10 + 
                 'Por favor, inícielo manualmente desde:' + #13#10 + 
                 ExpandConstant('{app}\iniciar-servicio.bat') + #13#10 + #13#10 +
                 'O ejecute el script de diagnóstico para más información.', 
                 mbInformation, MB_OK);
        end;
      end
      else if not PortActive then
      begin
        MsgBox('El proceso está corriendo pero el puerto 3001 no está activo.' + #13#10 + #13#10 + 
               'Espere unos segundos más e intente abrir:' + #13#10 + 
               'http://localhost:3001/console' + #13#10 + #13#10 +
               'Si el problema persiste, ejecute el script de diagnóstico.', 
               mbInformation, MB_OK);
      end;
    end;
  end;
end;

function InitializeUninstall(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  // Detener el servicio antes de desinstalar (buscar procesos node que ejecuten nfc-service.js)
  Exec('taskkill.exe', '/F /FI "WINDOWTITLE eq *nfc-service*" /IM node.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  
  // Eliminar acceso directo de inicio
  DeleteFile(ExpandConstant('{userstartup}\NFC-Service.lnk'));
end;
