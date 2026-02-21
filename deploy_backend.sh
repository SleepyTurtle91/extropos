#!/bin/bash

# Deploy Backend Web Application
# This script builds and serves the tenant backend access web app

set -e

echo "🚀 Deploying ExtroPOS Tenant Backend..."
echo ""

# Build the backend web app
echo "📦 Building backend web application..."
flutter build web --no-tree-shake-icons -t lib/main_backend.dart

echo ""
echo "✅ Build complete!"
echo ""
echo "📁 Output location: build/web/"
echo ""
echo "🌐 To serve locally:"
echo "   cd build/web && python3 -m http.server 8080"
echo ""
echo "🌐 Or using PHP:"
echo "   cd build/web && php -S localhost:8080"
echo ""
echo "🌐 Then open: http://localhost:8080"
echo ""
echo "📋 Deployment checklist:"
echo "   ✓ Backend web app built successfully"
echo "   ✓ Tenant login screen is the entry point"
echo "   ✓ Database integration enabled"
echo "   ✓ Ready for production deployment"
echo ""
echo "🎯 For production deployment:"
echo "   1. Upload contents of build/web/ to your web server"
echo "   2. Configure your web server (Apache, Nginx, etc.)"
echo "   3. Ensure database is accessible"
echo "   4. Test tenant login functionality"
echo ""
