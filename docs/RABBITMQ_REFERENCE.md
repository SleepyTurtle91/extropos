# RabbitMQ License-Key Sync - Quick Reference Card

## 🔌 Connection Settings

### Backend App (on PC)

```text
Host: localhost
Port: 5672
Username: posadmin
Password: changeme_secure_password

```text


### POS App (on Android device)



```text
Host: 192.168.1.234  (your PC's IP - run 'hostname -I')

Port: 5672
Username: posadmin
Password: changeme_secure_password

```text

---


## 🚀 Quick Start (3 Steps)



### 1. Start RabbitMQ



```bash
cd /home/abber/Documents/flutterpos/docker
./start-rabbitmq.sh
./test-connectivity.sh

```text


### 2. Configure Backend



```text
flutter run -d linux lib/main_backend.dart
→ Menu → RabbitMQ Settings → Test Connection → Enable Sync
→ Menu → Target POS Terminals → Add license key

```text


### 3. Configure POS



```text
Install APK → Activate license → Settings → RabbitMQ
→ Host: 192.168.1.234 → Test Connection → Enable Sync

```text

---


## 📊 Verify Setup



### Check RabbitMQ Status



```bash
cd docker
./status.sh
./test-connectivity.sh

```text


### Check Network Access



```bash
sudo netstat -tlnp | grep 5672

# Should show: 0.0.0.0:5672

```text


### Management UI



```text
http://192.168.1.234:15672
Login: posadmin / changeme_secure_password

```text

---


## 🧪 Test Sync


1. **Backend**: Edit product → Change price → Save
2. **POS**: Product updates automatically within 2 seconds
3. **Verify**: Check RabbitMQ UI → Connections (should be 2)

---


## 🔧 Troubleshooting



### POS Can't Connect


- Check PC IP: `hostname -I`

- Ping from POS: `ping 192.168.1.234`

- Firewall: `sudo firewall-cmd --list-ports` (should show 5672/tcp)


### Sync Not Working


- Verify license key in Backend → Target POS Terminals

- Check RabbitMQ UI → Queues (should see `pos_queue_<KEY>`)

- Check Backend logs when saving product

---


## 📱 Install APK



```bash

# Wireless ADB

adb connect 192.168.1.80:42279
adb install build/app/outputs/flutter-apk/app-posapp-release.apk
adb install build/app/outputs/flutter-apk/app-backendapp-release.apk

```text

---


## 🎯 Architecture



```text
Backend → Publish: license.<TARGET_KEY>.product_update
    ↓
RabbitMQ Topic Exchange (pos_license_events)
    ↓
POS → Subscribe: license.<MY_KEY>.#
    ↓
Database Update → UI Refresh

```text

---


## 📚 Documentation


- **Full Guide**: `docs/RABBITMQ_LICENSE_KEY_INTEGRATION.md`

- **Quick Start**: `docs/RABBITMQ_QUICKSTART.md`

- **Implementation**: `docs/IMPLEMENTATION_COMPLETE.md`

---


## ✨ Key Files


**Services**:


- `lib/services/rabbitmq_publisher_service.dart` (Backend)

- `lib/services/rabbitmq_subscriber_service.dart` (POS)

- `lib/services/rabbitmq_config_service.dart` (Both)

**Screens**:


- `lib/screens/rabbitmq_settings_screen.dart` (Both)

- `lib/screens/rabbitmq_license_targets_screen.dart` (Backend only)

**Scripts**:


- `docker/start-rabbitmq.sh`

- `docker/stop-rabbitmq.sh`

- `docker/configure-firewall.sh`

- `docker/test-connectivity.sh`

---


## 🔒 Production Checklist


- [ ] Change RabbitMQ password in `docker-compose.yml`

- [ ] Enable TLS/SSL (`docker-compose-tls.yml`)

- [ ] Set up Cloudflare Tunnel (or VPN)

- [ ] Restrict firewall to known IPs

- [ ] Configure monitoring/alerts

- [ ] Document backup procedures

---

**Status**: ✅ All tasks complete, ready for testing!
