# Run Appwrite Cloud Automation Setup as Administrator
# This script re-launches itself with admin privileges if needed

param(
    [ValidateSet('install', 'test', 'status', 'uninstall')]
    [string]$Action = 'install'
)

# Check if running as admin
$isAdmin = [bool]([System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "⚠️  This script requires Administrator privileges" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Requesting elevation..." -ForegroundColor Cyan
    Write-Host ""
    
    # Re-run this script as admin
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-NoExit -Command & {$scriptPath -Action $Action}"
    
    try {
        Start-Process powershell -ArgumentList $arguments -Verb RunAs -WindowStyle Normal
        exit 0
    } catch {
        Write-Host "❌ Failed to elevate privileges" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}

# If we get here, we're running as admin
Write-Host ""
Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Change to docker directory
Set-Location E:\flutterpos\docker

# Run setup-automation.ps1 with specified action
Write-Host "Running: .\setup-automation.ps1 -Action $Action" -ForegroundColor Cyan
Write-Host ""

try {
    & .\setup-automation.ps1 -Action $Action
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Setup completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Verify tasks in Task Scheduler: Win+R → taskschd.msc" -ForegroundColor Cyan
        Write-Host "  2. Test backup: .\backup-cloud-storage.ps1" -ForegroundColor Cyan
        Write-Host "  3. Configure alerts (optional): .\setup-alerts.ps1 -Action configure" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Setup failed with error:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    exit 1
}
