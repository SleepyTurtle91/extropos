# ========================================
# Appwrite Cloud Health Monitor & Restore
# ========================================
# Purpose: Monitor container health, disk usage, and facilitate restores

param(
    [ValidateSet("status", "logs", "health", "disk-usage", "db-size", "restore")]
    [string]$Command = "status",
    [string]$RestoreFile,
    [string]$ComposeDir = "E:\flutterpos\docker"
)

# ========================================
# Configuration
# ========================================
$StoragePath = "E:\appwrite-cloud"
$BackupPath = "$StoragePath\backups"
$DiskWarningPercent = 80

# ========================================
# Functions
# ========================================
function Get-ContainerStatus {
    Write-Host "=== Appwrite Docker Stack Status ===" -ForegroundColor Cyan
    
    try {
        Push-Location -Path $ComposeDir
        docker compose ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        Pop-Location
        Write-Host ""
    }
    catch {
        Write-Host "Error getting container status: $_" -ForegroundColor Red
    }
}

function Get-ContainerLogs {
    param([string]$Container = "appwrite-api", [int]$Lines = 50)
    
    Write-Host "=== Logs for $Container (last $Lines lines) ===" -ForegroundColor Cyan
    
    try {
        Push-Location -Path $ComposeDir
        docker compose logs --tail $Lines $Container
        Pop-Location
        Write-Host ""
    }
    catch {
        Write-Host "Error getting logs: $_" -ForegroundColor Red
    }
}

function Get-HealthCheck {
    Write-Host "=== Appwrite Health Check ===" -ForegroundColor Cyan
    
    # Check API endpoints
    try {
        $ApiResponse = Invoke-RestMethod -Uri "http://localhost:8080/v1/health/version" -ErrorAction Stop
        Write-Host "✓ API Version: $($ApiResponse.version)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ API Version Check Failed" -ForegroundColor Red
    }
    
    # Check MariaDB
    try {
        docker exec appwrite-mariadb mysqladmin ping -u appwrite -p"$env:MYSQL_PASSWORD" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Database: Healthy" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Database: Unhealthy" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Database Check Failed" -ForegroundColor Red
    }
    
    # Check Redis
    try {
        $RedisStatus = docker exec appwrite-redis redis-cli ping 2>&1
        if ($RedisStatus -eq "PONG") {
            Write-Host "✓ Redis Cache: Healthy" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Redis Cache: Unhealthy" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Redis Check Failed" -ForegroundColor Red
    }
    
    # Check Workers
    $Workers = @("appwrite-worker-database", "appwrite-worker-audits", "appwrite-worker-usage", "appwrite-worker-webhooks")
    foreach ($Worker in $Workers) {
        try {
            $Status = docker container inspect $Worker --format="{{.State.Running}}" 2>&1
            if ($Status -eq "true") {
                Write-Host "✓ $Worker : Running" -ForegroundColor Green
            }
            else {
                Write-Host "✗ $Worker : Not Running" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "✗ $Worker : Check Failed" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

function Get-DiskUsage {
    Write-Host "=== Disk Usage Analysis ===" -ForegroundColor Cyan
    
    $Drive = (Get-Item $StoragePath).PSDrive
    $Volume = Get-Volume -DriveLetter $Drive.Name
    
    $UsedSpace = $Volume.Size - $Volume.SizeRemaining
    $UsedPercent = ($UsedSpace / $Volume.Size) * 100
    
    Write-Host "Drive: $($Drive.Name):" -ForegroundColor Cyan
    Write-Host "  Total: $([math]::Round($Volume.Size / 1GB, 2)) GB"
    Write-Host "  Used: $([math]::Round($UsedSpace / 1GB, 2)) GB ($([math]::Round($UsedPercent, 1))%)"
    Write-Host "  Free: $([math]::Round($Volume.SizeRemaining / 1GB, 2)) GB"
    
    if ($UsedPercent -gt $DiskWarningPercent) {
        Write-Host "⚠ WARNING: Disk usage above $DiskWarningPercent%!" -ForegroundColor Yellow
    }
    else {
        Write-Host "✓ Disk usage normal" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Storage Directory Sizes:" -ForegroundColor Cyan
    $Dirs = @("mysql", "redis", "storage", "config", "traefik", "backups")
    
    foreach ($Dir in $Dirs) {
        $Path = Join-Path $StoragePath $Dir
        if (Test-Path $Path) {
            $Size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1MB
            Write-Host "  $Dir`: $([math]::Round($Size, 2)) MB"
        }
    }
    
    Write-Host ""
}

function Get-DatabaseSize {
    Write-Host "=== Database Size Analysis ===" -ForegroundColor Cyan
    
    try {
        $Query = "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb FROM information_schema.tables WHERE table_schema='appwrite' ORDER BY size_mb DESC;"
        
        $Result = docker exec appwrite-mariadb mysql -u appwrite -p"$env:MYSQL_PASSWORD" -e "$Query" appwrite
        Write-Host $Result
        Write-Host ""
    }
    catch {
        Write-Host "Error getting database size: $_" -ForegroundColor Red
    }
}

function Restore-Backup {
    param([string]$BackupFile)
    
    if (-not (Test-Path $BackupFile)) {
        Write-Host "Backup file not found: $BackupFile" -ForegroundColor Red
        return
    }
    
    Write-Host "=== Restore Appwrite Backup ===" -ForegroundColor Yellow
    Write-Host "Backup File: $BackupFile"
    Write-Host "⚠ This will overwrite current data. Continue? (yes/no)" -ForegroundColor Yellow
    
    $Confirm = Read-Host
    if ($Confirm -ne "yes") {
        Write-Host "Restore cancelled"
        return
    }
    
    try {
        Push-Location -Path $ComposeDir
        
        if ($BackupFile -match "\.zip$") {
            # Extract backup
            $TempDir = Join-Path $env:TEMP "appwrite_restore_$([datetime]::Now.Ticks)"
            New-Item -ItemType Directory -Path $TempDir | Out-Null
            Expand-Archive -Path $BackupFile -DestinationPath $TempDir
            
            # Find SQL dump
            $SqlFile = Get-ChildItem -Path $TempDir -Filter "*.sql" -Recurse | Select-Object -First 1
            if ($SqlFile) {
                Write-Host "Restoring database from: $($SqlFile.FullName)"
                $SqlContent = Get-Content $SqlFile.FullName -Raw
                $SqlContent | docker exec -i appwrite-mariadb mysql -u appwrite "-p${env:MYSQL_PASSWORD}" appwrite
                Write-Host "✓ Database restored" -ForegroundColor Green
            }
            
            # Restore storage if available
            $StorageDir = Get-ChildItem -Path $TempDir -Filter "*storage*" -Directory | Select-Object -First 1
            if ($StorageDir) {
                Write-Host "Restoring storage from: $($StorageDir.FullName)"
                Copy-Item -Path "$($StorageDir.FullName)\*" -Destination "$StoragePath\storage" -Recurse -Force
                Write-Host "✓ Storage restored" -ForegroundColor Green
            }
            
            # Cleanup
            Remove-Item -Path $TempDir -Recurse -Force
        }
        
        Write-Host "✓ Restore completed successfully" -ForegroundColor Green
        Pop-Location
    }
    catch {
        Write-Host "Restore failed: $_" -ForegroundColor Red
        Pop-Location
    }
}

# ========================================
# Main Execution
# ========================================
switch ($Command) {
    "status" { Get-ContainerStatus }
    "logs" { Get-ContainerLogs }
    "health" { Get-HealthCheck }
    "disk-usage" { Get-DiskUsage }
    "db-size" { Get-DatabaseSize }
    "restore" { 
        if (-not $RestoreFile) {
            Write-Host "Available backups:" -ForegroundColor Cyan
            Get-ChildItem -Path $BackupPath -Directory -ErrorAction SilentlyContinue | 
                ForEach-Object { "  - $($_.FullName)" }
        }
        else {
            Restore-Backup $RestoreFile
        }
    }
    default { Write-Host "Unknown command: $Command" -ForegroundColor Red }
}
