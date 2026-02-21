# 🚀 FlutterPOS Backend Deployment Guide

**Date**: January 28, 2026  
**Backend Type**: Node.js API Server  
**Integration**: Appwrite Cloud (Self-hosted)  
**Status**: Ready for Deployment

---

## 📦 What You Have

### Backend API Server

- **Type**: Express.js (Node.js)

- **Location**: `e:\flutterpos\backend-api\`

- **Port**: 3001 (default, configurable)

- **Features**:

  - Super admin operations API

  - Appwrite integration (databases, auth)

  - Rate limiting & security (helmet, CORS)

  - JWT authentication

  - IP whitelist support

  - Winston logging

### Infrastructure (Already Deployed)

- ✅ **Appwrite 1.5.7**: Running with MariaDB, Redis, Traefik

- ✅ **Storage**: 1.5 TB at E:\appwrite-cloud\

- ✅ **Monitoring**: Automated backups, health checks, alerts

- ✅ **Reverse Proxy**: Traefik with TLS support

---

## 🎯 Three Deployment Options

### Option 1: Local Development (Windows Desktop)

**Best for**: Testing and development

```powershell
cd e:\flutterpos\backend-api
npm install
npm start

# Runs at http://localhost:3001

```

### Option 2: Docker Container

**Best for**: Production on same machine

```powershell
cd e:\flutterpos\backend-api
docker build -t flutterpos-backend:1.0.0 .
docker run -d --name backend-api \
  -p 3001:3001 \
  --env-file .env \
  --network appwrite_default \
  flutterpos-backend:1.0.0

```

### Option 3: Docker Compose (Recommended)

**Best for**: Full stack management

- Integrates with Appwrite stack

- Unified configuration

- Easy scaling and updates

---

## 🔧 Quick Start - Option 1 (Local Dev)

### Step 1: Install Dependencies

```powershell
cd e:\flutterpos\backend-api
npm install

```

Expected output:

```
up to date, audited 8 packages in 2s

```

### Step 2: Configure Environment

```powershell

# Copy example to actual config

Copy-Item .env.example .env


# Edit .env (see section below for values)

notepad .env

```

### Step 3: Start Server

```powershell

# Start with npm

npm start


# Or run with nodemon (auto-reload on changes)

npm install --save-dev nodemon
npx nodemon server.js

```

Expected output:

```
ℹ️ Super Admin API listening on port 3001
✓ Connected to Appwrite
✓ Ready to accept requests

```

### Step 4: Test API

```powershell

# Health check

curl http://localhost:3001/health


# Should return:

# {"status":"ok","appwrite":"connected","timestamp":"2026-01-28T..."}

```

---

## ⚙️ Environment Configuration

### Create `.env` file in `backend-api/` directory

```env

# Server Configuration

NODE_ENV=production
PORT=3001


# Appwrite Configuration (pointing to your deployed instance)

APPWRITE_ENDPOINT=http://appwrite-api:80/v1

# Or for external access: https://api.yourdomain.com/v1

APPWRITE_PROJECT_ID=6940a64500383754a37f
APPWRITE_API_KEY=your_api_key_here


# JWT Secret (for token generation)

JWT_SECRET=your_super_secret_jwt_key_change_this


# Super Admin Password (for initial setup)

SUPER_ADMIN_PASSWORD=admin123


# Allowed Origins (CORS)

ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,https://yourdomain.com


# Rate Limiting

RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100


# IP Whitelist (optional, comma-separated)

IP_WHITELIST=127.0.0.1,192.168.1.0/24


# Logging

LOG_LEVEL=info
LOG_FILE=logs/backend.log

```

### Get Appwrite API Key

```powershell

# From your Appwrite instance:

# 1. Open http://localhost:8080/console

# 2. Settings → API Keys

# 3. Create new key with these scopes:

#    - databases.read, databases.write

#    - collections.read, collections.write

#    - documents.read, documents.write

#    - users.read, users.write

# 4. Copy the key to .env as APPWRITE_API_KEY

```

---

## 🐳 Production Deployment Options

### Option A: Docker Standalone

#### Step 1: Create Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3001

CMD ["npm", "start"]

```

#### Step 2: Build Image

```powershell
cd e:\flutterpos\backend-api
docker build -t flutterpos-backend:1.0.0 .

```

#### Step 3: Run Container

```powershell
docker run -d \
  --name backend-api \
  -p 3001:3001 \
  --env-file .env \
  --network appwrite_default \
  -v E:\appwrite-cloud\logs:/app/logs \
  flutterpos-backend:1.0.0

```

### Option B: Docker Compose Integration

#### Step 1: Create compose file

**File**: `e:\flutterpos\docker\backend-compose.yml`

```yaml
version: '3.8'

services:
  backend-api:
    image: node:18-alpine
    working_dir: /app
    volumes:

      - ../backend-api:/app

      - E:\appwrite-cloud\logs:/app/logs
    ports:

      - "3001:3001"
    environment:

      - NODE_ENV=production

      - APPWRITE_ENDPOINT=http://appwrite:80/v1

      - APPWRITE_PROJECT_ID=${APPWRITE_PROJECT_ID}

      - APPWRITE_API_KEY=${APPWRITE_API_KEY}

      - JWT_SECRET=${JWT_SECRET}

      - PORT=3001
    command: sh -c "npm install && npm start"
    networks:

      - appwrite
    depends_on:

      - appwrite
    restart: unless-stopped

networks:
  appwrite:
    name: appwrite_default

```

#### Step 2: Deploy with stack

```powershell
cd e:\flutterpos\docker


# Update .env with backend variables

# APPWRITE_PROJECT_ID=6940a64500383754a37f

# APPWRITE_API_KEY=your_key



# Start backend with Appwrite

docker compose -f appwrite-compose-cloud-windows.yml -f backend-compose.yml up -d


# Verify

docker compose ps | findstr backend

```

---

## 🧪 Testing Endpoints

### Health Check

```powershell
curl http://localhost:3001/health

```

### Appwrite Connection

```powershell
curl http://localhost:3001/api/status

```

### Database Operations

```powershell

# Create database

curl -X POST http://localhost:3001/api/databases \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"name":"test_db"}'


# List databases

curl http://localhost:3001/api/databases \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

```

---

## 📊 Project Structure

```
backend-api/
├── server.js                 # Main server file

├── package.json             # Dependencies

├── .env                     # Configuration (DO NOT COMMIT)

├── .env.example             # Template

├── Dockerfile               # Container definition

├── README.md                # Documentation

├── logs/                    # Log files

│   ├── error.log
│   └── combined.log
└── routes/                  # API endpoints (if organized)

```

---

## 🔐 Security Checklist

- [ ] Changed `JWT_SECRET` to strong random value

- [ ] Changed `SUPER_ADMIN_PASSWORD` to strong random value

- [ ] Set `APPWRITE_API_KEY` from Appwrite instance

- [ ] Configured `ALLOWED_ORIGINS` for your domain

- [ ] Set `NODE_ENV=production` for production

- [ ] Configured `IP_WHITELIST` if needed

- [ ] Enabled HTTPS/TLS (via Traefik)

- [ ] Reviewed rate limiting thresholds

- [ ] Validated input sanitization

- [ ] Tested authentication flows

---

## 🚀 Deployment Workflow

### Development (Local Machine)

```powershell
cd e:\flutterpos\backend-api
npm install
npm start

# Test at http://localhost:3001

```

### Staging (Docker)

```powershell
docker build -t flutterpos-backend:1.0.0 .
docker run -d --name backend-api -p 3001:3001 --env-file .env flutterpos-backend:1.0.0

# Verify: docker logs backend-api

```

### Production (Docker Compose + Appwrite)

```powershell
cd e:\flutterpos\docker
docker compose -f appwrite-compose-cloud-windows.yml -f backend-compose.yml up -d

# Monitor: docker compose logs -f backend-api

```

---

## 📈 Monitoring & Logs

### View Logs

```powershell

# Real-time logs

docker compose logs -f backend-api


# Last 50 lines

docker compose logs backend-api | tail -50


# Error logs

Get-Content E:\appwrite-cloud\logs\error.log -Tail 20

```

### Health Monitoring

```powershell

# Test API health

curl http://localhost:3001/health


# Check Appwrite connection

curl http://localhost:3001/api/status


# View running processes

docker compose ps

```

---

## 🔄 Update Workflow

### Pull Latest Code

```powershell
git pull origin main

```

### Rebuild Image

```powershell
cd e:\flutterpos\backend-api
docker build -t flutterpos-backend:1.0.1 .

```

### Deploy New Version

```powershell
cd e:\flutterpos\docker
docker compose down backend-api
docker compose -f appwrite-compose-cloud-windows.yml -f backend-compose.yml up -d backend-api

```

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Port 3001 already in use | Kill process: `Get-NetTCPConnection -LocalPort 3001 \| Stop-Process` |
| Cannot connect to Appwrite | Verify Appwrite running: `docker compose ps \| findstr appwrite` |
| Environment variables not loaded | Check .env exists: `Test-Path backend-api\.env` |
| Module not found errors | Run: `npm install` in backend-api directory |
| High memory usage | Check logs: `docker compose logs backend-api` |

---

## 📝 API Documentation

### Authentication

```
POST /auth/login

- Body: { email: string, password: string }

- Returns: { token: JWT, user: {...} }

POST /auth/refresh

- Headers: Authorization: Bearer <token>

- Returns: { token: JWT }

```

### Database Operations

```
GET /api/databases

- List all databases

POST /api/databases

- Create new database

GET /api/databases/:id

- Get database details

PUT /api/databases/:id

- Update database

DELETE /api/databases/:id

- Delete database

```

### Collections

```
GET /api/collections/:db_id

- List collections in database

POST /api/collections/:db_id

- Create collection

PUT /api/collections/:db_id/:col_id

- Update collection

DELETE /api/collections/:db_id/:col_id

- Delete collection

```

---

## ✅ Deployment Checklist

### Pre-Deployment

- [ ] All tests pass locally

- [ ] Environment variables configured

- [ ] Security checklist reviewed

- [ ] Database backups current

- [ ] Appwrite instance healthy

### Deployment

- [ ] Build Docker image

- [ ] Deploy to container

- [ ] Verify health endpoints

- [ ] Test API operations

- [ ] Check logs for errors

### Post-Deployment

- [ ] Monitor logs for 1 hour

- [ ] Test critical APIs

- [ ] Verify Appwrite integration

- [ ] Confirm backups running

- [ ] Document any changes

---

## 🎯 Next Steps

### Immediate (Today)

1. [ ] Review backend code: `cat server.js | head -50`
2. [ ] Install dependencies: `npm install`
3. [ ] Configure .env file
4. [ ] Test locally: `npm start`

### Short-term (This Week)

1. [ ] Build Docker image
2. [ ] Test Docker container
3. [ ] Deploy to production
4. [ ] Monitor logs and metrics

### Medium-term (This Month)

1. [ ] Add comprehensive API tests
2. [ ] Setup monitoring dashboard
3. [ ] Document all endpoints
4. [ ] Plan scaling strategy

---

## 📚 Supporting Docs

- **[Appwrite Documentation](https://appwrite.io/docs)** - Official Appwrite API reference

- **[Express.js Guide](https://expressjs.com/)** - HTTP server framework

- **[Node.js Best Practices](https://nodejs.org/en/docs/)** - Production best practices

- **APPWRITE_CLOUD_OPERATIONS.md** - Your Appwrite operations guide

---

**Ready to deploy! Choose your deployment option above and follow the steps.** 🚀
