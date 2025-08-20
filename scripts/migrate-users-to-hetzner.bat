@echo off
REM Migration script for users table data from local to Hetzner Docker PostgreSQL
REM Usage: migrate-users-to-hetzner.bat <server_ip>

SET SERVER_IP=%1
SET SSH_USER=root

IF "%SERVER_IP%"=="" (
    echo Usage: migrate-users-to-hetzner.bat ^<server_ip^>
    echo Example: migrate-users-to-hetzner.bat 123.456.789.0
    exit /b 1
)

echo =========================================
echo   Migrating Users Data to Hetzner
echo =========================================

REM Check if export file exists
IF NOT EXIST "users_data_export.sql" (
    echo Error: users_data_export.sql not found!
    echo Exporting data now...
    "C:\Program Files\PostgreSQL\15\bin\pg_dump.exe" -U postgres -h localhost -p 5432 -d shop_management_db -t users --data-only --column-inserts > users_data_export.sql
)

echo Transferring data to server...
scp users_data_export.sql %SSH_USER%@%SERVER_IP%:/tmp/

echo Importing data into Docker PostgreSQL...
ssh %SSH_USER%@%SERVER_IP% "docker exec shop-postgres pg_dump -U postgres -d shop_management_db -t users --data-only > /tmp/users_backup_$(date +%%Y%%m%%d_%%H%%M%%S).sql 2>/dev/null; docker exec shop-postgres psql -U postgres -d shop_management_db -c 'TRUNCATE TABLE users CASCADE;'; docker cp /tmp/users_data_export.sql shop-postgres:/tmp/; docker exec shop-postgres psql -U postgres -d shop_management_db < /tmp/users_data_export.sql; docker exec shop-postgres psql -U postgres -d shop_management_db -c 'SELECT COUNT(*) as user_count FROM users;'; rm /tmp/users_data_export.sql; docker exec shop-postgres rm /tmp/users_data_export.sql"

echo.
echo Migration complete!
echo.
echo Note: Users have been migrated with their existing passwords.
echo Make sure your application JWT_SECRET matches between environments.