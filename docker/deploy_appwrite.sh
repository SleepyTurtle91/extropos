#!/bin/bash

# FlutterPOS Appwrite Deployment Script
# Automates Phase 1 backend infrastructure deployment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STORAGE_PATH="/mnt/storage/appwrite"
COMPOSE_FILE="appwrite-compose-web-optimized.yml"
ENV_FILE=".env"

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_success "Docker is installed: $(docker --version)"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_success "Docker Compose is installed: $(docker-compose --version)"
    
    # Check port 8080
    if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port 8080 is already in use"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Port 8080 is available"
    fi
    
    # Check disk space
    AVAILABLE_SPACE=$(df -BG "$STORAGE_PATH" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ -z "$AVAILABLE_SPACE" ]; then
        AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    fi
    
    if [ "$AVAILABLE_SPACE" -lt 10 ]; then
        print_error "Insufficient disk space. At least 10GB required."
        exit 1
    fi
    print_success "Disk space available: ${AVAILABLE_SPACE}GB"
}

# Create storage directories
create_storage_dirs() {
    print_header "Creating Storage Directories"
    
    DIRS=("mysql" "redis" "config" "storage" "functions" "builds" "cache")
    
    for DIR in "${DIRS[@]}"; do
        FULL_PATH="$STORAGE_PATH/$DIR"
        if [ ! -d "$FULL_PATH" ]; then
            sudo mkdir -p "$FULL_PATH"
            print_success "Created: $FULL_PATH"
        else
            print_info "Already exists: $FULL_PATH"
        fi
    done
    
    # Set ownership
    sudo chown -R $USER:$USER "$STORAGE_PATH"
    chmod -R 755 "$STORAGE_PATH"
    print_success "Set permissions on $STORAGE_PATH"
}

# Setup environment file
setup_env_file() {
    print_header "Setting Up Environment File"
    
    if [ -f "$ENV_FILE" ]; then
        print_warning "Environment file already exists"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing environment file"
            return
        fi
    fi
    
    if [ ! -f ".env.example" ]; then
        print_error "Template file .env.example not found"
        exit 1
    fi
    
    # Copy template
    cp .env.example "$ENV_FILE"
    print_success "Copied .env.example to .env"
    
    # Generate secure passwords and keys
    MYSQL_ROOT_PASS=$(openssl rand -hex 16)
    MYSQL_PASS=$(openssl rand -hex 16)
    OPENSSL_KEY=$(openssl rand -hex 32)
    EXECUTOR_SECRET=$(openssl rand -hex 32)
    
    # Replace placeholders
    sed -i "s/appwrite_root_secure_2026_CHANGE_THIS/$MYSQL_ROOT_PASS/" "$ENV_FILE"
    sed -i "s/appwrite_db_secure_2026_CHANGE_THIS/$MYSQL_PASS/" "$ENV_FILE"
    sed -i "s/dbccde1aa2b0b905f3cda5203b070a75e0ee2e04ed215fd3a48462d77e3ab797/$OPENSSL_KEY/" "$ENV_FILE"
    sed -i "s/your-executor-secret-key-CHANGE_THIS/$EXECUTOR_SECRET/" "$ENV_FILE"
    
    print_success "Generated secure passwords and keys"
    
    # Save credentials for reference
    cat > appwrite_credentials.txt <<EOF
# Appwrite Deployment Credentials
# Generated on $(date)
# KEEP THIS FILE SECURE - Contains sensitive information

MySQL Root Password: $MYSQL_ROOT_PASS
MySQL Appwrite Password: $MYSQL_PASS
OpenSSL Key: $OPENSSL_KEY
Executor Secret: $EXECUTOR_SECRET

# Access Information
Appwrite Console: http://localhost:8080
API Endpoint: http://localhost:8080/v1

# Next Steps:
1. Access console at http://localhost:8080
2. Create first account (this will be admin)
3. Create project: "FlutterPOS-Backend"
4. Generate API key with full permissions
5. Create database: "pos_db"
6. Create collections (see DEPLOYMENT_GUIDE.md)

EOF
    chmod 600 appwrite_credentials.txt
    print_success "Saved credentials to appwrite_credentials.txt"
    print_warning "Keep appwrite_credentials.txt secure!"
}

# Deploy services
deploy_services() {
    print_header "Deploying Appwrite Services"
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    print_info "Starting services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    print_success "Services started"
    print_info "Waiting for services to become healthy (may take 60-90 seconds)..."
    sleep 10
    
    # Wait for services
    TIMEOUT=90
    ELAPSED=0
    while [ $ELAPSED -lt $TIMEOUT ]; do
        HEALTHY=$(docker-compose -f "$COMPOSE_FILE" ps | grep -c "(healthy)" || true)
        TOTAL=$(docker-compose -f "$COMPOSE_FILE" ps | grep -c "Up" || true)
        
        if [ "$HEALTHY" -ge 3 ]; then
            print_success "All critical services are healthy"
            break
        fi
        
        echo -ne "\rWaiting... ${ELAPSED}s / ${TIMEOUT}s (${HEALTHY}/${TOTAL} healthy)"
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    done
    echo ""
    
    if [ $ELAPSED -ge $TIMEOUT ]; then
        print_warning "Timeout waiting for services. Checking status..."
    fi
    
    # Show service status
    print_info "Service Status:"
    docker-compose -f "$COMPOSE_FILE" ps
}

# Verify deployment
verify_deployment() {
    print_header "Verifying Deployment"
    
    # Check Appwrite API
    print_info "Testing Appwrite API..."
    if curl -f -s http://localhost:8080/v1/health/version > /dev/null 2>&1; then
        VERSION=$(curl -s http://localhost:8080/v1/health/version | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        print_success "Appwrite API is responding (version: $VERSION)"
    else
        print_error "Appwrite API is not responding"
        print_info "Check logs: docker-compose -f $COMPOSE_FILE logs appwrite"
        return 1
    fi
    
    # Check database
    print_info "Testing database connection..."
    if docker-compose -f "$COMPOSE_FILE" exec -T mariadb mysql -u appwrite -p$(grep MYSQL_PASSWORD= "$ENV_FILE" | cut -d'=' -f2) -e "SHOW DATABASES;" > /dev/null 2>&1; then
        print_success "Database is accessible"
    else
        print_error "Database connection failed"
        return 1
    fi
    
    # Check Redis
    print_info "Testing Redis connection..."
    if docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping | grep -q PONG; then
        print_success "Redis is responding"
    else
        print_error "Redis connection failed"
        return 1
    fi
}

# Show next steps
show_next_steps() {
    print_header "Deployment Complete!"
    
    echo -e "${GREEN}Appwrite is now running!${NC}"
    echo ""
    echo "Access Information:"
    echo "  Console: http://localhost:8080"
    echo "  API Endpoint: http://localhost:8080/v1"
    echo ""
    echo "Credentials saved to: ${YELLOW}appwrite_credentials.txt${NC}"
    echo ""
    echo "Next Steps:"
    echo "  1. Open http://localhost:8080 in your browser"
    echo "  2. Create your first account (this will be the admin)"
    echo "  3. Create a new project: 'FlutterPOS-Backend'"
    echo "  4. Generate API key (Settings → API Keys)"
    echo "  5. Create database with ID: 'pos_db'"
    echo "  6. Create collections (see DEPLOYMENT_GUIDE.md for details)"
    echo "  7. Configure Backend app with Appwrite credentials"
    echo "  8. Test sync workflow"
    echo ""
    echo "Useful Commands:"
    echo "  View logs:    docker-compose -f $COMPOSE_FILE logs -f"
    echo "  Stop:         docker-compose -f $COMPOSE_FILE stop"
    echo "  Restart:      docker-compose -f $COMPOSE_FILE restart"
    echo "  Remove:       docker-compose -f $COMPOSE_FILE down"
    echo ""
    echo "Documentation: See DEPLOYMENT_GUIDE.md for detailed instructions"
}

# Main execution
main() {
    print_header "FlutterPOS Appwrite Deployment"
    print_info "Phase 1: Core Sync Infrastructure"
    echo ""
    
    # Change to script directory
    cd "$(dirname "$0")"
    
    check_prerequisites
    create_storage_dirs
    setup_env_file
    deploy_services
    
    if verify_deployment; then
        show_next_steps
    else
        print_error "Deployment verification failed"
        print_info "Check logs for details: docker-compose -f $COMPOSE_FILE logs"
        exit 1
    fi
}

# Run main function
main "$@"
