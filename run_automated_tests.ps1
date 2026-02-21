# FlutterPOS Automated Test Runner
# Runs comprehensive test suite after Windows app launches

param(
    [string]$TestTarget = "all",
    [switch]$Verbose
)

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  FlutterPOS Automated Test Suite" -ForegroundColor Cyan
Write-Host "  Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"
$testResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
}

# Test categories aligned with Phase 2 verification
$testGroups = @{
    "Core Services" = @(
        "test/payment_service_test.dart",
        "test/pricing_test.dart",
        "test/receipt_generator_test.dart",
        "test/thermal_receipt_generator_test.dart",
        "test/table_service_test.dart",
        "test/shift_models_test.dart"
    )
    "Database Operations" = @(
        "test/save_completed_sale_test.dart",
        "test/test_database_service_test.dart",
        "test/database_service_import_test.dart"
    )
    "Business Logic" = @(
        "test/split_bill_logic_test.dart",
        "test/screen_totals_test.dart",
        "test/ui_totals_test.dart"
    )
    "Table Management" = @(
        "test/table_merge_test.dart",
        "test/table_persistence_merge_test.dart",
        "test/table_management_service_test.dart"
    )
    "E-Wallet & Payment" = @(
        "test/e_wallet_service_test.dart",
        "test/ewallet_webhook_service_test.dart"
    )
    "Reports" = @(
        "test/reports_dashboard_test.dart",
        "test/models/sales_report_test.dart"
    )
    "Widgets" = @(
        "test/widget/cart_item_widget_test.dart",
        "test/widget/product_card_test.dart",
        "test/widget/table_card_widget_test.dart"
    )
}

function Run-TestGroup {
    param($GroupName, $TestFiles)
    
    Write-Host ""
    Write-Host "──────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  Testing: $GroupName" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────" -ForegroundColor Yellow
    
    foreach ($testFile in $TestFiles) {
        if (Test-Path $testFile) {
            Write-Host "  → Running: $testFile" -ForegroundColor Gray
            
            $output = flutter test $testFile 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                Write-Host "    ✓ PASS" -ForegroundColor Green
                $testResults.Passed++
            } else {
                Write-Host "    ✗ FAIL" -ForegroundColor Red
                $testResults.Failed++
                if ($Verbose) {
                    Write-Host $output -ForegroundColor DarkRed
                }
            }
            $testResults.Total++
        } else {
            Write-Host "  ⊘ SKIP: $testFile (not found)" -ForegroundColor DarkGray
            $testResults.Skipped++
        }
    }
}

function Run-AllTests {
    Write-Host "Running ALL tests in test directory..." -ForegroundColor Cyan
    Write-Host ""
    
    $output = flutter test 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "✓ ALL TESTS PASSED" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ SOME TESTS FAILED" -ForegroundColor Red
        Write-Host $output
        return $false
    }
}

# Wait for Windows build if running
Write-Host "Checking if Windows app is running..." -ForegroundColor Cyan
$flutterProcess = Get-Process -Name "flutter" -ErrorAction SilentlyContinue
if ($flutterProcess) {
    Write-Host "Flutter build detected, waiting for completion..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# Run tests based on target
if ($TestTarget -eq "all") {
    $success = Run-AllTests
} elseif ($testGroups.ContainsKey($TestTarget)) {
    Run-TestGroup -GroupName $TestTarget -TestFiles $testGroups[$TestTarget]
} else {
    # Run all groups sequentially
    foreach ($group in $testGroups.Keys) {
        Run-TestGroup -GroupName $group -TestFiles $testGroups[$group]
    }
}

# Summary Report
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Total:   $($testResults.Total + $testResults.Skipped)" -ForegroundColor White
Write-Host "  Passed:  $($testResults.Passed)" -ForegroundColor Green
Write-Host "  Failed:  $($testResults.Failed)" -ForegroundColor Red
Write-Host "  Skipped: $($testResults.Skipped)" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan

# Calculate pass rate
if ($testResults.Total -gt 0) {
    $passRate = [math]::Round(($testResults.Passed / $testResults.Total) * 100, 1)
    Write-Host ""
    Write-Host "  Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })
}

# Exit with appropriate code
if ($testResults.Failed -gt 0) {
    exit 1
} else {
    exit 0
}
