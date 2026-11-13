@echo off
rem Uninstall the WebGb portable Windows service (project files are kept)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

net stop WebGbPortable
"%~dp0nssm\nssm.exe" remove WebGbPortable confirm

echo.
echo Service WebGbPortable removed. Files kept in %~dp0
echo.
pause
