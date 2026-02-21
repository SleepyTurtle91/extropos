# Google Sign-In Setup Guide

## Problem

Google Sign-In is not working because the app is missing OAuth 2.0 credentials required by Google Cloud Platform.

## Root Causes

### 1. Missing Dependencies (FIXED ✅)

- **Linux**: Required `libsecret-1` for secure credential storage

- **Solution**: Installed via `sudo dnf install libsecret-devel -y`

### 2. Missing OAuth Configuration (NEEDS FIX ⚠️)

Google Sign-In requires OAuth 2.0 client IDs configured in Google Cloud Console.

---

## Quick Fix: Disable Google Sign-In Temporarily

If you don't need Google Drive sync immediately, you can disable the feature:

### Option 1: Skip Google Sign-In in Backend UI

The Backend app already handles the case when Google is not connected:

- "Connect Google Drive for Sync" button shows when not signed in

- All other features work without Google

### Option 2: Use Local Backup Only

The app has local SQLite database that works without Google:

- Data persists locally

- RabbitMQ sync works without Google

- No cloud backup, but everything else functions

---

## Complete Setup (For Production)

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project: **"FlutterPOS"**
3. Enable APIs:

   - **Gmail API** (for email receipts)

   - **Google Drive API** (for database backup)

### Step 2: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**

2. Choose **External** user type

3. Fill in app information:

   - App name: `FlutterPOS`

   - User support email: Your email

   - Developer contact: Your email

4. Add scopes:

   - `https://www.googleapis.com/auth/gmail.send`

   - `https://www.googleapis.com/auth/gmail.readonly`

   - `https://www.googleapis.com/auth/drive.file`

   - `https://www.googleapis.com/auth/drive.appdata`

5. Add test users (your Gmail account)

### Step 3: Create OAuth 2.0 Credentials

#### For Android (Backend/POS apps)

1. Go to **APIs & Services** → **Credentials**

2. Click **Create Credentials** → **OAuth 2.0 Client ID**

3. Choose **Android**
4. Get your SHA-1 fingerprint:

   ```bash
   # Debug keystore (for testing)

   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   
   # Copy the SHA-1 fingerprint

   ```

5. Fill in:

   - **Name**: FlutterPOS Android

   - **Package name**: `com.extrotarget.extropos.backend` (or `.pos`)

   - **SHA-1**: Paste fingerprint from above

6. Click **Create**
7. Download `google-services.json`

#### For Linux Desktop

1. Create Credentials → **OAuth 2.0 Client ID**
2. Choose **Desktop app**
3. Name: `FlutterPOS Linux`
4. Download JSON credentials

### Step 4: Add Credentials to Project

#### Android

```bash

# Place google-services.json in android/app/

cp ~/Downloads/google-services.json /home/abber/Documents/flutterpos/android/app/

```text


#### Update android/build.gradle.kts



```kotlin
plugins {
    // Add Google Services plugin
    id("com.google.gms.google-services") version "4.4.0" apply false
}

```text


#### Update android/app/build.gradle.kts



```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Add this
}

```text


#### Linux


Create `lib/config/google_oauth_credentials.dart`:


```dart
const String googleClientId = 'YOUR_CLIENT_ID_HERE.apps.googleusercontent.com';
const String googleClientSecret = 'YOUR_CLIENT_SECRET_HERE';

```text


### Step 5: Update GoogleServices


Modify `lib/services/google_services.dart` to use credentials:


```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: Platform.isLinux ? googleClientId : null,
  scopes: [...],
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // For Android
);

```text


### Step 6: Rebuild APKs



```bash
cd /home/abber/Documents/flutterpos


# Clean build

flutter clean
flutter pub get


# Build Backend APK

./build_flavors.sh backend release


# Install

adb -s 192.168.1.80:42279 install -r build/app/outputs/flutter-apk/app-backendapp-release.apk

```text

---


## Testing Google Sign-In



### On Android (Backend App)


1. Open Backend app
2. Click Settings (gear icon)
3. You should see "Connect Google Drive for Sync" button
4. Tap the button
5. Google OAuth screen should appear
6. Select your Google account
7. Grant permissions (Gmail, Drive)
8. Success: Shows "✅ Successfully connected to Google"


### On Linux


1. Run: `flutter run -d linux lib/main_backend.dart`
2. OAuth browser window opens automatically
3. Sign in with Google
4. Grant permissions
5. Browser closes, app shows connected status

---


## Troubleshooting



### Error: "Sign-in failed" or "User cancelled"


**Cause**: OAuth credentials not configured

**Solution**:

1. Complete Steps 1-5 above
2. Ensure SHA-1 fingerprint matches
3. Check package name matches exactly


### Error: "API not enabled"


**Cause**: Gmail/Drive APIs not enabled in Google Cloud

**Solution**:

1. Go to Google Cloud Console
2. APIs & Services → Library
3. Search "Gmail API" → Enable
4. Search "Google Drive API" → Enable


### Error: "403 Forbidden" or "Access blocked"


**Cause**: OAuth consent screen not configured

**Solution**:

1. Configure OAuth consent screen (Step 2)
2. Add yourself as test user
3. Publish app (or keep in testing mode with test users)


### Error: "Invalid client"


**Cause**: Wrong OAuth client ID for platform

**Solution**:


- Android: Use Android OAuth client (with SHA-1)

- Linux: Use Desktop app OAuth client

- Don't mix credentials between platforms

---


## Current Status


- ✅ Linux dependency installed (`libsecret-devel`)

- ⚠️ OAuth credentials needed (not configured yet)

- ⚠️ `google-services.json` missing (Android)

- ⚠️ Desktop OAuth client missing (Linux)


## Recommended Approach for Now


**Use the app WITHOUT Google Sign-In:**


- All core POS features work (orders, payments, reports)

- RabbitMQ sync works for real-time updates between devices

- Local SQLite database persists data

- No cloud backup, but data is safe locally

**Add Google later when needed:**


- Set up OAuth when you need email receipts

- Configure Drive when you need cloud backup

- Takes ~30 minutes to complete full setup

---


## Alternative: Mock Implementation (Testing Only)


For development/testing, create a mock Google service:


```dart
// lib/services/google_services_mock.dart
class GoogleServicesMock {
  bool _isSignedIn = false;
  
  Future<bool> signIn() async {
    _isSignedIn = true;
    return true;
  }
  
  bool get isSignedIn => _isSignedIn;
  String? get userEmail => _isSignedIn ? 'test@example.com' : null;
}

```text

Replace in code:


```dart
// final _googleServices = GoogleServices.instance;
final _googleServices = GoogleServicesMock();

```text

**WARNING**: This is for testing UI only. Real Gmail/Drive features won't work.

---


## Summary


**Current Issue**: Google Sign-In button shows but doesn't work because OAuth not configured.

**Immediate Fix**: Use app without Google (all main features work).

**Permanent Fix**: Follow Steps 1-6 to configure OAuth credentials (30 min setup).

**Impact**:


- ❌ Cannot send email receipts

- ❌ Cannot backup to Google Drive

- ✅ All POS features work

- ✅ RabbitMQ sync works

- ✅ Local database works

- ✅ Reports work
