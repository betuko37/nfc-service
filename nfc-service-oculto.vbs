Set WshShell = CreateObject("WScript.Shell")
WshShell.Run Chr(34) & WScript.ScriptFullName & "\..\nfc-service.exe" & Chr(34), 0
Set WshShell = Nothing