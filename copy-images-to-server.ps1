# PowerShell Script to Copy Local Images to Production Server
# Usage: .\copy-images-to-server.ps1

$LOCAL_UPLOADS = "D:\AAWS\nammaooru\uploads"
$SERVER_USER = "root"
$SERVER_HOST = "65.21.4.236"
$SERVER_PATH = "/opt/shop-management/uploads"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Copy Images to Production Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if local uploads folder exists
if (-not (Test-Path $LOCAL_UPLOADS)) {
    Write-Host "❌ Error: Local uploads folder not found: $LOCAL_UPLOADS" -ForegroundColor Red
    exit 1
}

# Count files to copy
$fileCount = (Get-ChildItem -Path $LOCAL_UPLOADS -Recurse -File).Count
$folderSize = (Get-ChildItem -Path $LOCAL_UPLOADS -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host "📁 Local uploads folder: $LOCAL_UPLOADS" -ForegroundColor Green
Write-Host "📊 Files to copy: $fileCount" -ForegroundColor Yellow
Write-Host "💾 Total size: $([math]::Round($folderSize, 2)) MB" -ForegroundColor Yellow
Write-Host ""

# Confirm before proceeding
$confirm = Read-Host "Do you want to proceed with copying? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "❌ Operation cancelled" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "🚀 Starting file copy..." -ForegroundColor Cyan
Write-Host ""

# Use SCP to copy files (requires OpenSSH installed on Windows)
Write-Host "📤 Copying files using SCP..." -ForegroundColor Green
Write-Host "Command: scp -r $LOCAL_UPLOADS/* ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/" -ForegroundColor Gray
Write-Host ""

# Execute SCP command
$scpCommand = "scp -r `"$LOCAL_UPLOADS\*`" ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/"
Write-Host "Executing: $scpCommand" -ForegroundColor Gray

try {
    # Execute SCP
    & cmd /c "scp -r `"$LOCAL_UPLOADS\*`" ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/"

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Files copied successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔍 Verification steps:" -ForegroundColor Cyan
        Write-Host "1. SSH to server: ssh $SERVER_USER@$SERVER_HOST" -ForegroundColor Yellow
        Write-Host "2. Check files: ls -la $SERVER_PATH" -ForegroundColor Yellow
        Write-Host "3. Count files: find $SERVER_PATH -type f | wc -l" -ForegroundColor Yellow
        Write-Host "4. Check size: du -sh $SERVER_PATH" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "❌ Error copying files (Exit code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 Troubleshooting:" -ForegroundColor Yellow
        Write-Host "1. Ensure SSH key is configured: ssh $SERVER_USER@$SERVER_HOST" -ForegroundColor Gray
        Write-Host "2. Check if OpenSSH is installed: Get-WindowsCapability -Online | ? Name -like 'OpenSSH*'" -ForegroundColor Gray
        Write-Host "3. Install if needed: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor Gray
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Alternative method using WinSCP or FileZilla:" -ForegroundColor Yellow
    Write-Host "1. Download WinSCP from https://winscp.net" -ForegroundColor Gray
    Write-Host "2. Connect to: $SERVER_HOST (user: $SERVER_USER)" -ForegroundColor Gray
    Write-Host "3. Navigate to: $SERVER_PATH" -ForegroundColor Gray
    Write-Host "4. Upload folder: $LOCAL_UPLOADS" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Script completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
