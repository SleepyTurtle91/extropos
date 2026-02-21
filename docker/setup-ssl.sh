#!/bin/bash
# SSL Certificate Setup for api.extropos.org
# Run this script AFTER DNS is configured

set -e

DOMAIN="api.extropos.org"
EMAIL="your-email@example.com"  # UPDATE THIS!

echo "🔐 Setting up SSL certificates for $DOMAIN"
echo ""

# Step 1: Check if DNS is configured
echo "Step 1: Checking DNS configuration..."
IP=$(dig +short $DOMAIN)
if [ -z "$IP" ]; then
    echo "❌ ERROR: DNS not configured for $DOMAIN"
    echo "Please add an A record pointing to your server's public IP"
    exit 1
fi
echo "✅ DNS configured: $DOMAIN -> $IP"
echo ""

# Step 2: Create directories
echo "Step 2: Creating certificate directories..."
mkdir -p certbot/conf
mkdir -p certbot/www
mkdir -p nginx-logs
echo "✅ Directories created"
echo ""

# Step 3: Create temporary NGINX config (HTTP only)
echo "Step 3: Creating temporary NGINX config for certificate challenge..."
cat > api-nginx-temp.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name api.extropos.org;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 200 "Waiting for SSL setup...\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
echo "✅ Temporary config created"
echo ""

# Step 4: Start temporary NGINX
echo "Step 4: Starting NGINX for certificate challenge..."
docker run -d --name api-nginx-temp \
    -p 80:80 \
    -v $(pwd)/api-nginx-temp.conf:/etc/nginx/nginx.conf:ro \
    -v $(pwd)/certbot/www:/var/www/certbot:ro \
    nginx:alpine
echo "✅ NGINX started"
echo ""

# Step 5: Request certificate
echo "Step 5: Requesting SSL certificate from Let's Encrypt..."
docker run --rm \
    -v $(pwd)/certbot/conf:/etc/letsencrypt \
    -v $(pwd)/certbot/www:/var/www/certbot \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN

if [ $? -eq 0 ]; then
    echo "✅ SSL certificate obtained successfully!"
else
    echo "❌ Failed to obtain SSL certificate"
    docker stop api-nginx-temp
    docker rm api-nginx-temp
    exit 1
fi
echo ""

# Step 6: Stop temporary NGINX
echo "Step 6: Stopping temporary NGINX..."
docker stop api-nginx-temp
docker rm api-nginx-temp
echo "✅ Temporary NGINX removed"
echo ""

# Step 7: Start production stack
echo "Step 7: Starting production API with SSL..."
docker-compose -f api-docker-compose.yml up -d
echo "✅ Production stack started"
echo ""

echo "🎉 SSL setup complete!"
echo ""
echo "Your API is now available at:"
echo "  https://$DOMAIN/health"
echo ""
echo "Test it with:"
echo "  curl https://$DOMAIN/health"
echo ""
