@echo off
:: Run deep trace elevated with output capture
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy','Bypass','-File','D:\GhitaPPT\installer\deep_trace.ps1' -RedirectStandardOutput 'D:\GhitaPPT\installer\scan_output.txt' -RedirectStandardError 'D:\GhitaPPT\installer\scan_errors.txt'"
echo Elevated process started. Waiting for completion...
:waitloop
timeout /t 2 /nobreak >nul
tasklist /FI "IMAGENAME eq powershell.exe" 2>nul | find /I "powershell.exe" >nul
if %ERRORLEVEL%==0 goto waitloop
echo.
echo Scan complete. Output saved to D:\GhitaPPT\installer\scan_output.txt
type "D:\GhitaPPT\installer\scan_output.txt"
pause
