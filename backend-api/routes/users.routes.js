/**
 * User Management Routes
 * Handles CRUD operations for users
 */

const express = require('express');
const router = express.Router();
const usersController = require('../controllers/users.controller');
const authMiddleware = require('../middleware/auth.middleware');
const rbacMiddleware = require('../middleware/rbac.middleware');

// All routes require authentication
router.use(authMiddleware.authenticate);

// List all users (requires 'users:read' permission)
router.get('/', rbacMiddleware.checkPermission('users:read'), usersController.getAllUsers);

// Get user by ID
router.get('/:id', rbacMiddleware.checkPermission('users:read'), usersController.getUserById);

// Create new user (requires 'users:write' permission)
router.post('/', rbacMiddleware.checkPermission('users:write'), usersController.createUser);

// Update user (requires 'users:write' permission)
router.put('/:id', rbacMiddleware.checkPermission('users:write'), usersController.updateUser);

// Delete user (requires 'users:delete' permission)
router.delete('/:id', rbacMiddleware.checkPermission('users:delete'), usersController.deleteUser);

// Activate/deactivate user
router.patch('/:id/status', rbacMiddleware.checkPermission('users:write'), usersController.toggleUserStatus);

// Reset user password (admin only)
router.post('/:id/reset-password', rbacMiddleware.checkPermission('users:write'), usersController.resetPassword);

module.exports = router;
