#!/bin/bash

# FlutterPOS Infrastructure Health Check Script
# Performs comprehensive health checks on all services

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
fi

DOMAIN=${DOMAIN:-"localhost"}
SKIP_SSL=${SKIP_SSL:-false}

echo "🏥 FlutterPOS Infrastructure Health Check"
echo "🌐 Domain: ${DOMAIN}"
echo "🔒 SSL Check: $([ "$SKIP_SSL" = "true" ] && echo "Skipped" || echo "Enabled")"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check HTTP endpoint
check_http() {
    local url=$1
    local service_name=$2
    local expected_code=${3:-200}

    echo -n "🔍 Checking ${service_name}... "

    # Add Host header for localhost testing
    local curl_opts=""
    if [[ "$url" == http://localhost* ]]; then
        case "$service_name" in
            "Appwrite API") curl_opts="-H Host:appwrite.localhost" ;;
            "Nextcloud") curl_opts="-H Host:cloud.localhost" ;;
            "RabbitMQ Management") curl_opts="-H Host:rabbitmq.localhost" ;;
            "FlutterPOS Backend") curl_opts="-H Host:backend.localhost" ;;
            "MailHog") curl_opts="-H Host:mail.localhost" ;;
        esac
    fi

    if [ "$SKIP_SSL" = "true" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 $curl_opts "${url}" 2>/dev/null || echo "000")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -k $curl_opts "${url}" 2>/dev/null || echo "000")
    fi

    if [ "${response}" = "${expected_code}" ]; then
        echo -e "${GREEN}✅ OK (${response})${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL (${response})${NC}"
        return 1
    fi
}

# Function to check Docker container
check_container() {
    local container_name=$1
    local service_name=$2

    echo -n "🐳 Checking ${service_name} container... "

    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        # Check if container is healthy
        health=$(docker inspect --format='{{.State.Health.Status}}' "${container_name}" 2>/dev/null || echo "none")

        if [ "${health}" = "healthy" ]; then
            echo -e "${GREEN}✅ HEALTHY${NC}"
            return 0
        elif [ "${health}" = "none" ]; then
            # No health check defined, check if running
            status=$(docker inspect --format='{{.State.Status}}' "${container_name}" 2>/dev/null)
            if [ "${status}" = "running" ]; then
                echo -e "${GREEN}✅ RUNNING${NC}"
                return 0
            else
                echo -e "${RED}❌ NOT RUNNING${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️  ${health^^}${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ NOT FOUND${NC}"
        return 1
    fi
}

# Track overall health
OVERALL_HEALTH=0
SERVICES_CHECKED=0

echo "🌐 HTTP Services:"
echo "────────────────"

# Check Traefik
if [ "${DOMAIN}" = "localhost" ]; then
    # Skip Traefik dashboard health check for localhost as it requires authentication
    echo -e "🔍 Checking Traefik Dashboard... ${YELLOW}⚠️ SKIPPED (requires auth)${NC}"
else
    check_http "https://${DOMAIN}/traefik" "Traefik Dashboard" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
fi
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

# Check Appwrite
if [ "${DOMAIN}" = "localhost" ]; then
    check_http "http://localhost/v1/health" "Appwrite API" 401 && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
else
    check_http "https://appwrite.${DOMAIN}/v1/health" "Appwrite API" 401 && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
fi
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

# Check Nextcloud
if [ "${DOMAIN}" = "localhost" ]; then
    # Skip Nextcloud health check for localhost as it may still be initializing
    echo -e "🔍 Checking Nextcloud... ${YELLOW}⚠️ SKIPPED (initializing)${NC}"
else
    check_http "https://cloud.${DOMAIN}/status.php" "Nextcloud" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
fi
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

# Check RabbitMQ Management
if [ "${DOMAIN}" = "localhost" ]; then
    # Skip RabbitMQ health check for localhost as it requires authentication
    echo -e "🔍 Checking RabbitMQ Management... ${YELLOW}⚠️ SKIPPED (requires auth)${NC}"
else
    check_http "https://rabbitmq.${DOMAIN}" "RabbitMQ Management" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
fi
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

# Check FlutterPOS Backend
if [ "${DOMAIN}" = "localhost" ]; then
    check_http "http://localhost" "FlutterPOS Backend" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
else
    check_http "https://backend.${DOMAIN}" "FlutterPOS Backend" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
fi
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

# Check MailHog (development)
if [ "${DOMAIN}" = "localhost" ]; then
    check_http "http://localhost" "MailHog" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
else
    check_http "https://mail.${DOMAIN}" "MailHog" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
fi
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

echo ""
echo "🐳 Docker Containers:"
echo "───────────────────"

# Check containers
check_container "flutterpos-traefik" "Traefik" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

check_container "flutterpos-appwrite" "Appwrite" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

check_container "flutterpos-appwrite-mariadb" "MariaDB" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

check_container "flutterpos-nextcloud" "Nextcloud" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

check_container "flutterpos-rabbitmq" "RabbitMQ" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

check_container "flutterpos-backend-web" "FlutterPOS Backend" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

check_container "flutterpos-mailhog" "MailHog" && OVERALL_HEALTH=$((OVERALL_HEALTH + 1))
SERVICES_CHECKED=$((SERVICES_CHECKED + 1))

echo ""
echo "📊 Health Summary:"
echo "─────────────────"
echo "Services Checked: ${SERVICES_CHECKED}"
echo "Healthy Services: ${OVERALL_HEALTH}"

if [ ${OVERALL_HEALTH} -eq ${SERVICES_CHECKED} ]; then
    echo -e "Overall Status: ${GREEN}✅ ALL HEALTHY${NC}"
    exit 0
elif [ ${OVERALL_HEALTH} -ge $((SERVICES_CHECKED / 2)) ]; then
    echo -e "Overall Status: ${YELLOW}⚠️  PARTIALLY HEALTHY${NC}"
    exit 1
else
    echo -e "Overall Status: ${RED}❌ MOSTLY UNHEALTHY${NC}"
    exit 1
fi