# Delete GhitaPPT leftover folder on next boot
Start-Sleep -Seconds 10
$folder = "C:\Program Files\GhitaPPT"
if (Test-Path $folder) {
    # Take ownership first
    takeown.exe /f $folder /r /d y 2>$null
    icacls.exe $folder /grant "$env:USERNAME:F" /t 2>$null
    Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
}
# Self-delete this script
Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
