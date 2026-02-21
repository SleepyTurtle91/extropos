# VS Code Java Configuration for JDK 8
# Add this to your VS Code settings.json

Write-Host "=== VS Code Java JDK 8 Configuration ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Your JDK 8 is installed at:" -ForegroundColor Green
Write-Host "D:\GitHub\java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64" -ForegroundColor White
Write-Host ""

Write-Host "Add this to your VS Code settings.json:" -ForegroundColor Yellow
Write-Host ""

Write-Host '{' -ForegroundColor Cyan
Write-Host '  "java.home": "D:\\GitHub\\java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64",' -ForegroundColor White
Write-Host '  "java.configuration.runtimes": [' -ForegroundColor White
Write-Host '    {' -ForegroundColor White
Write-Host '      "name": "JavaSE-1.8",' -ForegroundColor White
Write-Host '      "path": "D:\\GitHub\\java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64",' -ForegroundColor White
Write-Host '      "default": true' -ForegroundColor White
Write-Host '    }' -ForegroundColor White
Write-Host '  ],' -ForegroundColor White
Write-Host '  "java.jdt.ls.java.home": "D:\\GitHub\\java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64\\bin\\java.exe"' -ForegroundColor White
Write-Host '}' -ForegroundColor Cyan
Write-Host ""

Write-Host "How to add to VS Code:" -ForegroundColor Yellow
Write-Host "1. Open VS Code" -ForegroundColor White
Write-Host "2. Ctrl+Shift+P → 'Preferences: Open Settings (JSON)'" -ForegroundColor White
Write-Host "3. Add the above configuration" -ForegroundColor White
Write-Host "4. Save and restart VS Code" -ForegroundColor White
Write-Host ""

Write-Host "Note: Flutter will continue using Android Studio JDK 21" -ForegroundColor Green
Write-Host "This only affects VS Code Java language server" -ForegroundColor Green
Write-Host ""

Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
