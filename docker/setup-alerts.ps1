# ========================================
# Appwrite Cloud Alert Notification System
# ========================================
# Purpose: Send email alerts for critical issues

param(
    [ValidateSet("configure", "test", "disk-alert", "health-alert", "backup-alert")]
    [string]$Action = "configure",
    [string]$EmailFrom,
    [string]$EmailTo,
    [string]$SmtpServer,
    [int]$SmtpPort = 587,
    [string]$SmtpUsername,
    [string]$SmtpPassword
)

# ========================================
# Configuration Storage
# ========================================
$ConfigPath = "E:\appwrite-cloud\notifications\alert-config.json"
$NotificationDir = "E:\appwrite-cloud\notifications"

# ========================================
# Helper Functions
# ========================================
function Initialize-NotificationDir {
    if (-not (Test-Path $NotificationDir)) {
        New-Item -ItemType Directory -Path $NotificationDir -Force | Out-Null
        Write-Host "✓ Created notification directory" -ForegroundColor Green
    }
}

function Save-AlertConfig {
    param(
        [string]$From,
        [string]$To,
        [string]$Smtp,
        [int]$Port,
        [string]$Username,
        [string]$Password
    )
    
    $Config = @{
        EmailFrom = $From
        EmailTo = $To
        SmtpServer = $Smtp
        SmtpPort = $Port
        SmtpUsername = $Username
        SmtpPassword = $Password
        CreatedDate = Get-Date
    }
    
    $Config | ConvertTo-Json | Set-Content -Path $ConfigPath
    Write-Host "✓ Alert configuration saved" -ForegroundColor Green
}

function Get-AlertConfig {
    if (Test-Path $ConfigPath) {
        return Get-Content -Path $ConfigPath | ConvertFrom-Json
    }
    else {
        Write-Host "✗ Alert configuration not found. Run: .\setup-alerts.ps1 -Action configure" -ForegroundColor Red
        return $null
    }
}

function Send-Alert {
    param(
        [string]$Subject,
        [string]$Body,
        [string]$AlertType = "INFO"
    )
    
    $Config = Load-AlertConfig
    if (-not $Config) { return $false }
    
    try {
        # Create email message
        $EmailParams = @{
            To = $Config.EmailTo
            From = $Config.EmailFrom
            Subject = "[APPWRITE ALERT] [$AlertType] $Subject"
            Body = @"
Appwrite Cloud Alert
==================

Type: $AlertType
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Severity: $(if ($AlertType -eq 'ERROR') { 'HIGH' } elseif ($AlertType -eq 'WARNING') { 'MEDIUM' } else { 'LOW' })

Details:
$Body

---
Appwrite Cloud Monitoring System
Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')
"@
            SmtpServer = $Config.SmtpServer
            Port = $Config.SmtpPort
            UseSsl = $true
            Credential = (New-Object System.Management.Automation.PSCredential (
                $Config.SmtpUsername,
                (ConvertTo-SecureString $Config.SmtpPassword -AsPlainText -Force)
            ))
        }
        
        Send-MailMessage @EmailParams
        Write-Host "✓ Alert sent: $Subject" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to send alert: $_" -ForegroundColor Red
        return $false
    }
}

function Set-Alerts {
    Write-Host "Configure Email Alerts for Appwrite Cloud" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $EmailFrom) {
        $EmailFrom = Read-Host "Enter sender email address"
    }
    
    if (-not $EmailTo) {
        $EmailTo = Read-Host "Enter recipient email address (comma-separated for multiple)"
    }
    
    if (-not $SmtpServer) {
        $SmtpServer = Read-Host "Enter SMTP server (e.g., smtp.gmail.com)"
    }
    
    if (-not $SmtpUsername) {
        $SmtpUsername = Read-Host "Enter SMTP username"
    }
    
    if (-not $SmtpPassword) {
        $SecurePassword = Read-Host "Enter SMTP password" -AsSecureString
        $SmtpPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($SecurePassword)
        )
    }
    
    Initialize-NotificationDir
    Save-AlertConfig -From $EmailFrom -To $EmailTo -Smtp $SmtpServer -Port $SmtpPort -Username $SmtpUsername -Password $SmtpPassword
    
    Write-Host ""
    Write-Host "✓ Alert configuration complete!" -ForegroundColor Green
    Write-Host "Test alerts with: .\setup-alerts.ps1 -Action test" -ForegroundColor Yellow
}

function Test-AlertConfiguration {
    Write-Host "Testing Alert Configuration..." -ForegroundColor Cyan
    Write-Host ""
    
    $Config = Load-AlertConfig
    if (-not $Config) { return }
    
    Write-Host "Configuration Details:" -ForegroundColor Yellow
    Write-Host "  From: $($Config.EmailFrom)"
    Write-Host "  To: $($Config.EmailTo)"
    Write-Host "  SMTP: $($Config.SmtpServer):$($Config.SmtpPort)"
    Write-Host ""
    
    Write-Host "Sending test alert..." -ForegroundColor Cyan
    $TestResult = Send-Alert `
        -Subject "Test Alert" `
        -Body "This is a test alert from Appwrite Cloud monitoring system. If you receive this, email alerts are working correctly." `
        -AlertType "TEST"
    
    if ($TestResult) {
        Write-Host "✓ Test alert sent successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Failed to send test alert. Check SMTP credentials." -ForegroundColor Red
    }
}

function Send-DiskAlert {
    $StoragePath = "E:\appwrite-cloud"
    $Drive = (Get-Item $StoragePath).PSDrive
    $Volume = Get-Volume -DriveLetter $Drive.Name
    
    $UsedSpace = $Volume.Size - $Volume.SizeRemaining
    $UsedPercent = ($UsedSpace / $Volume.Size) * 100
    
    $Body = @"
Disk Usage Alert on Drive $($Drive.Name):

Current Usage: $([math]::Round($UsedPercent, 1))%
Used Space: $([math]::Round($UsedSpace / 1GB, 2)) GB
Free Space: $([math]::Round($Volume.SizeRemaining / 1GB, 2)) GB
Total Capacity: $([math]::Round($Volume.Size / 1GB, 2)) GB

RECOMMENDED ACTION:
- Archive or delete old backups in E:\appwrite-cloud\backups\
- Consider moving storage to larger disk
- Enable automatic cleanup in backup script

Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    Send-Alert -Subject "Disk Usage Critical: $([math]::Round($UsedPercent, 1))% full" -Body $Body -AlertType "ERROR"
}

function Send-HealthAlert {
    param([string]$HealthIssue = "Service health check failed")
    
    $HealthOutput = & "E:\flutterpos\docker\monitor-cloud-health.ps1" -Command health 2>&1
    
    $Body = @"
Health Check Alert:

Issue: $HealthIssue

Current Status:
$(($HealthOutput | Select-Object -Last 20) -join "`n")

RECOMMENDED ACTION:
1. Review full health report: .\monitor-cloud-health.ps1 -Command health
2. Check container logs: docker compose logs appwrite
3. Restart service if needed: docker compose restart appwrite
4. Contact support if issue persists

Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    Send-Alert -Subject "Health Check Alert: Services may be unhealthy" -Body $Body -AlertType "WARNING"
}

function Send-BackupAlert {
    param(
        [ValidateSet("SUCCESS", "FAILED")]
        [string]$Status = "FAILED",
        [string]$Details = ""
    )
    
    $AlertType = if ($Status -eq "SUCCESS") { "INFO" } else { "ERROR" }
    $Subject = "Backup $Status"
    
    $Body = @"
Backup Status: $Status

Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Location: E:\appwrite-cloud\backups\

Details:
$Details

RECENT BACKUPS:
$(Get-ChildItem "E:\appwrite-cloud\backups\" -Directory -ErrorAction SilentlyContinue | 
    Sort-Object -Property LastWriteTime -Descending | 
    Select-Object -First 5 | 
    ForEach-Object { "$($_.Name) - $([math]::Round((Get-ChildItem $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB" } | 
    Out-String)
"@
    
    Send-Alert -Subject $Subject -Body $Body -AlertType $AlertType
}

# ========================================
# Main Execution
# ========================================
switch ($Action) {
    "configure" {
        Configure-Alerts
    }
    
    "test" {
        Test-AlertConfiguration
    }
    
    "disk-alert" {
        Send-DiskAlert
    }
    
    "health-alert" {
        Send-HealthAlert
    }
    
    "backup-alert" {
        # Status and Details passed as arguments
        $Status = $args[0] -ne $null ? $args[0] : "FAILED"
        $Details = $args[1] -ne $null ? $args[1] : ""
        Send-BackupAlert -Status $Status -Details $Details
    }
}
