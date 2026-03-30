@echo off
:: Launches GameBoost.ps1 elevated.
set SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%SCRIPT_DIR%GameBoost.ps1\"'"
