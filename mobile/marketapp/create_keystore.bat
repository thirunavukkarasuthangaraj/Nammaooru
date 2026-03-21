@echo off
REM Generate Android signing keystore for NammaOoru Customer App
REM Save this file and run it once to create your keystore

echo ================================================
echo   NammaOoru Customer App - Keystore Generator
echo ================================================
echo.

REM Navigate to android folder
cd android\app

echo Creating keystore...
echo.
echo You will be asked for:
echo   1. Keystore password (remember this!)
echo   2. Key password (can be same as keystore password)
echo   3. Your name
echo   4. Organization: NammaOoru
echo   5. City, State, Country
echo.

keytool -genkey -v -keystore nammaooru-customer-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nammaooru-customer

echo.
echo ================================================
echo   Keystore created successfully!
echo ================================================
echo.
echo Location: android\app\nammaooru-customer-release-key.jks
echo.
echo IMPORTANT:
echo   1. Keep this keystore file safe
echo   2. Remember your passwords
echo   3. Never commit to git
echo   4. Make a backup
echo.

cd ..\..
pause
