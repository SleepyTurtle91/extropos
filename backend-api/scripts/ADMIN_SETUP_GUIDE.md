# Default Admin User Setup Guide

## Overview

The **Default Admin User Setup** creates the initial administrator account for FlutterPOS Backend API. This account is required to bootstrap the system and manage other users.

## Quick Start (Windows)

```powershell
cd E:\flutterpos\backend-api\scripts
.\setup-default-admin.ps1

```

## Quick Start (Linux/macOS)

```bash
cd /path/to/flutterpos/backend-api
node scripts/setup-default-admin.js

```

## Default Admin Credentials

| Field | Value |
|-------|-------|
| **Email** | `admin@extropos.com` |

| **Password** | `Admin@123` |

| **PIN** | `0000` |

| **Role** | `admin` |

| **Status** | Active |

| **Permissions** | 19 (full system access) |

## Admin Permissions

The default admin user receives all 19 permissions:

### User Management (4)

- `users:create` - Create new user accounts

- `users:read` - View user profiles

- `users:update` - Edit user information

- `users:delete` - Remove user accounts

### Product Management (4)

- `products:create` - Add new products

- `products:read` - View product catalog

- `products:update` - Modify product details

- `products:delete` - Remove products

### Category Management (4)

- `categories:create` - Create product categories

- `categories:read` - View categories

- `categories:update` - Edit category details

- `categories:delete` - Remove categories

### Sales Operations (3)

- `sales:create` - Create transactions

- `sales:read` - View transaction history

- `sales:refund` - Process refunds

### Reports & Settings (4)

- `reports:read` - Access analytics

- `reports:export` - Export report data

- `settings:manage` - Configure system settings

- `inventory:manage` - Manage stock levels

## Prerequisites

### Requirements

✅ Node.js 18+ installed  

✅ Database collections created (run `setup-user-management-database.ps1` first)  
✅ Appwrite API running (`docker-compose up -d`)  
✅ `.env.backend` file configured with:

- `APPWRITE_ENDPOINT`

- `APPWRITE_PROJECT_ID`

- `APPWRITE_API_KEY`

### Verify Prerequisites

```bash

# Check Node.js

node --version


# Check Appwrite API

curl http://localhost:80/v1/health


# Check .env.backend

cat .env.backend | grep APPWRITE

```

## Installation Steps

### Step 1: Navigate to Scripts Directory

```powershell
cd E:\flutterpos\backend-api\scripts

```

### Step 2: Run Setup Script (Windows)

```powershell
.\setup-default-admin.ps1

```

**Optional flags:**

```powershell

# Skip confirmation prompt

.\setup-default-admin.ps1 -Force


# Run with explicit environment

$env:APPWRITE_API_KEY = "your-key"; .\setup-default-admin.ps1

```

### Step 3: Verify Success

Expected output:

```
═══════════════════════════════════════════════════
ADMIN USER CREDENTIALS
═══════════════════════════════════════════════════
User ID:  [generated-id]
Email:    admin@extropos.com
Password: Admin@123
PIN:      0000
Role:     admin
Status:   Active
Permissions: 19 permissions granted
═══════════════════════════════════════════════════

```

## Testing the Admin Account

### Test 1: Login via Postman

1. Open **Postman**
2. Load collection: `FlutterPOS-User-Backend-API.postman_collection.json`
3. Navigate to: **Authentication → Login**
4. Request body:

```json
{
  "email": "admin@extropos.com",
  "password": "Admin@123"
}

```

1. Click **Send**
2. Verify response: **200 OK** with JWT token

### Test 2: Get Current User

1. In Postman, navigate to: **Authentication → Get Current User**
2. Verify token is set in Authorization header
3. Click **Send**
4. Verify response shows admin profile with all permissions

### Test 3: List All Users

1. Navigate to: **User Management → Get All Users**
2. Click **Send**
3. Verify response: **200 OK** with admin user in list

### Test 4: Create New User (Admin Action)

1. Navigate to: **User Management → Create User (Admin Only)**
2. Modify request body with new user details
3. Click **Send**
4. Verify response: **201 Created**

## Security Best Practices

### ⚠️ Critical: Change Default Credentials (Production Only)

```bash

# Step 1: Login with default credentials

POST /auth/login
{
  "email": "admin@extropos.com",
  "password": "Admin@123"
}


# Step 2: Change password immediately

PUT /auth/change-password
{
  "currentPassword": "Admin@123",
  "newPassword": "SecurePassword@2026!xyz"
}


# Step 3: Store new password in secure vault

# (1Password, LastPass, HashiCorp Vault, etc.)

```

### Recommended Actions

1. **Change default password** on first production deployment

2. **Rotate API keys** in `.env.backend` every 90 days

3. **Enable 2FA** if available in Appwrite

4. **Use strong password** (min 12 characters, mix of types)

5. **Restrict admin access** to authorized personnel only

6. **Audit admin logins** regularly

7. **Create dedicated admin accounts** for different responsibilities

8. **Disable default admin** after creating admin users for staff

## Multiple Admin Accounts

### Create Additional Admins (via API)

```bash
POST /api/users
Authorization: Bearer {{admin_token}}
Content-Type: application/json

{
  "email": "backup-admin@extropos.com",
  "password": "SecurePassword@123",
  "name": "Backup Administrator",
  "role": "admin",
  "pin": "9999"
}

```

### Create Manager Accounts

```bash
{
  "email": "manager@example.com",
  "password": "ManagerPass@123",
  "name": "Store Manager",
  "role": "manager",
  "permissions": [
    "users:read",
    "users:update",
    "products:read",
    "products:create",
    "sales:create",
    "sales:read"
  ]
}

```

## Troubleshooting

### Issue: "Admin user already exists"

**Cause**: Admin account was previously created  
**Solution**: The script will skip creation if admin exists. To reset:

```bash

# Via Postman: Reset admin password

POST /api/users/[admin_id]/reset-password
Authorization: Bearer {{admin_token}}
{
  "newPassword": "NewTempPassword@123"
}

```

### Issue: "APPWRITE_API_KEY not found"

**Cause**: Environment variables not loaded  
**Solution**:

```powershell

# Reload from file

$env:APPWRITE_API_KEY = (Get-Content .env.backend | Select-String "APPWRITE_API_KEY=" | ForEach-Object { $_ -replace 'APPWRITE_API_KEY=' }).Trim()
.\setup-default-admin.ps1

```

### Issue: "Database collection not found"

**Cause**: Users collection doesn't exist  
**Solution**:

```bash

# Create collections first

cd E:\flutterpos\docker
.\setup-user-management-database.ps1

# Then run admin setup

cd E:\flutterpos\backend-api\scripts
.\setup-default-admin.ps1

```

### Issue: "Connection refused - is Appwrite running?"

**Cause**: Docker containers not running  
**Solution**:

```bash

# Start Docker containers

cd E:\flutterpos\docker
docker-compose up -d


# Verify health

docker-compose ps
curl http://localhost:80/v1/health

```

### Issue: Node.js not found

**Cause**: Node.js not installed or not in PATH  
**Solution**:

```bash

# Install Node.js from https://nodejs.org/

# Or check PATH:

node --version
npm --version


# If installed but not found:

$env:PATH += ";C:\Program Files\nodejs"

```

## Verification Checklist

After setup, verify all components:

- [ ] Admin user created successfully

- [ ] Can login via Postman with <admin@extropos.com>

- [ ] Token returned in login response

- [ ] GET /auth/me returns admin profile

- [ ] All 19 permissions are assigned

- [ ] Can create new users via POST /users

- [ ] User role restrictions working (cashier can't create users)

- [ ] Database shows admin user document in Appwrite Console

## Integration with Flutter App

### Step 1: Update Backend URL in Flutter

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3001/api';
  // For production:
  // static const String baseUrl = 'https://api.yourdomain.com/api';
}

```

### Step 2: Test Login Flow in Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final token = data['data']['token'];
    
    // Store token securely
    await SecureStorage.save('access_token', token);
    
    return token;
  }
  
  return null;
}

```

### Step 3: Use Token in Subsequent Requests

```dart
final token = await SecureStorage.read('access_token');

final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/users'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json'
  },
);

```

## Maintenance & Monitoring

### Monitor Admin Account

```bash

# Check admin login attempts

GET /api/users/[admin_id]


# View recent sessions

GET /api/sessions?user_id=admin_id


# Export audit logs

GET /api/audit-logs?user_id=admin_id&action=login

```

### Regular Maintenance Tasks

- [ ] **Weekly**: Review admin login audit logs

- [ ] **Monthly**: Rotate JWT secret key

- [ ] **Quarterly**: Update admin password

- [ ] **Quarterly**: Review and update permissions

- [ ] **Quarterly**: Audit user access levels

- [ ] **Annually**: Full security audit

## Support & Resources

- **Backend API**: `backend-api/` directory

- **Documentation**: `backend-api/docs/` directory

- **Postman Collection**: `backend-api/postman/FlutterPOS-User-Backend-API.postman_collection.json`

- **Environment Config**: `docker/.env.backend`

- **Database Guide**: `APPWRITE_DATABASE_SETUP_COMPLETE.md`

---

**Status**: ✅ Production Ready  
**Last Updated**: January 28, 2026  
**Version**: 1.0.0
