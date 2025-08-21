# Flutter Setup Script for Windows
# Run this script as Administrator

param(
    [string]$FlutterPath = "C:\flutter"
)

Write-Host "🚀 Setting up Flutter for NammaOoru Mobile App Development" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script needs to be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Function to add to PATH
function Add-ToPath {
    param([string]$PathToAdd)
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$PathToAdd*") {
        $newPath = $currentPath + ";" + $PathToAdd
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "✅ Added $PathToAdd to PATH" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  $PathToAdd already in PATH" -ForegroundColor Yellow
    }
}

# Check if Flutter is already installed
if (Test-Path "$FlutterPath\bin\flutter.exe") {
    Write-Host "✅ Flutter found at $FlutterPath" -ForegroundColor Green
    Add-ToPath "$FlutterPath\bin"
} else {
    Write-Host "❌ Flutter not found at $FlutterPath" -ForegroundColor Red
    Write-Host "Please download Flutter from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    Write-Host "Extract it to: $FlutterPath" -ForegroundColor Yellow
    exit 1
}

# Check if Git is installed
try {
    git --version | Out-Null
    Write-Host "✅ Git is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Git not found" -ForegroundColor Red
    Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Run Flutter doctor
Write-Host "`n🔍 Running Flutter doctor..." -ForegroundColor Blue
try {
    flutter doctor
} catch {
    Write-Host "❌ Flutter command not found. Please restart PowerShell and try again." -ForegroundColor Red
    exit 1
}

Write-Host "`n📱 Setting up NammaOoru project..." -ForegroundColor Blue

# Navigate to project directory
$projectPath = "D:\AAWS\nammaooru\shop-management-system\mobile\nammaooru_mobile_app"
if (Test-Path $projectPath) {
    Set-Location $projectPath
    Write-Host "✅ Found NammaOoru project at: $projectPath" -ForegroundColor Green
    
    # Get Flutter dependencies
    Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Blue
    flutter pub get
    
    Write-Host "`n🎉 Setup complete!" -ForegroundColor Green
    Write-Host "You can now run the app with: flutter run" -ForegroundColor Yellow
    Write-Host "Make sure you have an Android emulator running or device connected" -ForegroundColor Yellow
} else {
    Write-Host "❌ NammaOoru project not found at: $projectPath" -ForegroundColor Red
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Blue
Write-Host "1. Install Android Studio from: https://developer.android.com/studio" -ForegroundColor White
Write-Host "2. Set up an Android emulator or connect a physical device" -ForegroundColor White
Write-Host "3. Run 'flutter doctor' to check for any remaining issues" -ForegroundColor White
Write-Host "4. Run 'flutter run' to start the NammaOoru app" -ForegroundColor White

Write-Host "`n🔗 Useful Links:" -ForegroundColor Blue
Write-Host "Flutter Docs: https://docs.flutter.dev" -ForegroundColor Cyan
Write-Host "Android Studio: https://developer.android.com/studio" -ForegroundColor Cyan
Write-Host "NammaOoru Project: $projectPath" -ForegroundColor Cyan