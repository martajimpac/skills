@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0ias-core.ps1" %*
exit /b %ERRORLEVEL%
