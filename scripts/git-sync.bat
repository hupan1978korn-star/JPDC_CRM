@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

set ROOT=%~dp0..
cd /d "%ROOT%"

:: Verify git exists
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Git not found
    exit /b 1
)

:: Stage db + import log
echo [Git] Staging...
git add backend\jpdc.db backend\import_log.txt 2>nul

:: Check if anything to commit
set HAS_CHANGES=0
git diff --cached --quiet backend\jpdc.db 2>nul
if %errorlevel% neq 0 set HAS_CHANGES=1
git diff --cached --quiet backend\import_log.txt 2>nul
if %errorlevel% neq 0 set HAS_CHANGES=1

if %HAS_CHANGES% equ 0 (
    echo [Git] Database already up to date on GitHub.
    exit /b 0
)

:: Commit
for /f "tokens=1-5 delims=/:. " %%a in ("%date% %time%") do set TS=%%a-%%b-%%c_%%d%%e
git commit -m "Data update %TS%" 2>nul

:: Push (remote URL already has token embedded)
echo [Git] Pushing...
set GIT_TERMINAL_PROMPT=0
git push origin main 2>&1

if %errorlevel% equ 0 (
    echo [Git] Synced to GitHub successfully.
    exit /b 0
) else (
    echo [WARN] Push failed (network?). Will retry next time.
    exit /b 1
)
