# Quick Start: Configure Your Appwrite Instance

This guide shows the fastest way to configure Appwrite with your API key and start using multi-tenant provisioning.

## Step 1: Run the Test Script

Test your Appwrite connection and API key permissions:

```bash
cd /mnt/Storage/Projects/flutterpos
./scripts/test_appwrite_config.sh

```

When prompted, enter:

- **Endpoint**: Your Appwrite server URL (e.g., `https://appwrite.extropos.org/v1`)

- **Project ID**: Get from Appwrite Console → Settings → General

- **API Key**: `standard_efb1a582dc22a5a476b13e2f36fccbbc7c48f88c3cfc8c60cc9c09a2ba49a2ca...` (paste your full key)

The script will verify:

- ✓ Server is reachable

- ✓ API key is valid

- ✓ Permissions are correct

- ✓ List existing databases

## Step 2: Configure the Backend App

### Option A: Using the UI (Recommended for Security)

1. **Run the Backend App**:

   ```bash
   flutter run -d linux lib/main_backend.dart
   # Or for web browser:

   flutter run -d chrome lib/main_backend_web.dart
   ```

2. **Open Appwrite Settings**:

   - Click the storage icon (📦) in the top-right corner of the AppBar

3. **Enter Credentials**:

   - **Appwrite Endpoint**: `https://appwrite.extropos.org/v1`

   - **Project ID**: (from Appwrite Console)

   - **API Key**: Paste your full API key

4. **Save & Test**:

   - Click "Save Settings"

   - Click "Test Connection"

   - You should see "Connected" status

### Option B: Using Environment File (For Development)

1. **Create local environment file**:

   ```bash
   cp .env.appwrite.template .env.appwrite.local
   ```

2. **Edit .env.appwrite.local**:

   ```bash
   nano .env.appwrite.local
   ```

3. **Fill in your values**:

   ```env
   APPWRITE_ENDPOINT=https://appwrite.extropos.org/v1
   APPWRITE_PROJECT_ID=your_project_id_here
   APPWRITE_API_KEY=standard_efb1a582dc22a5a476b13e2f36fccbbc7c48f88c3cfc8c60cc9c09a2ba49a2ca...
   ```

4. **Load in your app** (you'll need to add dotenv package or read manually)

**Important**: `.env.appwrite.local` is in `.gitignore` - it won't be committed.

## Step 3: Create Your First Tenant

1. **Open Backend App** (if not already running)

2. **Navigate to Tenant Onboarding**:

   - From the main menu, click "Tenant Onboarding"

3. **Fill in Tenant Details**:

   ```
   Business Name: Coffee Shop Central
   Owner Name: John Doe
   Owner Email: john@coffeeshop.com
   Custom Domain: (leave empty for now)
   ```

4. **Click "Create Tenant"**

5. **Save the Tenant ID**:

   - You'll see a green success message with the tenant ID

   - Example: `Tenant ID: 675726a8001e2b4f9c1d`

   - **Save this ID** - you'll need it to configure POS apps for this tenant

## Step 4: Verify Tenant Creation

### Using Appwrite Console

1. Open: `https://appwrite.extropos.org` (or your Appwrite URL without `/v1`)
2. Login to Appwrite Console
3. Go to "Databases" in the left sidebar
4. You should see a new database with your tenant's name
5. Click on it to see all 6 collections:

   - business_info

   - categories

   - products

   - modifiers

   - tables

   - users

### Using cURL

```bash

# List all databases

curl -X GET "https://appwrite.extropos.org/v1/databases" \
  -H "X-Appwrite-Project: YOUR_PROJECT_ID" \
  -H "X-Appwrite-Key: standard_efb1a582dc22a5a476b13e..."


# Get specific tenant database (replace TENANT_ID)

curl -X GET "https://appwrite.extropos.org/v1/databases/TENANT_ID" \
  -H "X-Appwrite-Project: YOUR_PROJECT_ID" \
  -H "X-Appwrite-Key: standard_efb1a582dc22a5a476b13e..."

```

## What You Just Created

Each tenant now has:

```
Tenant Database (isolated)
├── business_info collection
│   └── Initial business document (with tenant name & email)
├── categories collection (empty, ready for products)
├── products collection (empty, ready for menu items)
├── modifiers collection (empty, ready for add-ons)
├── tables collection (empty, ready for restaurant mode)
└── users collection
    └── Admin user document (for the owner)

```

## Next Steps

1. **Configure POS App for this Tenant**:

   - Each POS counter needs the tenant's database ID

   - Update POS config to point to the tenant's database

2. **Add Products & Categories**:

   - Use the Backend app → Categories Management

   - Use the Backend app → Products Management

3. **Create More Tenants**:

   - Repeat Step 3 for each new customer/branch

   - Each gets a completely isolated database

4. **Set Up Domain Routing** (Optional):

   - Configure Traefik to route `tenant1.extropos.org` → tenant 1's database

   - See: `docs/APPWRITE_MULTI_TENANT_SETUP.md` for subdomain routing

## Troubleshooting

### "Connection failed" in the app

**Check**:

```bash

# Can you reach Appwrite?

curl https://appwrite.extropos.org/v1/health/version


# Is the API key valid?

./scripts/test_appwrite_config.sh

```

### "Permission denied" when creating tenant

**Solution**: Your API key needs these scopes in Appwrite Console:

- `databases.read`

- `databases.write`

- `collections.write`

- `documents.write`

Go to: Appwrite Console → Settings → API Keys → Edit your key → Add scopes

### Tenant creation times out

**Cause**: Creating 6 collections + attributes takes time (each is a separate API call)

**Solution**: Wait 30-60 seconds. Check Appwrite Console to see if the database was created.

## Security Reminders

- ✅ API key is stored locally (SharedPreferences) - not in source code

- ✅ `.env.appwrite.local` is git-ignored

- ✅ Each tenant has isolated database - no cross-tenant access

- ⚠️ Rotate API keys every 90 days

- ⚠️ Use separate keys for dev/staging/prod

## Support & Documentation

- **Full Guide**: `docs/APPWRITE_MULTI_TENANT_SETUP.md`

- **Self-Hosting**: `docs/APPWRITE_SELF_HOSTING.md`

- **Test Script**: `./scripts/test_appwrite_config.sh`

---

**You're all set!** Start creating tenants and managing your multi-tenant POS system. 🎉
