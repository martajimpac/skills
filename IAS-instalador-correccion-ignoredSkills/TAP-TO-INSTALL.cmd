@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-IAS.ps1" %*
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" (
  echo Instalacion completada.
) else (
  echo La instalacion termino con codigo %RESULT%.
)
pause
exit /b %RESULT%
