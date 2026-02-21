# Setup Super Admin API with Traefik SSL
# Uses existing Appwrite Traefik for SSL termination

param(
    [string]$Domain = "api.extropos.org"
)

Write-Host "🔐 Setting up API with Traefik SSL" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check DNS
Write-Host "Step 1: Verifying DNS..." -ForegroundColor Yellow
try {
    $IP = (Resolve-DnsName $Domain -Type A).IPAddress
    Write-Host "✅ DNS configured: $Domain -> $IP" -ForegroundColor Green
} catch {
    Write-Host "❌ DNS not configured for $Domain" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Check Traefik is running
Write-Host "Step 2: Checking Traefik..." -ForegroundColor Yellow
$traefik = docker ps --filter "name=appwrite-traefik" --format "{{.Names}}"
if (-not $traefik) {
    Write-Host "❌ Appwrite Traefik not running" -ForegroundColor Red
    Write-Host "   Start Appwrite first: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Traefik is running" -ForegroundColor Green
Write-Host ""

# Step 3: Stop current production API if running standalone
Write-Host "Step 3: Preparing API container..." -ForegroundColor Yellow
$currentApi = docker ps -q --filter "name=super-admin-api"
if ($currentApi) {
    Write-Host "   Stopping standalone API container..." -ForegroundColor Yellow
    docker stop super-admin-api | Out-Null
    docker rm super-admin-api | Out-Null
}
Write-Host "✅ API container ready" -ForegroundColor Green
Write-Host ""

# Step 4: Create Traefik config directory
Write-Host "Step 4: Setting up Traefik configuration..." -ForegroundColor Yellow
$appwriteDir = "E:\flutterpos\docker\appwrite"
if (-not (Test-Path $appwriteDir)) {
    Write-Host "❌ Appwrite directory not found: $appwriteDir" -ForegroundColor Red
    Write-Host "   Looking for alternative location..." -ForegroundColor Yellow
    
    # Check if we're in docker directory
    if (Test-Path ".\docker-compose.yml") {
        $appwriteDir = "."
    } else {
        Write-Host "❌ Cannot find Appwrite installation" -ForegroundColor Red
        exit 1
    }
}

# Create traefik dynamic config directory if it doesn't exist
$traefikConfigDir = Join-Path $appwriteDir "traefik-config"
if (-not (Test-Path $traefikConfigDir)) {
    New-Item -ItemType Directory -Path $traefikConfigDir -Force | Out-Null
}

# Copy our API config to Traefik
Copy-Item "traefik-api-config.yml" -Destination "$traefikConfigDir\api.yml" -Force
Write-Host "✅ Traefik configuration updated" -ForegroundColor Green
Write-Host ""

# Step 5: Update docker-compose to include Traefik config volume
Write-Host "Step 5: Checking docker-compose configuration..." -ForegroundColor Yellow
$composeFile = Join-Path $appwriteDir "docker-compose.yml"
if (Test-Path $composeFile) {
    $composeContent = Get-Content $composeFile -Raw
    
    if ($composeContent -notmatch "traefik-config") {
        Write-Host "⚠️  Manual step required:" -ForegroundColor Yellow
        Write-Host "   Add this volume to Traefik service in docker-compose.yml:" -ForegroundColor Cyan
        Write-Host "   - ./traefik-config:/etc/traefik/dynamic:ro" -ForegroundColor White
        Write-Host ""
        Write-Host "   Then restart Traefik:" -ForegroundColor Cyan
        Write-Host "   docker-compose restart appwrite-traefik" -ForegroundColor White
    } else {
        Write-Host "✅ Docker compose already configured" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  Using Traefik without docker-compose modification" -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Start API with Traefik labels
Write-Host "Step 6: Starting API with Traefik integration..." -ForegroundColor Yellow

docker run -d `
  --name super-admin-api `
  --restart unless-stopped `
  --network appwrite `
  -e PORT=3001 `
  -e NODE_ENV=production `
  -e APPWRITE_ENDPOINT=http://appwrite-api:80/v1 `
  -e APPWRITE_PROJECT_ID=6940a64500383754a37f `
  -e APPWRITE_API_KEY=088ea83f36a48f15cc11adf63392f2da1f98f16aa554fa161baf5b28044bcd94ae3cd5e8c0365b161aadbfecb8e3cfa00e4ef24e46299903586388203272156da954c2b4204971321233701997c5bcda4764d25f774ac54fbfc595524a2900b4e216d35cbea9a1923970a099cc89463880f2b110f8362a7fdd1231f0e628b03f `
  -e JWT_SECRET=your-very-secure-jwt-secret-key-change-this-in-production `
  -e SUPER_ADMIN_API_KEY=088ea83f36a48f15cc11adf63392f2da1f98f16aa554fa161baf5b28044bcd94ae3cd5e8c0365b161aadbfecb8e3cfa00e4ef24e46299903586388203272156da954c2b4204971321233701997c5bcda4764d25f774ac54fbfc595524a2900b4e216d35cbea9a1923970a099cc89463880f2b110f8362a7fdd1231f0e628b03f `
  -e ALLOWED_ORIGINS=https://backend.extropos.org,https://api.extropos.org `
  --label "traefik.enable=true" `
  --label "traefik.http.routers.super-admin-api.rule=Host(\`api.extropos.org\`)" `
  --label "traefik.http.routers.super-admin-api.entrypoints=https" `
  --label "traefik.http.routers.super-admin-api.tls=true" `
  --label "traefik.http.routers.super-admin-api.tls.certresolver=letsencrypt" `
  --label "traefik.http.services.super-admin-api.loadbalancer.server.port=3001" `
  docker-super-admin-api:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ API started with Traefik labels" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to start API" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 7: Restart Traefik to pick up new config
Write-Host "Step 7: Reloading Traefik..." -ForegroundColor Yellow
docker restart appwrite-traefik | Out-Null
Start-Sleep -Seconds 5
Write-Host "✅ Traefik reloaded" -ForegroundColor Green
Write-Host ""

# Step 8: Wait for SSL certificate
Write-Host "Step 8: Waiting for SSL certificate generation..." -ForegroundColor Yellow
Write-Host "   This may take 30-60 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Step 9: Test the API
Write-Host ""
Write-Host "Step 9: Testing API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$Domain/health" -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ API is accessible via HTTPS!" -ForegroundColor Green
    Write-Host "   Response: $($response.Content)" -ForegroundColor White
} catch {
    Write-Host "⚠️  HTTPS not ready yet (this is normal)" -ForegroundColor Yellow
    Write-Host "   Traefik is generating SSL certificate..." -ForegroundColor Cyan
    Write-Host "   Wait 1-2 minutes and try:" -ForegroundColor Yellow
    Write-Host "   curl https://$Domain/health" -ForegroundColor White
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🎉 Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Your API will be available at:" -ForegroundColor Cyan
Write-Host "  https://$Domain/health" -ForegroundColor White
Write-Host "  https://$Domain/api/auth/register" -ForegroundColor White
Write-Host ""
Write-Host "SSL certificate will be auto-generated by Traefik" -ForegroundColor Green
Write-Host "Wait 1-2 minutes if HTTPS is not accessible yet" -ForegroundColor Yellow
Write-Host ""
Write-Host "Check Traefik dashboard:" -ForegroundColor Cyan
Write-Host "  http://localhost:8090" -ForegroundColor White
Write-Host ""
