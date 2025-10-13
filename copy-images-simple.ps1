# Simple PowerShell Script to Copy Images to Server

$LOCAL_UPLOADS = "D:\AAWS\nammaooru\uploads"
$SERVER = "root@65.21.4.236"
$SERVER_PATH = "/opt/shop-management/uploads"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Copy Images to Production Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Local folder: $LOCAL_UPLOADS" -ForegroundColor Green
Write-Host "Server: $SERVER" -ForegroundColor Green
Write-Host "Destination: $SERVER_PATH" -ForegroundColor Green
Write-Host ""

# Count files
$fileCount = (Get-ChildItem -Path $LOCAL_UPLOADS -Recurse -File).Count
$folderSize = (Get-ChildItem -Path $LOCAL_UPLOADS -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host "Files to copy: $fileCount" -ForegroundColor Yellow
Write-Host "Total size: $([math]::Round($folderSize, 2)) MB" -ForegroundColor Yellow
Write-Host ""

Write-Host "STEP 1: Creating directory on server..." -ForegroundColor Cyan
Write-Host "Command: ssh $SERVER 'mkdir -p $SERVER_PATH && chmod -R 755 $SERVER_PATH'" -ForegroundColor Gray
Write-Host ""
Write-Host "You will be prompted for your server password..." -ForegroundColor Yellow
Write-Host ""

ssh $SERVER "mkdir -p $SERVER_PATH && chmod -R 755 $SERVER_PATH && echo 'Directory created successfully!'"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Directory created!" -ForegroundColor Green
    Write-Host ""

    Write-Host "STEP 2: Copying files..." -ForegroundColor Cyan
    Write-Host "This may take a few minutes..." -ForegroundColor Yellow
    Write-Host ""

    # Change to uploads parent directory
    Set-Location "D:\AAWS\nammaooru"

    # Copy files
    & scp -r "uploads/*" "${SERVER}:${SERVER_PATH}/"

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Files copied successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Verification:" -ForegroundColor Cyan
        Write-Host "Run this command to verify: ssh $SERVER 'ls -la $SERVER_PATH'" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "❌ Error copying files" -ForegroundColor Red
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "❌ Error creating directory on server" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "1. Server is accessible: ping 65.21.4.236" -ForegroundColor Gray
    Write-Host "2. SSH works: ssh $SERVER" -ForegroundColor Gray
    Write-Host "3. You entered the correct password" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Script completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
