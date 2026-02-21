# FlutterPOS Backend API - Docker Deployment Guide

## Overview

This guide covers deploying the FlutterPOS Backend API to Docker for development, staging, and production environments.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Traefik    │  │   Backend    │  │   Appwrite   │      │
│  │    (LB)      │  │     API      │  │   1.5.7      │      │
│  │  Port 80/443 │  │  Port 3001   │  │  Port 80     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                           │                   │              │
│                           └───────┬───────────┘              │
│                                   │                          │
│  ┌──────────────┐  ┌──────────────┴────────────┐            │
│  │   MariaDB    │  │      Docker Network       │            │
│  │   10.11      │  │     (appwrite-net)        │            │
│  │  Port 3306   │  │                           │            │
│  └──────────────┘  └───────────────────────────┘            │
│         │                                                    │
│  ┌──────┴──────────┐                                         │
│  │ Redis 7.0       │                                         │
│  │ Port 6379       │                                         │
│  └─────────────────┘                                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘

```

## Prerequisites

### System Requirements

- **OS**: Windows 10+, macOS, or Linux

- **CPU**: 4 cores minimum (8+ recommended for production)

- **RAM**: 8GB minimum (16GB+ recommended)

- **Storage**: 20GB free space minimum

- **Docker**: 20.10+ installed

- **Docker Compose**: 2.0+ installed

- **Git**: For version control

### Verify Prerequisites

```bash

# Check Docker

docker --version

# Expected: Docker version 20.10+



# Check Docker Compose

docker-compose --version

# Expected: Docker Compose version 2.0+



# Check available disk space

df -h


# Check system resources

# Windows: Task Manager → Performance

# macOS: Activity Monitor

# Linux: free -h

```

## Deployment Environments

### Development

**Purpose**: Local development with full logging  
**Exposed Ports**: All (for debugging)  
**Environment**: `.env.development`  
**Database**: SQLite + Appwrite local  
**Secrets**: Default/example values  

### Staging

**Purpose**: Pre-production testing  
**Exposed Ports**: Limited (80, 443, 3001)  
**Environment**: `.env.staging`  
**Database**: MariaDB + Appwrite staging  
**Secrets**: Staging credentials  

### Production

**Purpose**: Live customer deployment  
**Exposed Ports**: 80, 443 only  
**Environment**: `.env.production`  
**Database**: Managed MariaDB + Appwrite cloud  
**Secrets**: Encrypted, rotated regularly  
**SSL**: Let's Encrypt/Custom certificate  
**Backup**: Daily automated backups  

## Quick Start (All Environments)

### 1. Clone Repository

```bash
git clone https://github.com/your-org/flutterpos.git
cd flutterpos

```

### 2. Prepare Environment File

```bash

# Copy example file

cp docker/.env.example docker/.env.production


# Edit with your values

nano docker/.env.production

```

### 3. Build Docker Image

```bash
cd docker


# Build production image

docker-compose -f docker-compose.yml build


# Or build specific service

docker-compose build backend-api

```

### 4. Start Services

```bash

# Start all services

docker-compose up -d


# View logs

docker-compose logs -f backend-api


# Check service status

docker-compose ps

```

### 5. Verify Deployment

```bash

# Test API

curl http://localhost:3001/api/health


# Check logs for errors

docker-compose logs backend-api | grep -i error

```

## Configuration

### Environment Variables

**Critical Variables** (must set for production):

```env

# Appwrite Configuration

APPWRITE_ENDPOINT=https://appwrite.example.com/v1
APPWRITE_PROJECT_ID=your-project-id
APPWRITE_API_KEY=your-api-key-here


# JWT Configuration

JWT_SECRET=your-very-secure-random-secret-minimum-32-chars


# Database

DB_DRIVER=mariadb
DB_HOST=mariadb
DB_PORT=3306
DB_USER=pos_user
DB_PASSWORD=secure-password-here
DB_NAME=pos_db


# Application

NODE_ENV=production
APP_PORT=3001
APP_HOST=0.0.0.0


# Email (optional)

MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=noreply@extropos.com


# Backup

BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *  # 2 AM daily

BACKUP_RETENTION=30  # Days



# Monitoring

MONITORING_ENABLED=true
LOG_LEVEL=info

```

### docker-compose.yml (Customization)

**Key Sections**:

#### Backend API Service

```yaml
backend-api:
  build:
    context: ../backend-api
    dockerfile: Dockerfile
  ports:

    - "3001:3001"
  environment:
    NODE_ENV: production
    APPWRITE_ENDPOINT: ${APPWRITE_ENDPOINT}
    JWT_SECRET: ${JWT_SECRET}
  depends_on:

    - appwrite
  networks:

    - appwrite-net
  restart: unless-stopped
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3001/api/health"]
    interval: 30s
    timeout: 10s
    retries: 3

```

#### MariaDB Service

```yaml
mariadb:
  image: mariadb:10.11
  ports:

    - "3306:3306"
  environment:
    MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    MYSQL_DATABASE: ${DB_NAME}
    MYSQL_USER: ${DB_USER}
    MYSQL_PASSWORD: ${DB_PASSWORD}
  volumes:

    - mariadb_data:/var/lib/mysql

    - ./backups:/backups
  networks:

    - appwrite-net
  restart: unless-stopped

```

## Deployment Procedures

### Development Deployment

```bash
cd docker


# Set development environment

export ENV=development


# Build and start

docker-compose build
docker-compose up -d


# Initialize database

docker-compose exec backend-api npm run db:migrate


# Create default admin

docker-compose exec backend-api node scripts/setup-default-admin.js


# Run tests

docker-compose exec backend-api npm test


# View logs

docker-compose logs -f backend-api

```

### Staging Deployment

```bash
cd docker


# Use staging environment

cp .env.staging .env


# Build with staging image

docker-compose -f docker-compose.staging.yml build


# Start services

docker-compose -f docker-compose.staging.yml up -d


# Run migrations

docker-compose exec backend-api npm run db:migrate


# Health checks

curl https://staging-api.yourdomain.com/health


# Smoke tests

npm run test:smoke

```

### Production Deployment

```bash
cd docker


# Backup existing database

docker-compose exec mariadb mysqldump -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} > backup-$(date +%Y%m%d-%H%M%S).sql


# Load production environment

cp .env.production .env


# Pull latest code

git pull origin main


# Build production image

docker build -f Dockerfile.prod -t flutterpos-api:latest ../backend-api


# Start services with production configuration

docker-compose -f docker-compose.prod.yml up -d


# Wait for services to be ready

sleep 10


# Run migrations

docker-compose exec backend-api npm run db:migrate


# Run tests

docker-compose exec backend-api npm test


# Verify health

curl https://api.yourdomain.com/health


# Check logs for errors

docker-compose logs backend-api | grep -i error

```

## Health Checks

### Backend API Health

```bash

# Check API is responding

curl http://localhost:3001/api/health


# Expected response:

# {"status":"healthy","uptime":123.45,"timestamp":"2026-01-28T10:30:00Z"}

```

### Database Health

```bash

# Connect to MariaDB

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "SELECT 1"


# Check database size

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb FROM information_schema.tables WHERE table_schema = '${DB_NAME}'"

```

### Appwrite Health

```bash

# Check Appwrite API

curl http://localhost:80/v1/health


# Check collections

curl -X GET "http://localhost:80/v1/databases/pos_db/collections" \
  -H "X-Appwrite-Project: ${APPWRITE_PROJECT_ID}" \
  -H "X-Appwrite-Key: ${APPWRITE_API_KEY}"

```

### Docker Container Status

```bash

# View all containers

docker-compose ps


# Check resource usage

docker stats


# View container logs

docker-compose logs backend-api


# Follow logs in real-time

docker-compose logs -f backend-api --tail=100

```

## Monitoring & Logging

### Real-time Logs

```bash

# Backend API logs

docker-compose logs -f backend-api


# Appwrite logs

docker-compose logs -f appwrite


# MariaDB logs

docker-compose logs -f mariadb


# All services

docker-compose logs -f

```

### Log Rotation

Add to docker-compose.yml:

```yaml
services:
  backend-api:
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"

```

### Performance Monitoring

```bash

# CPU & Memory usage

docker stats


# Disk usage by service

docker system df


# Network traffic

docker-compose exec backend-api iftop


# Database performance

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "SHOW PROCESSLIST"

```

### Centralized Logging (Optional)

Install ELK Stack (Elasticsearch, Logstash, Kibana):

```yaml
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
  environment:

    - discovery.type=single-node
  ports:

    - "9200:9200"

kibana:
  image: docker.elastic.co/kibana/kibana:7.14.0
  ports:

    - "5601:5601"
  depends_on:

    - elasticsearch

```

## Backup & Recovery

### Automated Backups

```bash

# Enable backup in .env

BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *  # Daily at 2 AM



# Create backup script

cat > docker/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DB_NAME="pos_db"
DB_USER="pos_user"

mkdir -p $BACKUP_DIR
docker-compose exec -T mariadb mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME \
  > $BACKUP_DIR/db-$TIMESTAMP.sql
  

# Keep only last 30 days

find $BACKUP_DIR -name "db-*.sql" -mtime +30 -delete
EOF

chmod +x docker/backup.sh


# Add to crontab (Linux/macOS)

0 2 * * * cd /path/to/flutterpos && ./docker/backup.sh

```

### Manual Backup

```bash

# Backup database

docker-compose exec mariadb mysqldump -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} \
  > backup-$(date +%Y%m%d-%H%M%S).sql


# Backup configuration

tar -czf config-backup-$(date +%Y%m%d-%H%M%S).tar.gz docker/.env*


# Backup volumes

docker run --rm \
  -v flutterpos_mariadb_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/volume-$(date +%Y%m%d-%H%M%S).tar.gz /data

```

### Recovery

```bash

# Restore database

docker-compose exec -T mariadb mysql -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} < backup-20260128-100000.sql


# Restore volumes

docker run --rm \
  -v flutterpos_mariadb_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar xzf /backup/volume-20260128-100000.tar.gz

```

## SSL/TLS Configuration

### Using Let's Encrypt (Automated)

```bash

# Add to docker-compose.yml

labels:

  - "traefik.enable=true"

  - "traefik.http.routers.api.rule=Host(`api.yourdomain.com`)"

  - "traefik.http.routers.api.entrypoints=websecure"

  - "traefik.http.routers.api.tls.certresolver=letsencrypt"

```

### Using Custom Certificate

```bash

# Generate self-signed certificate (development only)

openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes


# Add to docker-compose.yml

volumes:

  - ./certs/cert.pem:/etc/ssl/cert.pem

  - ./certs/key.pem:/etc/ssl/key.pem

```

## Scaling

### Horizontal Scaling (Multiple Backend Instances)

```yaml
services:
  backend-api-1:
    build: ../backend-api
    ports:

      - "3001:3001"
    # ...


  backend-api-2:
    build: ../backend-api
    ports:

      - "3002:3001"
    # ...


  load-balancer:
    image: nginx:latest
    ports:

      - "80:80"
    volumes:

      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:

      - backend-api-1

      - backend-api-2

```

### Vertical Scaling (More Resources)

```bash

# Edit docker-compose.yml

services:
  backend-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G

```

## Troubleshooting

### Container Won't Start

```bash

# Check logs

docker-compose logs backend-api


# Common issues:

# 1. Port already in use

docker ps | grep 3001
kill -9 <PID>


# 2. Image build failed

docker-compose build --no-cache


# 3. Volume permission issues

docker exec backend-api ls -la /app

```

### Database Connection Failed

```bash

# Test connection

docker-compose exec backend-api npm run db:test


# Check connection string

echo "Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD"


# Verify database is running

docker-compose ps mariadb

```

### Out of Memory

```bash

# Check resource limits

docker stats


# Increase available memory

# Edit docker-compose.yml and increase memory limit

# Or: Increase system swap space



# Reduce cache/optimize queries

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "OPTIMIZE TABLE pos_db.*"

```

### Slow Performance

```bash

# Check database indexes

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "ANALYZE TABLE pos_db.users"


# Monitor slow queries

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "SET GLOBAL slow_query_log='ON'"


# View query logs

docker-compose logs mariadb | grep "Query_time"

```

## Maintenance

### Update Services

```bash

# Pull latest code

git pull origin main


# Rebuild images

docker-compose build --no-cache


# Restart services

docker-compose up -d


# Verify services

docker-compose ps

```

### Database Maintenance

```bash

# Check table size

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) FROM information_schema.tables WHERE table_schema = 'pos_db'"


# Optimize tables

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "OPTIMIZE TABLE pos_db.*"


# Clean up old sessions (older than 30 days)

docker-compose exec mariadb mysql -u${DB_USER} -p${DB_PASSWORD} -e "DELETE FROM pos_db.sessions WHERE created_at < UNIX_TIMESTAMP(NOW() - INTERVAL 30 DAY)"

```

### Clean Up

```bash

# Remove stopped containers

docker-compose down


# Remove unused volumes

docker volume prune


# Remove unused images

docker image prune


# Remove everything (careful!)

docker system prune -a

```

## Production Checklist

Before going live:

- [ ] SSL/TLS certificate installed

- [ ] Environment variables configured (no defaults)

- [ ] Database backups automated

- [ ] Monitoring enabled (health checks, logs, metrics)

- [ ] Load testing completed

- [ ] Security audit passed

- [ ] Disaster recovery plan documented

- [ ] Team trained on operations

- [ ] Staging deployment verified

- [ ] Rollback plan documented

## Support & Resources

- **Docker Docs**: <https://docs.docker.com/>

- **Docker Compose Docs**: <https://docs.docker.com/compose/>

- **Appwrite Docs**: <https://appwrite.io/docs>

- **MariaDB Docs**: <https://mariadb.com/docs/>

---

**Last Updated**: January 28, 2026  
**Version**: 1.0.0  
**Status**: Production Ready
