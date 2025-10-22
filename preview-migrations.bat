@echo off
REM ============================================
REM Preview Migration Files Before Deployment
REM Shows what will be deployed to production
REM ============================================

setlocal enabledelayedexpansion

echo.
echo ============================================
echo   MIGRATION FILES PREVIEW
echo ============================================
echo.

set MIGRATION_DIR=backend\src\main\resources\db\migration

if not exist "%MIGRATION_DIR%" (
    echo [ERROR] Migration directory not found: %MIGRATION_DIR%
    exit /b 1
)

REM Count files
set FILE_COUNT=0
for %%f in ("%MIGRATION_DIR%\V*.sql") do set /a FILE_COUNT+=1

echo [INFO] Found %FILE_COUNT% migration file(s) in:
echo        %MIGRATION_DIR%
echo.

if %FILE_COUNT% equ 0 (
    echo [INFO] No migration files to deploy
    echo.
    exit /b 0
)

echo ============================================
echo   MIGRATION FILES LIST
echo ============================================
echo.

set INDEX=1
for %%f in ("%MIGRATION_DIR%\V*.sql") do (
    echo [!INDEX!] %%~nxf
    set /a INDEX+=1
)

echo.
echo ============================================
echo   FILE CONTENTS PREVIEW
echo ============================================
echo.

for %%f in ("%MIGRATION_DIR%\V*.sql") do (
    echo.
    echo ╔════════════════════════════════════════════════════════════════
    echo ║ FILE: %%~nxf
    echo ╚════════════════════════════════════════════════════════════════
    echo.
    type "%%f"
    echo.
    echo ────────────────────────────────────────────────────────────────
    echo.
)

echo.
echo ============================================
echo   DEPLOYMENT PREVIEW COMPLETE
echo ============================================
echo.
echo These %FILE_COUNT% migration file(s) will be deployed
echo.
echo Next steps:
echo   1. Review the files above
echo   2. Verify they are correct
echo   3. Run: validate-migrations.bat
echo   4. If OK, deploy: git push
echo.

pause
