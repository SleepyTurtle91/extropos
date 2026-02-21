/**
 * Create Default Admin User for FlutterPOS
 * 
 * This script creates the default admin user account in Appwrite.
 * Run once after database schema is created.
 * 
 * Usage:
 *   node setup-default-admin.js
 *   NODE_ENV=production node setup-default-admin.js
 */

const bcrypt = require('bcrypt');
const { Client, Databases, Query } = require('node-appwrite');
require('dotenv').config();

const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const database = new Databases(client);
const dbId = 'pos_db';

const DEFAULT_ADMIN = {
  email: 'admin@extropos.com',
  password: 'Admin@123',
  pin: '0000',
  name: 'System Administrator',
  phone: '+60123456789'
};

/**
 * Create default admin user
 */
async function createDefaultAdmin() {
  try {
    console.log('🚀 Starting default admin user creation...\n');

    // Check if admin already exists
    console.log('📋 Checking if admin user already exists...');
    const existing = await database.listDocuments(dbId, 'users', [
      Query.equal('email', DEFAULT_ADMIN.email)
    ]);

    if (existing.documents.length > 0) {
      console.log('✅ Admin user already exists - skipping creation\n');
      console.log('Admin Details:');
      console.log(`  Email: ${existing.documents[0].email}`);
      console.log(`  Name: ${existing.documents[0].name}`);
      console.log(`  Role: ${existing.documents[0].role}`);
      console.log(`  Status: ${existing.documents[0].is_active ? 'Active' : 'Inactive'}`);
      return;
    }

    console.log('⏳ Admin user not found - creating new admin account...\n');

    // Hash password
    console.log('🔐 Hashing password (12 rounds)...');
    const passwordHash = await bcrypt.hash(DEFAULT_ADMIN.password, 12);

    // Hash PIN
    console.log('🔐 Hashing PIN (12 rounds)...');
    const pinHash = await bcrypt.hash(DEFAULT_ADMIN.pin, 12);

    // Admin permissions
    const adminPermissions = [
      'users:create',
      'users:read',
      'users:update',
      'users:delete',
      'products:create',
      'products:read',
      'products:update',
      'products:delete',
      'categories:create',
      'categories:read',
      'categories:update',
      'categories:delete',
      'sales:create',
      'sales:read',
      'sales:refund',
      'reports:read',
      'reports:export',
      'settings:manage',
      'inventory:manage'
    ];

    const nowMs = Date.now();

    // Create admin user
    console.log('👤 Creating admin user document in Appwrite...');
    const adminUser = await database.createDocument(dbId, 'users', 'unique()', {
      email: DEFAULT_ADMIN.email,
      name: DEFAULT_ADMIN.name,
      password_hash: passwordHash,
      pin: pinHash,
      role: 'admin',
      is_active: true,
      permissions: JSON.stringify(adminPermissions),
      phone: DEFAULT_ADMIN.phone,
      avatar_url: null,
      failed_login_attempts: 0,
      created_at: nowMs,
      updated_at: nowMs
    });

    console.log('\n✅ Admin user created successfully!\n');
    console.log('═══════════════════════════════════════════════════');
    console.log('ADMIN USER CREDENTIALS');
    console.log('═══════════════════════════════════════════════════');
    console.log(`User ID:  ${adminUser.$id}`);
    console.log(`Email:    ${adminUser.email}`);
    console.log(`Password: ${DEFAULT_ADMIN.password}`);
    console.log(`PIN:      ${DEFAULT_ADMIN.pin}`);
    console.log(`Role:     ${adminUser.role}`);
    console.log(`Status:   ${adminUser.is_active ? 'Active' : 'Inactive'}`);
    console.log(`Permissions: ${adminPermissions.length} permissions granted`);
    console.log('═══════════════════════════════════════════════════\n');

    console.log('⚠️  IMPORTANT SECURITY NOTES:');
    console.log('   • Save these credentials in a secure location');
    console.log('   • Change password on first login in production');
    console.log('   • Enable 2FA if available');
    console.log('   • Do not share admin credentials with staff\n');

    console.log('🎯 Next Steps:');
    console.log('   1. Test login via Postman: POST /auth/login');
    console.log('   2. Verify middleware is working: GET /auth/me');
    console.log('   3. Test RBAC: Try endpoints with different roles');
    console.log('   4. Deploy to production\n');

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error creating admin user:', error.message);

    if (error.code === 409) {
      console.error('   Conflict: User with this email already exists');
    } else if (error.code === 400) {
      console.error('   Bad request: Check database schema is created');
      console.error('   Run: setup-user-management-database.ps1 first');
    } else if (error.code === 401) {
      console.error('   Unauthorized: Check APPWRITE_API_KEY environment variable');
    }

    console.error('\nFull error details:', error);
    process.exit(1);
  }
}

// Main execution
createDefaultAdmin();
