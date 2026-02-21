/**
 * Users Management Controller
 * Handles CRUD operations for user management
 */

const bcrypt = require('bcrypt');
const { Client, Databases, Query } = require('node-appwrite');

const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const database = new Databases(client);
const dbId = 'pos_db';

/**
 * Get all users with pagination
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.getAllUsers = async (req, res) => {
  try {
    const { page = 1, limit = 20, role, isActive } = req.query;
    const offset = (page - 1) * limit;

    const queries = [];

    if (role) {
      queries.push(Query.equal('role', role));
    }

    if (isActive !== undefined) {
      queries.push(Query.equal('is_active', isActive === 'true'));
    }

    queries.push(Query.orderDesc('created_at'));
    queries.push(Query.limit(limit));
    queries.push(Query.offset(offset));

    const result = await database.listDocuments(dbId, 'users', queries);

    const users = result.documents.map(user => ({
      id: user.$id,
      email: user.email,
      name: user.name,
      role: user.role,
      isActive: user.is_active,
      phone: user.phone,
      lastLogin: user.last_login,
      createdAt: user.created_at
    }));

    res.status(200).json({
      status: 'success',
      data: {
        users,
        pagination: {
          page,
          limit,
          total: result.total
        }
      }
    });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch users',
      error: error.message
    });
  }
};

/**
 * Get user by ID
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await database.getDocument(dbId, 'users', id);

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
          permissions: user.permissions ? JSON.parse(user.permissions) : [],
          createdAt: user.created_at,
          updatedAt: user.updated_at
        }
      }
    });
  } catch (error) {
    console.error('Get user by ID error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch user',
      error: error.message
    });
  }
};

/**
 * Create new user
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.createUser = async (req, res) => {
  try {
    const { email, password, name, role, pin, phone, avatarUrl, permissions } = req.body;

    // Validate required fields
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
        message: 'User with this email already exists'
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
      permissions: permissions ? JSON.stringify(permissions) : JSON.stringify(['sales:create', 'products:read']),
      phone: phone || null,
      avatar_url: avatarUrl || null,
      failed_login_attempts: 0,
      created_at: nowMs,
      updated_at: nowMs
    });

    res.status(201).json({
      status: 'success',
      message: 'User created successfully',
      data: {
        user: {
          id: newUser.$id,
          email: newUser.email,
          name: newUser.name,
          role: newUser.role,
          isActive: newUser.is_active
        }
      }
    });
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to create user',
      error: error.message
    });
  }
};

/**
 * Update user
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, role, phone, avatarUrl, permissions } = req.body;

    // Get existing user
    const user = await database.getDocument(dbId, 'users', id);

    const updateData = {
      updated_at: Date.now()
    };

    if (name !== undefined) updateData.name = name;
    if (role !== undefined) updateData.role = role;
    if (phone !== undefined) updateData.phone = phone;
    if (avatarUrl !== undefined) updateData.avatar_url = avatarUrl;
    if (permissions !== undefined) updateData.permissions = JSON.stringify(permissions);

    const updatedUser = await database.updateDocument(dbId, 'users', id, updateData);

    res.status(200).json({
      status: 'success',
      message: 'User updated successfully',
      data: {
        user: {
          id: updatedUser.$id,
          email: updatedUser.email,
          name: updatedUser.name,
          role: updatedUser.role,
          isActive: updatedUser.is_active
        }
      }
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update user',
      error: error.message
    });
  }
};

/**
 * Delete user
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    await database.deleteDocument(dbId, 'users', id);

    res.status(200).json({
      status: 'success',
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete user',
      error: error.message
    });
  }
};

/**
 * Toggle user active status
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    if (isActive === undefined) {
      return res.status(400).json({
        status: 'error',
        message: 'isActive field is required'
      });
    }

    const updatedUser = await database.updateDocument(dbId, 'users', id, {
      is_active: isActive,
      updated_at: Date.now()
    });

    res.status(200).json({
      status: 'success',
      message: `User ${isActive ? 'activated' : 'deactivated'} successfully`,
      data: {
        user: {
          id: updatedUser.$id,
          email: updatedUser.email,
          name: updatedUser.name,
          isActive: updatedUser.is_active
        }
      }
    });
  } catch (error) {
    console.error('Toggle user status error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to toggle user status',
      error: error.message
    });
  }
};

/**
 * Reset user password (admin only)
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 */
exports.resetPassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { newPassword } = req.body;

    if (!newPassword) {
      return res.status(400).json({
        status: 'error',
        message: 'newPassword is required'
      });
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(newPassword, 12);

    await database.updateDocument(dbId, 'users', id, {
      password_hash: passwordHash,
      failed_login_attempts: 0,
      locked_until: null,
      updated_at: Date.now()
    });

    res.status(200).json({
      status: 'success',
      message: 'Password reset successfully'
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to reset password',
      error: error.message
    });
  }
};
