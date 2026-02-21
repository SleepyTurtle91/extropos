# FlutterPOS Build Monitor & Auto Test Launcher
# Monitors Windows build completion and triggers automated tests

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  FlutterPOS Build Monitor & Auto Tester" -ForegroundColor Cyan
Write-Host "  Waiting for Windows build to complete..." -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$buildInProgress = $true
$checkInterval = 5  # seconds
$maxWaitTime = 600  # 10 minutes
$elapsedTime = 0

# Monitor build process
while ($buildInProgress -and $elapsedTime -lt $maxWaitTime) {
    # Check if Flutter Windows app is running
    $flutterApp = Get-Process -Name "extropos" -ErrorAction SilentlyContinue
    
    if ($flutterApp) {
        Write-Host "✓ Windows app detected running!" -ForegroundColor Green
        Write-Host "  PID: $($flutterApp.Id)" -ForegroundColor Gray
        Write-Host "  Memory: $([math]::Round($flutterApp.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Gray
        $buildInProgress = $false
        break
    }
    
    # Check if build is still active
    $gradleProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue | 
                     Where-Object { $_.CommandLine -like "*gradle*" }
    
    if ($gradleProcess) {
        Write-Host "." -NoNewline -ForegroundColor Yellow
        Start-Sleep -Seconds $checkInterval
        $elapsedTime += $checkInterval
    } else {
        # Check one more time for the app
        Start-Sleep -Seconds 2
        $flutterApp = Get-Process -Name "extropos" -ErrorAction SilentlyContinue
        if ($flutterApp) {
            Write-Host "✓ Windows app detected!" -ForegroundColor Green
            $buildInProgress = $false
        } else {
            Write-Host "⚠ Build may have completed but app not detected" -ForegroundColor Yellow
            $buildInProgress = $false
        }
    }
}

Write-Host ""

if ($elapsedTime -ge $maxWaitTime) {
    Write-Host "⚠ Build monitor timeout reached" -ForegroundColor Yellow
    Write-Host "Proceeding with tests anyway..." -ForegroundColor Gray
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Starting Automated Test Suite" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Run the automated test suite
& "$PSScriptRoot\run_automated_tests.ps1" -TestTarget "all" -Verbose

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Testing Complete!" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
