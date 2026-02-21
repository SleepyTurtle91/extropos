#!/bin/bash

# Configure Firewall for RabbitMQ Cross-Network Access
# For Fedora/RHEL/CentOS (firewalld)

echo "🔥 Configuring Firewall for RabbitMQ..."
echo ""

# Check if firewalld is running
if ! systemctl is-active --quiet firewalld; then
    echo "⚠️  firewalld is not running. Skipping firewall configuration."
    echo "   If you're using ufw or iptables, configure manually."
    exit 0
fi

# Add RabbitMQ AMQP port (5672)
echo "📡 Opening port 5672 (AMQP)..."
sudo firewall-cmd --permanent --add-port=5672/tcp

# Add RabbitMQ Management UI port (15672)
echo "🖥️  Opening port 15672 (Management UI)..."
sudo firewall-cmd --permanent --add-port=15672/tcp

# Reload firewall
echo "🔄 Reloading firewall..."
sudo firewall-cmd --reload

echo ""
echo "✅ Firewall configured successfully!"
echo ""
echo "📋 Current firewall rules for RabbitMQ:"
sudo firewall-cmd --list-ports | grep -E "5672|15672"

echo ""
echo "🌐 Your PC's IP address(es):"
hostname -I

echo ""
echo "📝 Next steps:"
echo "   1. Restart RabbitMQ: cd docker && ./stop-rabbitmq.sh && ./start-rabbitmq.sh"
echo "   2. Test from POS device: Use your PC's IP (shown above) as RabbitMQ host"
echo "   3. Example POS settings:"
echo "      Host: $(hostname -I | awk '{print $1}')"
echo "      Port: 5672"
echo "      Username: posadmin"
echo "      Password: changeme_secure_password"
