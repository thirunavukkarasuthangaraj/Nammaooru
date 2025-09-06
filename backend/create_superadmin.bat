@echo off
echo Creating/Updating Superadmin User...
echo.

echo Step 1: Reset superadmin password...
curl -X POST http://localhost:8082/api/test/reset-superadmin-password
echo.
echo.

echo Step 2: Testing login with different email combinations...
echo Trying superadmin@shopmanagement.com...
curl -X POST -H "Content-Type: application/json" -d "{\"email\":\"superadmin@shopmanagement.com\",\"password\":\"password\"}" http://localhost:8082/api/auth/login
echo.
echo.

echo Trying superadmin@example.com...
curl -X POST -H "Content-Type: application/json" -d "{\"email\":\"superadmin@example.com\",\"password\":\"password\"}" http://localhost:8082/api/auth/login
echo.
echo.

echo Trying admin@shopmanagement.com with superadmin credentials...
curl -X POST -H "Content-Type: application/json" -d "{\"email\":\"admin@shopmanagement.com\",\"password\":\"password\"}" http://localhost:8082/api/auth/login
echo.
echo.

echo Checking admin user for pattern...
curl -X GET http://localhost:8082/api/test/check-admin
echo.
echo.

echo Done! Check the responses above for working superadmin credentials.
pause