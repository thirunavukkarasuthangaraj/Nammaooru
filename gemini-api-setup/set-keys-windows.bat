@echo off
REM ═══════════════════════════════════════════════════════════════════════
REM  Gemini API Keys Setup Script for Windows
REM  Sets environment variables and starts Spring Boot application
REM ═══════════════════════════════════════════════════════════════════════

echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║          🚀 Gemini API Keys Configuration for Windows                ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.

REM ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REM  STEP 1: REPLACE THESE WITH YOUR ACTUAL API KEYS
REM ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REM  Get your keys from: https://aistudio.google.com/api-keys
REM  Click "Show API key" button for each key and paste below

set GEMINI_API_KEY_1=AIzaSyA-SdjVz-rnQbPk17e9k2FSq6LY_svGB3Q
set GEMINI_API_KEY_2=AIzaSyDvKELg3zFky3G2Pg0uN2_NV5BoIl9JiQE
set GEMINI_API_KEY_3=AIzaSyAYqI-DsGx4QWBjyS9K8P9uSqMEcD7CmQo
set GEMINI_API_KEY_4=AIzaSyCGt_F5WfqMZwr5UDkvOKWSuMQkkNRxoTc

REM Enable/disable Gemini AI
set GEMINI_ENABLED=true

REM ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ✅ Environment variables set for current session!
echo.
echo API Key 1 (GB3Q): %GEMINI_API_KEY_1:~0,20%...
echo API Key 2 (JlQE): %GEMINI_API_KEY_2:~0,20%...
echo API Key 3 (CmQo): %GEMINI_API_KEY_3:~0,20%...
echo API Key 4 (XoTc): %GEMINI_API_KEY_4:~0,20%...
echo.
echo Gemini Enabled: %GEMINI_ENABLED%
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo NOTE: These are session variables only (temporary)
echo For permanent setup, add to System Environment Variables:
echo   1. Press Win + R
echo   2. Type: sysdm.cpl
echo   3. Go to Advanced → Environment Variables
echo   4. Add these 4 variables under "User variables"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

REM Ask user if they want to start the backend
echo.
set /p START_BACKEND="Do you want to start the Spring Boot backend now? (Y/N): "

if /i "%START_BACKEND%"=="Y" (
    echo.
    echo Starting Spring Boot application...
    echo.
    cd /d "%~dp0..\backend"
    call mvnw.cmd spring-boot:run
) else (
    echo.
    echo Environment variables are set. Start your backend manually with:
    echo   cd backend
    echo   mvnw.cmd spring-boot:run
    echo.
)

pause
