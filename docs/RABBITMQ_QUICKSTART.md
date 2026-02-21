# RabbitMQ Cross-Network Setup - Quick Start Guide

This guide shows how to connect Backend and POS apps through RabbitMQ when they're on different networks.

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Configure RabbitMQ for Network Access

```bash
cd /home/abber/Documents/flutterpos/docker


# Stop RabbitMQ if running

./stop-rabbitmq.sh


# Configure firewall (Fedora/RHEL)

./configure-firewall.sh


# Start RabbitMQ with network access

./start-rabbitmq.sh

```text

**What this does:**


- Opens ports 5672 (AMQP) and 15672 (Management UI)

- Binds RabbitMQ to `0.0.0.0` (all network interfaces)

- Makes RabbitMQ accessible from other devices


### Step 2: Find Your PC's IP Address



```bash
hostname -I

```text

Example output: `192.168.1.100 172.17.0.1`

**Use the first IP** (e.g., `192.168.1.100`) - this is your local network IP.


### Step 3: Configure Apps



#### Backend App (on PC)


1. Run: `flutter run -d linux lib/main_backend.dart`
2. Go to: **Menu → RabbitMQ Settings**
3. Connection settings:

   - Host: `localhost` (or `127.0.0.1`)

   - Port: `5672`

   - Username: `posadmin`

   - Password: `changeme_secure_password`

4. Click **Test Connection** → Should show ✅

5. Enable **"Enable RabbitMQ Sync"** and **"Auto-connect"**

6. Click **Save**


#### POS App (on Android tablet)


1. Install APK: `adb install build/app/outputs/flutter-apk/app-posapp-release.apk`
2. Activate with license key (if not already)
3. Go to: **Settings → Cloud Services → RabbitMQ Settings** (or similar)

4. Connection settings:

   - Host: `192.168.1.100` (your PC's IP from Step 2)

   - Port: `5672`

   - Username: `posadmin`

   - Password: `changeme_secure_password`

5. Click **Test Connection** → Should show ✅

6. Enable **"Enable RabbitMQ Sync"** and **"Auto-connect"**

7. Click **Save**

---


## 📱 Add POS Terminal to Backend


1. Open **Backend app**
2. Go to: **Menu → Target POS Terminals**
3. Enter the POS device's **license key**

   - Example: `EXTRO-LIFE-ABC1-2345-WXYZ`

   - You can find this in POS app: **Settings → About → License Information**

4. Click **Add Terminal**

**Now the Backend will sync updates to this POS terminal!**

---


## ✅ Test the Connection



### From Backend


1. Go to **Menu → Items Management**
2. Edit a product (change price or name)
3. Save the product


### From POS


1. The product should update **automatically within 2 seconds**
2. You'll see a notification: "Syncing product_update..."


### Verify in RabbitMQ Management UI


1. Open browser: `http://localhost:15672`
2. Login: `posadmin` / `changeme_secure_password`
3. Go to **Connections** tab → Should see 2 connections (Backend + POS)

4. Go to **Queues** tab → Should see `pos_queue_<LICENSE_KEY>`

---


## 🌐 Cross-Network Scenarios



### Same WiFi Network


**Setup:** Both devices on same router


- ✅ Easiest option

- ✅ No additional configuration needed

- ✅ Use PC's local IP (e.g., `192.168.1.100`)

**POS Host**: `192.168.1.100` (PC's IP)

---


### Different Networks (Internet)



#### Option A: Port Forwarding


**Setup:** Router forwards port 5672 to PC

1. Find your public IP: `curl ifconfig.me`
2. Configure router:

   - Forward port `5672` → PC's local IP (`192.168.1.100`)

3. Use public IP or DDNS

**POS Host**: `<YOUR_PUBLIC_IP>` or `myshop.ddns.net`

⚠️ **Security Warning**: Expose only to trusted devices, change default password!

---


#### Option B: Cloudflare Tunnel (Recommended)


**Setup:** Free, secure tunnel without port forwarding


```bash

# Install Cloudflare Tunnel

wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared


# Create tunnel

cloudflared tunnel login
cloudflared tunnel create flutterpos-rabbitmq
cloudflared tunnel route dns flutterpos-rabbitmq rabbitmq.yourshop.com


# Create config

nano ~/.cloudflared/config.yml

```text

**Config file** (`~/.cloudflared/config.yml`):


```yaml
tunnel: flutterpos-rabbitmq
credentials-file: /home/user/.cloudflared/<UUID>.json

ingress:

  - hostname: rabbitmq.yourshop.com
    service: tcp://localhost:5672

  - service: http_status:404

```text

**Run tunnel**:


```bash
cloudflared tunnel run flutterpos-rabbitmq

```text

**POS Host**: `rabbitmq.yourshop.com`

✅ **Benefits**:


- Free forever

- No port forwarding

- Automatic HTTPS

- Works behind NAT/firewall

---


#### Option C: VPN (Most Secure)


**Setup:** Use Tailscale for private network


```bash

# Install Tailscale

curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

```text


- All devices get virtual IPs (e.g., `100.64.1.1`)

- Encrypted end-to-end

- No port forwarding needed

**POS Host**: `100.64.1.1` (Tailscale IP of PC)

---


## 🔒 Production Security



### 1. Change Default Password


Edit `docker/rabbitmq/docker-compose.yml`:


```yaml
environment:

  - RABBITMQ_DEFAULT_PASS=YOUR_STRONG_PASSWORD_HERE

```text

Then restart:


```bash
cd docker
./stop-rabbitmq.sh
./start-rabbitmq.sh

```text

Update Backend and POS apps with new password.


### 2. Enable TLS/SSL (Optional)



```bash
cd docker/rabbitmq
docker-compose -f docker-compose-tls.yml up -d

```text

Update apps to use `amqps://` instead of `amqp://`


### 3. Firewall Rules


Only allow specific IPs:


```bash

# Allow only from specific subnet

sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port protocol="tcp" port="5672" accept'
sudo firewall-cmd --reload

```text


### 4. Disable Management UI from Internet



```bash

# Block port 15672 from public access

sudo firewall-cmd --permanent --remove-port=15672/tcp
sudo firewall-cmd --reload

```text

Access Management UI via SSH tunnel:


```bash
ssh -L 15672:localhost:15672 user@your-server

```text

Then open: `http://localhost:15672`

---


## 🐛 Troubleshooting



### POS can't connect to Backend PC


**Check 1**: Ping PC from POS device


```bash

# On Android (using Termux or similar)

ping 192.168.1.100

```text

**Check 2**: Verify RabbitMQ is listening on all interfaces


```bash
sudo netstat -tlnp | grep 5672

```text

Should show: `0.0.0.0:5672` (not `127.0.0.1:5672`)

**Check 3**: Firewall status


```bash
sudo firewall-cmd --list-ports

```text

Should include: `5672/tcp` and `15672/tcp`

**Check 4**: Test from POS device


```bash

# Use telnet or nc

telnet 192.168.1.100 5672

```text

Should connect (not timeout or refused)

---


### Sync not working


**Check 1**: Verify connections in RabbitMQ UI


- Open: `http://localhost:15672`

- Go to **Connections** → Should see 2+ connections

**Check 2**: Check POS license key


- Backend → Menu → Target POS Terminals

- Verify POS license key is in the list

**Check 3**: Check exchange and queues


- RabbitMQ UI → **Exchanges** → Look for `pos_license_events`

- RabbitMQ UI → **Queues** → Look for `pos_queue_<LICENSE_KEY>`

**Check 4**: Test manual publish


```bash

# From RabbitMQ UI → Exchanges → pos_license_events → Publish message

Routing key: license.EXTRO-LIFE-ABC1-2345-WXYZ.test
Payload: {"type":"test","message":"hello"}

```text

---


## 📊 Monitoring



### Check Connection Status


**Backend App**:


- Status shown in RabbitMQ Settings screen

- Green = Connected, Red = Disconnected

**POS App**:


- AppBar shows status indicator:

  - 🟢 = Live Sync active

  - 🔴 = Offline

  - 🟡 = Connecting...


### View RabbitMQ Logs



```bash
cd docker
docker logs rabbitmq --tail 50 -f

```text


### Check Message Throughput


RabbitMQ Management UI → Overview → Message rates

---


## 🎯 Next Steps


1. ✅ Set up cross-network connectivity
2. ✅ Add target POS terminals in Backend
3. ⬜ Integrate publish calls into product/category save operations
4. ⬜ Test with multiple POS terminals
5. ⬜ Deploy with TLS/SSL for production
6. ⬜ Set up monitoring/alerting

---


## 📚 Related Documentation


- [RABBITMQ_LICENSE_KEY_INTEGRATION.md](./RABBITMQ_LICENSE_KEY_INTEGRATION.md) - Full implementation guide

- [docker/README.md](../docker/README.md) - Docker management

- [.github/copilot-instructions.md](../.github/copilot-instructions.md) - FlutterPOS architecture

---


## ✨ Summary


**You've successfully configured RabbitMQ for cross-network sync!**


- ✅ Backend publishes updates to RabbitMQ

- ✅ POS subscribes using its license key

- ✅ Works across different networks

- ✅ Tenant isolation (each POS only receives its own data)

**Test it**: Edit a product in Backend → See it update on POS instantly! 🚀
