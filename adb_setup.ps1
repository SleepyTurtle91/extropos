# ADB Setup Script for FlutterPOS
# Add ADB to PATH for easy access

$adbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools"
$env:Path += ";$adbPath"

Write-Host "ADB is now available in this PowerShell session." -ForegroundColor Green
Write-Host "You can run commands like:" -ForegroundColor Yellow
Write-Host "  adb devices" -ForegroundColor Cyan
Write-Host "  adb logcat" -ForegroundColor Cyan
Write-Host "  adb shell" -ForegroundColor Cyan
Write-Host ""

Write-Host "Your connected device:" -ForegroundColor Yellow
adb devices
Write-Host ""

Write-Host "Device info:" -ForegroundColor Yellow
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
Write-Host ""

Write-Host "To run Flutter on your tablet:" -ForegroundColor Yellow
Write-Host "  flutter run -d 8bab44b57d88" -ForegroundColor Cyan