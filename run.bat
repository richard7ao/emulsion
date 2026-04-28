@echo off
REM
REM Emulsion Portfolio App — Windows Setup & Run (Backend Only)
REM Requires: Rust (cargo)
REM Note: The iOS app requires macOS + Xcode. This script runs the API server only.
REM
setlocal enabledelayedexpansion

REM Source Rust environment if not already on PATH
if exist "%USERPROFILE%\.cargo\env.ps1" set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"

set "ROOT=%~dp0"
set "DB_PATH=%ROOT%services\portfolio-api\dev.db"
set "DATABASE_URL=sqlite:%DB_PATH%"

echo.
echo  Emulsion Portfolio App (Windows — Backend Only)
echo  ================================================
echo.

REM --- Prerequisites ---
echo  [1/4] Checking prerequisites...

where cargo >nul 2>&1
if errorlevel 1 (
    echo   X  Rust not installed — https://rustup.rs
    exit /b 1
)
for /f "tokens=2" %%v in ('rustc --version') do echo   OK  Rust %%v

echo.
echo  NOTE: The iOS app requires macOS + Xcode.
echo        This script builds and runs the Rust API server only.
echo.

REM --- Database ---
echo  [2/4] Setting up database...

if not exist "%DB_PATH%" (
    cargo run -p seed
    if errorlevel 1 (
        echo   X  Seeding failed
        exit /b 1
    )
    echo   OK  Database created and seeded
) else (
    echo   OK  Database already exists (delete %DB_PATH% to re-seed)
)

REM --- Build ---
echo.
echo  [3/4] Building Rust backend...

cargo build -p portfolio-api
if errorlevel 1 (
    echo   X  Build failed
    exit /b 1
)
echo   OK  Backend compiled

REM --- Run ---
echo.
echo  [4/4] Starting backend server...
echo.
echo  -----------------------------------------------
echo   API:      http://localhost:8080
echo   Health:   http://localhost:8080/health
echo  -----------------------------------------------
echo.
echo  Press Ctrl+C to stop the server.
echo.

cargo run -p portfolio-api
