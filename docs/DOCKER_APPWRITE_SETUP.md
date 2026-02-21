# Connecting FlutterPOS to Self-Hosted Appwrite (Docker)

## Quick Setup Guide

### 1. Get Your Appwrite Docker Information

Run these commands on your Docker host to get the required information:

```bash

# Get your Appwrite container info

docker ps | grep appwrite


# Check Appwrite endpoint (usually http://localhost or your server IP)

docker logs appwrite | grep "Appwrite is ready"


# Get your project ID from Appwrite Console

# Open browser: http://YOUR_SERVER_IP (or http://localhost if local)

# Login → Select/Create Project → Copy Project ID from URL or Settings

```text


### 2. Required Information


You'll need:


- **Endpoint URL**: `http://YOUR_SERVER_IP/v1` or `http://localhost/v1`

  - If accessing from Android device on same network: `http://192.168.X.X/v1`

  - If using domain: `https://appwrite.yourdomain.com/v1`

- **Project ID**: Found in Appwrite Console (e.g., `507f1f77bcf86cd799439011`)

- **Database ID**: You'll create this in step 3


### 3. Create Database in Appwrite Console


1. Open Appwrite Console: `http://YOUR_SERVER_IP`
2. Navigate to **Databases** → **Create Database**

3. Name: `extropos_db`
4. Copy the Database ID (auto-generated)


### 4. Create Collections


Create these 6 collections in your `extropos_db` database:


#### Collection 1: `business_info`



```javascript
Attributes:

- business_id (string, 255, required)

- user_id (string, 255, required)

- name (string, 255, required)

- address (string, 500)

- phone (string, 50)

- email (string, 255)

- tax_number (string, 100)

- currency_symbol (string, 10)

- is_tax_enabled (boolean, required)

- tax_rate (double, required)

- is_service_charge_enabled (boolean, required)

- service_charge_rate (double, required)

- receipt_header (string, 1000)

- receipt_footer (string, 1000)

- logo_path (string, 500)

- updated_at (datetime, required)

Indexes:

- business_id_idx (key, business_id)

Permissions:

- Read: Any

- Create: Users

- Update: Users

- Delete: Users

```text


#### Collection 2: `categories`



```javascript
Attributes:

- business_id (string, 255, required)

- category_id (string, 255, required)

- name (string, 255, required)

- icon (string, 100)

- color (string, 50)

- updated_at (datetime, required)

Indexes:

- business_id_idx (key, business_id)

- category_id_idx (key, category_id)

Permissions:

- Read: Any

- Create: Users

- Update: Users

- Delete: Users

```text


#### Collection 3: `products`



```javascript
Attributes:

- business_id (string, 255, required)

- product_id (string, 255, required)

- store_id (string, 255)  # For multi-tenant

- name (string, 255, required)

- price (double, required)

- category (string, 255)

- icon (string, 100)

- updated_at (datetime, required)

Indexes:

- business_id_idx (key, business_id)

- product_id_idx (key, product_id)

- store_id_idx (key, store_id)

Permissions:

- Read: Any

- Create: Users

- Update: Users

- Delete: Users

```text


#### Collection 4: `modifiers`



```javascript
Attributes:

- business_id (string, 255, required)

- modifier_id (string, 255, required)

- name (string, 255, required)

- updated_at (datetime, required)

Indexes:

- business_id_idx (key, business_id)

- modifier_id_idx (key, modifier_id)

Permissions:

- Read: Any

- Create: Users

- Update: Users

- Delete: Users

```text


#### Collection 5: `tables`



```javascript
Attributes:

- business_id (string, 255, required)

- table_id (string, 255, required)

- name (string, 255, required)

- capacity (integer, required)

- updated_at (datetime, required)

Indexes:

- business_id_idx (key, business_id)

- table_id_idx (key, table_id)

Permissions:

- Read: Any

- Create: Users

- Update: Users

- Delete: Users

```text


#### Collection 6: `users`



```javascript
Attributes:

- business_id (string, 255, required)

- user_id (string, 255, required)

- username (string, 255, required)

- full_name (string, 255, required)

- role (string, 50, required)

- updated_at (datetime, required)

Indexes:

- business_id_idx (key, business_id)

- user_id_idx (key, user_id)

Permissions:

- Read: Any

- Create: Users

- Update: Users

- Delete: Users

```text


#### Collection 7 (Optional): `stores` - For Multi-Tenant



```javascript
Attributes:

- tenant_id (string, 255, required)

- team_id (string, 255, required)

- store_name (string, 255, required)

- admin_user_id (string, 255, required)

- created_at (datetime, required)

Indexes:

- team_id_idx (key, team_id)

- tenant_id_idx (key, tenant_id, unique)

Permissions:

- Read: Any

- Create: Users

- Update: Team (team_id)

- Delete: Team (team_id)

```text


### 5. Configure FlutterPOS Backend App


**Option A: Using the UI (Recommended)**

1. Open **FlutterPOS Backend** app

2. Navigate to **Settings** → **Appwrite Configuration**

3. Enter:

   - Endpoint: `http://YOUR_SERVER_IP/v1`

   - Project ID: `YOUR_PROJECT_ID`

   - Database ID: `extropos_db`

4. Tap **Save Configuration**
5. Tap **Test Connection**

**Option B: Manual Configuration**

Edit the file: `lib/services/appwrite_sync_service.dart`

Change lines 17-19:


```dart
// OLD (Cloud Appwrite)
static const String _endpoint = 'https://syd.cloud.appwrite.io/v1';
static const String _projectId = '689965770017299bd5a5';

// NEW (Your Docker Appwrite)
static const String _endpoint = 'http://YOUR_SERVER_IP/v1';
static const String _projectId = 'YOUR_PROJECT_ID';

```text


### 6. Network Configuration



#### If accessing from Android device


**On same WiFi network:**


- Use your computer's local IP: `http://192.168.1.100/v1`

- Find IP on Linux: `ip addr show` or `hostname -I`

- Find IP on Windows: `ipconfig`

**Firewall rules (Linux):**


```bash

# Allow Appwrite port (usually 80/443)

sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

```text

**Docker port mapping check:**


```bash
docker ps | grep appwrite

# Should show: 0.0.0.0:80->80/tcp

```text


#### If accessing from desktop (same machine)


- Use: `http://localhost/v1`


### 7. Testing the Connection


**From Backend App:**

1. Go to **Appwrite Sync** screen

2. Tap **Upload to Cloud** or **Download from Cloud**

3. Check for errors in logs

**From Terminal:**


```bash

# Test Appwrite health

curl http://YOUR_SERVER_IP/v1/health/version


# Should return:

# {"version":"1.x.x"}

```text


### 8. Troubleshooting



#### Error: "Network unreachable"


- Check if Appwrite Docker container is running: `docker ps`

- Check firewall allows connections

- Verify IP address is correct


#### Error: "Invalid project ID"


- Verify Project ID in Appwrite Console

- Check spelling/capitalization


#### Error: "Database not found"


- Create database `extropos_db` in Appwrite Console

- Verify database ID matches


#### Error: "Collection not found"


- Create all 6 collections as specified above

- Verify collection IDs match (business_info, categories, products, etc.)


#### Error: "Self-signed certificate"


If using HTTPS with self-signed certificate:


```dart
// Already enabled in initialize():
.setSelfSigned(status: true)

```text


#### Can't access from Android device



```bash

# On your server, check Docker network:

docker network inspect appwrite_network


# Make sure Appwrite is bound to 0.0.0.0, not 127.0.0.1

docker-compose.yml should have:
ports:

  - "0.0.0.0:80:80"

  - "0.0.0.0:443:443"

```text


### 9. Environment-Specific Configurations



#### Development (Local Docker)



```dart
Endpoint: http://localhost/v1
Project ID: YOUR_PROJECT_ID

```text


#### Production (Server Docker)



```dart
Endpoint: https://appwrite.yourdomain.com/v1
Project ID: YOUR_PROJECT_ID

```text


#### Testing (WiFi Network)



```dart
Endpoint: http://192.168.1.100/v1  // Your server's local IP
Project ID: YOUR_PROJECT_ID

```text


### 10. Next Steps After Connection


1. **Register User:**

   - Backend App → Appwrite Sync → Register

   - Email: `admin@yourrestaurant.com`

   - Password: (secure password)

2. **Create Team (Optional for multi-tenant):**

   ```dart
   await AppwriteSyncService.instance.onboardNewTenant(
     storeName: 'My Restaurant'
   );
   ```

1. **Test Sync:**

   - Make changes in Backend app

   - Tap "Upload to Cloud"

   - Open POS app and "Download from Cloud"

   - Verify data appears

### Quick Command Reference

```bash

# Start Appwrite Docker

docker-compose up -d


# Stop Appwrite Docker

docker-compose down


# View Appwrite logs

docker logs appwrite -f


# Check Appwrite status

docker ps | grep appwrite


# Restart Appwrite

docker-compose restart


# Your Appwrite Console

http://YOUR_SERVER_IP

```text


### Support


If you encounter issues:

1. Check Docker logs: `docker logs appwrite`
2. Verify network connectivity: `ping YOUR_SERVER_IP`
3. Test API endpoint: `curl http://YOUR_SERVER_IP/v1/health/version`
4. Check FlutterPOS logs in Backend app

---


## Configuration Summary


Fill in your details:


```text
Appwrite Endpoint: http://________________/v1
Project ID: ________________________________
Database ID: extropos_db
Collections: ✓ business_info ✓ categories ✓ products 
             ✓ modifiers ✓ tables ✓ users
Network Access: ✓ Firewall configured ✓ Docker ports exposed

```text

Ready to sync! 🚀
