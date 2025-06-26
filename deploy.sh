#!/bin/bash

# Education AI Agent Production Deployment Script
set -e

# Production docker-compose file
COMPOSE_FILE="docker/docker-compose.prod.yml"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check required commands
check_requirements() {
    print_info "Checking system requirements..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first"
        exit 1
    fi
    
    print_success "System requirements check passed"
}

# Create environment variables file
setup_env() {
    print_info "Setting up environment variables..."
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        print_info "Creating .env file from template..."
        if [ -f env.example ]; then
            cp env.example .env
        else
            print_error "env.example file not found"
            exit 1
        fi
    fi
    
    # Check if ANTHROPIC_API_KEY is set
    if ! grep -q "ANTHROPIC_API_KEY=.*[^[:space:]]" .env 2>/dev/null; then
        print_warning "ANTHROPIC_API_KEY not found in .env file"
        
        # Prompt for API key
        echo ""
        echo -n "Please enter your Anthropic API Key: "
        read -s ANTHROPIC_API_KEY
        echo ""
        
        if [ -z "$ANTHROPIC_API_KEY" ]; then
            print_error "API key cannot be empty"
            exit 1
        fi
        
        # Update .env file
        if grep -q "ANTHROPIC_API_KEY=" .env; then
            # Replace existing line
            sed -i "s/ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY/" .env
        else
            # Add new line
            echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> .env
        fi
        
        print_success "API key has been saved to .env file"
    fi
    
    # Prompt for other optional settings
    echo ""
    print_info "Optional settings (press Enter to use defaults):"
    
    echo -n "Claude Model [claude-3-5-sonnet-20241022]: "
    read CLAUDE_MODEL_INPUT
    if [ ! -z "$CLAUDE_MODEL_INPUT" ]; then
        if grep -q "CLAUDE_MODEL=" .env; then
            sed -i "s/CLAUDE_MODEL=.*/CLAUDE_MODEL=$CLAUDE_MODEL_INPUT/" .env
        else
            echo "CLAUDE_MODEL=$CLAUDE_MODEL_INPUT" >> .env
        fi
    fi
    
    echo -n "Debug mode [false]: "
    read DEBUG_INPUT
    if [ ! -z "$DEBUG_INPUT" ]; then
        if grep -q "DEBUG=" .env; then
            sed -i "s/DEBUG=.*/DEBUG=$DEBUG_INPUT/" .env
        else
            echo "DEBUG=$DEBUG_INPUT" >> .env
        fi
    fi
    
    print_success "Environment variables setup completed"
}

# Pull latest images (for production deployment)
pull_images() {
    print_info "Pulling latest Docker images from registry..."
    
    # Pull latest images
    docker-compose -f $COMPOSE_FILE pull
    
    print_success "Image pull completed"
}

# Start services
start_services() {
    print_info "Starting production services..."
    
    # Stop existing services
    docker-compose -f $COMPOSE_FILE down 2>/dev/null || true
    
    # Start services
    docker-compose -f $COMPOSE_FILE up -d
    
    print_success "Services started successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_info "Waiting for services to be ready..."
    
    # Wait for backend service
    print_info "Waiting for backend service..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -f http://localhost:8000/health >/dev/null 2>&1; then
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "Backend service startup timeout"
        exit 1
    fi
    
    # Wait for frontend service (production runs on port 80)
    print_info "Waiting for frontend service..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -f http://localhost >/dev/null 2>&1; then
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        print_warning "Frontend service health check timeout, but service may have started normally"
    fi
    
    print_success "All services are ready"
}

# Show deployment information
show_deployment_info() {
    print_success "Deployment completed!"
    echo ""
    echo "Access URLs:"
    echo "  Frontend:  http://localhost"
    echo "  Backend API: http://localhost:8000"
    echo "  API Docs:  http://localhost:8000/docs"
    echo ""
    echo "Management Commands:"
    echo "  View logs:    docker-compose -f $COMPOSE_FILE logs -f"
    echo "  Stop services: docker-compose -f $COMPOSE_FILE down"
    echo "  Restart:      docker-compose -f $COMPOSE_FILE restart"
    echo "  Check status: docker-compose -f $COMPOSE_FILE ps"
}

# Main function
main() {
    print_info "Starting Education AI Agent system deployment..."
    
    check_requirements
    setup_env
    pull_images
    start_services
    wait_for_services
    show_deployment_info
    
    print_success "Deployment completed!"
}

# If running this script directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 