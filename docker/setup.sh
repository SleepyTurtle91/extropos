#!/bin/bash
# FlutterPOS Self-Hosted Cloud Setup Script
# This script sets up the complete self-hosted infrastructure for FlutterPOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN=${DOMAIN:-"yourdomain.com"}
EMAIL=${EMAIL:-"admin@$DOMAIN"}

echo -e "${BLUE}🚀 FlutterPOS Self-Hosted Cloud Setup${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are installed${NC}"

# Create necessary directories
echo -e "${BLUE}📁 Creating necessary directories...${NC}"
mkdir -p ../build/web

# Build Flutter web app
echo -e "${BLUE}🔨 Building FlutterPOS Backend Web App...${NC}"
cd ..
if [ ! -f "build/web/index.html" ]; then
    echo -e "${YELLOW}⚠️  Flutter web build not found. Building now...${NC}"
    flutter build web -t lib/main_backend_web.dart
fi
cd docker

# Generate secure passwords
echo -e "${BLUE}🔐 Generating secure passwords...${NC}"
APPWRITE_DB_ROOT_PASS=$(openssl rand -base64 32)
APPWRITE_DB_PASS=$(openssl rand -base64 32)
MINIO_ACCESS_KEY=$(openssl rand -hex 16)
MINIO_SECRET_KEY=$(openssl rand -base64 32)
RABBITMQ_PASS=$(openssl rand -base64 16)

# Generate Appwrite secrets
CONSOLE_KEY=$(openssl rand -hex 32)
CONSOLE_SECRET=$(openssl rand -hex 32)
TASKS_KEY=$(openssl rand -hex 32)
TASKS_SECRET=$(openssl rand -hex 32)
FUNCTIONS_KEY=$(openssl rand -hex 32)
FUNCTIONS_SECRET=$(openssl rand -hex 32)
QUEUE_KEY=$(openssl rand -hex 32)
QUEUE_SECRET=$(openssl rand -hex 32)
VCS_KEY=$(openssl rand -hex 32)
VCS_SECRET=$(openssl rand -hex 32)
WEBHOOK_KEY=$(openssl rand -hex 32)
WEBHOOK_SECRET=$(openssl rand -hex 32)
CERTIFICATE_KEY=$(openssl rand -hex 32)
CERTIFICATE_SECRET=$(openssl rand -hex 32)
MIGRATION_KEY=$(openssl rand -hex 32)
MIGRATION_SECRET=$(openssl rand -hex 32)
BUILD_KEY=$(openssl rand -hex 32)
BUILD_SECRET=$(openssl rand -hex 32)
REGISTRY_KEY=$(openssl rand -hex 32)
REGISTRY_SECRET=$(openssl rand -hex 32)
REALTIME_KEY=$(openssl rand -hex 32)
REALTIME_SECRET=$(openssl rand -hex 32)
CACHE_KEY=$(openssl rand -hex 32)
CACHE_SECRET=$(openssl rand -hex 32)
DB_KEY=$(openssl rand -hex 32)
DB_SECRET=$(openssl rand -hex 32)
STORAGE_KEY=$(openssl rand -hex 32)
STORAGE_SECRET=$(openssl rand -hex 32)
EXECUTOR_KEY=$(openssl rand -hex 32)
EXECUTOR_SECRET=$(openssl rand -hex 32)

# Create .env file with all configuration
cat > .env << EOF
# Domain Configuration
DOMAIN=$DOMAIN
EMAIL=$EMAIL

# Appwrite Database
APPWRITE_DB_ROOT_PASS=$APPWRITE_DB_ROOT_PASS
APPWRITE_DB_PASS=$APPWRITE_DB_PASS

# MinIO Storage
MINIO_ACCESS_KEY=$MINIO_ACCESS_KEY
MINIO_SECRET_KEY=$MINIO_SECRET_KEY

# RabbitMQ
RABBITMQ_PASS=$RABBITMQ_PASS

# Appwrite Secrets
CONSOLE_KEY=$CONSOLE_KEY
CONSOLE_SECRET=$CONSOLE_SECRET
TASKS_KEY=$TASKS_KEY
TASKS_SECRET=$TASKS_SECRET
FUNCTIONS_KEY=$FUNCTIONS_KEY
FUNCTIONS_SECRET=$FUNCTIONS_SECRET
QUEUE_KEY=$QUEUE_KEY
QUEUE_SECRET=$QUEUE_SECRET
VCS_KEY=$VCS_KEY
VCS_SECRET=$VCS_SECRET
WEBHOOK_KEY=$WEBHOOK_KEY
WEBHOOK_SECRET=$WEBHOOK_SECRET
CERTIFICATE_KEY=$CERTIFICATE_KEY
CERTIFICATE_SECRET=$CERTIFICATE_SECRET
MIGRATION_KEY=$MIGRATION_KEY
MIGRATION_SECRET=$MIGRATION_SECRET
BUILD_KEY=$BUILD_KEY
BUILD_SECRET=$BUILD_SECRET
REGISTRY_KEY=$REGISTRY_KEY
REGISTRY_SECRET=$REGISTRY_SECRET
REALTIME_KEY=$REALTIME_KEY
REALTIME_SECRET=$REALTIME_SECRET
CACHE_KEY=$CACHE_KEY
CACHE_SECRET=$CACHE_SECRET
DB_KEY=$DB_KEY
DB_SECRET=$DB_SECRET
STORAGE_KEY=$STORAGE_KEY
STORAGE_SECRET=$STORAGE_SECRET
EXECUTOR_KEY=$EXECUTOR_KEY
EXECUTOR_SECRET=$EXECUTOR_SECRET
EOF

echo -e "${GREEN}✅ Configuration generated and saved to .env${NC}"

# Update docker-compose.yml with actual values
echo -e "${BLUE}🔧 Updating docker-compose.yml with your configuration...${NC}"
sed -i "s/yourdomain.com/$DOMAIN/g" docker-compose.yml
sed -i "s/admin@yourdomain.com/$EMAIL/g" docker-compose.yml

# Replace secrets in docker-compose.yml
sed -i "s/your-console-key-here/$CONSOLE_KEY/g" docker-compose.yml
sed -i "s/your-console-secret-here/$CONSOLE_SECRET/g" docker-compose.yml
sed -i "s/your-tasks-key-here/$TASKS_KEY/g" docker-compose.yml
sed -i "s/your-tasks-secret-here/$TASKS_SECRET/g" docker-compose.yml
sed -i "s/your-functions-key-here/$FUNCTIONS_KEY/g" docker-compose.yml
sed -i "s/your-functions-secret-here/$FUNCTIONS_SECRET/g" docker-compose.yml
sed -i "s/your-queue-key-here/$QUEUE_KEY/g" docker-compose.yml
sed -i "s/your-queue-secret-here/$QUEUE_SECRET/g" docker-compose.yml
sed -i "s/your-vcs-key-here/$VCS_KEY/g" docker-compose.yml
sed -i "s/your-vcs-secret-here/$VCS_SECRET/g" docker-compose.yml
sed -i "s/your-webhook-key-here/$WEBHOOK_KEY/g" docker-compose.yml
sed -i "s/your-webhook-secret-here/$WEBHOOK_SECRET/g" docker-compose.yml
sed -i "s/your-certificate-key-here/$CERTIFICATE_KEY/g" docker-compose.yml
sed -i "s/your-certificate-secret-here/$CERTIFICATE_SECRET/g" docker-compose.yml
sed -i "s/your-migration-key-here/$MIGRATION_KEY/g" docker-compose.yml
sed -i "s/your-migration-key-here/$MIGRATION_KEY/g" docker-compose.yml
sed -i "s/your-migration-secret-here/$MIGRATION_SECRET/g" docker-compose.yml
sed -i "s/your-build-key-here/$BUILD_KEY/g" docker-compose.yml
sed -i "s/your-build-secret-here/$BUILD_SECRET/g" docker-compose.yml
sed -i "s/your-registry-key-here/$REGISTRY_KEY/g" docker-compose.yml
sed -i "s/your-registry-secret-here/$REGISTRY_SECRET/g" docker-compose.yml
sed -i "s/your-realtime-key-here/$REALTIME_KEY/g" docker-compose.yml
sed -i "s/your-realtime-secret-here/$REALTIME_SECRET/g" docker-compose.yml
sed -i "s/your-cache-key-here/$CACHE_KEY/g" docker-compose.yml
sed -i "s/your-cache-secret-here/$CACHE_SECRET/g" docker-compose.yml
sed -i "s/your-db-key-here/$DB_KEY/g" docker-compose.yml
sed -i "s/your-db-secret-here/$DB_SECRET/g" docker-compose.yml
sed -i "s/your-storage-key-here/$STORAGE_KEY/g" docker-compose.yml
sed -i "s/your-storage-secret-here/$STORAGE_SECRET/g" docker-compose.yml
sed -i "s/your-executor-key-here/$EXECUTOR_KEY/g" docker-compose.yml
sed -i "s/your-executor-secret-here/$EXECUTOR_SECRET/g" docker-compose.yml

# Replace passwords
sed -i "s/password/$APPWRITE_DB_ROOT_PASS/g" docker-compose.yml
sed -i "s/changeme_secure_password/$RABBITMQ_PASS/g" docker-compose.yml
sed -i "s/access-key/$MINIO_ACCESS_KEY/g" docker-compose.yml
sed -i "s/secret-key/$MINIO_SECRET_KEY/g" docker-compose.yml
sed -i "s/minio-secret/$MINIO_SECRET_KEY/g" docker-compose.yml

echo -e "${GREEN}✅ Docker Compose configuration updated${NC}"

# Create .htpasswd for Traefik basic auth
echo -e "${BLUE}🔒 Creating Traefik authentication...${NC}"
TRAEFIK_USER=${TRAEFIK_USER:-"admin"}
TRAEFIK_PASS=${TRAEFIK_PASS:-"admin123"}
TRAEFIK_HASH=$(openssl passwd -apr1 "$TRAEFIK_PASS")
# Update Traefik auth in docker-compose.yml
# Use awk to replace the line since sed has issues with multiple $ characters
awk -v user="$TRAEFIK_USER" -v hash="$TRAEFIK_HASH" '
  /traefik\.http\.middlewares\.auth\.basicauth\.users=admin:\$\$2y\$\$10\$\$...\./ {
    print "      - \"traefik.http.middlewares.auth.basicauth.users=" user ":" hash "\""
    next
  }
  { print }
' docker-compose.yml > docker-compose.yml.tmp && mv docker-compose.yml.tmp docker-compose.yml

echo -e "${GREEN}✅ Traefik authentication configured${NC}"

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Review and customize the .env file with your settings"
echo "2. Update DNS records to point to your server:"
echo "   - appwrite.$DOMAIN → your server IP"
echo "   - console.appwrite.$DOMAIN → your server IP"
echo "   - cloud.$DOMAIN → your server IP"
echo "   - backend.$DOMAIN → your server IP"
echo "   - rabbitmq.$DOMAIN → your server IP"
echo "   - traefik.$DOMAIN → your server IP"
echo ""
echo -e "${YELLOW}⚠️  Security Notes:${NC}"
echo "- Change default passwords in .env file"
echo "- Configure firewall to only allow necessary ports"
echo "- Enable SSL/TLS certificates through Traefik"
echo "- Regularly backup your data volumes"
echo ""
echo -e "${BLUE}🚀 To start the services:${NC}"
echo "cd docker && docker-compose up -d"
echo ""
echo -e "${BLUE}📊 To check status:${NC}"
echo "./status.sh"
echo ""
echo -e "${BLUE}🔗 Service URLs:${NC}"
echo "- Traefik Dashboard: https://traefik.$DOMAIN (admin/$TRAEFIK_PASS)"
echo "- Appwrite Console: https://console.appwrite.$DOMAIN"
echo "- Nextcloud: https://cloud.$DOMAIN (admin/admin123)"
echo "- RabbitMQ Management: https://rabbitmq.$DOMAIN (posadmin/$RABBITMQ_PASS)"
echo "- FlutterPOS Backend: https://backend.$DOMAIN"