@echo off
REM ============================================
REM Migration Validation Script (Windows)
REM Validates migration files before deployment
REM ============================================

setlocal enabledelayedexpansion

echo.
echo ============================================
echo   DATABASE MIGRATION VALIDATION
echo ============================================
echo.

set MIGRATION_DIR=backend\src\main\resources\db\migration
set ERROR_COUNT=0
set WARNING_COUNT=0

REM Check if migration directory exists
if not exist "%MIGRATION_DIR%" (
    echo [ERROR] Migration directory not found: %MIGRATION_DIR%
    exit /b 1
)

echo [INFO] Checking migrations in: %MIGRATION_DIR%
echo.

REM Count migration files
set FILE_COUNT=0
for %%f in ("%MIGRATION_DIR%\V*.sql") do set /a FILE_COUNT+=1

if %FILE_COUNT% equ 0 (
    echo [WARNING] No migration files found
    set /a WARNING_COUNT+=1
) else (
    echo [INFO] Found %FILE_COUNT% migration files
)

echo.
echo ============================================
echo   VALIDATION CHECKS
echo ============================================
echo.

REM Check 1: Migration file naming convention
echo [CHECK 1] Validating file naming convention...
for %%f in ("%MIGRATION_DIR%\V*.sql") do (
    set filename=%%~nxf
    echo !filename! | findstr /R "^V[0-9][0-9]*__.*\.sql$" >nul
    if errorlevel 1 (
        echo   [ERROR] Invalid naming: %%~nxf
        echo           Expected: V{number}__{description}.sql
        set /a ERROR_COUNT+=1
    )
)
if %ERROR_COUNT% equ 0 echo   [PASS] All files follow naming convention
echo.

REM Check 2: Check for duplicate version numbers
echo [CHECK 2] Checking for duplicate version numbers...
set PREV_VERSION=0
for /f "tokens=1 delims=_" %%v in ('dir /b /on "%MIGRATION_DIR%\V*.sql"') do (
    set VERSION_NUM=%%v
    set VERSION_NUM=!VERSION_NUM:V=!
    if !VERSION_NUM! leq !PREV_VERSION! (
        echo   [ERROR] Duplicate or out-of-order version: %%v
        set /a ERROR_COUNT+=1
    )
    set PREV_VERSION=!VERSION_NUM!
)
if %ERROR_COUNT% equ 0 echo   [PASS] No duplicate versions found
echo.

REM Check 3: Check for safe SQL patterns
echo [CHECK 3] Checking for safe SQL patterns...
for %%f in ("%MIGRATION_DIR%\V*.sql") do (
    findstr /I /C:"IF NOT EXISTS" /C:"IF EXISTS" /C:"CREATE TABLE IF NOT EXISTS" "%%f" >nul
    if errorlevel 1 (
        echo   [WARNING] %%~nxf may not have IF NOT EXISTS check
        set /a WARNING_COUNT+=1
    )
)
echo   [INFO] Safe SQL pattern check complete
echo.

REM Check 4: Check for dangerous operations
echo [CHECK 4] Checking for dangerous operations...
for %%f in ("%MIGRATION_DIR%\V*.sql") do (
    findstr /I /C:"DROP TABLE" /C:"TRUNCATE" "%%f" >nul
    if not errorlevel 1 (
        echo   [WARNING] %%~nxf contains potentially dangerous operation
        set /a WARNING_COUNT+=1
    )
)
if %WARNING_COUNT% equ 0 echo   [PASS] No dangerous operations detected
echo.

REM Check 5: Check for transaction blocks
echo [CHECK 5] Verifying transaction safety...
for %%f in ("%MIGRATION_DIR%\V*.sql") do (
    set HAS_DO_BLOCK=0
    findstr /I /C:"DO $$" "%%f" >nul
    if not errorlevel 1 set HAS_DO_BLOCK=1

    if !HAS_DO_BLOCK! equ 0 (
        echo   [INFO] %%~nxf: No DO block (may be simple DDL)
    )
)
echo   [INFO] Transaction safety check complete
echo.

REM Summary
echo ============================================
echo   VALIDATION SUMMARY
echo ============================================
echo   Migration files: %FILE_COUNT%
echo   Errors: %ERROR_COUNT%
echo   Warnings: %WARNING_COUNT%
echo ============================================
echo.

if %ERROR_COUNT% gtr 0 (
    echo [FAILED] Validation failed with %ERROR_COUNT% error(s)
    echo Please fix the errors before deploying
    exit /b 1
)

if %WARNING_COUNT% gtr 0 (
    echo [WARNING] Validation passed with %WARNING_COUNT% warning(s)
    echo Review warnings before deploying
    exit /b 0
)

echo [SUCCESS] All validations passed!
exit /b 0
