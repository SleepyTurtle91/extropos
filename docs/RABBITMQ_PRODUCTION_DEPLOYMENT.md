# RabbitMQ Production Deployment Guide

Complete guide for deploying RabbitMQ with TLS for the FlutterPOS messaging system.

## Architecture Overview

```text
┌─────────────────┐         AMQPS (5671)        ┌──────────────────┐
│  POS Devices    │◄──────────TLS──────────────►│   RabbitMQ       │
│  (Publisher)    │         WSS (15674)         │   + Web-STOMP    │

└─────────────────┘◄──────────TLS──────────────►└──────────────────┘
                                                          │
┌─────────────────┐         AMQPS (5671)                 │
│  Backend App    │◄──────────TLS──────────────►─────────┘
│  (Subscriber)   │
└─────────────────┘

```text


## Prerequisites



### Server Requirements


- Linux server (Ubuntu 22.04+ recommended)

- Docker & Docker Compose installed

- Domain name (e.g., `pos.mycompany.stream`)

- Cloudflare account for DNS management

- Ports open: 5671 (AMQPS), 15674 (Web-STOMP), 15672 (Management)


### GitHub Secrets Required


Set these in your repository settings → Secrets and variables → Actions:


```text
CF_API_TOKEN          # Cloudflare API token with DNS edit permissions

SERVER_HOST           # Your server IP or hostname

SERVER_USER           # SSH username (e.g., ubuntu)

SERVER_SSH_KEY        # SSH private key for authentication

SERVER_SSH_PORT       # SSH port (default: 22)

```text


## Step 1: DNS Setup



### Option A: Manual Cloudflare DNS


1. Log in to Cloudflare dashboard
2. Select your domain
3. Add A record: `pos` → `YOUR_SERVER_IP`
4. Set proxy status to "DNS only" (grey cloud)


### Option B: Automated via Script



```bash
export CF_API_TOKEN=your_cloudflare_token
./scripts/dns_cloudflare.sh mycompany.stream YOUR_SERVER_IP pos

```text


## Step 2: TLS Certificate Generation



### Development (Self-Signed)



```bash
cd docker/rabbitmq
./generate_rabbitmq_tls.sh pos.mycompany.stream

```text

This creates:


- `certs/ca_cert.pem` - CA certificate (distribute to clients)

- `certs/server_cert.pem` - Server certificate

- `certs/server_key.pem` - Server private key


### Production (Let's Encrypt)



#### Local Certificate Generation



```bash

# Install certbot

sudo apt-get install certbot python3-certbot-dns-cloudflare


# Create credentials file

cat > ~/.secrets/certbot/cloudflare.ini << EOF
dns_cloudflare_api_token = YOUR_CF_API_TOKEN
EOF
chmod 600 ~/.secrets/certbot/cloudflare.ini


# Generate certificate

sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
  --email admin@mycompany.com \
  --agree-tos \
  --non-interactive \
  --domain pos.mycompany.stream


# Copy to RabbitMQ certs directory

sudo cp /etc/letsencrypt/live/pos.mycompany.stream/fullchain.pem docker/rabbitmq/certs/server_cert.pem
sudo cp /etc/letsencrypt/live/pos.mycompany.stream/privkey.pem docker/rabbitmq/certs/server_key.pem
sudo cp /etc/letsencrypt/live/pos.mycompany.stream/chain.pem docker/rabbitmq/certs/ca_cert.pem

```text


#### Automated via GitHub Actions



```bash

# Trigger workflow from GitHub UI:

# Actions → RabbitMQ Deploy with TLS → Run workflow

# - domain: pos.mycompany.stream

```text


## Step 3: Deploy RabbitMQ



### Using Docker Compose (Manual)



```bash

# Clone repository on server

cd /home/your_user/rabbitmq


# Set credentials

export RABBITMQ_USER=rabbitadmin
export RABBITMQ_PASS=$(openssl rand -base64 32)


# Deploy

docker compose -f docker-compose-production.yml up -d


# Verify

docker compose -f docker-compose-production.yml ps
docker logs rabbitmq-pos

```text


### Using GitHub Actions (Automated)


The workflow automatically:

1. Issues Let's Encrypt certificate via Cloudflare DNS
2. Copies certificates to server
3. Deploys RabbitMQ with TLS configuration
4. Verifies deployment


## Step 4: Verify Deployment



### Test AMQPS Connection



```bash
openssl s_client -connect pos.mycompany.stream:5671 -CAfile certs/ca_cert.pem

```text

Expected output: `Verify return code: 0 (ok)`


### Test Web-STOMP



```bash
openssl s_client -connect pos.mycompany.stream:15674 -CAfile certs/ca_cert.pem

```text


### Access Management UI



```text
https://pos.mycompany.stream:15672
Username: rabbitadmin
Password: [your_password]

```text


## Step 5: Client Configuration



### Publisher (Dart)



```bash
cd examples/rabbitmq/publisher
export RABBITMQ_HOST=pos.mycompany.stream
export RABBITMQ_PORT=5671
export RABBITMQ_USER=rabbitadmin
export RABBITMQ_PASS=your_password
export RABBITMQ_CA_FILE=/path/to/ca_cert.pem  # for self-signed only


dart pub get
dart run bin/publisher.dart

```text


### Subscriber (Flutter)



```bash
cd examples/rabbitmq/subscriber
export RABBITMQ_HOST=pos.mycompany.stream
export RABBITMQ_PORT=5671
export RABBITMQ_USER=rabbitadmin
export RABBITMQ_PASS=your_password
export RABBITMQ_CA_FILE=/path/to/ca_cert.pem  # for self-signed only


flutter pub get
flutter run -d linux lib/subscriber.dart

```text


## Step 6: Mobile Device Setup



### Android


For self-signed certificates, add to `network_security_config.xml`:


```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">pos.mycompany.stream</domain>
        <trust-anchors>
            <certificates src="@raw/ca_cert"/>
        </trust-anchors>
    </domain-config>
</network-security-config>

```text

Place `ca_cert.pem` in `android/app/src/main/res/raw/`


### iOS


1. Email `ca_cert.pem` to the device
2. Install profile: Settings → Profile Downloaded → Install
3. Trust certificate: Settings → General → About → Certificate Trust Settings


## Step 7: Monitoring Setup



### Enable Prometheus Plugin



```bash
docker exec rabbitmq-pos rabbitmq-plugins enable rabbitmq_prometheus

```text


### Prometheus Configuration



```yaml
scrape_configs:

  - job_name: 'rabbitmq'
    static_configs:

      - targets: ['pos.mycompany.stream:15692']

```text


### Grafana Dashboard


Import dashboard ID: `10991` (RabbitMQ-Overview)


### Key Metrics to Monitor


- Connection count

- Message publish/consume rates

- Queue depth

- Memory usage

- Disk space

- Network throughput


## Step 8: Certificate Renewal



### Automated Renewal (Recommended)


GitHub Actions workflow runs monthly (or trigger manually):


```text
Actions → RabbitMQ Renew Certificates → Run workflow

```text


### Manual Renewal



```bash
sudo certbot renew
sudo cp /etc/letsencrypt/live/pos.mycompany.stream/fullchain.pem docker/rabbitmq/certs/server_cert.pem
sudo cp /etc/letsencrypt/live/pos.mycompany.stream/privkey.pem docker/rabbitmq/certs/server_key.pem
docker compose -f docker-compose-production.yml restart

```text


## Security Best Practices



### 1. Firewall Configuration



```bash

# Allow only necessary ports

sudo ufw allow 22/tcp     # SSH

sudo ufw allow 5671/tcp   # AMQPS

sudo ufw allow 15674/tcp  # Web-STOMP

sudo ufw allow 15672/tcp  # Management (restrict to trusted IPs)

sudo ufw enable

```text


### 2. Restrict Management UI


Edit `rabbitmq.conf`:


```text
management.tcp.ip = 127.0.0.1  # localhost only

```text

Access via SSH tunnel:


```bash
ssh -L 15672:localhost:15672 user@pos.mycompany.stream

# Then visit: http://localhost:15672

```text


### 3. User Permissions



```bash

# Create limited-privilege user for POS devices

docker exec rabbitmq-pos rabbitmqctl add_user pos_device secure_password
docker exec rabbitmq-pos rabbitmqctl set_permissions -p / pos_device "pos_.*" "pos_.*" "pos_.*"

```text


### 4. Enable Rate Limiting


Add to `rabbitmq.conf`:


```text
channel_max = 128
connection_max = 500

```text


## High Availability Setup



### 3-Node Cluster


Edit `docker-compose-production.yml` to add nodes:


```yaml
services:
  rabbitmq-1:
    # ... config ...

    hostname: rabbitmq-pos-1
    environment:
      RABBITMQ_ERLANG_COOKIE: 'secret-cookie-change-me'
  
  rabbitmq-2:
    # ... config ...

    hostname: rabbitmq-pos-2
    environment:
      RABBITMQ_ERLANG_COOKIE: 'secret-cookie-change-me'
  
  rabbitmq-3:
    # ... config ...

    hostname: rabbitmq-pos-3
    environment:
      RABBITMQ_ERLANG_COOKIE: 'secret-cookie-change-me'

```text

Update `rabbitmq.conf`:


```text
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
cluster_formation.classic_config.nodes.1 = rabbit@rabbitmq-pos-1
cluster_formation.classic_config.nodes.2 = rabbit@rabbitmq-pos-2
cluster_formation.classic_config.nodes.3 = rabbit@rabbitmq-pos-3

```text


## Troubleshooting



### Connection Refused



```bash

# Check RabbitMQ is running

docker ps | grep rabbitmq


# Check logs

docker logs rabbitmq-pos


# Verify port is open

telnet pos.mycompany.stream 5671

```text


### Certificate Errors



```bash

# Verify certificate validity

openssl x509 -in certs/server_cert.pem -text -noout


# Check certificate matches domain

openssl s_client -connect pos.mycompany.stream:5671 -servername pos.mycompany.stream

```text


### Performance Issues



```bash

# Check memory usage

docker exec rabbitmq-pos rabbitmq-diagnostics memory_breakdown


# Check connection count

docker exec rabbitmq-pos rabbitmqctl list_connections


# Check queue status

docker exec rabbitmq-pos rabbitmqctl list_queues

```text


## Backup & Disaster Recovery



### Backup Configuration



```bash

# Export definitions

docker exec rabbitmq-pos rabbitmqctl export_definitions /tmp/definitions.json
docker cp rabbitmq-pos:/tmp/definitions.json ./backup/


# Backup certificates

tar -czf backup/certs-$(date +%Y%m%d).tar.gz docker/rabbitmq/certs/

```text


### Restore



```bash

# Import definitions

docker cp ./backup/definitions.json rabbitmq-pos:/tmp/
docker exec rabbitmq-pos rabbitmqctl import_definitions /tmp/definitions.json

```text


## Production Checklist


- [ ] DNS A record created and verified

- [ ] TLS certificates issued and valid (Let's Encrypt or self-signed)

- [ ] Firewall rules configured

- [ ] RabbitMQ deployed and running

- [ ] Management UI accessible (restricted)

- [ ] AMQPS connection tested (port 5671)

- [ ] Web-STOMP connection tested (port 15674)

- [ ] Monitoring configured (Prometheus + Grafana)

- [ ] Certificate auto-renewal setup

- [ ] Backup strategy implemented

- [ ] Mobile clients configured with CA trust

- [ ] User permissions configured (least privilege)

- [ ] Rate limiting enabled

- [ ] Documentation updated with credentials (secure storage)


## Support & Resources


- RabbitMQ Docs: <https://www.rabbitmq.com/documentation.html>

- TLS Guide: <https://www.rabbitmq.com/ssl.html>

- Clustering: <https://www.rabbitmq.com/clustering.html>

- Monitoring: <https://www.rabbitmq.com/monitoring.html>

- FlutterPOS Examples: `examples/rabbitmq/`


## Next Steps


1. **Test with real POS devices**: Deploy examples to Android tablets
2. **Load testing**: Use `rabbitmq-perf-test` to simulate production load
3. **Add WireGuard VPN**: For additional security layer
4. **Implement message signing**: Add HMAC signatures to messages
5. **Add business logic**: Create order processing service that consumes messages
