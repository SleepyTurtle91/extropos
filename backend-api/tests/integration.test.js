/**
 * FlutterPOS Backend API - Integration Test Suite
 * 
 * Complete test suite for authentication and user management
 * Run with: npm test
 * 
 * Requirements:
 * - Jest test framework
 * - Supertest for HTTP assertions
 * - dotenv for environment variables
 */

const request = require('supertest');
const app = require('../app');
const { Client, Databases, Query } = require('node-appwrite');
require('dotenv').config();

// Initialize Appwrite client for cleanup
const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const database = new Databases(client);
const dbId = 'pos_db';

// Test data
const testUser = {
  email: `test-${Date.now()}@example.com`,
  password: 'TestPassword@123',
  name: 'Test User',
  role: 'cashier',
  pin: '1234',
  phone: '+60123456789'
};

const adminUser = {
  email: 'admin@extropos.com',
  password: 'Admin@123'
};

let adminToken = null;
let testUserToken = null;
let testUserId = null;

// Setup and teardown
beforeAll(async () => {
  console.log('\n🚀 Starting integration tests...\n');
});

afterAll(async () => {
  console.log('\n✅ Tests completed\n');
  
  // Cleanup: Delete test user
  try {
    if (testUserId) {
      await database.deleteDocument(dbId, 'users', testUserId);
      console.log('🧹 Cleaned up test user');
    }
  } catch (error) {
    console.error('Cleanup error:', error.message);
  }
});

describe('Authentication API', () => {
  describe('POST /api/auth/register', () => {
    test('should register new user successfully', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      expect(response.status).toBe(201);
      expect(response.body.status).toBe('success');
      expect(response.body.data.user).toHaveProperty('id');
      expect(response.body.data.user.email).toBe(testUser.email);
      expect(response.body.data.user.role).toBe(testUser.role);

      testUserId = response.body.data.user.id;
      testUserToken = response.body.data.token;
    });

    test('should fail registration with duplicate email', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      expect(response.status).toBe(409);
      expect(response.body.status).toBe('error');
      expect(response.body.message).toContain('already exists');
    });

    test('should fail registration with missing email', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          password: testUser.password,
          name: testUser.name
        });

      expect(response.status).toBe(400);
      expect(response.body.status).toBe('error');
    });

    test('should fail registration with missing password', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'another@example.com',
          name: testUser.name
        });

      expect(response.status).toBe(400);
    });
  });

  describe('POST /api/auth/login', () => {
    test('should login admin successfully', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send(adminUser);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data).toHaveProperty('token');
      expect(response.body.data.user.email).toBe(adminUser.email);
      expect(response.body.data.user.role).toBe('admin');

      adminToken = response.body.data.token;
    });

    test('should login test user successfully', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        });

      expect(response.status).toBe(200);
      expect(response.body.data.token).toBeDefined();
    });

    test('should fail login with wrong password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: adminUser.email,
          password: 'WrongPassword@123'
        });

      expect(response.status).toBe(401);
      expect(response.body.status).toBe('error');
    });

    test('should fail login with non-existent email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'SomePassword@123'
        });

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/auth/me', () => {
    test('should get current user profile', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.user.email).toBe(adminUser.email);
      expect(response.body.data.user.role).toBe('admin');
      expect(response.body.data.user.permissions).toBeDefined();
    });

    test('should fail without authorization token', async () => {
      const response = await request(app)
        .get('/api/auth/me');

      expect(response.status).toBe(401);
      expect(response.body.message).toContain('No authorization token');
    });

    test('should fail with invalid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid.token.here');

      expect(response.status).toBe(401);
      expect(response.body.message).toContain('Invalid token');
    });
  });

  describe('POST /api/auth/refresh', () => {
    test('should refresh token successfully', async () => {
      const response = await request(app)
        .post('/api/auth/refresh')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.token).toBeDefined();
      expect(response.body.data.token).not.toBe(adminToken);
    });
  });

  describe('PUT /api/auth/change-password', () => {
    test('should change password successfully', async () => {
      const newPassword = 'NewTestPassword@123';
      
      const response = await request(app)
        .put('/api/auth/change-password')
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          currentPassword: testUser.password,
          newPassword: newPassword
        });

      expect(response.status).toBe(200);
      expect(response.body.message).toContain('successfully');

      // Verify new password works
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: newPassword
        });

      expect(loginResponse.status).toBe(200);

      // Update test data for cleanup
      testUser.password = newPassword;
    });

    test('should fail with wrong current password', async () => {
      const response = await request(app)
        .put('/api/auth/change-password')
        .set('Authorization', `Bearer ${testUserToken}`)
        .send({
          currentPassword: 'WrongPassword@123',
          newPassword: 'AnotherPassword@123'
        });

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/auth/logout', () => {
    test('should logout successfully', async () => {
      // Get fresh token
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send(adminUser);

      const token = loginResponse.body.data.token;

      const response = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(200);
      expect(response.body.message).toContain('successfully');
    });
  });
});

describe('User Management API', () => {
  describe('GET /api/users', () => {
    test('should get all users (admin)', async () => {
      const response = await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.users).toBeInstanceOf(Array);
      expect(response.body.data.pagination).toHaveProperty('page');
      expect(response.body.data.pagination).toHaveProperty('limit');
      expect(response.body.data.pagination).toHaveProperty('total');
    });

    test('should get users with pagination', async () => {
      const response = await request(app)
        .get('/api/users?page=1&limit=10')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.pagination.page).toBe(1);
      expect(response.body.data.pagination.limit).toBe(10);
    });

    test('should fail without authorization', async () => {
      const response = await request(app)
        .get('/api/users');

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/users/:id', () => {
    test('should get user by ID', async () => {
      const response = await request(app)
        .get(`/api/users/${testUserId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.user.id).toBe(testUserId);
      expect(response.body.data.user.email).toBe(testUser.email);
    });

    test('should fail with invalid user ID', async () => {
      const response = await request(app)
        .get('/api/users/invalid-id')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(500);
    });
  });

  describe('POST /api/users', () => {
    test('should create new user (admin only)', async () => {
      const newUser = {
        email: `manager-${Date.now()}@example.com`,
        password: 'ManagerPassword@123',
        name: 'Test Manager',
        role: 'manager',
        pin: '5678'
      };

      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(newUser);

      expect(response.status).toBe(201);
      expect(response.body.data.user.email).toBe(newUser.email);
      expect(response.body.data.user.role).toBe('manager');
    });

    test('should fail creating user with duplicate email', async () => {
      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          email: testUser.email,
          password: 'AnotherPassword@123',
          name: 'Duplicate Test'
        });

      expect(response.status).toBe(409);
    });
  });

  describe('PUT /api/users/:id', () => {
    test('should update user profile', async () => {
      const response = await request(app)
        .put(`/api/users/${testUserId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Updated Test User',
          phone: '+60198765432'
        });

      expect(response.status).toBe(200);
      expect(response.body.data.user.name).toBe('Updated Test User');
    });
  });

  describe('PATCH /api/users/:id/status', () => {
    test('should toggle user status', async () => {
      // Deactivate
      const deactivateResponse = await request(app)
        .patch(`/api/users/${testUserId}/status`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ isActive: false });

      expect(deactivateResponse.status).toBe(200);

      // Verify user can't login when inactive
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        });

      expect(loginResponse.status).toBe(403);

      // Reactivate
      const activateResponse = await request(app)
        .patch(`/api/users/${testUserId}/status`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ isActive: true });

      expect(activateResponse.status).toBe(200);
    });
  });

  describe('POST /api/users/:id/reset-password', () => {
    test('should reset user password (admin only)', async () => {
      const newPassword = 'ResetPassword@123';

      const response = await request(app)
        .post(`/api/users/${testUserId}/reset-password`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ newPassword });

      expect(response.status).toBe(200);

      // Verify new password works
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: newPassword
        });

      expect(loginResponse.status).toBe(200);
    });
  });
});

describe('RBAC & Permissions', () => {
  let cashierToken = null;
  let cashierUserId = null;

  beforeAll(async () => {
    // Create cashier user
    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send({
        email: `cashier-${Date.now()}@example.com`,
        password: 'CashierPassword@123',
        name: 'Test Cashier',
        role: 'cashier'
      });

    if (registerResponse.status === 201) {
      cashierToken = registerResponse.body.data.token;
      cashierUserId = registerResponse.body.data.user.id;
    }
  });

  afterAll(async () => {
    // Cleanup cashier user
    try {
      if (cashierUserId) {
        await database.deleteDocument(dbId, 'users', cashierUserId);
      }
    } catch (error) {
      console.error('Cashier cleanup error:', error.message);
    }
  });

  test('admin should have full access', async () => {
    const response = await request(app)
      .get('/api/users')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(response.status).toBe(200);
  });

  test('cashier should not create users', async () => {
    const response = await request(app)
      .post('/api/users')
      .set('Authorization', `Bearer ${cashierToken}`)
      .send({
        email: 'test@example.com',
        password: 'Password@123',
        name: 'Test User'
      });

    expect(response.status).toBe(403);
  });

  test('cashier should not list all users', async () => {
    const response = await request(app)
      .get('/api/users')
      .set('Authorization', `Bearer ${cashierToken}`);

    expect(response.status).toBe(403);
  });

  test('cashier should get own profile', async () => {
    const response = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${cashierToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.user.role).toBe('cashier');
  });
});

describe('Error Handling', () => {
  test('should handle missing required fields', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({ email: 'test@example.com' });

    expect(response.status).toBe(400);
    expect(response.body.status).toBe('error');
  });

  test('should handle invalid JSON', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .set('Content-Type', 'application/json')
      .send('invalid json{');

    expect(response.status).toBeGreaterThanOrEqual(400);
  });

  test('should handle non-existent endpoints', async () => {
    const response = await request(app)
      .get('/api/nonexistent');

    expect(response.status).toBe(404);
  });
});

describe('Database Integrity', () => {
  test('password should be hashed', async () => {
    const user = await database.getDocument(dbId, 'users', testUserId);
    
    expect(user.password_hash).toBeDefined();
    expect(user.password_hash).not.toBe(testUser.password);
    expect(user.password_hash).toMatch(/^\$2b\$/); // bcrypt format
  });

  test('pin should be hashed', async () => {
    const user = await database.getDocument(dbId, 'users', testUserId);
    
    expect(user.pin).toBeDefined();
    expect(user.pin).not.toBe(testUser.pin);
  });

  test('user should have timestamps', async () => {
    const user = await database.getDocument(dbId, 'users', testUserId);
    
    expect(user.created_at).toBeDefined();
    expect(user.updated_at).toBeDefined();
    expect(typeof user.created_at).toBe('number');
  });
});
