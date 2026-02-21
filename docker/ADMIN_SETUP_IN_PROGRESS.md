# Appwrite Cloud Automation - Admin Setup Guide

## What's Happening

You should now see a **new PowerShell window** with administrator privileges opening.

This window will automatically run:

```powershell
.\setup-automation.ps1 -Action install

```

Which will:

1. ✅ Create Windows Task Scheduler task: **Appwrite Cloud Backup** (Daily 2:00 AM)

2. ✅ Create Windows Task Scheduler task: **Appwrite Health Check** (Every 4 hours)

3. ✅ Create Windows Task Scheduler task: **Appwrite Disk Usage Alert** (Every 6 hours)

4. ✅ Create necessary log directories
5. ✅ Output confirmation of all tasks created

---

## What To Do In The Admin PowerShell Window

### When It Opens

1. **Read the output carefully** - It should show task creation confirmation

2. **Keep the window open** - It will display results and next steps

3. **Press Enter** when prompted - To review logs or next steps

4. **DO NOT close it** until you see "✅ Setup completed successfully!"

---

## Verification Checklist

### After the admin window completes, verify in normal PowerShell

```powershell

# Check Task Scheduler status

.\setup-automation.ps1 -Action status


# Output should show:

# ✓ Appwrite Cloud Backup (Daily at 2:00 AM)

# ✓ Appwrite Health Check (Every 4 hours)  

# ✓ Appwrite Disk Usage Alert (Every 6 hours)

```

### Or check Task Scheduler directly

1. Press `Win + R`

2. Type: `taskschd.msc`
3. Look for these three tasks under "Task Scheduler Library":

   - Appwrite Cloud Backup

   - Appwrite Health Check

   - Appwrite Disk Usage Alert

---

## Expected Output

The admin PowerShell should display something like:

```
✓ Creating Appwrite Cloud Backup task...

  - Schedule: Daily at 2:00 AM

  - Action: Backup database and storage

  - Status: ✅ Created

✓ Creating Appwrite Health Check task...

  - Schedule: Every 4 hours

  - Action: Monitor service health

  - Status: ✅ Created

✓ Creating Appwrite Disk Usage Alert task...

  - Schedule: Every 6 hours

  - Action: Check disk usage

  - Status: ✅ Created

✅ All automation tasks installed successfully!

```

---

## What's Next (After Admin Setup Completes)

### 1. Verify Tasks (5 min)

```powershell

# In normal PowerShell (non-admin):

cd e:\flutterpos\docker
.\setup-automation.ps1 -Action status

```

### 2. Test Backup (10 min)

```powershell

# Run manual backup

.\backup-cloud-storage.ps1


# Check backup created

Get-ChildItem E:\appwrite-cloud\backups\ -Recurse

```

### 3. Configure Alerts (Optional, 5 min)

```powershell

# Interactive alert setup

.\setup-alerts.ps1 -Action configure


# Test email

.\setup-alerts.ps1 -Action test

```

---

## Troubleshooting

### If the admin window doesn't open

1. Close any dialogs (UAC prompt may be hidden)
2. Check taskbar for admin PowerShell window
3. Alt+Tab to switch to it
4. Or manually run:

   ```
   Right-click PowerShell → Run as Administrator
   cd e:\flutterpos\docker
   .\setup-automation.ps1 -Action install
   ```

### If the setup fails

1. Read the error message carefully
2. Check prerequisites:

   - Docker is running: `docker ps`

   - Network access: `ping google.com`

   - Disk space: `.\monitor-cloud-health.ps1 -Command disk-usage`

3. Try again with verbose output:

   ```powershell
   .\setup-automation.ps1 -Action install -Verbose
   ```

### If tasks don't appear in Task Scheduler

1. Refresh Task Scheduler (F5)
2. Check task status: `.\setup-automation.ps1 -Action status`
3. Run setup again: `.\setup-automation.ps1 -Action install`

---

## Admin Window Behavior

- **Stays open by default** - Shows all output and next steps

- **Close when done** - After you've reviewed the confirmation

- **May take 1-2 minutes** - Creating scheduler tasks

- **Will show any errors** - Read them carefully if they appear

---

## Success Indicators

✅ **Setup Complete When:**

- Admin window shows "✅ All tasks installed successfully!"

- Task Scheduler contains 3 Appwrite tasks

- Status check shows: `✓ Appwrite Cloud Backup`, `✓ Health Check`, `✓ Disk Check`

- First backup will run at 2:00 AM tomorrow

---

## Timeline

- **Right now**: Admin setup running in new window

- **In 1-2 minutes**: Admin setup completes

- **Next step**: Verify with `setup-automation.ps1 -Action status`

- **Tomorrow 2 AM**: First automatic backup runs

- **Next 4 hours**: First health check runs

- **Next 6 hours**: First disk usage check runs

---

**The admin PowerShell window should be opening now. Check your taskbar! 👀**
