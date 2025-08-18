@echo off
echo ==========================================
echo  Upload Files to Hetzner Server
echo ==========================================
echo.

set /p SERVER_IP="Enter your Hetzner server IP: "

echo.
echo Uploading files to %SERVER_IP%...
echo.

REM Create compressed archive
echo Creating deployment package...
tar -czf shop-deployment.tar.gz ^
    backend\src ^
    backend\pom.xml ^
    backend\Dockerfile.simple ^
    frontend\dist ^
    frontend\nginx.conf ^
    docker-compose.yml ^
    database\*.sql

echo Uploading to server...
scp -i "%USERPROFILE%\.ssh\hetzner_key" shop-deployment.tar.gz root@%SERVER_IP%:/opt/shop-management/

echo Extracting on server...
ssh -i "%USERPROFILE%\.ssh\hetzner_key" root@%SERVER_IP% "cd /opt/shop-management && tar -xzf shop-deployment.tar.gz"

echo.
echo ✅ Files uploaded successfully!
echo.
echo Next: Connect to server and run Docker
pause