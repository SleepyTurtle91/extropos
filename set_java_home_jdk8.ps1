# Set JDK 8 for VS Code Java Extension
# Run this to set JAVA_HOME environment variable

# Auto-detect Temurin JDK 8 installation and set JAVA_HOME for current user
$installRoot = 'C:\Program Files\Eclipse Adoptium'
$jdkDir = Get-ChildItem -Path $installRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^jdk-8' } | Sort-Object Name -Descending | Select-Object -First 1

if (-not $jdkDir) {
    Write-Host "❌ Temurin JDK 8 not found under $installRoot. Please install it first." -ForegroundColor Red
    exit 1
}

$jdkPath = $jdkDir.FullName

Write-Host "Setting JAVA_HOME to JDK 8: $jdkPath" -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkPath, "User")

# Ensure %JAVA_HOME%\bin is in User PATH
$current = [Environment]::GetEnvironmentVariable('Path','User')
$binPath = "$jdkPath\bin"
if (-not ($current -split ';' | Where-Object { $_ -eq $binPath })) {
    [Environment]::SetEnvironmentVariable('Path', "$current;$binPath", 'User')
    Write-Host "Added $binPath to User PATH" -ForegroundColor Green
} else {
    Write-Host "$binPath already present in User PATH" -ForegroundColor Yellow
}

Write-Host "JAVA_HOME set to: $jdkPath" -ForegroundColor Green
Write-Host ""
Write-Host "Restart VS Code (and any open terminals) for changes to take effect." -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: This affects all Java applications for your user account." -ForegroundColor Yellow
Write-Host "Flutter will still use Android Studio JDK 21 unless configured otherwise." -ForegroundColor Green
