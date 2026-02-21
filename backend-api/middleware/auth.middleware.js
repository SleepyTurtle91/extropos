/**
 * Authentication Middleware
 * Validates JWT tokens and extracts user information
 */

const jwt = require('jsonwebtoken');
const { Client, Databases, Query } = require('node-appwrite');

const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const database = new Databases(client);
const dbId = 'pos_db';

/**
 * Authenticate user by verifying JWT token
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {Function} next - Express next function
 */
exports.authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        status: 'error',
        message: 'No authorization token provided'
      });
    }

    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;

    if (!token) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid authorization header format'
      });
    }

    const secret = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

    const decoded = jwt.verify(token, secret);

    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role,
      permissions: decoded.permissions || []
    };

    next();
  } catch (error) {
    console.error('Authentication error:', error);

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        status: 'error',
        message: 'Token has expired'
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid token'
      });
    }

    res.status(401).json({
      status: 'error',
      message: 'Authentication failed',
      error: error.message
    });
  }
};

/**
 * Optional authentication - doesn't fail if no token provided
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {Function} next - Express next function
 */
exports.optionalAuth = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return next();
    }

    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;

    if (!token) {
      return next();
    }

    const secret = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
    const decoded = jwt.verify(token, secret);

    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role,
      permissions: decoded.permissions || []
    };

    next();
  } catch (error) {
    console.error('Optional authentication error:', error);
    next();
  }
};

/**
 * Verify user session is still active
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {Function} next - Express next function
 */
exports.verifySession = async (req, res, next) => {
  try {
    if (!req.user || !req.user.userId) {
      return res.status(401).json({
        status: 'error',
        message: 'User not authenticated'
      });
    }

    const sessions = await database.listDocuments(dbId, 'sessions', [
      Query.equal('user_id', req.user.userId)
    ]);

    if (sessions.documents.length === 0) {
      return res.status(401).json({
        status: 'error',
        message: 'Session not found - please log in again'
      });
    }

    const session = sessions.documents[0];
    const expiresAt = parseInt(session.expires_at);

    if (expiresAt < Date.now()) {
      return res.status(401).json({
        status: 'error',
        message: 'Session expired - please log in again'
      });
    }

    req.session = {
      id: session.$id,
      userId: session.user_id,
      deviceInfo: session.device_info,
      ipAddress: session.ip_address,
      userAgent: session.user_agent,
      expiresAt: session.expires_at,
      createdAt: session.created_at,
      lastActivity: session.last_activity
    };

    next();
  } catch (error) {
    console.error('Session verification error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to verify session',
      error: error.message
    });
  }
};

/**
 * Check if user is admin
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {Function} next - Express next function
 */
exports.isAdmin = (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        status: 'error',
        message: 'User not authenticated'
      });
    }

    if (req.user.role !== 'admin') {
      return res.status(403).json({
        status: 'error',
        message: 'Access denied - admin role required'
      });
    }

    next();
  } catch (error) {
    console.error('Admin check error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to verify admin status',
      error: error.message
    });
  }
};

/**
 * Check if user is manager or admin
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {Function} next - Express next function
 */
exports.isManagerOrAdmin = (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        status: 'error',
        message: 'User not authenticated'
      });
    }

    const allowedRoles = ['admin', 'manager'];
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        status: 'error',
        message: 'Access denied - manager or admin role required'
      });
    }

    next();
  } catch (error) {
    console.error('Manager/Admin check error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to verify manager/admin status',
      error: error.message
    });
  }
};

/**
 * Check if user is cashier or higher role
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {Function} next - Express next function
 */
exports.isCashierOrHigher = (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        status: 'error',
        message: 'User not authenticated'
      });
    }

    const allowedRoles = ['admin', 'manager', 'supervisor', 'cashier'];
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        status: 'error',
        message: 'Access denied - cashier or higher role required'
      });
    }

    next();
  } catch (error) {
    console.error('Cashier/Higher check error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to verify cashier/higher status',
      error: error.message
    });
  }
};

/**
 * Rate limiting middleware - track requests per user
 * @param {Number} maxRequests - Maximum requests allowed
 * @param {Number} windowMs - Time window in milliseconds
 */
exports.rateLimit = (maxRequests = 100, windowMs = 60000) => {
  const userRequests = new Map();

  return (req, res, next) => {
    try {
      const userId = req.user?.userId || req.ip;
      const now = Date.now();

      if (!userRequests.has(userId)) {
        userRequests.set(userId, []);
      }

      const requests = userRequests.get(userId);
      const recentRequests = requests.filter(timestamp => now - timestamp < windowMs);

      if (recentRequests.length >= maxRequests) {
        return res.status(429).json({
          status: 'error',
          message: 'Too many requests - please try again later'
        });
      }

      recentRequests.push(now);
      userRequests.set(userId, recentRequests);

      next();
    } catch (error) {
      console.error('Rate limiting error:', error);
      next();
    }
  };
};
