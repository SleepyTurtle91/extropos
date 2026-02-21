# Quick Install Script - FlutterPOS Refactored Printer Discovery
# Run this after 'flutter build apk --debug' completes

Write-Host "=== FlutterPOS - Install Refactored App ===" -ForegroundColor Cyan
Write-Host ""

# Add ADB to PATH
$env:Path += ";$env:LOCALAPPDATA\Android\sdk\platform-tools"

# Check if device is connected
Write-Host "Checking for connected devices..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices
Write-Host ""

if ($devices -match "device$") {
    Write-Host "✅ Device connected!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Installing APK..." -ForegroundColor Yellow
    adb install -r build\app\outputs\flutter-apk\app-debug.apk
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ App installed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🚀 Launching app..." -ForegroundColor Yellow
        adb shell monkey -p com.extrotarget.extropos -c android.intent.category.LAUNCHER 1
        Write-Host ""
        Write-Host "✅ App launched on your tablet!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Test Steps:" -ForegroundColor Cyan
        Write-Host "1. Go to Settings → Printers" -ForegroundColor White
        Write-Host "2. Tap USB icon (🔌) to scan USB printers" -ForegroundColor White
        Write-Host "3. Tap Bluetooth icon (📡) to scan Bluetooth printers" -ForegroundColor White
        Write-Host "4. Try adding a new printer with '+' button" -ForegroundColor White
        Write-Host "5. Check Printer Debug Console for detailed logs" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "❌ Installation failed!" -ForegroundColor Red
        Write-Host "Try running: adb install -r -d build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ No device detected!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Connect your tablet via USB" -ForegroundColor White
    Write-Host "2. Enable USB Debugging" -ForegroundColor White
    Write-Host "3. Run: .\fix_adb.ps1" -ForegroundColor White
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
