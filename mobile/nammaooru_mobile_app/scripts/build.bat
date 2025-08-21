@echo off
setlocal enabledelayedexpansion

:: NammaOoru Mobile App Build Script for Windows
:: This script automates the build process for different environments

:: Default values
set BUILD_TYPE=release
set PLATFORM=all
set CLEAN_BUILD=false
set RUN_TESTS=true
set ENVIRONMENT=production

:: Colors (if supported by terminal)
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "NC=[0m"

:: Function to print status messages
:print_status
echo %BLUE%[INFO]%NC% %~1
goto :eof

:print_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

:print_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:print_error
echo %RED%[ERROR]%NC% %~1
goto :eof

:show_usage
echo Usage: %0 [OPTIONS]
echo.
echo Options:
echo   -t, --type TYPE         Build type (debug^|profile^|release) [default: release]
echo   -p, --platform PLATFORM Platform (android^|ios^|all) [default: all]
echo   -c, --clean             Clean build (removes previous build artifacts)
echo   -s, --skip-tests        Skip running tests
echo   -e, --env ENVIRONMENT   Environment (development^|staging^|production) [default: production]
echo   -h, --help              Show this help message
echo.
echo Examples:
echo   %0 --type release --platform android
echo   %0 --clean --skip-tests
echo   %0 --env staging --type profile
goto :eof

:: Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="-t" set BUILD_TYPE=%~2& shift & shift & goto :parse_args
if "%~1"=="--type" set BUILD_TYPE=%~2& shift & shift & goto :parse_args
if "%~1"=="-p" set PLATFORM=%~2& shift & shift & goto :parse_args
if "%~1"=="--platform" set PLATFORM=%~2& shift & shift & goto :parse_args
if "%~1"=="-c" set CLEAN_BUILD=true& shift & goto :parse_args
if "%~1"=="--clean" set CLEAN_BUILD=true& shift & goto :parse_args
if "%~1"=="-s" set RUN_TESTS=false& shift & goto :parse_args
if "%~1"=="--skip-tests" set RUN_TESTS=false& shift & goto :parse_args
if "%~1"=="-e" set ENVIRONMENT=%~2& shift & shift & goto :parse_args
if "%~1"=="--env" set ENVIRONMENT=%~2& shift & shift & goto :parse_args
if "%~1"=="-h" call :show_usage & exit /b 0
if "%~1"=="--help" call :show_usage & exit /b 0
call :print_error "Unknown option: %~1"
call :show_usage
exit /b 1

:args_done

:: Main build process starts here
call %*
goto :main

:main
call :print_status "Starting NammaOoru Mobile App build process..."
call :print_status "Build Type: %BUILD_TYPE%"
call :print_status "Platform: %PLATFORM%"
call :print_status "Environment: %ENVIRONMENT%"
call :print_status "Clean Build: %CLEAN_BUILD%"

:: Validate build type
if not "%BUILD_TYPE%"=="debug" if not "%BUILD_TYPE%"=="profile" if not "%BUILD_TYPE%"=="release" (
    call :print_error "Invalid build type: %BUILD_TYPE%"
    exit /b 1
)

:: Validate platform
if not "%PLATFORM%"=="android" if not "%PLATFORM%"=="ios" if not "%PLATFORM%"=="all" (
    call :print_error "Invalid platform: %PLATFORM%"
    exit /b 1
)

:: Validate environment
if not "%ENVIRONMENT%"=="development" if not "%ENVIRONMENT%"=="staging" if not "%ENVIRONMENT%"=="production" (
    call :print_error "Invalid environment: %ENVIRONMENT%"
    exit /b 1
)

:: Check Flutter installation
flutter --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Flutter is not installed or not in PATH"
    exit /b 1
)

:: Check Flutter doctor
call :print_status "Checking Flutter doctor..."
flutter doctor --no-version-check

:: Navigate to project directory
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..
cd /d "%PROJECT_DIR%"

call :print_status "Project directory: %PROJECT_DIR%"

:: Clean build if requested
if "%CLEAN_BUILD%"=="true" (
    call :print_status "Cleaning previous build artifacts..."
    flutter clean
    
    :: Clean iOS pods if building for iOS
    if "%PLATFORM%"=="ios" (
        if exist "ios" (
            cd ios
            if exist "Pods" rmdir /s /q Pods
            if exist "Podfile.lock" del Podfile.lock
            cd ..
        )
    )
    if "%PLATFORM%"=="all" (
        if exist "ios" (
            cd ios
            if exist "Pods" rmdir /s /q Pods
            if exist "Podfile.lock" del Podfile.lock
            cd ..
        )
    )
    
    :: Clean Android build if building for Android
    if "%PLATFORM%"=="android" (
        if exist "android" (
            cd android
            gradlew.bat clean 2>nul
            cd ..
        )
    )
    if "%PLATFORM%"=="all" (
        if exist "android" (
            cd android
            gradlew.bat clean 2>nul
            cd ..
        )
    )
)

:: Get dependencies
call :print_status "Getting Flutter dependencies..."
flutter pub get

:: Run code generation if needed
findstr /c:"build_runner" pubspec.yaml >nul 2>&1
if not errorlevel 1 (
    call :print_status "Running code generation..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
)

:: Run tests if not skipped
if "%RUN_TESTS%"=="true" (
    call :print_status "Running tests..."
    flutter test
    if errorlevel 1 (
        call :print_warning "Some tests failed, but continuing with build..."
    )
)

:: Run static analysis
call :print_status "Running static analysis..."
flutter analyze
if errorlevel 1 (
    call :print_warning "Static analysis found issues, but continuing with build..."
)

:: Set environment variables based on environment
set DART_DEFINES=--dart-define=ENVIRONMENT=%ENVIRONMENT%

:: Build for Android
if "%PLATFORM%"=="android" goto :build_android
if "%PLATFORM%"=="all" goto :build_android
goto :check_ios

:build_android
call :print_status "Building Android app..."

:: Check Android SDK
if "%ANDROID_HOME%"=="" (
    call :print_warning "ANDROID_HOME not set. Make sure Android SDK is properly configured."
)

if "%BUILD_TYPE%"=="debug" (
    call :print_status "Building Android APK (Debug)..."
    flutter build apk --debug %DART_DEFINES%
) else if "%BUILD_TYPE%"=="profile" (
    call :print_status "Building Android APK (Profile)..."
    flutter build apk --profile %DART_DEFINES%
) else if "%BUILD_TYPE%"=="release" (
    call :print_status "Building Android App Bundle (Release)..."
    flutter build appbundle --release %DART_DEFINES%
    
    call :print_status "Building Android APK (Release)..."
    flutter build apk --release %DART_DEFINES%
)

if errorlevel 1 (
    call :print_error "Android build failed!"
    exit /b 1
) else (
    call :print_success "Android build completed successfully!"
    
    :: Show build outputs
    if "%BUILD_TYPE%"=="release" (
        call :print_status "Android App Bundle: build\app\outputs\bundle\release\app-release.aab"
        call :print_status "Android APK: build\app\outputs\flutter-apk\app-release.apk"
    ) else (
        call :print_status "Android APK: build\app\outputs\flutter-apk\app-%BUILD_TYPE%.apk"
    )
)

:check_ios
:: Build for iOS (Windows doesn't support iOS builds)
if "%PLATFORM%"=="ios" goto :ios_warning
if "%PLATFORM%"=="all" goto :ios_warning
goto :build_info

:ios_warning
call :print_warning "iOS builds are only supported on macOS. Skipping iOS build."
goto :build_info

:build_info
:: Generate build info
set BUILD_INFO_FILE=build_info.json
call :print_status "Generating build information..."

:: Get current timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%-%MM%-%DD%T%HH%:%Min%:%Sec%Z"

:: Get Flutter version
for /f "delims=" %%i in ('flutter --version 2^>nul ^| findstr "Flutter"') do set "flutter_version=%%i"

:: Get Git info if available
for /f "delims=" %%i in ('git rev-parse HEAD 2^>nul') do set "git_commit=%%i"
if not defined git_commit set "git_commit=unknown"

for /f "delims=" %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "git_branch=%%i"
if not defined git_branch set "git_branch=unknown"

:: Create build info JSON
(
echo {
echo   "buildTime": "%timestamp%",
echo   "buildType": "%BUILD_TYPE%",
echo   "platform": "%PLATFORM%",
echo   "environment": "%ENVIRONMENT%",
echo   "flutterVersion": "%flutter_version%",
echo   "gitCommit": "%git_commit%",
echo   "gitBranch": "%git_branch%"
echo }
) > "%BUILD_INFO_FILE%"

call :print_success "Build information saved to %BUILD_INFO_FILE%"

:: Performance suggestions
call :print_status "Build completed! Performance suggestions:"
echo   • Test the %BUILD_TYPE% build on physical devices
echo   • Monitor app size and performance metrics
echo   • Run integration tests on different device configurations

if "%BUILD_TYPE%"=="release" (
    echo   • Upload to internal testing before production release
    echo   • Update release notes and version information
)

call :print_success "NammaOoru Mobile App build process completed successfully!"
endlocal