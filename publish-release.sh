#!/bin/bash

# FlutterPOS Release Publisher
# This script builds an APK, creates a git tag, and publishes a GitHub release

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
BUILD=$(grep "^version:" pubspec.yaml | sed 's/.*+//')
DATE=$(date +%Y%m%d)
TAG="v${VERSION}-${DATE}"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   FlutterPOS Release Publisher        ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""
echo -e "${GREEN}Version:${NC} $VERSION (Build $BUILD)"
echo -e "${GREEN}Tag:${NC} $TAG"
echo -e "${GREEN}Date:${NC} $DATE"
echo ""

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${RED}Error: Tag $TAG already exists!${NC}"
    echo "Please update the version in pubspec.yaml first."
    exit 1
fi

# Prompt for release notes
echo -e "${YELLOW}Enter release notes (press Ctrl+D when done):${NC}"
RELEASE_NOTES=$(cat)

if [ -z "$RELEASE_NOTES" ]; then
    echo -e "${RED}Error: Release notes cannot be empty!${NC}"
    exit 1
fi

# Step 1: Build APK
echo ""
echo -e "${BLUE}[1/5] Building release APK...${NC}"
flutter build apk --release

if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo -e "${RED}Error: APK build failed!${NC}"
    exit 1
fi

APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
echo -e "${GREEN}✓ APK built successfully ($APK_SIZE)${NC}"

# Step 2: Copy to Desktop
echo ""
echo -e "${BLUE}[2/5] Copying APK to Desktop...${NC}"
DESKTOP_APK="$HOME/Desktop/FlutterPOS-${TAG}.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$DESKTOP_APK"
echo -e "${GREEN}✓ Copied to: $DESKTOP_APK${NC}"

# Step 3: Create Git tag
echo ""
echo -e "${BLUE}[3/5] Creating Git tag...${NC}"
git tag -a "$TAG" -m "FlutterPOS $TAG

$RELEASE_NOTES"
echo -e "${GREEN}✓ Tag created: $TAG${NC}"

# Step 4: Push tag to GitHub
echo ""
echo -e "${BLUE}[4/5] Pushing tag to GitHub...${NC}"
git push origin "$TAG"
echo -e "${GREEN}✓ Tag pushed to GitHub${NC}"

# Step 5: Create GitHub release
echo ""
echo -e "${BLUE}[5/5] Creating GitHub release...${NC}"
gh release create "$TAG" \
  build/app/outputs/flutter-apk/app-release.apk \
  --title "FlutterPOS $TAG" \
  --notes "$RELEASE_NOTES"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Release Published Successfully! 🎉  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Release Details:${NC}"
echo -e "  Tag: $TAG"
echo -e "  APK: FlutterPOS-${TAG}.apk ($APK_SIZE)"
echo -e "  Desktop: $DESKTOP_APK"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Test the update feature in the app"
echo "  2. Go to Settings → Check for Updates"
echo "  3. Verify it detects the new version"
echo ""
echo -e "${BLUE}View release:${NC} gh release view $TAG"
