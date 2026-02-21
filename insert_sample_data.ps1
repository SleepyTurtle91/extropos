# Insert sample transaction data for testing Horizon Dashboard
# Run this script to populate the database with test transactions

$endpoint = "http://localhost:8082/v1"
$projectId = "default"
$apiKey = "standard"

$headers = @{
    "X-Appwrite-Project" = $projectId
    "X-Appwrite-Key" = $apiKey
    "Content-Type" = "application/json"
}

# Sample transactions data
$transactions = @(
    @{
        transaction_number = "ORD-20251230-001"
        transaction_date = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        user_id = "user_1"
        subtotal = 25.00
        tax_amount = 2.50
        service_charge_amount = 0.00
        total_amount = 27.50
        payment_method = "cash"
        business_mode = "retail"
        items_json = '[{"productId":"prod_1","productName":"Coffee","quantity":2,"unitPrice":10.00,"lineTotal":20.00},{"productId":"prod_2","productName":"Croissant","quantity":1,"unitPrice":5.00,"lineTotal":5.00}]'
    },
    @{
        transaction_number = "ORD-20251230-002"
        transaction_date = [DateTimeOffset]::Now.AddHours(-2).ToUnixTimeMilliseconds()
        user_id = "user_1"
        subtotal = 15.00
        tax_amount = 1.50
        service_charge_amount = 0.00
        total_amount = 16.50
        payment_method = "card"
        business_mode = "retail"
        items_json = '[{"productId":"prod_1","productName":"Coffee","quantity":1,"unitPrice":10.00,"lineTotal":10.00},{"productId":"prod_3","productName":"Sandwich","quantity":1,"unitPrice":5.00,"lineTotal":5.00}]'
    },
    @{
        transaction_number = "ORD-20251230-003"
        transaction_date = [DateTimeOffset]::Now.AddHours(-4).ToUnixTimeMilliseconds()
        user_id = "user_2"
        subtotal = 35.00
        tax_amount = 3.50
        service_charge_amount = 0.00
        total_amount = 38.50
        payment_method = "cash"
        business_mode = "retail"
        items_json = '[{"productId":"prod_1","productName":"Coffee","quantity":3,"unitPrice":10.00,"lineTotal":30.00},{"productId":"prod_4","productName":"Cake","quantity":1,"unitPrice":5.00,"lineTotal":5.00}]'
    }
)

# Sample products data
$products = @(
    @{
        id = "prod_1"
        name = "Coffee"
        price = 10.00
        category_id = "cat_1"
        is_active = $true
    },
    @{
        id = "prod_2"
        name = "Croissant"
        price = 5.00
        category_id = "cat_2"
        is_active = $true
    },
    @{
        id = "prod_3"
        name = "Sandwich"
        price = 5.00
        category_id = "cat_2"
        is_active = $true
    },
    @{
        id = "prod_4"
        name = "Cake"
        price = 5.00
        category_id = "cat_2"
        is_active = $true
    }
)

Write-Host "Inserting sample products..."

foreach ($product in $products) {
    try {
        $jsonBody = $product | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$endpoint/databases/pos_db/collections/items/documents" -Method Post -Headers $headers -Body $jsonBody
        Write-Host "✅ Inserted product: $($product.name)"
    } catch {
        Write-Host "❌ Failed to insert product $($product.name): $($_.Exception.Message)"
    }
}

Write-Host "Inserting sample transactions..."

foreach ($transaction in $transactions) {
    try {
        $jsonBody = $transaction | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$endpoint/databases/pos_db/collections/transactions/documents" -Method Post -Headers $headers -Body $jsonBody
        Write-Host "✅ Inserted transaction: $($transaction.transaction_number)"
    } catch {
        Write-Host "❌ Failed to insert transaction $($transaction.transaction_number): $($_.Exception.Message)"
    }
}

Write-Host "Sample data insertion complete!"