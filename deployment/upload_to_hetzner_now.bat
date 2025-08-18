@echo off
echo ==========================================
echo  Uploading Files to Hetzner Server
echo ==========================================
echo.

echo Uploading backend JAR...
scp backend\target\shop-management-0.0.1-SNAPSHOT.jar root@65.21.4.236:/opt/shop-management/app.jar

echo Uploading frontend files...
scp -r frontend\dist\shop-management-frontend\* root@65.21.4.236:/opt/shop-management/frontend/

echo Uploading nginx config...
scp frontend\nginx.conf root@65.21.4.236:/opt/shop-management/

echo Uploading database files...
scp database\schema.sql root@65.21.4.236:/opt/shop-management/
scp database\init.sql root@65.21.4.236:/opt/shop-management/

echo.
echo ✅ Files uploaded successfully!
echo.
echo Now go back to server and run: docker-compose up -d
pause