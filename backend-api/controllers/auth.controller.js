/**
 * Authentication Controller
 * Handles user login, logout, and session management
 */

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { Client, Databases, Query } = require('node-appwrite');

const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const database = new Databases(client);
const dbId = 'pos_db';

/**
 * Login user with email and password
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.login = async (req, res) => {
  try {
    const { email, password, deviceInfo } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        status: 'error',
        message: 'Email and password are required'
      });
    }

    // Find user by email
    const users = await database.listDocuments(dbId, 'users', [
      Query.equal('email', email)
    ]);

    if (users.documents.length === 0) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid credentials'
      });
    }

    const user = users.documents[0];

    // Check if user is active
    if (!user.is_active) {
      return res.status(403).json({
        status: 'error',
        message: 'Account is inactive'
      });
    }

    // Check if account is locked
    if (user.locked_until && user.locked_until > Date.now()) {
      return res.status(423).json({
        status: 'error',
        message: 'Account is locked. Try again later.'
      });
    }

    // Verify password
    const passwordMatch = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatch) {
      // Increment failed login attempts
      const newAttempts = (user.failed_login_attempts || 0) + 1;
      let lockUntil = null;

      if (newAttempts >= 5) {
        lockUntil = Date.now() + (15 * 60 * 1000); // Lock for 15 minutes
      }

      await database.updateDocument(dbId, 'users', user.$id, {
        failed_login_attempts: newAttempts,
        locked_until: lockUntil
      });

      return res.status(401).json({
        status: 'error',
        message: 'Invalid credentials'
      });
    }

    // Reset failed login attempts
    const nowMs = Date.now();
    await database.updateDocument(dbId, 'users', user.$id, {
      failed_login_attempts: 0,
      locked_until: null,
      last_login: nowMs
    });

    // Generate JWT token
    const token = jwt.sign(
      {
        userId: user.$id,
        email: user.email,
        role: user.role,
        permissions: user.permissions ? JSON.parse(user.permissions) : []
      },
      process.env.JWT_SECRET || 'your-secret-key-change-in-production',
      { expiresIn: '24h' }
    );

    // Create session record
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    await database.createDocument(dbId, 'sessions', 'unique()', {
      user_id: user.$id,
      token_hash: tokenHash,
      device_info: deviceInfo || 'Unknown Device',
      ip_address: req.ip,
      user_agent: req.get('user-agent'),
      expires_at: Date.now() + (24 * 60 * 60 * 1000),
      created_at: nowMs,
      last_activity: nowMs
    });

    res.status(200).json({
      status: 'success',
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user.$id,
          email: user.email,
          name: user.name,
          role: user.role,
          permissions: user.permissions ? JSON.parse(user.permissions) : []
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Login failed',
      error: error.message
    });
  }
};

/**
 * Register new user (admin only)
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.register = async (req, res) => {
  try {
    const { email, password, name, role, pin } = req.body;

    // Validate input
    if (!email || !password || !name) {
      return res.status(400).json({
        status: 'error',
        message: 'Email, password, and name are required'
      });
    }

    // Check if user already exists
    const existing = await database.listDocuments(dbId, 'users', [
      Query.equal('email', email)
    ]);

    if (existing.documents.length > 0) {
      return res.status(409).json({
        status: 'error',
        message: 'User already exists'
      });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Hash PIN if provided
    let pinHash = null;
    if (pin) {
      pinHash = await bcrypt.hash(pin, 12);
    }

    const nowMs = Date.now();

    // Create user
    const newUser = await database.createDocument(dbId, 'users', 'unique()', {
      email,
      name,
      password_hash: passwordHash,
      pin: pinHash,
      role: role || 'cashier',
      is_active: true,
      permissions: JSON.stringify(['sales:create', 'products:read']),
      failed_login_attempts: 0,
      created_at: nowMs,
      updated_at: nowMs
    });

    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      data: {
        user: {
          id: newUser.$id,
          email: newUser.email,
          name: newUser.name,
          role: newUser.role
        }
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Registration failed',
      error: error.message
    });
  }
};

/**
 * Logout user
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.logout = async (req, res) => {
  try {
    const { sessionId } = req.body;

    if (sessionId) {
      await database.deleteDocument(dbId, 'sessions', sessionId);
    }

    res.status(200).json({
      status: 'success',
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Logout failed',
      error: error.message
    });
  }
};

/**
 * Get current user
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.getCurrentUser = async (req, res) => {
  try {
    const userId = req.user.userId;

    const user = await database.getDocument(dbId, 'users', userId);

    res.status(200).json({
      status: 'success',
      data: {
        user: {
          id: user.$id,
          email: user.email,
          name: user.name,
          role: user.role,
          isActive: user.is_active,
          phone: user.phone,
          avatarUrl: user.avatar_url,
          lastLogin: user.last_login,
          permissions: user.permissions ? JSON.parse(user.permissions) : []
        }
      }
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch user',
      error: error.message
    });
  }
};

/**
 * Refresh JWT token
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.refreshToken = async (req, res) => {
  try {
    const userId = req.user.userId;

    const user = await database.getDocument(dbId, 'users', userId);

    // Generate new JWT token
    const token = jwt.sign(
      {
        userId: user.$id,
        email: user.email,
        role: user.role,
        permissions: user.permissions ? JSON.parse(user.permissions) : []
      },
      process.env.JWT_SECRET || 'your-secret-key-change-in-production',
      { expiresIn: '24h' }
    );

    res.status(200).json({
      status: 'success',
      message: 'Token refreshed',
      data: { token }
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to refresh token',
      error: error.message
    });
  }
};

/**
 * Change password
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.changePassword = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        status: 'error',
        message: 'Current password and new password are required'
      });
    }

    const user = await database.getDocument(dbId, 'users', userId);

    // Verify current password
    const passwordMatch = await bcrypt.compare(currentPassword, user.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({
        status: 'error',
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const newPasswordHash = await bcrypt.hash(newPassword, 12);

    // Update password
    await database.updateDocument(dbId, 'users', userId, {
      password_hash: newPasswordHash,
      updated_at: Date.now()
    });

    res.status(200).json({
      status: 'success',
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to change password',
      error: error.message
    });
  }
};
