# GitHub Release Upload Script for ExtroPOS v1.1.6 (PowerShell)
# This script uploads the APK and release notes to GitHub Releases

param(
    [string]$APKPath = "build/app/outputs/flutter-apk/app-posapp-release.apk",
    [string]$ReleaseNotesPath = "RELEASE_v1.1.6.md"
)

$Version = "1.1.6"
$Tag = "v1.1.6-20260302"
$Repo = "SleepyTurtle91/extropos"

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "ExtroPOS v$Version Release Upload" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repository: $Repo" -ForegroundColor Green
Write-Host "Tag: $Tag" -ForegroundColor Green
Write-Host "APK Path: $APKPath"
Write-Host "Release Notes: $ReleaseNotesPath"
Write-Host ""

# Check if gh CLI is installed
$ghInstalled = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
if (-not $ghInstalled) {
    Write-Host "❌ GitHub CLI (gh) is not installed." -ForegroundColor Red
    Write-Host "   Install from: https://cli.github.com" -ForegroundColor Yellow
    exit 1
}

# Check if APK exists
if (-not (Test-Path $APKPath)) {
    Write-Host "❌ APK file not found at: $APKPath" -ForegroundColor Red
    exit 1
}

# Check if release notes exist
if (-not (Test-Path $ReleaseNotesPath)) {
    Write-Host "❌ Release notes file not found at: $ReleaseNotesPath" -ForegroundColor Red
    exit 1
}

# Get file info
$APKInfo = Get-Item $APKPath
$APKSize = "{0:N2} MB" -f ($APKInfo.Length / 1MB)

Write-Host "APK Size: $APKSize" -ForegroundColor Green
Write-Host ""

# Read release notes
$ReleaseNotes = Get-Content $ReleaseNotesPath -Raw

Write-Host "Creating GitHub release..." -ForegroundColor Cyan

# Create release with gh CLI
try {
    & gh release create $Tag `
        --repo $Repo `
        --title "ExtroPOS v$Version - Production Ready (March 2, 2026)" `
        --notes $ReleaseNotes `
        $APKPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Release created successfully!" -ForegroundColor Green
        Write-Host "   View: https://github.com/$Repo/releases/tag/$Tag" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Release details:" -ForegroundColor Green
        Write-Host "  • Tag: $Tag"
        Write-Host "  • APK: $(Split-Path $APKPath -Leaf) ($APKSize)"
        Write-Host "  • Repository: $Repo"
    }
    else {
        Write-Host "❌ Failed to create release" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "If gh CLI upload fails, upload manually:" -ForegroundColor Yellow
Write-Host "  1. Go to: https://github.com/$Repo/releases/tag/$Tag" -ForegroundColor Gray
Write-Host "  2. Click Edit on the release" -ForegroundColor Gray
Write-Host "  3. Drag/drop APK file to upload" -ForegroundColor Gray
Write-Host "  4. Save changes" -ForegroundColor Gray
