# FlutterPOS Self-Hosted Deployment Guide

Complete step-by-step guide for deploying FlutterPOS premium backend infrastructure.

## 📋 Prerequisites

### System Requirements

- **OS**: Linux (Ubuntu 20.04+, CentOS 8+, Debian 11+)

- **CPU**: 2+ cores (4+ recommended)

- **RAM**: 4GB minimum (8GB+ recommended)

- **Storage**: 50GB+ available space

- **Network**: Static IP address, domain name

### Software Requirements

- **Docker**: 20.10+ (`docker --version`)

- **Docker Compose**: 2.0+ (`docker-compose --version` or `docker compose version`)

- **curl**: For health checks

- **openssl**: For certificate generation

### Domain Requirements

- Domain name (e.g., `yourdomain.com`)

- DNS A records pointing to your server IP:

  ```
  appwrite.yourdomain.com     → YOUR_SERVER_IP
  console.appwrite.yourdomain.com → YOUR_SERVER_IP
  cloud.yourdomain.com        → YOUR_SERVER_IP
  backend.yourdomain.com      → YOUR_SERVER_IP
  rabbitmq.yourdomain.com     → YOUR_SERVER_IP
  traefik.yourdomain.com      → YOUR_SERVER_IP
  mail.yourdomain.com         → YOUR_SERVER_IP
  ```

## 🚀 Deployment Steps

### Step 1: Server Preparation

```bash

# Update system

sudo apt update && sudo apt upgrade -y


# Install Docker

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER


# Install Docker Compose

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


# Reboot to apply Docker group changes

sudo reboot

```

### Step 2: Clone and Setup FlutterPOS

```bash

# Clone repository

cd /opt
sudo git clone https://github.com/yourusername/flutterpos.git
sudo chown -R $USER:$USER flutterpos
cd flutterpos/docker


# Set your domain

export DOMAIN="yourdomain.com"
export EMAIL="admin@yourdomain.com"


# Run setup

./setup.sh

```

### Step 3: Configure Firewall

```bash

# Allow required ports

sudo ufw allow 22/tcp    # SSH

sudo ufw allow 80/tcp    # HTTP

sudo ufw allow 443/tcp   # HTTPS

sudo ufw --force enable


# Verify firewall status

sudo ufw status

```

### Step 4: Start Services

```bash
cd /opt/flutterpos/docker


# Start all services

docker-compose up -d


# Wait for services to initialize (may take 2-3 minutes)

sleep 180


# Check status

./status.sh

```

### Step 5: Initial Configuration

#### Appwrite Setup

1. Open <https://console.appwrite.yourdomain.com>
2. Create admin account
3. Create project: `flutterpos`
4. Configure authentication providers
5. Set up storage buckets

#### Nextcloud Setup

1. Open <https://cloud.yourdomain.com>
2. Create admin account (admin/admin123)
3. Configure storage and sharing settings
4. Set up user accounts

#### RabbitMQ Setup

1. Open <https://rabbitmq.yourdomain.com>
2. Login with generated credentials
3. Create virtual hosts and users
4. Configure exchanges and queues

### Step 6: FlutterPOS Backend Build

```bash

# Build Flutter web app

cd /opt/flutterpos
flutter build web --release


# Copy build to docker directory

cp -r build/web docker/flutterpos-build


# Rebuild backend container

cd docker
docker-compose up -d --build backend

```

### Step 7: SSL Certificate Setup

Traefik automatically handles SSL certificates via Let's Encrypt. However, you may need to:

```bash

# Check certificate status

docker-compose logs traefik | grep -i "certificate"


# Clear certificates if needed

docker volume rm flutterpos-traefik_letsencrypt
docker-compose restart traefik

```

## 🔍 Verification Steps

### Health Check

```bash
cd /opt/flutterpos/docker
./health-check.sh

```

### Manual Verification

1. **Traefik Dashboard**: <https://traefik.yourdomain.com>
2. **Appwrite API**: <https://appwrite.yourdomain.com/v1/health>
3. **Appwrite Console**: <https://console.appwrite.yourdomain.com>
4. **Nextcloud**: <https://cloud.yourdomain.com>
5. **RabbitMQ**: <https://rabbitmq.yourdomain.com>
6. **FlutterPOS Backend**: <https://backend.yourdomain.com>
7. **MailHog**: <https://mail.yourdomain.com>

## 🔧 Post-Deployment Configuration

### Change Default Passwords

```bash
cd /opt/flutterpos/docker


# Edit .env file

nano .env


# Change these passwords:

# - APPWRITE_DB_ROOT_PASS

# - APPWRITE_DB_PASS

# - RABBITMQ_PASS

# - MINIO_ACCESS_KEY

# - MINIO_SECRET_KEY



# Restart services

docker-compose down && docker-compose up -d

```

### Configure Appwrite Project

```bash

# Access Appwrite console

open https://console.appwrite.yourdomain.com


# Create FlutterPOS project

# Configure authentication

# Set up database collections

# Create storage buckets

```

### Setup Backup Schedule

```bash

# Create daily backup cron job

crontab -e


# Add this line for daily backups at 2 AM:

# 0 2 * * * cd /opt/flutterpos/docker && ./backup.sh

```

## 📊 Monitoring & Maintenance

### Daily Checks

```bash
cd /opt/flutterpos/docker


# Quick status check

./status.sh


# Comprehensive health check

./health-check.sh

```

### Log Monitoring

```bash

# View all logs

docker-compose logs -f


# View specific service logs

docker-compose logs -f appwrite
docker-compose logs -f traefik
docker-compose logs -f nextcloud

```

### Updates

```bash

# Update all images

docker-compose pull


# Restart with new versions

docker-compose up -d


# Check for issues

./health-check.sh

```

### Backup & Restore

```bash

# Create backup

./backup.sh


# List available backups

ls -la backups/


# Restore from specific backup

./restore.sh 20241126_143022

```

## 🐛 Troubleshooting

### Common Issues

#### Services Not Starting

```bash

# Check Docker system resources

docker system df


# Check available disk space

df -h


# Check available memory

free -h


# View detailed logs

docker-compose logs [service-name]

```

#### Port 80/443 Already in Use

```bash

# Find conflicting services

sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443


# Stop conflicting services

sudo systemctl stop apache2 nginx

```

#### SSL Certificate Issues

```bash

# Check Traefik logs

docker-compose logs traefik


# Clear Let's Encrypt certificates

docker volume rm flutterpos-traefik_letsencrypt
docker-compose restart traefik

```

#### Database Connection Issues

```bash

# Check MariaDB logs

docker-compose logs appwrite-mariadb


# Test database connection

docker-compose exec appwrite-mariadb mysql -u root -p

```

### Emergency Recovery

```bash

# Stop all services

docker-compose down


# Remove all containers and volumes (⚠️ DATA LOSS)

docker-compose down -v --remove-orphans


# Clean up Docker system

docker system prune -a --volumes


# Restart fresh deployment

./setup.sh
docker-compose up -d

```

## 🔒 Security Hardening

### 1. Network Security

```bash

# Configure firewall properly

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443

```

### 2. Service Security

- Change all default passwords

- Use strong, unique passwords

- Enable 2FA where available

- Regularly update Docker images

### 3. SSL/TLS

- Traefik automatically provides SSL

- Certificates are renewed automatically

- All services use HTTPS

### 4. Backup Security

- Store backups in encrypted location

- Test backup restoration regularly

- Keep multiple backup generations

## 📞 Support

### Log Collection for Support

```bash
cd /opt/flutterpos/docker


# Collect system information

uname -a > support_info.txt
docker --version >> support_info.txt
docker-compose --version >> support_info.txt


# Collect service status

./status.sh >> support_info.txt


# Collect recent logs

docker-compose logs --tail=100 >> support_logs.txt


# Create support archive

tar czf flutterpos_support_$(date +%Y%m%d).tar.gz support_*.txt

```

### Emergency Contacts

- **System Admin**: [Your contact information]

- **Docker Support**: <https://docs.docker.com/>

- **Appwrite Support**: <https://appwrite.io/support>

- **Nextcloud Support**: <https://help.nextcloud.com/>

---

## ✅ Deployment Checklist

- [ ] Server meets minimum requirements

- [ ] Docker and Docker Compose installed

- [ ] Domain DNS configured

- [ ] Firewall configured

- [ ] FlutterPOS cloned and setup.sh run

- [ ] Services started successfully

- [ ] SSL certificates issued

- [ ] Default passwords changed

- [ ] Appwrite project configured

- [ ] Nextcloud admin account created

- [ ] RabbitMQ users configured

- [ ] FlutterPOS backend built and deployed

- [ ] Backup schedule configured

- [ ] Health checks passing

- [ ] Monitoring alerts configured

**Deployment Complete!** 🎉

Your FlutterPOS self-hosted infrastructure is now ready for production use.
