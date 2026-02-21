#!/bin/bash
# Start RabbitMQ with Docker Compose
# This script starts RabbitMQ for FlutterPOS real-time sync

cd "$(dirname "$0")/rabbitmq"

echo "🐰 Starting RabbitMQ..."
docker-compose up -d

echo ""
echo "✅ RabbitMQ is starting up!"
echo ""
echo "📊 Access RabbitMQ Management UI:"
echo "   URL: http://localhost:15672"
echo "   Username: posadmin"
echo "   Password: changeme_secure_password"
echo ""
echo "🔌 AMQP Connection:"
echo "   Host: localhost"
echo "   Port: 5672"
echo ""
echo "💡 Use 'docker logs rabbitmq' to view logs"
echo "💡 Use './stop-rabbitmq.sh' to stop RabbitMQ"
