# Appwrite Configuration & Multi-Tenant Setup Guide

This guide shows how to configure Appwrite with your API key and use the automated tenant provisioning system for multi-tenant deployments.

## Quick Start: Configure Appwrite

### Option 1: Using the Backend App UI (Recommended)

1. **Run the Backend App**:

   ```bash
   cd /mnt/Storage/Projects/flutterpos
   flutter run -d linux lib/main_backend.dart
   # Or for web:

   flutter run -d chrome lib/main_backend_web.dart
   ```

2. **Navigate to Appwrite Settings**:

   - Click the storage icon in the top-right AppBar, or

   - Go to Settings → Appwrite Integration from the menu

3. **Enter Your Credentials**:

   - **Appwrite Endpoint**: Your Appwrite server URL

     - Example: `https://appwrite.extropos.org/v1`

     - Or local: `http://localhost/v1`

   - **Project ID**: Your Appwrite project ID (get from Appwrite Console)

   - **API Key**: Your server API key

4. **Save and Test**:

   - Tap "Save Settings"

   - Tap "Test Connection" to verify

### Security Best Practices

1. **Never commit API keys to git**
2. **Use scoped API keys** with minimum required permissions

3. **Rotate keys regularly** (every 90 days)

4. Store keys in app UI (SharedPreferences) or environment variables

## Multi-Tenant Provisioning

### What Gets Created Automatically

When you create a tenant using the Tenant Onboarding screen:

```text
Tenant Database (ID: unique-tenant-id)
├── business_info (collection) + initial document

├── categories (collection)
├── products (collection)
├── modifiers (collection)
├── tables (collection)
└── users (collection) + admin user document

```text


### Using the Tenant Onboarding Screen


1. Open Backend App → "Tenant Onboarding"
2. Fill in tenant details (name, owner email, owner name)
3. Click "Create Tenant"
4. Save the returned Tenant ID for POS configuration


### Programmatic Tenant Creation



```dart
import 'package:flutterpos/services/tenant_provisioning_service.dart';

final tenantId = await TenantProvisioningService.instance.createTenant(
  tenantName: 'My Restaurant',
  ownerEmail: 'owner@restaurant.com',
  ownerName: 'John Doe',
);

```text


## Testing & Verification



### Test Script



```bash
./scripts/test_appwrite_config.sh

```text


### Manual cURL Tests



```bash

# Health check

curl http://localhost/v1/health/version


# List databases

curl -X GET "http://localhost/v1/databases" \
  -H "X-Appwrite-Project: YOUR_PROJECT_ID" \
  -H "X-Appwrite-Key: YOUR_API_KEY"

```text


## Troubleshooting


- **Connection failed**: Check endpoint URL and network accessibility

- **Invalid API key**: Verify key in Appwrite Console → Settings → API Keys

- **Permission denied**: Add required scopes (databases.write, collections.write)


## Next Steps


- Configure subdomain routing for tenants

- Implement billing/quotas per tenant

- Set up automated backups

- Add tenant-specific branding

See `APPWRITE_QUICK_START.md` for step-by-step setup instructions.
