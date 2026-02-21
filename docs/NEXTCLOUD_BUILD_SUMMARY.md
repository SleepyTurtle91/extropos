# Nextcloud Integration Build Summary

**Date**: November 28, 2025  
**Version**: 1.0.14+14  
**Build Type**: Release APKs with Nextcloud Cloud Backup

---

## ✅ What Was Done

### 1. Nextcloud Service Implementation

- Created `lib/services/nextcloud_service.dart` (285 lines)

- WebDAV client for cloud backups (upload, download, list, delete)

- Offline-first architecture (no OAuth complexity like Google Drive)

- Auto-initialization in both POS and Backend apps

### 2. Nextcloud Settings UI

- Created `lib/screens/nextcloud_settings_screen.dart` (540 lines)

- Configuration form: server URL, username, app password, backup path

- Features: test connection, manual upload, backup list, restore

- Integrated into Backend app menu (Settings → Nextcloud Settings)

### 3. Docker Server Deployment

- Created `docker/docker-compose-nextcloud.yml`

- Services: Nextcloud 28-apache + MariaDB 11 + Redis 7

- Named volumes (fixes permission issues)

- Port: 8080 (exposed on 192.168.1.234)

### 4. App Initialization

- **Backend App** (`lib/main_backend.dart`):

  - Line 24: Import NextcloudService

  - Lines 95-101: Initialize NextcloudService on startup

- **POS App** (`lib/main.dart`):

  - Line 30: Import NextcloudService

  - Lines 98-103: Initialize NextcloudService on startup

### 5. Documentation Created

- `docs/NEXTCLOUD_INTEGRATION.md` - Complete integration guide

- `docs/GOOGLE_SIGNIN_SETUP.md` - OAuth setup (for Google Drive alternative)

- `docs/DISPLAY_MODE_GUIDE.md` - Backend touchscreen/desktop modes

---

## 📦 Built APKs

| Flavor | Size | Location | Features |
|--------|------|----------|----------|
| **Backend** | 77MB | `~/Desktop/FlutterPOS-v1.0.14-20251128-backend-nextcloud.apk` | Nextcloud Settings UI, cloud backup management |

| **POS** | 83MB | `~/Desktop/FlutterPOS-v1.0.14-20251128-pos-nextcloud.apk` | Nextcloud service initialized (for future POS backup support) |

**Build Output**:

```text
build/app/outputs/flutter-apk/
├── app-backendapp-release.apk (77MB)
└── app-posapp-release.apk (83MB)

```text

---


## 🌐 Nextcloud Server Status


**Access**: <https://extropos.duckdns.org> (external) or <http://192.168.1.234:8080> (LAN)
**Login**: admin / admin123  
**Status**: ✅ Running (Apache 2.4.62, PHP 8.2.27)

**Docker Containers**:


```text
nextcloud         Up 38 minutes  0.0.0.0:8080->80/tcp
nextcloud-db      Up 38 minutes  3306/tcp (MariaDB 11)
nextcloud-redis   Up 38 minutes  6379/tcp (Redis 7)

```text

**Volumes**:


- `nextcloud_data` - Nextcloud files and apps

- `nextcloud_db` - MariaDB database

---


## 🔧 How to Use Nextcloud



### First-Time Setup (Backend App)


1. **Open Nextcloud Web Interface**:

   - URL: <https://extropos.duckdns.org> (external) or <http://192.168.1.234:8080> (LAN)

   - Login: admin / admin123

   - Navigate to Settings → Security → Devices & Sessions

   - Create new App Password (name: "FlutterPOS Backend")

   - Copy the generated password

2. **Configure in Backend App**:

   - Open Backend app on tablet

   - Go to: ☰ Menu → Nextcloud Settings

   - Fill in:

     - Server URL: `http://192.168.1.234:8080`

     - Username: `admin`

     - App Password: (paste from Nextcloud)

     - Backup Path: `/backups/flutterpos` (or custom path)

   - Tap "Test Connection" → Should show ✅ Success

   - Enable "Use Nextcloud for Backups"

   - (Optional) Enable "Auto Backup Daily"

3. **Create Backup Folder in Nextcloud**:

   - In Nextcloud web UI, click "Files"

   - Create folder: `backups/flutterpos`

   - This folder will store all database backups

4. **Upload First Backup**:

   - In Backend app → Nextcloud Settings

   - Tap "Upload Backup Now"

   - Check Nextcloud web UI → Should see `flutterpos_backup_YYYYMMDD_HHMMSS.db`

5. **Restore Backup**:

   - In Backend app → Nextcloud Settings

   - Tap "List Backups" → Shows all backups with dates and sizes

   - Tap on any backup → "Download" → Restore database

---


## 🔄 Architecture



### Backup Flow



```text
POS/Backend App (SQLite)
    ↓
NextcloudService.uploadBackup()
    ↓
WebDAV Upload
    ↓
Nextcloud Server (/backups/flutterpos/)
    ↓
MariaDB + File Storage

```text


### Real-Time Sync (RabbitMQ)


- **Separate System**: RabbitMQ handles real-time order/table/product sync

- **Nextcloud Role**: Nightly database backups only (not real-time)

- **Ports**: RabbitMQ (5672), Nextcloud (8080)

---


## 📝 Key Differences from Google Drive


| Feature | Google Drive | Nextcloud |
|---------|-------------|-----------|
| **Authentication** | OAuth 2.0 (complex) | Username + App Password (simple) |

| **Hosting** | Cloud (Google) | Self-hosted (your server) |

| **Internet Required** | Yes (always) | Only for sync (local network works) |

| **Data Control** | Google owns | You own |

| **Cost** | Free tier → Paid | Free (self-hosted) |

| **Setup Complexity** | OAuth config, Google Cloud Console | Docker compose up |

---


## 🧪 Testing Checklist



### Backend App


- [ ] Install APK on Backend tablet (192.168.1.80)

- [ ] Open Nextcloud Settings

- [ ] Test connection to server

- [ ] Upload backup manually

- [ ] Check Nextcloud web UI for uploaded file

- [ ] Download and restore backup

- [ ] Enable auto-backup

- [ ] Wait 24 hours and verify auto-backup works


### POS App


- [ ] Install APK on POS tablet (192.168.1.241)

- [ ] Verify app starts without errors (Nextcloud service initializes silently)

- [ ] (Future) Add Nextcloud Settings to POS app for cashier backups

---


## 🐛 Troubleshooting



### "Connection Failed" in App


1. Check Nextcloud server is running: `docker ps | grep nextcloud`
2. Test from PC: `curl -I http://192.168.1.234:8080` → Should return 200 or 302
3. Check firewall: `sudo firewall-cmd --list-ports` → Should show 8080/tcp
4. Verify network: Ping 192.168.1.234 from tablet


### "Invalid Credentials"


1. Use App Password, NOT admin account password
2. Generate new App Password in Nextcloud web UI
3. Copy exact password without spaces


### "Folder Not Found"


1. Create `/backups/flutterpos` folder in Nextcloud web UI first
2. Use leading slash: `/backups/flutterpos` (not `backups/flutterpos`)


### Docker Containers Keep Restarting


1. Check logs: `docker compose logs nextcloud-db`
2. If permission errors, ensure using named volumes (not bind mounts)
3. Restart: `docker compose down && docker compose up -d`

---


## 📚 Related Documentation


- **Full Integration Guide**: `docs/NEXTCLOUD_INTEGRATION.md`

- **Docker Management**: `docker/docker-compose-nextcloud.yml`

- **Setup Script**: `docker/setup-nextcloud.sh`

- **Display Modes**: `docs/DISPLAY_MODE_GUIDE.md`

- **Google Drive Alternative**: `docs/GOOGLE_SIGNIN_SETUP.md`

---


## 🚀 Next Steps


1. **Install APKs on tablets** (when they reconnect):

   ```bash
   # Backend tablet (192.168.1.80)

   adb connect 192.168.1.80:5555
   adb install ~/Desktop/FlutterPOS-v1.0.14-20251128-backend-nextcloud.apk
   
   # POS tablet (192.168.1.241)

   adb connect 192.168.1.241:5555
   adb install ~/Desktop/FlutterPOS-v1.0.14-20251128-pos-nextcloud.apk
   ```

1. **Configure Nextcloud in Backend App** (see "First-Time Setup" above)

2. **Test Backup Workflow**:

   - Upload → Verify in web UI → Download → Restore

3. **(Optional) Add Nextcloud to POS App Settings**:

   - Create Nextcloud Settings screen in POS flavor

   - Add to POS Settings menu

   - Allow cashiers to backup/restore from POS tablets

4. **Monitor Auto-Backup**:

   - Check Nextcloud folder daily

   - Verify old backups are cleaned up (optional: add retention policy)

---

## ✅ Build Verification

```bash

# Code Analysis (0 issues)

flutter analyze lib/main.dart lib/main_backend.dart

# ✅ No issues found! (ran in 6.2s)



# APK Sizes

-rw-r--r--. 1 abber abber 77M  backend-nextcloud.apk
-rw-r--r--. 1 abber abber 83M  pos-nextcloud.apk


# Docker Status

nextcloud         Up 38 minutes  ✅
nextcloud-db      Up 38 minutes  ✅
nextcloud-redis   Up 38 minutes  ✅


# Nextcloud HTTP Response

curl -I http://localhost:8080

# HTTP/1.1 302 Found  ✅

```text

---


## 🎯 Summary


**What Changed**:


- ✅ Nextcloud service added to both POS and Backend apps

- ✅ Nextcloud Settings UI added to Backend app menu

- ✅ Docker server running on port 8080

- ✅ Both APKs built with Nextcloud integration (v1.0.14)

- ✅ Ready for production testing

**Ready to Use**:


- Install APKs on tablets

- Configure Nextcloud connection in Backend app

- Start backing up databases to self-hosted cloud

**Advantages**:


- No Google OAuth complexity

- Full data control (self-hosted)

- Works on local network (no internet required for LAN access)

- Free (no cloud storage costs)

- Simple username + app password authentication
