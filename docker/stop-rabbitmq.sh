#!/bin/bash
# Stop RabbitMQ
# This script stops the RabbitMQ Docker container

cd "$(dirname "$0")/rabbitmq"

echo "🛑 Stopping RabbitMQ..."
docker-compose down

echo "✅ RabbitMQ stopped!"
echo ""
echo "💡 Data is preserved in Docker volume: rabbitmq_data"
echo "💡 Use './start-rabbitmq.sh' to start RabbitMQ again"
