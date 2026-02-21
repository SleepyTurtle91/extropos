# ========================================
# Appwrite Cloud Automation Setup
# ========================================
# Purpose: Configure Windows Task Scheduler for automated backups and monitoring
# Run As: Administrator

param(
    [ValidateSet("install", "test", "status", "uninstall")]
    [string]$Action = "install",
    [string]$BackupScript = "E:\flutterpos\docker\backup-cloud-storage.ps1",
    [string]$MonitorScript = "E:\flutterpos\docker\monitor-cloud-health.ps1"
)

# ========================================
# Configuration
# ========================================
$BackupTaskName = "Appwrite Cloud Backup"
$HealthCheckTaskName = "Appwrite Health Check"
$DiskCheckTaskName = "Appwrite Disk Usage Alert"
$LogDir = "E:\appwrite-cloud\logs"

# ========================================
# Helper Functions
# ========================================
function Test-AdminPrivileges {
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    $Admin = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    
    if (-not $Principal.IsInRole($Admin)) {
        Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
        exit 1
    }
}

function New-LogDirectory {
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
        Write-Host "✓ Created log directory: $LogDir" -ForegroundColor Green
    }
}

function Install-BackupTask {
    Write-Host "Setting up Daily Backup Task..." -ForegroundColor Cyan
    
    # Create task action
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File '$BackupScript' -BackupPath 'E:\appwrite-cloud\backups' -RetentionDays 30"
    
    # Create trigger (daily at 2 AM)
    $Trigger = New-ScheduledTaskTrigger `
        -Daily `
        -At 2am
    
    # Create settings
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -RunOnlyIfIdle:$false
    
    # Register task
    try {
        $ExistingTask = Get-ScheduledTask -TaskName $BackupTaskName -ErrorAction SilentlyContinue
        if ($ExistingTask) {
            Write-Host "Updating existing task: $BackupTaskName" -ForegroundColor Yellow
            $ExistingTask | Unregister-ScheduledTask -Confirm:$false
        }
        
        Register-ScheduledTask `
            -TaskName $BackupTaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Settings $Settings `
            -Description "Daily backup of Appwrite database and storage (runs at 2:00 AM)" `
            -RunLevel Highest | Out-Null
        
        Write-Host "✓ Backup task created: $BackupTaskName (runs daily at 2:00 AM)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to create backup task: $_" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Install-HealthCheckTask {
    Write-Host "Setting up Health Check Monitoring Task..." -ForegroundColor Cyan
    
    # Create health check script inline
    $HealthCheckScript = @'
$MonitorScript = "E:\flutterpos\docker\monitor-cloud-health.ps1"
$LogFile = "E:\appwrite-cloud\logs\health_$(Get-Date -Format 'yyyy-MM-dd_HH').log"

# Run health check
& $MonitorScript -Command health | Tee-Object -FilePath $LogFile

# Check for critical issues
$Output = & $MonitorScript -Command health 2>&1
if ($Output -match "✗") {
    Write-Host "ALERT: Health check found issues!" -ForegroundColor Red
    # Could send email here
}
'@
    
    $ScriptPath = "E:\flutterpos\docker\health-check-runner.ps1"
    Set-Content -Path $ScriptPath -Value $HealthCheckScript
    
    # Create task action
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File '$ScriptPath'"
    
    # Create trigger (every 4 hours)
    $Trigger = New-ScheduledTaskTrigger `
        -Daily `
        -At 12:00am `
        -RepetitionInterval (New-TimeSpan -Hours 4) `
        -RepetitionDuration (New-TimeSpan -Days 999)
    
    # Create settings
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable
    
    # Register task
    try {
        $ExistingTask = Get-ScheduledTask -TaskName $HealthCheckTaskName -ErrorAction SilentlyContinue
        if ($ExistingTask) {
            Write-Host "Updating existing task: $HealthCheckTaskName" -ForegroundColor Yellow
            $ExistingTask | Unregister-ScheduledTask -Confirm:$false
        }
        
        Register-ScheduledTask `
            -TaskName $HealthCheckTaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Settings $Settings `
            -Description "Health check monitoring for Appwrite services (runs every 4 hours)" `
            -RunLevel Highest | Out-Null
        
        Write-Host "✓ Health check task created: $HealthCheckTaskName (runs every 4 hours)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to create health check task: $_" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Install-DiskCheckTask {
    Write-Host "Setting up Disk Usage Monitoring Task..." -ForegroundColor Cyan
    
    # Create disk check script
    $DiskCheckScript = @'
$StoragePath = "E:\appwrite-cloud"
$WarningPercent = 80
$LogFile = "E:\appwrite-cloud\logs\disk_$(Get-Date -Format 'yyyy-MM-dd_HH').log"

$Drive = (Get-Item $StoragePath).PSDrive
$Volume = Get-Volume -DriveLetter $Drive.Name
$UsedPercent = (($Volume.Size - $Volume.SizeRemaining) / $Volume.Size) * 100

$Message = "Disk Usage: $([math]::Round($UsedPercent, 1))% | Free: $([math]::Round($Volume.SizeRemaining / 1GB, 2)) GB"
Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"

if ($UsedPercent -gt $WarningPercent) {
    Write-Host "WARNING: Disk usage above ${WarningPercent}%!" -ForegroundColor Yellow
    Write-Host $Message -ForegroundColor Yellow
    # Could send email alert here
}
else {
    Write-Host "✓ $Message" -ForegroundColor Green
}
'@
    
    $ScriptPath = "E:\flutterpos\docker\disk-check-runner.ps1"
    Set-Content -Path $ScriptPath -Value $DiskCheckScript
    
    # Create task action
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File '$ScriptPath'"
    
    # Create trigger (every 6 hours)
    $Trigger = New-ScheduledTaskTrigger `
        -Daily `
        -At 12:00am `
        -RepetitionInterval (New-TimeSpan -Hours 6) `
        -RepetitionDuration (New-TimeSpan -Days 999)
    
    # Register task
    try {
        $ExistingTask = Get-ScheduledTask -TaskName $DiskCheckTaskName -ErrorAction SilentlyContinue
        if ($ExistingTask) {
            Write-Host "Updating existing task: $DiskCheckTaskName" -ForegroundColor Yellow
            $ExistingTask | Unregister-ScheduledTask -Confirm:$false
        }
        
        Register-ScheduledTask `
            -TaskName $DiskCheckTaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable) `
            -Description "Monitor disk usage and alert if above 80%" `
            -RunLevel Highest | Out-Null
        
        Write-Host "✓ Disk check task created: $DiskCheckTaskName (runs every 6 hours)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to create disk check task: $_" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Test-Tasks {
    Write-Host "Testing Scheduled Tasks..." -ForegroundColor Cyan
    Write-Host ""
    
    $Tasks = @($BackupTaskName, $HealthCheckTaskName, $DiskCheckTaskName)
    
    foreach ($Task in $Tasks) {
        $ScheduledTask = Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue
        
        if ($ScheduledTask) {
            Write-Host "Task: $Task" -ForegroundColor Yellow
            Write-Host "  Status: $($ScheduledTask.State)" -ForegroundColor Green
            Write-Host "  Last Run: $($ScheduledTask.LastRunTime)" 
            Write-Host "  Last Result: $(if ($ScheduledTask.LastTaskResult -eq 0) { '✓ Success' } else { '✗ Failed' })" -ForegroundColor $(if ($ScheduledTask.LastTaskResult -eq 0) { 'Green' } else { 'Red' })
            
            # Run task immediately for testing
            Write-Host "  Running task now for testing..." -ForegroundColor Cyan
            Start-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            $UpdatedTask = Get-ScheduledTask -TaskName $Task
            Write-Host "  Latest Result: $(if ($UpdatedTask.LastTaskResult -eq 0) { '✓ Success' } else { '✗ Failed' })" -ForegroundColor $(if ($UpdatedTask.LastTaskResult -eq 0) { 'Green' } else { 'Red' })
        }
        else {
            Write-Host "✗ Task not found: $Task" -ForegroundColor Red
        }
        Write-Host ""
    }
}

function Show-Status {
    Write-Host "=== Appwrite Cloud Automation Status ===" -ForegroundColor Cyan
    Write-Host ""
    
    $Tasks = @($BackupTaskName, $HealthCheckTaskName, $DiskCheckTaskName)
    
    foreach ($Task in $Tasks) {
        $ScheduledTask = Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue
        
        if ($ScheduledTask) {
            $Icon = if ($ScheduledTask.State -eq "Ready") { "✓" } else { "✗" }
            Write-Host "$Icon $Task"
            Write-Host "  State: $($ScheduledTask.State)"
            Write-Host "  Last Run: $($ScheduledTask.LastRunTime)"
        }
        else {
            Write-Host "✗ $Task (Not Installed)"
        }
    }
    
    Write-Host ""
    Write-Host "Log Directory: $LogDir" -ForegroundColor Green
    
    if (Test-Path $LogDir) {
        $LogFiles = Get-ChildItem $LogDir -File | Measure-Object
        Write-Host "Log Files: $($LogFiles.Count)"
    }
}

function Uninstall-Tasks {
    Write-Host "Removing Scheduled Tasks..." -ForegroundColor Yellow
    
    $Tasks = @($BackupTaskName, $HealthCheckTaskName, $DiskCheckTaskName)
    
    foreach ($Task in $Tasks) {
        $ScheduledTask = Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue
        if ($ScheduledTask) {
            Unregister-ScheduledTask -TaskName $Task -Confirm:$false
            Write-Host "✓ Removed: $Task" -ForegroundColor Green
        }
    }
    
    # Remove helper scripts
    Remove-Item -Path "E:\flutterpos\docker\health-check-runner.ps1" -ErrorAction SilentlyContinue
    Remove-Item -Path "E:\flutterpos\docker\disk-check-runner.ps1" -ErrorAction SilentlyContinue
}

# ========================================
# Main Execution
# ========================================
Check-AdminPrivileges
Create-LogDirectory

switch ($Action) {
    "install" {
        Write-Host "Installing Appwrite Cloud Automation Tasks" -ForegroundColor Cyan
        Write-Host ""
        
        $BackupSuccess = Install-BackupTask
        Write-Host ""
        
        $HealthSuccess = Install-HealthCheckTask
        Write-Host ""
        
        $DiskSuccess = Install-DiskCheckTask
        Write-Host ""
        
        if ($BackupSuccess -and $HealthSuccess -and $DiskSuccess) {
            Write-Host "✓ All automation tasks installed successfully!" -ForegroundColor Green
            Write-Host ""
            Show-Status
        }
        else {
            Write-Host "⚠ Some tasks failed to install. Please check the errors above." -ForegroundColor Yellow
        }
    }
    
    "test" {
        Test-Tasks
    }
    
    "status" {
        Show-Status
    }
    
    "uninstall" {
        Uninstall-Tasks
        Write-Host "✓ All automation tasks removed" -ForegroundColor Green
    }
}
