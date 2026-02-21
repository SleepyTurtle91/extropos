#!/bin/bash
# Build Android App Bundle (AAB) for Google Play Store
# Usage: ./build_playstore_bundle.sh

echo "Building App Bundle for POS Flavor (Release)..."

flutter build appbundle --release --flavor posApp --target lib/main.dart

if [ $? -eq 0 ]; then
    echo "✓ App Bundle built successfully!"
    echo "Location: build/app/outputs/bundle/posAppRelease/app-posApp-release.aab"
    echo ""
    echo "Next steps for Play Store:"
    echo "1. Sign the AAB (if not already handled by gradle config)"
    echo "2. Upload 'app-posApp-release.aab' to Google Play Console"
    echo "3. Ensure you have created the In-App Products:"
    echo "   - extropos_lifetime_license (Non-consumable)"
    echo "   - extropos_cloud_6mo (Subscription)"
    echo "   - extropos_cloud_1yr (Subscription)"
else
    echo "x Build failed"
    exit 1
fi
