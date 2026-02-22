# Local Appwrite Setup for FlutterPOS

**Your Appwrite Configuration:**

- **Endpoint**: `http://localhost:8080/v1`

- **Project ID**: `69392e4c0017357bd3d5`

- **Email**: `abber8@gmail.com`

- **Password**: `Berneydaniel123`

---

## Quick Setup Steps

### 1. Find Your Local IP Address

The app is now configured to use `localhost:8080`, which works for:

- ✅ Desktop apps (Windows/Linux/macOS)

- ✅ Web development

For **Android/iOS testing**, you MUST replace `localhost` with your machine's IP:

```bash

# Linux/macOS - Find your IP

ip addr show | grep "inet " | grep -v 127.0.0.1


# OR use this shortcut

hostname -I | awk '{print $1}'


# Windows

ipconfig | findstr IPv4

```

**Example result**: `192.168.1.100`

---

### 2. Update Environment Configuration

**File**: `lib/config/environment.dart`

**For Desktop/Web Development** (current setup):

```dart
static const String appwritePublicEndpoint =
    'http://localhost:8080/v1';

```

**For Android/iOS Testing** (change localhost to your IP):

```dart
static const String appwritePublicEndpoint =
    'http://192.168.1.100:8080/v1'; // Replace with YOUR IP

```

---

### 3. Verify Appwrite is Running

```bash

# Check if Appwrite Docker containers are running

docker ps | grep appwrite


# Expected output: Multiple containers (appwrite, appwrite-worker-*, etc.)



# Test connection from terminal

curl http://localhost:8080/v1/health/version


# Expected output: {"version":"1.x.x"}

```

---

### 4. Configure FlutterPOS Appwrite Settings

#### Option A: Use AppwriteSettingsScreen (Recommended)

1. Run FlutterPOS
2. Go to **Settings** → **Appwrite Integration**

3. Enter:

   - **Endpoint**: `http://localhost:8080/v1` (or your IP for mobile)

   - **Project ID**: `69392e4c0017357bd3d5`

   - **API Key**: *(optional - leave empty for now)*

4. Tap **Test Connection**
5. Tap **Save**

**Option B: Hardcoded in Environment.dart** (Already Done)

The configuration is already updated in `lib/config/environment.dart` with your credentials.

---

## Testing the Connection

### From Flutter Desktop App

```bash

# Run POS flavor

flutter run -d windows


# Run Backend flavor (for management)

flutter run -d windows lib/main_backend.dart

```

Once app loads, check the Appwrite connection status in Settings.

### From Android Device/Emulator

**CRITICAL**: Android cannot connect to `localhost:8080` - it sees its own localhost!

1. **Update environment.dart**:

   ```dart
   static const String appwritePublicEndpoint =
       'http://YOUR_MACHINE_IP:8080/v1'; // e.g., http://192.168.1.100:8080/v1
   ```

2. **Ensure Appwrite allows your IP**:

   ```bash
   # Check docker/appwrite-compose.yml

   # Ensure _APP_CONSOLE_WHITELIST_ORIGINS includes "*" or your IP

   ```

3. **Build and deploy**:

   ```bash
   ./build_flavors.sh pos debug
   adb install build/app/outputs/flutter-apk/app-posapp-debug.apk
   ```

---

## JavaScript Example (Web Frontend)

```javascript
import { Client, Account } from 'appwrite';

const client = new Client()
    .setEndpoint('http://localhost:8080/v1')
    .setProject('69392e4c0017357bd3d5');

const account = new Account(client);

// Login
await account.createEmailPasswordSession(
    'abber8@gmail.com',
    'Berneydaniel123'
);

// Get user
const user = await account.get();
console.log(user);

```

---

## Flutter Example (FlutterPOS)

```dart
import 'package:appwrite/appwrite.dart';

final client = Client()
    .setEndpoint('http://YOUR_IP:8080/v1') // Replace YOUR_IP
    .setProject('69392e4c0017357bd3d5');

final account = Account(client);
final databases = Databases(client);

// Example: Login
try {
  await account.createEmailPasswordSession(
    'abber8@gmail.com',
    'Berneydaniel123',
  );
  print('Logged in successfully');
} catch (e) {
  print('Login failed: $e');
}

// Example: Fetch data
try {
  final result = await databases.listDocuments(
    databaseId: 'your_database_id',
    collectionId: 'your_collection_id',
  );
  print('Documents: ${result.documents}');
} catch (e) {
  print('Fetch failed: $e');
}

```

---

## Common Issues & Fixes

### Issue 1: "Connection refused" or "Timeout"

**Cause**: Appwrite not running or wrong endpoint

**Fix**:

```bash

# Start Appwrite

cd docker
docker-compose -f appwrite-compose.yml up -d


# Verify it's running

curl http://localhost:8080/v1/health/version

```

---

### Issue 2: Android app can't connect

**Cause**: Using `localhost` in environment.dart

**Fix**: Replace `localhost` with your machine's IP address (e.g., `192.168.1.100`)

---

### Issue 3: CORS errors in web

**Cause**: Appwrite CORS not configured

**Fix** (in `docker/appwrite-compose.yml`):

```yaml
environment:
  _APP_CONSOLE_WHITELIST_ORIGINS: "*"
  # OR specific origins:

  # _APP_CONSOLE_WHITELIST_ORIGINS: "http://localhost:8000,http://192.168.1.100:8000"

```

Then restart Appwrite:

```bash
cd docker
docker-compose -f appwrite-compose.yml restart

```

---

### Issue 4: "Project not found"

**Cause**: Wrong project ID

**Fix**: Get correct project ID from Appwrite Console

1. Open <http://localhost:8080> in browser
2. Login with `abber8@gmail.com` / `Berneydaniel123`
3. Click on your project
4. Copy Project ID from Settings
5. Update `lib/config/environment.dart`

---

## Project Structure

```text
FlutterPOS/
├── lib/
│   ├── config/
│   │   └── environment.dart         # ← Appwrite config (UPDATED)

│   ├── services/
│   │   ├── appwrite_client.dart     # Global client

│   │   └── appwrite_service.dart    # Connection service

│   └── screens/
│       └── appwrite_settings_screen.dart  # UI for configuration

└── docker/
    └── appwrite-compose.yml         # Your Appwrite Docker setup

```

---

## Next Steps

1. ✅ **Configuration Updated** - Your project ID and endpoint are set

2. ⏳ **Test Connection** - Run the app and verify Appwrite connection

3. ⏳ **Setup Collections** - Create databases/collections in Appwrite Console

4. ⏳ **Integrate Data Sync** - Use AppwriteService in your screens

---

## Useful Commands

```bash

# Check Appwrite logs

docker logs appwrite


# Restart Appwrite

cd docker
docker-compose -f appwrite-compose.yml restart


# Stop Appwrite

docker-compose -f appwrite-compose.yml down


# Start Appwrite

docker-compose -f appwrite-compose.yml up -d


# Get your IP (Linux)

hostname -I | awk '{print $1}'


# Test Appwrite from terminal

curl http://localhost:8080/v1/health/version

```

---

## Security Notes

⚠️ **IMPORTANT**: Your credentials are visible in this config!

**For Production**:

1. Move credentials to environment variables or secure storage
2. Use API keys instead of email/password
3. Enable HTTPS (not HTTP)
4. Restrict CORS origins
5. Use proper authentication flow (OAuth, JWT)

**Current Setup**: Development only - OK for local testing

---

**Last Updated**: 2025-12-10  
**Appwrite Version**: Check with `curl http://localhost:8080/v1/health/version`
