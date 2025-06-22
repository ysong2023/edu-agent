#!/bin/bash

# Education AI Agent One-Click Deployment Script
set -e

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
    
    if [ ! -f .env ]; then
        if [ -f env.example ]; then
            cp env.example .env
            print_warning ".env file created. Please edit and add your API keys"
            print_warning "Especially need to set: ANTHROPIC_API_KEY"
        else
            print_error "env.example file not found"
            exit 1
        fi
    fi
    
    # Check required environment variables
    if ! grep -q "ANTHROPIC_API_KEY=.*[^[:space:]]" .env; then
        print_error "Please set ANTHROPIC_API_KEY in the .env file"
        exit 1
    fi
    
    print_success "Environment variables setup completed"
}

# Build images
build_images() {
    print_info "Building Docker images..."
    
    # Build backend image
    print_info "Building backend image..."
    docker build -f docker/backend/Dockerfile -t edu-agent-backend:latest .
    
    # Build frontend image
    print_info "Building frontend image..."
    docker build -f docker/frontend/Dockerfile -t edu-agent-frontend:latest .
    
    print_success "Image build completed"
}

# Start services
start_services() {
    print_info "Starting services..."
    
    # Stop existing services
    docker-compose down 2>/dev/null || true
    
    # Start services
    docker-compose up -d
    
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
    
    # Wait for frontend service
    print_info "Waiting for frontend service..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -f http://localhost:3000/health >/dev/null 2>&1; then
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
    echo "  Frontend:  http://localhost:3000"
    echo "  Backend API: http://localhost:8000"
    echo "  API Docs:  http://localhost:8000/docs"
    echo ""
    echo "Management Commands:"
    echo "  View logs:    docker-compose logs -f"
    echo "  Stop services: docker-compose down"
    echo "  Restart:      docker-compose restart"
    echo "  Check status: docker-compose ps"
}

# Main function
main() {
    print_info "Starting Education AI Agent system deployment..."
    
    check_requirements
    setup_env
    build_images
    start_services
    wait_for_services
    show_deployment_info
    
    print_success "Deployment completed!"
}

# If running this script directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 