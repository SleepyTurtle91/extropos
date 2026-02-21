#!/bin/bash
# FlutterPOS Wireless APK Deployment Script
# Builds, copies, and installs POS and Backend APKs via ADB wireless

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/home/abber/Documents/flutterpos"
VERSION="1.0.14"
DATE=$(date +%Y%m%d)
DESKTOP_DIR="$HOME/Desktop"

# APK paths
POS_APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-posapp-release.apk"
BACKEND_APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-backendapp-release.apk"

# Desktop copies with version naming
POS_DESKTOP="$DESKTOP_DIR/FlutterPOS-v${VERSION}-${DATE}-POS.apk"
BACKEND_DESKTOP="$DESKTOP_DIR/FlutterPOS-v${VERSION}-${DATE}-Backend.apk"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  FlutterPOS Wireless Deployment Script        ║${NC}"
echo -e "${BLUE}║  Version: ${VERSION} | Date: ${DATE}              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check if APK exists
check_apk() {
    local apk_path=$1
    local apk_name=$2
    
    if [ ! -f "$apk_path" ]; then
        echo -e "${RED}✗ ${apk_name} not found at: ${apk_path}${NC}"
        echo -e "${YELLOW}Please build the APK first${NC}"
        return 1
    else
        local size=$(du -h "$apk_path" | cut -f1)
        echo -e "${GREEN}✓ ${apk_name} found (${size})${NC}"
        return 0
    fi
}

# Function to copy APK to desktop
copy_to_desktop() {
    local src=$1
    local dest=$2
    local name=$3
    
    echo -e "${BLUE}Copying ${name} to Desktop...${NC}"
    cp "$src" "$dest"
    echo -e "${GREEN}✓ Saved to: ${dest}${NC}"
}

# Function to get device IP
get_device_ip() {
    echo -e "${YELLOW}Enter device IP address (e.g., 192.168.1.100): ${NC}"
    read -r DEVICE_IP
    echo "$DEVICE_IP"
}

# Function to get ADB port
get_adb_port() {
    echo -e "${YELLOW}Enter ADB port (default: 5555): ${NC}"
    read -r ADB_PORT
    ADB_PORT=${ADB_PORT:-5555}
    echo "$ADB_PORT"
}

# Function to connect ADB wireless
connect_adb() {
    local device_ip=$1
    local adb_port=$2
    
    echo -e "${BLUE}Connecting to ${device_ip}:${adb_port}...${NC}"
    
    # Try to connect
    if adb connect "${device_ip}:${adb_port}" 2>&1 | grep -q "connected"; then
        echo -e "${GREEN}✓ Connected to device${NC}"
        
        # Verify connection
        if adb devices | grep -q "${device_ip}:${adb_port}"; then
            echo -e "${GREEN}✓ Device verified${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}✗ Failed to connect${NC}"
    return 1
}

# Function to install APK
install_apk() {
    local apk_path=$1
    local app_name=$2
    
    echo -e "${BLUE}Installing ${app_name}...${NC}"
    
    if adb install -r "$apk_path" 2>&1 | tee /tmp/adb_install.log | grep -q "Success"; then
        echo -e "${GREEN}✓ ${app_name} installed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Installation failed${NC}"
        cat /tmp/adb_install.log
        return 1
    fi
}

# Main workflow
main() {
    echo -e "${YELLOW}Step 1: Checking APK files...${NC}"
    echo ""
    
    POS_EXISTS=false
    BACKEND_EXISTS=false
    
    if check_apk "$POS_APK" "POS APK"; then
        POS_EXISTS=true
    fi
    
    if check_apk "$BACKEND_APK" "Backend APK"; then
        BACKEND_EXISTS=true
    fi
    
    if [ "$POS_EXISTS" = false ] && [ "$BACKEND_EXISTS" = false ]; then
        echo -e "${RED}No APKs found. Build them first with:${NC}"
        echo -e "${YELLOW}  flutter build apk --release${NC}"
        echo -e "${YELLOW}  flutter build apk --release --flavor backendapp --target lib/main_backend.dart${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}Step 2: Copying APKs to Desktop...${NC}"
    echo ""
    
    if [ "$POS_EXISTS" = true ]; then
        copy_to_desktop "$POS_APK" "$POS_DESKTOP" "POS APK"
    fi
    
    if [ "$BACKEND_EXISTS" = true ]; then
        copy_to_desktop "$BACKEND_APK" "$BACKEND_DESKTOP" "Backend APK"
    fi
    
    echo ""
    echo -e "${YELLOW}Step 3: ADB Wireless Connection...${NC}"
    echo ""
    
    # Check if adb is available
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}✗ ADB not found in PATH${NC}"
        echo -e "${YELLOW}Install Android SDK Platform Tools first${NC}"
        exit 1
    fi
    
    # Get device connection info
    DEVICE_IP=$(get_device_ip)
    ADB_PORT=$(get_adb_port)
    
    # Connect to device
    if ! connect_adb "$DEVICE_IP" "$ADB_PORT"; then
        echo -e "${YELLOW}Connection failed. Make sure:${NC}"
        echo -e "  1. Device and PC are on same network"
        echo -e "  2. USB debugging is enabled on device"
        echo -e "  3. Wireless ADB is enabled (Settings → Developer Options → Wireless debugging)"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}Step 4: Installing APKs...${NC}"
    echo ""
    
    INSTALL_SUCCESS=true
    
    if [ "$POS_EXISTS" = true ]; then
        if ! install_apk "$POS_APK" "POS App"; then
            INSTALL_SUCCESS=false
        fi
    fi
    
    if [ "$BACKEND_EXISTS" = true ]; then
        if ! install_apk "$BACKEND_APK" "Backend App"; then
            INSTALL_SUCCESS=false
        fi
    fi
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    
    if [ "$INSTALL_SUCCESS" = true ]; then
        echo -e "${BLUE}║  ${GREEN}✓ Deployment Complete!${BLUE}                      ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}APKs saved to Desktop:${NC}"
        [ "$POS_EXISTS" = true ] && echo -e "  • ${POS_DESKTOP}"
        [ "$BACKEND_EXISTS" = true ] && echo -e "  • ${BACKEND_DESKTOP}"
        echo ""
        echo -e "${GREEN}Installed on device (${DEVICE_IP}):${NC}"
        [ "$POS_EXISTS" = true ] && echo -e "  • FlutterPOS (com.extrotarget.extropos.pos)"
        [ "$BACKEND_EXISTS" = true ] && echo -e "  • FlutterPOS Backend (com.extrotarget.extropos.backend)"
    else
        echo -e "${BLUE}║  ${RED}✗ Deployment Failed${BLUE}                         ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
        echo -e "${YELLOW}Check error messages above${NC}"
        exit 1
    fi
}

# Run main function
main
