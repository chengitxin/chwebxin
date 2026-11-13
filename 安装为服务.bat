@echo off
rem ============================================
rem   Install WebGb portable as a Windows service
rem   Auto-start on boot, auto-restart on crash
rem   Edit PORT below and run again to change port
rem ============================================
set PORT=80

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%
if not exist "%ROOT%\logs" mkdir "%ROOT%\logs"

set NSSM=%~dp0nssm\nssm.exe
if not exist "%NSSM%" (
    echo nssm.exe not found in the nssm folder.
    pause
    exit /b 1
)

"%NSSM%" stop WebGbPortable >nul 2>&1
"%NSSM%" remove WebGbPortable confirm >nul 2>&1
"%NSSM%" install WebGbPortable "%ROOT%\node\node.exe"
"%NSSM%" set WebGbPortable AppParameters "service.js"
"%NSSM%" set WebGbPortable AppDirectory "%ROOT%"
"%NSSM%" set WebGbPortable AppEnvironmentExtra NODE_ENV=production PORT=%PORT%
"%NSSM%" set WebGbPortable AppStdout "%ROOT%\logs\service.out.log"
"%NSSM%" set WebGbPortable AppStderr "%ROOT%\logs\service.err.log"
"%NSSM%" set WebGbPortable AppRotateFiles 1
"%NSSM%" set WebGbPortable AppRotateOnline 1
"%NSSM%" set WebGbPortable AppRotateBytes 10485760
"%NSSM%" set WebGbPortable AppExit Default Restart
"%NSSM%" set WebGbPortable AppRestartDelay 5000
"%NSSM%" set WebGbPortable Start SERVICE_AUTO_START
"%NSSM%" set WebGbPortable DisplayName "WebGb News Site (Portable)"

net start WebGbPortable

echo.
echo   ==========================================
echo    Service WebGbPortable installed and started.
echo    URL:   http://localhost:%PORT%
echo    Logs:  %ROOT%\logs
echo    Stop:  net stop WebGbPortable
echo   ==========================================
echo.
pause
