# Build and Deploy Backend Admin Panel
# Option B: Docker-based deployment with Cloudflare Tunnel

Write-Host "🚀 Backend Admin Panel Deployment" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build Flutter web
Write-Host "Step 1: Building Flutter web backend..." -ForegroundColor Yellow
Push-Location "E:\flutterpos"

Write-Host "   Getting dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host "   Building web..." -ForegroundColor Cyan
flutter build web --release --web-renderer html

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "✅ Build complete" -ForegroundColor Green
Pop-Location
Write-Host ""

# Step 2: Setup Docker
Write-Host "Step 2: Creating Docker setup..." -ForegroundColor Yellow
Push-Location "E:\flutterpos\docker"

# NGINX config
$nginx = @"
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    gzip on;
    server {
        listen 8080;
        root /usr/share/nginx/html;
        index index.html;
        location / {
            try_files `$uri `$uri/ /index.html;
        }
        location /api/ {
            proxy_pass https://api.extropos.org/api/;
            proxy_set_header Host `$host;
        }
        location /health {
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
"@

$nginx | Out-File backend-nginx.conf -Encoding UTF8

# Dockerfile
$df = @"
FROM nginx:alpine
COPY ../build/web /usr/share/nginx/html
COPY backend-nginx.conf /etc/nginx/nginx.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
"@

$df | Out-File backend-web.Dockerfile -Encoding UTF8

Write-Host "   Building Docker image..." -ForegroundColor Cyan
docker build -f backend-web.Dockerfile -t backend-admin-web:latest ..

Write-Host "✅ Docker image created" -ForegroundColor Green
Write-Host ""

# Step 3: Start container
Write-Host "Step 3: Starting backend container..." -ForegroundColor Yellow

docker rm -f backend-admin 2>$null
docker run -d --name backend-admin --restart unless-stopped --network appwrite -p 3003:8080 backend-admin-web:latest

Write-Host "✅ Backend running on port 3003" -ForegroundColor Green
Write-Host ""

# Step 4: Update tunnel config
Write-Host "Step 4: Configuring Cloudflare Tunnel..." -ForegroundColor Yellow

$config = Get-Content tunnel-config.yml -Raw

if ($config -notmatch "backend.extropos.org") {
    $newRoute = @"

  - hostname: backend.extropos.org
    service: http://backend-admin:8080
"@
    $config = $config -replace "(- service: http_status)", ($newRoute + "`n`$1")
    $config | Out-File tunnel-config.yml -Encoding UTF8
    
    docker restart cloudflare-tunnel | Out-Null
    Start-Sleep -Seconds 3
}

Write-Host "✅ Tunnel configured" -ForegroundColor Green
Write-Host ""

# Step 5: DNS
Write-Host "Step 5: Setting up DNS..." -ForegroundColor Yellow

.\cloudflared.exe tunnel route dns super-admin-api-tunnel backend.extropos.org 2>&1 | Out-Null

Write-Host "✅ DNS configured" -ForegroundColor Green
Write-Host ""

# Step 6: Test
Write-Host "Step 6: Testing..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

try {
    curl https://backend.extropos.org/health 2>$null | Out-Null
    Write-Host "✅ Backend is LIVE!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Still loading..." -ForegroundColor Yellow
}

Pop-Location

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "🎉 Backend Admin Panel Deployed!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Access at: https://backend.extropos.org" -ForegroundColor Cyan
Write-Host "🔗 API URL:  https://api.extropos.org" -ForegroundColor Cyan
Write-Host ""
Write-Host "Container Status:" -ForegroundColor White
docker ps --filter "name=backend" --format "{{.Names}}\t{{.Status}}"
Write-Host ""
