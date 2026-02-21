#!/bin/bash

# Nextcloud Setup Script for FlutterPOS
# Starts Nextcloud with Docker Compose and configures it for POS backups
# Uses external storage at /mnt/storage/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_PATH="/mnt/storage/nextcloud"
cd "$SCRIPT_DIR"

echo "╔════════════════════════════════════════╗"
echo "║   Nextcloud Setup for FlutterPOS       ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if /mnt/storage/ is mounted
if ! mountpoint -q /mnt/storage/ 2>/dev/null; then
  echo "❌ Error: /mnt/storage/ is not mounted!"
  echo "   Please mount your external drive first."
  exit 1
fi

# Get PC IP address
PC_IP=$(hostname -I | awk '{print $1}')
echo "📍 Your PC's IP Address: $PC_IP"
echo "💾 External Storage: /mnt/storage/"
df -h /mnt/storage/ | tail -1
echo ""

# Create directories on external storage
echo "📁 Creating Nextcloud directories on /mnt/storage/..."
sudo mkdir -p "$STORAGE_PATH"/{data,config,apps,db}

# Set proper ownership (www-data UID 33, mysql UID 999)
echo "🔧 Setting permissions..."
sudo chown -R 33:33 "$STORAGE_PATH"/{data,config,apps}
sudo chown -R 999:999 "$STORAGE_PATH/db"

echo "✅ Directories created at: $STORAGE_PATH"
ls -ld "$STORAGE_PATH"/*
echo ""

# Start Nextcloud
echo "🚀 Starting Nextcloud services..."
docker compose -f docker-compose-nextcloud.yml up -d

echo ""
echo "⏳ Waiting for Nextcloud to initialize (this may take 1-2 minutes)..."
sleep 10

# Check if Nextcloud is running
if docker ps | grep -q "nextcloud"; then
    echo "✅ Nextcloud is running!"
else
    echo "❌ Nextcloud failed to start"
    echo "Run: docker compose -f docker-compose-nextcloud.yml logs"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   Nextcloud Access Information         ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "🌐 Web Interface:"
echo "   Local: http://localhost:8080"
echo "   Network: http://$PC_IP:8080"
echo ""
echo "👤 Admin Credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "⚠️  IMPORTANT: Change the admin password after first login!"
echo ""
echo "📱 POS App Configuration:"
echo "   Server URL: http://$PC_IP:8080"
echo "   Username: admin"
echo "   App Password: (Generate after setup)"
echo ""
echo "╔════════════════════════════════════════╗"
echo "║   Next Steps                            ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "1. Open Nextcloud in browser: http://$PC_IP:8080"
echo "2. Login with admin/admin123"
echo "3. Go to Settings → Security"
echo "4. Create an App Password for FlutterPOS:"
echo "   - Name: FlutterPOS Backend"
echo "   - Copy the generated password"
echo "5. Create a folder: /backups/flutterpos"
echo "6. Configure POS app with:"
echo "   - Server: http://$PC_IP:8080"
echo "   - Username: admin"
echo "   - Password: (App Password from step 4)"
echo "   - Backup Path: /backups/flutterpos"
echo ""
echo "📊 Useful Commands:"
echo "   Start:   docker compose -f docker-compose-nextcloud.yml up -d"
echo "   Stop:    docker compose -f docker-compose-nextcloud.yml down"
echo "   Logs:    docker compose -f docker-compose-nextcloud.yml logs -f"
echo "   Restart: docker compose -f docker-compose-nextcloud.yml restart"
echo ""
echo "✅ Nextcloud setup complete!"
