#!/bin/bash

# Education AI Agent Local Development Deployment Script
set -e

# Local docker-compose file
COMPOSE_FILE="docker/docker-compose.yml"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Setup environment variables
setup_env() {
    print_info "Setting up environment variables..."
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        print_info "Creating .env file from template..."
        if [ -f .env.example ]; then
            cp .env.example .env
        else
            print_error ".env.example file not found"
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
            sed -i "s/ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY/" .env
        else
            echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> .env
        fi
        
        print_success "API key has been saved to .env file"
    fi
    
    print_success "Environment variables setup completed"
}

# Build and start services
start_services() {
    print_info "Building and starting local development services..."
    
    # Stop existing services
    docker-compose -f $COMPOSE_FILE --env-file .env down 2>/dev/null || true
    
    # Build and start services
    docker-compose -f $COMPOSE_FILE --env-file .env up --build -d
    
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
        print_info "Checking backend logs..."
        docker-compose -f $COMPOSE_FILE --env-file .env logs backend
        exit 1
    fi
    
    # Wait for frontend service (development runs on port 3000)
    print_info "Waiting for frontend service..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -f http://localhost:3000 >/dev/null 2>&1; then
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
    print_success "Local deployment completed!"
    echo ""
    echo "🌐 Access URLs:"
    echo "  Frontend:     http://localhost:3000"
    echo "  Backend API:  http://localhost:8000"
    echo "  API Docs:     http://localhost:8000/docs"
    echo "  Health Check: http://localhost:8000/health"
    echo ""
    echo "🔧 Management Commands:"
    echo "  View logs:    docker-compose -f $COMPOSE_FILE --env-file .env logs -f"
    echo "  Stop services: docker-compose -f $COMPOSE_FILE --env-file .env down"
    echo "  Restart:      docker-compose -f $COMPOSE_FILE --env-file .env restart"
    echo "  Check status: docker-compose -f $COMPOSE_FILE --env-file .env ps"
    echo ""
    echo "🧪 Test with questions like:"
    echo "  - Explain the brachistochrone problem"
    echo "  - Show me how magnets work"
    echo "  - Demonstrate the Central Limit Theorem"
}

# Main function
main() {
    print_info "🚀 Starting Education AI Agent local development deployment..."
    echo ""
    
    check_requirements
    setup_env
    start_services
    wait_for_services
    show_deployment_info
    
    print_success "🎉 Local deployment completed!"
}

# If running this script directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 