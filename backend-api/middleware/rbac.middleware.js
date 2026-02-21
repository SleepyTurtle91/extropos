/**
 * RBAC (Role-Based Access Control) Middleware
 * Handles permission-based access control
 */

const { Client, Databases, Query } = require('node-appwrite');

const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const database = new Databases(client);
const dbId = 'pos_db';

/**
 * Role hierarchy - higher roles inherit lower permissions
 */
const roleHierarchy = {
  admin: ['admin', 'manager', 'supervisor', 'cashier', 'viewer'],
  manager: ['manager', 'supervisor', 'cashier', 'viewer'],
  supervisor: ['supervisor', 'cashier', 'viewer'],
  cashier: ['cashier', 'viewer'],
  viewer: ['viewer']
};

/**
 * Default permissions by role
 */
const rolePermissions = {
  admin: [
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
  ],
  manager: [
    'users:read',
    'users:update',
    'products:create',
    'products:read',
    'products:update',
    'categories:read',
    'categories:create',
    'sales:create',
    'sales:read',
    'sales:refund',
    'reports:read',
    'reports:export',
    'inventory:manage'
  ],
  supervisor: [
    'users:read',
    'products:read',
    'categories:read',
    'sales:create',
    'sales:read',
    'sales:refund',
    'reports:read'
  ],
  cashier: [
    'products:read',
    'categories:read',
    'sales:create',
    'sales:read'
  ],
  viewer: [
    'products:read',
    'categories:read',
    'sales:read'
  ]
};

/**
 * Check if user has required permission
 * @param {String} requiredPermission - Permission to check (e.g., 'sales:create')
 */
exports.checkPermission = (requiredPermission) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          status: 'error',
          message: 'User not authenticated'
        });
      }

      const userPermissions = req.user.permissions || [];
      const defaultPermissions = rolePermissions[req.user.role] || [];
      const allPermissions = [...new Set([...userPermissions, ...defaultPermissions])];

      if (!allPermissions.includes(requiredPermission)) {
        return res.status(403).json({
          status: 'error',
          message: 'Insufficient permissions',
          requiredPermission
        });
      }

      next();
    } catch (error) {
      console.error('Permission check error:', error);
      res.status(500).json({
        status: 'error',
        message: 'Failed to verify permissions',
        error: error.message
      });
    }
  };
};

/**
 * Check if user has any of the required permissions
 * @param {Array} requiredPermissions - Array of permissions (user needs at least one)
 */
exports.checkAnyPermission = (requiredPermissions) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          status: 'error',
          message: 'User not authenticated'
        });
      }

      const userPermissions = req.user.permissions || [];
      const defaultPermissions = rolePermissions[req.user.role] || [];
      const allPermissions = [...new Set([...userPermissions, ...defaultPermissions])];

      const hasPermission = requiredPermissions.some(permission =>
        allPermissions.includes(permission)
      );

      if (!hasPermission) {
        return res.status(403).json({
          status: 'error',
          message: 'Insufficient permissions',
          requiredPermissions
        });
      }

      next();
    } catch (error) {
      console.error('Permission check error:', error);
      res.status(500).json({
        status: 'error',
        message: 'Failed to verify permissions',
        error: error.message
      });
    }
  };
};

/**
 * Check if user has all required permissions
 * @param {Array} requiredPermissions - Array of permissions (user needs all)
 */
exports.checkAllPermissions = (requiredPermissions) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          status: 'error',
          message: 'User not authenticated'
        });
      }

      const userPermissions = req.user.permissions || [];
      const defaultPermissions = rolePermissions[req.user.role] || [];
      const allPermissions = [...new Set([...userPermissions, ...defaultPermissions])];

      const hasAllPermissions = requiredPermissions.every(permission =>
        allPermissions.includes(permission)
      );

      if (!hasAllPermissions) {
        return res.status(403).json({
          status: 'error',
          message: 'Insufficient permissions - all required permissions needed',
          requiredPermissions
        });
      }

      next();
    } catch (error) {
      console.error('Permission check error:', error);
      res.status(500).json({
        status: 'error',
        message: 'Failed to verify permissions',
        error: error.message
      });
    }
  };
};

/**
 * Check if user can access resource by ownership
 * Only allows access if user is owner or admin
 * @param {String} resourceType - Type of resource (e.g., 'transaction', 'user')
 */
exports.checkOwnershipOrAdmin = (resourceType) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          status: 'error',
          message: 'User not authenticated'
        });
      }

      if (req.user.role === 'admin') {
        return next();
      }

      const resourceId = req.params.id;
      if (!resourceId) {
        return res.status(400).json({
          status: 'error',
          message: 'Resource ID is required'
        });
      }

      // Get user's own resources
      let userResourceField = 'user_id';
      if (resourceType === 'transaction') {
        userResourceField = 'user_id';
      } else if (resourceType === 'user') {
        userResourceField = '$id';
      }

      const resource = await database.getDocument(dbId, resourceType, resourceId);

      if (resource[userResourceField] !== req.user.userId) {
        return res.status(403).json({
          status: 'error',
          message: 'Access denied - you can only access your own resources'
        });
      }

      req.resource = resource;
      next();
    } catch (error) {
      console.error('Ownership check error:', error);
      res.status(500).json({
        status: 'error',
        message: 'Failed to verify resource ownership',
        error: error.message
      });
    }
  };
};

/**
 * Check if target user role is equal or lower than requester role
 * Prevents lower-role users from modifying higher-role users
 */
exports.checkRoleHierarchy = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        status: 'error',
        message: 'User not authenticated'
      });
    }

    const targetUserId = req.params.id;
    if (!targetUserId) {
      return res.status(400).json({
        status: 'error',
        message: 'User ID is required'
      });
    }

    const targetUser = await database.getDocument(dbId, 'users', targetUserId);

    const requesterHierarchy = roleHierarchy[req.user.role] || [];
    const targetUserRole = targetUser.role;

    if (!requesterHierarchy.includes(targetUserRole)) {
      return res.status(403).json({
        status: 'error',
        message: 'Access denied - cannot modify users with higher or equal role'
      });
    }

    req.targetUser = targetUser;
    next();
  } catch (error) {
    console.error('Role hierarchy check error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to verify role hierarchy',
      error: error.message
    });
  }
};

/**
 * Audit logging middleware - log all resource modifications
 */
exports.auditLog = async (req, res, next) => {
  try {
    if (!req.user) {
      return next();
    }

    const auditData = {
      user_id: req.user.userId,
      user_email: req.user.email,
      action: `${req.method} ${req.path}`,
      ip_address: req.ip,
      user_agent: req.get('user-agent'),
      timestamp: Date.now(),
      status_code: res.statusCode
    };

    // Don't audit GET requests (only mutations)
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
      auditData.request_body = JSON.stringify(req.body);
      console.log('[AUDIT]', JSON.stringify(auditData));
    }

    next();
  } catch (error) {
    console.error('Audit log error:', error);
    next();
  }
};

/**
 * Get user's effective permissions
 * Combines role-based permissions with custom user permissions
 */
exports.getUserPermissions = (user) => {
  const defaultPermissions = rolePermissions[user.role] || [];
  const customPermissions = user.permissions || [];
  return [...new Set([...defaultPermissions, ...customPermissions])];
};

/**
 * Get role hierarchy information
 */
exports.getRoleHierarchy = () => {
  return roleHierarchy;
};

/**
 * Get default permissions for role
 */
exports.getRolePermissions = (role) => {
  return rolePermissions[role] || [];
};
