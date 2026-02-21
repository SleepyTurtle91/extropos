# FlutterPOS Web Backend

A standalone web-based management interface for FlutterPOS using Appwrite as the backend.

## Features

- ✅ Appwrite connection management

- ✅ Multi-tenant database creation

- ✅ Dashboard with statistics

- ✅ Categories management

- ✅ Products management

- ✅ Modifiers management

- ✅ Business information configuration

- ✅ Responsive design

- ✅ No build process required - pure HTML/CSS/JS

## Quick Start

### 1. Ensure Appwrite is Running

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose -f appwrite-compose.yml up -d

```

### 2. Serve the Web Backend (static files)

**Option A: Python HTTP Server (Recommended)**

```bash
cd /mnt/Storage/Projects/flutterpos/web-backend
python3 -m http.server 8000

```

**Option B: PHP Built-in Server**

```bash
cd /mnt/Storage/Projects/flutterpos/web-backend
php -S localhost:8000

```

**Option C: Node.js http-server**

```bash
npm install -g http-server
cd /mnt/Storage/Projects/flutterpos/web-backend
http-server -p 8000

```

### 3. Start the Python Proxy (bypasses Appwrite domain/CORS checks)

Open a second terminal:

```bash
cd /mnt/Storage/Projects/flutterpos/web-backend
python3 proxy.py --port 9000 --target http://localhost:8080

```

- Proxy listens on `http://localhost:9000/proxy`

- Static UI stays on `http://localhost:8000`

- Both terminals must remain running while you use the web backend

### 3. Open in Browser

Navigate to: **<http://localhost:8000>**

## Default Configuration

The web backend comes pre-configured with:

- **Endpoint**: `http://127.0.0.1:8080`

- **Project ID**: `689965770017299bd5a5`

- **API Key**: Your Appwrite API key

These settings are stored in browser localStorage after first save.

## Usage

### 1. Test Connection

- Go to **Settings** tab

- Click **Test Connection** to verify Appwrite connectivity

- Click **Save Settings** to persist configuration

### 2. Create Tenant Database

- Go to **Tenants** tab

- Click **Create Tenant**

- Enter business name (e.g., "ABC Restaurant")

- Click **Create Tenant**

- A new isolated database will be created with ID: `tenant_[timestamp]`

### 3. Manage Data

- Switch to **Dashboard** to view statistics

- Use **Categories**, **Products**, **Modifiers** tabs to manage data

- **Business Info** tab for tax/service charge settings

## Architecture

```
FlutterPOS Ecosystem:
┌─────────────────────┐
│  Flutter POS App    │ ← Android tablets (production)
│  (Android/Desktop)  │
└──────────┬──────────┘
           │
           ├─ Local SQLite (offline-first)
           │
           └─ Sync with ↓
                        
┌─────────────────────┐
│  Appwrite Backend   │ ← Docker (localhost:8080)
│  (Self-hosted)      │
└──────────┬──────────┘
           │
           └─ Managed by ↓
                        
┌─────────────────────┐
│  Web Backend (You!) │ ← http://localhost:8000
│  (HTML/JS)          │
└─────────────────────┘

```

## Multi-Tenancy

Each tenant gets:

- Isolated database (`tenant_[id]`)

- Own collections: categories, products, modifiers, orders, etc.

- Separate business configuration

- Independent data (no cross-tenant access)

## CORS Note

If you encounter CORS issues, ensure:

1. Appwrite's `_APP_DOMAIN` allows your web backend origin
2. Use same protocol (http/https)
3. API key has proper permissions

If CORS/domain validation still blocks calls, keep the Python proxy running. The UI is already configured to route through `http://localhost:9000/proxy` by default.

## Troubleshooting

### Connection Failed

- Verify Appwrite is running: `docker ps | grep appwrite`

- Check endpoint URL matches Appwrite port

- Ensure API key is correct

- Check browser console for detailed errors

### Can't Create Tenant

- Verify API key has database creation permissions

- Check Appwrite logs: `docker-compose -f appwrite-compose.yml logs appwrite`

### Empty Tables

- First create a tenant database

- Then navigate to Categories/Products sections

- Collections will be created automatically

## Development

The web backend uses:

- **Appwrite Web SDK** v15.0.0 (CDN)

- Pure JavaScript (ES6+)

- No build tools required

- LocalStorage for configuration persistence

## Next Steps

1. Add collection creation for tenant databases
2. Implement CRUD operations for categories/products
3. Add data import/export functionality
4. Build sync mechanism with Flutter app
5. Add user authentication

## File Structure

```
web-backend/
├── index.html          # Main UI

├── app.js             # Application logic

└── README.md          # This file

```

## License

Same as FlutterPOS main project.
