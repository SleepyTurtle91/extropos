/**
 * FlutterPOS Backend API - Express Application
 * Exports the configured Express app for testing and external use
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const winston = require('winston');
const ipRangeCheck = require('ip-range-check');
const jwt = require('jsonwebtoken');
const { Client, Databases } = require('node-appwrite');
require('dotenv').config();

const app = express();

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'super-admin-api' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple(),
  }));
}

// Initialize Appwrite client
let appwriteClient = null;
let appwriteDatabases = null;

try {
  appwriteClient = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://appwrite.extropos.org/v1')
    .setProject(process.env.APPWRITE_PROJECT_ID || '6940a64500383754a37f')
    .setKey(process.env.APPWRITE_API_KEY);

  appwriteDatabases = new Databases(appwriteClient);
  logger.info('Appwrite client initialized successfully');
} catch (error) {
  logger.error('Failed to initialize Appwrite client', { error: error.message });
}

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'https://backend.extropos.org'],
  credentials: true,
}));

// CIDR-based IP restrictions for Super Admin endpoints
const allowedCIDRs = process.env.ALLOWED_CIDRS?.split(',') || ['192.168.0.0/24', '10.0.0.0/8', '172.16.0.0/12'];
const cidrMiddleware = (req, res, next) => {
  const clientIP = req.ip || req.connection.remoteAddress || req.socket.remoteAddress;
  
  // Skip CIDR check for health endpoint and testing
  if (req.path === '/health' || process.env.NODE_ENV === 'test') {
    return next();
  }
  
  // Check if client IP is in allowed CIDR ranges
  const isAllowed = allowedCIDRs.some(cidr => {
    try {
      return ipRangeCheck(clientIP, cidr);
    } catch (error) {
      logger.warn(`Invalid CIDR range: ${cidr}`, { error: error.message });
      return false;
    }
  });

  if (!isAllowed) {
    logger.warn(`Unauthorized access attempt from ${clientIP}`);
    return res.status(403).json({ error: 'Access denied' });
  }

  next();
};

app.use(cidrMiddleware);

// Rate limiting
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
});

app.use(limiter);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent'),
  });
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    appwrite: appwriteClient ? 'connected' : 'disconnected',
  });
});

// Routes
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/users.routes');

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
    path: req.path,
  });

  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
  });
});

module.exports = app;
