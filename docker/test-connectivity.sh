#!/bin/bash

# Test RabbitMQ Cross-Network Connectivity
# This script helps verify that POS and Backend can communicate through RabbitMQ

echo "🧪 RabbitMQ Cross-Network Connectivity Test"
echo "==========================================="
echo ""

# Get PC's IP address
PC_IP=$(hostname -I | awk '{print $1}')
echo "📍 Your PC's IP Address: $PC_IP"
echo ""

# Check if RabbitMQ is running
echo "1️⃣  Checking if RabbitMQ is running..."
if docker ps | grep -q rabbitmq; then
    echo "   ✅ RabbitMQ is running"
else
    echo "   ❌ RabbitMQ is not running!"
    echo "   Run: cd docker && ./start-rabbitmq.sh"
    exit 1
fi
echo ""

# Check if RabbitMQ is listening on all interfaces
echo "2️⃣  Checking if RabbitMQ is accessible from network..."
if sudo netstat -tlnp | grep -q "0.0.0.0:5672"; then
    echo "   ✅ RabbitMQ is listening on all interfaces (0.0.0.0:5672)"
else
    echo "   ❌ RabbitMQ is only listening on localhost!"
    echo "   Check docker/rabbitmq/docker-compose.yml ports configuration"
    exit 1
fi
echo ""

# Check firewall
echo "3️⃣  Checking firewall configuration..."
if sudo firewall-cmd --list-ports | grep -q "5672/tcp"; then
    echo "   ✅ Port 5672 is open in firewall"
else
    echo "   ⚠️  Port 5672 may be blocked by firewall"
    echo "   Run: ./configure-firewall.sh"
fi

if sudo firewall-cmd --list-ports | grep -q "15672/tcp"; then
    echo "   ✅ Port 15672 is open in firewall"
else
    echo "   ⚠️  Port 15672 may be blocked by firewall"
fi
echo ""

# Test RabbitMQ connection
echo "4️⃣  Testing RabbitMQ connection..."
if curl -s -u posadmin:changeme_secure_password http://localhost:15672/api/overview > /dev/null; then
    echo "   ✅ RabbitMQ API is accessible"
else
    echo "   ❌ Cannot connect to RabbitMQ API"
    exit 1
fi
echo ""

# Check active connections
echo "5️⃣  Checking active connections..."
CONNECTIONS=$(curl -s -u posadmin:changeme_secure_password http://localhost:15672/api/connections | grep -o '"name"' | wc -l)
echo "   📊 Active connections: $CONNECTIONS"
echo ""

# Instructions for POS device
echo "📱 POS Device Configuration"
echo "=============================="
echo ""
echo "Use these settings in your POS app (Settings → RabbitMQ):"
echo ""
echo "   Host: $PC_IP"
echo "   Port: 5672"
echo "   Username: posadmin"
echo "   Password: changeme_secure_password"
echo ""
echo "Then test connection from POS device."
echo ""

# Instructions for testing
echo "🧪 Testing Steps"
echo "================"
echo ""
echo "1. Backend App:"
echo "   - Run: flutter run -d linux lib/main_backend.dart"
echo "   - Go to Menu → RabbitMQ Settings"
echo "   - Host: localhost, Port: 5672"
echo "   - Test connection → Should show ✅"
echo "   - Enable 'Enable RabbitMQ Sync' and 'Auto-connect'"
echo ""
echo "2. Add Target POS:"
echo "   - Go to Menu → Target POS Terminals"
echo "   - Add your POS device's license key"
echo "   - Example: EXTRO-LIFE-ABC1-2345-WXYZ"
echo ""
echo "3. POS Device:"
echo "   - Install APK from build/app/outputs/flutter-apk/"
echo "   - Activate with license key (if not already)"
echo "   - Go to Settings → RabbitMQ"
echo "   - Host: $PC_IP, Port: 5672"
echo "   - Test connection → Should show ✅"
echo "   - Enable 'Enable RabbitMQ Sync' and 'Auto-connect'"
echo ""
echo "4. Test Sync:"
echo "   - Backend: Go to Menu → Items Management"
echo "   - Edit a product (change name or price)"
echo "   - Save"
echo "   - POS: Product should update within 2 seconds!"
echo ""

# Management UI
echo "🖥️  RabbitMQ Management UI"
echo "=========================="
echo ""
echo "   URL: http://localhost:15672"
echo "   Or from network: http://$PC_IP:15672"
echo "   Username: posadmin"
echo "   Password: changeme_secure_password"
echo ""
echo "   Use this to monitor connections, queues, and message flow."
echo ""

echo "✅ RabbitMQ is ready for cross-network testing!"
echo ""
echo "💡 Tip: Run this script again after connecting POS to see connection count."
