# Appwrite — Self-hosting & Local data storage

This document explains how to run Appwrite on your own machine and store Appwrite's database and object storage on host directories. It also covers useful integration steps for FlutterPOS so your apps can point to a local Appwrite instance instead of Appwrite Cloud.

Summary

- You can run the official Appwrite Docker Compose stack on your machine and map container data paths to host folders (so the database and uploaded files persist on your disk).

- Flutter apps (including your Flutter web app) talk to Appwrite via HTTP(S) — they never access raw DB files — so hosting Appwrite locally means updating your endpoint / project ID / API keys in `lib/services/appwrite_sync_service.dart` or using the backend settings screen.

Why host Appwrite locally?

- Full control of your data and configuration

- No 3rd-party cloud cost or dependency

- Easier testing and debugging in local networks

- Works well with your current Traefik + Cloudflared setup for remote access

Prerequisites

- Docker and Docker Compose installed on your host

- Enough disk space to hold Appwrite storage + DB

- Properly configured firewall or reverse proxy (Traefik + Cloudflared if exposing publicly)

High-level approach

1. Deploy Appwrite with Docker Compose on your machine
2. Replace anonymous volumes with host-mounted directories (or explicit named volumes)
3. Ensure correct permissions and SELinux contexts (if applicable)
4. Configure Traefik/Cloudflared to route traffic to your local Appwrite instance (optional for remote access)
5. Point FlutterPOS backend configuration (settings or `lib/services/appwrite_sync_service.dart`) to the local Appwrite endpoint and credentials

Example: host-mounted Docker Compose snippet (minimal)

```yaml
version: '3.8'
services:
  mariadb:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'appwrite_root_pw'
      MYSQL_DATABASE: 'appwrite'
      MYSQL_USER: 'appwrite'
      MYSQL_PASSWORD: 'appwrite_db_pw'
    volumes:

      - ./appwrite-data/mysql:/var/lib/mysql

  redis:
    image: redis:7
    restart: unless-stopped
    volumes:

      - ./appwrite-data/redis:/data

  storage:
    image: appwrite/storage:latest
    restart: unless-stopped
    volumes:

      - ./appwrite-data/storage:/storage

  appwrite:
    image: appwrite/appwrite:latest
    restart: unless-stopped
    environment:
      _APP_ENV: 'production'
      _APP_OPENSSL_KEY_V1: 'your_random_key'
    depends_on: [mariadb, redis, storage]
    ports:

      - '80:80'    # optional - bind appwrite console/http

      - '443:443'  # optional - TLS

    volumes:

      - ./appwrite-data/config:/etc/appwrite

```text

Notes & warnings


- Always use absolute host paths in production (e.g., `/srv/appwrite/appwrite-data/redis`).

- Adjust container UID/GID ownership if the containers write files as a non-root user; chown the host directories accordingly.

- Keep database/port access internal to Docker networks whenever possible; do not expose the DB port publicly unless you really need to.

Permissions tips


- Create the directories on the host and set ownership to the same UID/GID used by the containers. Example for a typical linux host:


```bash
mkdir -p ~/appwrite-data/{mysql,redis,storage,config}

# Example: chown these to the container user (adjust UID if different)

sudo chown -R 1000:1000 ~/appwrite-data

```text

Traefik & Cloudflared (optional remote access)


- If you already use Traefik + cloudflared (like in this repo), create a static route to forward requests for `appwrite.example.com` to your Appwrite container on port 80/443.

- Use proper TLS, or route traffic through Cloudflare tunnel so the origin doesn't expose ports publicly.

Configuring FlutterPOS to use your local Appwrite

1. Host Appwrite and make sure the console is reachable (e.g. `http://192.168.1.123` or `http://localhost`)
2. Open FlutterPOS Backend → Settings → Appwrite Configuration and set:

   - Endpoint: `http://<your-host-ip>/v1` (or `https://appwrite.yourdomain.com/v1`)

   - Project ID & Database ID: configure or create them in Appwrite Console

   - Save and Test Connection

If you prefer code changes, update the values in `lib/services/appwrite_sync_service.dart`:


```dart
static const String _endpoint = 'http://YOUR_SERVER_IP/v1';
static const String _projectId = 'YOUR_PROJECT_ID';

```text

Creating the `extropos_db` database and required collections


- Follow the existing docs/DOCKER_APPWRITE_SETUP.md step 3 instructions, or use the Appwrite Console API (curl) to create the database and collections listed there.

Migration: exporting data from cloud Appwrite to local

1. Export database using Appwrite's export features or via a DB dump from cloud (if you can access it). If Appwrite backs data to a single database you can export with mysqldump:

   ```bash
   mysqldump -u <user> -p -h <host> <database> > extropos_dump.sql
   ```

1. Copy the object storage files (if possible) and place them under your local storage path (the path you mounted to `./appwrite-data/storage`).
2. Import DB dump into your local DB container:

   ```bash
   docker cp ./extropos_dump.sql <mariadb-container>:/tmp/extropos_dump.sql
   docker exec -it <mariadb-container> bash -c "mysql -u appwrite -pappwrite_db_pw appwrite < /tmp/extropos_dump.sql"
   ```

Backups & DR (must-have)

- Schedule nightly DB exports and copy storage to off-host backup (S3 or another server).

- Example backup script (cron-friendly) pseudocode:

```bash
docker exec -i mariadb mysqldump -u appwrite -pPASSWORD appwrite > /backups/extropos_$(date +%F).sql
tar -czf /backups/extropos-storage-$(date +%F).tar.gz -C /path/to/appwrite-data/storage .

# Copy backups off-host (S3 / remote host)

```text

Troubleshooting checklist


- Do a health check: `curl http://localhost/v1/health/version`

- If the console is unreachable, check `docker ps` and container logs: `docker logs appwrite` and `docker logs mariadb`.

- File permissions: check the owner and permission bits of your host-mounted folders.

Security recommendations


- Do not expose MariaDB, Redis, or internal services to the public internet. Keep them on an internal Docker network.

- Use HTTPS fronting (Traefik + Let's Encrypt) or Cloudflare Tunnel to secure external access.

- Rotate secrets and store them in environment variables or an external secret manager.

Next steps / Good to have


- Add automated migration and provisioning scripts for tenant onboarding (when you move to multi-tenant)

- Consider S3 or a managed DB for production-scale reliability

References


- Appwrite Docker docs: <https://appwrite.io/docs/installation>

- Your project's docs/DOCKER_APPWRITE_SETUP.md (already in this repo) — follow the 'Create Database' step and collections section.

---
End of document — created for this repository to support Appwrite self-hosting and integration with FlutterPOS.
