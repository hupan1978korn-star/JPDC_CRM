@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

REM ==========================================
REM  git-pull.bat — Pull latest from GitHub
REM  Run on other machines to get latest DB
REM ==========================================

set ROOT=%~dp0..

cd /d "%ROOT%"

set GH="C:\Program Files\GitHub CLI\gh.exe"

REM Check Git
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [FAIL] Git not found. Please install Git first.
    pause
    exit /b 1
)

REM Check GitHub CLI
if not exist %GH% (
    echo [FAIL] GitHub CLI not found at %GH%
    pause
    exit /b 1
)

REM Check login
%GH% auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo First time: login required. Opening browser...
    %GH% auth login --hostname github.com --web
    if %errorlevel% neq 0 (
        echo [FAIL] Login failed.
        pause
        exit /b 1
    )
)

REM Pull latest
echo [Git] Pulling latest data from GitHub...
git pull origin main

if %errorlevel% neq 0 (
    echo.
    echo ================================================
    echo   PULL FAILED
    echo ================================================
    echo   This can happen on a new machine / first setup.
    echo   If you haven't cloned yet, run:
    echo     git clone YOUR_REPO_URL JPDC_CRM
    echo.
    pause
    exit /b 1
)

echo.
echo [Git] Latest database pulled.
echo Now start JPDC Backend and open the app on your phone.
pause
exit /b 0
