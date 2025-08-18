@echo off
echo ========================================
echo  Connect to Hetzner Server
echo ========================================
echo.

set /p SERVER_IP="Enter your Hetzner server IP: "

echo Connecting to %SERVER_IP%...
ssh -i "%USERPROFILE%\.ssh\hetzner_key" root@%SERVER_IP%

pause