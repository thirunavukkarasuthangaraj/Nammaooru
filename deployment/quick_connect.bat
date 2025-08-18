@echo off
echo ==========================================
echo  Quick Connect to Hetzner Server
echo ==========================================
echo.
echo Your server IP: 65.21.4.236
echo.

REM Try to connect with password first (since no SSH key was added)
echo Connecting to your Hetzner server...
echo.
echo NOTE: You'll need to enter the root password
echo (Check your email from Hetzner for the root password)
echo.

ssh root@65.21.4.236

pause