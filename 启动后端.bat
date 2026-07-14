@echo off
chcp 65001 >nul
title JPDC CRM Backend (auto-restart)

echo ============================================
echo   JPDC CRM - Backend Auto-Restart
echo ============================================

cd /d "%~dp0backend"

:: Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found
    pause
    exit /b 1
)

:: Install deps if missing
python -c "import fastapi, uvicorn" >nul 2>&1
if %errorlevel% neq 0 (
    pip install fastapi uvicorn pyjwt -q
)

:: Loop forever, restart on crash
:loop
for /f "tokens=3 delims=: " %%a in ('powershell -Command "Get-NetIPAddress -AddressFamily IPv4 ^| Where-Object {$_.InterfaceAlias -notmatch 'Loopback' -and $_.PrefixOrigin -ne 'WellKnown' -and $_.IPAddress -notlike '172.*'} ^| Select-Object -First 1 -ExpandProperty IPAddress"') do set IP=%%a
    echo [%date% %time%] Starting backend on http://%IP%:8001
    echo [%date% %time%] Starting backend on http://%IP%:8001 >> backend.log 2>&1
    python -m uvicorn main:app --host 0.0.0.0 --port 8001 --log-level warning
    echo [%date% %time%] Backend stopped, restarting in 5s...
    echo [%date% %time%] Backend stopped, restarting in 5s... >> backend.log 2>&1
    timeout /t 5 /nobreak >nul
    goto loop
