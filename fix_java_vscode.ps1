# Fix VS Code Java Extension Issues
# Run this to resolve Java language server problems

Write-Host "=== VS Code Java Extension Fix ===" -ForegroundColor Cyan
Write-Host ""

# Check Java versions
Write-Host "Checking Java installations..." -ForegroundColor Yellow
cmd /c "java -version"
Write-Host ""

# Find Java home
$javaHome = $env:JAVA_HOME
if ($javaHome) {
    Write-Host "JAVA_HOME: $javaHome" -ForegroundColor Green
} else {
    Write-Host "JAVA_HOME not set" -ForegroundColor Yellow
}

# Check VS Code Java settings
Write-Host ""
Write-Host "VS Code Java Extension Issues:" -ForegroundColor Red
Write-Host "1. Language server expecting Java 25 but configured for Java 21" -ForegroundColor White
Write-Host "2. Named pipe connection failures" -ForegroundColor White
Write-Host "3. Maven integration shutdown" -ForegroundColor White
Write-Host ""

Write-Host "Solutions:" -ForegroundColor Yellow
Write-Host "1. Update VS Code Java extension settings:" -ForegroundColor White
Write-Host "   - Open VS Code Settings (Ctrl+,)" -ForegroundColor Cyan
Write-Host "   - Search for 'java.home'" -ForegroundColor Cyan
Write-Host "   - Set 'Java: Home' to: C:\Program Files\Eclipse Adoptium\jdk-25.0.1.8-hotspot" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. Or add to VS Code settings.json:" -ForegroundColor White
Write-Host '   "java.home": "C:\Program Files\Eclipse Adoptium\jdk-25.0.1.8-hotspot",' -ForegroundColor Cyan
Write-Host '   "java.configuration.runtimes": [' -ForegroundColor Cyan
Write-Host '     {' -ForegroundColor Cyan
Write-Host '       "name": "JavaSE-25",' -ForegroundColor Cyan
Write-Host '       "path": "C:\Program Files\Eclipse Adoptium\jdk-25.0.1.8-hotspot",' -ForegroundColor Cyan
Write-Host '       "default": true' -ForegroundColor Cyan
Write-Host '     }' -ForegroundColor Cyan
Write-Host '   ],' -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Restart VS Code after making changes" -ForegroundColor Yellow
Write-Host ""

Write-Host "4. Alternative: Reload Java Language Server" -ForegroundColor White
Write-Host "   - Ctrl+Shift+P → 'Java: Reload Projects'" -ForegroundColor Cyan
Write-Host "   - Or → 'Developer: Reload Window'" -ForegroundColor Cyan
Write-Host ""

Write-Host "Note: These are VS Code extension issues, not Flutter build issues." -ForegroundColor Green
Write-Host "Your Flutter app builds and runs fine!" -ForegroundColor Green
Write-Host ""

Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
