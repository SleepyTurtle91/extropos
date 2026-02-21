# ==========================================
# FlutterPOS Docker Cloud Management
# ==========================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "backup", "restore", "shell", "health", "monitor")]
    [string]$Command = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$Service = "all",
    
    [Parameter(Mandatory=$false)]
    [int]$Lines = 50
)

# Color output functions
function Write-Success { Write-Host "[✓] $args" -ForegroundColor Green }
function Write-Error { Write-Host "[✗] $args" -ForegroundColor Red }
function Write-Info { Write-Host "[→] $args" -ForegroundColor Cyan }
function Write-Warning { Write-Host "[!] $args" -ForegroundColor Yellow }

$dockerCompose = "appwrite-compose-cloud-windows.yml"
$envFile = ".env"

# ==========================================
# Start Services
# ==========================================
function Start-Services {
    Write-Info "Starting Appwrite services with cloud storage..."
    docker compose -f $dockerCompose --env-file $envFile up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Services started successfully"
        Write-Info "Waiting for services to be ready (30 seconds)..."
        Start-Sleep -Seconds 30
        Show-Status
    } else {
        Write-Error "Failed to start services"
        exit 1
    }
}

# ==========================================
# Stop Services
# ==========================================
function Stop-Services {
    Write-Warning "Stopping Appwrite services..."
    docker compose -f $dockerCompose stop
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Services stopped"
    } else {
        Write-Error "Failed to stop services"
        exit 1
    }
}

# ==========================================
# Restart Services
# ==========================================
function Restart-Services {
    Write-Info "Restarting Appwrite services..."
    
    if ($Service -eq "all") {
        docker compose -f $dockerCompose restart
    } else {
        docker compose -f $dockerCompose restart $Service
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Services restarted"
        Start-Sleep -Seconds 5
        Show-Status
    } else {
        Write-Error "Failed to restart services"
        exit 1
    }
}

# ==========================================
# Show Status
# ==========================================
function Show-Status {
    Write-Info "Service Status:"
    docker compose -f $dockerCompose ps
}

# ==========================================
# Show Logs
# ==========================================
function Show-Logs {
    Write-Info "Showing logs for: $Service (last $Lines lines)"
    
    if ($Service -eq "all") {
        docker compose -f $dockerCompose logs -f --tail $Lines
    } else {
        docker compose -f $dockerCompose logs -f --tail $Lines $Service
    }
}

# ==========================================
# Health Check
# ==========================================
function Get-HealthStatus {
    Write-Info "Checking health status..."
    
    $services = @("mariadb", "redis", "appwrite")
    
    foreach ($svc in $services) {
        $health = docker inspect --format='{{.State.Health.Status}}' "appwrite-$svc" 2>$null
        
        if ($health -eq "healthy") {
            Write-Success "$svc is healthy"
        } elseif ($health -eq "unhealthy") {
            Write-Error "$svc is unhealthy"
        } else {
            Write-Warning "$svc status: $health"
        }
    }
    
    # Check connectivity
    Write-Info ""
    Write-Info "Testing API connectivity..."
    
    try {
        $response = curl -s -w "%{http_code}" -o /dev/null http://localhost:8080/v1/health/version
        if ($response -eq "200") {
            Write-Success "API is accessible (HTTP 200)"
        } else {
            Write-Warning "API returned HTTP $response"
        }
    } catch {
        Write-Error "Cannot connect to API"
    }
    
    # Check disk space
    Write-Info ""
    Write-Info "Checking E:/ drive usage..."
    
    try {
        $drive = Get-PSDrive E
        $usedGB = [math]::Round(($drive.Used / 1GB), 2)
        $freeGB = [math]::Round(($drive.Free / 1GB), 2)
        $totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
        
        Write-Info "E:\ Drive: $usedGB GB used / $freeGB GB free (Total: $totalGB GB)"
        
        if ($drive.Free / 1GB -lt 5) {
            Write-Warning "Low disk space! Less than 5GB remaining"
        }
    } catch {
        Write-Error "Cannot access E:/ drive"
    }
    
    # Check cloud storage size
    Write-Info ""
    Write-Info "Cloud storage usage..."
    
    try {
        $cloudDir = "E:\appwrite-cloud"
        if (Test-Path $cloudDir) {
            $size = (Get-ChildItem -Path $cloudDir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $sizeGB = [math]::Round($size / 1GB, 2)
            Write-Info "E:\appwrite-cloud: $sizeGB GB"
        }
    } catch {
        Write-Warning "Could not calculate cloud storage size"
    }
}

# ==========================================
# Monitor Resources
# ==========================================
function Get-ResourceMetrics {
    Write-Info "Monitoring Docker container resources (press Ctrl+C to stop)..."
    Write-Info ""
    
    docker stats --no-stream `
        --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" `
        appwrite-mariadb appwrite-redis appwrite-api appwrite-console
}

# ==========================================
# Backup
# ==========================================
function Backup-Cloud {
    $backupDate = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "E:\appwrite-cloud\backups\backup_$backupDate"
    
    Write-Warning "Creating backup at: $backupPath"
    
    try {
        # Create backup directory
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        
        # Backup database
        Write-Info "Backing up database..."
        
        # Get password from env file
        $envContent = Get-Content $envFile
        $mysqlPass = $envContent | Select-String "MYSQL_ROOT_PASSWORD=" | ForEach-Object { $_ -replace 'MYSQL_ROOT_PASSWORD=' } | ForEach-Object { $_.Trim() }
        
        docker compose -f $dockerCompose exec -T mariadb `
            mysqldump -uroot -p"$mysqlPass" appwrite > "$backupPath\appwrite.sql"
        
        Write-Success "Database backup created"
        
        # Backup configuration
        Write-Info "Backing up configuration..."
        Copy-Item "E:\appwrite-cloud\config" "$backupPath\config" -Recurse -Force 2>$null
        Write-Success "Configuration backup created"
        
        # Backup storage metadata (not full storage to save space)
        Write-Info "Backing up storage metadata..."
        Copy-Item "E:\appwrite-cloud\storage" "$backupPath\storage" -Recurse -Force 2>$null
        Write-Success "Storage backup created"
        
        Write-Success "Backup completed: $backupPath"
    } catch {
        Write-Error "Backup failed: $_"
        exit 1
    }
}

# ==========================================
# Restore
# ==========================================
function Restore-Cloud {
    Write-Warning "Listing available backups..."
    
    $backups = Get-ChildItem "E:\appwrite-cloud\backups" -Directory | Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        Write-Error "No backups found"
        exit 1
    }
    
    Write-Info "Available backups:"
    for ($i = 0; $i -lt $backups.Count; $i++) {
        Write-Host "[$i] $($backups[$i].Name)"
    }
    
    $selection = Read-Host "Select backup to restore (number)"
    
    if (-not ($selection -as [int]) -or $selection -ge $backups.Count) {
        Write-Error "Invalid selection"
        exit 1
    }
    
    $backupPath = $backups[$selection].FullName
    
    Write-Warning "Restoring from: $backupPath"
    Write-Warning "This will stop services. Continue? (y/N)"
    
    $confirm = Read-Host "Continue"
    if ($confirm -ne "y") {
        Write-Info "Restore cancelled"
        exit 0
    }
    
    try {
        # Stop services
        Write-Info "Stopping services..."
        docker compose -f $dockerCompose down
        
        # Restore database
        Write-Info "Restoring database..."
        $envContent = Get-Content $envFile
        $mysqlPass = $envContent | Select-String "MYSQL_ROOT_PASSWORD=" | ForEach-Object { $_ -replace 'MYSQL_ROOT_PASSWORD=' } | ForEach-Object { $_.Trim() }
        
        docker compose -f $dockerCompose up -d mariadb
        Start-Sleep -Seconds 10
        
        docker compose -f $dockerCompose exec -T mariadb `
            mysql -uroot -p"$mysqlPass" appwrite < "$backupPath\appwrite.sql"
        
        Write-Success "Database restored"
        
        # Restore configuration
        Write-Info "Restoring configuration..."
        Copy-Item "$backupPath\config\*" "E:\appwrite-cloud\config" -Recurse -Force
        Write-Success "Configuration restored"
        
        # Restore storage
        Write-Info "Restoring storage..."
        Copy-Item "$backupPath\storage\*" "E:\appwrite-cloud\storage" -Recurse -Force
        Write-Success "Storage restored"
        
        # Restart all services
        Write-Info "Restarting services..."
        docker compose -f $dockerCompose up -d
        
        Write-Success "Restore completed"
    } catch {
        Write-Error "Restore failed: $_"
        exit 1
    }
}

# ==========================================
# Shell Access
# ==========================================
function Enter-Shell {
    $container = "appwrite-$Service"
    Write-Info "Entering shell for: $container"
    docker exec -it $container bash
}

# ==========================================
# Main Entry Point
# ==========================================
try {
    switch ($Command) {
        "start" { Start-Services }
        "stop" { Stop-Services }
        "restart" { Restart-Services }
        "status" { Show-Status }
        "logs" { Show-Logs }
        "backup" { Backup-Cloud }
        "restore" { Restore-Cloud }
        "shell" { Enter-Shell }
        "health" { Get-HealthStatus }
        "monitor" { Get-ResourceMetrics }
        default {
            Write-Warning "Unknown command: $Command"
            Write-Info "Usage: .\manage-cloud.ps1 [command] [service] [options]"
            Write-Info ""
            Write-Info "Commands:"
            Write-Info "  start              - Start all services"
            Write-Info "  stop               - Stop all services"
            Write-Info "  restart            - Restart services (use -Service for specific service)"
            Write-Info "  status             - Show service status"
            Write-Info "  logs               - Show service logs (use -Service and -Lines)"
            Write-Info "  health             - Check system health"
            Write-Info "  monitor            - Monitor resource usage"
            Write-Info "  backup             - Create backup"
            Write-Info "  restore            - Restore from backup"
            Write-Info "  shell              - Open shell in container (use -Service)"
            Write-Info ""
            Write-Info "Examples:"
            Write-Info "  .\manage-cloud.ps1 start"
            Write-Info "  .\manage-cloud.ps1 logs -Service appwrite -Lines 100"
            Write-Info "  .\manage-cloud.ps1 restart -Service mariadb"
            Write-Info "  .\manage-cloud.ps1 health"
            Write-Info "  .\manage-cloud.ps1 backup"
            exit 1
        }
    }
}
catch {
    Write-Error "Error: $_"
    exit 1
}
