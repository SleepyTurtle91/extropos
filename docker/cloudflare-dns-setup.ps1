# Cloudflare DNS Automation for extropos.org
# Automatically creates A records for API subdomains

param(
    [string]$CloudflareToken = "D588VVxITISJNiBVbaklOKr_EMIeW2e5bV99AtVt",
    [string]$ZoneName = "extropos.org",
    [string]$ServerIP = "27.125.244.203"
)

Write-Host "🌐 Cloudflare DNS Setup for $ZoneName" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Cloudflare API endpoint
$ApiBase = "https://api.cloudflare.com/client/v4"
$Headers = @{
    "Authorization" = "Bearer $CloudflareToken"
    "Content-Type" = "application/json"
}

# Function to call Cloudflare API
function Invoke-CloudflareAPI {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null
    )
    
    $params = @{
        Method = $Method
        Uri = "$ApiBase$Endpoint"
        Headers = $Headers
    }
    
    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
    }
    
    try {
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Host "❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "   Details: $($errorObj.errors[0].message)" -ForegroundColor Red
        }
        return $null
    }
}

# Step 1: Get Zone ID
Write-Host "Step 1: Getting zone ID for $ZoneName..." -ForegroundColor Yellow
$zonesResponse = Invoke-CloudflareAPI -Method GET -Endpoint "/zones?name=$ZoneName"

if (-not $zonesResponse -or $zonesResponse.result.Count -eq 0) {
    Write-Host "❌ Zone not found: $ZoneName" -ForegroundColor Red
    Write-Host "   Make sure the domain is added to your Cloudflare account" -ForegroundColor Red
    exit 1
}

$ZoneID = $zonesResponse.result[0].id
Write-Host "✅ Zone ID: $ZoneID" -ForegroundColor Green
Write-Host ""

# Step 2: Get existing DNS records (both A and CNAME)
Write-Host "Step 2: Checking existing DNS records..." -ForegroundColor Yellow
$existingARecords = Invoke-CloudflareAPI -Method GET -Endpoint "/zones/$ZoneID/dns_records?type=A"
$existingCNAMERecords = Invoke-CloudflareAPI -Method GET -Endpoint "/zones/$ZoneID/dns_records?type=CNAME"

# Function to create or update DNS record
function Set-DNSRecord {
    param(
        [string]$Name,
        [string]$IP
    )
    
    $fullName = "$Name.$ZoneName"
    Write-Host "  📝 Processing: $fullName" -ForegroundColor Cyan
    
    # Check if CNAME record exists (must be deleted first)
    $existingCNAME = $existingCNAMERecords.result | Where-Object { $_.name -eq $fullName }
    if ($existingCNAME) {
        Write-Host "     🗑️ Deleting existing CNAME record..." -ForegroundColor Yellow
        $deleteResult = Invoke-CloudflareAPI -Method DELETE -Endpoint "/zones/$ZoneID/dns_records/$($existingCNAME.id)"
        if ($deleteResult) {
            Write-Host "     ✅ CNAME deleted" -ForegroundColor Green
        }
        Start-Sleep -Seconds 1
    }
    
    # Check if A record exists
    $existing = $existingARecords.result | Where-Object { $_.name -eq $fullName }
    
    if ($existing) {
        # Update existing record
        if ($existing.content -eq $IP) {
            Write-Host "     ✅ Already configured with correct IP" -ForegroundColor Green
            return $true
        }
        
        Write-Host "     🔄 Updating existing record..." -ForegroundColor Yellow
        $updateBody = @{
            type = "A"
            name = $Name
            content = $IP
            ttl = 300
            proxied = $false
        }
        
        $result = Invoke-CloudflareAPI -Method PUT -Endpoint "/zones/$ZoneID/dns_records/$($existing.id)" -Body $updateBody
        
        if ($result) {
            Write-Host "     ✅ Updated: $fullName -> $IP" -ForegroundColor Green
            return $true
        } else {
            Write-Host "     ❌ Failed to update" -ForegroundColor Red
            return $false
        }
    } else {
        # Create new record
        Write-Host "     ➕ Creating new record..." -ForegroundColor Yellow
        $createBody = @{
            type = "A"
            name = $Name
            content = $IP
            ttl = 300
            proxied = $false
        }
        
        $result = Invoke-CloudflareAPI -Method POST -Endpoint "/zones/$ZoneID/dns_records" -Body $createBody
        
        if ($result) {
            Write-Host "     ✅ Created: $fullName -> $IP" -ForegroundColor Green
            return $true
        } else {
            Write-Host "     ❌ Failed to create" -ForegroundColor Red
            return $false
        }
    }
}

# Step 3: Create/Update DNS records
Write-Host ""
Write-Host "Step 3: Creating/Updating DNS records..." -ForegroundColor Yellow

$subdomains = @("api", "backend", "appwrite")
$results = @{}

foreach ($subdomain in $subdomains) {
    $results[$subdomain] = Set-DNSRecord -Name $subdomain -IP $ServerIP
}

Write-Host ""

# Step 4: Verify DNS propagation
Write-Host "Step 4: Verifying DNS records..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

$allSuccess = $true
foreach ($subdomain in $subdomains) {
    $fullName = "$subdomain.$ZoneName"
    try {
        $resolved = (Resolve-DnsName $fullName -Type A -ErrorAction SilentlyContinue).IPAddress
        if ($resolved -eq $ServerIP) {
            Write-Host "  ✅ $fullName -> $resolved" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ $fullName -> $resolved (expected $ServerIP, may need time to propagate)" -ForegroundColor Yellow
            $allSuccess = $false
        }
    } catch {
        Write-Host "  ⏳ $fullName -> Not resolved yet (propagating...)" -ForegroundColor Yellow
        $allSuccess = $false
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($allSuccess) {
    Write-Host "🎉 DNS setup complete and verified!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your API endpoints will be:" -ForegroundColor Cyan
    Write-Host "  • https://api.extropos.org" -ForegroundColor White
    Write-Host "  • https://backend.extropos.org" -ForegroundColor White
    Write-Host "  • https://appwrite.extropos.org" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Ready for SSL setup! Run:" -ForegroundColor Green
    Write-Host "   .\setup-ssl.ps1" -ForegroundColor White
} else {
    Write-Host "⚠️ DNS records created but not fully propagated yet" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Wait 2-5 minutes and verify with:" -ForegroundColor Cyan
    Write-Host "  Resolve-DnsName api.extropos.org -Type A" -ForegroundColor White
    Write-Host ""
    Write-Host "Once DNS resolves, run SSL setup:" -ForegroundColor Cyan
    Write-Host "  .\setup-ssl.ps1" -ForegroundColor White
}

Write-Host ""
