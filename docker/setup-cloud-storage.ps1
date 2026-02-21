# ==========================================
# FlutterPOS Docker Cloud Setup Script
# E:/ Drive Cloud Storage Configuration
# ==========================================

# Color output functions
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Warning { Write-Host "[WARN] $args" -ForegroundColor Yellow }

# ==========================================
# STEP 1: Verify Prerequisites
# ==========================================
Write-Info "Checking prerequisites..."

# Check Docker
try {
    $dockerVersion = docker --version
    Write-Success "Docker found: $dockerVersion"
}
catch {
    Write-Error "Docker is not installed. Please install Docker Desktop for Windows."
    exit 1
}

# Check Docker Compose
try {
    $composeVersion = docker compose version
    Write-Success "Docker Compose found: $composeVersion"
}
catch {
    Write-Error "Docker Compose is not installed."
    exit 1
}

# ==========================================
# STEP 2: Create Cloud Storage Directory Structure
# ==========================================
Write-Info "Creating cloud storage directories on E:/ drive..."

$cloudStoragePath = "E:\appwrite-cloud"

# Create main directories
$directories = @(
    "$cloudStoragePath",
    "$cloudStoragePath\mysql",
    "$cloudStoragePath\redis",
    "$cloudStoragePath\config",
    "$cloudStoragePath\storage",
    "$cloudStoragePath\storage\functions",
    "$cloudStoragePath\storage\uploads",
    "$cloudStoragePath\storage\buckets",
    "$cloudStoragePath\backups"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Success "Created: $dir"
        }
        catch {
            Write-Error "Failed to create: $dir"
            exit 1
        }
    }
    else {
        Write-Info "Already exists: $dir"
    }
}

# ==========================================
# STEP 3: Set Directory Permissions
# ==========================================
Write-Info "Setting directory permissions..."

try {
    # Grant full control to current user
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    icacls "$cloudStoragePath" /grant "$currentUser`:(OI)(CI)F" /T /Q
    Write-Success "Permissions set for: $cloudStoragePath"
}
catch {
    Write-Warning "Could not set permissions automatically. Please run as Administrator if you encounter permission issues."
}

# ==========================================
# STEP 4: Create .env File from Template
# ==========================================
Write-Info "Checking environment configuration..."

$envCloudFile = "$PSScriptRoot\.env.cloud"
$envFile = "$PSScriptRoot\.env"

if (Test-Path $envCloudFile) {
    Write-Info "Found .env.cloud template"
    
    if (!(Test-Path $envFile)) {
        Copy-Item $envCloudFile $envFile
        Write-Success "Created .env file from template"
    }
    else {
        Write-Warning ".env file already exists. Skipping copy."
        Write-Info "To use cloud configuration, ensure your .env file has the cloud settings."
    }
}
else {
    Write-Error ".env.cloud template not found at $envCloudFile"
    exit 1
}

# ==========================================
# STEP 5: Verify Cloud Compose File
# ==========================================
Write-Info "Verifying Docker Compose configuration..."

$composeFile = "$PSScriptRoot\appwrite-compose-cloud-windows.yml"

if (!(Test-Path $composeFile)) {
    Write-Error "Docker Compose file not found: $composeFile"
    exit 1
}

Write-Success "Found: $composeFile"

# ==========================================
# STEP 6: Display Configuration Summary
# ==========================================
Write-Info "`n========== CLOUD STORAGE CONFIGURATION =========="
Write-Info "Cloud Storage Location: E:\appwrite-cloud"
Write-Info ""
Write-Info "Storage Structure:"
Write-Info "  E:\appwrite-cloud\mysql       - Database files"
Write-Info "  E:\appwrite-cloud\redis       - Cache data"
Write-Info "  E:\appwrite-cloud\config      - Configuration files"
Write-Info "  E:\appwrite-cloud\storage     - File uploads & functions"
Write-Info "  E:\appwrite-cloud\backups     - Backup location"
Write-Info ""
Write-Info "Docker Compose File: $composeFile"
Write-Info "Environment File: $envFile"

# ==========================================
# STEP 7: Optional - Pre-pull Images
# ==========================================
Write-Warning "Do you want to pre-pull Docker images? (Y/n)"
$response = Read-Host "Response"

if ($response -ne "n" -and $response -ne "N") {
    Write-Info "Pre-pulling Docker images..."
    
    $images = @(
        "mariadb:10.11",
        "redis:7-alpine",
        "appwrite/appwrite:1.5.7",
        "appwrite/console:1.5.7"
    )
    
    foreach ($image in $images) {
        Write-Info "Pulling: $image"
        docker pull $image
    }
    
    Write-Success "All images pre-pulled"
}

# ==========================================
# STEP 8: Display Next Steps
# ==========================================
Write-Info "`n========== NEXT STEPS =========="
Write-Success "`nCloud storage setup complete! To start the Docker containers:"
Write-Info ""
Write-Info "  1. Navigate to the docker directory:"
Write-Info "     cd $(Split-Path $PSScriptRoot -Leaf)"
Write-Info ""
Write-Info "  2. Start Appwrite with cloud storage:"
Write-Info "     docker compose -f appwrite-compose-cloud-windows.yml --env-file .env up -d"
Write-Info ""
Write-Info "  3. Verify services are running:"
Write-Info "     docker compose -f appwrite-compose-cloud-windows.yml ps"
Write-Info ""
Write-Info "  4. Access Appwrite Console:"
Write-Info "     Browser: http://localhost:3000"
Write-Info ""
Write-Info "  5. Appwrite API:"
Write-Info "     http://localhost:8080/v1"
Write-Info ""
Write-Info "  6. Check logs:"
Write-Info "     docker compose -f appwrite-compose-cloud-windows.yml logs -f appwrite"
Write-Info ""
Write-Success "Setup complete! Your cloud storage is ready on E:/ drive"
