# Multi-Tenant Architecture with License-Key Routing

## 🎯 Overview

This architecture implements **true multi-tenant isolation** using RabbitMQ Topic Exchange with license keys as routing identifiers. Each POS terminal receives only messages intended for its specific license key, ensuring complete data isolation.

## 🏗️ Architecture Diagram

```text
┌─────────────────────────────────────────────────────────────┐
│                    Backend Server                            │
│  ┌──────────────────┐        ┌──────────────────┐          │
│  │  Publisher       │        │  REST API        │          │
│  │  (Topic Exchange)│        │  (Sync Endpoint) │          │
│  └────────┬─────────┘        └────────┬─────────┘          │
│           │                           │                     │
└───────────┼───────────────────────────┼─────────────────────┘
            │                           │
            │ AMQP (5672)               │ HTTP (8080)
            │                           │
    ┌───────▼───────────────────────────▼────────┐
    │      RabbitMQ Topic Exchange               │
    │      Exchange: pos_license_events          │
    │                                            │
    │  Routing Keys:                             │
    │  - license.EXTRO-LIFE-ABC123.price_update  │
    │  - license.EXTRO-LIFE-XYZ789.price_update  │
    │  - license.*.broadcast.system_notice       │
    └───────┬───────────────────────┬────────────┘
            │                       │
┌───────────▼──────────┐  ┌────────▼───────────────┐
│  POS Terminal 1      │  │  POS Terminal 2        │
│  License: ABC123     │  │  License: XYZ789       │
│                      │  │                        │
│  Binding:            │  │  Binding:              │
│  license.ABC123.#    │  │  license.XYZ789.#      │

│                      │  │                        │
│  ✅ Receives: ABC123 │  │  ✅ Receives: XYZ789   │
│  ❌ Blocked: XYZ789  │  │  ❌ Blocked: ABC123    │
└──────────────────────┘  └────────────────────────┘

```text


## 🔑 License-Key Routing Pattern



### Routing Key Format



```text
license.<LICENSE_KEY>.<message_type>

```text

**Examples:**


- `license.EXTRO-LIFE-ABC123.price_update`

- `license.EXTRO-LIFE-ABC123.category_update`

- `license.EXTRO-LIFE-XYZ789.price_update`

- `license.*.broadcast.system_notice` (broadcast to all)


### Binding Pattern


Each POS terminal subscribes with:


```text
license.<MY_LICENSE_KEY>.#

```text

The `#` wildcard matches any message type for that license.


## 📋 Components



### 1. Backend Publisher (`backend_publisher_multitenant.dart`)


**Purpose:** Publishes messages to specific POS terminals by license key

**Key Features:**


- Topic Exchange declaration

- License-key-based routing

- Non-persistent messages (deliveryMode: 1)

- Broadcast capability

**Usage:**


```dart
final publisher = BackendPublisher(
  host: 'localhost',
  port: 5672,
  username: 'posadmin',
  password: 'password',
);

await publisher.connect();

// Send to specific terminal
await publisher.publishPriceUpdate(
  licenseKey: 'EXTRO-LIFE-ABC123',
  productId: 'PROD-001',
  newPrice: 25.99,
);

```text


### 2. REST Sync API (`backend_sync_api.dart`)


**Purpose:** Provides HTTP endpoints for manual synchronization

**Endpoints:**


- `GET /health` - Health check (no auth)

- `GET /api/v1/sync/full_data` - Full sync (products + categories)

- `GET /api/v1/sync/products` - Products only

- `GET /api/v1/sync/categories` - Categories only

**Authentication:**


```text
X-License-Key: EXTRO-LIFE-ABC123

```text

**Usage:**


```bash
curl -H "X-License-Key: EXTRO-LIFE-ABC123" \
  http://localhost:8080/api/v1/sync/full_data

```text


### 3. Frontend Subscriber (`frontend_subscriber_multitenant.dart`)


**Purpose:** Flutter app that receives messages for its license key only

**Key Features:**


- Exclusive queue (auto-delete)

- License-key binding pattern

- Real-time message handling

- Manual sync button

- Visual connection status

**Usage:**


```bash
flutter run -d linux \
  --dart-define=LICENSE_KEY=EXTRO-LIFE-ABC123 \
  examples/rabbitmq/frontend_subscriber_multitenant.dart

```text


## 🚀 Quick Start



### Step 1: Start RabbitMQ



```bash
cd docker/rabbitmq
cp .env.multitenant .env

# Edit .env with secure credentials

docker-compose up -d

```text


### Step 2: Start Sync API Server



```bash
cd examples/rabbitmq


# Add shelf dependencies

# Add to a temporary pubspec.yaml:

# dependencies:

#   shelf: ^1.4.0

#   shelf_router: ^1.1.0

#   http: ^1.1.0


export VALID_LICENSE_KEY=EXTRO-LIFE-ABC123
export PORT=8080
dart run backend_sync_api.dart

```text


### Step 3: Run Frontend (Terminal 1)



```bash
export RABBITMQ_HOST=localhost
export RABBITMQ_PORT=5672
export RABBITMQ_USER=posadmin
export RABBITMQ_PASS=changeme_secure_password
export LICENSE_KEY=EXTRO-LIFE-ABC123
export SYNC_API_URL=http://localhost:8080

flutter run -d linux \
  --dart-define=LICENSE_KEY=EXTRO-LIFE-ABC123 \
  frontend_subscriber_multitenant.dart

```text


### Step 4: Run Frontend (Terminal 2 - Different License)



```bash
export LICENSE_KEY=EXTRO-LIFE-XYZ789

flutter run -d linux \
  --dart-define=LICENSE_KEY=EXTRO-LIFE-XYZ789 \
  frontend_subscriber_multitenant.dart

```text


### Step 5: Send Test Messages



```bash
export RABBITMQ_HOST=localhost
export RABBITMQ_PORT=5672
export RABBITMQ_USER=posadmin
export RABBITMQ_PASS=changeme_secure_password

dart run backend_publisher_multitenant.dart

```text


## 🔒 Security Considerations



### 1. License Key Storage


**❌ Don't:**


```dart
const licenseKey = 'EXTRO-LIFE-ABC123';  // Hardcoded!

```text

**✅ Do:**


```dart
// Use flutter_secure_storage
final storage = FlutterSecureStorage();
final licenseKey = await storage.read(key: 'license_key');

// Or encrypted Hive
final box = await Hive.openBox('secure', encryptionCipher: cipher);
final licenseKey = box.get('license_key');

```text


### 2. API Authentication


Current implementation uses simple header-based auth. For production:


```dart
// Add JWT tokens
Middleware _jwtMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final token = request.headers['authorization']?.replaceFirst('Bearer ', '');
      if (!await verifyJWT(token)) {
        return Response.unauthorized('Invalid token');
      }
      return handler(request);
    };
  };
}

```text


### 3. TLS/SSL


For production, enable TLS:


```dart
// Publisher
tlsConfig: TlsSettings(
  certificateAuthority: '/path/to/ca.pem',
  verify: true,
),

// API Server
import 'dart:io';
final context = SecurityContext()
  ..useCertificateChain('server.crt')
  ..usePrivateKey('server.key');
final server = await io.serve(handler, '0.0.0.0', 443, securityContext: context);

```text


## 📊 Monitoring



### RabbitMQ Management UI


Access at: `http://localhost:15672`

**Key Metrics:**


- Exchange `pos_license_events` message rate

- Queue count (one per connected client)

- Connection count

- Message routing patterns


### Application Logging



```dart
// Add structured logging
import 'package:logging/logging.dart';

final log = Logger('MultiTenantPOS');

log.info('Published message', {
  'license_key': licenseKey,
  'message_type': messageType,
  'routing_key': routingKey,
});

```text


## 🧪 Testing



### Test Isolation



```bash

# Terminal 1: License ABC123

LICENSE_KEY=EXTRO-LIFE-ABC123 flutter run -d linux frontend_subscriber_multitenant.dart


# Terminal 2: License XYZ789  

LICENSE_KEY=EXTRO-LIFE-XYZ789 flutter run -d linux frontend_subscriber_multitenant.dart


# Terminal 3: Send to ABC123 only

dart run backend_publisher_multitenant.dart

# Verify Terminal 1 receives, Terminal 2 does not

```text


### Test Manual Sync



```bash

# Start sync API

dart run backend_sync_api.dart


# Click "Manual Sync" in frontend

# Should see:

# - HTTP request with X-License-Key header

# - API returns products/categories

# - Frontend logs sync completion

```text


## 📈 Scaling Considerations



### Horizontal Scaling


**Multiple Backend Publishers:**


```bash

# All publishers share the same exchange

# No coordination needed - RabbitMQ handles routing

docker-compose scale publisher=3

```text

**RabbitMQ Cluster:**


```yaml

# docker-compose.yml

services:
  rabbitmq-1:
    environment:

      - RABBITMQ_ERLANG_COOKIE=shared-cookie
  rabbitmq-2:
    environment:

      - RABBITMQ_ERLANG_COOKIE=shared-cookie

```text


### Load Balancing


**Frontend Connections:**


- Use HAProxy or Nginx for AMQP load balancing

- Configure multiple RabbitMQ nodes

**API Endpoints:**


- Standard HTTP load balancing

- Multiple sync API instances (stateless)


## 🔧 Troubleshooting



### Issue: Frontend not receiving messages


**Check:**

1. License key matches exactly
2. Exchange name is `pos_license_events`
3. Binding pattern is `license.<KEY>.#`
4. Publisher uses correct routing key format

**Debug:**


```bash

# Check RabbitMQ logs

docker logs rabbitmq


# Verify exchange exists

rabbitmqadmin list exchanges


# Check bindings

rabbitmqadmin list bindings

```text


### Issue: Manual sync fails


**Check:**

1. Sync API is running (`curl http://localhost:8080/health`)
2. License key header is set correctly
3. Network connectivity between frontend and API

**Debug:**


```bash

# Test sync endpoint directly

curl -H "X-License-Key: EXTRO-LIFE-ABC123" \
  http://localhost:8080/api/v1/sync/full_data

```text


## 📚 Next Steps


1. **Integrate with Real Database:**

   - Replace mock `DatabaseService`

   - Add SQLite/PostgreSQL queries

   - Implement bulk insert operations

2. **Add Message Types:**

   - `product_delete`

   - `modifier_update`

   - `table_update`

   - `user_update`

3. **Implement Offline Queue:**

   - Store outgoing messages when offline

   - Drain on reconnect

   - Use file-based or SQLite outbox

4. **Add Metrics:**

   - Message delivery latency

   - Sync completion time

   - Error rates

5. **Production Hardening:**

   - Add rate limiting

   - Implement circuit breakers

   - Add retry policies

   - Enable message compression
