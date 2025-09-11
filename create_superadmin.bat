@echo off
echo Creating Super Admin user...

REM Set PostgreSQL password
set PGPASSWORD=postgres

REM Create super admin with the credentials you provided
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -h localhost -p 5432 -U postgres -d shop_management_db -c "INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, mobile_verified, created_at, created_by, updated_at, updated_by) VALUES ('superadmin', 'thiruna2394@gmail.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Super', 'Admin', 'SUPER_ADMIN', 'ACTIVE', true, true, true, CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, 'SYSTEM') ON CONFLICT (email) DO UPDATE SET password = EXCLUDED.password, updated_at = CURRENT_TIMESTAMP;"

if %ERRORLEVEL% EQU 0 (
    echo Super Admin created successfully!
    echo Email: thiruna2394@gmail.com
    echo Password: Super@123
) else (
    echo Failed to create Super Admin!
    pause
    exit /b 1
)

pause