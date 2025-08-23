@echo off
echo === Shop Management System Password Hash Generator ===
echo.
if "%~1"=="" (
    set /p password="Enter password: "
) else (
    set password=%~1
)

echo Generating BCrypt hash for: %password%
echo.

cd backend
mvn exec:java -Dexec.mainClass="com.shopmanagement.util.PasswordHashGenerator" -Dexec.args="%password%" -q

echo.
echo You can now copy the SQL command above and run it in your production database.
pause