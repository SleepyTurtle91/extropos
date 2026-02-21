# Cloudflare Tunnel Setup for Super Admin API
# Exposes local API to internet without opening firewall ports

param(
    [string]$Domain = "api.extropos.org",
    [string]$CloudflareToken = "D588VVxITISJNiBVbaklOKr_EMIeW2e5bV99AtVt"
)

Write-Host "🚇 Cloudflare Tunnel Setup" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Step 1: Download cloudflared
Write-Host "Step 1: Downloading Cloudflare Tunnel client..." -ForegroundColor Yellow
$cloudflaredPath = ".\cloudflared.exe"

if (-not (Test-Path $cloudflaredPath)) {
    Write-Host "   Downloading cloudflared..." -ForegroundColor Cyan
    $url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    Invoke-WebRequest -Uri $url -OutFile $cloudflaredPath -UseBasicParsing
    Write-Host "✅ Downloaded cloudflared" -ForegroundColor Green
} else {
    Write-Host "✅ cloudflared already exists" -ForegroundColor Green
}
Write-Host ""

# Step 2: Create tunnel config
Write-Host "Step 2: Creating tunnel configuration..." -ForegroundColor Yellow
$tunnelConfig = @"
tunnel: super-admin-api-tunnel
credentials-file: tunnel-credentials.json

ingress:
  # Route api.extropos.org to local API
  - hostname: $Domain
    service: http://super-admin-api:3001
    originRequest:
      noTLSVerify: true
  
  # Catch-all rule (required)
  - service: http_status:404
"@

$tunnelConfig | Out-File -FilePath "tunnel-config.yml" -Encoding UTF8
Write-Host "✅ Configuration created" -ForegroundColor Green
Write-Host ""

# Step 3: Authenticate with Cloudflare
Write-Host "Step 3: Authenticating with Cloudflare..." -ForegroundColor Yellow
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "⚠️  IMPORTANT: A browser window will open" -ForegroundColor Yellow
Write-Host "   1. Click 'Authorize' in the browser" -ForegroundColor White
Write-Host "   2. Select your 'extropos.org' domain" -ForegroundColor White
Write-Host "   3. Return here when done" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter when ready to open browser..." -ForegroundColor Cyan
$null = Read-Host

# Run authentication
& $cloudflaredPath tunnel login

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Authentication failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Authenticated with Cloudflare" -ForegroundColor Green
Write-Host ""

# Step 4: Create tunnel
Write-Host "Step 4: Creating Cloudflare Tunnel..." -ForegroundColor Yellow
& $cloudflaredPath tunnel create super-admin-api-tunnel

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Tunnel might already exist, continuing..." -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Get tunnel ID and credentials
Write-Host "Step 5: Getting tunnel information..." -ForegroundColor Yellow
$tunnelInfo = & $cloudflaredPath tunnel info super-admin-api-tunnel 2>&1 | Out-String

if ($tunnelInfo -match "Your tunnel ([a-f0-9-]+) has") {
    $tunnelId = $Matches[1]
    Write-Host "✅ Tunnel ID: $tunnelId" -ForegroundColor Green
    
    # Find credentials file
    $credPath = "$env:USERPROFILE\.cloudflared\$tunnelId.json"
    if (Test-Path $credPath) {
        Copy-Item $credPath -Destination "tunnel-credentials.json" -Force
        Write-Host "✅ Credentials copied" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  Checking for existing tunnel..." -ForegroundColor Yellow
    $tunnelList = & $cloudflaredPath tunnel list 2>&1 | Out-String
    if ($tunnelList -match "super-admin-api-tunnel") {
        Write-Host "✅ Using existing tunnel" -ForegroundColor Green
    }
}
Write-Host ""

# Step 6: Configure DNS
Write-Host "Step 6: Configuring DNS route..." -ForegroundColor Yellow
& $cloudflaredPath tunnel route dns super-admin-api-tunnel $Domain

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ DNS route configured" -ForegroundColor Green
} else {
    Write-Host "⚠️  DNS route might already exist" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Start tunnel as Docker container
Write-Host "Step 7: Starting Cloudflare Tunnel..." -ForegroundColor Yellow

# Stop existing tunnel if running
docker stop cloudflare-tunnel 2>$null
docker rm cloudflare-tunnel 2>$null

# Check if credentials file exists
if (-not (Test-Path "tunnel-credentials.json")) {
    Write-Host "⚠️  Credentials not found, using cloudflared directly..." -ForegroundColor Yellow
    Write-Host "   Starting tunnel in background..." -ForegroundColor Cyan
    
    Start-Process -FilePath $cloudflaredPath -ArgumentList "tunnel", "--config", "tunnel-config.yml", "run", "super-admin-api-tunnel" -WindowStyle Minimized
    Write-Host "✅ Tunnel started" -ForegroundColor Green
} else {
    # Run as Docker container
    docker run -d `
      --name cloudflare-tunnel `
      --restart unless-stopped `
      --network appwrite `
      -v "${PWD}\tunnel-config.yml:/etc/cloudflared/config.yml:ro" `
      -v "${PWD}\tunnel-credentials.json:/etc/cloudflared/tunnel-credentials.json:ro" `
      cloudflare/cloudflared:latest tunnel run
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Tunnel started as Docker container" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to start Docker container, trying direct..." -ForegroundColor Yellow
        Start-Process -FilePath $cloudflaredPath -ArgumentList "tunnel", "--config", "tunnel-config.yml", "run", "super-admin-api-tunnel" -WindowStyle Minimized
        Write-Host "✅ Tunnel started as process" -ForegroundColor Green
    }
}
Write-Host ""

# Step 8: Wait and test
Write-Host "Step 8: Testing connection..." -ForegroundColor Yellow
Write-Host "   Waiting for tunnel to establish..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

try {
    $response = Invoke-WebRequest -Uri "https://$Domain/health" -UseBasicParsing -TimeoutSec 30
    Write-Host "✅ API is accessible via HTTPS!" -ForegroundColor Green
    Write-Host "   Response: $($response.Content)" -ForegroundColor White
} catch {
    Write-Host "⚠️  Not ready yet (normal for first run)" -ForegroundColor Yellow
    Write-Host "   Tunnel is connecting..." -ForegroundColor Cyan
    Write-Host "   Wait 30 seconds and try:" -ForegroundColor Yellow
    Write-Host "   curl https://$Domain/health" -ForegroundColor White
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🎉 Cloudflare Tunnel Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Your API is now accessible at:" -ForegroundColor Cyan
Write-Host "  🌐 https://$Domain/health" -ForegroundColor White
Write-Host "  🔐 Automatic SSL by Cloudflare" -ForegroundColor Green
Write-Host "  🚀 No firewall ports needed!" -ForegroundColor Green
Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Cyan
Write-Host "  • https://$Domain/api/auth/register" -ForegroundColor White
Write-Host "  • https://$Domain/api/auth/login" -ForegroundColor White
Write-Host "  • https://$Domain/api/users/profile" -ForegroundColor White
Write-Host ""
Write-Host "Test from anywhere:" -ForegroundColor Cyan
Write-Host "  curl https://$Domain/health" -ForegroundColor White
Write-Host ""
Write-Host "Tunnel Status:" -ForegroundColor Cyan
Write-Host "  .\cloudflared.exe tunnel info super-admin-api-tunnel" -ForegroundColor White
Write-Host ""
