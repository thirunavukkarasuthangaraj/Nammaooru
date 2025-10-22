@echo off
REM ============================================
REM Create Migration File (Organized by Year)
REM Automatically creates in year folder
REM ============================================

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: create-migration-organized.bat "Migration description"
    echo Example: create-migration-organized.bat "Add delivery fee column"
    exit /b 1
)

REM Get current year
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do (
    set YEAR=%%c
)

REM Migration directory with year folder
set MIGRATION_DIR=backend\src\main\resources\db\migration\%YEAR%

REM Create year folder if it doesn't exist
if not exist "%MIGRATION_DIR%" (
    echo Creating directory: %MIGRATION_DIR%
    mkdir "%MIGRATION_DIR%"
)

REM Find highest existing version number across ALL folders
set MAX_VERSION=0
for /f "delims=" %%f in ('dir /b /s backend\src\main\resources\db\migration\V*.sql 2^>nul') do (
    for /f "tokens=1 delims=_" %%v in ("%%~nf") do (
        set VERSION_STR=%%v
        set VERSION_STR=!VERSION_STR:V=!
        if !VERSION_STR! gtr !MAX_VERSION! (
            set MAX_VERSION=!VERSION_STR!
        )
    )
)

REM Calculate next version
set /a NEXT_VERSION=!MAX_VERSION!+1

REM Clean description (replace spaces with underscores)
set DESCRIPTION=%~1
set DESCRIPTION=%DESCRIPTION: =_%

REM Create filename
set FILENAME=V%NEXT_VERSION%__%DESCRIPTION%.sql
set FILEPATH=%MIGRATION_DIR%\%FILENAME%

REM Create file with template
echo -- Migration: %~1 > "%FILEPATH%"
echo -- Version: V%NEXT_VERSION% >> "%FILEPATH%"
echo -- Date: %date% >> "%FILEPATH%"
echo -- Year: %YEAR% >> "%FILEPATH%"
echo. >> "%FILEPATH%"
echo DO $$ >> "%FILEPATH%"
echo BEGIN >> "%FILEPATH%"
echo     IF NOT EXISTS ( >> "%FILEPATH%"
echo         SELECT 1 FROM information_schema.columns >> "%FILEPATH%"
echo         WHERE table_name = 'YOUR_TABLE' >> "%FILEPATH%"
echo         AND column_name = 'YOUR_COLUMN' >> "%FILEPATH%"
echo     ) THEN >> "%FILEPATH%"
echo         ALTER TABLE YOUR_TABLE ADD COLUMN YOUR_COLUMN TYPE; >> "%FILEPATH%"
echo         RAISE NOTICE 'Added YOUR_COLUMN to YOUR_TABLE'; >> "%FILEPATH%"
echo     ELSE >> "%FILEPATH%"
echo         RAISE NOTICE 'YOUR_COLUMN already exists in YOUR_TABLE, skipping'; >> "%FILEPATH%"
echo     END IF; >> "%FILEPATH%"
echo END $$; >> "%FILEPATH%"

echo.
echo ================================================
echo   Migration Created Successfully!
echo ================================================
echo   File: %FILENAME%
echo   Location: %MIGRATION_DIR%
echo   Year: %YEAR%
echo   Version: V%NEXT_VERSION%
echo ================================================
echo.
echo Next steps:
echo   1. Edit: %FILEPATH%
echo   2. Replace: YOUR_TABLE, YOUR_COLUMN, TYPE
echo   3. Test: mvn spring-boot:run
echo   4. Preview: preview-migrations.bat
echo   5. Validate: validate-migrations.bat
echo   6. Commit: git add %FILEPATH%
echo.

REM Open file in default editor
start "" "%FILEPATH%"
