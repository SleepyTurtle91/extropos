# Auto User Creation Feature - Quick Guide

**Feature**: One-Click Nextcloud User Account Creation  
**Location**: Backend/POS App → Nextcloud Settings → Quick Setup  
**Version**: 1.0.14+14

---

## 🎯 What It Does

Automatically creates a personalized Nextcloud user account for your business based on your Business Information (name, email, owner).

**Before** (Manual):

1. Open Nextcloud web
2. Login as admin
3. Create user manually
4. Set quota
5. Generate app password
6. Copy credentials to FlutterPOS

**After** (Automatic):

1. Click "Create My Account" button
2. Done! ✅

---

## 🚀 How To Use

### Step 1: Set Up Business Information (First Time Only)

1. **Open Backend App** → **Menu** → **Business Information**

2. Fill in required fields:

   - ✅ Business Name (e.g., "Restaurant ABC")

   - ✅ Owner Name

   - ✅ Email (e.g., "<owner@restaurant.com>")

3. Save

### Step 2: Configure Nextcloud Connection

1. **Open Backend App** → **Menu** → **Nextcloud Settings**

2. Enter **Server URL**: `https://extropos.duckdns.org` (external) or `http://192.168.1.234:8080` (LAN)
3. Click **"Show Admin Fields"** button

4. Enter **Admin Credentials**:

   - Admin Username: `admin`

   - Admin Password: `admin123` (or your Nextcloud admin password)

### Step 3: Create Your Account

1. Click **"Create My Account"** button (green button)

2. Wait for account creation (~5 seconds)
3. **Success Dialog** appears showing:

   - Your Username (auto-generated from business name)

   - Temporary Password

   - Email

4. **Save these credentials!** (write down or screenshot)

### Step 4: Configure FlutterPOS

The form is automatically filled with:

- ✅ Username (e.g., "restaurant-abc")

- ✅ Password (temporary)

- ✅ Backup Path ("/flutterpos_backups")

1. Click **"Save Settings"**
2. Enable **"Use Nextcloud for Backups"**
3. Click **"Upload Backup Now"** to test

---

## 🔐 Security Best Practice (Recommended)

### Generate App Password (After Account Creation)

1. **Login to Nextcloud Web**:

   - URL: <https://extropos.duckdns.org> (external) or <http://192.168.1.234:8080> (LAN)

   - Username: (from Step 3)

   - Password: (from Step 3)

2. **Go to Security Settings**:

   - Click Profile Icon (top right)

   - Settings → Security → Devices & sessions

3. **Create App Password**:

   - Under "App passwords"

   - Enter name: `FlutterPOS Backend`

   - Click **"Create new app password"**

   - **Copy the generated password** (5 groups of letters/numbers)

4. **Update FlutterPOS**:

   - Backend App → Nextcloud Settings

   - Replace password field with **App Password**

   - Click "Save Settings"

5. **Why?**:

   - ✅ More secure (can revoke without changing main password)

   - ✅ Can create separate passwords for each device/POS terminal

   - ✅ Limits access (app password can't change account settings)

---

## 📋 What Happens Behind the Scenes

### Auto-Generated Username

**From Business Name** → **Username**:

- "Restaurant ABC" → `restaurant-abc`

- "Cafe One Two Three" → `cafe-one-two-three`

- "Joe's Diner" → `joes-diner`

- "北京餐厅" → `(non-ASCII removed)`

**Rules**:

- Lowercase only

- Spaces → hyphens

- Special characters removed

- Max 30 characters

### User Account Details

**Created with**:

- Username: Auto-generated

- Password: Random 16-char secure password

- Email: From Business Information

- Display Name: Business Name + Owner Name

- Quota: 50GB (default)

- Group: "pos-users"

### Storage Structure

```text
/mnt/storage/nextcloud/data/
└── restaurant-abc/          # Your username

    └── files/
        └── flutterpos_backups/   # Your private backup folder

            ├── flutterpos_backup_20251128_100000.db
            ├── flutterpos_backup_20251128_110000.db
            └── flutterpos_backup_20251128_120000.db

```text

---


## 🎭 Multiple Restaurants/Businesses


Each business gets their own isolated account:

| Business Name | Auto Username | Email | Storage Quota |
|---------------|---------------|-------|---------------|
| Restaurant ABC | restaurant-abc | <owner@abc.com> | 50 GB |
| Cafe One | cafe-one | <cafe@one.com> | 50 GB |
| Joe's Diner | joes-diner | <joe@diner.com> | 50 GB |

**Benefits**:


- ✅ Each business has separate login

- ✅ Can't see other businesses' backups

- ✅ Individual quotas prevent storage abuse

- ✅ Professional multi-tenant setup

---


## ❓ FAQ



### Q: What if my user already exists?


**A**: The system detects existing users and shows:


```text
"Your user account already exists in Nextcloud"

```text

You'll need to enter your existing password manually.


### Q: Can I change my username?


**A**: No, username is auto-generated from business name. To change it:

1. Update Business Name in Business Information
2. Create a new account (old one will remain)
3. Or manually edit username in Nextcloud admin panel


### Q: What if I forget my password?


**A**: Two options:

1. **Self-service**: Login to Nextcloud web → Settings → Security → Change password
2. **Admin reset**: Admin can reset via Nextcloud web or command line


### Q: Can I use this for multiple POS terminals?


**A**: Yes!


- Create ONE user account per business

- Generate MULTIPLE app passwords (one per POS terminal)

- Each terminal uses same username, different app password


### Q: What if account creation fails?


**Common Issues**:

1. **Wrong admin password**: Double-check admin credentials
2. **Server unreachable**: Verify Server URL and Nextcloud is running
3. **Business info not set**: Fill Business Information first
4. **User already exists**: Username collision (change business name slightly)

---


## 🛠️ Troubleshooting



### Error: "Please set up your business information first"


**Solution**:

1. Menu → Business Information
2. Fill required fields (Business Name, Email)
3. Save
4. Return to Nextcloud Settings


### Error: "Please enter admin credentials"


**Solution**:

1. Click "Show Admin Fields"
2. Enter admin username (default: `admin`)
3. Enter admin password (default: `admin123`)


### Error: "Failed to create user account"


**Check**:


```bash

# Verify Nextcloud is running

docker ps | grep nextcloud


# Test admin credentials

curl -u admin:admin123 http://192.168.1.234:8080/ocs/v1.php/cloud/users


# Check Nextcloud logs

docker logs nextcloud | tail -50

```text

---


## 📊 Comparison: Manual vs Auto


| Task | Manual Method | Auto-Create |
|------|--------------|-------------|
| Create user | 2-3 min | 5 seconds |
| Set quota | Manual click | Automatic (50GB) |
| Generate password | Manual | Automatic (secure) |
| Enter credentials | Copy/paste | Auto-filled |
| Error-prone | High | Low |
| Business name mapping | Manual typing | Automatic |

**Time Saved**: ~2 minutes per restaurant  
**For 50 restaurants**: ~100 minutes saved! 🎉

---


## ✅ Summary


**One-Click User Creation**:

1. Set business info (once)
2. Click "Create My Account"
3. Save settings
4. Start backing up!

**Result**:


- ✅ Personalized Nextcloud account

- ✅ Isolated storage

- ✅ Secure auto-generated password

- ✅ Professional multi-tenant setup

- ✅ No manual Nextcloud admin panel needed

**Best Practice**:


- Always generate App Password after account creation

- Keep main password secure (for account recovery)

- Use different app passwords for each device

Ready to create your account! 🚀
