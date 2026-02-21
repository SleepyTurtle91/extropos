#!/bin/bash
# Stop and Remove Appwrite Containers
# This script stops and removes all Appwrite-related Docker containers

echo "🛑 Stopping Appwrite containers..."
docker ps -a --format "{{.Names}}" | grep appwrite | xargs -r docker stop

echo "🗑️  Removing Appwrite containers..."
docker ps -a --format "{{.Names}}" | grep appwrite | xargs -r docker rm

echo "🧹 Removing Appwrite volumes (optional - comment out if you want to keep data)..."
# Uncomment the line below to also remove Appwrite volumes
# docker volume ls --format "{{.Name}}" | grep appwrite | xargs -r docker volume rm

echo "✅ Appwrite containers removed!"
echo ""
echo "Note: Appwrite volumes are preserved. To remove them, uncomment the volume removal line in this script."
