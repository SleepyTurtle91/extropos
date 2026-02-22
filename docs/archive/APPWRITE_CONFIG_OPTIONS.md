# Appwrite Configuration Options for FlutterPOS

## 🎯 Current Status

✅ **Appwrite is running locally!**

- Console: <http://localhost:3000>

- API: <http://localhost:8080/v1>

- Containers: Running and healthy

## 📋 Configuration Options

You have **two options** for configuring your FlutterPOS app:

### Option 1: Use Local Appwrite (Recommended for Development)

**Pros:**

- ✅ Full control over data

- ✅ Works offline

- ✅ Faster development

- ✅ No internet required

**Setup Steps:**

1. **Get Your Local IP Address** (for Android device testing):

```powershell
ipconfig

# Look for "IPv4 Address" under your active network adapter

# Example: 192.168.1.100

```

1. **Update FlutterPOS Configuration**:

Edit `lib/config/environment.dart`:

```dart
class Environment {
  // Local Appwrite Docker instance
  static const String appwriteProjectId =
      'YOUR_NEW_PROJECT_ID'; // Create new project at http://localhost:8080
  static const String appwriteProjectName = 'ExtroPOS';

  // API Key for server-side operations
  static const String appwriteApiKey =
      'YOUR_NEW_API_KEY'; // Create in project settings

  // Use localhost for desktop, local IP for Android
  static const String appwritePublicEndpoint =
      'http://localhost:8080/v1'; // For Windows/Desktop
      // 'http://192.168.1.100:8080/v1'; // For Android device (use your IP)

  // Database and collection names remain the same
  static const String posDatabase = 'pos_db';
  // ... rest of the configuration stays the same

```

1. **Create Project in Appwrite Console**:

   - Open <http://localhost:8080>

   - Sign up (if first time)

   - Create project named "ExtroPOS"

   - Copy the Project ID

   - Create database named "pos_db"

   - Create all 14 collections (see detailed list in APPWRITE_WINDOWS_SETUP_COMPLETE.md)

   - Create API key with all scopes

   - Update the config file above with your IDs

### Option 2: Keep Using Remote Appwrite

**Pros:**

- ✅ Already configured

- ✅ Data accessible from anywhere

- ✅ Multi-device sync

**Current Configuration:**

```dart
static const String appwriteProjectId = '6940a64500383754a37f';
static const String appwritePublicEndpoint = 'https://appwrite.extropos.org/v1';

```

**No changes needed!** Your app is already set up to use the remote instance.

## 🔄 Switching Between Local and Remote

### To use Local Appwrite

```dart
static const String appwritePublicEndpoint = 'http://localhost:8080/v1';

```

### To use Remote Appwrite

```dart
static const String appwritePublicEndpoint = 'https://appwrite.extropos.org/v1';

```

## 📱 For Android Device Testing

When testing on an Android device, you **cannot use localhost**. You must use your PC's local IP:

1. **Find your PC's IP**:

```powershell
ipconfig

# Example output: IPv4 Address. . . . . . . . . . : 192.168.1.100

```

1. **Update endpoint with your IP**:

```dart
static const String appwritePublicEndpoint = 'http://192.168.1.100:8080/v1';

```

1. **Ensure Windows Firewall allows port 8080**:

```powershell
New-NetFirewallRule -DisplayName "Appwrite HTTP" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow

```

## 🏗️ Collections Required (For Option 1)

If you choose **Option 1 (Local Appwrite)**, you need to create these 14 collections in `pos_db`:

1. **categories** - Product categories

2. **items** - Products/menu items

3. **orders** - Order records

4. **order_items** - Order line items

5. **users** - Staff user accounts

6. **tables** - Restaurant tables

7. **payment_methods** - Payment types

8. **customers** - Customer database

9. **transactions** - Payment history

10. **printers** - Printer configurations

11. **customer_displays** - Customer-facing displays

12. **receipt_settings** - Receipt configuration

13. **modifier_groups** - Modifier groups

14. **modifier_items** - Individual modifiers

**Permissions for each collection:**

- Read: `["any"]` (allow all to read)

- Write: `["role:all"]` (allow authenticated users to write)

## 🎬 Quick Start Commands

### Start Local Appwrite

```powershell
cd C:\Users\USER\Documents\flutterpos\docker
docker-compose -f appwrite-compose-windows.yml up -d

```

### Open Appwrite Console

```powershell
Start-Process "http://localhost:3000"

```

### Check Status

```powershell
docker ps | Select-String "appwrite"

```

### Stop Appwrite

```powershell
docker-compose -f appwrite-compose-windows.yml down

```

## 💡 Recommendation

**For Development**: Use **Option 1 (Local Appwrite)**

- Faster iteration

- Full control

- No internet dependency

**For Production**: Use **Option 2 (Remote Appwrite)**

- Multi-device access

- Cloud backup

- Always available

You can easily switch between them by just changing the `appwritePublicEndpoint` value!

## 📚 Reference Files

- **Setup Guide**: [APPWRITE_WINDOWS_SETUP_COMPLETE.md](APPWRITE_WINDOWS_SETUP_COMPLETE.md)

- **Configuration File**: `lib/config/environment.dart`

- **Docker Compose**: `docker/appwrite-compose-windows.yml`

## ✅ Next Steps

1. Choose Option 1 or Option 2 above
2. If Option 1: Follow setup in APPWRITE_WINDOWS_SETUP_COMPLETE.md
3. If Option 2: No changes needed, continue development
4. Test connection from FlutterPOS Backend app
5. Start syncing data!

**Your Appwrite is ready to use! 🚀**
