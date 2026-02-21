#!/bin/bash
# Create a Nextcloud user for a restaurant

USERNAME="$1"
EMAIL="$2"
DISPLAY_NAME="$3"
QUOTA="${4:-50 GB}"

if [ -z "$USERNAME" ] || [ -z "$EMAIL" ] || [ -z "$DISPLAY_NAME" ]; then
  echo "Usage: ./create-user.sh USERNAME EMAIL 'DISPLAY NAME' [QUOTA]"
  echo ""
  echo "Examples:"
  echo "  ./create-user.sh restaurant1 owner@restaurant1.com 'Restaurant One' '50 GB'"
  echo "  ./create-user.sh cafe-abc cafe@example.com 'Cafe ABC' '20 GB'"
  exit 1
fi

echo "Creating Nextcloud user: $USERNAME"
echo "Email: $EMAIL"
echo "Display Name: $DISPLAY_NAME"
echo "Quota: $QUOTA"
echo ""

# Create user (will prompt for password)
docker exec -it -u www-data nextcloud php occ user:add \
  --display-name="$DISPLAY_NAME" \
  --group="pos-users" \
  "$USERNAME"

# Set email
docker exec -u www-data nextcloud php occ user:setting \
  "$USERNAME" settings email "$EMAIL"

# Set quota
docker exec -u www-data nextcloud php occ user:setting \
  "$USERNAME" files quota "$QUOTA"

echo ""
echo "✅ User created successfully!"
echo ""
echo "📧 Send to user:"
echo "   Server: https://extropos.duckdns.org"
echo "   Username: $USERNAME"
echo "   Email: $EMAIL"
echo ""
echo "🔑 User must:"
echo "   1. Login to Nextcloud web"
echo "   2. Go to Settings → Security → App passwords"
echo "   3. Create app password named 'FlutterPOS'"
echo "   4. Use that password in FlutterPOS Backend app"
