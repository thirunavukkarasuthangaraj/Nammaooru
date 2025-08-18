@echo off
echo ==========================================
echo  Manual Deploy to Hetzner
echo ==========================================
echo.

echo Building backend...
cd backend
call mvnw clean package -DskipTests
cd ..

echo Building frontend...
cd frontend
call npm run build
cd ..

echo Uploading to server...
scp backend\target\shop-management-backend-1.0.0.jar root@65.21.4.236:/opt/shop-management/app.jar
scp -r frontend\dist\shop-management-frontend\* root@65.21.4.236:/opt/shop-management/frontend/
scp frontend\nginx.conf root@65.21.4.236:/opt/shop-management/

echo Restarting containers...
ssh root@65.21.4.236 "cd /opt/shop-management && docker-compose down && docker-compose up -d"

echo.
echo ✅ Manual deployment complete!
echo Your app: http://65.21.4.236
pause