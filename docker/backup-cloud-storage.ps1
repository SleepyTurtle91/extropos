# ========================================
# Appwrite Cloud Storage Backup Script
# ========================================
# Purpose: Automated daily backups of MariaDB and storage buckets
# Schedule: Run via Windows Task Scheduler at 2 AM daily
# Backup Location: E:\appwrite-cloud\backups\

param(
    [string]$BackupPath = "E:\appwrite-cloud\backups",
    [int]$RetentionDays = 30
)

# ========================================
# Configuration
# ========================================
$ComposeDir = "E:\flutterpos\docker"
$ContainerMariaDB = "appwrite-mariadb"
$DBName = "appwrite"
$DBUser = "appwrite"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DateFolder = (Get-Date).ToString("yyyy-MM-dd")
$BackupFolder = Join-Path $BackupPath $DateFolder
$LogFile = Join-Path $BackupPath "backup_$(Get-Date -Format 'yyyy-MM-dd').log"

# ========================================
# Functions
# ========================================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
}

function Test-DockerHealth {
    try {
        docker compose -f "$ComposeDir\appwrite-compose-cloud-windows.yml" ps --format "table" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Docker compose not accessible" "ERROR"
            return $false
        }
        Write-Log "Docker environment healthy"
        return $true
    }
    catch {
        Write-Log "Docker health check failed: $_" "ERROR"
        return $false
    }
}

function Backup-Database {
    param([string]$OutputPath)
    
    try {
        Write-Log "Starting MariaDB backup..."
        
        # Export database using mysqldump inside container
        $DumpFile = Join-Path $OutputPath "appwrite_database_$Timestamp.sql"
        $Password = $env:MYSQL_PASSWORD
        
        # Execute mysqldump in container
        docker exec $ContainerMariaDB mysqldump `
            --user=$DBUser `
            --password=$Password `
            --single-transaction `
            --quick `
            --lock-tables=false `
            $DBName > $DumpFile 2>&1
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $DumpFile)) {
            $Size = (Get-Item $DumpFile).Length / 1MB
            Write-Log "Database backup completed: $DumpFile ($([math]::Round($Size, 2)) MB)"
            
            # Compress database dump
            Compress-Archive -Path $DumpFile -DestinationPath "$DumpFile.zip" -Force
            Remove-Item $DumpFile
            Write-Log "Database backup compressed"
            return $true
        }
        else {
            Write-Log "Database backup failed" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Database backup error: $_" "ERROR"
        return $false
    }
}

function Backup-Storage {
    param([string]$OutputPath)
    
    try {
        Write-Log "Starting storage backup..."
        
        $StoragePath = "E:\appwrite-cloud\storage"
        $StorageBackup = Join-Path $OutputPath "appwrite_storage_$Timestamp"
        
        if (Test-Path $StoragePath) {
            # Copy storage directory
            Copy-Item -Path $StoragePath -Destination $StorageBackup -Recurse -Force
            
            # Compress storage
            Compress-Archive -Path $StorageBackup -DestinationPath "$StorageBackup.zip" -Force
            Remove-Item $StorageBackup -Recurse
            
            $Size = (Get-Item "$StorageBackup.zip").Length / 1MB
            Write-Log "Storage backup completed: $StorageBackup.zip ($([math]::Round($Size, 2)) MB)"
            return $true
        }
        else {
            Write-Log "Storage path not found: $StoragePath" "WARN"
            return $false
        }
    }
    catch {
        Write-Log "Storage backup error: $_" "ERROR"
        return $false
    }
}

function Backup-Config {
    param([string]$OutputPath)
    
    try {
        Write-Log "Backing up .env configuration..."
        
        $EnvFile = "$ComposeDir\.env"
        if (Test-Path $EnvFile) {
            Copy-Item -Path $EnvFile -Destination (Join-Path $OutputPath ".env_$Timestamp")
            Write-Log ".env backup completed"
            return $true
        }
        else {
            Write-Log ".env file not found" "WARN"
            return $false
        }
    }
    catch {
        Write-Log "Config backup error: $_" "ERROR"
        return $false
    }
}

function Remove-OldBackups {
    param([int]$Days)
    
    try {
        Write-Log "Cleaning old backups (older than $Days days)..."
        
        $CutoffDate = (Get-Date).AddDays(-$Days)
        $BackupFolders = Get-ChildItem -Path $BackupPath -Directory -ErrorAction SilentlyContinue
        
        foreach ($Folder in $BackupFolders) {
            if ($Folder.LastWriteTime -lt $CutoffDate) {
                Remove-Item -Path $Folder.FullName -Recurse -Force
                Write-Log "Removed old backup: $($Folder.Name)"
            }
        }
        
        Write-Log "Backup cleanup completed"
    }
    catch {
        Write-Log "Cleanup error: $_" "ERROR"
    }
}

# ========================================
# Main Backup Execution
# ========================================
Write-Log "=== Appwrite Cloud Storage Backup Started ==="
Write-Log "Backup Path: $BackupPath"
Write-Log "Retention Days: $RetentionDays"

# Create backup directory
if (-not (Test-Path $BackupFolder)) {
    New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null
    Write-Log "Created backup directory: $BackupFolder"
}

# Check Docker health
if (-not (Test-DockerHealth)) {
    Write-Log "Backup aborted - Docker not healthy" "ERROR"
    exit 1
}

# Perform backups
$DbBackupSuccess = Backup-Database $BackupFolder
$StorageBackupSuccess = Backup-Storage $BackupFolder
$ConfigBackupSuccess = Backup-Config $BackupFolder

# Cleanup old backups
Remove-OldBackups $RetentionDays

# Summary
Write-Log "=== Backup Summary ==="
Write-Log "Database Backup: $(if ($DbBackupSuccess) { 'SUCCESS' } else { 'FAILED' })"
Write-Log "Storage Backup: $(if ($StorageBackupSuccess) { 'SUCCESS' } else { 'FAILED' })"
Write-Log "Config Backup: $(if ($ConfigBackupSuccess) { 'SUCCESS' } else { 'FAILED' })"
Write-Log "=== Appwrite Cloud Storage Backup Completed ==="

# Exit with appropriate code
if ($DbBackupSuccess -and $StorageBackupSuccess) {
    exit 0
}
else {
    exit 1
}
