# 🚀 FlutterPOS Backend API - Quick Deployment Guide

**Date**: January 28, 2026  
**Status**: Ready for Deployment  
**Infrastructure**: Appwrite Cloud + Docker  

---

## 📦 What You're Deploying

**Backend API Server** (Node.js + Express.js)

- Super admin operations

- Appwrite integration

- Database management

- REST API endpoints

- Production-ready security

**Integration Points**:

- ✅ Appwrite 1.5.7 (MariaDB, Redis)

- ✅ Docker network (appwrite_default)

- ✅ Centralized logging (E:\appwrite-cloud\logs\backend\)

- ✅ Automated backups & monitoring

---

## ⚡ Quick Start (5 Minutes)

### Step 1: Update Environment Configuration

```powershell
cd e:\flutterpos\docker


# Edit backend configuration

notepad .env.backend

```

**Required changes in .env.backend**:

```env

# Appwrite API Key (from http://localhost:8080/console → Settings → API Keys)

APPWRITE_API_KEY=your_appwrite_api_key_here


# JWT Secret (change to random value)

JWT_SECRET=your_super_secret_jwt_key_change_this_to_random_value


# Super Admin Password (change from default)

SUPER_ADMIN_PASSWORD=your_secure_password


# Super Admin API Key (change from default)

SUPER_ADMIN_API_KEY=your_super_secret_api_key_change_this

```

**Optional**: Update ALLOWED_ORIGINS for your domain.

### Step 2: Deploy Backend

```powershell
cd e:\flutterpos\docker


# Build and deploy (full stack)

.\deploy-backend.ps1 -Action deploy

```

**Expected output**:

```
[INFO] Building Docker image: flutterpos-backend-api:1.0.0
...
[SUCCESS] ✓ Image built successfully
[INFO] Starting backend-api container...
[SUCCESS] ✓ Backend deployed successfully
[INFO] Container name: flutterpos-backend-api
[INFO] API endpoint: http://localhost:3001
[INFO] Health check: http://localhost:3001/health

```

### Step 3: Verify Deployment

```powershell

# Check status

.\deploy-backend.ps1 -Action status


# Test API

.\deploy-backend.ps1 -Action test


# View logs

.\deploy-backend.ps1 -Action logs

```

---

## 📋 Detailed Setup

### 1. Get Appwrite API Key

**From your Appwrite console:**

1. Open `http://localhost:8080/console`
2. Navigate to **Settings → API Keys**
3. Click **Create API Key**
4. Name: "Backend API"
5. **Required Scopes**:

   - ✓ databases.read

   - ✓ databases.write

   - ✓ collections.read

   - ✓ collections.write

   - ✓ documents.read

   - ✓ documents.write

   - ✓ users.read

   - ✓ users.write

6. Copy the generated key to `.env.backend`:

   ```
   APPWRITE_API_KEY=your_copied_api_key_here
   ```

### 2. Update Security Credentials

**Generate secure random values:**

```powershell

# Generate JWT Secret (copy the output to .env.backend)

[System.Convert]::ToBase64String([System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(32))


# Generate Super Admin Password (use something strong)

# Example: MyS3cur3P@ssw0rd!



# Generate Super Admin API Key

[System.Convert]::ToBase64String([System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(32))

```

### 3. Update .env.backend

```powershell
notepad e:\flutterpos\docker\.env.backend

```

Update these values:

```env
APPWRITE_API_KEY=your_appwrite_api_key_here
JWT_SECRET=your_generated_jwt_secret
SUPER_ADMIN_PASSWORD=your_strong_password
SUPER_ADMIN_API_KEY=your_generated_api_key

```

### 4. Deploy

```powershell
cd e:\flutterpos\docker
.\deploy-backend.ps1 -Action deploy

```

---

## 🔍 Verification Checklist

### After Deployment

```powershell

# 1. Check container is running

docker ps | findstr backend-api

# Should show: flutterpos-backend-api ... Up



# 2. Test health endpoint

curl http://localhost:3001/health

# Should return: {"status":"ok",...}



# 3. Test Appwrite connection

curl http://localhost:3001/api/status

# Should return: {"appwrite":"connected",...}



# 4. View logs

docker compose logs backend-api

# Should show: "✓ Connected to Appwrite"

```

### Visual Verification

- [ ] Docker Desktop → Containers → backend-api showing "Running"

- [ ] Container status shows "healthy"

- [ ] Logs show "Connected to Appwrite"

- [ ] No error messages in logs

---

## 📊 Deployment Scripts

### Main Deployment Script

```powershell
cd e:\flutterpos\docker
.\deploy-backend.ps1 -Action [action]

```

**Actions**:

| Action | What It Does |
|--------|-------------|
| `build` | Build Docker image only |
| `deploy` | Build image and start container (default) |
| `start` | Start stopped container |
| `stop` | Stop running container |
| `logs` | View last 50 lines of logs |
| `status` | Check container health |
| `test` | Test API endpoints |
| `clean` | Remove container and image |

### Examples

```powershell

# Deploy (full setup)

.\deploy-backend.ps1 -Action deploy


# Check status

.\deploy-backend.ps1 -Action status


# View logs

.\deploy-backend.ps1 -Action logs


# Test API

.\deploy-backend.ps1 -Action test


# Stop backend

.\deploy-backend.ps1 -Action stop

```

---

## 🧪 Testing API Endpoints

### Basic Health Check

```powershell

# Test API is responding

curl http://localhost:3001/health


# Response should be:

# {"status":"ok","timestamp":"2026-01-28T...","uptime":123.45}

```

### Test Appwrite Connection

```powershell

# Check Appwrite integration

curl http://localhost:3001/api/status


# Response should show:

# {"appwrite":"connected","databases":5,"collections":20}

```

### List Databases

```powershell

# Get all databases from Appwrite

curl http://localhost:3001/api/databases


# Response should be an array of databases

```

---

## 📁 File Structure

```
docker/
├── appwrite-compose-cloud-windows.yml    # Appwrite stack

├── backend-api-compose.yml               # Backend service (NEW)

├── deploy-backend.ps1                    # Deployment script (NEW)

├── .env                                  # Appwrite config

├── .env.backend                          # Backend config (NEW)

└── [other files]

backend-api/
├── Dockerfile                            # Container definition

├── server.js                             # Express server

├── package.json                          # Dependencies

├── .env                                  # Runtime config

└── [routes, modules, etc]

```

---

## 🔗 API Endpoints

### Health & Status

```
GET /health
Response: {"status":"ok","uptime":123.45}

GET /api/status
Response: {"appwrite":"connected","timestamp":"2026-01-28T..."}

```

### Database Operations

```
GET /api/databases
List all databases

POST /api/databases
Create new database

GET /api/databases/:id
Get database details

PUT /api/databases/:id
Update database

DELETE /api/databases/:id
Delete database

```

---

## 🛠️ Troubleshooting

### Container Won't Start

```powershell

# Check logs

docker compose logs backend-api


# Common issues:

# - Port 3001 in use: docker ps | findstr :3001

# - Missing Appwrite: docker ps | findstr appwrite

# - Missing network: docker network ls | findstr appwrite_default

```

### Can't Connect to Appwrite

```powershell

# Verify Appwrite is running

docker compose ps | findstr appwrite


# Verify API key is correct

docker compose logs appwrite | findstr "initialized"


# Test Appwrite directly

curl http://localhost:8080/v1/health

```

### High Memory Usage

```powershell

# Check container stats

docker stats flutterpos-backend-api


# Restart container

.\deploy-backend.ps1 -Action stop
.\deploy-backend.ps1 -Action start

```

---

## 📊 Monitoring

### View Live Logs

```powershell

# Real-time logs

docker compose logs -f backend-api


# Last 50 lines

docker compose logs --tail=50 backend-api


# Search logs for errors

docker compose logs backend-api | findstr "ERROR"

```

### Check Resource Usage

```powershell

# Container statistics

docker stats flutterpos-backend-api


# Disk usage

docker system df

```

### View Running Services

```powershell

# All Appwrite + Backend services

docker compose ps


# Appwrite only

docker ps --filter "name=appwrite"


# Backend only

docker ps --filter "name=backend"

```

---

## 🔄 Updating Backend

### Update Code

```powershell

# Pull latest code

git pull origin main


# Rebuild image

.\deploy-backend.ps1 -Action build


# Restart container

.\deploy-backend.ps1 -Action stop
.\deploy-backend.ps1 -Action start

```

### Or in one command

```powershell
cd e:\flutterpos\docker
.\deploy-backend.ps1 -Action deploy

```

---

## 🔐 Security Notes

- [ ] Changed `APPWRITE_API_KEY` to your actual key

- [ ] Changed `JWT_SECRET` to secure random value

- [ ] Changed `SUPER_ADMIN_PASSWORD` to secure value

- [ ] Changed `SUPER_ADMIN_API_KEY` to secure random value

- [ ] Configured `ALLOWED_ORIGINS` for your domain

- [ ] `.env.backend` is NOT committed to git (.gitignore)

- [ ] Container runs as non-root user

- [ ] HTTPS via Traefik reverse proxy (if configured)

---

## 📚 Documentation

- **BACKEND_DEPLOYMENT_GUIDE.md** - Comprehensive deployment guide

- **backend-api/README.md** - Backend API documentation

- **APPWRITE_CLOUD_OPERATIONS.md** - Appwrite operations

- **docker/DEPLOYMENT_SUMMARY.md** - Full deployment summary

---

## ✅ Deployment Checklist

### Pre-Deployment

- [ ] Appwrite is running (9 services)

- [ ] Appwrite health check passes

- [ ] API key obtained from Appwrite console

- [ ] Security credentials generated

- [ ] .env.backend updated with all values

- [ ] .env.backend not committed to git

### Deployment

- [ ] Run `.\deploy-backend.ps1 -Action deploy`

- [ ] No errors in deployment output

- [ ] Container shows "Up" in docker ps

- [ ] Container is healthy (green checkmark)

### Post-Deployment

- [ ] Health endpoint responds: `http://localhost:3001/health`

- [ ] Appwrite connection works: `http://localhost:3001/api/status`

- [ ] Logs show "Connected to Appwrite"

- [ ] No errors in container logs

- [ ] Resource usage is reasonable (< 200MB RAM)

---

## 🎯 What's Next

### Immediate

1. [ ] Deploy backend: `.\deploy-backend.ps1 -Action deploy`
2. [ ] Verify with: `.\deploy-backend.ps1 -Action test`
3. [ ] Check logs: `.\deploy-backend.ps1 -Action logs`

### Short-term

1. [ ] Test API endpoints with curl/Postman
2. [ ] Set up monitoring alerts
3. [ ] Test backup includes backend logs
4. [ ] Document API key storage location

### Medium-term

1. [ ] Build frontend for backend management
2. [ ] Set up CI/CD pipeline
3. [ ] Configure production domain
4. [ ] Enable HTTPS/TLS (via Traefik)

---

## 🆘 Quick Help

```powershell

# Everything in 3 commands:

cd e:\flutterpos\docker
notepad .env.backend          # Update API key and secrets

.\deploy-backend.ps1          # Deploy (uses default "deploy" action)



# Then verify:

.\deploy-backend.ps1 -Action test

```

---

**Your Backend API is ready to deploy!** 🚀

Start with: `cd e:\flutterpos\docker && .\deploy-backend.ps1`
