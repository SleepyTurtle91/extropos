# Appwrite Docker Deployment Guide

## Phase 1 Backend Sync Infrastructure - Deployment Instructions

### Prerequisites

- Docker and Docker Compose installed

- At least 10GB free disk space at `/mnt/storage/appwrite/`

- Port 8080 available (or change `APPWRITE_HTTP_PORT` in `.env`)

### Step 1: Prepare Environment

```bash
cd /mnt/Storage/Projects/flutterpos/docker


# Copy example environment file

cp .env.example .env


# Edit environment file with secure passwords

nano .env

# OR

vim .env

```

**CRITICAL**: Change these values in `.env`:

- `MYSQL_ROOT_PASSWORD` - Strong password for MariaDB root

- `MYSQL_PASSWORD` - Strong password for Appwrite database user

- `APPWRITE_OPENSSL_KEY` - Generate with: `openssl rand -hex 32`

- `EXECUTOR_SECRET` - Generate with: `openssl rand -hex 32`

### Step 2: Create Persistent Storage Directories

```bash
sudo mkdir -p /mnt/storage/appwrite/{mysql,redis,config,storage,functions,builds,cache}
sudo chown -R $USER:$USER /mnt/storage/appwrite/
chmod -R 755 /mnt/storage/appwrite/

```

### Step 3: Deploy Appwrite

```bash

# Start all services in detached mode

docker-compose -f appwrite-compose-web-optimized.yml up -d


# Monitor logs (Ctrl+C to exit)

docker-compose -f appwrite-compose-web-optimized.yml logs -f


# Check service status

docker-compose -f appwrite-compose-web-optimized.yml ps

```

**Expected Output**: All services should show "Up (healthy)" status after 30-60 seconds.

### Step 4: Access Appwrite Console

1. Open browser: `http://localhost:8080` (or your configured domain)
2. Create your first account (this will be the admin)
3. Note your user ID - you'll need it for API access

### Step 5: Create FlutterPOS Project

In Appwrite Console:

1. Click "Create Project"
2. Name: `FlutterPOS-Backend`
3. Note the **Project ID** (e.g., `6940a64500383754a37f`)

### Step 6: Generate API Key

1. Open your project
2. Navigate to "Settings" → "API Keys"
3. Click "Add API Key"
4. Name: `Backend-Sync-Key`
5. Scopes: Select ALL permissions (or minimum: `databases.read`, `databases.write`, `collections.read`, `collections.write`, `documents.read`, `documents.write`)
6. Copy the **API Key** (you won't see it again!)

### Step 7: Create Database and Collections

#### Option A: Manual (via Console)

1. Navigate to "Databases" → "Create Database"
2. Database ID: `pos_db` (custom ID)
3. Name: `POS Database`

Create these collections (with custom IDs):

- `products` - Product catalog

- `categories` - Product categories

- `modifier_groups` - Modifier groups (e.g., "Toppings", "Sizes")

- `orders` - Transaction orders

- `business_info` - Business configuration

- `counters` - Auto-increment counters

For each collection, add these attributes:

**products**:

- `name` (string, required)

- `price` (double, required)

- `category_id` (string)

- `sku` (string)

- `description` (string)

- `is_active` (boolean, default: true)

**categories**:

- `name` (string, required)

- `icon` (string)

- `color` (string)

- `sort_order` (integer)

**modifier_groups**:

- `name` (string, required)

- `selection_type` (string) // "single" or "multiple"

- `required` (boolean)

- `items` (string) // JSON array

**orders**:

- `order_number` (string, required)

- `total_amount` (double, required)

- `items` (string) // JSON array

- `payment_method` (string)

- `business_mode` (string)

- `created_at` (datetime)

**business_info**:

- `business_name` (string)

- `tax_rate` (double)

- `service_charge_rate` (double)

- `currency_symbol` (string)

- `is_tax_enabled` (boolean)

- `is_service_charge_enabled` (boolean)

**counters**:

- `counter_name` (string, required)

- `current_value` (integer, required)

#### Option B: Automated (via Script)

```bash

# Coming soon - collection setup script

./setup_appwrite_collections.sh

```

### Step 8: Configure Backend App

1. Build Backend flavor:

```bash
cd /mnt/Storage/Projects/flutterpos
flutter build web --no-tree-shake-icons -t lib/main_backend.dart

```

1. Run Backend app:

```bash
flutter run -d linux -t lib/main_backend.dart

# OR for Windows

flutter run -d windows -t lib/main_backend.dart

```

1. In Backend app:

   - Click "Settings" (gear icon)

   - Navigate to "Appwrite Settings"

   - Enter configuration:

     - **Endpoint**: `http://localhost:8080/v1` (or your domain)

     - **Project ID**: (from Step 5)

     - **Database ID**: `pos_db`

     - **API Key**: (from Step 6)

   - Click "Test Connection"

   - If successful, click "Save"

### Step 9: Test Sync Workflow

1. In Backend home screen, check "Sync Status" card
2. Click "Sync Now" button
3. Verify sync completes successfully
4. Check Appwrite Console → Database → Collections for synced data

### Troubleshooting

#### Services Won't Start

```bash

# Check logs for errors

docker-compose -f appwrite-compose-web-optimized.yml logs appwrite


# Restart services

docker-compose -f appwrite-compose-web-optimized.yml restart

```

#### Port Already in Use

```bash

# Check what's using port 8080

sudo lsof -i :8080


# Change port in .env file

APPWRITE_HTTP_PORT=8081

```

#### Database Connection Failed

```bash

# Verify MariaDB is healthy

docker-compose -f appwrite-compose-web-optimized.yml exec mariadb mysql -u appwrite -p -e "SHOW DATABASES;"


# Reset database (WARNING: destroys all data)

docker-compose -f appwrite-compose-web-optimized.yml down -v
rm -rf /mnt/storage/appwrite/mysql/*
docker-compose -f appwrite-compose-web-optimized.yml up -d

```

#### Sync Fails in Backend App

- Verify API key has correct permissions

- Check endpoint URL (must include `/v1`)

- Ensure database ID matches exactly

- Check Appwrite logs: `docker-compose logs appwrite | grep ERROR`

### Maintenance Commands

```bash

# Stop services

docker-compose -f appwrite-compose-web-optimized.yml stop


# Start services

docker-compose -f appwrite-compose-web-optimized.yml start


# Restart services

docker-compose -f appwrite-compose-web-optimized.yml restart


# View logs

docker-compose -f appwrite-compose-web-optimized.yml logs -f


# Stop and remove containers (keeps data)

docker-compose -f appwrite-compose-web-optimized.yml down


# Stop and remove everything including volumes (DESTROYS DATA)

docker-compose -f appwrite-compose-web-optimized.yml down -v


# Check disk usage

du -sh /mnt/storage/appwrite/*

```

### Security Hardening (Production)

1. **Change default ports**:

   - Edit `.env`: `APPWRITE_HTTP_PORT=9090`

   - Use reverse proxy (nginx/traefik) for SSL

2. **Enable HTTPS**:

   - Set `APPWRITE_FORCE_HTTPS=enabled`

   - Configure SSL certificates in compose file

3. **Restrict CORS**:

   - Change `_APP_CONSOLE_WHITELIST_ORIGINS` to your specific domains

   - Example: `https://backend.extropos.org,https://app.extropos.org`

4. **Enable abuse protection**:

   - Set `APPWRITE_DISABLE_ABUSE=disabled`

5. **Firewall rules**:

```bash
sudo ufw allow 8080/tcp  # Appwrite HTTP

sudo ufw allow 8443/tcp  # Appwrite HTTPS (if enabled)

```

### Backup Strategy

```bash

# Backup database

docker-compose exec mariadb mysqldump -u appwrite -p appwrite > backup_$(date +%Y%m%d).sql


# Backup storage

tar -czf storage_backup_$(date +%Y%m%d).tar.gz /mnt/storage/appwrite/storage/


# Backup configuration

cp /mnt/storage/appwrite/config/*.json ~/backups/

```

### Next Steps

Once deployment is verified:

1. ✅ Test sync workflow (Backend → Appwrite → POS)
2. 🔄 Move to Phase 2: Cloud Backup System
3. 🔄 Implement automated backups
4. 🔄 Set up remote management features

---

**Deployment Status**: Phase 1 infrastructure ready for testing
**Last Updated**: January 2026
**FlutterPOS Version**: 1.0.27+
