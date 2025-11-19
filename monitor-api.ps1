# API Uptime Monitor - Calls API every second
# Tests zero-downtime deployment

$apiUrl = "https://api.nammaoorudelivary.in/api/version"
$successCount = 0
$failCount = 0
$startTime = Get-Date

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  API UPTIME MONITOR - Zero Downtime Test" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Testing: $apiUrl" -ForegroundColor White
Write-Host "Interval: 1 second" -ForegroundColor White
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

while ($true) {
    $timestamp = Get-Date -Format "HH:mm:ss"

    try {
        # Call API and measure response time
        $start = Get-Date
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 5
        $end = Get-Date
        $responseTime = ($end - $start).TotalMilliseconds

        # Extract version
        $version = $response.data.version
        $successCount++

        # Calculate uptime percentage
        $totalRequests = $successCount + $failCount
        $uptimePercent = [math]::Round(($successCount / $totalRequests) * 100, 2)

        Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
        Write-Host "✅ SUCCESS" -NoNewline -ForegroundColor Green
        Write-Host " | HTTP 200 | Version: " -NoNewline -ForegroundColor White
        Write-Host "$version" -NoNewline -ForegroundColor Cyan
        Write-Host " | Response: " -NoNewline -ForegroundColor White
        Write-Host "$([math]::Round($responseTime))ms" -NoNewline -ForegroundColor Yellow
        Write-Host " | Uptime: " -NoNewline -ForegroundColor White
        Write-Host "$uptimePercent%" -NoNewline -ForegroundColor Green
        Write-Host " ($successCount/$totalRequests)" -ForegroundColor Gray
    }
    catch {
        $failCount++
        $totalRequests = $successCount + $failCount
        $uptimePercent = if ($totalRequests -gt 0) { [math]::Round(($successCount / $totalRequests) * 100, 2) } else { 0 }

        Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
        Write-Host "❌ FAILED" -NoNewline -ForegroundColor Red
        Write-Host " | Error: $($_.Exception.Message)" -NoNewline -ForegroundColor Red
        Write-Host " | Uptime: " -NoNewline -ForegroundColor White
        Write-Host "$uptimePercent%" -NoNewline -ForegroundColor Red
        Write-Host " (Failures: $failCount)" -ForegroundColor Gray
    }

    Start-Sleep -Seconds 1
}
