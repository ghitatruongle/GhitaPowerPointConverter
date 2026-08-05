@echo off
chcp 65001 >nul
echo Scheduling deletion of C:\Program Files\GhitaPPT on next boot...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /t REG_MULTI_SZ /d "\"\"\"\"C:\Program Files\GhitaPPT\"" /f
echo Done. Please restart Windows to delete the folder.
pause
