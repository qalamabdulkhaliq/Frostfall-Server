@echo off
title Frostfall Roleplay — Server
cd /d "%~dp0"

if not exist ".env" (
    echo [!] No .env found. Run setup.bat first.
    pause & exit /b 1
)

node scripts/generate-settings.js
node dist_back/skymp5-server.js
pause
