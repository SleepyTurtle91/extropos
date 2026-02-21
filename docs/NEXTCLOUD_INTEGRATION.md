# Nextcloud Integration Guide

## Overview

FlutterPOS now uses **Nextcloud** instead of Google Drive for cloud backup storage. This provides:

- ✅ **No OAuth complexity** - Simple username + app password

- ✅ **Self-hosted** - Full control over your data

- ✅ **WebDAV protocol** - Standard, reliable, cross-platform

- ✅ **No API limits** - Unlimited backups

- ✅ **Privacy** - Your data stays on your infrastructure

---

## Architecture

### Backup Strategy

```text
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   POS App   │────────>│   RabbitMQ   │<────────│  Backend    │
│  (Counter)  │ Real-   │ (Real-time)  │  Real-  │    App      │

│             │ time    │              │  time   │             │
└─────────────┘ Sync    └──────────────┘  Sync   └─────────────┘
      │                                                  │
      │                                                  │
      │ Nightly                                   Nightly│
      │ Backup                                    Backup │
      ▼                                                  ▼
┌─────────────────────────────────────────────────────────────┐
│                     Nextcloud Server                        │
│                  (WebDAV Cloud Storage)                     │
│                                                              │
│  /backups/flutterpos/                                       │
│  ├── flutterpos_backup_1732780800000.db                    │
│  ├── flutterpos_backup_1732867200000.db                    │
│  └── flutterpos_backup_1732953600000.db                    │
└─────────────────────────────────────────────────────────────┘

```text


### Workflow


1. **Real-time Sync** (via RabbitMQ)

   - Product updates

   - Price changes

   - Category modifications

   - Instant propagation to all connected devices

2. **Scheduled Backups** (via Nextcloud)

   - Nightly at midnight (00:00)

   - Full SQLite database backup

   - Automatic cleanup (keep last 30 backups)

   - Upload to Nextcloud via WebDAV

3. **Manual Operations**

   - Upload backup on demand

   - Download and restore any backup

   - List all available backups

   - Delete old backups

---


## Setup Instructions



### Step 1: Start Nextcloud Server



```bash
cd /home/abber/Documents/flutterpos/docker


# Start Nextcloud

./setup-nextcloud.sh


# Wait for initialization (1-2 minutes)

```text

**Expected Output:**


```text
✅ Nextcloud is running!

🌐 Web Interface:
   Local: http://localhost:8080
   Network: http://192.168.1.234:8080

👤 Admin Credentials:
   Username: admin
   Password: admin123

```text


### Step 2: Initial Nextcloud Configuration


1. **Open Nextcloud in browser:**

   ```

   <http://192.168.1.234:8080>

   ```

2. **Login:**

   - Username: `admin`

   - Password: `admin123`

3. **Change admin password:**

   - Click avatar → Settings

   - Personal → Security

   - Change password to something secure

4. **Create backup folder:**

   - Click Files

   - New → New folder

   - Name: `backups`

   - Open `backups` → New folder → `flutterpos`

5. **Generate App Password for POS:**

   - Settings → Security

   - App passwords section

   - App name: `FlutterPOS Backend`

   - Click "Create new app password"

   - **IMPORTANT:** Copy the generated password (e.g., `xxxxx-xxxxx-xxxxx-xxxxx-xxxxx`)


### Step 3: Configure Backend App


1. **Open Backend app** on tablet/PC

2. **Navigate to Nextcloud Settings:**

   - Settings (gear icon) → Nextcloud Settings

   - OR

   - Menu → Nextcloud Settings

3. **Fill in connection details:**

   ```

  Server URL: <https://extropos.duckdns.org> (external) or <http://192.168.1.234:8080> (LAN)
   Username: admin
   App Password: xxxxx-xxxxx-xxxxx-xxxxx-xxxxx (from Step 2.5)
   Backup Path: /backups/flutterpos

   ```

4. **Test connection:**

   - Click "Test Connection"

   - Should show: ✅ Connection successful!

5. **Enable Nextcloud:**

   - Toggle "Enable Nextcloud" ON

   - Toggle "Auto Backup" ON (for nightly backups)

   - Click "Save Settings"

6. **Test manual backup:**

   - Click "Upload Now"

   - Should show: ✅ Backup uploaded successfully

   - Verify in Nextcloud web interface

---


## Flutter/Dart Code Usage



### Upload Backup



```dart
import 'package:extropos/services/nextcloud_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'dart:io';

Future<void> uploadBackup() async {
  final nextcloud = NextcloudService.instance;
  
  // Get database file
  final dbPath = await DatabaseHelper.instance.getDatabasePath();
  final dbFile = File(dbPath);
  
  // Upload to Nextcloud
  final success = await nextcloud.uploadBackup(dbFile);
  
  if (success) {
    print('✅ Backup uploaded successfully');
  } else {
    print('❌ Backup upload failed');
  }
}

```text


### List Backups



```dart
Future<void> listBackups() async {
  final nextcloud = NextcloudService.instance;
  
  final backups = await nextcloud.listBackups();
  
  for (final backup in backups) {
    print('${backup.formattedDate} - ${backup.sizeFormatted}');
  }
}

```text


### Download and Restore Backup



```dart
Future<void> restoreBackup(NextcloudBackup backup) async {
  final nextcloud = NextcloudService.instance;
  
  // Get database path
  final dbPath = await DatabaseHelper.instance.getDatabasePath();
  
  // Download and replace current database
  final success = await nextcloud.downloadBackup(backup, dbPath);
  
  if (success) {
    print('✅ Backup restored. Please restart the app.');
  } else {
    print('❌ Restore failed');
  }
}

```text


### Configure Nextcloud Programmatically



```dart
Future<void> configureNextcloud() async {
  final nextcloud = NextcloudService.instance;
  
  final success = await nextcloud.configure(
    serverUrl: 'http://192.168.1.234:8080',
    username: 'admin',
    password: 'xxxxx-xxxxx-xxxxx-xxxxx-xxxxx',
    backupPath: '/backups/flutterpos',
    enabled: true,
    autoBackup: true,
  );
  
  if (success) {
    print('✅ Nextcloud configured');
  }
}

```text

---


## Docker Management



### Start Nextcloud



```bash
cd /home/abber/Documents/flutterpos/docker
docker compose -f docker-compose-nextcloud.yml up -d

```text


### Stop Nextcloud



```bash
docker compose -f docker-compose-nextcloud.yml down

```text


### View Logs



```bash
docker compose -f docker-compose-nextcloud.yml logs -f nextcloud

```text


### Restart Nextcloud



```bash
docker compose -f docker-compose-nextcloud.yml restart

```text


### Backup Nextcloud Data



```bash

# Backup entire Nextcloud data folder

tar -czf nextcloud_backup_$(date +%Y%m%d).tar.gz \
  nextcloud_data nextcloud_db nextcloud_config


# Restore from backup

tar -xzf nextcloud_backup_YYYYMMDD.tar.gz

```text

---


## Scheduled Backups Implementation



### Option 1: Using Cron (Linux)


Add to Backend app initialization:


```dart
// lib/services/backup_scheduler.dart
import 'dart:async';
import 'package:extropos/services/nextcloud_service.dart';
import 'package:extropos/services/database_helper.dart';

class BackupScheduler {
  static final BackupScheduler instance = BackupScheduler._internal();
  BackupScheduler._internal();

  Timer? _timer;

  void startScheduledBackups() {
    // Calculate time until next midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);

    // Schedule first backup at midnight
    _timer = Timer(duration, () {
      _performBackup();
      
      // Then repeat every 24 hours
      _timer = Timer.periodic(const Duration(hours: 24), (timer) {
        _performBackup();
      });
    });

    print('📅 Scheduled backups configured. Next backup at: $nextMidnight');
  }

  Future<void> _performBackup() async {
    final nextcloud = NextcloudService.instance;
    
    if (!nextcloud.isEnabled || !nextcloud.autoBackup) {
      return;
    }

    print('🌙 Running nightly backup...');

    final dbPath = await DatabaseHelper.instance.getDatabasePath();
    final dbFile = File(dbPath);
    
    final success = await nextcloud.uploadBackup(dbFile);
    
    if (success) {
      print('✅ Nightly backup completed successfully');
    } else {
      print('❌ Nightly backup failed');
    }
  }

  void stopScheduledBackups() {
    _timer?.cancel();
    _timer = null;
  }
}

```text

Add to `main_backend.dart`:


```dart
import 'services/backup_scheduler.dart';

void main() async {
  // ... existing initialization

  await NextcloudService.instance.initialize();
  
  // Start scheduled backups if enabled
  if (NextcloudService.instance.autoBackup) {
    BackupScheduler.instance.startScheduledBackups();
  }

  runApp(const MyApp());
}

```text


### Option 2: Using Android WorkManager


For Android devices, use `workmanager` package for reliable background tasks:


```yaml

# pubspec.yaml

dependencies:
  workmanager: ^0.5.2

```text


```dart
// Initialize in main()
Workmanager().initialize(callbackDispatcher);

// Register periodic task
Workmanager().registerPeriodicTask(
  "nextcloud-backup",
  "performBackup",
  frequency: const Duration(hours: 24),
  initialDelay: Duration(
    hours: 24 - DateTime.now().hour,
    minutes: -DateTime.now().minute,
  ),
  constraints: Constraints(
    networkType: NetworkType.connected,
  ),
);

```text

---


## Troubleshooting



### Connection Failed


**Error:** ❌ Connection failed. Check your credentials.

**Solutions:**

1. Verify server URL is correct (include `http://` or `https://`)
2. Check network connectivity: `ping 192.168.1.234`
3. Ensure Nextcloud is running: `docker ps | grep nextcloud`
4. Verify app password is correct (regenerate if needed)
5. Check firewall: `sudo firewall-cmd --list-ports` (should include `8080/tcp`)


### Upload Failed


**Error:** ❌ Failed to upload backup

**Solutions:**

1. Check backup path exists in Nextcloud
2. Verify app password has write permissions
3. Check disk space on Nextcloud server
4. Review Nextcloud logs: `docker logs nextcloud`


### Download Failed


**Error:** ❌ Failed to download backup

**Solutions:**

1. Check if backup file exists on Nextcloud
2. Verify local storage has enough space
3. Check app has write permissions to database directory


### Nextcloud Won't Start


**Error:** Docker container fails to start

**Solutions:**


```bash

# Check logs

docker compose -f docker-compose-nextcloud.yml logs


# Reset Nextcloud (WARNING: Deletes all data)

docker compose -f docker-compose-nextcloud.yml down -v
rm -rf nextcloud_*
./setup-nextcloud.sh

```text

---


## Security Best Practices


1. **Change Default Password:**

   - Never use `admin123` in production

   - Use strong, unique password

2. **Use HTTPS:**

   - For production, configure reverse proxy with SSL

   - Example: nginx with Let's Encrypt

3. **Restrict Access:**

   - Configure firewall to allow only trusted IPs

   - Use VPN for remote access

4. **App Passwords:**

   - Use separate app password for each device

   - Revoke compromised passwords immediately

5. **Regular Backups:**

   - Backup Nextcloud data folder weekly

   - Test restore procedure

6. **Monitor Logs:**

   ```bash
   docker logs nextcloud | grep -i error
   ```

---

## Migration from Google Drive

### Disable Google Drive

1. Open Backend app
2. Settings → Google Account Settings
3. Click "Disconnect Google Account"

### Enable Nextcloud

1. Follow setup instructions above
2. Test with manual backup
3. Enable auto-backup

### Migrate Existing Backups (Optional)

Google Drive backups can't be automatically migrated. Options:

1. **Start fresh** - Use Nextcloud for new backups going forward

2. **Manual download** - Download Google Drive backups manually, then upload to Nextcloud web interface

---

## Comparison: Google Drive vs Nextcloud

| Feature | Google Drive | Nextcloud |
|---------|--------------|-----------|
| **Setup Complexity** | High (OAuth 2.0) | Low (username + password) |

| **Developer Account** | Required | Not required |

| **API Limits** | Yes (quotas) | No limits |

| **Data Privacy** | Google servers | Your server |

| **Cost** | Free (15GB limit) | Free (unlimited on your hardware) |

| **Network** | Internet required | LAN works fine |

| **Authentication** | OAuth token refresh | Simple credentials |

| **Backup Speed** | Depends on internet | Fast on LAN |

---

## Files Modified

1. **lib/services/nextcloud_service.dart** (NEW)

   - WebDAV client wrapper

   - Upload/download/list/delete backups

   - Configuration management

2. **lib/screens/nextcloud_settings_screen.dart** (NEW)

   - UI for Nextcloud configuration

   - Backup management interface

   - Test connection feature

3. **docker/docker-compose-nextcloud.yml** (NEW)

   - Nextcloud + MariaDB stack

   - Persistent volume mounts

4. **docker/setup-nextcloud.sh** (NEW)

   - One-command Nextcloud setup

   - Configuration helper

5. **pubspec.yaml** (MODIFIED)

   - Added `webdav_client: ^1.2.5`

---

## Next Steps

1. ✅ **Start Nextcloud**: Run `./setup-nextcloud.sh`
2. ✅ **Configure Backend**: Add Nextcloud settings in app
3. ✅ **Test Manual Backup**: Upload one backup to verify
4. ✅ **Enable Auto-Backup**: Turn on nightly backups
5. ⬜ **Add to Backend Menu**: Link Nextcloud Settings screen
6. ⬜ **Implement Scheduler**: Add nightly backup timer
7. ⬜ **Production SSL**: Configure HTTPS for security

---

## Support

For issues or questions:

1. Check Nextcloud logs: `docker logs nextcloud`
2. Review app logs in console
3. Verify network connectivity
4. Consult Nextcloud documentation: <https://docs.nextcloud.com/>

**Version**: 1.0.14  
**Date**: November 28, 2025  
**Author**: FlutterPOS Team
