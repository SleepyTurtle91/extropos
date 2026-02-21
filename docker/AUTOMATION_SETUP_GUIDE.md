# Appwrite Cloud Automation Setup Guide

## Overview

This guide walks you through setting up automated backups and monitoring for your Appwrite cloud infrastructure.

**Requirements:**

- Windows PowerShell (runs best in PowerShell 5.1+)

- Administrator privileges (for Task Scheduler)

- Email account (for alerts - optional)

---

## Part 1: Setup Automation Tasks (Administrator Required)

### Step 1: Open PowerShell as Administrator

1. Press `Win + X` and select "Windows PowerShell (Admin)"

2. Or: Right-click PowerShell → "Run as administrator"

### Step 2: Run Automation Setup

```powershell
cd e:\flutterpos\docker
.\setup-automation.ps1 -Action install

```

This will create three scheduled tasks:

- **Appwrite Cloud Backup** - Daily at 2:00 AM (database + storage)

- **Appwrite Health Check** - Every 4 hours (service health monitoring)

- **Appwrite Disk Usage Alert** - Every 6 hours (disk space monitoring)

### Step 3: Verify Tasks Created

```powershell

# Check status

.\setup-automation.ps1 -Action status


# Output should show:

# ✓ Appwrite Cloud Backup

# ✓ Appwrite Health Check

# ✓ Appwrite Disk Usage Alert

```

### Step 4: Test Tasks (Optional)

```powershell

# Run tests immediately

.\setup-automation.ps1 -Action test


# This will:

# 1. Display task status

# 2. Run each task once

# 3. Show results and logs

```

---

## Part 2: Setup Email Alerts (Optional but Recommended)

### Step 1: Configure Alert Credentials

```powershell
cd e:\flutterpos\docker
.\setup-alerts.ps1 -Action configure

```

You'll be prompted for:

- **Sender email**: Email address to send alerts FROM (e.g., <appwrite-monitoring@gmail.com>)

- **Recipient email**: Email to receive alerts TO (your email)

- **SMTP server**: Usually smtp.gmail.com (for Gmail) or your email provider's SMTP

- **SMTP username**: Your email address

- **SMTP password**: Your email password or app-specific password

**Note for Gmail Users:**

- Use your Gmail address as SMTP username

- Generate an [App Password](https://support.google.com/accounts/answer/185833) (not your regular password)

- Use the app password in the setup

### Step 2: Test Alert Configuration

```powershell
.\setup-alerts.ps1 -Action test

```

Check your email for a test message. If received, alerts are working!

### Step 3: Manual Alert Testing (Optional)

```powershell

# Test disk usage alert

.\setup-alerts.ps1 -Action disk-alert


# Test health check alert

.\setup-alerts.ps1 -Action health-alert


# Test backup completion alert

.\setup-alerts.ps1 -Action backup-alert -Status SUCCESS

```

---

## Part 3: Verify Everything is Running

### Check Task Scheduler Directly

1. Press `Win + R`

2. Type `taskschd.msc` and press Enter
3. Look for these tasks under "Task Scheduler Library":

   - Appwrite Cloud Backup

   - Appwrite Health Check

   - Appwrite Disk Usage Alert

### Check Logs

```powershell

# View backup logs

Get-Content E:\appwrite-cloud\logs\backup_*.log -Tail 20


# View health check logs

Get-Content E:\appwrite-cloud\logs\health_*.log -Tail 20


# View disk check logs

Get-Content E:\appwrite-cloud\logs\disk_*.log -Tail 20


# View all recent logs

Get-ChildItem E:\appwrite-cloud\logs\ | Sort-Object LastWriteTime -Descending | Select-Object -First 10

```

---

## Part 4: Backup Verification

### First Backup (Manual)

```powershell
cd e:\flutterpos\docker
.\backup-cloud-storage.ps1

```

Check the output:

```
✓ Database backup completed: appwrite_database_20260128_020000.sql.zip
✓ Storage backup completed: appwrite_storage_20260128_020000.zip
✓ .env backup completed

```

### View Backups

```powershell

# List all backups

Get-ChildItem E:\appwrite-cloud\backups\ -Recurse -File | Sort-Object LastWriteTime -Descending


# Get backup statistics

$Backups = Get-ChildItem E:\appwrite-cloud\backups\ -File -Recurse
"Total backups: $($Backups.Count)"
"Total size: $([math]::Round(($Backups | Measure-Object -Property Length -Sum).Sum / 1GB, 2)) GB"

```

---

## Monitoring Dashboard

### Daily Status Check

```powershell
cd e:\flutterpos\docker


# Quick health check

.\monitor-cloud-health.ps1 -Command health


# Disk usage

.\monitor-cloud-health.ps1 -Command disk-usage


# Database size

.\monitor-cloud-health.ps1 -Command db-size


# View logs

docker compose logs appwrite | tail -50

```

### Weekly Deep Dive

```powershell

# Full status report

.\setup-automation.ps1 -Action status


# Check backup integrity

$Backups = Get-ChildItem E:\appwrite-cloud\backups\ -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($Backups) {
    Write-Host "Latest backup: $($Backups.Name)"
    Write-Host "Files: $(Get-ChildItem $Backups.FullName -File | Measure-Object).Count"
    Write-Host "Size: $([math]::Round((Get-ChildItem $Backups.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB"
}


# Check for errors in logs

Select-String "ERROR|FAILED" E:\appwrite-cloud\logs\*.log | Select-Object -Last 10

```

---

## Troubleshooting

### Tasks Not Running

```powershell

# Check if Task Scheduler service is running

Get-Service -Name "Schedule" | Select-Object Status


# If stopped, restart it

Start-Service -Name "Schedule"

```

### Email Alerts Not Sending

```powershell

# Test SMTP connection

$Config = Get-Content E:\appwrite-cloud\notifications\alert-config.json | ConvertFrom-Json

# Try to connect manually:

# telnet $Config.SmtpServer $Config.SmtpPort



# Common issues:

# 1. Wrong SMTP server or port

# 2. Gmail app password not used

# 3. Email account 2FA enabled without app password

# 4. Firewall blocking outbound SMTP

```

### Backup Failing

```powershell

# Check Docker is running

docker ps


# Check database health

docker exec appwrite-mariadb mysqladmin ping -u appwrite -p


# Check disk space

.\monitor-cloud-health.ps1 -Command disk-usage


# Run backup with verbose output

.\backup-cloud-storage.ps1 -BackupPath "E:\appwrite-cloud\backups" -RetentionDays 30 -Verbose

```

### High Disk Usage

```powershell

# Check what's using space

Get-ChildItem E:\appwrite-cloud\ -Recurse | 
    Group-Object -Property Directory | 
    Select-Object -Property @{Name='Path';Expression={$_.Name}}, @{Name='Size(MB)';Expression={[math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1MB, 2)}} | 
    Sort-Object -Property "Size(MB)" -Descending


# Clean old backups manually

Remove-Item E:\appwrite-cloud\backups\2026-01-* -Recurse -Force

```

---

## Automation Features Summary

### Backup Task (Daily at 2:00 AM)

- ✅ Exports MariaDB database to compressed SQL

- ✅ Backs up storage directory

- ✅ Backs up configuration files

- ✅ Maintains 30-day retention (auto-cleanup)

- ✅ Logs all operations

### Health Check (Every 4 Hours)

- ✅ Monitors all containers

- ✅ Tests API endpoint

- ✅ Tests database connectivity

- ✅ Tests cache (Redis) connectivity

- ✅ Logs results

- ✅ Can send alert if issues detected

### Disk Usage Check (Every 6 Hours)

- ✅ Monitors E:\ drive usage

- ✅ Alerts if usage >80%

- ✅ Shows breakdown by directory

- ✅ Logs all checks

### Email Notifications

- ✅ Backup completion alerts

- ✅ Health check warnings

- ✅ Disk usage alerts

- ✅ Customizable thresholds

- ✅ Supports Gmail, Outlook, and other SMTP providers

---

## Maintenance Checklist

### Weekly

- [ ] Check backup logs for errors

- [ ] Review disk usage trends

- [ ] Verify email alerts are being received

### Monthly

- [ ] Test restore from backup

- [ ] Archive backups older than 30 days to off-site storage

- [ ] Review and update SMTP credentials if needed

- [ ] Check for any recurring issues in logs

### Quarterly

- [ ] Full disaster recovery drill

- [ ] Update documentation

- [ ] Review and adjust retention policies

---

## Support

### Getting Help

1. **Check logs first**: `Get-ChildItem E:\appwrite-cloud\logs\ | tail`
2. **Run health check**: `.\monitor-cloud-health.ps1 -Command health`
3. **Review Task Status**: Open Task Scheduler and check task history
4. **Check Docker**: `docker compose ps` and `docker compose logs`

### Common Commands Reference

```powershell

# Start stack

docker compose up -d


# Stop stack

docker compose down


# View real-time logs

docker compose logs -f


# Check container health

docker compose ps


# Manual backup

.\backup-cloud-storage.ps1


# Restore from backup

.\monitor-cloud-health.ps1 -Command restore -RestoreFile "path/to/backup.zip"


# Health check

.\monitor-cloud-health.ps1 -Command health


# Disk usage

.\monitor-cloud-health.ps1 -Command disk-usage

```

---

**Installation Complete! Your Appwrite cloud infrastructure is now fully automated.** ✅

Next steps:

1. Verify all tasks appear in Task Scheduler
2. Test first backup and email alert
3. Monitor logs for the first week
4. Update backup strategy based on your actual backup size and frequency

For detailed operations guide, see: `APPWRITE_CLOUD_OPERATIONS.md`
