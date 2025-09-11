@echo off
echo ========================================
echo Image Files Cleanup Script
echo This will remove ALL uploaded product and shop images!
echo ========================================
echo.

set /p confirm="Are you sure you want to delete all image files? (yes/no): "
if /i not "%confirm%"=="yes" (
    echo Image cleanup cancelled.
    pause
    exit /b
)

echo.
echo Cleaning up image directories...
echo.

REM Remove all product images
if exist "uploads\products\master" (
    echo Removing master product images...
    rmdir /s /q "uploads\products\master"
    mkdir "uploads\products\master"
)

if exist "uploads\products\shop" (
    echo Removing shop product images...
    rmdir /s /q "uploads\products\shop"
    mkdir "uploads\products\shop"
)

REM Remove all shop images
if exist "uploads\shops" (
    echo Removing shop images...
    rmdir /s /q "uploads\shops"
    mkdir "uploads\shops"
)

REM Remove any other image directories
if exist "uploads\temp" (
    echo Removing temporary images...
    rmdir /s /q "uploads\temp"
    mkdir "uploads\temp"
)

echo.
echo ========================================
echo Image cleanup completed!
echo All image directories have been cleared.
echo ========================================
pause