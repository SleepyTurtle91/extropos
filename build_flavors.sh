#!/bin/bash
# FlutterPOS - Build Script for Product Flavors
# Usage: ./build_flavors.sh [pos|kds|backend|dealer|all] [debug|release]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
FLAVOR="all"  # pos, kds, backend, dealer, or all
BUILD_TYPE="release"

# Parse arguments
if [ $# -ge 1 ]; then
    FLAVOR=$1
fi

if [ $# -ge 2 ]; then
    BUILD_TYPE=$2
fi

# Validate inputs
if [[ ! "$FLAVOR" =~ ^(pos|kds|backend|dealer|frontend|all)$ ]]; then
    echo -e "${RED}Error: Invalid flavor '$FLAVOR'. Use: pos, kds, backend, dealer, frontend, or all${NC}"
    exit 1
fi

if [[ ! "$BUILD_TYPE" =~ ^(debug|release)$ ]]; then
    echo -e "${RED}Error: Invalid build type '$BUILD_TYPE'. Use: debug or release${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   FlutterPOS Flavor Build Script      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Build POS App
build_pos() {
    echo -e "${YELLOW}Building POS App ($BUILD_TYPE)...${NC}"
    flutter build apk --$BUILD_TYPE --flavor posApp --target lib/main.dart
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ POS App built successfully!${NC}"
        APK_PATH="build/app/outputs/flutter-apk/app-posapp-$BUILD_TYPE.apk"
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "${GREEN}  Location: $APK_PATH${NC}"
        echo -e "${GREEN}  Size: $APK_SIZE${NC}"
        
        # Copy to desktop with date tag
        DESKTOP_APK="$HOME/Desktop/FlutterPOS-v$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)-$(date +%Y%m%d)-pos.apk"
        cp "$APK_PATH" "$DESKTOP_APK"
        echo -e "${GREEN}  Copied to: $DESKTOP_APK${NC}"
    else
        echo -e "${RED}✗ POS App build failed!${NC}"
        return 1
    fi
}

# Build KDS App
build_kds() {
    echo -e "${YELLOW}Building KDS App ($BUILD_TYPE)...${NC}"
    flutter build apk --$BUILD_TYPE --flavor kdsApp --target lib/main_kds.dart
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ KDS App built successfully!${NC}"
        APK_PATH="build/app/outputs/flutter-apk/app-kdsapp-$BUILD_TYPE.apk"
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "${GREEN}  Location: $APK_PATH${NC}"
        echo -e "${GREEN}  Size: $APK_SIZE${NC}"
        
        # Copy to desktop with date tag
        DESKTOP_APK="$HOME/Desktop/FlutterPOS-v$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)-$(date +%Y%m%d)-kds.apk"
        cp "$APK_PATH" "$DESKTOP_APK"
        echo -e "${GREEN}  Copied to: $DESKTOP_APK${NC}"
    else
        echo -e "${RED}✗ KDS App build failed!${NC}"
        return 1
    fi
}

# Build Backend App (Web Only)
build_backend() {
    echo -e "${YELLOW}Building Backend App ($BUILD_TYPE)...${NC}"
    flutter build web --$BUILD_TYPE --target lib/main_backend.dart --no-tree-shake-icons
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Backend App built successfully!${NC}"
        WEB_PATH="build/web"
        echo -e "${GREEN}  Location: $WEB_PATH${NC}"
        
        # Copy to desktop with date tag
        DESKTOP_WEB="$HOME/Desktop/FlutterPOS-v$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)-$(date +%Y%m%d)-backend-web"
        cp -r "$WEB_PATH" "$DESKTOP_WEB"
        echo -e "${GREEN}  Copied to: $DESKTOP_WEB${NC}"
    else
        echo -e "${RED}✗ Backend App build failed!${NC}"
        return 1
    fi
}

# Build Dealer Portal App
build_dealer() {
    echo -e "${YELLOW}Building Dealer Portal App ($BUILD_TYPE)...${NC}"
    flutter build web --$BUILD_TYPE --target lib/main_dealer.dart
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Dealer Portal App built successfully!${NC}"
        WEB_PATH="build/web"
        echo -e "${GREEN}  Location: $WEB_PATH${NC}"
        
        # Copy to desktop with date tag
        DESKTOP_WEB="$HOME/Desktop/FlutterPOS-v$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)-$(date +%Y%m%d)-dealer-web"
        cp -r "$WEB_PATH" "$DESKTOP_WEB"
        echo -e "${GREEN}  Copied to: $DESKTOP_WEB${NC}"
    else
        echo -e "${RED}✗ Dealer Portal App build failed!${NC}"
        return 1
    fi
}

# Build Frontend Customer App
build_frontend() {
    echo -e "${YELLOW}Building Frontend Customer App ($BUILD_TYPE)...${NC}"
    flutter build apk --$BUILD_TYPE --flavor frontendApp --target lib/main_frontend.dart
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Frontend Customer App built successfully!${NC}"
        APK_PATH="build/app/outputs/flutter-apk/app-frontendapp-$BUILD_TYPE.apk"
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "${GREEN}  Location: $APK_PATH${NC}"
        echo -e "${GREEN}  Size: $APK_SIZE${NC}"
        
        # Copy to desktop with date tag
        DESKTOP_APK="$HOME/Desktop/FlutterPOS-v$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)-$(date +%Y%m%d)-frontend.apk"
        cp "$APK_PATH" "$DESKTOP_APK"
        echo -e "${GREEN}  Copied to: $DESKTOP_APK${NC}"
    else
        echo -e "${RED}✗ Frontend Customer App build failed!${NC}"
        return 1
    fi
}

# Execute builds based on flavor selection
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Flavor: ${YELLOW}$FLAVOR${NC}"
echo -e "  Build Type: ${YELLOW}$BUILD_TYPE${NC}"
echo ""

START_TIME=$(date +%s)

if [ "$FLAVOR" == "pos" ]; then
    build_pos
elif [ "$FLAVOR" == "kds" ]; then
    build_kds
elif [ "$FLAVOR" == "backend" ]; then
    build_backend
elif [ "$FLAVOR" == "dealer" ]; then
    build_dealer
elif [ "$FLAVOR" == "frontend" ]; then
    build_frontend
else
    # Build all flavors
    build_pos
    echo ""
    build_kds
    echo ""
    build_backend
    echo ""
    build_dealer
    echo ""
    build_frontend
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}  Build completed in ${DURATION}s${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# List all APKs
echo ""
echo -e "${BLUE}Available APKs:${NC}"
ls -lh build/app/outputs/flutter-apk/app-*-$BUILD_TYPE.apk 2>/dev/null || echo "No APKs found"
