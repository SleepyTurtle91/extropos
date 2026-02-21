# Docker Migration Complete - Appwrite → RabbitMQ

## ✅ What Was Done

Successfully migrated from Appwrite to RabbitMQ for FlutterPOS.

### 1. Removed Appwrite

- **Stopped**: 25 Appwrite containers

- **Removed**: All Appwrite containers

- **Preserved**: Appwrite volumes (can be removed later if needed)

### 2. Started RabbitMQ

- **Container**: `rabbitmq` (running)

- **Status**: ✅ Healthy and ready

- **Ports**:

  - AMQP: `5672` (for FlutterPOS connections)

  - Management UI: `15672` (for admin)

  - Prometheus: `15692` (for metrics)

### 3. Created Management Scripts

```
docker/
├── start-rabbitmq.sh       # Start RabbitMQ

├── stop-rabbitmq.sh        # Stop RabbitMQ  

├── status.sh               # Check container status

├── remove-appwrite.sh      # Remove Appwrite (already used)

└── README.md               # Complete documentation

```

All scripts are executable and ready to use.

## 🎯 Current Status

### RabbitMQ

✅ **Running** - Container healthy

- Management UI: <http://localhost:15672>

- Username: `posadmin`

- Password: `changeme_secure_password`

- AMQP: `localhost:5672`

### Appwrite

✅ **Removed** - All 25 containers stopped and removed

- Volumes preserved (can delete if not needed)

## 🚀 Next Steps

### 1. Access RabbitMQ Management UI

Open in browser: <http://localhost:15672>

Login with:

- Username: `posadmin`

- Password: `changeme_secure_password`

You should see:

- Dashboard with 0 connections (normal, no apps connected yet)

- No queues (will be created when POS connects)

- Exchange `pos_license_events` will be created automatically

### 2. Test with Backend App

```bash
cd /home/abber/Documents/flutterpos


# Run Backend flavor

flutter run -d linux lib/main_backend.dart

```

In the app:

1. Go to **Menu → RabbitMQ Settings**
2. Connection settings should already be filled:

   - Host: `localhost`

   - Port: `5672`

   - Username: `posadmin`

   - Password: `changeme_secure_password`

3. Click **Test Connection** → Should see ✅

4. Enable **"Enable RabbitMQ Sync"** toggle

5. Enable **"Auto-connect on startup"**
6. Click **Save**

### 3. Test with POS App

```bash

# Run POS flavor

flutter run -d linux lib/main.dart

```

In the app:

1. Make sure license is **activated** (Settings → About)

2. Check AppBar for **🟢 Live Sync** indicator

3. If you see 🟢, RabbitMQ is connected!

### 4. Test Real-Time Sync

**In Backend app:**

1. Go to Menu → Products
2. Edit a product price
3. Save

**In POS app:**

- Price should update automatically in real-time!

- No manual refresh needed

- Check console for: `📥 RabbitMQ Sync Handler: Processing price_update`

## 📊 Monitoring

### Quick Status Check

```bash
cd docker
./status.sh

```

### RabbitMQ Logs

```bash

# View logs

docker logs rabbitmq


# Follow logs in real-time

docker logs -f rabbitmq

```

### Container Stats

```bash

# CPU, memory usage

docker stats rabbitmq

```

### Management UI

- **Overview**: <http://localhost:15672/#/>

- **Queues**: <http://localhost:15672/#/queues>

- **Exchanges**: <http://localhost:15672/#/exchanges>

- **Connections**: <http://localhost:15672/#/connections>

## 🛠️ Troubleshooting

### RabbitMQ not accessible

```bash

# Check if running

docker ps | grep rabbitmq


# If stopped, start it

cd docker
./start-rabbitmq.sh


# Check logs for errors

docker logs rabbitmq

```

### Backend can't connect

1. Check RabbitMQ is running: `docker ps | grep rabbitmq`
2. Test connection in Backend: Menu → RabbitMQ Settings → Test Connection
3. Check credentials match docker-compose.yml
4. View RabbitMQ logs: `docker logs rabbitmq`

### POS shows 🟠 Offline

1. Check license is activated (Settings → About)
2. Check RabbitMQ settings are saved
3. Check Backend published at least one message
4. Restart POS app

### Need to reset everything

```bash
cd docker


# Stop RabbitMQ

./stop-rabbitmq.sh


# Remove RabbitMQ data (DESTROYS ALL QUEUES/MESSAGES!)

docker volume rm rabbitmq_data


# Start fresh

./start-rabbitmq.sh

```

## 🔧 Advanced Configuration

### Change Password

Edit `docker/rabbitmq/docker-compose.yml`:

```yaml
environment:

  - RABBITMQ_USER=posadmin

  - RABBITMQ_PASS=YOUR_NEW_PASSWORD  # Change this

```

Then:

```bash
cd docker
./stop-rabbitmq.sh
./start-rabbitmq.sh

```

Also update in FlutterPOS apps (Backend → RabbitMQ Settings).

### Enable TLS (Production)

Use `docker-compose-tls.yml`:

```bash
cd docker/rabbitmq
docker-compose -f docker-compose-tls.yml up -d

```

See `docker/rabbitmq/docker-compose-tls.yml` for TLS configuration.

### View All RabbitMQ Commands

```bash

# Enter container

docker exec -it rabbitmq bash


# Inside container

rabbitmqctl list_queues
rabbitmqctl list_exchanges
rabbitmqctl list_connections
rabbitmqctl list_bindings

```

## 📁 What Changed

### Files Created

- `docker/start-rabbitmq.sh` - Start script

- `docker/stop-rabbitmq.sh` - Stop script

- `docker/status.sh` - Status check script

- `docker/remove-appwrite.sh` - Appwrite removal script

- `docker/README.md` - Docker documentation

- `docker/MIGRATION_COMPLETE.md` - This file

### Files Modified

- `docker/rabbitmq/docker-compose.yml` - Updated credentials to match FlutterPOS defaults

### Docker Changes

- **Removed**: 25 Appwrite containers

- **Started**: 1 RabbitMQ container

- **Network**: `rabbitmq_rabbitnet` (created)

- **Volume**: `rabbitmq_data` (created)

## 🎉 Success

You now have:

- ✅ RabbitMQ running and healthy

- ✅ Appwrite removed

- ✅ Management scripts ready

- ✅ Documentation complete

- ✅ Ready for real-time sync testing

RabbitMQ is much simpler than Appwrite:

- **1 container** instead of 25

- **~500 MB RAM** instead of ~2-3 GB

- **Faster startup** (5 seconds vs 30+ seconds)

- **Purpose-built** for messaging

## 📚 Documentation

- **Docker Guide**: `/docker/README.md`

- **RabbitMQ Integration**: `/docs/RABBITMQ_INTEGRATION.md`

- **Implementation Summary**: `/docs/RABBITMQ_IMPLEMENTATION_SUMMARY.md`

- **Quick Start**: `/examples/rabbitmq/MULTITENANT_QUICKSTART.md`

Enjoy real-time sync! 🚀
