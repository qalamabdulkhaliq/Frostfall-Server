@echo off
setlocal EnableDelayedExpansion
title Frostfall Roleplay — Setup

echo.
echo  ============================================
echo   Frostfall Roleplay — Local Server Setup
echo  ============================================
echo.

:: ── Check Node.js ─────────────────────────────────────────────────────────────
where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js not found. Install it from https://nodejs.org then re-run.
    pause & exit /b 1
)
for /f "tokens=*" %%v in ('node -v') do set NODE_VER=%%v
echo [OK] Node.js %NODE_VER% found.

:: ── Skip if .env already exists ───────────────────────────────────────────────
if exist ".env" (
    echo [OK] .env already exists — skipping detection.
    goto :generate
)

:: ── Auto-detect Skyrim SE install path ────────────────────────────────────────
echo [..] Looking for Skyrim Special Edition...

set SKYRIM_DATA=

:: Registry lookup (most reliable)
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 489830" /v InstallLocation 2^>nul') do (
    set SKYRIM_DATA=%%b\Data
)
if not defined SKYRIM_DATA (
    for /f "tokens=2*" %%a in ('reg query "HKCU\SOFTWARE\Valve\Steam" /v SteamPath 2^>nul') do (
        set STEAM_PATH=%%b
    )
)

:: Fallback: common drive letters
if not defined SKYRIM_DATA (
    for %%D in (C D E F G H) do (
        if not defined SKYRIM_DATA (
            for %%P in (
                "%%D:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Data"
                "%%D:\Steam\steamapps\common\Skyrim Special Edition\Data"
                "%%D:\SteamLibrary\steamapps\common\Skyrim Special Edition\Data"
                "%%D:\Games\Steam\steamapps\common\Skyrim Special Edition\Data"
                "%%D:\Games\Skyrim Special Edition\Data"
            ) do (
                if not defined SKYRIM_DATA (
                    if exist %%P\Skyrim.esm (
                        set SKYRIM_DATA=%%~P
                    )
                )
            )
        )
    )
)

if not defined SKYRIM_DATA (
    echo.
    echo [!] Could not auto-detect Skyrim. Enter the path to your Skyrim Data folder manually.
    echo     Example: D:\Steam\steamapps\common\Skyrim Special Edition\Data
    echo.
    set /p SKYRIM_DATA="Skyrim Data path: "
    if not exist "!SKYRIM_DATA!\Skyrim.esm" (
        echo [ERROR] Skyrim.esm not found at that path. Check and re-run.
        pause & exit /b 1
    )
)

echo [OK] Skyrim found at: !SKYRIM_DATA!

:: ── Write .env ────────────────────────────────────────────────────────────────
echo.
echo [..] Writing .env...
(
    echo SERVER_NAME=Frostfall Roleplay
    echo SERVER_PORT=7777
    echo MAX_PLAYERS=100
    echo OFFLINE_MODE=true
    echo SKYRIM_DATA_PATH=!SKYRIM_DATA!
    echo NPC_ENABLED=false
    echo DISCORD_CLIENT_ID=
    echo DISCORD_CLIENT_SECRET=
    echo DISCORD_BOT_TOKEN=
    echo DISCORD_GUILD_ID=
    echo DISCORD_BAN_ROLE_ID=
    echo DISCORD_EVENT_LOG_CHANNEL_ID=
    echo DISCORD_HIDE_IP_ROLE_ID=
    echo METRICS_USER=
    echo METRICS_PASSWORD=
    echo MASTER_URL=
) > .env
echo [OK] .env written.

:generate
:: ── Generate server-settings.json ─────────────────────────────────────────────
echo [..] Generating server-settings.json...
node scripts/generate-settings.js
if errorlevel 1 (
    echo [ERROR] Failed to generate server-settings.json.
    pause & exit /b 1
)
echo [OK] server-settings.json generated.

:: ── Install Node dependencies ─────────────────────────────────────────────────
echo [..] Installing Node dependencies...
call npm install --silent
if errorlevel 1 (
    echo [ERROR] npm install failed.
    pause & exit /b 1
)
echo [OK] Dependencies installed.

:: ── Done ──────────────────────────────────────────────────────────────────────
echo.
echo  ============================================
echo   Setup complete! Starting server...
echo   Connect in-game to: localhost:7777
echo  ============================================
echo.

node dist_back/skymp5-server.js
pause
