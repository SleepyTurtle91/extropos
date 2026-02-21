# ✅ Appwrite Docker Configuration Complete

**Date**: 2025-12-10  
**Status**: Running and Ready

---

## 🚀 Your Appwrite Setup

### Connection Details

**For Local Development (Same Machine)**:

- **Endpoint**: `http://localhost:8080/v1`

- **Console**: `http://localhost:8080`

- **Version**: 1.7.5

**For Network Access (Android Devices on Same WiFi)**:

- **Endpoint**: `http://192.168.0.145:8080/v1`

- **Console**: `http://192.168.0.145:8080`

- **Your Server IP**: `192.168.0.145`

### Default Credentials

- **Project ID**: `default` (create new projects in console)

- **Database**: Create via Appwrite Console

- **Collections**: Create via Appwrite Console

---

## 📋 Running Services

```bash
✓ docker-appwrite-1     - Main Appwrite API (Port 8080, 9443)

✓ docker-mariadb-1      - Database Backend

✓ docker-redis-1        - Cache & Sessions

```

---

## 🔧 Quick Commands

### Check Status

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose -f appwrite-compose.yml ps

```

### View Logs

```bash
docker logs docker-appwrite-1 -f

```

### Stop Appwrite

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose -f appwrite-compose.yml down

```

### Start Appwrite

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose -f appwrite-compose.yml up -d

```

### Restart Appwrite

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose -f appwrite-compose.yml restart

```

---

## 📱 Configure FlutterPOS Apps

### Backend App Configuration

1. Open **FlutterPOS Backend** app

2. Navigate to **Settings → Appwrite Configuration**
3. Enter:

   - **Endpoint**: `http://192.168.0.145:8080/v1` (for Android) or `http://localhost:8080/v1` (for desktop)

   - **Project ID**: Create in Appwrite Console first

   - **Database ID**: `extropos_db` (create in console)

4. Tap **"Test Connection"** - should succeed

5. Tap **"Save Config"**

### POS App Configuration

Same as Backend app configuration above.

---

## 🌐 Access Appwrite Console

1. Open browser: `http://localhost:8080` (or `http://192.168.0.145:8080` from other devices)
2. Create an account (first user becomes admin)
3. Create a new project for FlutterPOS
4. Copy the **Project ID** for use in apps

5. Create database named `extropos_db`
6. Create collections as needed:

   - `business_info`

   - `categories`

   - `products`

   - `modifiers`

   - `tables`

   - `users`

---

## 🔐 Security Notes

**Current Setup**: Development mode (localhost access)

For production deployment:

- Configure domain in `.env` file

- Enable SSL/HTTPS

- Set proper firewall rules

- Use strong passwords (already set in appwrite-compose.yml)

---

## 📊 Data Persistence

Your Appwrite data is stored at:

```
/mnt/storage/appwrite/
├── mysql/      - Database files

├── redis/      - Cache data

├── config/     - Configuration

└── storage/    - File uploads

```

**Backup**: These directories contain all your Appwrite data. Back them up regularly.

---

## ✅ Next Steps

1. ✅ **Docker Appwrite Running** - DONE

2. 🔲 **Access Console** - `http://localhost:8080`

3. 🔲 **Create Project** - Get Project ID

4. 🔲 **Create Database** - Name: `extropos_db`

5. 🔲 **Create Collections** - 6 collections needed

6. 🔲 **Configure Backend App** - Add endpoint + project ID

7. 🔲 **Test Sync** - Upload/download data

8. 🔲 **Configure POS App** - Same settings as backend

---

## 🆘 Troubleshooting

### Can't access from Android device

```bash

# Make sure port 8080 is accessible

sudo ufw allow 8080/tcp  # If using UFW firewall



# Or with firewalld

sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

```

### Containers not running

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose -f appwrite-compose.yml up -d

```

### Reset everything

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose -f appwrite-compose.yml down -v  # WARNING: Deletes all data

docker-compose -f appwrite-compose.yml up -d

```

---

## 📚 Documentation

- **Quick Start**: `DOCKER_QUICK_START.md`

- **Appwrite Config**: `APPWRITE_CONFIG.md`

- **Full Setup Guide**: See docs in `/mnt/Storage/Projects/flutterpos/docs/`

---

**Configuration Complete!** 🎉

Your Appwrite instance is running and ready for FlutterPOS integration.
