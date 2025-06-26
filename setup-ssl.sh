#!/bin/bash

# SSL Certificate Setup Script for Education AI Agent
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if domain is provided
if [ -z "$1" ]; then
    print_error "Please provide your domain name"
    echo "Usage: ./setup-ssl.sh your-domain.com"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-"admin@$DOMAIN"}

print_info "Setting up SSL certificate for domain: $DOMAIN"
print_info "Email: $EMAIL"

# Create necessary directories
mkdir -p docker/nginx/ssl
mkdir -p docker/nginx/conf.d

# Update nginx configuration with actual domain
print_info "Updating nginx configuration..."
sed -i "s/your-domain.com/$DOMAIN/g" docker/nginx/nginx.conf

# Start nginx without SSL first
print_info "Starting nginx for certificate challenge..."
docker-compose -f docker/docker-compose.prod.yml --env-file .env up -d nginx

# Wait for nginx to be ready
sleep 10

# Get SSL certificate
print_info "Obtaining SSL certificate from Let's Encrypt..."
docker-compose -f docker/docker-compose.prod.yml --env-file .env --profile ssl run --rm certbot \
    certonly --webroot --webroot-path=/var/www/certbot \
    --email $EMAIL --agree-tos --no-eff-email \
    -d $DOMAIN -d www.$DOMAIN

# Copy certificates to nginx directory
print_info "Setting up certificate files..."
docker-compose -f docker/docker-compose.prod.yml --env-file .env --profile ssl run --rm certbot \
    sh -c "cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/nginx/ssl/"

# Restart nginx with SSL
print_info "Restarting nginx with SSL configuration..."
docker-compose -f docker/docker-compose.prod.yml --env-file .env restart nginx

print_success "SSL certificate setup completed!"
print_info "Your site should now be accessible at https://$DOMAIN"

# Setup auto-renewal
print_info "Setting up certificate auto-renewal..."
(crontab -l 2>/dev/null; echo "0 12 * * * cd $(pwd) && docker-compose -f docker/docker-compose.prod.yml --env-file .env --profile ssl run --rm certbot renew --quiet && docker-compose -f docker/docker-compose.prod.yml --env-file .env restart nginx") | crontab -

print_success "Auto-renewal cron job added!"
print_info "Certificates will be automatically renewed every day at 12:00 PM" 