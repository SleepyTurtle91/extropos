# Appwrite Collections Setup Script
# Creates all required collections for FlutterPOS Backend
# Run this after setting up Appwrite instance

param(
    [string]$Endpoint = "https://appwrite.extropos.org/v1",
    [string]$ProjectId = "6940a64500383754a37f",
    [string]$DatabaseId = "pos_db",
    [switch]$DryRun = $false
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FlutterPOS Appwrite Collections Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Endpoint:   $Endpoint" -ForegroundColor Yellow
Write-Host "Project ID: $ProjectId" -ForegroundColor Yellow
Write-Host "Database:   $DatabaseId" -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No actual changes will be made" -ForegroundColor Magenta
    Write-Host ""
}

# Check if appwrite CLI is installed
$appwriteCmd = Get-Command appwrite -ErrorAction SilentlyContinue
if (-not $appwriteCmd) {
    Write-Host "❌ Error: Appwrite CLI not found" -ForegroundColor Red
    Write-Host "Install with: npm install -g appwrite-cli" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Appwrite CLI found: $($appwriteCmd.Version)" -ForegroundColor Green
Write-Host ""

# Collection configurations
$collections = @(
    @{
        Id = "backend_users"
        Name = "Backend Users"
        Description = "User accounts for backend management"
    },
    @{
        Id = "roles"
        Name = "Roles"
        Description = "RBAC roles with permissions"
    },
    @{
        Id = "activity_logs"
        Name = "Activity Logs"
        Description = "Audit trail for all operations"
    },
    @{
        Id = "inventory_items"
        Name = "Inventory Items"
        Description = "Stock tracking with movements"
    },
    @{
        Id = "products"
        Name = "Products"
        Description = "Product catalog with variants"
    },
    @{
        Id = "categories"
        Name = "Categories"
        Description = "Product categories with hierarchy"
    }
)

Write-Host "📋 Collections to create: $($collections.Count)" -ForegroundColor Cyan
Write-Host ""

foreach ($collection in $collections) {
    Write-Host "➡️  Creating collection: $($collection.Name) [$($collection.Id)]" -ForegroundColor Yellow
    
    if (-not $DryRun) {
        try {
            $cmd = "appwrite databases createCollection " +
                   "--databaseId $DatabaseId " +
                   "--collectionId $($collection.Id) " +
                   "--name `"$($collection.Name)`" " +
                   "--permissions `"create('users')`" `"read('users')`" `"update('users')`" `"delete('users')`""
            
            Write-Host "   Command: $cmd" -ForegroundColor Gray
            Invoke-Expression $cmd
            Write-Host "   ✅ Created: $($collection.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "   ⚠️  Warning: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "   (Collection may already exist)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "   [DRY RUN] Would create collection" -ForegroundColor Magenta
    }
    Write-Host ""
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📝 Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Create attributes for each collection:" -ForegroundColor Yellow
Write-Host "   See PRODUCT_CATEGORY_APPWRITE_SETUP.md for detailed commands" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Create indexes for performance:" -ForegroundColor Yellow
Write-Host "   - categoryId_idx for products" -ForegroundColor Gray
Write-Host "   - isActive_idx for products/categories" -ForegroundColor Gray
Write-Host "   - name_search fulltext for products" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test connectivity:" -ForegroundColor Yellow
Write-Host "   flutter test test/integration/appwrite_connectivity_test.dart --dart-define=REAL_APPWRITE=true" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Verify in Appwrite Console:" -ForegroundColor Yellow
Write-Host "   $Endpoint/console/project-$ProjectId/databases/database-$DatabaseId" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Collection creation complete!" -ForegroundColor Green
Write-Host ""
