# FlutterPOS Self-Hosted Cloud Infrastructure

Complete self-hosted cloud infrastructure for FlutterPOS premium backend features using Docker, Appwrite, Nextcloud, and RabbitMQ.

## 🏗️ Architecture Overview

```
Internet
    │
    ▼
┌─────────────┐    ┌─────────────────┐
│   Traefik   │────│  FlutterPOS     │
│ (Reverse    │    │  Backend Web    │
│  Proxy)     │    │                 │
└─────────────┘    └─────────────────┘
        │
        ├─────────────────┬─────────────────┬─────────────────┬─────────────────┐
        │                 │                 │                 │                 │
    ┌───▼───┐    ┌────▼────┐    ┌─────▼─────┐    ┌─────▼─────┐    ┌─────▼─────┐
    │Appwrite│    │Nextcloud│    │ RabbitMQ  │    │ MailHog  │    │  MariaDB  │
    │(API/DB)│    │ (Cloud  │    │(Real-time)│    │ (Email   │    │ (Database)│
    │        │    │ Storage)│    │           │    │ Testing) │    │           │
    └────────┘    └─────────┘    └───────────┘    └──────────┘    └───────────┘

```

## 🚀 Quick Start

### Prerequisites

- Linux server with Docker and Docker Compose

- Domain name pointing to your server

- At least 4GB RAM, 2 CPU cores, 50GB storage

### 1. Clone and Setup

```bash
cd /path/to/flutterpos
cd docker

```

### 2. Configure Environment

```bash

# Set your domain and email

export DOMAIN="yourdomain.com"
export EMAIL="admin@yourdomain.com"


# Run setup script

./setup.sh

```

### 3. Start Services

```bash
docker-compose up -d

```

### 4. Check Status

```bash
./status.sh

```

## 📋 Services Included

### 🏗️ Traefik (Reverse Proxy & SSL)

- **Port**: 80/443

- **Dashboard**: <https://traefik.yourdomain.com>

- **Features**: Automatic SSL certificates, load balancing, routing

### 📱 Appwrite (Backend API)

- **API**: <https://appwrite.yourdomain.com>

- **Console**: <https://console.appwrite.yourdomain.com>

- **Features**: Database, authentication, storage, functions

- **Project ID**: `flutterpos`

### ☁️ Nextcloud (Cloud Storage)

- **URL**: <https://cloud.yourdomain.com>

- **Features**: File storage, backup, sync

- **Default Login**: admin / admin123

### 🐰 RabbitMQ (Real-time Sync)

- **Management**: <https://rabbitmq.yourdomain.com>

- **AMQP Port**: 5672

- **Features**: Real-time POS synchronization

- **Default Login**: posadmin / [generated-password]

### 🌐 FlutterPOS Backend (Web Management)

- **URL**: <https://backend.yourdomain.com>

- **Features**: Remote POS management interface

### 📧 MailHog (Development)

- **URL**: <https://mail.yourdomain.com>

- **Features**: Email testing and debugging

## 🔧 Configuration

### Environment Variables (.env)

```bash

# Domain settings

DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com


# Generated secure passwords

APPWRITE_DB_ROOT_PASS=...
APPWRITE_DB_PASS=...
MINIO_ACCESS_KEY=...
MINIO_SECRET_KEY=...
RABBITMQ_PASS=...


# Appwrite API keys

CONSOLE_KEY=...
CONSOLE_SECRET=...

# ... (other keys)

```

### DNS Configuration

Point these subdomains to your server IP:

```
appwrite.yourdomain.com     → server-ip
console.appwrite.yourdomain.com → server-ip
cloud.yourdomain.com        → server-ip
backend.yourdomain.com      → server-ip
rabbitmq.yourdomain.com     → server-ip
traefik.yourdomain.com      → server-ip
mail.yourdomain.com         → server-ip

```

## 🔒 Security Setup

### 1. Change Default Passwords

```bash

# Edit .env file and change default passwords

nano .env

```

### 2. Configure Firewall

```bash

# Allow only necessary ports

sudo ufw allow 22/tcp    # SSH

sudo ufw allow 80/tcp    # HTTP

sudo ufw allow 443/tcp   # HTTPS

sudo ufw --force enable

```

### 3. SSL Certificates

Traefik automatically handles Let's Encrypt SSL certificates for all services.

## 📊 Monitoring & Maintenance

### View Logs

```bash

# All services

docker-compose logs -f


# Specific service

docker-compose logs -f appwrite


# Last 100 lines

docker-compose logs --tail=100 traefik

```

### Backup Data

```bash

# Backup all volumes

docker run --rm -v flutterpos_backup:/backup -v $(pwd):/host alpine tar czf /host/backup.tar.gz -C /backup .


# Backup specific volume

docker run --rm -v flutterpos_appwrite_mariadb:/data -v $(pwd):/backup alpine tar czf /backup/appwrite-db.tar.gz -C /data .

```

### Update Services

```bash

# Update all images

docker-compose pull


# Restart with new images

docker-compose up -d


# Update specific service

docker-compose up -d appwrite

```

## 🐛 Troubleshooting

### Common Issues

**Port 80/443 already in use:**

```bash

# Check what's using the ports

sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443


# Stop conflicting services

sudo systemctl stop apache2 nginx

```

**SSL Certificate Issues:**

```bash

# Check Traefik logs

docker-compose logs traefik


# Clear Let's Encrypt certificates

docker volume rm flutterpos-traefik_letsencrypt

```

**Appwrite Not Starting:**

```bash

# Check Appwrite logs

docker-compose logs appwrite


# Verify environment variables

docker-compose exec appwrite env

```

**Database Connection Issues:**

```bash

# Check MariaDB logs

docker-compose logs appwrite-mariadb


# Test database connection

docker-compose exec appwrite-mariadb mysql -u root -p

```

### Health Checks

```bash

# Manual health checks

curl -k https://appwrite.yourdomain.com/v1/health
curl -k https://cloud.yourdomain.com/status.php
curl -k https://backend.yourdomain.com/health

```

## 🔄 Migration & Updates

### From Development to Production

1. Update domain in `.env`
2. Re-run `./setup.sh`
3. Update DNS records
4. Restart services: `docker-compose down && docker-compose up -d`

### Backup Before Updates

```bash

# Create backup

./backup.sh


# Update and restart

docker-compose pull && docker-compose up -d

```

## 📈 Performance Tuning

### Memory Limits

```yaml

# In docker-compose.yml, add memory limits

services:
  appwrite:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

```

### Database Optimization

```sql
-- Run in Appwrite MariaDB console

SET GLOBAL innodb_buffer_pool_size = 268435456; -- 256MB

SET GLOBAL max_connections = 100;

```

## 🆘 Support

### Logs to Collect

```bash

# System info

uname -a
docker --version
docker-compose --version


# Service status

./status.sh


# Recent logs

docker-compose logs --tail=50

```

### Emergency Stop

```bash

# Stop all services

docker-compose down


# Remove all containers and volumes (⚠️ DATA LOSS)

docker-compose down -v --remove-orphans

```

## 📚 Additional Resources

- [Appwrite Documentation](https://appwrite.io/docs)

- [Nextcloud Documentation](https://docs.nextcloud.com/)

- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)

- [Traefik Documentation](https://doc.traefik.io/traefik/)

---

## 🎯 FlutterPOS Integration

### Backend Configuration

The FlutterPOS backend connects to:

- **Appwrite**: `https://appwrite.yourdomain.com/v1`

- **Nextcloud**: `https://cloud.yourdomain.com`

- **RabbitMQ**: `amqps://posadmin:password@rabbitmq.yourdomain.com:5672`

### Environment Variables for FlutterPOS

```dart
const String appwriteEndpoint = 'https://appwrite.yourdomain.com/v1';
const String appwriteProjectId = 'flutterpos';
const String nextcloudUrl = 'https://cloud.yourdomain.com';
const String rabbitmqHost = 'rabbitmq.yourdomain.com';

```
