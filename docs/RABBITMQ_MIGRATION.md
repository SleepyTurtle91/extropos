# Migration: Replace Appwrite & Firebase with RabbitMQ (Non-Persistent Streaming)

This document explains how to remove Appwrite/Firebase dependencies from a Flutter project and replace the realtime messaging with RabbitMQ (non-persistent setup) across networks using DDNS.

## Task 1: Environment & Dependency Cleanup

### 1. Flutter Dependency Removal (pubspec.yaml)

- Remove `appwrite` and `firebase_core` and related packages from `pubspec.yaml`. Example:

```yaml

# Before

dependencies:
  flutter:
    sdk: flutter
  appwrite: ^20.3.0
  firebase_core: ^2.0.0
  cloud_firestore: ^4.0.0
  firebase_messaging: ^14.0.0
  # ...



# After

dependencies:
  flutter:
    sdk: flutter
  # removed: appwrite, firebase_core, cloud_firestore, firebase_messaging

  sqlite3: ^1.0.0 # if you need local SQLite

  dart_amqp: ^0.2.0

```text

Run:


```bash

# Remove packages (recommended)

flutter pub remove appwrite firebase_core cloud_firestore firebase_messaging

# Add replacement package for pubsub

flutter pub add dart_amqp

```text

> Note: Also delete any `appwrite` config files, `lib/services/appwrite_*` files, or platform keys in `android/app/src` and `ios/Runner` that relate to Appwrite or Firebase.


### 2. Code Deletion Guidance


- Remove `import 'package:appwrite/appwrite.dart';` and all usages:

  - `Client()` initialization

  - `Account`, `Realtime`, `Databases` classes

  - `client.setProject` and `setEndpoint` usage

  - `realtime.subscribe` or Realtime listeners

- Replace `Realtime` usage with `dart_amqp`'s `Queue.consume()` (subscriber) and `Exchange.publish()` (publisher).

- Remove all `firebase` and `cloud_firestore` initialization code (like `Firebase.initializeApp()`), message handlers (e.g., Flutter Push Notifications code), and Firestore calls.

- Ensure local database code remains (using `sqflite` or `sqlite3`) in its existing data models. For the new message system, push messages into SQLite locally in subscriber callback.


## Task 2: RabbitMQ Docker Configuration



### 1. Docker Compose file (rabbitmq/docker-compose.yml)


- File created at `docker/rabbitmq/docker-compose.yml` (see repo)

- Key points:

  - Uses `rabbitmq:3-management` image (management UI on 15672)

  - Environment variables for default user and pass

  - Ports 5672 and 15672 exposed

  - Restart policy `always` for resilience

Example `docker-compose.yml`:


```yaml
version: "3.9"
services:
  rabbitmq:
    image: rabbitmq:3-management
    container_name: rabbitmq
    restart: always
    environment:

      - RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER:-rabbitadmin}

      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-S3cur3_P@ssw0rd!}

      - RABBITMQ_ERLANG_COOKIE=${RABBITMQ_ERLANG_COOKIE:-RABBITMQ_COOKIE}
    ports:

      - "5672:5672"

      - "15672:15672"
    volumes:

      - rabbitmq_data:/var/lib/rabbitmq
    networks:

      - rabbitnet

volumes:
  rabbitmq_data:
networks:
  rabbitnet:
    driver: bridge

```text

> Keep the passwords secure; consider using Docker secrets or an `.env` file not checked into the repo.


### 2. Ports, Firewall, & Router NAT


- Allow and forward the following ports to your RabbitMQ server/host:

  - TCP 5672 (AMQP) - required for AMQP client connections

  - TCP 15672 (optional) - for Admin/Management UI (prefer to restrict this to internal networks)

- On your router, configure Persistent Port Forwarding to your server's local IP.


### DDNS & Hostname


- Dynamic DNS (DDNS) provides a stable hostname when the ISP changes public IP.

- Recommended providers: DuckDNS, No-IP, DynDNS, or Cloudflare (if using Cloudflare API to update A records).

Workflow to set up DDNS (example using DuckDNS)

1. Register at DuckDNS and create an `pos.mycompany.stream` subdomain.
2. Set up a script or keep the DuckDNS client updated on the server or router to update the IP.
3. Verify: `ping pos.mycompany.stream` should return the current public IP.

For remote Flutter clients, they will use the DDNS hostname:


```text
AMQP Hostname: pos.mycompany.stream
AMQP Port: 5672
For TLS use: AMQPS Port: 5671

```text


## Task 3: Non-Persistent AMQP Implementation



### 1. Package Recommendation


- `dart_amqp` — stable client library for AMQP in Dart/Flutter

  - `https://pub.dev/packages/dart_amqp`


### 2. Backend (Publisher) Dart Code Example


- See `examples/rabbitmq/publisher.dart` in repo: it connects to `pos.mycompany.stream`, declares a non-durable exchange & queue, binds them, and publishes a JSON message with `deliveryMode = 1` (non-persistent).

Key points:


- Exchange and queue declared with `durable: false` so they do not survive broker restarts.

- Use `deliveryMode = 1` (non-persistent) when publishing.

- For production, secure the connection using TLS (AMQPS port 5671) or VPN. At minimum always use secure credentials.


### 3. Frontend (Subscriber) Flutter/Dart Code Example


- See `examples/rabbitmq/subscriber.dart` in repo. It uses `dart_amqp` to connect via DDNS hostname and port 5672 and listens on a non-durable queue.

- On message received, it logs and shows a placeholder to save to local SQLite (or `sqflite`/`sqlite3` driver) for offline persistence.


### Security & Stability best practices


- Avoid exposing AMQP (5672) directly to the Internet unless secured by TLS. Use one of these options:

  - VPN (WireGuard/StrongSwan) to connect remote POS devices to the internal network.

  - TLS (AMQPS / port 5671), requiring certificates on broker and clients.

  ### TLS (AMQPS) Setup & Client Trust


  1. Create a CA and server certificate (or use a trusted CA):

  ```bash
  cd docker/rabbitmq
  ./generate_rabbitmq_tls.sh pos.mycompany.stream
  ```

  1. Copy the `certs/` folder into `/home/abber/appwrite/certs` on the Docker host and mount it in Compose (already done in `docker-compose-tls.yml`).
  2. Open/forward port `5671` (AMQPS) on the router. Prefer all client connections to use `amqps://pos.mycompany.stream:5671`.

  3. On clients (Dart/Flutter) trust the CA certificate: add CA cert to system trust store or use TLS configuration in the client to trust the server certificate (example below).

  Client example (dart_amqp) using TLS: (see examples in `examples/rabbitmq`)

  > Note: If using a self-signed CA for testing, you can temporarily set `verify: false` or import the CA cert into client platform trust store. Production: Use a trusted CA or a VPN.

- Add firewall rules to allow only certain source IPs or use a reverse proxy.

- Implement client reconnection logic on the front-end to handle intermittent network outages.

- Consider WebSocket support (if needed) if devices need to connect through restricted networks.

  - I added a STOMP over WebSocket example using `stomp_dart_client` in `examples/rabbitmq/subscriber_stomp.dart`. The Web STOMP endpoint is `wss://pos.mycompany.stream:15674/ws`.

### Android / iOS TLS trust and configuration (brief)

Android (Network Security Config):

1. Add file `android/app/src/main/res/xml/network_security_config.xml` with:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <domain-config cleartextTrafficPermitted="false">
    <domain includeSubdomains="true">pos.mycompany.stream</domain>
    <trust-anchors>
      <certificates src="system" />
      <!-- If using a private CA for testing: include certificate in raw resources and add: -->
      <!-- <certificates src="@raw/my_ca"/> -->
    </trust-anchors>
  </domain-config>
</network-security-config>

```text

1. Reference that config in `AndroidManifest.xml` inside `<application>`:


```xml
android:networkSecurityConfig="@xml/network_security_config"

```text

1. For private CA distribution during development, import the CA certificate on each test device or use device profile methods.

iOS (Testing with private CA):


- For local development, you can install the CA certificate and trust it using Profiles & Device management.

- For production, use a public CA (Let's Encrypt) to avoid manual trust steps.


### pubspec usage for examples


Add these packages to your `pubspec.yaml` when trying the examples:


```yaml
dependencies:
  dart_amqp: ^0.2.0
  stomp_dart_client: ^0.6.0
  stomp_dart_client: # for STOMP websocket fallback

```text


## STOMP (WebSocket) fallback details


- STOMP provides a lightweight messaging over WebSocket; `stomp_dart_client` is a Flutter-friendly client.

- Web STOMP endpoint is `wss://pos.mycompany.stream:15674/ws` when you enable `rabbitmq_web_stomp` plugin and expose 15674.


### Frontend reconnection & SQLite insertion example (concept)


In the `subscriber.dart` example, the listener uses naive reconnect logic in `onError`/`onDone`. For production, implement exponential backoff with a maximum retry cap.

For local storage use `sqflite` or `sqlite3` package. Example (pseudo):


```dart
// final db = await openDatabase('pos.db');
// await db.insert('transactions', transactionMap);

```text

Store messages locally and sync when connectivity restored.


- Monitor QoS, message ack/nack and consider prefetch/consumer limitations for resource-constrained devices.

---

If you want, I can:


- Create sample TLS cert instructions to enable AMQPS

- Add a Docker compose configuration to publish Traefik in front of RabbitMQ to enable TLS via Let’s Encrypt

- Add a small sample `sqlite` insertion snippet for `subscriber.dart` to store transactions locally

Tell me if you want me to proceed with any of the above next steps.
