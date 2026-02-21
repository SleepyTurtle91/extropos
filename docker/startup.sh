#!/bin/bash

# Production Appwrite Quick-Start
# Sets up Appwrite for extropos.org with proper configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/appwrite-compose-web-optimized.yml"
API_KEY="${APPWRITE_API_KEY:-}"

echo "════════════════════════════════════════════════════════════"
echo "  ExtroPOS Appwrite Production Setup"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check prerequisites
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not found. Please install Docker first."
  exit 1
fi

if ! command -v docker-compose &> /dev/null; then
  echo "❌ Docker Compose not found. Please install Docker Compose first."
  exit 1
fi

echo "✅ Docker and Docker Compose found"
echo ""

# Start services
echo "🚀 Starting Appwrite services..."
docker-compose -f "$COMPOSE_FILE" up -d --remove-orphans

echo "⏳ Waiting for services to become healthy (30s)..."
sleep 30

# Check health
echo ""
echo "📊 Service Status:"
docker-compose -f "$COMPOSE_FILE" ps

echo ""
echo "✅ Appwrite is running!"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Next Steps"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  Access Appwrite Console:"
echo "   Local:  http://localhost:8080"
echo "   Prod:   https://appwrite.extropos.org (requires DNS & reverse proxy)"
echo ""
echo "2️⃣  Configure CORS for your website:"
echo "   ./setup_appwrite_cors.sh https://appwrite.extropos.org/v1 <your-api-key>"
echo ""
echo "3️⃣  Create API Keys in Console:"
echo "   • Web-scoped key for extropos.org website"
echo "   • Keep POS key separate (already in environment.dart)"
echo ""
echo "4️⃣  Backend Flavor Configuration:"
echo "   flutter run lib/main_backend.dart \\"
echo "     --dart-define=APPWRITE_ENDPOINT=https://appwrite.extropos.org/v1 \\"
echo "     --dart-define=APPWRITE_API_KEY=<your-backend-key>"
echo ""
echo "5️⃣  POS/KDS Flavor Configuration:"
echo "   flutter run \\"
echo "     --dart-define=APPWRITE_ENDPOINT=https://appwrite.extropos.org/v1 \\"
echo "     --dart-define=APPWRITE_API_KEY=<your-pos-key>"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📚 Documentation: docker/DEPLOYMENT_GUIDE.md"
echo ""
