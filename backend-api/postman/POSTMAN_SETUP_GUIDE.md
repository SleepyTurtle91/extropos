# Postman API Collection Setup Guide

## Overview

The **FlutterPOS User Backend API** Postman collection provides complete API testing and documentation for the user authentication and management system.

## Quick Start

### 1. Import the Collection

1. Open **Postman**
2. Click **Import** (top-left)

3. Select **File** tab

4. Navigate to: `backend-api/postman/FlutterPOS-User-Backend-API.postman_collection.json`
5. Click **Import**

### 2. Set Environment Variables

The collection uses these variables (auto-populated after requests):

| Variable | Initial Value | Set By | Purpose |
|----------|---------------|--------|---------|
| `base_url` | `http://localhost:3001/api` | Manual | API base endpoint |
| `access_token` | (empty) | Login/Register | JWT authentication token |
| `user_id` | (empty) | Login/Register | Current user ID |
| `user_email` | (empty) | Register | Created user email |
| `new_user_id` | (empty) | Create User | Admin-created user ID |
| `cashier_token` | (empty) | Manual | Cashier user's JWT (for RBAC tests) |

## API Endpoints Overview

### Authentication (6 endpoints)

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|----------------|
| POST | `/auth/register` | Create new user account | ❌ No |
| POST | `/auth/login` | Authenticate user, get JWT | ❌ No |
| GET | `/auth/me` | Get current user profile | ✅ Yes |
| POST | `/auth/refresh` | Generate new JWT token | ✅ Yes |
| PUT | `/auth/change-password` | Update own password | ✅ Yes |
| POST | `/auth/logout` | Invalidate session | ✅ Yes |

### User Management (7 endpoints)

| Method | Endpoint | Purpose | Auth | Role Required |
|--------|----------|---------|------|---------------|
| GET | `/users` | List all users (paginated) | ✅ | manager+ |

| GET | `/users/:id` | Get user details | ✅ | any |
| POST | `/users` | Create new user | ✅ | admin |
| PUT | `/users/:id` | Update user profile | ✅ | admin/owner |
| PATCH | `/users/:id/status` | Activate/deactivate user | ✅ | admin |
| POST | `/users/:id/reset-password` | Reset user password | ✅ | admin |
| DELETE | `/users/:id` | Delete user | ✅ | admin |

## Testing Workflow

### Step 1: User Registration

1. Open **Authentication → Register User**
2. Modify email/password/name in request body
3. Click **Send**
4. Verify status: **201 Created**
5. Check **Tests** tab - `access_token` and `user_id` auto-populated

### Step 2: Login

1. Open **Authentication → Login**
2. Use registered email and password
3. Click **Send**
4. Verify status: **200 OK**
5. Check response token is stored in `access_token` variable

### Step 3: Get Current User

1. Open **Authentication → Get Current User**
2. Click **Send**
3. Verify status: **200 OK**
4. Response shows your full user profile

### Step 4: User Management

1. Open **User Management → Get All Users**
2. Click **Send**
3. Browse returned user list
4. Use any `id` in subsequent requests

### Step 5: Create Admin User (requires admin token)

1. First login with **<admin@extropos.com>** credentials

2. Copy returned token to `access_token`
3. Open **User Management → Create User (Admin Only)**
4. Click **Send**
5. Verify status: **201 Created**
6. New user ID stored in `new_user_id`

## Testing RBAC & Permissions

### Test 1: Verify Admin Access

```
1. Login with admin account (access_token set)
2. GET /users → Should succeed (200)
3. POST /users → Should succeed (201)
4. DELETE /users/:id → Should succeed (200)

```

### Test 2: Verify Cashier Access Restrictions

```
1. Login with cashier account → Get token
2. Paste token into Authorization header for CRUD tests
3. GET /users → Should succeed (200 - read own info)

4. POST /users → Should fail (403 - Forbidden)

5. PUT /users/:id → Should fail (403 - Forbidden)

```

### Test 3: Account Lockout (5 failed attempts)

```
1. Open Error Scenarios → Account Lockout Test
2. Send request 5 times with wrong password
3. 6th attempt should return: "Account locked - try again in 15 minutes"

4. Login after 15 minutes should succeed

```

## Error Handling Tests

### Test Missing Token

1. Open **Error Scenarios → Access Protected Route Without Token**
2. Click **Send**
3. Expected response: **401 Unauthorized**

```json
{
  "status": "error",
  "message": "No authorization token provided"
}

```

### Test Invalid Token

1. Open **Error Scenarios → Access Protected Route with Invalid Token**
2. Click **Send**
3. Expected response: **401 Unauthorized**

```json
{
  "status": "error",
  "message": "Invalid token"
}

```

### Test Permission Denied

1. Open **Error Scenarios → Access Admin Endpoint with Cashier Role**
2. Ensure `cashier_token` is in Authorization header
3. Click **Send**
4. Expected response: **403 Forbidden**

```json
{
  "status": "error",
  "message": "Access denied - admin role required"

}

```

## Request Body Examples

### Register New User

```json
{
  "email": "user@example.com",
  "password": "SecurePassword@123",
  "name": "John Doe",
  "role": "cashier",
  "pin": "1234",
  "phone": "+60123456789"
}

```

### Login

```json
{
  "email": "user@example.com",
  "password": "SecurePassword@123"
}

```

### Create User (Admin)

```json
{
  "email": "manager@example.com",
  "password": "ManagerPass@123",
  "name": "Jane Manager",
  "role": "manager",
  "pin": "5678",
  "phone": "+60187654321",
  "permissions": [
    "users:read",
    "users:update",
    "products:create",
    "sales:create"
  ]
}

```

### Update User

```json
{
  "name": "Jane Doe Updated",
  "phone": "+60198765432",
  "avatarUrl": "https://example.com/avatar.jpg",
  "permissions": [
    "sales:create",
    "sales:read",
    "products:read"
  ]
}

```

### Change Password

```json
{
  "currentPassword": "OldPassword@123",
  "newPassword": "NewPassword@456"
}

```

### Reset Password (Admin)

```json
{
  "newPassword": "TempPassword@123"
}

```

### Toggle User Status

```json
{
  "isActive": false
}

```

## Common Response Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | Success | GET request, successful update |
| 201 | Created | New user/resource created |
| 400 | Bad Request | Missing required fields |
| 401 | Unauthorized | No token or invalid token |
| 403 | Forbidden | Insufficient permissions |
| 409 | Conflict | Duplicate email during registration |
| 429 | Too Many Requests | Rate limit exceeded (100/min) |
| 500 | Server Error | Database/backend issue |

## Testing Automation

### Pre-request Scripts

The collection includes **pre-request scripts** that:

- Auto-populate request paths with variable values

- Format timestamps correctly

- Validate required fields

### Test Scripts

Each request includes **test scripts** that:

- Verify response status codes

- Extract tokens and IDs for subsequent requests

- Log debug information to console

- Validate response structure

### Auto-populated Variables

After successful authentication:

- **access_token** → Used in Authorization header for subsequent requests

- **user_id** → Used in path parameters

- **user_email** → Reference for verification

- **new_user_id** → Created user ID for further operations

## Tips & Best Practices

### 1. Always Login First

The `access_token` variable must be set before calling protected endpoints.

```
Step 1: Auth → Login
Step 2: Use returned token in subsequent requests

```

### 2. Use Collection Variables

All requests use `{{variable}}` placeholders - modify base values in **Variables** tab.

### 3. Test Roles Separately

Create separate tokens for different roles:

- Admin token: `admin@extropos.com`

- Manager token: `manager@example.com`

- Cashier token: `cashier@example.com`

Store in environment variables before running RBAC tests.

### 4. Monitor Network Tab

Check **Network** tab in Postman for:

- Response headers (token format, timing)

- Actual request sent (headers, body)

- Performance metrics

### 5. Run Complete Test Suite

1. **Authentication tab** → Run all 6 requests sequentially

2. **User Management tab** → Test CRUD operations

3. **Error Scenarios tab** → Verify error handling

## Troubleshooting

### Issue: "No authorization token provided"

**Solution**: First run the **Login** request to populate `access_token` variable.

### Issue: "Invalid token"

**Solution**: Check if token has expired. Run **Refresh Token** to get new token.

### Issue: "Access denied - admin role required"

**Solution**: Use admin account for login. Check RBAC middleware is enforcing role checks.

### Issue: "Account locked"

**Solution**: Wait 15 minutes or use admin to reset via **Reset User Password** endpoint.

### Issue: "User with this email already exists"

**Solution**: Use unique email for each registration test.

## Integration with Frontend

### Flutter App Integration Steps

1. **Postman → Export** the collection as cURL format

2. **Copy endpoints** from Postman to Flutter HTTP client

3. **Use tokens** from Postman responses for testing authentication flow

4. **Verify requests** in Postman before implementing in Flutter code

### Example Flutter Implementation

```dart
// Login in Flutter
final response = await http.post(
  Uri.parse('http://localhost:3001/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'email': email,
    'password': password
  }),
);

if (response.statusCode == 200) {
  final token = json.decode(response.body)['data']['token'];
  // Store token in secure storage
  prefs.setString('access_token', token);
}

// Subsequent requests with token
final response = await http.get(
  Uri.parse('http://localhost:3001/api/users'),
  headers: {
    'Authorization': 'Bearer $token'
  },
);

```

## Support & Documentation

- **Base URL**: `http://localhost:3001/api`

- **Backend Source**: `backend-api/` directory

- **Database**: Appwrite (`pos_db` database)

- **Auth Method**: JWT (24-hour expiry)

- **Rate Limit**: 100 requests per minute per user

---

**Last Updated**: January 28, 2026  
**API Version**: 1.0.0  
**Status**: Production Ready
