# FlutterPOS - Build Script for Product Flavors (Windows PowerShell)
# Usage: .\build_flavors.ps1 [pos|kds|backend|dealer|all] [debug|release]

param(
    [string]$Flavor = "all",  # pos, kds, backend, dealer, or all
    [string]$BuildType = "release"
)

# Colors for output
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Blue"
$NC = "White"  # No Color

# Validate inputs
$validFlavors = @("pos", "kds", "backend", "dealer", "frontend", "all")
if ($validFlavors -notcontains $Flavor) {
    Write-Host "Error: Invalid flavor '$Flavor'. Use: pos, kds, backend, dealer, frontend, or all" -ForegroundColor $RED
    exit 1
}

$validBuildTypes = @("debug", "release")
if ($validBuildTypes -notcontains $BuildType) {
    Write-Host "Error: Invalid build type '$BuildType'. Use: debug or release" -ForegroundColor $RED
    exit 1
}

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor $BLUE
Write-Host "║   FlutterPOS Flavor Build Script      ║" -ForegroundColor $BLUE
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor $BLUE
Write-Host ""

# Function to get version from pubspec.yaml
function Get-Version {
    $pubspec = Get-Content "pubspec.yaml" | Select-String "version:" | ForEach-Object { $_.Line.Split(":")[1].Trim() }
    return $pubspec.Split("+")[0]
}

# Build POS App
function Build-POS {
    Write-Host "Building POS App ($BuildType)..." -ForegroundColor $YELLOW
    flutter build apk --$BuildType --flavor posApp --target lib/main.dart

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ POS App built successfully!" -ForegroundColor $GREEN
        $apkPath = "build/app/outputs/flutter-apk/app-posapp-$BuildType.apk"
        $apkSize = (Get-Item $apkPath).Length / 1MB
        Write-Host "  Location: $apkPath" -ForegroundColor $GREEN
        Write-Host ("  Size: {0:N2} MB" -f $apkSize) -ForegroundColor $GREEN

        # Copy to desktop with date tag
        $version = Get-Version
        $date = Get-Date -Format "yyyyMMdd"
        $desktopApk = "$env:USERPROFILE\Desktop\FlutterPOS-v$version-$date-pos.apk"
        Copy-Item $apkPath $desktopApk
        Write-Host "  Copied to: $desktopApk" -ForegroundColor $GREEN
        return $true
    } else {
        Write-Host "✗ POS App build failed!" -ForegroundColor $RED
        return $false
    }
}

# Build KDS App
function Build-KDS {
    Write-Host "Building KDS App ($BuildType)..." -ForegroundColor $YELLOW
    flutter build apk --$BuildType --flavor kdsApp --target lib/main_kds.dart

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ KDS App built successfully!" -ForegroundColor $GREEN
        $apkPath = "build/app/outputs/flutter-apk/app-kdsapp-$BuildType.apk"
        $apkSize = (Get-Item $apkPath).Length / 1MB
        Write-Host "  Location: $apkPath" -ForegroundColor $GREEN
        Write-Host ("  Size: {0:N2} MB" -f $apkSize) -ForegroundColor $GREEN

        # Copy to desktop with date tag
        $version = Get-Version
        $date = Get-Date -Format "yyyyMMdd"
        $desktopApk = "$env:USERPROFILE\Desktop\FlutterPOS-v$version-$date-kds.apk"
        Copy-Item $apkPath $desktopApk
        Write-Host "  Copied to: $desktopApk" -ForegroundColor $GREEN
        return $true
    } else {
        Write-Host "✗ KDS App build failed!" -ForegroundColor $RED
        return $false
    }
}

# Build Backend App (Web Only)
function Build-Backend {
    Write-Host "Building Backend App ($BuildType)..." -ForegroundColor $YELLOW
    flutter build web --$BuildType --target lib/main_backend.dart --no-tree-shake-icons

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Backend App built successfully!" -ForegroundColor $GREEN
        $webPath = "build/web"
        Write-Host "  Location: $webPath" -ForegroundColor $GREEN

        # Copy to desktop with date tag
        $version = Get-Version
        $date = Get-Date -Format "yyyyMMdd"
        $desktopWeb = "$env:USERPROFILE\Desktop\FlutterPOS-v$version-$date-backend-web"
        Copy-Item $webPath $desktopWeb -Recurse
        Write-Host "  Copied to: $desktopWeb" -ForegroundColor $GREEN
        return $true
    } else {
        Write-Host "✗ Backend App build failed!" -ForegroundColor $RED
        return $false
    }
}

# Build Dealer Portal App
function Build-Dealer {
    Write-Host "Building Dealer Portal App ($BuildType)..." -ForegroundColor $YELLOW
    flutter build web --$BuildType --target lib/main_dealer.dart

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Dealer Portal App built successfully!" -ForegroundColor $GREEN
        $webPath = "build/web"
        Write-Host "  Location: $webPath" -ForegroundColor $GREEN

        # Copy to desktop with date tag
        $version = Get-Version
        $date = Get-Date -Format "yyyyMMdd"
        $desktopWeb = "$env:USERPROFILE\Desktop\FlutterPOS-v$version-$date-dealer-web"
        Copy-Item $webPath $desktopWeb -Recurse
        Write-Host "  Copied to: $desktopWeb" -ForegroundColor $GREEN
        return $true
    } else {
        Write-Host "✗ Dealer Portal App build failed!" -ForegroundColor $RED
        return $false
    }
}

# Build Frontend Customer App
function Build-Frontend {
    Write-Host "Building Frontend Customer App ($BuildType)..." -ForegroundColor $YELLOW
    flutter build apk --$BuildType --flavor frontendApp --target lib/main_frontend.dart

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Frontend Customer App built successfully!" -ForegroundColor $GREEN
        $apkPath = "build/app/outputs/flutter-apk/app-frontendapp-$BuildType.apk"
        $apkSize = (Get-Item $apkPath).Length / 1MB
        Write-Host "  Location: $apkPath" -ForegroundColor $GREEN
        Write-Host ("  Size: {0:N2} MB" -f $apkSize) -ForegroundColor $GREEN

        # Copy to desktop with date tag
        $version = Get-Version
        $date = Get-Date -Format "yyyyMMdd"
        $desktopApk = "$env:USERPROFILE\Desktop\FlutterPOS-v$version-$date-frontend.apk"
        Copy-Item $apkPath $desktopApk
        Write-Host "  Copied to: $desktopApk" -ForegroundColor $GREEN
        return $true
    } else {
        Write-Host "✗ Frontend Customer App build failed!" -ForegroundColor $RED
        return $false
    }
}

# Execute builds based on flavor selection
Write-Host "Configuration:" -ForegroundColor $BLUE
Write-Host "  Flavor: $Flavor" -ForegroundColor $YELLOW
Write-Host "  Build Type: $BuildType" -ForegroundColor $YELLOW
Write-Host ""

$startTime = Get-Date

switch ($Flavor) {
    "pos" { Build-POS }
    "kds" { Build-KDS }
    "backend" { Build-Backend }
    "dealer" { Build-Dealer }
    "frontend" { Build-Frontend }
    default {
        # Build all flavors
        Build-POS
        Write-Host ""
        Build-KDS
        Write-Host ""
        Build-Backend
        Write-Host ""
        Build-Dealer
        Write-Host ""
        Build-Frontend
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor $BLUE
Write-Host "  Build completed in $([math]::Round($duration))s" -ForegroundColor $GREEN
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor $BLUE

# List all APKs
Write-Host ""
Write-Host "Available APKs:" -ForegroundColor $BLUE
$apks = Get-ChildItem "build/app/outputs/flutter-apk/app-*-$BuildType.apk" -ErrorAction SilentlyContinue
if ($apks) {
    $apks | ForEach-Object {
        $sizeMB = $_.Length / 1MB
        Write-Host ("  {0} ({1:N2} MB)" -f $_.Name, $sizeMB) -ForegroundColor $GREEN
    }
} else {
    Write-Host "No APKs found" -ForegroundColor $YELLOW
}