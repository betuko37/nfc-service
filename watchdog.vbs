' ===============================================
' WATCHDOG NFC SERVICE - Monitor y Auto-Reinicio
' ===============================================
' Este script monitorea el servicio NFC y lo reinicia
' automáticamente si se detecta que no está corriendo.
' Revisa cada 30 segundos.

Option Explicit

Dim WshShell, fso, scriptPath, exePath, jsPath, nodePortable
Dim checkInterval, maxRetries, currentRetry
Dim logFile

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Configuración
checkInterval = 30000 ' 30 segundos entre verificaciones
maxRetries = 0 ' 0 = infinito
currentRetry = 0

' Obtener la ruta del script
scriptPath = fso.GetParentFolderName(WScript.ScriptFullName)
exePath = scriptPath & "\nfc-service.exe"
jsPath = scriptPath & "\nfc-service.js"
nodePortable = scriptPath & "\node\node.exe"
logFile = scriptPath & "\watchdog.log"

' Verificar si Node.js está disponible
Function IsNodeAvailable()
    Dim objShell, result
    Set objShell = CreateObject("WScript.Shell")
    On Error Resume Next
    objShell.Run "cmd /c where node >nul 2>&1", 0, True
    IsNodeAvailable = (Err.Number = 0)
    On Error Goto 0
End Function

' Función para escribir en el log
Sub WriteLog(message)
    Dim file, timestamp
    timestamp = FormatDateTime(Now, 0)
    
    On Error Resume Next
    Set file = fso.OpenTextFile(logFile, 8, True) ' 8 = append
    If Err.Number = 0 Then
        file.WriteLine timestamp & " - " & message
        file.Close
    End If
    On Error Goto 0
    
    ' Mantener el archivo de log pequeño (eliminar si > 1MB)
    If fso.FileExists(logFile) Then
        If fso.GetFile(logFile).Size > 1048576 Then
            fso.DeleteFile logFile
        End If
    End If
End Sub

' Función para verificar si el proceso está corriendo
Function IsProcessRunning(processName)
    Dim objWMI, colProcesses, objProcess
    
    On Error Resume Next
    Set objWMI = GetObject("winmgmts:\\.\root\cimv2")
    Set colProcesses = objWMI.ExecQuery("SELECT * FROM Win32_Process WHERE Name='" & processName & "'")
    
    IsProcessRunning = (colProcesses.Count > 0)
    On Error Goto 0
End Function

' Función para verificar si el servicio responde por HTTP
Function IsServiceResponding()
    Dim http, url
    url = "http://127.0.0.1:47321/ping"
    
    On Error Resume Next
    Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    http.SetTimeouts 2000, 2000, 2000, 2000 ' Timeouts de 2 segundos
    http.Open "GET", url, False
    http.Send
    
    If Err.Number = 0 And http.Status = 200 Then
        IsServiceResponding = True
    Else
        IsServiceResponding = False
    End If
    On Error Goto 0
End Function

' Función para iniciar el servicio (OCULTO)
Sub StartService()
    WriteLog "Iniciando servicio NFC (oculto)..."
    
    On Error Resume Next
    
    ' Cambiar al directorio del script
    WshShell.CurrentDirectory = scriptPath
    
    ' Usar node portable si existe, sino usar node del sistema
    If fso.FileExists(nodePortable) Then
        WriteLog "Usando Node.js portable"
        WshShell.Run Chr(34) & nodePortable & Chr(34) & " nfc-service.js", 0, False
    Else
        WriteLog "Usando Node.js del sistema"
        WshShell.Run "node nfc-service.js", 0, False
    End If
    
    If Err.Number = 0 Then
        WriteLog "Servicio iniciado correctamente"
        currentRetry = 0
    Else
        WriteLog "Error al iniciar servicio: " & Err.Description
        currentRetry = currentRetry + 1
    End If
    On Error Goto 0
End Sub

' ===============================================
' BUCLE PRINCIPAL DEL WATCHDOG
' ===============================================

WriteLog "=========================================="
WriteLog "WATCHDOG NFC SERVICE INICIADO"
WriteLog "Monitoreando: http://127.0.0.1:47321/ping"
WriteLog "Intervalo: " & (checkInterval / 1000) & " segundos"
WriteLog "=========================================="

' Verificación inicial - iniciar si no responde
If Not IsServiceResponding() Then
    WriteLog "Servicio no detectado al inicio - Iniciando..."
    StartService
    WScript.Sleep 5000 ' Esperar 5 segundos para que inicie
End If

' Bucle infinito de monitoreo
Do While True
    ' Esperar el intervalo configurado
    WScript.Sleep checkInterval
    
    ' Verificar si el servicio responde por HTTP
    If Not IsServiceResponding() Then
        WriteLog "ALERTA: Servicio no responde en puerto 47321"
        
        ' Matar procesos node que puedan estar zombie
        On Error Resume Next
        WshShell.Run "taskkill /F /IM node.exe /FI ""WINDOWTITLE eq nfc*""", 0, True
        On Error Goto 0
        
        WScript.Sleep 2000
        StartService
        WScript.Sleep 5000
    End If
    
    ' Si hay límite de reintentos, verificar
    If maxRetries > 0 And currentRetry >= maxRetries Then
        WriteLog "Máximo de reintentos alcanzado (" & maxRetries & "). Deteniendo watchdog."
        Exit Do
    End If
Loop

WriteLog "Watchdog finalizado"
