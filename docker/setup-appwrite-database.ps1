# FlutterPOS - Appwrite Database Setup Script
# Creates database and collections for POS system

param(
    [string]$ProjectId = "69792d39002f4a01e438",
    [string]$ApiKey = "f961a544a7399930c9491b231548bebc1e2e8a9ecefebe81a435c23c3db0f0d7e95e4a5b6493ed6f7689e97e0cd5a7720920003b455bf8dba8171fffb6bc7b9f18db2d486d8278fda3a9143d835dd8f1e2210fd7ed49f084b4bde9645ed5902ffd1be24f41a88543746a09f62f1d2c10eccfa55c0d019ee0c4a6488084132edf",
    [string]$Endpoint = "http://localhost:8080/v1"
)

Write-Host "FlutterPOS - Appwrite Database Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Content-Type" = "application/json"
    "X-Appwrite-Project" = $ProjectId
    "X-Appwrite-Key" = $ApiKey
}

# Function to make API calls
function Invoke-AppwriteAPI {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$Body = @{}
    )
    
    $uri = "$Endpoint$Path"
    
    try {
        if ($Body.Count -gt 0) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body $jsonBody -ContentType "application/json"
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
        }
        return $response
    } catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        return $null
    }
}

# 1. Create Database
Write-Host "1. Creating database 'pos_db'..." -ForegroundColor Yellow
$database = Invoke-AppwriteAPI -Method POST -Path "/databases" -Body @{
    databaseId = "pos_db"
    name = "POS Database"
}

if ($database) {
    Write-Host "  ✓ Database created successfully" -ForegroundColor Green
} else {
    Write-Host "  ℹ Database may already exist" -ForegroundColor Yellow
}

# 2. Create Collections
Write-Host ""
Write-Host "2. Creating collections..." -ForegroundColor Yellow

$collections = @(
    @{
        id = "categories"
        name = "Categories"
        permissions = @("read(`"any`")", "create(`"users`")", "update(`"users`")", "delete(`"users`")")
    },
    @{
        id = "products"
        name = "Products"
        permissions = @("read(`"any`")", "create(`"users`")", "update(`"users`")", "delete(`"users`")")
    },
    @{
        id = "transactions"
        name = "Transactions"
        permissions = @("read(`"users`")", "create(`"users`")", "update(`"users`")")
    },
    @{
        id = "users"
        name = "Users"
        permissions = @("read(`"users`")", "create(`"users`")", "update(`"users`")")
    },
    @{
        id = "tables"
        name = "Restaurant Tables"
        permissions = @("read(`"any`")", "create(`"users`")", "update(`"users`")", "delete(`"users`")")
    },
    @{
        id = "modifiers"
        name = "Product Modifiers"
        permissions = @("read(`"any`")", "create(`"users`")", "update(`"users`")", "delete(`"users`")")
    },
    @{
        id = "inventory"
        name = "Inventory"
        permissions = @("read(`"users`")", "create(`"users`")", "update(`"users`")")
    },
    @{
        id = "business_info"
        name = "Business Information"
        permissions = @("read(`"any`")", "create(`"users`")", "update(`"users`")")
    }
)

foreach ($collection in $collections) {
    Write-Host "  Creating collection: $($collection.name)..." -NoNewline
    
    $result = Invoke-AppwriteAPI -Method POST -Path "/databases/pos_db/collections" -Body @{
        collectionId = $collection.id
        name = $collection.name
        permissions = $collection.permissions
        documentSecurity = $true
    }
    
    if ($result) {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ℹ (may already exist)" -ForegroundColor Yellow
    }
    
    Start-Sleep -Milliseconds 500
}

# 3. Create Attributes for Categories Collection
Write-Host ""
Write-Host "3. Creating attributes for 'categories' collection..." -ForegroundColor Yellow

$categoryAttributes = @(
    @{ key = "name"; type = "string"; size = 255; required = $true }
    @{ key = "description"; type = "string"; size = 1000; required = $false }
    @{ key = "icon"; type = "string"; size = 100; required = $false }
    @{ key = "color"; type = "string"; size = 50; required = $false }
    @{ key = "sort_order"; type = "integer"; required = $false; default = 0 }
    @{ key = "is_active"; type = "boolean"; required = $false; default = $true }
)

foreach ($attr in $categoryAttributes) {
    Write-Host "  Adding attribute: $($attr.key)..." -NoNewline
    
    $body = @{
        key = $attr.key
        size = $attr.size
        required = $attr.required
    }
    
    if ($attr.ContainsKey("default")) {
        $body["default"] = $attr.default
    }
    
    $path = "/databases/pos_db/collections/categories/attributes/$($attr.type)"
    $result = Invoke-AppwriteAPI -Method POST -Path $path -Body $body
    
    if ($result) {
        Write-Host " ✓" -ForegroundColor Green
    }
    
    Start-Sleep -Milliseconds 500
}

# 4. Create Attributes for Products Collection
Write-Host ""
Write-Host "4. Creating attributes for 'products' collection..." -ForegroundColor Yellow

$productAttributes = @(
    @{ key = "name"; type = "string"; size = 255; required = $true }
    @{ key = "description"; type = "string"; size = 2000; required = $false }
    @{ key = "price"; type = "double"; required = $true }
    @{ key = "category_id"; type = "string"; size = 100; required = $true }
    @{ key = "sku"; type = "string"; size = 100; required = $false }
    @{ key = "icon"; type = "string"; size = 100; required = $false }
    @{ key = "image_url"; type = "string"; size = 500; required = $false }
    @{ key = "is_active"; type = "boolean"; required = $false; default = $true }
    @{ key = "stock_quantity"; type = "integer"; required = $false; default = 0 }
)

foreach ($attr in $productAttributes) {
    Write-Host "  Adding attribute: $($attr.key)..." -NoNewline
    
    $body = @{
        key = $attr.key
        required = $attr.required
    }
    
    if ($attr.ContainsKey("size")) {
        $body["size"] = $attr.size
    }
    
    if ($attr.ContainsKey("default")) {
        $body["default"] = $attr.default
    }
    
    $path = "/databases/pos_db/collections/products/attributes/$($attr.type)"
    $result = Invoke-AppwriteAPI -Method POST -Path $path -Body $body
    
    if ($result) {
        Write-Host " ✓" -ForegroundColor Green
    }
    
    Start-Sleep -Milliseconds 500
}

# 5. Create Storage Buckets
Write-Host ""
Write-Host "5. Creating storage buckets..." -ForegroundColor Yellow

$buckets = @(
    @{
        id = "product-images"
        name = "Product Images"
        permissions = @("read(`"any`")", "create(`"users`")", "update(`"users`")", "delete(`"users`")")
        fileSecurity = $true
        enabled = $true
        maximumFileSize = 10485760  # 10MB
        allowedFileExtensions = @("jpg", "jpeg", "png", "gif", "webp")
    },
    @{
        id = "receipts"
        name = "Receipts"
        permissions = @("read(`"users`")", "create(`"users`")")
        fileSecurity = $true
        enabled = $true
        maximumFileSize = 5242880  # 5MB
        allowedFileExtensions = @("pdf", "png", "jpg")
    }
)

foreach ($bucket in $buckets) {
    Write-Host "  Creating bucket: $($bucket.name)..." -NoNewline
    
    $result = Invoke-AppwriteAPI -Method POST -Path "/storage/buckets" -Body $bucket
    
    if ($result) {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ℹ (may already exist)" -ForegroundColor Yellow
    }
    
    Start-Sleep -Milliseconds 500
}

# Summary
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Database Setup Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created:" -ForegroundColor Yellow
Write-Host "  ✓ Database: pos_db" -ForegroundColor Green
Write-Host "  ✓ $($collections.Count) Collections" -ForegroundColor Green
Write-Host "  ✓ 2 Storage Buckets" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Go to: http://localhost:8080/console" -ForegroundColor White
Write-Host "  2. View your database structure" -ForegroundColor White
Write-Host "  3. Start adding products and categories" -ForegroundColor White
Write-Host ""
