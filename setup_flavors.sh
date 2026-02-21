#!/bin/bash
# FlutterPOS - Flavor Directory Setup Script
# Creates the required directory structure for POS and KDS product flavors

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  FlutterPOS Flavor Directory Setup          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to project root
cd "$(dirname "$0")"

echo -e "${YELLOW}Creating Android flavor directories...${NC}"

# Create POS flavor directories
mkdir -p android/app/src/posApp/res/values
mkdir -p android/app/src/posApp/res/mipmap-mdpi
mkdir -p android/app/src/posApp/res/mipmap-hdpi
mkdir -p android/app/src/posApp/res/mipmap-xhdpi
mkdir -p android/app/src/posApp/res/mipmap-xxhdpi
mkdir -p android/app/src/posApp/res/mipmap-xxxhdpi
mkdir -p android/app/src/posApp/res/drawable
mkdir -p android/app/src/posApp/kotlin/com/extrotarget/extropos

# Create KDS flavor directories
mkdir -p android/app/src/kdsApp/res/values
mkdir -p android/app/src/kdsApp/res/mipmap-mdpi
mkdir -p android/app/src/kdsApp/res/mipmap-hdpi
mkdir -p android/app/src/kdsApp/res/mipmap-xhdpi
mkdir -p android/app/src/kdsApp/res/mipmap-xxhdpi
mkdir -p android/app/src/kdsApp/res/mipmap-xxxhdpi
mkdir -p android/app/src/kdsApp/res/drawable
mkdir -p android/app/src/kdsApp/kotlin/com/extrotarget/extropos

echo -e "${GREEN}✓ Android directories created${NC}"

echo -e "${YELLOW}Creating flavor-specific resource files...${NC}"

# Create POS strings.xml
cat > android/app/src/posApp/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">FlutterPOS</string>
</resources>
EOF

# Create KDS strings.xml
cat > android/app/src/kdsApp/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">FlutterPOS Kitchen Display</string>
</resources>
EOF

# Create POS AndroidManifest.xml
cat > android/app/src/posApp/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- POS-specific configurations -->
    <application>
        <!-- Will merge with main manifest -->
    </application>
</manifest>
EOF

# Create KDS AndroidManifest.xml
cat > android/app/src/kdsApp/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- KDS-specific configurations -->
    <application
        android:screenOrientation="landscape">
        <!-- Force landscape orientation for Kitchen Display -->
    </application>
</manifest>
EOF

echo -e "${GREEN}✓ Resource files created${NC}"

echo -e "${YELLOW}Creating Flutter flavor directories...${NC}"

# Create Flutter directories
mkdir -p lib/screens/pos/restaurant
mkdir -p lib/screens/kds
mkdir -p lib/screens/common

echo -e "${GREEN}✓ Flutter directories created${NC}"

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}  Setup Complete! ✓${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Created directories:${NC}"
echo -e "  ${GREEN}✓${NC} android/app/src/posApp/"
echo -e "  ${GREEN}✓${NC} android/app/src/kdsApp/"
echo -e "  ${GREEN}✓${NC} lib/screens/pos/"
echo -e "  ${GREEN}✓${NC} lib/screens/kds/"
echo ""

echo -e "${BLUE}Created files:${NC}"
echo -e "  ${GREEN}✓${NC} android/app/src/posApp/res/values/strings.xml"
echo -e "  ${GREEN}✓${NC} android/app/src/posApp/AndroidManifest.xml"
echo -e "  ${GREEN}✓${NC} android/app/src/kdsApp/res/values/strings.xml"
echo -e "  ${GREEN}✓${NC} android/app/src/kdsApp/AndroidManifest.xml"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Add app icons to:"
echo -e "     - android/app/src/posApp/res/mipmap-*/"
echo -e "     - android/app/src/kdsApp/res/mipmap-*/"
echo ""
echo -e "  2. Build POS app:"
echo -e "     ${BLUE}flutter build apk --release --flavor posApp --dart-define=FLAVOR=pos${NC}"
echo ""
echo -e "  3. Build KDS app:"
echo -e "     ${BLUE}flutter build apk --release --flavor kdsApp --dart-define=FLAVOR=kds${NC}"
echo ""
echo -e "  4. Or use the convenience script:"
echo -e "     ${BLUE}./build_flavors.sh both release${NC}"
echo ""
