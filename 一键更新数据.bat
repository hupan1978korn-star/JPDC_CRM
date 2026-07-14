@echo off
setlocal enabledelayedexpansion
title JPDC CRM - 1-Click Data Update
chcp 65001 >nul 2>&1

set ROOT=%~dp0
cd /d "%ROOT%backend"

echo.
echo ================================================
echo   JPDC CRM - One-Click Update + GitHub Sync
echo   Jinxi Seaview City ^(Jin Xi Hai Jing Cheng^)
echo ================================================
echo.

:: ── Step 1: Import from Excel ──
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Python not found
    pause & exit /b 1
)

python -c "import openpyxl, fastapi" >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Installing dependencies...
    pip install openpyxl fastapi uvicorn pyjwt -q
)

echo [1/4] Importing from Excel...
python import_excel.py
set RESULT=%errorlevel%

if %RESULT% neq 0 (
    echo [FAIL] Import failed (code %RESULT%)
    echo        Check: %ROOT%backend\import_log.txt
    pause & exit /b 1
)

:: ── Step 2: Restart backend ──
echo.
echo [2/4] Checking backend...

powershell -Command "try { $r=Invoke-RestMethod 'http://localhost:8001/api/health' -TimeoutSec 3; if($r.status -ne 'ok'){throw} } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    taskkill /f /im python.exe /fi "WINDOWTITLE eq JPDC*" >nul 2>&1
    timeout /t 2 /nobreak >nul
    start "JPDC_Backend" /MIN cmd /c "cd /d "%ROOT%backend" && python -m uvicorn main:app --host 0.0.0.0 --port 8001 --log-level warning"
    timeout /t 4 /nobreak >nul
)

:: ── Step 3: Verify ──
echo.
echo [3/4] Verifying data...
python -c "import sqlite3; c=sqlite3.connect('jpdc.db').cursor(); c.execute('SELECT tower,COUNT(*) FROM units GROUP BY tower'); r=c.fetchall(); print('  Units:', {k:v for k,v in r}); c.execute('SELECT COUNT(*) FROM sold_clients'); print('  Sold:', c.fetchone()[0]); c.execute('SELECT COUNT(*) FROM overdue_warnings'); print('  Overdue:', c.fetchone()[0]); c.execute('SELECT COUNT(*) FROM returned_units'); print('  Returned:', c.fetchone()[0]); print('OK')" 2>nul

:: ── Step 4: Git push ──
echo.
echo [4/4] Syncing to GitHub...
if exist "%ROOT%scripts\git-sync.bat" (
    start "GIT_SYNC" /MIN cmd /c "call "%ROOT%scripts\git-sync.bat" && pause"
) else (
    echo [SKIP] git-sync.bat not found. Run git-sync.bat separately.
)

echo.
echo ================================================
echo   UPDATE COMPLETE
echo ================================================
echo.
echo   Server: http://192.168.8.46:8001
echo   Phone: pull down to refresh
echo.
echo   GitHub sync: scripts\git-sync.bat
echo   Log: %ROOT%backend\import_log.txt
echo.
echo ================================================
pause
