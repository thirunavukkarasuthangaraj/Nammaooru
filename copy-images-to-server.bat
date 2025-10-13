@echo off
REM Batch Script to Copy Local Images to Production Server
REM Usage: copy-images-to-server.bat

echo ========================================
echo   Copy Images to Production Server
echo ========================================
echo.

set LOCAL_UPLOADS=D:\AAWS\nammaooru\uploads
set SERVER_USER=root
set SERVER_HOST=65.21.4.236
set SERVER_PATH=/opt/shop-management/uploads

REM Check if local uploads folder exists
if not exist "%LOCAL_UPLOADS%" (
    echo Error: Local uploads folder not found: %LOCAL_UPLOADS%
    pause
    exit /b 1
)

echo Local uploads folder: %LOCAL_UPLOADS%
echo Server: %SERVER_USER%@%SERVER_HOST%:%SERVER_PATH%
echo.

echo Counting files...
dir /s /b "%LOCAL_UPLOADS%\*" | find /c "\" > temp_count.txt
set /p FILE_COUNT=<temp_count.txt
del temp_count.txt
echo Files to copy: %FILE_COUNT%
echo.

set /p CONFIRM=Do you want to proceed with copying? (yes/no):
if /i not "%CONFIRM%"=="yes" (
    echo Operation cancelled
    pause
    exit /b 0
)

echo.
echo Starting file copy...
echo.

REM Method 1: Using SCP (requires OpenSSH)
echo Method 1: Using SCP command...
echo Command: scp -r "%LOCAL_UPLOADS%\*" %SERVER_USER%@%SERVER_HOST%:%SERVER_PATH%/
echo.

scp -r "%LOCAL_UPLOADS%\*" %SERVER_USER%@%SERVER_HOST%:%SERVER_PATH%/

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   Files copied successfully!
    echo ========================================
    echo.
    echo Verification steps:
    echo 1. SSH to server: ssh %SERVER_USER%@%SERVER_HOST%
    echo 2. Check files: ls -la %SERVER_PATH%
    echo 3. Count files: find %SERVER_PATH% -type f ^| wc -l
    echo 4. Check size: du -sh %SERVER_PATH%
    echo.
) else (
    echo.
    echo ========================================
    echo   Error copying files
    echo ========================================
    echo.
    echo Troubleshooting:
    echo 1. Ensure SSH key is configured
    echo 2. Check if OpenSSH is installed
    echo 3. Try using WinSCP or FileZilla instead
    echo.
    echo Alternative: Use PowerShell script
    echo   powershell -ExecutionPolicy Bypass -File copy-images-to-server.ps1
    echo.
)

pause
