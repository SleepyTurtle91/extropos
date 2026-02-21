#!/bin/bash

# FlutterPOS Docker Infrastructure Backup Script
# Creates timestamped backups of all critical data volumes

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="flutterpos_backup_${TIMESTAMP}"

echo "🗄️  Creating FlutterPOS infrastructure backup..."
echo "📁 Backup directory: ${BACKUP_DIR}"
echo "📦 Backup name: ${BACKUP_NAME}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Function to backup a volume
backup_volume() {
    local volume_name=$1
    local backup_file="${BACKUP_DIR}/${BACKUP_NAME}_${volume_name}.tar.gz"

    echo "📦 Backing up volume: ${volume_name}"

    if docker volume ls | grep -q "${volume_name}"; then
        docker run --rm \
            -v "${volume_name}:/source" \
            -v "$(pwd)/${BACKUP_DIR}:/backup" \
            alpine:latest \
            tar czf "/backup/${BACKUP_NAME}_${volume_name}.tar.gz" -C /source .

        echo "✅ Backed up ${volume_name} to ${backup_file}"
    else
        echo "⚠️  Volume ${volume_name} not found, skipping..."
    fi
}

# Backup all critical volumes
echo "🔄 Starting volume backups..."

# Appwrite volumes
backup_volume "flutterpos_appwrite_uploads"
backup_volume "flutterpos_appwrite_cache"
backup_volume "flutterpos_appwrite_config"
backup_volume "flutterpos_appwrite_certificates"
backup_volume "flutterpos_appwrite_functions"

# Database volumes
backup_volume "flutterpos_appwrite_mariadb"
backup_volume "flutterpos_appwrite_influxdb"
backup_volume "flutterpos_appwrite_redis"

# Nextcloud volumes
backup_volume "flutterpos_nextcloud"

# RabbitMQ volumes
backup_volume "flutterpos_rabbitmq"

# MinIO volumes
backup_volume "flutterpos_minio"

# Traefik volumes
backup_volume "flutterpos-traefik_letsencrypt"

echo "📊 Backup Summary:"
echo "📁 Location: ${BACKUP_DIR}/${BACKUP_NAME}_*.tar.gz"
echo "📅 Timestamp: ${TIMESTAMP}"

# List created backup files
echo "📋 Created backup files:"
ls -lh "${BACKUP_DIR}/${BACKUP_NAME}_"*.tar.gz 2>/dev/null || echo "No backup files found"

# Calculate total backup size
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}/${BACKUP_NAME}_"*.tar.gz 2>/dev/null | awk '{sum += $1} END {print sum}' || echo "0")
echo "💾 Total backup size: ${TOTAL_SIZE}"

echo ""
echo "✅ Backup completed successfully!"
echo ""
echo "💡 To restore from backup, use the restore script:"
echo "   ./restore.sh ${BACKUP_NAME}"
echo ""
echo "⚠️  Important: Store backups in a secure location!"
echo "🔐 Consider encrypting sensitive backup files."