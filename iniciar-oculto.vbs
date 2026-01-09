' Inicia el servicio NFC completamente oculto
Set WS = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Obtener directorio del script
scriptPath = fso.GetParentFolderName(WScript.ScriptFullName)

' Cambiar al directorio e iniciar node oculto
WS.CurrentDirectory = scriptPath
WS.Run "node nfc-service.js", 0, False
