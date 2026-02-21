# FlutterPOS User Management Database Setup
# Creates users and sessions collections in Appwrite

param(
    [string]$AppwriteEndpoint = "http://localhost:8080/v1",
    [string]$ProjectId = "69792d39002f4a01e438",
    [string]$ApiKey = $env:APPWRITE_API_KEY
)

Write-Host "=== FlutterPOS User Management Database Setup ===" -ForegroundColor Cyan
Write-Host ""

if (-not $ApiKey) {
    Write-Host "Error: APPWRITE_API_KEY environment variable not set" -ForegroundColor Red
    exit 1
}

$headers = @{
    "X-Appwrite-Project" = $ProjectId
    "X-Appwrite-Key" = $ApiKey
    "Content-Type" = "application/json"
}

$databaseId = "pos_db"

# Function to create collection
function New-Collection {
    param($name, $collectionId, $permissions)
    
    Write-Host "Creating collection: $name..." -ForegroundColor Yellow
    
    $body = @{
        collectionId = $collectionId
        name = $name
        permissions = $permissions
        documentSecurity = $true
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$AppwriteEndpoint/databases/$databaseId/collections" `
            -Method Post -Headers $headers -Body $body
        Write-Host "✓ Collection '$name' created" -ForegroundColor Green
        return $response
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "! Collection '$name' already exists" -ForegroundColor Yellow
        }
        else {
            Write-Host "✗ Failed to create collection '$name': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to create attribute
function New-Attribute {
    param($collectionId, $key, $type, $size, $required, $default = $null)
    
    $body = @{
        key = $key
        type = $type
        size = $size
        required = $required
    }
    
    if ($default -ne $null) {
        $body.default = $default
    }
    
    $bodyJson = $body | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$AppwriteEndpoint/databases/$databaseId/collections/$collectionId/attributes/$type" `
            -Method Post -Headers $headers -Body $bodyJson
        Write-Host "  ✓ Attribute '$key' ($type) created" -ForegroundColor Green
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "  ! Attribute '$key' already exists" -ForegroundColor Yellow
        }
        else {
            Write-Host "  ✗ Failed to create attribute '$key': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to create index
function New-Index {
    param($collectionId, $key, $type, $attributes)
    
    $body = @{
        key = $key
        type = $type
        attributes = $attributes
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$AppwriteEndpoint/databases/$databaseId/collections/$collectionId/indexes" `
            -Method Post -Headers $headers -Body $body
        Write-Host "  ✓ Index '$key' created" -ForegroundColor Green
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "  ! Index '$key' already exists" -ForegroundColor Yellow
        }
        else {
            Write-Host "  ✗ Failed to create index '$key': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "Step 1: Creating users collection..." -ForegroundColor Cyan
New-Collection -name "users" -collectionId "users" -permissions @("read(`"any`")")

Write-Host "`nStep 2: Adding attributes to users collection..." -ForegroundColor Cyan
New-Attribute -collectionId "users" -key "email" -type "string" -size 255 -required $true
New-Attribute -collectionId "users" -key "name" -type "string" -size 255 -required $true
New-Attribute -collectionId "users" -key "password_hash" -type "string" -size 255 -required $true
New-Attribute -collectionId "users" -key "pin" -type "string" -size 255 -required $false
New-Attribute -collectionId "users" -key "role" -type "string" -size 50 -required $true -default "cashier"
New-Attribute -collectionId "users" -key "is_active" -type "boolean" -size 0 -required $true -default $true
New-Attribute -collectionId "users" -key "permissions" -type "string" -size 1000 -required $false
New-Attribute -collectionId "users" -key "phone" -type "string" -size 20 -required $false
New-Attribute -collectionId "users" -key "avatar_url" -type "string" -size 500 -required $false
New-Attribute -collectionId "users" -key "last_login" -type "integer" -size 0 -required $false
New-Attribute -collectionId "users" -key "failed_login_attempts" -type "integer" -size 0 -required $true -default 0
New-Attribute -collectionId "users" -key "locked_until" -type "integer" -size 0 -required $false
New-Attribute -collectionId "users" -key "created_at" -type "integer" -size 0 -required $true
New-Attribute -collectionId "users" -key "updated_at" -type "integer" -size 0 -required $true

Write-Host "`nStep 3: Creating indexes for users collection..." -ForegroundColor Cyan
New-Index -collectionId "users" -key "email_idx" -type "unique" -attributes @("email")
New-Index -collectionId "users" -key "role_idx" -type "key" -attributes @("role")
New-Index -collectionId "users" -key "is_active_idx" -type "key" -attributes @("is_active")
New-Index -collectionId "users" -key "created_at_idx" -type "key" -attributes @("created_at")

Write-Host "`nStep 4: Creating sessions collection..." -ForegroundColor Cyan
New-Collection -name "sessions" -collectionId "sessions" -permissions @("read(`"any`")")

Write-Host "`nStep 5: Adding attributes to sessions collection..." -ForegroundColor Cyan
New-Attribute -collectionId "sessions" -key "user_id" -type "string" -size 255 -required $true
New-Attribute -collectionId "sessions" -key "token_hash" -type "string" -size 255 -required $true
New-Attribute -collectionId "sessions" -key "device_info" -type "string" -size 255 -required $false
New-Attribute -collectionId "sessions" -key "ip_address" -type "string" -size 50 -required $false
New-Attribute -collectionId "sessions" -key "user_agent" -type "string" -size 500 -required $false
New-Attribute -collectionId "sessions" -key "expires_at" -type "integer" -size 0 -required $true
New-Attribute -collectionId "sessions" -key "created_at" -type "integer" -size 0 -required $true
New-Attribute -collectionId "sessions" -key "last_activity" -type "integer" -size 0 -required $true

Write-Host "`nStep 6: Creating indexes for sessions collection..." -ForegroundColor Cyan
New-Index -collectionId "sessions" -key "user_id_idx" -type "key" -attributes @("user_id")
New-Index -collectionId "sessions" -key "token_hash_idx" -type "unique" -attributes @("token_hash")
New-Index -collectionId "sessions" -key "expires_at_idx" -type "key" -attributes @("expires_at")

Write-Host "`n=== User Management Database Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Collections created:" -ForegroundColor Cyan
Write-Host "  - users (14 attributes, 4 indexes)"
Write-Host "  - sessions (8 attributes, 3 indexes)"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Create default admin user"
Write-Host "  2. Test authentication flow"
Write-Host "  3. Implement backend API endpoints"
Write-Host ""
