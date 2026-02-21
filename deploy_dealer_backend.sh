#!/bin/bash
# Build and Deploy Dealer Backend to Docker
# Usage: ./deploy_dealer_backend.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Dealer Backend Deployment Script    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Build Flutter web app first (faster iteration)
echo -e "${YELLOW}Building Dealer Portal Web App...${NC}"
flutter build web \
    --release \
    --target lib/main_dealer.dart \
    --no-tree-shake-icons

if [ $? -ne 0 ]; then
    echo -e "${RED}Flutter build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter web build successful${NC}"
echo ""

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build \
    -f docker/dealer-backend.Dockerfile \
    -t flutterpos-dealer-backend:latest \
    -t flutterpos-dealer-backend:v$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1) \
    .

if [ $? -ne 0 ]; then
    echo -e "${RED}Docker build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

# Stop and remove existing container
echo -e "${YELLOW}Stopping existing container (if any)...${NC}"
docker stop flutterpos-dealer-backend 2>/dev/null || true
docker rm flutterpos-dealer-backend 2>/dev/null || true
echo ""

# Run new container
echo -e "${YELLOW}Starting new container...${NC}"
echo "# Public TLS router: only include the publicly routable hostname so ACME" 
echo "# requests do not attempt to include local-only names (which fail DNS" 
echo "# validation). This router will obtain certificates via the letsencrypt" 
echo "# resolver." 
echo "# Local-only router (no TLS) for testing on developer machines." 
docker run -d \
    --name flutterpos-dealer-backend \
    --restart unless-stopped \
    --network flutterpos_proxy \
    -p 8082:80 \
    -l "traefik.enable=true" \
    -l "traefik.http.routers.dealer.rule=Host(\`dealer.extropos.org\`)" \
    -l "traefik.http.routers.dealer.entrypoints=web,websecure" \
    -l "traefik.http.routers.dealer.tls=true" \
    -l "traefik.http.routers.dealer.tls.certresolver=letsencrypt" \
    -l "traefik.http.routers.dealer-local.rule=Host(\`dealer.localhost\`)" \
    -l "traefik.http.routers.dealer-local.entrypoints=web" \
    -l "traefik.http.services.dealer-service.loadbalancer.server.port=80" \
    flutterpos-dealer-backend:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}Container start failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Container started successfully${NC}"
echo ""

# Wait for container to be healthy
echo -e "${YELLOW}Waiting for health check...${NC}"
sleep 3

# Check container status
if docker ps | grep -q flutterpos-dealer-backend; then
    echo -e "${GREEN}✓ Container is running${NC}"
else
    echo -e "${RED}✗ Container failed to start${NC}"
    docker logs flutterpos-dealer-backend
    exit 1
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}  Deployment Successful!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Access URLs:${NC}"
echo -e "  Local:          ${GREEN}http://localhost:8082${NC}"
echo -e "  Network:        ${GREEN}http://dealer.localhost${NC}"
echo -e "  Production:     ${GREEN}http://dealer.extropos.org${NC}"
echo ""
echo -e "${BLUE}Management:${NC}"
echo -e "  View logs:      ${YELLOW}docker logs -f flutterpos-dealer-backend${NC}"
echo -e "  Stop:           ${YELLOW}docker stop flutterpos-dealer-backend${NC}"
echo -e "  Restart:        ${YELLOW}docker restart flutterpos-dealer-backend${NC}"
echo ""

# Show container info
echo -e "${BLUE}Container Info:${NC}"
docker ps --filter name=flutterpos-dealer-backend --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
