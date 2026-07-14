@echo off
setlocal enabledelayedexpansion
title JPDC CRM - 1-Click Data Update
chcp 65001 >nul 2>&1

set ROOT=%~dp0
cd /d "%ROOT%backend"

echo.
echo ================================================
echo   JPDC CRM - One-Click Update
echo   Jinxi Seaview City
echo ================================================
echo.

:: ── Step 1: Import from Excel ──
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Python not found
    pause
    exit /b 1
)

python -c "import openpyxl" >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Installing dependencies...
    pip install openpyxl fastapi uvicorn pyjwt --quiet 2>nul
)

echo [1/4] Importing from Excel...
python import_excel.py
set RESULT=%errorlevel%

if %RESULT% neq 0 (
    echo [FAIL] Import failed (code %RESULT%)
    echo        Check: import_log.txt
    pause
    exit /b 1
)

:: ── Step 2: Restart backend ──
echo.
echo [2/4] Restarting backend...

:: Kill old backend
taskkill /f /fi "WINDOWTITLE eq JPDC_Backend*" >nul 2>&1
taskkill /f /fi "WINDOWTITLE eq Admin*JPDC*" >nul 2>&1
:: Also kill port 8001
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8001.*LISTENING" 2^>nul') do (
    taskkill /f /pid %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul

:: Start new backend
start "JPDC_Backend" /MIN cmd /c "cd /d "%ROOT%backend" && python -m uvicorn main:app --host 0.0.0.0 --port 8001 --log-level warning"
echo   Backend restarted
timeout /t 4 /nobreak >nul

:: ── Step 3: Verify ──
echo.
echo [3/4] Verifying data...

:: Direct DB check (much faster & never fails)
python -c "import sqlite3;c=sqlite3.connect('jpdc.db').cursor();c.execute('SELECT tower,COUNT(*) FROM units GROUP BY tower');r=c.fetchall();print(f'  Units: A={r[0][1]}, E={r[1][1]}');c.execute('SELECT COUNT(*) FROM sold_clients');print(f'  Sold: {c.fetchone()[0]}');c.execute('SELECT COUNT(*) FROM overdue_warnings');print(f'  Overdue: {c.fetchone()[0]}');c.execute('SELECT COUNT(*) FROM returned_units');print(f'  Returned: {c.fetchone()[0]}');print('  OK')" 2>nul

:: Also verify API is up
timeout /t 2 /nobreak >nul
curl.exe -s http://localhost:8001/api/dashboard >nul 2>&1
if %errorlevel% equ 0 (
    echo   API: OK
) else (
    echo   API: starting... (may take a moment)
)

:: ── Step 4: Git push to GitHub ──
echo.
echo [4/4] Syncing to GitHub...

set GIT_TERMINAL_PROMPT=0
cd /d "%ROOT%"

:: Stage db + log
git add backend\jpdc.db backend\import_log.txt >nul 2>&1

:: Check if jpdc.db changed
git diff --cached --quiet backend\jpdc.db 2>nul
if %errorlevel% neq 0 (
    :: Commit and push
    for /f "tokens=1-5 delims=/:. " %%a in ("%date% %time%") do set TS=%%a-%%b-%%c_%%d%%e
    git commit -m "Data update !TS!" >nul 2>&1
    git push origin main >nul 2>&1
    if !errorlevel! equ 0 (
        echo   Pushed to GitHub
    ) else (
        echo   [WARN] Push failed (will retry next time)
    )
) else (
    echo   Database already up to date on GitHub
)

:: ── Done ──
echo.
echo ================================================
echo   UPDATE COMPLETE
echo ================================================
echo.
echo   Server: http://192.168.8.46:8001
echo   Phone: pull down to refresh
echo.
echo   Log: backend\import_log.txt
echo   GitHub: https://github.com/hupan1978korn-star/JPDC_CRM
echo ================================================
echo.
pause
