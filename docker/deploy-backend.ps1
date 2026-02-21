# FlutterPOS Backend API - Docker Deployment Script
# Deploys the Node.js Backend API integrated with Appwrite

param(
    [ValidateSet('build', 'deploy', 'start', 'stop', 'logs', 'status', 'test', 'clean')]
    [string]$Action = 'deploy'
)

$BackendDir = "$(Split-Path -Parent $PSScriptRoot)\backend-api"
$DockerDir = $PSScriptRoot
$ImageName = "flutterpos-backend-api"
$ImageTag = "1.0.0"
$FullImageName = "$ImageName`:$ImageTag"
$ContainerName = "flutterpos-backend-api"

function Write-Status {
    param([string]$Message, [string]$Status = "info")
    $Color = @{
        "info"    = "Cyan"
        "success" = "Green"
        "warning" = "Yellow"
        "error"   = "Red"
    }[$Status]
    
    Write-Host "[$Status.ToUpper()] $Message" -ForegroundColor $Color
}

function Build-Image {
    Write-Status "Building Docker image: $FullImageName" "info"
    
    if (-not (Test-Path $BackendDir)) {
        Write-Status "Backend directory not found: $BackendDir" "error"
        exit 1
    }
    
    Push-Location $BackendDir
    try {
        docker build -t $FullImageName .
        if ($LASTEXITCODE -eq 0) {
            Write-Status "✓ Image built successfully" "success"
        } else {
            Write-Status "✗ Build failed" "error"
            exit 1
        }
    } finally {
        Pop-Location
    }
}

function Deploy-Backend {
    Write-Status "Deploying Backend API with Docker Compose" "info"
    
    # Check if .env.backend exists
    if (-not (Test-Path "$DockerDir\.env.backend")) {
        Write-Status "Warning: .env.backend not found. Using defaults." "warning"
        Write-Status "Create $DockerDir\.env.backend with your configuration" "warning"
    }
    
    # Build image first
    Build-Image
    
    # Check if appwrite_default network exists
    $NetworkExists = docker network ls | Select-String "appwrite_default"
    if (-not $NetworkExists) {
        Write-Status "Creating appwrite_default network..." "info"
        docker network create appwrite_default
    }
    
    # Stop existing container
    Stop-Backend
    
    # Deploy with compose
    Write-Status "Starting backend-api container..." "info"
    
    Push-Location $DockerDir
    try {
        # Use existing Appwrite compose and add backend
        docker compose `
            -f appwrite-compose-cloud-windows.yml `
            -f backend-api-compose.yml `
            up -d backend-api
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "✓ Backend deployed successfully" "success"
            Write-Status "Container name: $ContainerName" "info"
            Write-Status "API endpoint: http://localhost:3001" "info"
            Write-Status "Health check: http://localhost:3001/health" "info"
        } else {
            Write-Status "✗ Deployment failed" "error"
            exit 1
        }
    } finally {
        Pop-Location
    }
}

function Start-Backend {
    Write-Status "Starting backend-api container..." "info"
    
    Push-Location $DockerDir
    try {
        docker compose -f appwrite-compose-cloud-windows.yml -f backend-api-compose.yml up -d backend-api
        if ($LASTEXITCODE -eq 0) {
            Write-Status "✓ Backend started" "success"
        }
    } finally {
        Pop-Location
    }
}

function Stop-Backend {
    Write-Status "Stopping backend-api container..." "info"
    
    $Running = docker ps --quiet --filter "name=$ContainerName"
    if ($Running) {
        docker stop $ContainerName
        docker rm $ContainerName 2>$null
        Write-Status "✓ Backend stopped" "success"
    } else {
        Write-Status "Backend is not running" "info"
    }
}

function Get-Logs {
    Write-Status "Backend API Logs (last 50 lines)" "info"
    Write-Host ""
    
    Push-Location $DockerDir
    try {
        docker compose logs --tail=50 backend-api
    } finally {
        Pop-Location
    }
}

function Get-Status {
    Write-Status "Backend API Status" "info"
    Write-Host ""
    
    # Container status
    Write-Host "Container Status:" -ForegroundColor Cyan
    Push-Location $DockerDir
    try {
        docker compose ps backend-api
    } finally {
        Pop-Location
    }
    
    Write-Host ""
    Write-Host "Health Check:" -ForegroundColor Cyan
    
    try {
        $Response = curl.exe -s http://localhost:3001/health
        Write-Host "✓ API is responding" -ForegroundColor Green
        Write-Host "Response: $Response" -ForegroundColor Cyan
    } catch {
        Write-Host "✗ API is not responding" -ForegroundColor Red
        Write-Host "Make sure container is running: docker ps | findstr backend-api" -ForegroundColor Yellow
    }
}

function Test-Backend {
    Write-Status "Testing Backend API" "info"
    Write-Host ""
    
    Write-Host "1. Health Check:" -ForegroundColor Yellow
    try {
        $Health = curl.exe -s http://localhost:3001/health
        Write-Host "   ✓ Response: $Health" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ Failed: $_" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "2. Appwrite Connection:" -ForegroundColor Yellow
    try {
        $Status = curl.exe -s http://localhost:3001/api/status
        Write-Host "   ✓ Response: $Status" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ Failed: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "3. Available Endpoints:" -ForegroundColor Yellow
    Write-Host "   - Health: http://localhost:3001/health" -ForegroundColor Cyan
    Write-Host "   - Status: http://localhost:3001/api/status" -ForegroundColor Cyan
    Write-Host "   - Databases: http://localhost:3001/api/databases" -ForegroundColor Cyan
}

function Remove-Resources {
    Write-Status "Cleaning up Docker resources" "warning"
    
    Write-Host "This will remove:" -ForegroundColor Yellow
    Write-Host "  - Container: $ContainerName" -ForegroundColor Cyan
    Write-Host "  - Image: $FullImageName" -ForegroundColor Cyan
    
    $Confirm = Read-Host "Continue? (y/n)"
    if ($Confirm -ne 'y') {
        Write-Status "Cleanup cancelled" "info"
        return
    }
    
    Stop-Backend
    
    Write-Status "Removing image..." "info"
    docker rmi $FullImageName
    
    Write-Status "✓ Cleanup complete" "success"
}

# Execute requested action
switch ($Action) {
    'build' { Build-Image }
    'deploy' { Deploy-Backend }
    'start' { Start-Backend }
    'stop' { Stop-Backend }
    'logs' { Get-Logs }
    'status' { Get-Status }
    'test' { Test-Backend }
    'clean' { Remove-Resources }
    default {
        Write-Status "Unknown action: $Action" "error"
        Write-Host ""
        Write-Host "Available actions:" -ForegroundColor Cyan
        Write-Host "  build    - Build Docker image" -ForegroundColor Gray
        Write-Host "  deploy   - Build and deploy backend (default)" -ForegroundColor Gray
        Write-Host "  start    - Start container" -ForegroundColor Gray
        Write-Host "  stop     - Stop container" -ForegroundColor Gray
        Write-Host "  logs     - View container logs" -ForegroundColor Gray
        Write-Host "  status   - Check container status" -ForegroundColor Gray
        Write-Host "  test     - Test API endpoints" -ForegroundColor Gray
        Write-Host "  clean    - Remove container and image" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Usage:" -ForegroundColor Cyan
        Write-Host "  .\deploy-backend.ps1 -Action deploy" -ForegroundColor Yellow
        Write-Host "  .\deploy-backend.ps1 -Action logs" -ForegroundColor Yellow
        exit 1
    }
}
