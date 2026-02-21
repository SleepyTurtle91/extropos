# Delete existing A record for backend.extropos.org and verify tunnel config

$token = "D588VVxITISJNiBVbaklOKr_EMIeW2e5bV99AtVt"
$zoneId = "ef557a5e467c69bc87ca93a0b98e61ac"

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "🔍 Fetching DNS records for backend.extropos.org..." -ForegroundColor Yellow

$url = "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records?name=backend.extropos.org"
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

if ($response.success) {
    Write-Host "Found $($response.result.Count) records:" -ForegroundColor Cyan
    foreach ($record in $response.result) {
        Write-Host "  ID: $($record.id)" -ForegroundColor White
        Write-Host "  Name: $($record.name)" -ForegroundColor White
        Write-Host "  Type: $($record.type)" -ForegroundColor White
        Write-Host "  Content: $($record.content)" -ForegroundColor White
        Write-Host "  Status: $($record.status)" -ForegroundColor White
        
        if ($record.type -eq "A") {
            Write-Host "`n🗑️  Deleting A record..." -ForegroundColor Yellow
            $deleteUrl = "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$($record.id)"
            $deleteResponse = Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete
            if ($deleteResponse.success) {
                Write-Host "✅ Deleted A record: $($record.name)" -ForegroundColor Green
            } else {
                Write-Host "❌ Failed to delete: $($deleteResponse.errors)" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "❌ Error fetching records: $($response.errors)" -ForegroundColor Red
}

Write-Host "`n✅ Cleanup complete. Now run tunnel route dns command." -ForegroundColor Green
