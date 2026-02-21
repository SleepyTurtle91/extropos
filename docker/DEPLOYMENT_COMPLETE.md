# FlutterPOS Self-Hosted Deployment - COMPLETE ✅

## Deployment Summary

**Date**: December 8, 2025  
**Domain**: extropos.org  
**Hosting**: Local server with Cloudflare Tunnel  
**Status**: All services deployed and configured

---

## 🌐 Public URLs (External Access)

Once DNS propagates (5-15 minutes), these URLs will be accessible from anywhere:

- **Appwrite API**: <https://appwrite.extropos.org>

- **Backend Management**: <https://backend.extropos.org>

- **Nextcloud Storage**: <https://cloud.extropos.org>

- **RabbitMQ Console**: <https://mail.extropos.org>

- **Main Site**: <https://extropos.org>

All traffic is secured with Cloudflare SSL (HTTPS).

---

## 🐳 Docker Services Running

### Infrastructure Stack

```
✅ Traefik (Reverse Proxy)         - Port 80, 443

✅ Cloudflare Tunnel                - Connector to Cloudflare Edge

✅ Appwrite (Backend API)           - Port 8080
   ├── MariaDB (Database)
   ├── Redis (Cache)
   ├── InfluxDB (Metrics)
   ├── Telegraf (Monitoring)
   └── MinIO (S3 Storage)
✅ Nextcloud (Cloud Storage)        - Port 8082
   ├── MariaDB (Database)
   └── Redis (Cache)
✅ RabbitMQ (Message Queue)         - Port 5672, 15672

✅ FlutterPOS Backend (Web App)     - Port 8083

✅ Duck DNS Updater                 - Auto IP update every 5min

```

### Service Status

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose ps

```

---

## 🔧 Configuration Files

### Cloudflare Tunnel Config

**File**: `docker/cloudflared-config.yml`

```yaml
tunnel: a83dc363-b8f3-4e47-b6cd-1f45412ab9a8
ingress:

  - hostname: appwrite.extropos.org
    service: http://172.21.0.3:80

  - hostname: backend.extropos.org
    service: http://172.21.0.3:80

  - hostname: cloud.extropos.org
    service: http://172.21.0.3:80

  - hostname: mail.extropos.org
    service: http://172.21.0.3:80

  - hostname: extropos.org
    service: http://172.21.0.3:80

  - service: http_status:404

```

### Environment Variables

**File**: `docker/.env`

- Domain: extropos.org

- Cloudflare Tunnel Token: Configured

- Database Passwords: URL-encoded

- SMTP Settings: Configured in BusinessInfo

### DNS Records (Cloudflare)

**Nameservers**: phoenix.ns.cloudflare.com, venkat.ns.cloudflare.com

| Type | Name | Target | Proxy |
|------|------|--------|-------|
| CNAME | extropos.org | a83dc363-b8f3-4e47-b6cd-1f45412ab9a8.cfargotunnel.com | ✅ |
| CNAME | mail | a83dc363-b8f3-4e47-b6cd-1f45412ab9a8.cfargotunnel.com | ✅ |
| CNAME | cloud | a83dc363-b8f3-4e47-b6cd-1f45412ab9a8.cfargotunnel.com | ✅ |
| CNAME | backend | a83dc363-b8f3-4e47-b6cd-1f45412ab9a8.cfargotunnel.com | ✅ |

---

## 📱 Next Steps: Update Mobile App

Update FlutterPOS mobile app to use the self-hosted backend:

### 1. Update Appwrite Configuration

**File**: `lib/config/appwrite_config.dart` (or similar)

```dart
class AppwriteConfig {
  static const String endpoint = 'https://appwrite.extropos.org/v1';
  static const String projectId = 'YOUR_PROJECT_ID'; // Get from Appwrite console
  static const String databaseId = 'flutterpos';
}

```

### 2. Update Google Drive Backup (Backend Flavor)

**File**: `lib/services/google_services.dart`

The backend is already configured to use Gmail & Drive integration.

### 3. Build and Deploy Updated APK

```bash
cd /mnt/Storage/Projects/flutterpos
./build_flavors.sh pos release
./build_flavors.sh backend release

```

---

## 🔍 Testing & Verification

### Check Service Status

```bash

# View all running containers

docker-compose ps


# Check Cloudflare Tunnel logs

docker-compose logs cloudflared --tail 50


# Check Traefik logs

docker-compose logs traefik --tail 50


# Check Appwrite logs

docker-compose logs appwrite --tail 50

```

### Test External Access (After DNS Propagation)

```bash

# Test from external network or phone

curl -I https://appwrite.extropos.org
curl -I https://backend.extropos.org
curl -I https://cloud.extropos.org
curl -I https://mail.extropos.org

```

### Access Dashboards

- **Traefik Dashboard**: <http://localhost:8081>

- **Appwrite Console**: <https://appwrite.extropos.org> (after DNS)

- **RabbitMQ Console**: <https://mail.extropos.org> (after DNS)

  - Default credentials: guest/guest

- **Nextcloud**: <https://cloud.extropos.org> (after DNS)

---

## 🛠️ Maintenance Commands

### Start All Services

```bash
cd /mnt/Storage/Projects/flutterpos/docker
docker-compose up -d

```

### Stop All Services

```bash
docker-compose down

```

### Restart Specific Service

```bash
docker-compose restart cloudflared
docker-compose restart traefik
docker-compose restart appwrite

```

### View Logs

```bash
docker-compose logs -f cloudflared
docker-compose logs -f traefik
docker-compose logs -f appwrite

```

### Update Services

```bash
docker-compose pull
docker-compose up -d

```

### Backup Data

```bash

# Backup all volumes

docker run --rm -v docker_appwrite-mariadb:/data -v $(pwd)/backups:/backup alpine tar czf /backup/appwrite-db-$(date +%Y%m%d).tar.gz /data


# Backup Nextcloud

docker run --rm -v docker_nextcloud:/data -v $(pwd)/backups:/backup alpine tar czf /backup/nextcloud-$(date +%Y%m%d).tar.gz /data

```

---

## 🔐 Security Considerations

### ✅ Implemented

- [x] HTTPS encryption via Cloudflare

- [x] URL-encoded database passwords

- [x] Cloudflare Tunnel (no open ports)

- [x] Traefik reverse proxy

- [x] Private Docker networks

### 🚧 Recommended Additions

- [ ] Enable Cloudflare WAF rules

- [ ] Set up database regular backups

- [ ] Configure fail2ban for SSH

- [ ] Enable Cloudflare Access for admin dashboards

- [ ] Set up monitoring/alerting (Grafana + Prometheus)

- [ ] Regular security updates for Docker images

---

## 📊 Network Architecture

```
Internet
    ↓
Cloudflare Edge (SSL Termination)
    ↓
Cloudflare Tunnel (cloudflared)
    ↓
Traefik Reverse Proxy (172.21.0.3:80)
    ↓
┌─────────────────────────────────────┐
│  Docker Internal Networks           │
├─────────────────────────────────────┤
│  proxy network (172.21.0.0/16)      │
│  ├── Traefik                        │
│  ├── Cloudflared                    │
│  └── FlutterPOS Backend             │
│                                     │
│  appwrite network (172.20.0.0/16)   │
│  ├── Appwrite                       │
│  ├── MariaDB                        │
│  ├── Redis                          │
│  ├── InfluxDB                       │
│  ├── Telegraf                       │
│  └── MinIO                          │
│                                     │
│  nextcloud network (172.22.0.0/16)  │
│  ├── Nextcloud                      │
│  ├── MariaDB                        │
│  └── Redis                          │
│                                     │
│  rabbitmq network (172.23.0.0/16)   │
│  └── RabbitMQ                       │
└─────────────────────────────────────┘

```

---

## 🎯 Success Criteria

- [x] Docker Compose installed and configured

- [x] All services running without errors

- [x] Cloudflare Tunnel connected (4 active connections)

- [x] DNS records configured and propagating

- [x] HTTPS enabled for all endpoints

- [x] Traefik routing configured

- [x] Database connections working

- [ ] External HTTPS access verified (pending DNS propagation)

- [ ] Mobile app updated with new endpoint

- [ ] End-to-end testing complete

---

## 📞 Troubleshooting

### DNS Not Resolving

```bash

# Check current nameservers

curl -s "https://dns.google/resolve?name=extropos.org&type=NS" | grep data


# Should show: phoenix.ns.cloudflare.com, venkat.ns.cloudflare.com

```

### Tunnel Connection Issues

```bash

# Check tunnel status

docker-compose logs cloudflared | grep "Registered tunnel"


# Should show 4 registered connections to kul01/sin12

```

### Service Not Accessible

```bash

# Check Traefik routing

docker-compose logs traefik | grep -i error


# Check service is running

docker-compose ps | grep appwrite

```

---

## 📚 Documentation References

- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

- [Traefik Documentation](https://doc.traefik.io/traefik/)

- [Appwrite Docs](https://appwrite.io/docs)

- [Docker Compose Reference](https://docs.docker.com/compose/)

- [FlutterPOS Copilot Instructions](../.github/copilot-instructions.md)

---

**Deployment completed successfully! 🚀**

Wait 5-15 minutes for DNS propagation, then test external access.
