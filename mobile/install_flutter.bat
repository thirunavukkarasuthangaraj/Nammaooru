@echo off
echo 🚀 Flutter Installation Helper for NammaOoru Project
echo =====================================================

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ Please run this script as Administrator
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

:: Check if Flutter directory exists
if exist "C:\flutter\bin\flutter.exe" (
    echo ✅ Flutter found at C:\flutter
    goto :add_to_path
) else (
    echo ❌ Flutter not found at C:\flutter
    echo.
    echo Please follow these steps:
    echo 1. Download Flutter from: https://docs.flutter.dev/get-started/install/windows
    echo 2. Extract the zip file to C:\flutter
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

:add_to_path
echo 📝 Adding Flutter to PATH...

:: Add Flutter to system PATH
for /f "skip=2 tokens=3*" %%a in ('reg query HKCU\Environment /v PATH') do set "currentPath=%%b"
echo %currentPath% | find "C:\flutter\bin" >nul
if %errorLevel% neq 0 (
    setx PATH "%currentPath%;C:\flutter\bin"
    echo ✅ Added C:\flutter\bin to PATH
) else (
    echo ℹ️ C:\flutter\bin already in PATH
)

echo.
echo 🔄 Please close and reopen your PowerShell/Command Prompt
echo Then run: flutter doctor
echo.
echo 📋 Next steps:
echo 1. Install Android Studio: https://developer.android.com/studio
echo 2. Install Visual Studio Community with C++ workload
echo 3. Run: flutter doctor --android-licenses
echo 4. Navigate to your project and run: flutter pub get
echo.
pause