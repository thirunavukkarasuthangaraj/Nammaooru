@echo off
REM Automated Database Migration Creator
REM Usage: create-migration.bat "Add user status column"

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Error: Please provide a migration description
    echo Usage: create-migration.bat "Your migration description"
    echo Example: create-migration.bat "Add user status column"
    exit /b 1
)

REM Get migration description from argument
set "DESCRIPTION=%~1"

REM Replace spaces with underscores
set "DESCRIPTION=!DESCRIPTION: =_!"

REM Find the highest version number
set MAX_VERSION=0
for /f "tokens=1 delims=_" %%a in ('dir /b backend\src\main\resources\db\migration\V*.sql 2^>nul') do (
    set "VERSION=%%a"
    set "VERSION=!VERSION:~1!"
    if !VERSION! GTR !MAX_VERSION! set MAX_VERSION=!VERSION!
)

REM Calculate next version
set /a NEXT_VERSION=!MAX_VERSION!+1

REM Create filename
set "FILENAME=V!NEXT_VERSION!__!DESCRIPTION!.sql"
set "FILEPATH=backend\src\main\resources\db\migration\!FILENAME!"

REM Create the migration file with template
echo -- Migration: !DESCRIPTION! > "!FILEPATH!"
echo -- Version: V!NEXT_VERSION! >> "!FILEPATH!"
echo -- Created: %DATE% %TIME% >> "!FILEPATH!"
echo -- >> "!FILEPATH!"
echo -- TODO: Add your SQL statements below >> "!FILEPATH!"
echo. >> "!FILEPATH!"
echo -- Example: >> "!FILEPATH!"
echo -- ALTER TABLE users ADD COLUMN status VARCHAR(50); >> "!FILEPATH!"
echo. >> "!FILEPATH!"

echo.
echo ============================================
echo ✅ Migration file created successfully!
echo ============================================
echo.
echo File: !FILENAME!
echo Location: !FILEPATH!
echo.
echo Next steps:
echo 1. Edit the file and add your SQL
echo 2. Run backend to test locally
echo 3. git add !FILEPATH!
echo 4. git commit -m "Migration: !DESCRIPTION!"
echo 5. git push (CI/CD will auto-apply to production)
echo.
echo Opening file in notepad...
echo.

REM Open the file in default editor
start notepad "!FILEPATH!"

endlocal
