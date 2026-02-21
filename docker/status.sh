#!/bin/bash
# FlutterPOS Self-Hosted Status Check
# Shows the status of all Docker containers and services

echo "🔍 FlutterPOS Self-Hosted Services Status"
echo "=========================================="
echo ""

# Check if docker-compose is available
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose not found"
    exit 1
fi

echo "📊 Container Status:"
echo "-------------------"
$COMPOSE_CMD ps
echo ""

echo "🌐 Service URLs:"
echo "---------------"
if [ -f .env ]; then
    source .env
    echo "• Traefik Dashboard: https://traefik.$DOMAIN"
    echo "• Appwrite API: https://appwrite.$DOMAIN"
    echo "• Appwrite Console: https://console.appwrite.$DOMAIN"
    echo "• Nextcloud: https://cloud.$DOMAIN"
    echo "• RabbitMQ Management: https://rabbitmq.$DOMAIN"
    echo "• FlutterPOS Backend: https://backend.$DOMAIN"
    echo "• MailHog (Dev): https://mail.$DOMAIN"
else
    echo "⚠️  .env file not found. Run setup.sh first."
fi
echo ""

echo "💾 Volume Status:"
echo "----------------"
docker volume ls | grep flutterpos
echo ""

echo "🏥 Comprehensive Health Check:"
echo "-----------------------------"
# Run the comprehensive health check
if [ -f "./health-check.sh" ]; then
    # Load environment variables for health check
    if [ -f .env ]; then
        source .env
        export DOMAIN
    fi
    ./health-check.sh
else
    echo "⚠️  health-check.sh not found. Running basic checks..."
    echo ""

    # Load environment variables
    if [ -f .env ]; then
        source .env
    fi

    # Basic health checks (fallback)
    # Check Traefik
    if curl -s -k https://traefik.${DOMAIN:-localhost} &> /dev/null 2>&1; then
        echo "✅ Traefik: Running"
    else
        echo "❌ Traefik: Not accessible"
    fi

    # Check Appwrite
    if curl -s -k https://appwrite.${DOMAIN:-localhost}/v1/health &> /dev/null 2>&1; then
        echo "✅ Appwrite API: Running"
    else
        echo "❌ Appwrite API: Not accessible"
    fi

    # Check Nextcloud
    if curl -s -k https://cloud.${DOMAIN:-localhost}/status.php &> /dev/null 2>&1; then
        echo "✅ Nextcloud: Running"
    else
        echo "❌ Nextcloud: Not accessible"
    fi

    # Check RabbitMQ
    if curl -s -k -u "posadmin:${RABBITMQ_PASS:-changeme_secure_password}" https://rabbitmq.${DOMAIN:-localhost}/api/overview &> /dev/null 2>&1; then
        echo "✅ RabbitMQ: Running"
    else
        echo "❌ RabbitMQ: Not accessible"
    fi

    # Check FlutterPOS Backend
    if curl -s -k https://backend.${DOMAIN:-localhost}/health &> /dev/null 2>&1; then
        echo "✅ FlutterPOS Backend: Running"
    else
        echo "❌ FlutterPOS Backend: Not accessible"
    fi
fi

echo ""
echo "📋 Useful Commands:"
echo "------------------"
echo "• View logs: $COMPOSE_CMD logs -f [service-name]"
echo "• Restart service: $COMPOSE_CMD restart [service-name]"
echo "• Stop all: $COMPOSE_CMD down"
echo "• Start all: $COMPOSE_CMD up -d"
echo "• Update: $COMPOSE_CMD pull && $COMPOSE_CMD up -d"
echo "• Backup: ./backup.sh"
echo "• Health check: ./health-check.sh"
echo ""
echo "💡 Legacy Commands:"
echo "   Start RabbitMQ:    ./start-rabbitmq.sh"
echo "   Stop RabbitMQ:     ./stop-rabbitmq.sh"
echo "   Remove Appwrite:   ./remove-appwrite.sh"
