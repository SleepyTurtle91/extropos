#!/bin/bash

# FlutterPOS Docker Infrastructure Restore Script
# Restores data volumes from timestamped backups

set -e

BACKUP_DIR="./backups"

# Check if backup name is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: Please provide backup name"
    echo ""
    echo "Usage: $0 <backup_timestamp>"
    echo ""
    echo "Available backups:"
    ls -1 "${BACKUP_DIR}"/flutterpos_backup_*_*.tar.gz 2>/dev/null | \
        sed 's|.*/flutterpos_backup_\([^_]*\)_.*|\1|' | sort -u | \
        while read timestamp; do
            echo "  ${timestamp}"
        done
    echo ""
    echo "Example: $0 20241126_143022"
    exit 1
fi

BACKUP_TIMESTAMP=$1
BACKUP_PATTERN="${BACKUP_DIR}/flutterpos_backup_${BACKUP_TIMESTAMP}_*.tar.gz"

echo "🔄 Restoring FlutterPOS infrastructure from backup..."
echo "📦 Backup timestamp: ${BACKUP_TIMESTAMP}"

# Check if backup files exist
if ! ls ${BACKUP_PATTERN} 1> /dev/null 2>&1; then
    echo "❌ Error: No backup files found for timestamp ${BACKUP_TIMESTAMP}"
    echo ""
    echo "Available backups:"
    ls -1 "${BACKUP_DIR}"/flutterpos_backup_*_*.tar.gz 2>/dev/null | \
        sed 's|.*/flutterpos_backup_\([^_]*\)_.*|\1|' | sort -u
    exit 1
fi

# Stop all services before restore
echo "🛑 Stopping all services..."
docker-compose down

# Function to restore a volume
restore_volume() {
    local backup_file=$1
    local volume_name=$2

    if [ -f "${backup_file}" ]; then
        echo "📦 Restoring volume: ${volume_name}"

        # Remove existing volume if it exists
        docker volume rm "${volume_name}" 2>/dev/null || true

        # Create new volume
        docker volume create "${volume_name}"

        # Restore data
        docker run --rm \
            -v "${volume_name}:/target" \
            -v "$(pwd)/${BACKUP_DIR}:/backup" \
            alpine:latest \
            tar xzf "/backup/$(basename ${backup_file})" -C /target

        echo "✅ Restored ${volume_name}"
    else
        echo "⚠️  Backup file not found: ${backup_file}, skipping..."
    fi
}

# Restore all volumes
echo "🔄 Starting volume restores..."

# Find and restore each volume
for backup_file in ${BACKUP_PATTERN}; do
    # Extract volume name from filename
    # Format: flutterpos_backup_TIMESTAMP_VOLUMENAME.tar.gz
    volume_name=$(basename "${backup_file}" | sed "s/flutterpos_backup_${BACKUP_TIMESTAMP}_\(.*\)\.tar\.gz/\1/")

    # Map to actual volume names
    case "${volume_name}" in
        "appwrite_uploads")
            actual_volume="flutterpos_appwrite_uploads"
            ;;
        "appwrite_cache")
            actual_volume="flutterpos_appwrite_cache"
            ;;
        "appwrite_config")
            actual_volume="flutterpos_appwrite_config"
            ;;
        "appwrite_certificates")
            actual_volume="flutterpos_appwrite_certificates"
            ;;
        "appwrite_functions")
            actual_volume="flutterpos_appwrite_functions"
            ;;
        "appwrite_mariadb")
            actual_volume="flutterpos_appwrite_mariadb"
            ;;
        "appwrite_influxdb")
            actual_volume="flutterpos_appwrite_influxdb"
            ;;
        "appwrite_redis")
            actual_volume="flutterpos_appwrite_redis"
            ;;
        "nextcloud")
            actual_volume="flutterpos_nextcloud"
            ;;
        "rabbitmq")
            actual_volume="flutterpos_rabbitmq"
            ;;
        "minio")
            actual_volume="flutterpos_minio"
            ;;
        "traefik_letsencrypt")
            actual_volume="flutterpos-traefik_letsencrypt"
            ;;
        *)
            echo "⚠️  Unknown volume: ${volume_name}, skipping..."
            continue
            ;;
    esac

    restore_volume "${backup_file}" "${actual_volume}"
done

echo ""
echo "✅ Restore completed successfully!"
echo ""
echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "📊 Checking service status..."
sleep 10
./status.sh

echo ""
echo "🎯 Restore Summary:"
echo "📦 Backup timestamp: ${BACKUP_TIMESTAMP}"
echo "🔄 Services restarted"
echo ""
echo "⚠️  Important: Verify that all services are healthy!"
echo "🔍 Check service logs if any issues occur."