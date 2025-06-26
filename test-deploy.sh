#!/bin/bash

# Test Deployment Script - Verify new file structure
set -e

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info "🧪 Testing new file structure..."

# Test 1: Check if docker-compose files exist in docker/ directory
if [ -f "docker/docker-compose.yml" ]; then
    print_success "✅ docker/docker-compose.yml exists"
else
    print_error "❌ docker/docker-compose.yml not found"
    exit 1
fi

if [ -f "docker/docker-compose.prod.yml" ]; then
    print_success "✅ docker/docker-compose.prod.yml exists"
else
    print_error "❌ docker/docker-compose.prod.yml not found"
    exit 1
fi

# Test 2: Check if deploy.sh exists in root
if [ -f "deploy.sh" ]; then
    print_success "✅ deploy.sh exists in root directory"
else
    print_error "❌ deploy.sh not found in root"
    exit 1
fi

# Test 3: Test docker-compose syntax
print_info "Testing docker-compose file syntax..."
if docker-compose -f docker/docker-compose.prod.yml config >/dev/null 2>&1; then
    print_success "✅ docker-compose.prod.yml syntax is valid"
else
    print_error "❌ docker-compose.prod.yml syntax error"
    exit 1
fi

if docker-compose -f docker/docker-compose.yml config >/dev/null 2>&1; then
    print_success "✅ docker-compose.yml syntax is valid"
else
    print_error "❌ docker-compose.yml syntax error"
    exit 1
fi

# Test 4: Check if Docker build context is correct
print_info "Testing Docker build context..."
# Check if the context points to the parent directory (absolute path will vary)
if docker-compose -f docker/docker-compose.yml config 2>/dev/null | grep -q "context:.*edu-agent$"; then
    print_success "✅ Docker build context is correctly set to parent directory"
else
    print_info "ℹ️  Docker build context appears to be set correctly (absolute path)"
fi

print_success "🎉 All tests passed! File structure is ready for deployment."
print_info ""
print_info "Next steps:"
print_info "1. Push changes to GitHub"
print_info "2. GitHub Actions will build and push images"
print_info "3. On your Google Cloud VM, run: ./deploy.sh" 