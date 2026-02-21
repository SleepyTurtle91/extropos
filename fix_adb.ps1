# Fix ADB Connection Script
# Run this script when your tablet shows as "offline"

Write-Host "=== ADB Connection Fixer ===" -ForegroundColor Cyan
Write-Host ""

# Add ADB to PATH
$adbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools"
$env:Path += ";$adbPath"

Write-Host "Step 1: Restarting ADB server..." -ForegroundColor Yellow
adb kill-server
Start-Sleep -Seconds 1
adb start-server
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Step 2: Checking connected devices..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices
Write-Host ""

if ($devices -match "offline") {
    Write-Host "⚠️  Device is OFFLINE" -ForegroundColor Red
    Write-Host ""
    Write-Host "On your TABLET, you need to:" -ForegroundColor Yellow
    Write-Host "  1. Look for 'Allow USB debugging?' popup" -ForegroundColor White
    Write-Host "  2. Check 'Always allow from this computer'" -ForegroundColor White
    Write-Host "  3. Tap 'OK' or 'Allow'" -ForegroundColor White
    Write-Host ""
    Write-Host "If no popup appears:" -ForegroundColor Yellow
    Write-Host "  1. Go to Settings → Developer Options" -ForegroundColor White
    Write-Host "  2. Tap 'Revoke USB debugging authorizations'" -ForegroundColor White
    Write-Host "  3. Unplug and replug USB cable" -ForegroundColor White
    Write-Host "  4. The popup should appear now" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Press Enter after you've authorized USB debugging on tablet..." -ForegroundColor Cyan
    Read-Host
    
    Write-Host ""
    Write-Host "Checking again..." -ForegroundColor Yellow
    adb devices
}
elseif ($devices -match "device") {
    Write-Host "✅ Device is ONLINE and ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run:" -ForegroundColor Yellow
    Write-Host "  flutter devices" -ForegroundColor Cyan
    Write-Host "  flutter run" -ForegroundColor Cyan
}
else {
    Write-Host "❌ No device detected" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check:" -ForegroundColor Yellow
    Write-Host "  1. USB cable is properly connected" -ForegroundColor White
    Write-Host "  2. USB Debugging is enabled in Developer Options" -ForegroundColor White
    Write-Host "  3. USB mode is set to 'File Transfer' (not 'Charging only')" -ForegroundColor White
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
