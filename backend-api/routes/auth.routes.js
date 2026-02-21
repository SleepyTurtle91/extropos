/**
 * User Authentication Routes
 * Handles login, logout, session management
 */

const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Public routes (no authentication required)
router.post('/login', authController.login);
router.post('/register', authController.register);

// Protected routes (authentication required)
router.post('/logout', authMiddleware.authenticate, authController.logout);
router.get('/me', authMiddleware.authenticate, authController.getCurrentUser);
router.post('/refresh', authMiddleware.authenticate, authController.refreshToken);
router.put('/change-password', authMiddleware.authenticate, authController.changePassword);

module.exports = router;
