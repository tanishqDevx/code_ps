# Ensure script persists in ProgramData
$sourcePath = if ($PSCommandPath) { $PSCommandPath } else { $ps1Path }
$persistentPath = "C:\ProgramData\RemoteShell.ps1"
if (Test-Path $sourcePath) {
    Copy-Item -Path $sourcePath -Destination $persistentPath -Force
} else {
    Write-Warning "Source path not found. Saving current script content to $persistentPath."
    $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
    Set-Content -Path $persistentPath -Value $scriptContent -Force
}
