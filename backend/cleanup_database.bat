@echo off
echo ========================================
echo Database Cleanup Script
echo This will remove ALL shops, products, and images!
echo ========================================
echo.

set /p confirm="Are you sure you want to clean all data? (yes/no): "
if /i not "%confirm%"=="yes" (
    echo Cleanup cancelled.
    pause
    exit /b
)

echo.
echo Starting database cleanup...
echo.

REM Execute the SQL cleanup script
REM Adjust the connection parameters below for your database setup

REM For PostgreSQL:
psql -U postgres -h localhost -d shop_management -f ../database_cleanup.sql

REM For MySQL (uncomment if using MySQL):
REM mysql -u root -p shop_management < ../database_cleanup.sql

echo.
echo ========================================
echo Cleanup completed!
echo Database is now ready for fresh data.
echo ========================================
pause