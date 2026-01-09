' Inicia el servicio NFC completamente oculto
On Error Resume Next

Set WS = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Obtener directorio del script
scriptPath = fso.GetParentFolderName(WScript.ScriptFullName)
nodePortable = scriptPath & "\node\node.exe"
jsFile = scriptPath & "\nfc-service.js"
logFile = scriptPath & "\inicio.log"

' Cambiar al directorio
WS.CurrentDirectory = scriptPath

' Verificar que existe el archivo JS
If Not fso.FileExists(jsFile) Then
    ' Escribir error en log
    Set log = fso.OpenTextFile(logFile, 2, True)
    log.WriteLine Now & " - ERROR: No se encuentra nfc-service.js en " & scriptPath
    log.Close
    WScript.Quit 1
End If

' Intentar iniciar con node portable primero
If fso.FileExists(nodePortable) Then
    ' Usar node portable
    WS.Run Chr(34) & nodePortable & Chr(34) & " " & Chr(34) & jsFile & Chr(34), 0, False
    If Err.Number = 0 Then
        ' Escribir éxito en log
        Set log = fso.OpenTextFile(logFile, 2, True)
        log.WriteLine Now & " - Servicio iniciado con Node.js portable"
        log.Close
    Else
        ' Escribir error en log
        Set log = fso.OpenTextFile(logFile, 2, True)
        log.WriteLine Now & " - ERROR al iniciar con node portable: " & Err.Description
        log.Close
    End If
Else
    ' Intentar con node del sistema
    WS.Run "node " & Chr(34) & jsFile & Chr(34), 0, False
    If Err.Number = 0 Then
        Set log = fso.OpenTextFile(logFile, 2, True)
        log.WriteLine Now & " - Servicio iniciado con Node.js del sistema"
        log.Close
    Else
        Set log = fso.OpenTextFile(logFile, 2, True)
        log.WriteLine Now & " - ERROR: No se encuentra Node.js. Error: " & Err.Description
        log.Close
    End If
End If

On Error Goto 0
