# RabbitMQ License Key Integration Plan

## Goal

Connect Backend and POS flavors through RabbitMQ using **offline license keys** as unique routing identifiers for tenant isolation. Support cross-network connectivity (Backend and POS on different networks).

---

## Architecture Overview

### Exchange Pattern

**Topic Exchange**: `pos_license_events`

### Routing Key Format

```text
license.<LICENSE_KEY>.<message_type>

```text

Examples:


- `license.EXTRO-1MTR-9F2A-0000-X7Y9.product_update`

- `license.EXTRO-LIFE-ABC1-2345-WXYZ.category_update`

- `license.EXTRO-3MTR-DEF4-5678-QRST.price_update`


### Binding Pattern (POS Subscriber)



```text
license.<MY_LICENSE_KEY>.#

```text

This ensures each POS only receives messages for its own license key.


### Message Flow



```text
Backend (Publisher)
    │
    ├─> Selects target license key(s)
    ├─> Publishes to: license.TARGET_LICENSE.product_update
    │
    v
RabbitMQ Topic Exchange (pos_license_events)
    │
    ├─> Routes based on license key pattern
    │
    v
POS (Subscriber)
    │
    ├─> Queue: pos_queue_<LICENSE_KEY>
    ├─> Binding: license.<MY_LICENSE_KEY>.#
    └─> Consumes only its own messages

```text

---


## Phase 1: RabbitMQ Configuration for Cross-Network Access



### Current Setup (localhost only)



```yaml

# docker/rabbitmq/docker-compose.yml

ports:

  - "5672:5672"   # AMQP - localhost only

  - "15672:15672" # Management UI - localhost only

```text


### Updated Setup (network-accessible)



```yaml

# docker/rabbitmq/docker-compose.yml

ports:

  - "0.0.0.0:5672:5672"   # AMQP - all interfaces

  - "0.0.0.0:15672:15672" # Management UI - all interfaces

environment:
  RABBITMQ_DEFAULT_USER: posadmin
  RABBITMQ_DEFAULT_PASS: changeme_secure_password  # CHANGE THIS IN PRODUCTION!

```text


### Firewall Configuration (Linux - Fedora)



```bash

# Allow RabbitMQ ports through firewall

sudo firewall-cmd --permanent --add-port=5672/tcp
sudo firewall-cmd --permanent --add-port=15672/tcp
sudo firewall-cmd --reload

```text


### Connection from Different Networks


- **Backend**: Can be on PC (e.g., `192.168.1.100`)

- **POS**: Can be on tablet (e.g., `192.168.1.50`) or different network via internet

- **RabbitMQ Host**: Use public IP or domain name (e.g., `sync.yourcompany.com`)

**Production Recommendation**: Use NGINX reverse proxy or Cloudflare Tunnel for secure external access.

---


## Phase 2: Backend Publisher Implementation



### Service: RabbitMQPublisherService (Already Exists)



#### Current Status


- ✅ Service exists: `lib/services/rabbitmq_publisher_service.dart`

- ✅ Methods exist: `publishProductUpdate()`, `publishCategoryUpdate()`, `publishPriceUpdate()`, `publishProductDelete()`

- ⚠️ Not integrated with actual save operations


#### Enhancement Needed: Target License Selection


**Add to RabbitMQConfigService**:


```dart
// lib/services/rabbitmq_config_service.dart
class RabbitMQConfigService {
  // ... existing code ...
  
  // New: Store list of target license keys for sync
  static const String _targetLicenseKeysKey = 'rabbitmq_target_license_keys';
  
  Future<List<String>> getTargetLicenseKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_targetLicenseKeysKey) ?? [];
  }
  
  Future<void> setTargetLicenseKeys(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_targetLicenseKeysKey, keys);
  }
  
  Future<void> addTargetLicenseKey(String key) async {
    final keys = await getTargetLicenseKeys();
    if (!keys.contains(key)) {
      keys.add(key);
      await setTargetLicenseKeys(keys);
    }
  }
  
  Future<void> removeTargetLicenseKey(String key) async {
    final keys = await getTargetLicenseKeys();
    keys.remove(key);
    await setTargetLicenseKeys(keys);
  }
}

```text


#### Integration Points


**1. Items Management Screen** (`lib/screens/items_management_screen.dart`)


```dart
// After saving product
final success = await DatabaseService.instance.updateItem(editedItem);
if (success) {
  // NEW: Publish to RabbitMQ
  if (RabbitMQPublisherService.instance.isConnected) {
    final targetKeys = await RabbitMQConfigService().getTargetLicenseKeys();
    for (final licenseKey in targetKeys) {
      await RabbitMQPublisherService.instance.publishProductUpdate(
        licenseKey: licenseKey,
        productId: editedItem.id,
        productName: editedItem.name,
        price: editedItem.price,
        categoryId: editedItem.categoryId,
      );
    }
  }
  // ... existing refresh logic
}

```text

**2. Categories Management Screen** (`lib/screens/categories_management_screen.dart`)


```dart
// After saving category
final success = await DatabaseService.instance.updateCategory(editedCategory);
if (success) {
  // NEW: Publish to RabbitMQ
  if (RabbitMQPublisherService.instance.isConnected) {
    final targetKeys = await RabbitMQConfigService().getTargetLicenseKeys();
    for (final licenseKey in targetKeys) {
      await RabbitMQPublisherService.instance.publishCategoryUpdate(
        licenseKey: licenseKey,
        categoryId: editedCategory.id,
        categoryName: editedCategory.name,
      );
    }
  }
  // ... existing refresh logic
}

```text

**3. Bulk Price Update** (if exists)


```dart
// After bulk price changes
for (final licenseKey in targetKeys) {
  await RabbitMQPublisherService.instance.publishPriceUpdate(
    licenseKey: licenseKey,
    productId: item.id,
    newPrice: item.price,
  );
}

```text

---


## Phase 3: POS Subscriber Implementation



### Service: RabbitMQSubscriberService (Already Exists)



#### Current Status


- ✅ Service exists: `lib/services/rabbitmq_subscriber_service.dart`

- ✅ Auto-subscribes using license key from `LicenseService`

- ✅ Creates exclusive queue: `pos_queue_<LICENSE_KEY>`

- ✅ Binding pattern: `license.<LICENSE_KEY>.#`

- ✅ Message stream available


#### Enhancement Needed: Auto-Connection on App Start


**Update main.dart**:


```dart
// lib/main.dart - After license activation check

if (licenseService.isActivated) {
  // Initialize RabbitMQ subscriber
  final rabbitmqConfig = RabbitMQConfigService();
  if (await rabbitmqConfig.isEnabled() && await rabbitmqConfig.isAutoConnectEnabled()) {
    try {
      await RabbitMQSubscriberService.instance.connect();
      developer.log('🐰 RabbitMQ subscriber connected successfully');
    } catch (e) {
      developer.log('⚠️ RabbitMQ subscriber connection failed: $e');
      // Don't block app startup if sync fails
    }
  }
}

```text


#### Sync Handler Enhancement


**Current**: `lib/services/rabbitmq_sync_handler.dart` handles messages
**Enhancement**: Add visual feedback for sync events


```dart
// lib/services/rabbitmq_sync_handler.dart
class RabbitMQSyncHandler {
  // Add notification callback
  static Function(String message)? onSyncNotification;
  
  static Future<void> handleMessage(Map<String, dynamic> message) async {
    final messageType = message['type'] as String?;
    
    // Notify UI
    onSyncNotification?.call('Syncing ${messageType ?? 'data'}...');
    
    // ... existing handling logic ...
    
    // Notify completion
    onSyncNotification?.call('Sync complete!');
  }
}

```text

**UI Integration** (in UnifiedPOSScreen or similar):


```dart
@override
void initState() {
  super.initState();
  
  // Listen for sync notifications
  RabbitMQSyncHandler.onSyncNotification = (message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  };
}

```text

---


## Phase 4: Backend UI - Target License Selection



### New Screen: License Target Selection


**File**: `lib/screens/rabbitmq_license_targets_screen.dart`


```dart
import 'package:flutter/material.dart';
import '../services/rabbitmq_config_service.dart';
import '../services/license_key_generator.dart';

class RabbitMQLicenseTargetsScreen extends StatefulWidget {
  const RabbitMQLicenseTargetsScreen({super.key});

  @override
  State<RabbitMQLicenseTargetsScreen> createState() => _RabbitMQLicenseTargetsScreenState();
}

class _RabbitMQLicenseTargetsScreenState extends State<RabbitMQLicenseTargetsScreen> {
  final _configService = RabbitMQConfigService();
  List<String> _targetKeys = [];
  final _newKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTargetKeys();
  }

  Future<void> _loadTargetKeys() async {
    final keys = await _configService.getTargetLicenseKeys();
    setState(() => _targetKeys = keys);
  }

  Future<void> _addLicenseKey() async {
    final key = _newKeyController.text.trim();
    if (key.isEmpty) return;

    // Validate license key format
    if (!LicenseKeyGenerator.validateKey(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid license key format')),
      );
      return;
    }

    await _configService.addTargetLicenseKey(key);
    _newKeyController.clear();
    await _loadTargetKeys();
  }

  Future<void> _removeLicenseKey(String key) async {
    await _configService.removeTargetLicenseKey(key);
    await _loadTargetKeys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RabbitMQ Target POS Terminals'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add license keys of POS terminals you want to sync with. '
                    'When you update products/categories, changes will be pushed to these terminals.',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          
          // Add new license key
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newKeyController,
                    decoration: InputDecoration(
                      labelText: 'License Key',
                      hintText: 'EXTRO-XXXX-XXXX-XXXX-XXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addLicenseKey,
                  icon: Icon(Icons.add),
                  label: Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // List of target keys
          Expanded(
            child: _targetKeys.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.devices_other, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No target POS terminals configured',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _targetKeys.length,
                    itemBuilder: (context, index) {
                      final key = _targetKeys[index];
                      final licenseType = LicenseKeyGenerator.getLicenseType(key);
                      final isExpired = LicenseKeyGenerator.isExpired(key);
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isExpired 
                                ? Colors.red 
                                : const Color(0xFF2563EB),
                            child: Icon(
                              isExpired ? Icons.error_outline : Icons.smartphone,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            key,
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                          subtitle: Text(
                            'Type: $licenseType${isExpired ? ' (EXPIRED)' : ''}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeLicenseKey(key),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

```text


### Add Menu Item to Backend Home Screen


**File**: `lib/screens/backend_home_screen.dart`

Add after RabbitMQ Settings menu item:


```dart
_buildMenuTile(
  icon: Icons.devices,
  title: 'Target POS Terminals',
  subtitle: 'Configure which terminals receive sync updates',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RabbitMQLicenseTargetsScreen(),
      ),
    );
  },
),

```text

---


## Phase 5: Cross-Network Connectivity Setup



### Option 1: Same Local Network (Easiest)


- Backend PC: `192.168.1.100` (runs RabbitMQ Docker)

- POS Tablet: `192.168.1.50`

- **RabbitMQ Host**: `192.168.1.100` (Backend PC's IP)

**POS Settings**:


```text
Host: 192.168.1.100
Port: 5672
Username: posadmin
Password: changeme_secure_password

```text


### Option 2: Different Networks (Internet)



#### A. Port Forwarding (Home/Small Office)


1. Configure router to forward port 5672 → Backend PC
2. Use public IP or DDNS (e.g., `myshop.ddns.net`)

**POS Settings**:


```text
Host: myshop.ddns.net
Port: 5672

```text


#### B. Cloudflare Tunnel (Recommended for Production)


1. Install Cloudflare Tunnel on Backend PC
2. Expose RabbitMQ through tunnel: `rabbitmq.yourshop.com`
3. Free, secure, no port forwarding needed

**Setup**:


```bash

# On Backend PC

cloudflared tunnel create flutterpos-rabbitmq
cloudflared tunnel route dns flutterpos-rabbitmq rabbitmq.yourshop.com
cloudflared tunnel run flutterpos-rabbitmq

```text

**Config** (`~/.cloudflared/config.yml`):


```yaml
tunnel: flutterpos-rabbitmq
credentials-file: /home/user/.cloudflared/tunnel-credentials.json

ingress:

  - hostname: rabbitmq.yourshop.com
    service: tcp://localhost:5672

  - service: http_status:404

```text

**POS Settings**:


```text
Host: rabbitmq.yourshop.com
Port: 5672

```text


#### C. VPN (Most Secure)


- Use Tailscale/ZeroTier for private network

- All devices get virtual IPs (e.g., `100.64.1.1`)

- No port forwarding, encrypted

---


## Phase 6: Testing Checklist



### Local Network Test


- [ ] Backend connected to RabbitMQ (localhost)

- [ ] POS connected to RabbitMQ (Backend PC's IP)

- [ ] Edit product in Backend

- [ ] Verify POS receives update within 2 seconds

- [ ] Check RabbitMQ Management UI shows active connections


### Cross-Network Test


- [ ] Backend on WiFi, POS on mobile data

- [ ] Use public IP/domain for RabbitMQ host

- [ ] Verify connection works

- [ ] Test with firewall enabled

- [ ] Measure latency (should be <500ms)


### Multi-Tenant Test


- [ ] Activate 2 POS devices with different license keys

- [ ] Configure Backend to target only License Key A

- [ ] Update product in Backend

- [ ] Verify only POS A receives update, POS B does not

- [ ] Switch target to License Key B, verify isolation

---


## Security Considerations



### Production Deployment


1. **Change Default Password**:

   ```yaml
   RABBITMQ_DEFAULT_PASS: <GENERATE_STRONG_PASSWORD>
   ```

1. **Enable TLS/SSL**:

   - Use `docker-compose-tls.yml` (already exists)

   - Get SSL certificate (Let's Encrypt)

   - Update POS settings to use `amqps://` instead of `amqp://`

2. **Firewall Rules**:

   - Only allow connections from known IP ranges

   - Block management UI (port 15672) from public internet

3. **License Key Validation**:

   - Backend validates license keys before adding to targets

   - Reject expired/invalid keys

---

## Implementation Order

### Week 1: Foundation

1. ✅ Update RabbitMQ docker-compose.yml for network access
2. ✅ Configure firewall rules
3. ✅ Test local network connectivity

### Week 2: Backend Integration

1. ⬜ Add target license key management to RabbitMQConfigService
2. ⬜ Create RabbitMQLicenseTargetsScreen UI
3. ⬜ Integrate publish calls into items_management_screen.dart
4. ⬜ Integrate publish calls into categories_management_screen.dart

### Week 3: POS Integration

1. ⬜ Add auto-connect logic to main.dart
2. ⬜ Enhance RabbitMQSyncHandler with UI notifications
3. ⬜ Add sync status indicator to POS AppBar

### Week 4: Testing & Production

1. ⬜ Test same-network connectivity
2. ⬜ Test cross-network connectivity
3. ⬜ Test multi-tenant isolation
4. ⬜ Deploy with TLS/SSL
5. ⬜ Production hardening

---

## Expected Outcomes

✅ **Backend**:

- Can select which POS terminals to sync with (by license key)

- Automatically publishes updates when saving products/categories

- Connection status visible in settings

✅ **POS**:

- Auto-connects to RabbitMQ on app start (if configured)

- Receives only updates for its own license key

- Shows sync status in AppBar (🟢 Live / 🔴 Offline)

- Displays toast notifications when sync occurs

✅ **Cross-Network**:

- Works across different WiFi networks

- Works when POS is on mobile data

- Supports internet-based connectivity via public IP/domain

✅ **Security**:

- Each POS only receives its own data (tenant isolation)

- License key validation prevents unauthorized access

- Optional TLS encryption for production
