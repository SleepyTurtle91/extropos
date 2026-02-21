# Appwrite Self-Hosted Cloud Operations Guide

**Status**: ✅ Production Ready (v1.5.7)  
**Last Updated**: January 28, 2026  
**Infrastructure**: Windows Docker (E:\appwrite-cloud)

---

## Quick Access

### Start Stack

```powershell
cd e:\flutterpos\docker
docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml up -d

```

### Access Points

- **API**: <http://localhost:8080/v1> (or <https://api.yourdomain/v1> with Traefik)

- **Console**: <http://localhost:8080/console>

- **Traefik Dashboard**: <http://localhost:8090>

- **Database**: MariaDB at localhost:3306 (internal to Docker)

- **Cache**: Redis at localhost:6379 (internal to Docker)

### Status & Monitoring

```powershell

# Check all containers

cd e:\flutterpos\docker
docker compose ps


# Run health checks

.\monitor-cloud-health.ps1 -Command health


# View disk usage

.\monitor-cloud-health.ps1 -Command disk-usage


# Check database size

.\monitor-cloud-health.ps1 -Command db-size


# View API logs

.\monitor-cloud-health.ps1 -Command logs

```

---

## Architecture Overview

### Docker Services (8 containers + 1 proxy)

| Service | Image | Purpose | Port |
|---------|-------|---------|------|
| **appwrite-api** | appwrite/appwrite:1.5.7 | REST API + Console | 8080/8443 |

| **appwrite-console** | nginx:alpine | Console redirect (optional) | 3000 |

| **appwrite-mariadb** | mariadb:10.11 | Database (MySQL) | 3306 |

| **appwrite-redis** | redis:7-alpine | Cache + Queue | 6379 |

| **appwrite-worker-database** | appwrite/appwrite:1.5.7 | DB maintenance worker | internal |

| **appwrite-worker-audits** | appwrite/appwrite:1.5.7 | Audit logging worker | internal |

| **appwrite-worker-usage** | appwrite/appwrite:1.5.7 | Usage stats worker | internal |

| **appwrite-worker-webhooks** | appwrite/appwrite:1.5.7 | Webhook delivery worker | internal |

| **appwrite-traefik** | traefik:v3.0 | Reverse proxy + TLS | 80/443 |

### Storage Layout (E:\appwrite-cloud\)

```
E:\appwrite-cloud\
├── mysql/                    # MariaDB persistent data

├── redis/                    # Redis persistent data (RDB/AOF)

├── storage/                  # Appwrite file storage

│   ├── config/              # App configurations

│   ├── uploads/             # User uploads

│   ├── functions/           # Serverless functions

│   └── buckets/             # Storage buckets

├── traefik/
│   ├── letsencrypt/         # TLS certificates

│   └── logs/                # Traefik access logs

├── backups/                 # Daily backup directory

│   └── YYYY-MM-DD/
│       ├── appwrite_database_*.sql.zip
│       ├── appwrite_storage_*.zip
│       └── .env_*
├── config/                  # Appwrite config mounts

└── .env                     # Environment configuration

```

---

## Daily Operations

### 1. Backup & Recovery

#### Automated Daily Backups

```powershell

# Schedule backup script to run at 2 AM daily (Windows Task Scheduler)

# Task: "Appwrite Cloud Storage Backup"

# Location: e:\flutterpos\docker\backup-cloud-storage.ps1



# Test backup manually

.\backup-cloud-storage.ps1 -BackupPath "E:\appwrite-cloud\backups" -RetentionDays 30


# Check backup status

Get-ChildItem E:\appwrite-cloud\backups -Directory | ForEach-Object {
    Write-Host "$($_.Name): $(Get-ChildItem $_.FullName -File | Measure-Object).Count files"
}

```

#### Manual Database Backup

```powershell
docker exec appwrite-mariadb mysqldump \
  --user=appwrite \
  --password=appwrite_db_pw_secure_2026 \
  --single-transaction \
  appwrite > "C:\backup\appwrite_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"

```

#### Restore from Backup

```powershell

# List available backups

.\monitor-cloud-health.ps1 -Command restore


# Restore specific backup

.\monitor-cloud-health.ps1 -Command restore -RestoreFile "E:\appwrite-cloud\backups\2026-01-28\appwrite_database_20260128_020000.sql.zip"

```

### 2. Health Monitoring

#### Manual Health Check

```powershell

# Quick status check

.\monitor-cloud-health.ps1 -Command health


# View API logs (last 50 lines)

.\monitor-cloud-health.ps1 -Command logs


# Disk usage analysis

.\monitor-cloud-health.ps1 -Command disk-usage


# Database size breakdown

.\monitor-cloud-health.ps1 -Command db-size

```

#### Real-time Log Monitoring

```powershell

# API logs

docker compose logs -f appwrite


# Database logs

docker compose logs -f appwrite-mariadb


# Worker logs

docker compose logs -f appwrite-worker-database
docker compose logs -f appwrite-worker-audits

```

### 3. Restart & Maintenance

#### Graceful Restart

```powershell

# Restart all services (maintains data)

docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml restart


# Restart specific service

docker compose restart appwrite-api
docker compose restart appwrite-mariadb

```

#### Complete Restart (Clean)

```powershell

# Stop all services

docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml down


# Start fresh

docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml up -d

```

#### Update Appwrite Version

```powershell

# Pull latest image

docker pull appwrite/appwrite:latest


# Update compose file version tag

# Then restart

docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml up -d --pull always

```

---

## TLS & Reverse Proxy Setup (Traefik)

### Local Development (localhost)

- API: <http://localhost:8080>

- Console: <http://localhost:8080/console>

- Dashboard: <http://localhost:8090>

### Production Deployment (with DNS)

#### 1. Configure DNS

Point these A records to your server:

```
api.yourdomain.com     → your.server.ip
console.yourdomain.com → your.server.ip
yourdomain.com         → your.server.ip

```

#### 2. Update .env for Production

```dotenv
DOMAIN=yourdomain.com
FORCE_HTTPS=true
APPWRITE_ENDPOINT=https://api.yourdomain.com/v1

```

#### 3. Enable Let's Encrypt (Traefik)

Uncomment in `traefik-compose.yml`:

```yaml

- "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory"

```

#### 4. Firewall Configuration

```powershell

# Open ports 80, 443 to public internet

# Keep ports 3306 (DB), 6379 (Redis) internal only

# Keep port 8080 internal (use Traefik proxy instead)



# Example: Allow HTTP/HTTPS

netsh advfirewall firewall add rule name="Allow HTTP" dir=in action=allow protocol=tcp localport=80
netsh advfirewall firewall add rule name="Allow HTTPS" dir=in action=allow protocol=tcp localport=443

```

#### 5. Certificate Validation

```powershell

# Check certificate is valid

curl -I https://api.yourdomain.com/v1


# Monitor certificate renewal

docker compose logs traefik | Select-String -Pattern "ACME|certificate"

```

---

## Database Operations

### MySQL Access

#### Direct Container Access

```powershell

# Connect to MySQL CLI

docker exec -it appwrite-mariadb mysql -u appwrite -p appwrite


# Run SQL query

docker exec appwrite-mariadb mysql -u appwrite -p appwrite -e "SELECT * FROM collections LIMIT 5;"

```

#### Backup Strategies

**Strategy 1: Daily Automated Dumps**

```powershell

# Via backup script (recommended)

.\backup-cloud-storage.ps1


# Stores compressed SQL + storage snapshots

# Retention: 30 days by default

```

**Strategy 2: Binary Backups (Mariabackup)**

```powershell

# Full backup

docker exec appwrite-mariadb mariabackup --backup \
  --user=appwrite --password=appwrite_db_pw_secure_2026 \
  --target-dir=/backup


# Incremental (after full backup)

docker exec appwrite-mariadb mariabackup --backup --incremental \
  --user=appwrite --password=appwrite_db_pw_secure_2026 \
  --target-dir=/backup

```

**Strategy 3: Continuous Replication**
For production environments, consider setting up a replica database:

- Secondary MariaDB container syncing via replication

- Store on separate disk/backup location

- Test failover monthly

---

## Performance Tuning

### Database Optimization

```powershell

# Check slow queries

docker exec appwrite-mariadb mysql -u appwrite -p appwrite -e \
  "SHOW VARIABLES LIKE 'long_query_time'; SHOW GLOBAL STATUS LIKE 'Slow_queries';"


# Enable query log (temporary, impacts performance)

docker exec appwrite-mariadb mysql -u appwrite -p appwrite -e \
  "SET GLOBAL slow_query_log = 'ON'; SET GLOBAL long_query_time = 2;"

```

### Redis Optimization

```powershell

# Monitor Redis memory usage

docker exec appwrite-redis redis-cli INFO memory


# Check eviction policy

docker exec appwrite-redis redis-cli CONFIG GET maxmemory-policy


# Current memory stats

docker exec appwrite-redis redis-cli INFO stats

```

### Appwrite Worker Tuning

Edit `.env`:

```dotenv
_APP_WORKER_PER_CORE=6        # Increase if CPU available

_APP_FUNCTION_BUILD_TIMEOUT=900
_APP_FUNCTION_EXECUTION_TIMEOUT=900

```

---

## Troubleshooting

### Container Won't Start

```powershell

# Check error logs

docker compose logs appwrite-api


# Check disk space

Get-Volume | Where-Object { $_.DriveLetter -eq 'E' }


# Verify .env syntax

Get-Content E:\flutterpos\docker\.env

```

### Database Connection Errors

```powershell

# Test database connectivity

docker exec appwrite-mariadb mysqladmin ping -u appwrite -p


# Check MariaDB logs

docker compose logs appwrite-mariadb


# Reset database password (emergency)

docker exec appwrite-mariadb mysql -u root -p[MYSQL_ROOT_PASSWORD] \
  -e "ALTER USER 'appwrite'@'%' IDENTIFIED BY 'new_password'; FLUSH PRIVILEGES;"

```

### High Disk Usage

```powershell

# Analyze storage

.\monitor-cloud-health.ps1 -Command disk-usage


# Clean old backups

Remove-Item E:\appwrite-cloud\backups\2026-01* -Recurse -Force


# Optimize database

docker exec appwrite-mariadb mysql -u appwrite -p appwrite \
  -e "OPTIMIZE TABLE `*`.`*`;"

```

### API Timeouts

```powershell

# Increase Appwrite timeouts

# Edit .env:

_APP_UPLOAD_MAX_FILE_SIZE=1073741824
_APP_FUNCTION_BUILD_TIMEOUT=1200
_APP_FUNCTION_EXECUTION_TIMEOUT=1200


# Restart API

docker compose restart appwrite

```

### Worker Queue Lag

```powershell

# Check worker status

docker compose logs appwrite-worker-database
docker compose logs appwrite-worker-audits
docker compose logs appwrite-worker-webhooks


# Restart workers

docker compose restart appwrite-worker-database appwrite-worker-audits appwrite-worker-usage appwrite-worker-webhooks

```

---

## Disaster Recovery

### Scenario 1: Data Corruption

```powershell

# 1. Stop services

docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml down


# 2. Restore from latest backup

.\monitor-cloud-health.ps1 -Command restore -RestoreFile "path/to/backup.zip"


# 3. Restart services

docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml up -d


# 4. Verify data integrity

.\monitor-cloud-health.ps1 -Command health

```

### Scenario 2: Complete Drive Failure

```powershell

# 1. Restore from off-site backup

# (Copy backup from cloud storage / external drive)



# 2. Create new E:\appwrite-cloud directory structure

E:\appwrite-cloud\
├── mysql\
├── redis\
├── storage\
├── config\
├── traefik\
└── backups\


# 3. Extract database dump

Expand-Archive -Path backup.zip -DestinationPath E:\appwrite-cloud\


# 4. Restore database

docker exec -i appwrite-mariadb mysql -u appwrite -p < database.sql


# 5. Copy storage files

Copy-Item -Path backup_storage/* -Destination E:\appwrite-cloud\storage -Recurse

```

### Scenario 3: Database Corruption

```powershell

# 1. Check for corruption

docker exec appwrite-mariadb mysqlcheck -u appwrite -p appwrite --all-databases


# 2. Repair tables

docker exec appwrite-mariadb mysqlcheck -u appwrite -p appwrite --all-databases --repair


# 3. If repair fails, restore from backup

.\monitor-cloud-health.ps1 -Command restore -RestoreFile "latest_backup.zip"

```

---

## Security Hardening

### Access Control

```powershell

# 1. Change default passwords in .env

MYSQL_ROOT_PASSWORD=change_me_production
MYSQL_PASSWORD=change_me_production
REDIS_PASSWORD=change_me_production


# 2. Regenerate OpenSSL key

openssl rand -hex 32  # Use output in OPENSSL_KEY



# 3. Set strong API key

API_KEY=generate_long_random_string_here


# 4. Update Traefik admin password

traefik-admin-password=$(openssl passwd -apr1)

```

### Network Security

```powershell

# 1. Limit database access

# In traefik-compose.yml or firewall rules:

# - Port 3306 (MySQL) → localhost only

# - Port 6379 (Redis) → localhost only

# - Port 8080 (API) → localhost only (use Traefik proxy)

# - Port 80/443 (Traefik) → public internet



# 2. Enable HTTPS-only

FORCE_HTTPS=true


# 3. Configure CORS

_APP_CONSOLE_WHITELIST_ORIGINS=https://yourdomain.com

```

### Firewall Configuration

```powershell

# Allow public ports only

netsh advfirewall firewall add rule name="Allow HTTPS" dir=in action=allow protocol=tcp localport=443
netsh advfirewall firewall add rule name="Allow HTTP" dir=in action=allow protocol=tcp localport=80


# Block direct database access

netsh advfirewall firewall add rule name="Block MySQL" dir=in action=block protocol=tcp localport=3306
netsh advfirewall firewall add rule name="Block Redis" dir=in action=block protocol=tcp localport=6379

```

---

## Maintenance Schedule

### Daily (Automatic)

- ✅ Database backup (2 AM)

- ✅ Storage backup (2 AM)

- ✅ Log rotation

### Weekly

- [ ] Review logs for errors

- [ ] Check disk usage

- [ ] Verify backup integrity

- [ ] Test restore procedure

### Monthly

- [ ] Full system backup (off-site)

- [ ] Disaster recovery drill

- [ ] Performance analysis

- [ ] Security audit

- [ ] Update Docker images

### Quarterly

- [ ] Major version upgrade planning

- [ ] Capacity planning

- [ ] Replication/failover testing

- [ ] Access control review

---

## Support & Documentation

### Useful Commands Reference

```powershell

# Restart everything

docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml restart


# View all logs live

docker compose -f appwrite-compose-cloud-windows.yml -f traefik-compose.yml logs -f


# Clean up unused Docker resources

docker system prune -a


# Export configuration for migration

docker compose config > appwrite-config.yml


# Check disk usage by container

docker system df

```

### Getting Help

1. Check application logs: `docker compose logs appwrite`
2. Run health check: `.\monitor-cloud-health.ps1 -Command health`
3. Review error messages for specific service
4. Consult Appwrite documentation: <https://appwrite.io/docs>
5. Contact support with logs and stack info

---

**Emergency Contact**: Backup restoration team  
**Next Review Date**: April 28, 2026  
**Document Version**: 1.0.0
