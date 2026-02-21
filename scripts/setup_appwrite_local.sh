#!/usr/bin/env bash
set -euo pipefail

# Simple helper to create Appwrite host directories and print advice
# Usage: ./scripts/setup_appwrite_local.sh /absolute/path/to/appwrite-data

BASE=${1:-"$HOME/appwrite-data"}

echo "Creating Appwrite host data directories under: $BASE"
mkdir -p "$BASE"/mysql
mkdir -p "$BASE"/redis
mkdir -p "$BASE"/storage
mkdir -p "$BASE"/config

echo
echo "Directories created:"
ls -ld "$BASE"/*

echo
echo "Permission suggestion: set ownership so the containers can write to them." \
     "If you know the container user/group (UID:GID), use chown -R <UID:GID> $BASE"
echo "Example (may require sudo):"
echo "  sudo chown -R 1000:1000 $BASE"

echo
echo "Sample docker-compose snippet for mounting these directories (host -> container):"
cat <<'EOF'
  mariadb:
    image: mariadb:10.11
    volumes:
      - /your/host/path/appwrite-data/mysql:/var/lib/mysql

  storage:
    image: appwrite/storage:latest
    volumes:
      - /your/host/path/appwrite-data/storage:/storage

  appwrite:
    image: appwrite/appwrite:latest
    volumes:
      - /your/host/path/appwrite-data/config:/etc/appwrite
EOF

echo
echo "Done. Next stop: start your Appwrite docker-compose and confirm via curl http://<host>/v1/health/version"
