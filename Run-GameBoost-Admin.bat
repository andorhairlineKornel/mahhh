@echo off
setlocal

set SCRIPT_DIR=%~dp0
set PS_FILE=%SCRIPT_DIR%GameBoost.ps1

if not exist "%PS_FILE%" (
  echo Could not find "%PS_FILE%".
  pause
  exit /b 1
)

echo.
echo GameBoost launcher
echo -----------------
echo 1^) Apply safe gaming tweaks
echo 2^) Apply tweaks + enable HAGS
echo 3^) Revert settings from backup
echo 4^) Exit
echo.

set /p CHOICE=Select an option [1-4]:

if "%CHOICE%"=="1" goto apply
if "%CHOICE%"=="2" goto apply_hags
if "%CHOICE%"=="3" goto revert
if "%CHOICE%"=="4" goto done

echo Invalid option.
pause
exit /b 1

:apply
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PS_FILE%\"'"
goto done

:apply_hags
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PS_FILE%\" -EnableHags'"
goto done

:revert
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PS_FILE%\" -Revert'"
goto done

:done
endlocal
