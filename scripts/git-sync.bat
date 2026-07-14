@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

REM ==========================================
REM  git-sync.bat — Push JPDC CRM to GitHub
REM  Usage: double-click or call from 一键更新
REM ==========================================

set ROOT=%~dp0..

cd /d "%ROOT%"

set GH="C:\Program Files\GitHub CLI\gh.exe"

REM Step 1: Check Git + GitHub CLI
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Git not found. Install from https://git-scm.com
    pause
    exit /b 1
)

if not exist %GH% (
    echo [FAIL] GitHub CLI not found at %GH%
    echo        Install: winget install GitHub.cli
    pause
    exit /b 1
)

REM Step 2: Check GitHub login
%GH% auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ================================================
    echo   First time setup: GitHub login required
    echo ================================================
    echo   Open this URL in your browser to login:
    echo.
    %GH% auth login --hostname github.com --web
    if %errorlevel% neq 0 (
        echo [FAIL] GitHub login failed. Try again later.
        pause
        exit /b 1
    )
)

REM Step 3: Stage all tracked changes
echo [Git] Staging changes...
git add backend\jpdc.db backend\import_log.txt backend\*.py scripts\ backend\requirements.txt
git add 一键更新数据.bat 启动后端.bat README.txt .gitignore git-sync.bat iOS编译指南.md

REM Step 4: Check if there's anything to commit
git diff --cached --quiet
if %errorlevel% equ 0 (
    echo [Git] No changes to commit. Database is up to date on GitHub.
    exit /b 0
)

REM Step 5: Commit with timestamp
for /f "tokens=1-5 delims=/:. " %%a in ("%date% %time%") do set TS=%%a-%%b-%%c_%%d%%e
git commit -m "Data update %TS%"

if %errorlevel% neq 0 (
    echo [WARN] Commit may have failed (no changes?)
    exit /b 0
)

REM Step 6: Push
echo [Git] Pushing to GitHub...
git push -u origin main

if %errorlevel% neq 0 (
    echo [WARN] Push failed. Will retry next time.
    echo        Check: gh auth status
    echo        You can manually push later with: cd JPDC_CRM && git push
    pause
    exit /b 1
)

echo.
echo [Git] Database synced to GitHub successfully!

exit /b 0
