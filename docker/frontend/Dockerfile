# Use official Node.js image as base
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY frontend/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY frontend/ .

# Build application
RUN npm run build

# Use nginx to serve static files
FROM nginx:alpine

# Copy custom nginx configuration
COPY docker/frontend/nginx.conf /etc/nginx/nginx.conf

# Copy build output to nginx directory
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"] 