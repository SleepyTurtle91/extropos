# SSL Certificate Setup for api.extropos.org (Windows)
# Run this script AFTER DNS is configured

param(
    [string]$Domain = "api.extropos.org",
    [string]$Email = "abber8@gmail.com"
)

Write-Host "🔐 Setting up SSL certificates for $Domain" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if DNS is configured
Write-Host "Step 1: Checking DNS configuration..." -ForegroundColor Yellow
try {
    $IP = (Resolve-DnsName $Domain -Type A).IPAddress
    Write-Host "✅ DNS configured: $Domain -> $IP" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: DNS not configured for $Domain" -ForegroundColor Red
    Write-Host "Please add an A record pointing to your server's public IP" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Create directories
Write-Host "Step 2: Creating certificate directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "certbot\conf" | Out-Null
New-Item -ItemType Directory -Force -Path "certbot\www" | Out-Null
New-Item -ItemType Directory -Force -Path "nginx-logs" | Out-Null
Write-Host "✅ Directories created" -ForegroundColor Green
Write-Host ""

# Step 3: Create temporary NGINX config
Write-Host "Step 3: Creating temporary NGINX config..." -ForegroundColor Yellow
$tempConfig = @"
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $Domain;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 200 "Waiting for SSL setup...\n";
            add_header Content-Type text/plain;
        }
    }
}
"@
$tempConfig | Out-File -FilePath "api-nginx-temp.conf" -Encoding UTF8
Write-Host "✅ Temporary config created" -ForegroundColor Green
Write-Host ""

# Step 4: Start temporary NGINX
Write-Host "Step 4: Starting NGINX for certificate challenge..." -ForegroundColor Yellow
docker run -d --name api-nginx-temp `
    -p 80:80 `
    -v "${PWD}\api-nginx-temp.conf:/etc/nginx/nginx.conf:ro" `
    -v "${PWD}\certbot\www:/var/www/certbot:ro" `
    nginx:alpine
Write-Host "✅ NGINX started" -ForegroundColor Green
Write-Host ""

# Step 5: Wait for NGINX to be ready
Start-Sleep -Seconds 3

# Step 6: Request certificate
Write-Host "Step 5: Requesting SSL certificate from Let's Encrypt..." -ForegroundColor Yellow
docker run --rm `
    -v "${PWD}\certbot\conf:/etc/letsencrypt" `
    -v "${PWD}\certbot\www:/var/www/certbot" `
    certbot/certbot certonly `
    --webroot `
    --webroot-path=/var/www/certbot `
    --email $Email `
    --agree-tos `
    --no-eff-email `
    -d $Domain

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SSL certificate obtained successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to obtain SSL certificate" -ForegroundColor Red
    docker stop api-nginx-temp
    docker rm api-nginx-temp
    exit 1
}
Write-Host ""

# Step 7: Stop temporary NGINX
Write-Host "Step 6: Stopping temporary NGINX..." -ForegroundColor Yellow
docker stop api-nginx-temp
docker rm api-nginx-temp
Write-Host "✅ Temporary NGINX removed" -ForegroundColor Green
Write-Host ""

# Step 8: Stop current production API (if running)
Write-Host "Step 7: Stopping current production API..." -ForegroundColor Yellow
docker stop super-admin-api 2>$null
docker rm super-admin-api 2>$null
Write-Host "✅ Current API stopped" -ForegroundColor Green
Write-Host ""

# Step 9: Start production stack with SSL
Write-Host "Step 8: Starting production API with SSL..." -ForegroundColor Yellow
docker-compose -f api-docker-compose.yml up -d
Write-Host "✅ Production stack started" -ForegroundColor Green
Write-Host ""

Write-Host "🎉 SSL setup complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your API is now available at:" -ForegroundColor Green
Write-Host "  https://$Domain/health" -ForegroundColor White
Write-Host ""
Write-Host "Test it with:" -ForegroundColor Green
Write-Host "  curl https://$Domain/health" -ForegroundColor White
Write-Host ""
