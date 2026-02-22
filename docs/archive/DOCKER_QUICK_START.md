# FlutterPOS Docker Appwrite - Quick Start

## 🚀 QUICK SETUP (5 Minutes)

### Step 1: Get Your Docker Appwrite Info

```bash

# Find your server IP (Linux/Mac)

ip addr show | grep "inet " | grep -v 127.0.0.1


# OR

hostname -I

```

**You need:**

- ✅ Server IP: `192.168.X.X` (or `localhost` if on same machine)

- ✅ Appwrite Endpoint: `http://YOUR_IP/v1`

### Step 2: Open Appwrite Console

```
Browser: http://YOUR_IP
Login with your Appwrite admin credentials

```

### Step 3: Get/Create Project

**Option A: Use Existing Project**

1. Select your project
2. Click Settings (⚙️)
3. Copy **Project ID** (e.g., `507f1f77bcf86cd799439011`)

**Option B: Create New Project**

1. Click "Create Project"
2. Name: `FlutterPOS`
3. Copy the generated **Project ID**

### Step 4: Create Database

1. In Appwrite Console → **Databases**
2. Click **"Create Database"**
3. Name: `extropos_db`
4. Copy the **Database ID** (usually same as name)

### Step 5: Configure FlutterPOS Backend App

1. Open **FlutterPOS Backend** app on your device

2. Navigate: **Appwrite Config** (in menu)

3. Fill in:

   ```
   Endpoint: http://YOUR_IP/v1
   Project ID: [paste from step 3]
   Database ID: extropos_db
   ```

4. Tap **"Test Connection"**

   - ✅ Should show "Connection successful!"

5. Tap **"Save Config"**

### Step 6: Create Collections (One-Time Setup)

Run this script on your Appwrite server or use the Console:

```bash

# Option A: Auto-create via script (coming soon)

# Option B: Manual creation in Console (5 minutes)

```

**Manual Steps:**

1. Databases → `extropos_db` → Collections
2. Create 6 collections with these exact names:

   - `business_info`

   - `categories`

   - `products`

   - `modifiers`

   - `tables`

   - `users`

**For each collection, set permissions:**

- Read: `Any`

- Create: `Users`

- Update: `Users`

- Delete: `Users`

**Attributes (add as needed later, or see full guide)**

### Step 7: Test Sync

1. Backend App → **Appwrite Sync**
2. Register new account:

   ```
   Email: admin@yourstore.com
   Password: [secure password]
   ```

3. Tap **"Upload to Cloud"**
4. Check Appwrite Console → Database → business_info

   - Should see your data!

---

## 📱 Network Access (Choose One)

### Same Machine (Desktop/Laptop)

```
Endpoint: http://localhost/v1

```

### Same WiFi Network (Android Device)

```
1. Find computer IP: hostname -I
2. Use: http://192.168.X.X/v1
3. Make sure Docker is bound to 0.0.0.0, not 127.0.0.1

```

### Different Network (Production)

```
1. Set up domain with SSL
2. Use: https://appwrite.yourdomain.com/v1

```

---

## 🔥 Quick Troubleshooting

**"Connection failed"**

- [ ] Is Docker Appwrite running? `docker ps | grep appwrite`

- [ ] Can you ping the IP? `ping YOUR_IP`

- [ ] Is endpoint correct? Must end with `/v1`

**"Invalid Project ID"**

- [ ] Copy/paste from Appwrite Console (no typos)

- [ ] Check capitalization

**"Database not found"**

- [ ] Create `extropos_db` in Appwrite Console

- [ ] Verify name matches exactly

**Android can't connect to laptop's Docker**

```bash

# Check Docker is listening on all interfaces:

docker-compose.yml should have:
ports:

  - "0.0.0.0:80:80"  # NOT 127.0.0.1:80:80



# Restart Docker after change:

docker-compose down && docker-compose up -d

```

**Firewall blocking (Linux)**

```bash
sudo ufw allow 80/tcp      # Debian/Ubuntu

sudo ufw allow 443/tcp     # Debian/Ubuntu

# Fedora (firewalld):

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

```

---

## 📋 Checklist

Before using sync:

- [ ] Docker Appwrite running

- [ ] Endpoint configured in app

- [ ] Project ID configured

- [ ] Database `extropos_db` created

- [ ] Collections created (6 total)

- [ ] Test connection ✅

- [ ] User registered

- [ ] First sync tested

---

## 🎯 Common Configurations

### Local Development (Same Machine)

```
Endpoint: http://localhost/v1
Project ID: [your_project_id]
Database: extropos_db

```

### Local Network (WiFi Testing)

```
Endpoint: http://192.168.1.100/v1  # Your computer's IP

Project ID: [your_project_id]
Database: extropos_db

```

### Production (With Domain)

```
Endpoint: https://appwrite.yourdomain.com/v1
Project ID: [your_project_id]
Database: extropos_db

```

---

## 📖 Full Documentation

See: `docs/DOCKER_APPWRITE_SETUP.md` for complete guide

---

## ⚡ Next Steps After Setup

1. ✅ **Create some data** in Backend app (categories, products)

2. ✅ **Upload to Cloud** via Appwrite Sync

3. ✅ **Login on another device** (POS app)

4. ✅ **Download from Cloud** to sync data

5. 🎉 **Multi-device sync working!**

---

## 🆘 Need Help?

1. Check logs: Backend App → (debug mode shows errors)
2. Check Appwrite logs: `docker logs appwrite -f`
3. Test API: `curl http://YOUR_IP/v1/health/version`
4. See full guide: `docs/DOCKER_APPWRITE_SETUP.md`
