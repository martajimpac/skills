@echo off
setlocal
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0ias-core.ps1" %*
exit /b %ERRORLEVEL%
