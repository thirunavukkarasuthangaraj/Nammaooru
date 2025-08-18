@echo off
echo ==========================================
echo  Upload Files to Hetzner (65.21.4.236)
echo ==========================================
echo.

echo Creating deployment package...

REM Copy docker-compose.yml
scp docker-compose.yml root@65.21.4.236:/opt/shop-management/

REM Copy backend JAR
scp backend/target/*.jar root@65.21.4.236:/opt/shop-management/

REM Copy frontend files
scp -r frontend/dist/shop-management-frontend root@65.21.4.236:/opt/shop-management/frontend/

REM Copy nginx config
scp frontend/nginx.conf root@65.21.4.236:/opt/shop-management/

echo.
echo ✅ Files uploaded!
echo.
echo Next: SSH to server and run docker-compose up -d
pause