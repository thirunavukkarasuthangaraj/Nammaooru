# Check Production Server Status
# Run this script to verify deployment status and CORS fix

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Production Server Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$server = "root@65.21.4.236"

Write-Host "[1/4] Checking containers..." -ForegroundColor Yellow
ssh $server "docker ps --format 'table {{.Names}}\t{{.Status}}'"

Write-Host ""
Write-Host "[2/4] Checking backend logs (last 10 lines)..." -ForegroundColor Yellow
ssh $server "docker logs nammaooru-backend --tail 10 2>&1"

Write-Host ""
Write-Host "[3/4] Testing CORS headers..." -ForegroundColor Yellow
$corsHeaders = curl -I -X OPTIONS https://api.nammaoorudelivary.in/api/auth/login `
  -H "Origin: https://nammaoorudelivary.in" `
  -H "Access-Control-Request-Method: POST" 2>&1 | Select-String "access-control"

Write-Host $corsHeaders

$headerCount = ($corsHeaders | Measure-Object).Count
if ($headerCount -le 4) {
    Write-Host "`n✅ CORS FIX SUCCESSFUL! Only ONE set of CORS headers found" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  WARNING: Still seeing duplicate CORS headers ($headerCount headers)" -ForegroundColor Red
}

Write-Host ""
Write-Host "[4/4] Testing login endpoint..." -ForegroundColor Yellow
try {
    $response = curl -X POST "https://api.nammaoorudelivary.in/api/auth/login" `
      -H "Content-Type: application/json" `
      -H "Origin: https://nammaoorudelivary.in" `
      -d "{`"email`":`"test@test.com`",`"password`":`"test123`"}" 2>&1

    if ($response -match "502") {
        Write-Host "❌ Backend not responding yet (502 error)" -ForegroundColor Yellow
        Write-Host "Wait 2-3 minutes for backend to fully start, then run this script again" -ForegroundColor Yellow
    } elseif ($response -match "401\|400") {
        Write-Host "✅ Backend is responding! (Invalid credentials is OK for this test)" -ForegroundColor Green
    } else {
        Write-Host $response
    }
} catch {
    Write-Host "Error testing endpoint: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Status Check Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
