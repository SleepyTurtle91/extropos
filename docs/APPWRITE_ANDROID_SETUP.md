# Appwrite Android Device Setup Guide

## Problem: Android Device Cannot Access Localhost

When running Appwrite on your development machine and trying to connect from an Android device, the device **cannot access `localhost`** because localhost on Android refers to the device itself, not your PC.

## Solution Options

### Option 1: ADB Reverse Port Forwarding (Recommended for Testing)

Use ADB to forward ports from Android device to your PC:

```bash

# Forward Appwrite port (requires device connected via USB)

adb reverse tcp:8080 tcp:80


# Verify forwarding

adb reverse --list


# Now use http://localhost:8080/v1 in the app

```text

**Limitations:**


- Only works while USB connected

- Need to set up each time device reconnects

- Port 80 requires root, so we use 8080


### Option 2: Network IP Access (Requires Appwrite Reconfiguration)


**Current Status**: ❌ Not working due to Traefik routing

Appwrite uses Traefik reverse proxy which routes based on the `Host` header. When you access via IP (e.g., `192.168.1.234`), Traefik returns 404.

**To fix this, you would need to:**

1. Configure Traefik to accept IP-based requests
2. Or bypass Traefik entirely by exposing Appwrite container directly
3. Or set up a proper domain with SSL

This is complex and not recommended for development.


### Option 3: Cloud Appwrite (Production Recommended)


Use Appwrite Cloud for production:

1. Sign up at <https://cloud.appwrite.io>
2. Create a project
3. Get your Project ID
4. Use endpoint: `https://cloud.appwrite.io/v1`

**In Backend App:**


- Go to Menu → Appwrite Config

- Select "Cloud (Appwrite.io)"

- Enter your Project ID

- Test connection


### Option 4: Ngrok Tunnel (Development Alternative)


Expose your local Appwrite via ngrok:


```bash

# Install ngrok

# Then run:

ngrok http 80


# Use the ngrok URL in your app

# Example: https://abc123.ngrok.io/v1

```text


## Current Recommended Setup


**For Development on Same Machine (Desktop):**


- Use `http://localhost/v1`

- Works perfectly on Windows/Linux/macOS

**For Testing on Android Device:**


- **Option A**: Use ADB reverse port forwarding (see Option 1)

- **Option B**: Use Appwrite Cloud (see Option 3)

- **Option C**: Use ngrok (see Option 4)


## Quick Test



### Test from PC (should work)



```bash
curl http://localhost/v1/health/version

# Expected: {"version":"1.8.0"}

```text


### Test from Android (will fail)



```bash
adb shell curl http://localhost/v1/health/version

# Expected: Connection refused (localhost = Android device itself)

```text


### Test with port forwarding



```bash

# Set up forwarding

adb reverse tcp:8080 tcp:80


# Test from Android

adb shell curl http://localhost:8080/v1/health/version

# Expected: {"version":"1.8.0"}

```text


## Configuration in Backend App



### Using Appwrite Config Screen


1. Open Backend app
2. Menu → **Appwrite Config**
3. Try presets:

   - **Local Docker**: `http://localhost/v1` (only works on PC)

   - **Network**: `http://192.168.1.234/v1` (won't work due to Traefik)

   - **Cloud**: `https://cloud.appwrite.io/v1` (requires account)

4. For Android with ADB reverse:

   - Use Custom

   - Endpoint: `http://localhost:8080/v1`

   - Before opening app, run: `adb reverse tcp:8080 tcp:80`


## Troubleshooting



### Ping fails with "Connection refused"


- Android device trying to access localhost → Use ADB reverse

- Or switch to Cloud Appwrite


### Ping fails with "404 Not Found"


- Trying to access via IP (192.168.1.234) → Traefik routing issue

- Use localhost with ADB reverse instead


### Ping succeeds but can't create database


- Authentication required

- Access Appwrite Console: <http://localhost> (on PC)

- Create account, create database manually


## Next Steps After Connection Works


1. **Access Appwrite Console**: <http://localhost> (on your PC browser)
2. **Create Database**: Name = `extropos_db`
3. **Create Collections**:

   - `business_info`

   - `categories`

   - `products`

   - `modifiers`

   - `tables`

   - `users`

4. **Set Permissions**: Read: Any, Write: Users
5. **Test Sync**: Backend App → Sync menu → Upload data


## Summary


| Scenario | Endpoint | Setup Required |
|----------|----------|----------------|
| Desktop PC (Windows/Linux/Mac) | `http://localhost/v1` | ✅ None |
| Android Device (USB debugging) | `http://localhost:8080/v1` | ⚙️ `adb reverse tcp:8080 tcp:80` |
| Android Device (Wi-Fi only) | `https://cloud.appwrite.io/v1` | ☁️ Cloud account |
| Production | `https://cloud.appwrite.io/v1` | ☁️ Cloud account |
