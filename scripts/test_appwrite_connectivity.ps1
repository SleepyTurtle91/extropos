# Appwrite Connectivity Test Runner
# 
# This script helps run Appwrite connectivity tests in different modes
#
# Usage:
#   .\scripts\test_appwrite_connectivity.ps1 [mode]
#
# Modes:
#   test     - Run in test mode (no real backend, fast)
#   real     - Run with real Appwrite connection (requires backend)
#   all      - Run both modes

param(
    [Parameter(Position=0)]
    [ValidateSet('test', 'real', 'all')]
    [string]$Mode = 'test'
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Appwrite Connectivity Test Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Run-TestMode {
    Write-Host "🟢 Running in TEST MODE (no real backend)" -ForegroundColor Green
    Write-Host ""
    
    flutter test test/integration/appwrite_connectivity_test.dart --reporter expanded
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ TEST MODE: All tests passed!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ TEST MODE: Some tests failed" -ForegroundColor Red
    }
}

function Run-RealMode {
    Write-Host "🔴 Running in REAL APPWRITE MODE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Prerequisites:" -ForegroundColor Yellow
    Write-Host "  ✓ Appwrite instance at https://appwrite.extropos.org/v1" -ForegroundColor Yellow
    Write-Host "  ✓ Project ID: 6940a64500383754a37f" -ForegroundColor Yellow
    Write-Host "  ✓ Database: pos_db" -ForegroundColor Yellow
    Write-Host "  ✓ Collections: backend_users, roles, activity_logs, inventory_items" -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Continue with real backend testing? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Cancelled by user" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true --reporter expanded
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ REAL MODE: All tests passed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Backend Status: HEALTHY ✅" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ REAL MODE: Some tests failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "Backend Status: ISSUES DETECTED ⚠️" -ForegroundColor Red
    }
}

# Execute based on mode
switch ($Mode) {
    'test' {
        Run-TestMode
    }
    'real' {
        Run-RealMode
    }
    'all' {
        Run-TestMode
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Run-RealMode
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test execution complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
