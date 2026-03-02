#!/bin/bash
# GitHub Release Upload Script for ExtroPOS v1.1.6
# This script uploads the APK and release notes to GitHub Releases

VERSION="1.1.6"
TAG="v1.1.6-20260302"
APK_FILE="build/app/outputs/flutter-apk/app-posapp-release.apk"
RELEASE_NOTES="RELEASE_v1.1.6.md"
REPO="SleepyTurtle91/extropos"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first:"
    echo "  https://cli.github.com"
    exit 1
fi

# Check if APK exists
if [ ! -f "$APK_FILE" ]; then
    echo "Error: APK file not found at $APK_FILE"
    exit 1
fi

# Check if release notes exist
if [ ! -f "$RELEASE_NOTES" ]; then
    echo "Error: Release notes file not found at $RELEASE_NOTES"
    exit 1
fi

# Get file size
APK_SIZE=$(ls -lh "$APK_FILE" | awk '{print $5}')

echo "=========================================="
echo "ExtroPOS v$VERSION Release Upload"
echo "=========================================="
echo "Repository: $REPO"
echo "Tag: $TAG"
echo "APK File: $APK_FILE ($APK_SIZE)"
echo "Release Notes: $RELEASE_NOTES"
echo ""

# Create GitHub release
echo "Creating GitHub release..."
gh release create "$TAG" \
    --repo "$REPO" \
    --title "ExtroPOS v$VERSION - Production Ready (March 2, 2026)" \
    --notes-file "$RELEASE_NOTES" \
    "$APK_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Release created successfully!"
    echo "View release: https://github.com/$REPO/releases/tag/$TAG"
else
    echo "❌ Failed to create release"
    exit 1
fi

echo ""
echo "To manually upload to GitHub:"
echo "1. Go to: https://github.com/$REPO/releases/tag/$TAG"
echo "2. Click 'Edit' on the release"
echo "3. Drag and drop the APK file to upload"
echo "4. Save changes"
