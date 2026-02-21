# Nextcloud Multi-User Setup Guide

**Purpose**: Allow each restaurant/business to have their own isolated Nextcloud account for database backups.

**Date**: November 28, 2025  
**Version**: 1.0.14+14

---

## 🎯 Overview

Instead of sharing one admin account, each business owner/manager gets:

- ✅ Their own email-based login (e.g., <owner@restaurant.com>)

- ✅ Isolated storage folder (can't see other users' backups)

- ✅ Individual quota limits

- ✅ Personal app passwords for FlutterPOS app

- ✅ Separate access control

---

## 📋 Setup Methods

### Method 1: Manual User Creation (Web UI)

**Best for**: Small deployments (1-10 users)

#### Step 1: Login as Admin

1. Open <http://192.168.1.234:8080>
2. Login: `admin` / `admin123`

#### Step 2: Create New User

1. Click **Profile Icon** (top right) → **Users**

2. Click **+ New user** button

3. Fill in:

   - **Username**: `restaurant1` (or owner's email)

   - **Display Name**: `Restaurant One Owner`

   - **Email**: `owner@restaurant1.com` (real email for password reset)

   - **Password**: Generate strong password

   - **Groups**: Create group "POS Users" (optional)

   - **Quota**: Set limit (e.g., 10GB, 50GB, or Unlimited)

4. Click **Create**

#### Step 3: Generate App Password

1. Login as the new user (<owner@restaurant1.com>)
2. Go to **Settings** → **Security** → **Devices & sessions**

3. Under "App passwords", enter name: `FlutterPOS Backend`
4. Click **Create new app password**
5. **Copy the generated password** (e.g., `xxxxx-xxxxx-xxxxx-xxxxx-xxxxx`)

6. Give this to the restaurant owner

#### Step 4: Create User's Backup Folder

1. Login as the new user
2. Click **Files** (top left)

3. Click **+ New** → **New folder**

4. Name it: `flutterpos_backups`
5. This is their private backup location

---

### Method 2: Automated User Creation (OCC Command)

**Best for**: Bulk setup (10+ users)

#### Using Docker OCC Tool

```bash

# Create a new user

docker exec -u www-data nextcloud php occ user:add \
  --password-from-env \
  --display-name="Restaurant One Owner" \
 Provides a free subdomain like `extropos.duckdns.org` and an easy token-based update API.
  restaurant1


# Set quota (10GB)



# Set email

```text


#### Bulk User Creation Script


Create `docker/create-nextcloud-users.sh`:


```bash
#!/bin/bash

# Bulk create Nextcloud users for FlutterPOS


USERS=(
  "restaurant1:owner1@example.com:Restaurant One"
  "restaurant2:owner2@example.com:Restaurant Two"
  "cafe1:cafe@example.com:Cafe ABC"
)

for user_data in "${USERS[@]}"; do
  IFS=':' read -r username email display_name <<< "$user_data"
  
  echo "Creating user: $username ($display_name)"
  
  # Create user (will prompt for password)

  docker exec -it -u www-data nextcloud php occ user:add \
    --display-name="$display_name" \
    --group="pos-users" \
    "$username"
  
  # Set email

  docker exec -u www-data nextcloud php occ user:setting \
    "$username" settings email "$email"
  
  # Set 50GB quota

  docker exec -u www-data nextcloud php occ user:setting \
    "$username" files quota "50 GB"
  
  echo "✅ User $username created"
  echo ""
done

echo "🎉 All users created!"
echo ""
echo "📧 Send each user:"
echo "   1. Server URL: https://extropos.duckdns.org (or http://192.168.1.234:8080 for LAN)"
echo "   2. Username: (their username)"
echo "   3. Password: (set during creation)"
echo "   4. Instructions: Login → Security → Create App Password for FlutterPOS"

```text

---


## 🔧 FlutterPOS App Configuration (Per User)



### Backend App Setup


Each restaurant owner configures their **own** credentials:

1. **Open Backend App** → **Nextcloud Settings**

2. **Fill in Connection Details**:

   ```

   Server URL:    <https://extropos.duckdns.org> (or <http://192.168.1.234:8080> for LAN)
   Username:      restaurant1            (or their email)
   App Password:  xxxxx-xxxxx-xxxxx-xxxxx-xxxxx  (from Nextcloud)
   Backup Path:   /flutterpos_backups    (their private folder)

   ```

3. **Test Connection** → Should show ✅ Success

4. **Enable Options**:

   - ✅ Use Nextcloud for Backups

   - ✅ Auto Backup Daily (optional)

5. **Upload First Backup** → Click "Upload Backup Now"

6. **Verify in Nextcloud**:

   - Login to web UI

   - Check Files → flutterpos_backups

   - Should see: `flutterpos_backup_YYYYMMDD_HHMMSS.db`

---


## 🔒 Data Isolation



### How Isolation Works



```text
/mnt/storage/nextcloud/data/
│   └── files/
├── restaurant1/               # Restaurant 1's isolated storage

│   └── files/
│       └── flutterpos_backups/
│           ├── flutterpos_backup_20251128_100000.db
│           └── flutterpos_backup_20251128_110000.db
├── restaurant2/               # Restaurant 2's isolated storage

│   └── files/
│       └── flutterpos_backups/
│           └── flutterpos_backup_20251128_120000.db
└── cafe1/                     # Cafe's isolated storage

    └── files/
        └── flutterpos_backups/
            └── flutterpos_backup_20251128_130000.db

```text

**Key Points**:


- ✅ Each user can **only** see their own files

- ✅ No cross-contamination of backups

- ✅ Admin can see all files (for management)

- ✅ Disk quota prevents one user from filling storage

---


## 📊 User Management



### List All Users



```bash
docker exec -u www-data nextcloud php occ user:list

```text


### Check User's Quota



```bash
docker exec -u www-data nextcloud php occ user:info restaurant1

```text


### Set Quota



```bash

# Set 100GB limit

docker exec -u www-data nextcloud php occ user:setting \
  restaurant1 files quota "100 GB"


# Set unlimited

docker exec -u www-data nextcloud php occ user:setting \
  restaurant1 files quota "none"

```text


### Reset User Password



```bash
docker exec -it -u www-data nextcloud php occ user:resetpassword restaurant1

```text


### Delete User (and their backups)



```bash

# ⚠️ WARNING: This deletes all user data!




### 1. Use Real Emails

- Set real email addresses for password reset

- Users can recover access if they forget password


### 2. Enforce Strong Passwords

Enable in Nextcloud admin:

- Settings → Security → Password policy

- Minimum length: 12 characters


### 3. Use App Passwords (Not Main Password)

- **Never** give main Nextcloud password to FlutterPOS app

- Always generate app passwords for each device

- Protects against unauthorized admin access


### 5. Set Appropriate Quotas

Prevent storage abuse:

```bash

# Small restaurant: 10GB

# Medium restaurant: 50GB

# Large chain: 200GB

# Unlimited: Only for trusted users

```text

---


## 📧 Email Template for New Users


Send this to each restaurant owner:


```text
Subject: Your FlutterPOS Cloud Backup Access

Hello [Restaurant Name],

Your cloud backup account has been created!

🌐 Server URL: http://192.168.1.234:8080
👤 Username: [restaurant1]
🔑 Temporary Password: [password]

📱 Setup Instructions:

1. Login to Nextcloud web:

   - Open: http://192.168.1.234:8080

   - Username: [restaurant1]

   - Password: [password]

   - Change password on first login!

2. Generate App Password for FlutterPOS:

   - Click your profile icon (top right)

   - Settings → Security → Devices & sessions

   - Under "App passwords", enter: "FlutterPOS Backend"

   - Click "Create new app password"

   - **Copy the generated password** (5 groups of letters)

3. Configure FlutterPOS Backend App:

   - Open Backend app → Menu → Nextcloud Settings

   - Server URL: http://192.168.1.234:8080

   - Username: [restaurant1]

   - App Password: (paste the generated password)

   - Backup Path: /flutterpos_backups

   - Enable "Use Nextcloud for Backups"

   - Click "Upload Backup Now" to test

4. Create your backup folder:

   - In Nextcloud web, click "Files"

   - Click "+ New" → "New folder"

   - Name: flutterpos_backups

✅ Your backups are now secure and private!

📊 Storage Quota: [50 GB]

Need help? Contact support.

Best regards,
FlutterPOS Admin

```text

---


## 🧪 Testing Multi-User Setup



### Test Scenario


1. **Create 2 test users**:

   ```bash
   # User 1

   docker exec -it -u www-data nextcloud php occ user:add test1
   
   # User 2

   docker exec -it -u www-data nextcloud php occ user:add test2
   ```

1. **Login as User 1** → Create folder `/flutterpos_backups`

2. **Login as User 2** → Create folder `/flutterpos_backups`

3. **Configure Backend App for User 1**:

   - Username: test1

   - Upload a backup

4. **Configure Backend App for User 2**:

   - Username: test2

   - Upload a backup

5. **Verify Isolation**:

   - Login to Nextcloud as test1 → Should see only test1's backups

   - Login to Nextcloud as test2 → Should see only test2's backups

   - Login as admin → Should see both users' backups

6. **Test Restore**:

   - User 1 downloads their own backup → ✅ Works

   - User 1 tries to access User 2's folder → ❌ Permission denied

---

## 🚀 Recommended Deployment Workflow

### For 10 Restaurants

1. **Plan User Structure**:

   ```
   restaurant-downtown
   restaurant-uptown
   cafe-central
   bakery-west
   ```

2. **Create All Users** (use bulk script above)

3. **Set Quotas** (based on size):

   - Small (1-2 POS): 10GB

   - Medium (3-5 POS): 50GB

   - Large (6+ POS): 100GB

4. **Generate App Passwords** (one per restaurant)

5. **Send Setup Emails** (use template above)

6. **Schedule Onboarding Calls** (walk through first backup)

7. **Monitor Storage**:

   ```bash
   docker exec -u www-data nextcloud php occ user:report
   ```

---

## 📈 Storage Calculations

### Estimate Backup Sizes

**Per POS Database**:

- Empty: ~500KB

- 100 products, 50 orders: ~2MB

- 1000 products, 500 orders: ~15MB

- 5000 products, 5000 orders: ~80MB

**With Daily Backups (keeping 30 days)**:

- Small restaurant: 2MB × 30 = 60MB/month

- Medium restaurant: 15MB × 30 = 450MB/month

- Large restaurant: 80MB × 30 = 2.4GB/month

**Recommended Quotas**:

- Small: 10GB (6+ years of backups)

- Medium: 50GB (9+ years of backups)

- Large: 100GB (4+ years of backups)

**Total Storage** (473GB available):

- Can support: 40+ restaurants at 10GB each

- Or: 9 large restaurants at 50GB each

---

## 🛠️ Troubleshooting

### User Can't Login

```bash

# Check if user exists

docker exec -u www-data nextcloud php occ user:list | grep username


# Check user status

docker exec -u www-data nextcloud php occ user:info username


# Reset password

docker exec -it -u www-data nextcloud php occ user:resetpassword username

```text


### User Can't Upload Backups


1. **Check quota**:

   ```bash
   docker exec -u www-data nextcloud php occ user:info username
   ```

1. **Check folder permissions**:

   - Login as user in web UI

   - Verify `/flutterpos_backups` exists

   - Check folder is not shared (should be private)

2. **Check app password**:

   - Regenerate app password in Nextcloud web

   - Update in FlutterPOS app

### Storage Full

```bash

# Check overall storage

df -h /mnt/storage


# Check per-user usage

docker exec -u www-data nextcloud php occ user:report


# Clean old backups (manually or script)

```text

---


## ✅ Summary


**Multi-User Benefits**:


- ✅ Data isolation per restaurant

- ✅ Individual access control

- ✅ Quota management

- ✅ Professional setup

- ✅ Scalable to 100+ users

**Each User Gets**:


- Unique login (email-based)

- Private backup folder

- App password for FlutterPOS

- Storage quota limit

- Independent restore capability

**Admin Controls**:


- User creation/deletion

- Quota management

- Password resets

- Access to all backups (for support)

- Usage monitoring

**Ready to deploy!** 🚀

---


## 🌐 External Access & Free Domain (Recommended)


If you want to access Nextcloud from the public internet (not just `localhost` or LAN), you need two things:


- A domain/subdomain that points to your public IP (dynamic IPs need DDNS)

- HTTPS (Let's Encrypt) and proper router/firewall rules


### Best Free Domain / DDNS Providers (Recommended)


- **DuckDNS (duckdns.org)** — Best for simplicity and reliability for home/small deployments. Provides a free subdomain like `extropos.duckdns.org` and an easy token-based update API.

- **Dynu** — Also great for free DDNS subdomains and offers a small UI.

- **No-IP (noip.com)** — Has a free tier; requires periodic confirmation (less convenient but widely used).

- **Freenom** — Free domain registration (.tk/.ml/.ga/.cf/.gq) if you want your own top-level domain but note reliability concerns.

- **Cloudflare (free)** — Not a free domain, but free DNS + proxy (great if you own a domain). Use Cloudflare API to update A record for dynamic IPs.

**Recommendation**: Use **DuckDNS** for a free, easy, and fast setup. If you have a domain and need more control, use **Cloudflare** with the free plan.

---


## 🔧 DuckDNS Quick Setup (CLI)


This example shows how to make your Nextcloud accessible with `extropos.duckdns.org`.

1) Create a DuckDNS account: <https://www.duckdns.org>

   - Register and create a subdomain like `extropos` → `extropos.duckdns.org`.

    - Save the generated token.

2) Update DuckDNS from the shell (one-off test):


```bash
curl "https://www.duckdns.org/update?domains=extropos&token=YOUR_DUCKDNS_TOKEN&ip="

```text

1) Create a systemd timer to keep IP updated (recommended):


```bash
sudo tee /etc/systemd/system/duckdns-update.service >/dev/null <<'EOF'
[Unit]
Description=Update DuckDNS IP

[Service]
Type=oneshot
ExecStart=/usr/bin/curl "https://www.duckdns.org/update?domains=extropos&token=YOUR_DUCKDNS_TOKEN&ip="
EOF

sudo tee /etc/systemd/system/duckdns-update.timer >/dev/null <<'EOF'
[Unit]
Description=Run duckdns update every 5 minutes

[Timer]
OnBootSec=60
OnUnitActiveSec=300
Unit=duckdns-update.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now duckdns-update.timer

```text

1) Test Nextcloud's trusted domain: add the domain into `config.php` (Docker) or via `occ`:


```bash

# Docker

docker exec -u www-data nextcloud php occ config:system:set trusted_domains 2 --value="extropos.duckdns.org"


# Or manually edit

sudo nano /var/www/nextcloud/config/config.php

# Add an entry inside 'trusted_domains' array

```text

1) Certbot (Let's Encrypt) — Apache or Nginx on host (non-docker):


```bash

# For Apache

sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d extropos.duckdns.org


# For Nginx

sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d extropos.duckdns.org

```text

If you use Docker with Traefik or Nginx Proxy Manager, Traefik can handle automatic Let’s Encrypt certs.

1) Firewall: Allow HTTPS only (UFW / Firewalld)


```bash

# Debian/Ubuntu (UFW)

sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw enable


# Fedora (firewalld)

sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

```text

1) Router port-forwarding (OpenWrt example):


```bash

# Forward port 80 and 443 to the Nextcloud box IP

uci add firewall redirect
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='443'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.1.100'
uci set firewall.@redirect[-1].dest_port='443'
uci commit firewall
/etc/init.d/firewall restart

```text

---


## 🔁 Alternative: No-IP/Dynu (DDNS) or Cloudflare (if you own a domain)



### No-IP (free subdomain)



```bash
sudo apt install ddclient  # ddclient supports No-IP

sudo nano /etc/ddclient.conf

# sample lines

protocol=noip
server=dynupdate.no-ip.com
login=your_noip_username
password=your_noip_password
extropos.no-ip.org

sudo systemctl enable --now ddclient

```text


### Cloudflare + your own domain (free tier DNS)


1. Add your domain to cloudflare.com and configure DNS A record to point to your public IP (or proxied “orange cloud”).
2. Use Cloudflare API token and certificated plugin for certbot if you need DNS auth:


```bash
sudo apt install certbot python3-certbot-dns-cloudflare
sudo certbot --dns-cloudflare --dns-cloudflare-credentials ~/cloudflare.ini -d example.com -d www.example.com

```text

Note: Cloudflare's proxy hides your origin IP by default; for Let’s Encrypt, use DNS challenge or configure with the proxy appropriately.

---


## 🐳 Docker / Traefik Example (Recommended for Docker users)


Traefik can obtain certs automatically for `extropos.duckdns.org` and handle routing to your Nextcloud container.

Create Docker network and run traefik:


```bash
docker network create proxy

docker run -d \
   --name traefik \
   --network proxy \
   -p 80:80 -p 443:443 \
   -v /var/run/docker.sock:/var/run/docker.sock \
   -v ./traefik:/etc/traefik \
   traefik:v2.10

```text

Set Nextcloud labels to route via Traefik:


```yaml
labels:

   - traefik.enable=true

   - traefik.http.routers.nextcloud.rule=Host(`extropos.duckdns.org`)

   - traefik.http.routers.nextcloud.tls=true

   - traefik.http.routers.nextcloud.tls.certresolver=letsencrypt

   - traefik.http.services.nextcloud.loadbalancer.server.port=80

```text

Traefik config will automatically generate and renew Let's Encrypt certs.

---


## ⚠️ Security Notes


- Only expose HTTPS (port 443). If you open port 80, redirect it to 443 to avoid exposing plaintext credentials.

- Restrict management access (Nextcloud admin panel) to restricted IPs or use VPN for admin tasks.

- Certificate auto-renewal: verify `certbot renew --dry-run` works or that Traefik's cert resolver is functioning.

- Use Cloudflare Access or VPN if you want to lock down access even further.

---


## ✅ Production-grade Recommended Configuration (Best Practice)


If you want the most secure and production-grade deployment right now, follow these recommendations:

1. Use a reverse-proxy with automatic certificates (Traefik) or a Cloudflare Tunnel to avoid opening ports directly.

   - If you own a domain, prefer DNS challenge (Cloudflare DNS) to issue Let's Encrypt certs without opening ports.

   - If you only have a dynamic IP and no domain, DuckDNS with HTTP challenge works but requires port-forwarding on the router.

2. Use Docker Secrets for production credentials instead of committing `.env` files. A helper script `env-to-docker-secrets.sh` is provided in `docker/nextcloud-traefik`.

   - Replace environment variables referencing passwords with `_FILE` variants in `docker-compose.yml` (e.g., `MYSQL_PASSWORD_FILE=/run/secrets/mysql_password`).

3. Use Cloudflare Tunnel (recommended) or a VPN for admin access.

   - Use Cloudflare Access to restrict admin panel access to a set of IPs or enforced MFA.

4. Harden the host:

   - Setup UFW to only allow 80/443 (or none if using Cloudflare Tunnel)

   - Disable password SSH and use key-based SSH only

   - Monitor logs for repeated failures and use fail2ban or an equivalent service

5. Set `trusted_domains` using `set-trusted-domain.sh` or OCC:

   ```bash
   cd docker/nextcloud-traefik
   ./set-trusted-domain.sh extropos.duckdns.org
   ```

1. Implement a backup retention policy and validate restores periodically (daily incremental, weekly full backups, and monthly archival retention).

2. Monitor and alert for cert expiry & backup failures. We recommend Prometheus + Grafana and alertmanager for production.

See `docker/nextcloud-traefik/DEPLOY.md` for a more detailed step-by-step deployment checklist and guidance on hosting options and using Docker Secrets.

If you are deploying to Fedora and want a single-command setup that also converts `.env` to Docker secrets, starts the stack, and optionally installs Cloudflare Tunnel configs, use:

```bash
cd docker/nextcloud-traefik
sudo ./deploy-fedora.sh --apply --full --cloudflared

```text

The `--full` flag will run the `env-to-docker-secrets.sh` conversion and bring up the stack via `docker compose`. The `--cloudflared` flag copies the sample configuration and systemd service; you must still run `cloudflared login` to authenticate and create the tunnel (interactive step).

---


## ✅ Post-setup Checklist


1. Register DuckDNS or other DDNS and configure automatic updates
2. Add your domain to `trusted_domains` via `occ` or `config.php`
3. Verify router port forward for 443/80
4. Install HTTPS cert via Certbot or Traefik
5. Validate Nextcloud login from external network using that domain
6. Generate app password for FlutterPOS and configure

---

If you want, I can add a sample DuckDNS update systemd unit and service, and extend the repo's docs for Docker/Traefik users with a docker-compose example. I added sample files in `scripts/duckdns/` and a Traefik/Nextcloud example in `docker/nextcloud-traefik/`.


### Shortcuts added in the repo


- `scripts/duckdns/update_duckdns.sh` - a simple updater script

- `scripts/duckdns/duckdns-update.service` - systemd unit to run updater (one-shot)

- `scripts/duckdns/duckdns-update.timer` - systemd timer to run every 5 minutes

- `scripts/duckdns/README.md` - local doc for the updater

- `scripts/duckdns/install-instructions.md` - install and secure steps

- `docker/nextcloud-traefik/` - sample Traefik + Nextcloud `docker-compose.yml` and `traefik.yml` with a LetsEncrypt certresolver

Use the `scripts/duckdns/install-instructions.md` to install and secure the token and enable the timer.
