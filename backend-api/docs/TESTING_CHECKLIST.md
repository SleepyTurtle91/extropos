# FlutterPOS Backend API - Testing Checklist

## Pre-Testing Verification

### Environment & Prerequisites

- [ ] Docker containers running (`docker-compose ps` shows all healthy)

- [ ] Appwrite API accessible (<http://localhost:80/v1/health> returns 200)

- [ ] Backend API running (<http://localhost:3001/api> health check)

- [ ] Database collections created (users, sessions)

- [ ] Node.js 18+ installed (`node --version`)

- [ ] Postman installed and ready

- [ ] `.env.backend` file configured with all required variables

- [ ] Admin user created (`admin@extropos.com`)

### Verification Commands

```bash

# Verify Docker containers

docker-compose ps


# Verify Appwrite health

curl http://localhost:80/v1/health


# Verify Backend API

curl http://localhost:3001/api/health


# Check Node.js

node --version
npm --version


# Check environment variables

cat .env.backend | grep -E "APPWRITE_|JWT_"

```

---

## Phase 1: Authentication Tests

### Test 1.1: User Registration

**Endpoint**: `POST /api/auth/register`

**Test Data**:

```json
{
  "email": "testuser@example.com",
  "password": "TestPassword@123",
  "name": "Test User",
  "role": "cashier",
  "pin": "1234",
  "phone": "+60123456789"
}

```

**Expected Results**:

- [ ] Status: **201 Created**

- [ ] Response contains `user` object with:

  - [ ] `id` (string)

  - [ ] `email` (matches input)

  - [ ] `name` (matches input)

  - [ ] `role` (matches input)

- [ ] Token generated for new user

- [ ] Password hashed in database (not plaintext)

- [ ] PIN hashed in database (not plaintext)

**Test Case Variations**:

- [ ] **Missing email** → Status 400

- [ ] **Missing password** → Status 400

- [ ] **Duplicate email** → Status 409 Conflict

- [ ] **Weak password** → Status 400

- [ ] **Invalid email format** → Status 400

---

### Test 1.2: User Login (Admin)

**Endpoint**: `POST /api/auth/login`

**Test Data**:

```json
{
  "email": "admin@extropos.com",
  "password": "Admin@123"
}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] Response contains:

  - [ ] `token` (JWT format: xxx.yyy.zzz)

  - [ ] `user` object with all fields

  - [ ] `expiresIn` (24h)

  - [ ] `role` is "admin"

- [ ] Token is valid and can be decoded

- [ ] Token contains user claims (userId, email, role, permissions)

**Test Case Variations**:

- [ ] **Wrong password** → Status 401 Unauthorized

- [ ] **Non-existent email** → Status 401 Unauthorized

- [ ] **Inactive user** → Status 403 Forbidden (after disabling user)

- [ ] **Account locked** (5 failed attempts) → Status 423 Locked

- [ ] **Empty email/password** → Status 400

---

### Test 1.3: Login with Account Lockout

**Endpoint**: `POST /api/auth/login`

**Procedure**:

1. [ ] Send 5 login requests with wrong password (same email)
2. [ ] 6th login attempt should return error
3. [ ] Wait 15 minutes OR use admin to reset via POST `/api/users/:id/reset-password`
4. [ ] 7th login attempt should succeed

**Expected Results**:

- [ ] After 5 failed attempts: Account locked for 15 minutes

- [ ] Error message: "Account locked - try again in 15 minutes"

- [ ] Status: **423 Locked** (or 429 Too Many Attempts)

- [ ] After lockout expires: Login succeeds with correct password

- [ ] Failed attempt counter resets after successful login

---

### Test 1.4: Get Current User Profile

**Endpoint**: `GET /api/auth/me`

**Headers**:

```
Authorization: Bearer {{access_token}}
Content-Type: application/json

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] Response contains full user profile:

  - [ ] `id`

  - [ ] `email`

  - [ ] `name`

  - [ ] `role`

  - [ ] `isActive`

  - [ ] `permissions` (array)

  - [ ] `phone`

  - [ ] `avatarUrl`

  - [ ] `lastLogin`

  - [ ] `createdAt`

  - [ ] `updatedAt`

**Test Case Variations**:

- [ ] **No token** → Status 401

- [ ] **Invalid token** → Status 401

- [ ] **Expired token** → Status 401

---

### Test 1.5: Refresh Token

**Endpoint**: `POST /api/auth/refresh`

**Headers**:

```
Authorization: Bearer {{old_token}}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] New token issued

- [ ] Old token still valid (for graceful transition)

- [ ] New token contains same claims as old token

- [ ] Token expiry extended another 24 hours

---

### Test 1.6: Change Password

**Endpoint**: `PUT /api/auth/change-password`

**Test Data**:

```json
{
  "currentPassword": "Admin@123",
  "newPassword": "NewPassword@456"
}

```

**Headers**:

```
Authorization: Bearer {{admin_token}}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] Old password no longer works

- [ ] New password works for login

- [ ] Message: "Password changed successfully"

**Test Case Variations**:

- [ ] **Wrong current password** → Status 401 Unauthorized

- [ ] **New password same as old** → Status 400 Bad Request

- [ ] **Weak new password** → Status 400 Bad Request

- [ ] **No authorization** → Status 401

---

### Test 1.7: Logout

**Endpoint**: `POST /api/auth/logout`

**Headers**:

```
Authorization: Bearer {{access_token}}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] Message: "Logged out successfully"

- [ ] Session deleted from database

- [ ] Token still valid but session verification fails on next request

- [ ] New login required for subsequent operations

---

## Phase 2: User Management Tests

### Test 2.1: Get All Users (Paginated)

**Endpoint**: `GET /api/users?page=1&limit=20`

**Headers**:

```
Authorization: Bearer {{admin_token}}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] Response contains:

  - [ ] `users` (array of user objects)

  - [ ] `pagination` object with:

    - [ ] `page` (current page)

    - [ ] `limit` (items per page)

    - [ ] `total` (total user count)

- [ ] User objects contain: id, email, name, role, isActive, createdAt

- [ ] Results are ordered by newest first

**Test Case Variations**:

- [ ] **Page 2** → Returns next batch of users

- [ ] **Limit 50** → Returns up to 50 items

- [ ] **Filter by role=cashier** → Only cashiers returned

- [ ] **Filter by isActive=false** → Only inactive users

- [ ] **No authorization** → Status 401

- [ ] **Cashier role** (insufficient permissions) → Status 403

---

### Test 2.2: Get User by ID

**Endpoint**: `GET /api/users/{{user_id}}`

**Headers**:

```
Authorization: Bearer {{admin_token}}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] Response contains full user object:

  - [ ] All profile fields

  - [ ] Permissions array (JSON parsed)

  - [ ] Account status fields

- [ ] User can retrieve their own profile (not just admin)

**Test Case Variations**:

- [ ] **Invalid ID** → Status 404 Not Found

- [ ] **Non-existent ID** → Status 404 Not Found

- [ ] **Without authorization** → Status 401

---

### Test 2.3: Create User (Admin Only)

**Endpoint**: `POST /api/users`

**Test Data**:

```json
{
  "email": "newmanager@example.com",
  "password": "TempPassword@123",
  "name": "New Manager",
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

**Expected Results**:

- [ ] Status: **201 Created**

- [ ] User created with all provided fields

- [ ] Password hashed (not stored plaintext)

- [ ] PIN hashed (not stored plaintext)

- [ ] Role assigned correctly

- [ ] Custom permissions stored

- [ ] User can login with new password immediately

**Test Case Variations**:

- [ ] **Cashier creating user** → Status 403 Forbidden

- [ ] **Duplicate email** → Status 409 Conflict

- [ ] **Missing required fields** → Status 400

- [ ] **Invalid role** → Status 400

---

### Test 2.4: Update User Profile

**Endpoint**: `PUT /api/users/{{user_id}}`

**Test Data**:

```json
{
  "name": "Updated Name",
  "phone": "+60198765432",
  "avatarUrl": "https://example.com/avatar.jpg",
  "permissions": ["sales:read"]
}

```

**Headers**:

```
Authorization: Bearer {{admin_token}}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] User name updated

- [ ] Phone number updated

- [ ] Avatar URL updated

- [ ] Custom permissions updated

- [ ] Role unchanged (not modifiable here)

- [ ] `updatedAt` timestamp updated

**Test Case Variations**:

- [ ] **Non-existent user** → Status 404

- [ ] **Cashier updating another user** → Status 403

- [ ] **User updating own profile** → Status 200 (allowed)

---

### Test 2.5: Toggle User Status

**Endpoint**: `PATCH /api/users/{{user_id}}/status`

**Test Data**:

```json
{
  "isActive": false
}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] User `is_active` field set to false

- [ ] Inactive user cannot login

- [ ] Error message on login: "User account is disabled"

- [ ] Message: "User deactivated successfully"

**Test Case Variations**:

- [ ] **Activate user** (isActive: true) → Status 200

- [ ] **Inactive user tries to login** → Status 403

- [ ] **Reactivate user** → Can login again

- [ ] **Admin-only operation** → Cashier gets 403

---

### Test 2.6: Reset User Password (Admin Only)

**Endpoint**: `POST /api/users/{{user_id}}/reset-password`

**Test Data**:

```json
{
  "newPassword": "ResetPassword@123"
}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] User's password changed to new value

- [ ] Old password no longer works

- [ ] New password works for login

- [ ] Failed login attempts reset to 0

- [ ] Account lockout cleared

- [ ] Message: "Password reset successfully"

---

### Test 2.7: Delete User (Admin Only)

**Endpoint**: `DELETE /api/users/{{user_id}}`

**Headers**:

```
Authorization: Bearer {{admin_token}}

```

**Expected Results**:

- [ ] Status: **200 OK**

- [ ] User removed from database

- [ ] Deleted user cannot login

- [ ] GET user by ID returns 404

- [ ] Message: "User deleted successfully"

**Test Case Variations**:

- [ ] **Non-existent user** → Status 404

- [ ] **Delete self** → Status 200 (allowed but risky)

- [ ] **Cashier deleting user** → Status 403

---

## Phase 3: RBAC & Permission Tests

### Test 3.1: Admin Full Access

**Procedure**:

1. [ ] Login with admin account
2. [ ] Create new user
3. [ ] Update user
4. [ ] Delete user
5. [ ] Get all users

**Expected Results**:

- [ ] All operations succeed with 200/201/204 status

- [ ] Full access to all endpoints

---

### Test 3.2: Manager Restricted Access

**Setup**:

1. [ ] Create manager user via admin
2. [ ] Login with manager credentials

**Test Operations**:

- [ ] GET /users → Status **200 OK** ✅

- [ ] POST /users → Status **403 Forbidden** ❌

- [ ] DELETE /users/:id → Status **403 Forbidden** ❌

- [ ] GET /users/:id → Status **200 OK** ✅

- [ ] PUT /users/:id → Status **403 Forbidden** (restricted) ❌

**Expected Results**:

- [ ] Manager can read user data

- [ ] Manager cannot create/delete users

- [ ] Manager cannot modify user roles/passwords

---

### Test 3.3: Cashier Limited Access

**Setup**:

1. [ ] Create cashier user
2. [ ] Login with cashier credentials

**Test Operations**:

- [ ] GET /auth/me → Status **200 OK** ✅ (own profile)

- [ ] GET /users → Status **403 Forbidden** ❌

- [ ] POST /users → Status **403 Forbidden** ❌

- [ ] GET /users/:id → Status **200 OK** (own) ✅

**Expected Results**:

- [ ] Cashier can only access own profile

- [ ] Cashier cannot access admin/management functions

- [ ] Proper 403 Forbidden errors

---

### Test 3.4: Role Hierarchy Enforcement

**Test**: Lower role cannot modify higher role

**Procedure**:

1. [ ] Create manager user
2. [ ] Login as manager
3. [ ] Try to update admin user
4. [ ] Try to delete supervisor

**Expected Results**:

- [ ] Status **403 Forbidden**

- [ ] Message: "Cannot modify users with higher or equal role"

---

## Phase 4: Error Handling & Edge Cases

### Test 4.1: Missing Authorization Header

**Endpoint**: `GET /api/users` (without Authorization header)

**Expected Results**:

- [ ] Status: **401 Unauthorized**

- [ ] Message: "No authorization token provided"

---

### Test 4.2: Invalid JWT Format

**Endpoint**: `GET /api/users`

**Headers**:

```
Authorization: Bearer invalid.token.format

```

**Expected Results**:

- [ ] Status: **401 Unauthorized**

- [ ] Message: "Invalid token"

---

### Test 4.3: Expired Token

**Procedure**:

1. [ ] Generate token (manually set expiry to past date for testing)
2. [ ] Use token in request

**Expected Results**:

- [ ] Status: **401 Unauthorized**

- [ ] Message: "Token has expired"

- [ ] User can refresh token or re-login

---

### Test 4.4: Rate Limiting

**Procedure**:

1. [ ] Send 100 requests rapidly
2. [ ] Send 101st request

**Expected Results**:

- [ ] First 100 requests: Status **200/201**

- [ ] 101st request: Status **429 Too Many Requests**

- [ ] Message: "Too many requests - please try again later"

- [ ] After 1 minute window: Can make new requests

---

### Test 4.5: Concurrent Login Attempts

**Procedure**:

1. [ ] User A logs in
2. [ ] User A logs in again from different device
3. [ ] Both sessions should be active (or last one wins)

**Expected Results**:

- [ ] Both logins succeed

- [ ] Separate sessions created

- [ ] Logout from one session doesn't affect other

---

## Phase 5: Integration Tests

### Test 5.1: Complete User Lifecycle

**Scenario**: Full user onboarding flow

**Steps**:

1. [ ] Admin creates user: `POST /users`
2. [ ] New user logs in: `POST /auth/login`
3. [ ] New user views profile: `GET /auth/me`
4. [ ] New user changes password: `PUT /auth/change-password`
5. [ ] User logs out: `POST /auth/logout`
6. [ ] User logs in with new password
7. [ ] Admin updates user: `PUT /users/:id`
8. [ ] Admin deactivates user: `PATCH /users/:id/status`
9. [ ] Deactivated user tries to login → Status 403
10. [ ] Admin reactivates user: `PATCH /users/:id/status`
11. [ ] User can login again

**Expected Results**:

- [ ] All steps succeed with appropriate status codes

- [ ] No data corruption or state inconsistencies

---

### Test 5.2: Multi-User Concurrent Access

**Scenario**: Multiple users accessing system simultaneously

**Setup**:

- [ ] Create 5 test users with different roles

- [ ] Generate tokens for each

**Parallel Operations**:

- [ ] User A: Create transaction

- [ ] User B: Update user profile

- [ ] User C: Get user list

- [ ] User D: Change password

- [ ] User E: Logout

**Expected Results**:

- [ ] All operations succeed

- [ ] No race conditions or data conflicts

- [ ] Response times acceptable (< 1 second per request)

---

### Test 5.3: Session Timeout

**Scenario**: Session expires after inactivity

**Procedure**:

1. [ ] User logs in
2. [ ] Wait for session expiry (or modify database)
3. [ ] Attempt to use expired token

**Expected Results**:

- [ ] Status: **401 Unauthorized**

- [ ] Message: "Session expired - please log in again"

- [ ] User must re-authenticate

---

## Phase 6: Database Integrity Tests

### Test 6.1: Data Consistency

**Procedure**:

1. [ ] Create user via API
2. [ ] Check Appwrite Console
3. [ ] Verify all fields persisted correctly

**Expected Results**:

- [ ] All fields present in database

- [ ] No null/undefined critical fields

- [ ] Timestamps correct (milliseconds since epoch)

- [ ] Hashed fields not plaintext

---

### Test 6.2: Password/PIN Hashing

**Procedure**:

1. [ ] Create user with password "TestPass@123"
2. [ ] Query database directly
3. [ ] Check password_hash field

**Expected Results**:

- [ ] Password NOT stored as plaintext

- [ ] Password hash starts with `$2b$` (bcrypt format)

- [ ] Same password creates different hash each time

- [ ] PIN similarly hashed

---

### Test 6.3: Referential Integrity

**Procedure**:

1. [ ] Create session for user
2. [ ] Delete user
3. [ ] Check if session is orphaned or deleted

**Expected Results**:

- [ ] Orphaned sessions cleaned up OR

- [ ] Sessions linked to user cannot exist without user

- [ ] Cascading deletes handled properly

---

## Phase 7: Performance Tests

### Test 7.1: Login Response Time

**Procedure**:

1. [ ] Time 10 login requests
2. [ ] Calculate average response time

**Expected Results**:

- [ ] Average response time: < 500ms

- [ ] Max response time: < 1000ms

- [ ] Consistent performance

---

### Test 7.2: Get All Users Performance

**Procedure**:

1. [ ] Create 1000 test users
2. [ ] Time GET /users?limit=100 request
3. [ ] Verify pagination works

**Expected Results**:

- [ ] Response time: < 1 second

- [ ] Pagination returns correct subset

- [ ] No timeout errors

---

### Test 7.3: Token Verification Speed

**Procedure**:

1. [ ] Time JWT token verification
2. [ ] Check middleware overhead

**Expected Results**:

- [ ] Token verification: < 10ms

- [ ] Minimal performance impact

---

## Phase 8: Security Tests

### Test 8.1: SQL Injection Prevention

**Procedure**:

1. [ ] Create user with email: `admin@example.com'; DROP TABLE users; --`
2. [ ] Attempt login with malicious query

**Expected Results**:

- [ ] Query treated as literal string

- [ ] No database damage

- [ ] Request either fails safely or treats as invalid email

---

### Test 8.2: JWT Secret Vulnerability

**Procedure**:

1. [ ] Verify JWT_SECRET is set in production
2. [ ] Check default secret is NOT used

**Expected Results**:

- [ ] Custom JWT_SECRET in environment

- [ ] Default secret warning in logs (if development)

---

### Test 8.3: Password Strength Enforcement

**Procedure**:

1. [ ] Try creating user with weak password: "123"
2. [ ] Try with strong password: "SecureP@ss2026!"

**Expected Results**:

- [ ] Weak password: Status **400 Bad Request**

- [ ] Strong password: Status **201 Created**

---

### Test 8.4: XSS Prevention

**Procedure**:

1. [ ] Create user with name: `<script>alert('XSS')</script>`
2. [ ] Retrieve user profile

**Expected Results**:

- [ ] Script tags escaped or sanitized

- [ ] No JavaScript execution

- [ ] Safe rendering in client

---

## Phase 9: Postman Collection Verification

### Test 9.1: Pre-request Scripts

**Procedure**:

1. [ ] Run "Register User" request
2. [ ] Check if variables auto-populated

**Expected Results**:

- [ ] `access_token` set automatically

- [ ] `user_id` set automatically

- [ ] Subsequent requests use these variables

---

### Test 9.2: Test Scripts

**Procedure**:

1. [ ] Run each request in Authentication folder
2. [ ] Check Tests tab output

**Expected Results**:

- [ ] Tests pass for successful requests

- [ ] Tests fail appropriately for error cases

- [ ] Console shows debug info

---

## Phase 10: Documentation Verification

### Test 10.1: Postman Setup Guide

**Procedure**:

1. [ ] Follow POSTMAN_SETUP_GUIDE.md exactly
2. [ ] Import collection
3. [ ] Set environment variables
4. [ ] Run test workflow

**Expected Results**:

- [ ] Guide is accurate and complete

- [ ] No missing steps or typos

- [ ] All requests work as documented

---

### Test 10.2: API Documentation

**Procedure**:

1. [ ] Read auth.routes.js comments
2. [ ] Read users.routes.js comments
3. [ ] Verify all endpoints documented

**Expected Results**:

- [ ] All endpoints have JSDoc comments

- [ ] Request/response formats documented

- [ ] Error codes listed

---

## Test Execution Summary

### Quick Test Script

```bash

# Run all phases sequentially

npm test


# Or run specific phase

npm test -- --phase 1

npm test -- --phase 2


# Run with coverage

npm test -- --coverage


# Run with verbose output

npm test -- --verbose

```

---

## Sign-Off Checklist

After completing all tests:

- [ ] Phase 1: Authentication Tests - ✅ All passed

- [ ] Phase 2: User Management Tests - ✅ All passed

- [ ] Phase 3: RBAC & Permissions Tests - ✅ All passed

- [ ] Phase 4: Error Handling Tests - ✅ All passed

- [ ] Phase 5: Integration Tests - ✅ All passed

- [ ] Phase 6: Database Integrity Tests - ✅ All passed

- [ ] Phase 7: Performance Tests - ✅ All passed

- [ ] Phase 8: Security Tests - ✅ All passed

- [ ] Phase 9: Postman Collection Tests - ✅ All passed

- [ ] Phase 10: Documentation Tests - ✅ All passed

### Issues Found & Resolution

| Issue | Severity | Status | Resolution |
|-------|----------|--------|------------|
| | | | |

### Performance Baseline

| Operation | Target | Actual | Status |
|-----------|--------|--------|--------|
| Login | < 500ms | | ✅/❌ |
| Get All Users | < 1s | | ✅/❌ |
| Token Verification | < 10ms | | ✅/❌ |

### Sign-Off

- **Tester**: ___________________

- **Date**: ___________________

- **Approved for Deployment**: ✅ Yes / ❌ No

---

**Last Updated**: January 28, 2026  
**Version**: 1.0.0  
**Status**: Ready for Testing
