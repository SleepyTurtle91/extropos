#Requires -Version 5.0
<#
.SYNOPSIS
    Setup default admin user for FlutterPOS Backend API

.DESCRIPTION
    This script creates the default admin user account in Appwrite.
    It loads environment variables from .env.backend file and creates
    an admin user with full permissions.

.EXAMPLE
    .\setup-default-admin.ps1
    .\setup-default-admin.ps1 -Force

.NOTES
    Requires Node.js to be installed
    Run after: setup-user-management-database.ps1
#>

param(
    [switch]$Force = $false
)

# Script configuration
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendRoot = Split-Path -Parent $ScriptPath
$DockerRoot = Split-Path -Parent $BackendRoot
$EnvFile = Join-Path $DockerRoot ".env.backend"
$NodeScript = Join-Path $ScriptPath "setup-default-admin.js"

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  FlutterPOS Default Admin User Setup                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Validate environment file
if (-not (Test-Path $EnvFile)) {
    Write-Host "❌ Error: .env.backend file not found at: $EnvFile" -ForegroundColor Red
    Write-Host "   Please ensure you're running from the correct directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found .env.backend file" -ForegroundColor Green

# Load environment variables
Write-Host "📋 Loading environment variables from .env.backend..." -ForegroundColor Cyan

$EnvContent = Get-Content $EnvFile

# Parse required variables
$AppwriteEndpoint = ($EnvContent | Select-String "APPWRITE_ENDPOINT=" | ForEach-Object { $_ -replace 'APPWRITE_ENDPOINT=' }).Trim()
$AppwriteProjectId = ($EnvContent | Select-String "APPWRITE_PROJECT_ID=" | ForEach-Object { $_ -replace 'APPWRITE_PROJECT_ID=' }).Trim()
$AppwriteApiKey = ($EnvContent | Select-String "APPWRITE_API_KEY=" | ForEach-Object { $_ -replace 'APPWRITE_API_KEY=' }).Trim()

# Validate required variables
$MissingVars = @()
if (-not $AppwriteEndpoint) { $MissingVars += "APPWRITE_ENDPOINT" }
if (-not $AppwriteProjectId) { $MissingVars += "APPWRITE_PROJECT_ID" }
if (-not $AppwriteApiKey) { $MissingVars += "APPWRITE_API_KEY" }

if ($MissingVars.Count -gt 0) {
    Write-Host "❌ Missing environment variables: $($MissingVars -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Environment variables loaded successfully" -ForegroundColor Green
Write-Host ""

# Display configuration
Write-Host "🔧 Configuration:" -ForegroundColor Cyan
Write-Host "   Appwrite Endpoint: $AppwriteEndpoint"
Write-Host "   Project ID: $AppwriteProjectId"
Write-Host "   Node Script: $NodeScript"
Write-Host ""

# Confirm before proceeding
if (-not $Force) {
    Write-Host "⚠️  This will create a default admin user with:" -ForegroundColor Yellow
    Write-Host "   Email: admin@extropos.com"
    Write-Host "   Password: Admin@123"
    Write-Host "   PIN: 0000"
    Write-Host "   Role: admin (all permissions)"
    Write-Host ""

    $Response = Read-Host "Continue? (yes/no)"
    if ($Response -ne "yes") {
        Write-Host "❌ Aborted" -ForegroundColor Red
        exit 1
    }
}

# Check if Node.js is installed
Write-Host "🔍 Checking for Node.js..." -ForegroundColor Cyan
$NodeCheck = & node --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Node.js is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Node.js found: $NodeCheck" -ForegroundColor Green
Write-Host ""

# Set environment variables for Node process
Write-Host "🚀 Running admin setup script..." -ForegroundColor Cyan
Write-Host ""

$env:APPWRITE_ENDPOINT = $AppwriteEndpoint
$env:APPWRITE_PROJECT_ID = $AppwriteProjectId
$env:APPWRITE_API_KEY = $AppwriteApiKey

# Run the Node script
$CurrentLocation = Get-Location
Set-Location $BackendRoot

try {
    & node $NodeScript
    $ExitCode = $LASTEXITCODE
} catch {
    Write-Host "❌ Error running setup script:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $ExitCode = 1
} finally {
    Set-Location $CurrentLocation
}

if ($ExitCode -eq 0) {
    Write-Host "✅ Admin setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Open Postman: FlutterPOS-User-Backend-API.postman_collection.json"
    Write-Host "   2. Login with: admin@extropos.com / Admin@123"
    Write-Host "   3. Test API endpoints"
    Write-Host "   4. Verify middleware and RBAC are working"
} else {
    Write-Host "❌ Admin setup failed with exit code: $ExitCode" -ForegroundColor Red
    exit $ExitCode
}
