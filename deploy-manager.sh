#!/bin/bash

# ===========================================
# SUE Chatbot Deployment Manager v4.1
# Multi-Container Architecture with Enhanced Features
# Supports: Install, Update, Repair, Uninstall, Configuration Management
# Architecture: Frontend + Backend + ChromaDB + Nginx (4 containers)
# Compatible: CentOS, RHEL, Debian, Ubuntu, SUSE, Amazon Linux, Oracle Linux, Euler OS
# ===========================================

set -e

# Version and metadata
SCRIPT_VERSION="4.1.0"
SCRIPT_NAME="SUE Chatbot Deployment Manager"
GITHUB_REPO="https://github.com/arnozeng98/shebang-chatbot.git"
PROJECT_BASE_DIR="/www/wwwroot/sue"
SCRIPT_INSTALL_PATH="/usr/local/bin/sue"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Global variables
DETECTED_OS=""
PKG_MANAGER=""
PKG_UPDATE_CMD=""
PKG_INSTALL_CMD=""
FIREWALL_CMD=""
DOMAIN=""
PROJECT_DIR="$PROJECT_BASE_DIR/shebang-chatbot"
DOCKER_ENV_FILE=""
BACKEND_ENV_FILE=""
GITHUB_TOKEN=""
GITHUB_USERNAME=""

# ===========================================
# UTILITY FUNCTIONS
# ===========================================

print_sue_logo() {
    echo -e "${CYAN}"
    echo "  ███████╗   ██╗   ██╗   ███████╗"
    echo "  ██╔════╝   ██║   ██║   ██╔════╝"
    echo "  ███████╗   ██║   ██║   █████╗  "
    echo "  ╚════██║   ██║   ██║   ██╔══╝  "
    echo "  ███████║██╗╚██████╔╝██╗███████╗"
    echo "  ╚══════╝╚═╝ ╚═════╝ ╚═╝╚══════╝"
    echo ""
    echo "  Smart Universal Engine for Sexual Health Education"
    echo -e "${NC}"
}

print_banner() {
    print_sue_logo
    echo -e "${BLUE}"
    echo "================================================================"
    echo "🚀 $SCRIPT_NAME v$SCRIPT_VERSION"
    echo "================================================================"
    echo -e "${NC}"
}

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_step() { echo -e "${CYAN}🔄 $1${NC}"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ===========================================
# GITHUB AUTHENTICATION FUNCTIONS
# ===========================================

github_authentication() {
    echo -e "${YELLOW}🔐 GitHub Authentication Required${NC}"
    echo ""
    echo "This repository is private and requires authentication."
    echo "Please choose your authentication method:"
    echo ""
    echo "1. Personal Access Token (Recommended)"
    echo "2. Username & Password (Legacy)"
    echo "3. Use existing credentials"
    echo ""
    
    read -p "Choice [1-3]: " auth_choice
    
    case $auth_choice in
        1)
            github_token_auth
            ;;
        2)
            github_username_password_auth
            ;;
        3)
            if check_existing_github_auth; then
                print_status "Using existing GitHub credentials"
                return 0
            else
                print_warning "No existing credentials found"
                github_token_auth
            fi
            ;;
        *)
            print_error "Invalid choice, using Token authentication"
            github_token_auth
            ;;
    esac
}

github_token_auth() {
    echo ""
    echo -e "${CYAN}📝 Personal Access Token Authentication${NC}"
    echo ""
    echo "To create a Personal Access Token:"
    echo "1. Go to: https://github.com/settings/tokens"
    echo "2. Click 'Generate new token (classic)'"
    echo "3. Select 'repo' scope for private repositories"
    echo "4. Copy the generated token"
    echo ""
    
    while true; do
        read -s -p "Enter your GitHub Personal Access Token: " token
        echo ""
        
        if [[ -z "$token" ]]; then
            print_error "Token cannot be empty"
            continue
        fi
        
        # Test the token
        print_step "Validating token..."
        if test_github_token "$token"; then
            GITHUB_TOKEN="$token"
            save_github_credentials "$token" ""
            print_status "Token validated successfully"
            break
        else
            print_error "Invalid token or insufficient permissions"
            read -p "Try again? (y/n): " retry
            if [[ ! $retry =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
    done
}

github_username_password_auth() {
    echo ""
    echo -e "${CYAN}👤 Username & Password Authentication${NC}"
    echo ""
    print_warning "Note: GitHub deprecated password authentication for Git operations."
    print_info "Consider using Personal Access Token instead."
    echo ""
    
    read -p "GitHub Username: " username
    read -s -p "GitHub Password/Token: " password
    echo ""
    
    if [[ -z "$username" ]] || [[ -z "$password" ]]; then
        print_error "Username and password cannot be empty"
        return 1
    fi
    
    GITHUB_USERNAME="$username"
    GITHUB_TOKEN="$password"
    save_github_credentials "$password" "$username"
    print_status "Credentials saved"
}

test_github_token() {
    local token="$1"
    local repo_api="https://api.github.com/repos/arnozeng98/shebang-chatbot"
    
    if curl -s -H "Authorization: token $token" "$repo_api" | grep -q '"private": true'; then
        return 0
    else
        return 1
    fi
}

save_github_credentials() {
    local token="$1"
    local username="$2"
    
    mkdir -p "$PROJECT_BASE_DIR"
    
    # Save encrypted credentials
    echo "GITHUB_TOKEN=$(echo "$token" | base64)" > "$PROJECT_BASE_DIR/.github_auth"
    if [[ -n "$username" ]]; then
        echo "GITHUB_USERNAME=$(echo "$username" | base64)" >> "$PROJECT_BASE_DIR/.github_auth"
    fi
    
    chmod 600 "$PROJECT_BASE_DIR/.github_auth"
    print_info "Credentials saved securely"
}

load_github_credentials() {
    local auth_file="$PROJECT_BASE_DIR/.github_auth"
    
    if [[ -f "$auth_file" ]]; then
        source "$auth_file"
        
        if [[ -n "$GITHUB_TOKEN" ]]; then
            GITHUB_TOKEN=$(echo "$GITHUB_TOKEN" | base64 -d)
        fi
        
        if [[ -n "$GITHUB_USERNAME" ]]; then
            GITHUB_USERNAME=$(echo "$GITHUB_USERNAME" | base64 -d)
        fi
        
        return 0
    else
        return 1
    fi
}

check_existing_github_auth() {
    if load_github_credentials; then
        # Test if existing credentials still work
        if test_github_token "$GITHUB_TOKEN"; then
            return 0
        else
            print_warning "Existing credentials are no longer valid"
            rm -f "$PROJECT_BASE_DIR/.github_auth"
            return 1
        fi
    else
        return 1
    fi
}

# ===========================================
# OPERATING SYSTEM DETECTION
# ===========================================

detect_os() {
    print_step "Detecting operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID,,}"
        OS_LIKE="${ID_LIKE,,}"
        
        case "$OS_ID" in
            "centos"|"rhel"|"redhat")
                DETECTED_OS="RHEL"
                PKG_MANAGER="yum"
                if command_exists dnf; then PKG_MANAGER="dnf"; fi
                ;;
            "fedora")
                DETECTED_OS="Fedora"
                PKG_MANAGER="dnf"
                ;;
            "ubuntu"|"debian")
                DETECTED_OS="Debian"
                PKG_MANAGER="apt"
                ;;
            "opensuse"|"opensuse-leap"|"opensuse-tumbleweed"|"sles")
                DETECTED_OS="SUSE"
                PKG_MANAGER="zypper"
                ;;
            "amzn"|"amazon")
                DETECTED_OS="Amazon"
                PKG_MANAGER="yum"
                if command_exists dnf; then PKG_MANAGER="dnf"; fi
                ;;
            "ol"|"oracle")
                DETECTED_OS="Oracle"
                PKG_MANAGER="yum"
                if command_exists dnf; then PKG_MANAGER="dnf"; fi
                ;;
            "euler"|"euleros")
                DETECTED_OS="Euler"
                PKG_MANAGER="yum"
                ;;
            "arch"|"manjaro")
                DETECTED_OS="Arch"
                PKG_MANAGER="pacman"
                ;;
            *)
                if [[ "$OS_LIKE" == *"rhel"* ]] || [[ "$OS_LIKE" == *"fedora"* ]]; then
                    DETECTED_OS="RHEL-Like"
                    PKG_MANAGER="yum"
                    if command_exists dnf; then PKG_MANAGER="dnf"; fi
                elif [[ "$OS_LIKE" == *"debian"* ]]; then
                    DETECTED_OS="Debian-Like"
                    PKG_MANAGER="apt"
                else
                    DETECTED_OS="Unknown"
                fi
                ;;
        esac
    else
        DETECTED_OS="Unknown"
    fi
    
    # Set commands based on package manager
    case "$PKG_MANAGER" in
        "yum"|"dnf")
            PKG_UPDATE_CMD="$PKG_MANAGER update -y"
            PKG_INSTALL_CMD="$PKG_MANAGER install -y"
            FIREWALL_CMD="firewall-cmd"
            ;;
        "apt")
            PKG_UPDATE_CMD="apt-get update && apt-get upgrade -y"
            PKG_INSTALL_CMD="apt-get install -y"
            FIREWALL_CMD="ufw"
            ;;
        "zypper")
            PKG_UPDATE_CMD="zypper update -y"
            PKG_INSTALL_CMD="zypper install -y"
            FIREWALL_CMD="firewall-cmd"
            ;;
        "pacman")
            PKG_UPDATE_CMD="pacman -Syu --noconfirm"
            PKG_INSTALL_CMD="pacman -S --noconfirm"
            FIREWALL_CMD="ufw"
            ;;
        *)
            print_error "Unsupported package manager: $PKG_MANAGER"
            exit 1
            ;;
    esac
    
    print_status "Detected: $DETECTED_OS ($PKG_MANAGER)"
}

# ===========================================
# CONFIGURATION MANAGEMENT
# ===========================================

load_config() {
    local config_file="$PROJECT_BASE_DIR/shebang-chatbot/docker/config/domain.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        if [[ -n "$CHATBOT_DOMAIN" ]]; then
            DOMAIN="$CHATBOT_DOMAIN"
            PROJECT_DIR="$PROJECT_BASE_DIR/shebang-chatbot"
            DOCKER_ENV_FILE="$PROJECT_DIR/docker/config/docker.env.production"
            BACKEND_ENV_FILE="$PROJECT_DIR/backend/.env"
        fi
    fi
    
    # Load GitHub credentials if available
    load_github_credentials >/dev/null 2>&1 || true
}

save_domain_config() {
    local domain="$1"
    mkdir -p "$PROJECT_DIR/docker/config"
    echo "CHATBOT_DOMAIN=\"$domain\"" > "$PROJECT_DIR/docker/config/domain.conf"
}

get_server_ip() {
    echo "Server Network Information:"
    
    # Get IPv4 address
    local ipv4=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 ipinfo.io/ip 2>/dev/null)
    if [[ -n "$ipv4" && "$ipv4" != *"error"* ]]; then
        echo "  📍 IPv4: $ipv4"
    fi
    
    # Get IPv6 address  
    local ipv6=$(curl -s -6 ifconfig.me 2>/dev/null || curl -s -6 ipinfo.io/ip 2>/dev/null)
    if [[ -n "$ipv6" && "$ipv6" != *"error"* ]]; then
        echo "  📍 IPv6: $ipv6"
    fi
    
    # Get local network interfaces
    echo "  🔗 Local interfaces:"
    if command_exists ip; then
        ip addr show | grep -E "inet " | grep -v "127.0.0.1" | awk '{print "     " $2}' | head -3
    elif command_exists ifconfig; then
        ifconfig | grep -E "inet " | grep -v "127.0.0.1" | awk '{print "     " $2}' | head -3
    fi
    
    # Return primary IPv4 for scripts that need a single IP
    echo "$ipv4"
}

configure_domain() {
    echo -e "${YELLOW}🌐 Domain Configuration${NC}"
    
    if [[ -n "$DOMAIN" ]]; then
        echo "Current domain: $DOMAIN"
        read -p "Change domain? (y/n): " change
        if [[ ! $change =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo ""
    get_server_ip >/dev/null 2>&1  # Call but suppress the return value
    # Show the network info directly 
    echo "Server Network Information:"
    local ipv4=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 ipinfo.io/ip 2>/dev/null)
    if [[ -n "$ipv4" && "$ipv4" != *"error"* ]]; then
        echo "  📍 IPv4: $ipv4"
    fi
    local ipv6=$(curl -s -6 ifconfig.me 2>/dev/null || curl -s -6 ipinfo.io/ip 2>/dev/null)
    if [[ -n "$ipv6" && "$ipv6" != *"error"* ]]; then
        echo "  📍 IPv6: $ipv6"
    fi
    echo "  🔗 Local interfaces:"
    if command_exists ip; then
        ip addr show | grep -E "inet " | grep -v "127.0.0.1" | awk '{print "     " $2}' | head -3
    elif command_exists ifconfig; then
        ifconfig | grep -E "inet " | grep -v "127.0.0.1" | awk '{print "     " $2}' | head -3
    fi
    echo ""
    
    while true; do
        read -p "Enter domain (e.g., chat.yourdomain.com): " new_domain
        
        if [[ -z "$new_domain" ]]; then
            print_error "Domain cannot be empty"
            continue
        fi
        
        if [[ ! "$new_domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
            print_error "Invalid domain format"
            continue
        fi
        
        DOMAIN="$new_domain"
        PROJECT_DIR="$PROJECT_BASE_DIR/shebang-chatbot"
        DOCKER_ENV_FILE="$PROJECT_DIR/docker/config/docker.env.production"
        BACKEND_ENV_FILE="$PROJECT_DIR/backend/.env"
        
        save_domain_config "$DOMAIN"
        print_status "Domain set to: $DOMAIN"
        break
    done
}

# ===========================================
# DEPENDENCY INSTALLATION WITH IMPROVED OS DETECTION
# ===========================================

install_required_tools() {
    print_step "Installing required system tools..."
    
    # Tools needed by the script
    local tools=("curl" "wget" "openssl" "lsof")
    
    # OS-specific additional tools
    case "$PKG_MANAGER" in
        "yum"|"dnf")
            tools+=("yum-utils" "ca-certificates" "firewalld" "net-tools" "psmisc")
            ;;
        "apt")
            tools+=("ca-certificates" "gnupg" "lsb-release" "apt-transport-https" "software-properties-common" "ufw" "net-tools" "psmisc")
            ;;
        "zypper")
            tools+=("ca-certificates" "net-tools" "psmisc")
            ;;
        "pacman")
            tools+=("net-tools" "psmisc")
            ;;
    esac
    
    # Install each tool with proper error handling
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            print_step "Installing $tool..."
            
            # Try installation with specific package names per OS
            case "$tool" in
                "lsof")
                    case "$PKG_MANAGER" in
                        "yum"|"dnf")
                            eval "$PKG_INSTALL_CMD lsof" 2>/dev/null || {
                                # Try alternative package names
                                eval "$PKG_INSTALL_CMD util-linux procps-ng" 2>/dev/null || true
                            }
                            ;;
                        "apt")
                            apt-get update -qq 2>/dev/null || true
                            eval "$PKG_INSTALL_CMD lsof" 2>/dev/null || {
                                # Try alternative
                                eval "$PKG_INSTALL_CMD procps net-tools" 2>/dev/null || true
                            }
                            ;;
                        "zypper")
                            eval "$PKG_INSTALL_CMD lsof" 2>/dev/null || {
                                eval "$PKG_INSTALL_CMD procps net-tools" 2>/dev/null || true
                            }
                            ;;
                        "pacman")
                            eval "$PKG_INSTALL_CMD lsof" 2>/dev/null || {
                                eval "$PKG_INSTALL_CMD procps-ng net-tools" 2>/dev/null || true
                            }
                            ;;
                    esac
                    ;;
                *)
                    # Capture installation output to check for "already installed" messages
                    install_output=$(eval "$PKG_INSTALL_CMD $tool" 2>&1) || {
                        # Check if it's actually already installed (common with apt)
                        if echo "$install_output" | grep -q -E "(already|newest|up to date|0 newly installed)"; then
                            print_info "$tool is already at the newest version"
                        else
                            print_warning "Failed to install $tool, continuing..."
                        fi
                    }
                    ;;
            esac
            
            # Verify installation
            if command_exists "$tool"; then
                print_status "$tool installed successfully"
            else
                case "$tool" in
                    "lsof")
                        print_warning "$tool installation failed, will use alternative port cleanup methods"
                        ;;
                    *)
                        print_warning "$tool installation failed, continuing anyway..."
                        ;;
                esac
            fi
        else
            print_status "$tool already available"
        fi
    done
    
    print_status "System tools installation completed"
}

# ===========================================
# IMPROVED PORT CLEANUP FUNCTIONS
# ===========================================

cleanup_ports() {
    print_step "Cleaning up conflicting ports..."
    
    # Stop system nginx if running
    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true
    
    # Function to kill processes on specific port
    kill_port_processes() {
        local port=$1
        local killed=false
        
        # Method 1: lsof (preferred)
        if command_exists lsof; then
            if lsof -ti:$port >/dev/null 2>&1; then
                print_info "Using lsof to clean port $port..."
                lsof -ti:$port | xargs kill -9 2>/dev/null || true
                killed=true
            fi
        fi
        
        # Method 2: fuser (alternative)  
        if [ "$killed" = false ] && command_exists fuser; then
            if fuser $port/tcp >/dev/null 2>&1; then
                print_info "Using fuser to clean port $port..."
                fuser -k $port/tcp 2>/dev/null || true
                killed=true
            fi
        fi
        
        # Method 3: netstat + kill (last resort)
        if [ "$killed" = false ] && command_exists netstat; then
            print_info "Using netstat method to clean port $port..."
            netstat -tlnp 2>/dev/null | awk '$4 ~ /:'"$port"'$/ {split($7,a,"/"); if(a[1]!="" && a[1]!="-") system("kill -9 " a[1])}' 2>/dev/null || true
            killed=true
        fi
        
        # Method 4: ss command (modern alternative)
        if [ "$killed" = false ] && command_exists ss; then
            print_info "Using ss method to clean port $port..."
            ss -tlnp | awk '$4 ~ /:'"$port"'$/ {split($6,a,","); for(i in a) if(match(a[i],/pid=([0-9]+)/,m)) system("kill -9 " m[1])}' 2>/dev/null || true
        fi
    }
    
    # Clean up required ports
    for port in 80 443 8001; do
        kill_port_processes $port
    done
    
    # Remove any existing Docker containers on these ports
    docker ps -a --filter "publish=80" --filter "publish=443" --filter "publish=8001" -q | xargs docker rm -f 2>/dev/null || true
    
    print_status "Port cleanup completed"
}

# ===========================================
# INSTALLATION FUNCTIONS
# ===========================================

update_system() {
    print_step "Updating system packages..."
    
    case "$PKG_MANAGER" in
        "yum"|"dnf")
            eval "$PKG_UPDATE_CMD"
            ;;
        "apt")
            apt-get update && apt-get upgrade -y
            ;;
        "zypper")
            zypper refresh && zypper update -y
            ;;
        "pacman")
            pacman -Syu --noconfirm
            ;;
    esac
    
    print_status "System updated successfully"
}

check_and_install_git() {
    print_step "Checking Git installation..."
    
    if command_exists git; then
        local git_version=$(git --version | cut -d' ' -f3)
        print_status "Git already installed: v$git_version"
        return 0
    fi
    
    print_step "Installing Git..."
    eval "$PKG_INSTALL_CMD git"
    
    if command_exists git; then
        local git_version=$(git --version | cut -d' ' -f3)
        print_status "Git installed successfully: v$git_version"
    else
        print_error "Failed to install Git"
        return 1
    fi
}

install_dependencies() {
    print_step "Installing system dependencies..."
    install_required_tools
}

install_docker() {
    if command_exists docker; then
        print_status "Docker already installed"
        return 0
    fi
    
    print_step "Installing Docker..."
    
    case "$PKG_MANAGER" in
        "yum"|"dnf")
            if [[ "$PKG_MANAGER" == "dnf" ]]; then
                dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            else
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            fi
            eval "$PKG_INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
            ;;
        "apt")
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            if grep -q "ubuntu" /etc/os-release 2>/dev/null; then
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
            else
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
            fi
            apt-get update
            install_output=$(eval "$PKG_INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" 2>&1) || {
                if echo "$install_output" | grep -q -E "(already|newest|up to date|0 newly installed)"; then
                    print_info "Docker packages are already at the newest version"
                else
                    print_error "Failed to install Docker packages: $install_output"
                    return 1
                fi
            }
            ;;
        "zypper")
            zypper addrepo https://download.docker.com/linux/sles/docker-ce.repo
            eval "$PKG_INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
            ;;
        "pacman")
            eval "$PKG_INSTALL_CMD docker docker-compose"
            ;;
    esac
    
    systemctl start docker
    systemctl enable docker
    
    # Verify Docker installation
    if command_exists docker && systemctl is-active --quiet docker; then
        print_status "Docker installed and started successfully"
    else
        print_error "Docker installation failed or service not running"
        return 1
    fi
}

install_certbot() {
    if command_exists certbot; then
        print_status "Certbot already installed"
        return 0
    fi
    
    print_step "Installing Certbot..."
    
    case "$PKG_MANAGER" in
        "yum"|"dnf")
            eval "$PKG_INSTALL_CMD epel-release" || true
            eval "$PKG_INSTALL_CMD certbot" || {
                eval "$PKG_INSTALL_CMD python3 python3-pip"
                pip3 install certbot
            }
            ;;
        "apt")
            install_output=$(eval "$PKG_INSTALL_CMD certbot" 2>&1) || {
                if echo "$install_output" | grep -q -E "(already|newest|up to date|0 newly installed)"; then
                    print_info "Certbot is already at the newest version"
                else
                    print_error "Failed to install Certbot: $install_output"
                    return 1
                fi
            }
            ;;
        "zypper")
            eval "$PKG_INSTALL_CMD certbot"
            ;;
        "pacman")
            eval "$PKG_INSTALL_CMD certbot"
            ;;
    esac
    
    # Verify Certbot installation
    if command_exists certbot; then
        print_status "Certbot installed successfully"
    else
        print_error "Certbot installation failed"
        return 1
    fi
}

setup_firewall() {
    print_step "Configuring firewall..."
    
    case "$FIREWALL_CMD" in
        "firewall-cmd")
            if ! systemctl is-active --quiet firewalld; then
                systemctl start firewalld
                systemctl enable firewalld
            fi
            firewall-cmd --permanent --add-port=80/tcp
            firewall-cmd --permanent --add-port=443/tcp
            firewall-cmd --permanent --add-port=22/tcp
            firewall-cmd --reload
            print_status "Firewall (firewalld) configured"
            ;;
        "ufw")
            ufw --force enable
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            print_status "Firewall (ufw) configured"
            ;;
    esac
}

# ===========================================
# DEPLOYMENT FUNCTIONS
# ===========================================

create_environment_config() {
    local domain="$1" email="$2" admin_username="$3" admin_password="$4" openai_key="$5"
    
    local password_hash=$(echo -n "$admin_password" | sha256sum | cut -d' ' -f1)
    local jwt_secret=$(openssl rand -hex 32)
    
    mkdir -p docker/config
    
    # Use template-based environment generation
    if [[ -f "docker/config/docker.env.template" ]]; then
        print_step "Generating environment config from template..."
        
        # Replace template variables
        sed -e "s/{{DOMAIN}}/$domain/g" \
            -e "s/{{OPENAI_API_KEY}}/$openai_key/g" \
            -e "s/{{ADMIN_USERNAME}}/$admin_username/g" \
            -e "s/{{ADMIN_PASSWORD}}/$admin_password/g" \
            -e "s/{{ADMIN_PASSWORD_HASH}}/$password_hash/g" \
            -e "s/{{JWT_SECRET}}/$jwt_secret/g" \
            -e "s/{{EMBEDDING_MODEL}}/text-embedding-ada-002/g" \
            -e "s/{{CHAT_MODEL}}/gpt-4o/g" \
            -e "s/{{CHUNK_SIZE}}/512/g" \
            -e "s/{{CHUNK_OVERLAP}}/64/g" \
            -e "s/{{BARK_KEY}}//g" \
            docker/config/docker.env.template > "$DOCKER_ENV_FILE"
        
        # Add SSL email (not in template)
        echo "SSL_EMAIL=$email" >> "$DOCKER_ENV_FILE"
    else
        print_warning "Template not found, creating basic environment config..."
        
        cat > "$DOCKER_ENV_FILE" << EOF
DOMAIN=$domain
OPENAI_API_KEY=$openai_key
ADMIN_USERNAME=$admin_username
ADMIN_PASSWORD=$admin_password
ADMIN_PASSWORD_HASH=$password_hash
JWT_SECRET=$jwt_secret
SSL_EMAIL=$email
EMBEDDING_MODEL=text-embedding-ada-002
CHAT_MODEL=gpt-4o
CHUNK_SIZE=512
CHUNK_OVERLAP=64
BARK_KEY=
DOCKER_ENV=true
TZ=UTC
PYTHONPATH=/app
PYTHONUNBUFFERED=1
EOF
    fi

    cat > "$BACKEND_ENV_FILE" << EOF
OPENAI_API_KEY=$openai_key
ADMIN_USERNAME=$admin_username
ADMIN_PASSWORD=$admin_password
ADMIN_PASSWORD_HASH=$password_hash
JWT_SECRET=$jwt_secret
EMBEDDING_MODEL=text-embedding-ada-002
CHAT_MODEL=gpt-4o
CHUNK_SIZE=512
CHUNK_OVERLAP=64
DOCKER_ENV=true
DOMAIN=$domain
EOF

    # NOTE: Removed generate_nginx_config call for multi-container deployment
    # Multi-container nginx config is handled by setup_multi_container_nginx_config function
    
    print_status "Configuration created"
}

generate_nginx_config() {
    local domain="$1"
    
    print_step "Generating nginx configuration for $domain..."
    
    # Remove old domain-specific configurations (keep templates)
    find docker/nginx/conf.d/ -name "*.conf" ! -name "chatbot.conf.template" -delete 2>/dev/null || true
    
    # Create domain-specific nginx configuration
    cat > "docker/nginx/conf.d/$domain.conf" << EOF
# Upstream backend for $domain
upstream chatbot_backend_production {
    server chatbot:8000;
    keepalive 32;
}

# HTTP server - serves content and handles SSL challenges
server {
    listen 80;
    server_name $domain;
    
    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    
    # Check if SSL certificate exists, if not serve over HTTP
    location / {
        # Try to check SSL certificate existence and redirect accordingly
        # For now, serve over HTTP until SSL is configured
        proxy_pass http://chatbot_backend_production;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Standard timeouts
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
        
        # Client settings
        client_max_body_size 50M;
    }
    
    # API endpoints with rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://chatbot_backend_production;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # API timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 60s;
    }
    
    # Admin endpoints with longer timeouts
    location /api/admin/reindex-vector-database {
        limit_req zone=api burst=2 nodelay;
        
        proxy_pass http://chatbot_backend_production;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Extended timeout for reindex operation
        proxy_read_timeout 300s;
        proxy_send_timeout 60s;
        proxy_connect_timeout 30s;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://chatbot_backend_production;
        access_log off;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 5s;
        proxy_connect_timeout 5s;
    }
}
EOF

    print_status "Nginx configuration generated for $domain"
}

create_ssl_nginx_config() {
    local domain="$1"
    
    print_step "Creating HTTPS nginx configuration for $domain..."
    
    cat > "docker/nginx/conf.d/$domain.conf" << EOF
# Upstream backend for $domain
upstream chatbot_backend_production {
    server chatbot:8000;
    keepalive 32;
}

# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name $domain;
    
    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server for $domain
server {
    listen 443 ssl;
    http2 on;
    server_name $domain;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https:; connect-src 'self' https: wss: ws:;" always;

    # Client settings
    client_max_body_size 50M;
    client_body_timeout 60s;
    client_header_timeout 60s;

    # Special handling for reindex endpoint
    location /api/admin/reindex-vector-database {
        limit_req zone=api burst=2 nodelay;
        
        proxy_pass http://chatbot_backend_production;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 5 minutes for reindex
        proxy_read_timeout 300s;
        proxy_send_timeout 60s;
        proxy_connect_timeout 30s;
    }

    # API endpoints
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://chatbot_backend_production;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://chatbot_backend_production;
        access_log off;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 5s;
        proxy_connect_timeout 5s;
    }

    # Main application
    location / {
        proxy_pass http://chatbot_backend_production;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }
}
EOF

    print_status "HTTPS nginx configuration created for $domain"
}

setup_multi_container_nginx_config() {
    local domain="$1"
    local ssl_mode="${2:-http}"  # Default to HTTP-only mode
    
    print_step "Creating multi-container nginx configuration for $domain (mode: $ssl_mode)..."
    
    # Backup existing config if it exists
    if [[ -f "docker/nginx/conf.d/$domain.conf" ]]; then
        cp "docker/nginx/conf.d/$domain.conf" "docker/nginx/conf.d/$domain.conf.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backed up existing nginx config"
    fi
    
    # Create nginx config for multi-container setup using new template
    if [[ -f "docker/nginx/conf.d/chatbot.conf.template" ]]; then
        # Generate unique upstream name from domain
        local upstream_name=$(echo "$domain" | sed 's/[^a-zA-Z0-9]/_/g')
        
        # Replace template variables
        sed -e "s/{{DOMAIN}}/$domain/g" \
            -e "s/{{UPSTREAM_NAME}}/$upstream_name/g" \
            docker/nginx/conf.d/chatbot.conf.template > \
            "docker/nginx/conf.d/$domain.conf"
            
        # If HTTP-only mode, remove HTTPS server configuration
        if [[ "$ssl_mode" == "http" ]]; then
            print_info "Generating HTTP-only configuration (SSL will be added later)"
            sed -i '/# HTTPS server/,$d' "docker/nginx/conf.d/$domain.conf"
        fi
    else
        print_error "Multi-container nginx template not found: docker/nginx/conf.d/chatbot.conf.template"
        print_info "Creating basic nginx configuration..."
        create_basic_multi_container_nginx_config "$domain" "$ssl_mode"
    fi
    
    print_status "Multi-container nginx configuration created for $domain (mode: $ssl_mode)"
}

create_http_only_nginx_config() {
    local domain="$1"
    
    print_step "Creating HTTP-only nginx configuration for $domain..."
    
    # Generate unique upstream name from domain
    local upstream_name=$(echo "$domain" | sed 's/[^a-zA-Z0-9]/_/g')
    
    cat > "docker/nginx/conf.d/$domain.conf" << EOF
# Multi-Container Nginx Configuration (HTTP-only)
# This configuration is used during SSL certificate acquisition

# Rate limiting zones
limit_req_zone \$binary_remote_addr zone=${upstream_name}_api:10m rate=10r/s;
limit_req_zone \$binary_remote_addr zone=${upstream_name}_general:10m rate=30r/s;

# Upstream servers
upstream ${upstream_name}_backend {
    server backend:8000;
    keepalive 32;
}

upstream ${upstream_name}_frontend {
    server frontend:8080;
    keepalive 16;
}

upstream ${upstream_name}_chromadb {
    server chromadb:8000;
    keepalive 8;
}

# HTTP server (for SSL certificate acquisition and HTTP traffic)
server {
    listen 80;
    server_name $domain;
    
    # Allow large file uploads
    client_max_body_size 50M;
    client_body_timeout 60s;
    client_header_timeout 60s;

    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }

    # Health checks (no rate limiting)
    location /health {
        proxy_pass http://${upstream_name}_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 10s;
        proxy_connect_timeout 5s;
    }
    
    location /health/frontend {
        proxy_pass http://${upstream_name}_frontend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 10s;
        proxy_connect_timeout 5s;
    }
    
    location /health/chromadb {
        proxy_pass http://${upstream_name}_chromadb/api/v1/heartbeat;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 10s;
        proxy_connect_timeout 5s;
    }

    # Backend API endpoints
    location /api/ {
        limit_req zone=${upstream_name}_api burst=20 nodelay;
        
        proxy_pass http://${upstream_name}_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 60s;
    }

    # Admin routes - redirect to frontend for SPA handling
    location /admin {
        limit_req zone=${upstream_name}_general burst=50 nodelay;
        
        proxy_pass http://${upstream_name}_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }

    location /admin/ {
        limit_req zone=${upstream_name}_general burst=50 nodelay;
        
        proxy_pass http://${upstream_name}_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }

    # FastAPI docs
    location /docs {
        proxy_pass http://${upstream_name}_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Frontend React app (catch-all)
    location / {
        limit_req zone=${upstream_name}_general burst=50 nodelay;
        
        proxy_pass http://${upstream_name}_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 60s;
    }
}
EOF

    print_status "HTTP-only nginx configuration created for $domain"
}

create_ssl_multi_container_nginx_config() {
    local domain="$1"
    
    print_step "Creating HTTPS multi-container nginx configuration for $domain..."
    
    cat > "docker/nginx/conf.d/$domain.conf" << EOF
# Multi-Container Nginx Configuration for $domain
# Frontend: port 8080, Backend: port 8000, ChromaDB: port 8001

# Upstream servers
upstream chatbot_backend {
    server backend:8000;
    keepalive 32;
}

upstream chatbot_frontend {
    server frontend:8080;
    keepalive 16;
}

upstream chromadb_server {
    server chromadb:8000;
    keepalive 8;
}

# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name $domain;
    
    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server for $domain
server {
    listen 443 ssl;
    http2 on;
    server_name $domain;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https:; connect-src 'self' https: wss: ws:;" always;

    # Client settings
    client_max_body_size 50M;
    client_body_timeout 60s;
    client_header_timeout 60s;

    # Backend API endpoints
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://chatbot_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 60s;
    }

    # FastAPI docs (served by backend)
    location /docs {
        proxy_pass http://chatbot_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }

    # OpenAPI spec (served by backend)
    location /openapi.json {
        proxy_pass http://chatbot_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }

    # Special handling for reindex endpoint
    location /api/admin/reindex-vector-database {
        limit_req zone=api burst=2 nodelay;
        
        proxy_pass http://chatbot_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 5 minutes for reindex
        proxy_read_timeout 300s;
        proxy_send_timeout 60s;
        proxy_connect_timeout 30s;
    }

    # Admin routes - redirect to frontend for SPA handling
    location /admin {
        limit_req zone=api burst=10 nodelay;
        
        proxy_pass http://chatbot_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_read_timeout 120s;
        proxy_send_timeout 60s;
        proxy_connect_timeout 30s;
    }

    location /admin/ {
        limit_req zone=api burst=10 nodelay;
        
        proxy_pass http://chatbot_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_read_timeout 120s;
        proxy_send_timeout 60s;
        proxy_connect_timeout 30s;
    }

    # ChromaDB API (optional - for direct access if needed)
    location /chromadb/ {
        limit_req zone=api burst=10 nodelay;
        
        # Remove /chromadb prefix when proxying
        rewrite ^/chromadb/(.*)\$ /\$1 break;
        
        proxy_pass http://chromadb_server;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_read_timeout 60s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }

    # Serve uploaded files directly from nginx
    location /static/uploads/ {
        alias /var/www/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
    }

    # Serve logo files
    location /static/logo/ {
        alias /var/www/logo/;
        expires 30d;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
    }

    # Health check endpoints
    location /health {
        proxy_pass http://chatbot_backend;
        access_log off;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 5s;
        proxy_connect_timeout 5s;
    }

    location /health/frontend {
        proxy_pass http://chatbot_frontend;
        access_log off;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 5s;
        proxy_connect_timeout 5s;
    }

    location /health/chromadb {
        proxy_pass http://chromadb_server/api/v1/heartbeat;
        access_log off;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 5s;
        proxy_connect_timeout 5s;
    }

    # Frontend application (React SPA)
    location / {
        proxy_pass http://chatbot_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }

    # Block access to sensitive files
    location ~ /\\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ \\.(env|log|conf)\$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

    print_status "HTTPS multi-container nginx configuration created for $domain"
}

create_basic_multi_container_nginx_config() {
    local domain="$1"
    local ssl_mode="${2:-http}"  # Default to HTTP-only mode
    
    if [[ "$ssl_mode" == "http" ]]; then
        # Use the HTTP-only configuration
        create_http_only_nginx_config "$domain"
        return 0
    fi
    
    print_step "Creating basic multi-container nginx configuration for $domain..."
    
    # Generate unique upstream name from domain
    local upstream_name=$(echo "$domain" | sed 's/[^a-zA-Z0-9]/_/g')
    
    cat > "docker/nginx/conf.d/$domain.conf" << EOF
# Multi-Container Nginx Configuration
# Frontend: port 8080, Backend: port 8000, ChromaDB: port 8001

# Rate limiting zones
limit_req_zone \$binary_remote_addr zone=${upstream_name}_api:10m rate=10r/s;
limit_req_zone \$binary_remote_addr zone=${upstream_name}_general:10m rate=30r/s;

# Upstream servers
upstream ${upstream_name}_backend {
    server backend:8000;
    keepalive 32;
}

upstream ${upstream_name}_frontend {
    server frontend:8080;
    keepalive 16;
}

upstream ${upstream_name}_chromadb {
    server chromadb:8000;
    keepalive 8;
}

# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name $domain;
    
    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl;
    http2 on;
    server_name $domain;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https:; connect-src 'self' https: wss: ws:;" always;

    # Client settings
    client_max_body_size 50M;
    client_body_timeout 60s;
    client_header_timeout 60s;

    # Backend API endpoints
    location /api/ {
        limit_req zone=${upstream_name}_api burst=20 nodelay;
        
        proxy_pass http://${upstream_name}_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 60s;
    }

    # Admin routes - redirect to frontend for SPA handling
    location /admin {
        limit_req zone=${upstream_name}_general burst=50 nodelay;
        
        proxy_pass http://${upstream_name}_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }

    location /admin/ {
        limit_req zone=${upstream_name}_general burst=50 nodelay;
        
        proxy_pass http://${upstream_name}_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
        proxy_connect_timeout 15s;
    }

    # Health check endpoints
    location /health {
        proxy_pass http://${upstream_name}_backend;
        access_log off;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 5s;
        proxy_connect_timeout 5s;
    }

    location /health/frontend {
        proxy_pass http://${upstream_name}_frontend;
        access_log off;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 5s;
        proxy_connect_timeout 5s;
    }

    location /health/chromadb {
        proxy_pass http://${upstream_name}_chromadb/api/v1/heartbeat;
        access_log off;
        
        proxy_read_timeout 10s;
        proxy_send_timeout 5s;
        proxy_connect_timeout 5s;
    }

    # FastAPI docs
    location /docs {
        proxy_pass http://${upstream_name}_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Frontend React app (catch-all)
    location / {
        limit_req zone=${upstream_name}_general burst=50 nodelay;
        
        proxy_pass http://${upstream_name}_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 60s;
    }
}
EOF

    print_status "Basic multi-container nginx configuration created for $domain"
}

clone_project() {
    print_step "Cloning project from GitHub..."
    
    # Check if we have GitHub credentials, if not, authenticate
    if [[ -z "$GITHUB_TOKEN" ]]; then
        if ! check_existing_github_auth; then
            github_authentication
            if [[ -z "$GITHUB_TOKEN" ]]; then
                print_error "GitHub authentication failed"
                return 1
            fi
        fi
    fi
    
    # Step 1: Safe directory cleanup and preparation
    print_info "Preparing clean directory structure..."
    
    # Always start from root to avoid path issues
    cd /
    
    # Create base directory
    mkdir -p "$PROJECT_BASE_DIR"
    
    # If project directory exists, do complete cleanup
    if [ -d "$PROJECT_BASE_DIR/shebang-chatbot" ]; then
        print_warning "Existing project found, performing complete cleanup..."
        
        # Stop any running containers first
        cd "$PROJECT_BASE_DIR/shebang-chatbot" 2>/dev/null || true
        docker compose -f docker/compose/docker-compose.multi-container.yml down --volumes --remove-orphans --timeout 10 2>/dev/null || true
        docker compose -f docker/compose/docker-compose.production.yml down --volumes --remove-orphans --timeout 10 2>/dev/null || true
        
        # Go back to root and remove completely
        cd /
        rm -rf "$PROJECT_BASE_DIR/shebang-chatbot"
        
        # Wait a moment for filesystem to sync
        sleep 2
        
        print_info "Old project completely removed"
    fi
    
    # Step 2: Navigate to base directory
    cd "$PROJECT_BASE_DIR"
    pwd  # Confirm our location
    
    # Step 3: Setup authenticated clone URL
    local auth_repo_url
    if [[ -n "$GITHUB_USERNAME" ]]; then
        auth_repo_url="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/arnozeng98/shebang-chatbot.git"
    else
        auth_repo_url="https://${GITHUB_TOKEN}@github.com/arnozeng98/shebang-chatbot.git"
    fi
    
    # Step 4: Clone repository with authentication
    print_info "Cloning private repository with authentication..."
    if git clone "$auth_repo_url"; then
        print_status "Project cloned successfully"
    else
        print_error "Failed to clone repository"
        print_info "Attempting retry with fresh credentials..."
        
        # Clear old credentials and re-authenticate
        rm -f "$PROJECT_BASE_DIR/.github_auth"
        github_authentication
        
        if [[ -n "$GITHUB_TOKEN" ]]; then
            # Retry with new credentials
            if [[ -n "$GITHUB_USERNAME" ]]; then
                auth_repo_url="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/arnozeng98/shebang-chatbot.git"
            else
                auth_repo_url="https://${GITHUB_TOKEN}@github.com/arnozeng98/shebang-chatbot.git"
            fi
            
            if git clone "$auth_repo_url"; then
                print_status "Project cloned successfully on retry"
            else
                print_error "Failed to clone repository after retry"
                return 1
            fi
        else
            print_error "Authentication failed, cannot clone repository"
            return 1
        fi
    fi
    
    # Step 5: Navigate to project and confirm
    cd "$PROJECT_DIR"
    pwd  # Confirm our final location
    print_status "Project ready at: $PROJECT_DIR"
    
    # Step 6: Fix any potential ownership issues
    chown -R $(whoami):$(whoami) "$PROJECT_DIR" 2>/dev/null || true
    
    # Step 7: Remove credentials from git remote for security
    print_step "Securing git configuration..."
    git remote set-url origin "$GITHUB_REPO"
    print_info "Git remote URL secured (credentials removed)"
}

setup_project_directories() {
    print_step "Setting up project directories..."
    
    cd "$PROJECT_DIR"
    
    # Create data directories
    mkdir -p docker-data/{processed,raw,vectors}
    mkdir -p docker-static/{uploads,logo}
    mkdir -p docker/nginx/ssl
    mkdir -p /var/www/certbot
    
    # Copy logo if exists
    if [ -f "backend/static/logo/logo.png" ]; then
        cp backend/static/logo/logo.png docker-static/logo/
    fi
    
    # Set proper permissions
    chmod -R 755 docker-data docker-static
    
    print_status "Project directories ready"
}

install_script_globally() {
    print_step "Installing SUE command globally..."
    
    # Copy script to global location
    cp "$0" "$SCRIPT_INSTALL_PATH"
    chmod +x "$SCRIPT_INSTALL_PATH"
    
    # Add to PATH if not already there
    if ! grep -q "/usr/local/bin" ~/.bashrc 2>/dev/null; then
        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    fi
    
    print_status "SUE command installed - use 'sue' to run this script"
}

deploy_services() {
    print_step "Deploying multi-container services..."
    
    # Clean up ports and services
    cleanup_ports
    
    # Stop any existing deployments
    cd "$PROJECT_DIR"
    docker compose -f docker/compose/docker-compose.production.yml down 2>/dev/null || true
    docker compose -f docker/compose/docker-compose.multi-container.yml down 2>/dev/null || true
    
    # Create required directories for multi-container
    print_step "Creating data directories..."
    mkdir -p docker-data/chromadb
    mkdir -p docker-static/uploads
    mkdir -p docker-static/logo
    
    # Setup nginx configuration for multi-container
    print_step "Configuring nginx for multi-container..."
    setup_multi_container_nginx_config "$DOMAIN" "http"
    
    # Load environment variables
    export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
    
    # Deploy services (removed waiting logic as services start sequentially)
    print_step "Starting ChromaDB..."
    if docker compose -f docker/compose/docker-compose.multi-container.yml up chromadb -d; then
        print_status "ChromaDB container started"
        
        # Quick readiness check (but don't wait too long)
        print_step "Checking ChromaDB readiness..."
        sleep 10  # Give it a moment to start
        
        # Try direct connection test
        if docker exec chromadb bash -c "exec 3<>/dev/tcp/localhost/8000" 2>/dev/null; then
            print_status "ChromaDB is responding on port 8000"
        else
            print_warning "ChromaDB may still be starting up, continuing deployment..."
        fi
    else
        print_warning "ChromaDB failed to start, but continuing deployment..."
    fi
    
    # Start backend
    print_step "Starting backend..."
    if docker compose -f docker/compose/docker-compose.multi-container.yml up backend -d; then
        print_status "Backend container started"
        sleep 5  # Brief pause for initialization
    else
        print_warning "Backend failed to start, but continuing deployment..."
    fi
    
    # Start frontend
    print_step "Starting frontend..."
    if docker compose -f docker/compose/docker-compose.multi-container.yml up frontend -d; then
        print_status "Frontend container started"
        sleep 3  # Brief pause for initialization
    else
        print_warning "Frontend failed to start, but continuing deployment..."
    fi
    
    # Start nginx
    print_step "Starting nginx..."
    if docker compose -f docker/compose/docker-compose.multi-container.yml up nginx -d; then
        print_status "Nginx container started"
        sleep 3  # Brief pause for initialization
    else
        print_error "Nginx failed to start"
        print_info "Checking nginx logs..."
        docker compose -f docker/compose/docker-compose.multi-container.yml logs nginx || true
        
        # Try to fix common nginx issues and restart
        print_step "Attempting to fix nginx configuration..."
        setup_multi_container_nginx_config "$DOMAIN" "http"  # Regenerate HTTP-only config
        
        if docker compose -f docker/compose/docker-compose.multi-container.yml restart nginx; then
            print_status "Nginx restarted successfully after config fix"
        else
            print_warning "Nginx still failing, deployment may be incomplete"
        fi
    fi
    
    print_status "Multi-container services deployment completed"
    
    # Display service status (non-blocking)
    echo ""
    print_info "Final Service Status:"
    echo "=================================="
    docker compose -f docker/compose/docker-compose.multi-container.yml ps || true
    
    # Quick connectivity test (non-blocking)
    echo ""
    print_step "Running connectivity test..."
    sleep 5  # Give services a moment to fully initialize
    
    # Test basic connectivity without failing the deployment
    if curl -f "http://localhost/health" >/dev/null 2>&1; then
        print_status "Health check passed - services are responding!"
    else
        print_warning "Services may still be initializing. You can test manually with: curl http://$DOMAIN/health"
    fi
}

setup_ssl() {
    local domain="$1" email="$2"
    
    # Check if SSL certificate already exists
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        print_status "SSL certificate already exists for $domain"
        # Generate HTTPS configuration
        setup_multi_container_nginx_config "$domain" "https"
        export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
        docker compose -f docker/compose/docker-compose.multi-container.yml restart nginx
        return 0
    fi
    
    print_step "Setting up SSL certificates for $domain..."
    print_info "This process has two phases:"
    print_info "Phase 1: HTTP-only mode for certificate acquisition"
    print_info "Phase 2: Enable HTTPS after certificate is obtained"
    
    # Phase 1: Ensure HTTP-only configuration is active
    print_step "Phase 1: Configuring HTTP-only mode for SSL certificate acquisition..."
    setup_multi_container_nginx_config "$domain" "http"
    
    # Restart nginx with HTTP-only configuration
    export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
    print_info "Restarting nginx with HTTP-only configuration..."
    if ! docker compose -f docker/compose/docker-compose.multi-container.yml restart nginx; then
        print_error "Failed to restart nginx with HTTP-only configuration"
        return 1
    fi
    
    # Wait for nginx to stabilize
    sleep 10
    
    # Verify HTTP is working
    print_step "Verifying HTTP connectivity before SSL certificate acquisition..."
    local max_attempts=6
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_info "Attempt $attempt/$max_attempts: Testing HTTP connectivity..."
        
        if curl -f --connect-timeout 10 --max-time 30 "http://$domain/health" >/dev/null 2>&1; then
            print_status "HTTP connectivity verified - ready for SSL certificate acquisition"
            break
        elif curl -f --connect-timeout 10 --max-time 30 "http://$domain/.well-known/acme-challenge/" >/dev/null 2>&1; then
            print_status "ACME challenge path accessible - ready for SSL certificate acquisition"
            break
        else
            if [ $attempt -eq $max_attempts ]; then
                print_warning "HTTP connectivity test failed, but proceeding with SSL certificate acquisition..."
                print_info "Let's Encrypt will perform its own connectivity test"
                break
            else
                print_warning "HTTP test failed, retrying in 10 seconds..."
                sleep 10
                attempt=$((attempt + 1))
            fi
        fi
    done
    
    # Phase 2: Acquire SSL certificate
    print_step "Phase 2: Acquiring SSL certificate from Let's Encrypt..."
    print_info "Domain: $domain"
    print_info "Email: $email"
    print_info "Webroot path: /var/www/certbot"
    
    if certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$email" \
        --agree-tos \
        --no-eff-email \
        --non-interactive \
        --domains "$domain"; then
        
        print_status "✅ SSL certificate successfully acquired for $domain"
        
        # Phase 3: Enable HTTPS configuration
        print_step "Phase 3: Enabling HTTPS configuration..."
        setup_multi_container_nginx_config "$domain" "https"
        
        # Setup auto-renewal
        print_step "Setting up SSL certificate auto-renewal..."
        local cron_job="0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'cd $PROJECT_DIR && export \$(grep -v \"^#\" $DOCKER_ENV_FILE | grep -v \"^$\" | xargs) && docker compose -f docker/compose/docker-compose.multi-container.yml restart nginx'"
        
        # Add cron job if it doesn't exist
        if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
            (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
            print_status "SSL auto-renewal configured"
        else
            print_info "SSL auto-renewal already configured"
        fi
        
        # Restart nginx with HTTPS configuration
        print_info "Restarting nginx with HTTPS configuration..."
        export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
        if docker compose -f docker/compose/docker-compose.multi-container.yml restart nginx; then
            print_status "✅ HTTPS configuration successfully enabled"
            
            # Verify HTTPS is working
            sleep 5
            if curl -f --connect-timeout 10 --max-time 30 "https://$domain/health" >/dev/null 2>&1; then
                print_status "✅ HTTPS connectivity verified"
            else
                print_warning "HTTPS connectivity test failed, but configuration has been applied"
            fi
            
            return 0
        else
            print_error "Failed to restart nginx with HTTPS configuration"
            print_info "Reverting to HTTP-only configuration..."
            setup_multi_container_nginx_config "$domain" "http"
            docker compose -f docker/compose/docker-compose.multi-container.yml restart nginx
            return 1
        fi
    else
        print_error "❌ SSL certificate acquisition failed"
        print_warning "Continuing with HTTP-only configuration"
        print_info "Common causes:"
        print_info "  • Domain DNS not pointing to this server"
        print_info "  • Firewall blocking port 80"
        print_info "  • Rate limiting (5 certificates per week per domain)"
        print_info "  • Domain validation failed"
        
        # Ensure we're still in HTTP-only mode
        setup_multi_container_nginx_config "$domain" "http"
        export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
        docker compose -f docker/compose/docker-compose.multi-container.yml restart nginx
        
        return 1
    fi
}

# ===========================================
# MENU ACTIONS
# ===========================================

fresh_installation() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🚀 SUE CHATBOT FRESH INSTALLATION${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Step 0: Install SUE command early for convenience  
    print_step "Step 0/12: Installing SUE command globally..."
    install_script_globally
    
    # Step 1: System Detection and Update
    print_step "Step 1/12: Detecting and updating system..."
    update_system
    
    # Step 2: Install Git
    print_step "Step 2/12: Installing Git..."
    check_and_install_git
    
    # Step 3: Install dependencies
    print_step "Step 3/12: Installing system dependencies..."
    install_dependencies
    
    # Step 4: Install Docker
    print_step "Step 4/12: Installing Docker..."
    install_docker
    
    # Step 5: Install Certbot
    print_step "Step 5/12: Installing Certbot..."
    install_certbot
    
    # Step 6: Setup firewall
    print_step "Step 6/12: Configuring firewall..."
    setup_firewall
    
    # Step 7: GitHub Authentication (NEW)
    print_step "Step 7/12: GitHub Authentication..."
    if ! check_existing_github_auth; then
        github_authentication
        if [[ -z "$GITHUB_TOKEN" ]]; then
            print_error "GitHub authentication required for private repository"
            return 1
        fi
    else
        print_status "Using existing GitHub credentials"
    fi
    
    # Step 8: Clone project (MODIFIED)
    print_step "Step 8/12: Cloning project from private GitHub repository..."
    clone_project
    
    # Step 9: Setup directories
    print_step "Step 9/12: Setting up project directories..."
    setup_project_directories
    
    # Step 10: Prepare project structure
    print_step "Step 10/12: Finalizing project setup..."
    # SUE command already installed in Step 0
    
    echo ""
    echo -e "${YELLOW}🔧 Configuration Setup${NC}"
    echo ""
    
    # Step 11: Configure domain
    print_step "Step 11/12: Domain configuration..."
    configure_domain
    if [[ -z "$DOMAIN" ]]; then
        print_error "Domain required for installation"
        return 1
    fi
    
    # Get SSL email
    echo -e "${YELLOW}📧 SSL Configuration${NC}"
    while true; do
        read -p "Email for SSL certificates: " email
        if [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            break
        fi
        print_error "Invalid email format"
    done
    
    # Get admin credentials
    echo -e "${YELLOW}👤 Admin Configuration${NC}"
    read -p "Admin username (default: admin): " admin_username
    admin_username=${admin_username:-admin}
    
    while true; do
        read -s -p "Admin password: " admin_password
        echo ""
        if [ -n "$admin_password" ]; then break; fi
        print_error "Password cannot be empty"
    done
    
    # Get OpenAI API key
    echo -e "${YELLOW}🔑 OpenAI Configuration${NC}"
    while true; do
        read -p "OpenAI API key (sk-...): " openai_key
        if [[ $openai_key =~ ^sk- ]]; then break; fi
        print_error "Invalid API key format (must start with sk-)"
    done
    
    echo ""
    
    # Step 12: Create configuration
    print_step "Step 12/12: Creating environment configuration..."
    create_environment_config "$DOMAIN" "$email" "$admin_username" "$admin_password" "$openai_key"
    
    # Step 13: Deploy services
    print_step "Step 13/12: Deploying services..."
    deploy_services
    
    # Setup SSL (optional)
    echo ""
    if [[ "${SKIP_SSL:-false}" != "true" ]]; then
        print_step "Setting up SSL certificates..."
        if ! setup_ssl "$DOMAIN" "$email"; then
            print_warning "SSL setup failed, continuing with HTTP-only configuration"
        fi
    else
        print_info "Skipping SSL setup (SKIP_SSL=true)"
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ MULTI-CONTAINER INSTALLATION COMPLETED${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "🎉 SUE Chatbot has been successfully installed with multi-container architecture!"
    echo ""
    echo -e "${CYAN}🌐 Access Points:${NC}"
    echo "  • Main Site:  http://$DOMAIN"
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        echo "  • HTTPS:      https://$DOMAIN"
    fi
    echo "  • API Docs:   https://$DOMAIN/docs"
    echo ""
    echo -e "${CYAN}🔍 Health Checks:${NC}"
    echo "  • Backend:    https://$DOMAIN/health"
    echo "  • Frontend:   https://$DOMAIN/health/frontend"
    echo "  • ChromaDB:   https://$DOMAIN/health/chromadb"
    echo ""
    echo -e "${CYAN}👤 Admin Panel:${NC}"
    echo "  • URL:        https://$DOMAIN/admin"
    echo "  • Username:   $admin_username"
    echo "  • Password:   [hidden]"
    echo ""
    echo -e "${PURPLE}🐳 Container Architecture:${NC}"
    echo "  • Frontend:   chatbot-frontend (React, port 8080)"
    echo "  • Backend:    chatbot-backend (FastAPI, port 8000)"
    echo "  • Database:   chromadb (Vector DB, port 8001)"
    echo "  • Proxy:      nginx (SSL/Reverse Proxy, ports 80/443)"
    echo ""
    echo -e "${CYAN}🛠️  Management Commands:${NC}"
    echo "  • SUE Manager:    ${WHITE}sue${NC}"
    echo "  • View All Logs:  ${WHITE}cd $PROJECT_DIR && docker compose -f docker/compose/docker-compose.multi-container.yml logs${NC}"
    echo "  • Service Status: ${WHITE}cd $PROJECT_DIR && docker compose -f docker/compose/docker-compose.multi-container.yml ps${NC}"
    echo "  • Restart All:    ${WHITE}cd $PROJECT_DIR && docker compose -f docker/compose/docker-compose.multi-container.yml restart${NC}"
    echo "  • Update System:  ${WHITE}sue${NC} → Option 2"
    echo ""
    echo -e "${YELLOW}📁 Project Location: $PROJECT_DIR${NC}"
    echo -e "${YELLOW}📊 Direct ChromaDB Access: https://$DOMAIN/chromadb/${NC}"
    echo ""
}

update_deployment() {
    if [[ -z "$DOMAIN" ]] || [[ ! -d "$PROJECT_DIR" ]]; then
        print_error "No installation found"
        return 1
    fi
    
    print_step "Updating..."
    cd "$PROJECT_DIR"
    
    # Check GitHub authentication before git pull
    if ! check_existing_github_auth; then
        print_warning "GitHub authentication required for updates"
        github_authentication
        if [[ -z "$GITHUB_TOKEN" ]]; then
            print_error "Cannot update without GitHub authentication"
            return 1
        fi
        
        # Set up authenticated remote temporarily
        local current_remote=$(git remote get-url origin)
        if [[ -n "$GITHUB_USERNAME" ]]; then
            git remote set-url origin "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/arnozeng98/shebang-chatbot.git"
        else
            git remote set-url origin "https://${GITHUB_TOKEN}@github.com/arnozeng98/shebang-chatbot.git"
        fi
        
        git pull origin main
        
        # Restore original remote URL
        git remote set-url origin "$current_remote"
    else
        # Set up authenticated remote temporarily
        if [[ -n "$GITHUB_USERNAME" ]]; then
            git remote set-url origin "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/arnozeng98/shebang-chatbot.git"
        else
            git remote set-url origin "https://${GITHUB_TOKEN}@github.com/arnozeng98/shebang-chatbot.git"
        fi
        
        git pull origin main
        
        # Restore original remote URL
        git remote set-url origin "$GITHUB_REPO"
    fi
    
    export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
    # Stop both possible deployment types
    docker compose -f docker/compose/docker-compose.production.yml down 2>/dev/null || true
    docker compose -f docker/compose/docker-compose.multi-container.yml down 2>/dev/null || true
    # Start multi-container deployment
    docker compose -f docker/compose/docker-compose.multi-container.yml up -d --build
    
    print_status "Updated to latest version!"
}

repair_deployment() {
    if [[ -z "$DOMAIN" ]] || [[ ! -d "$PROJECT_DIR" ]]; then
        print_error "No installation found"
        return 1
    fi
    
    print_step "Repairing..."
    cd "$PROJECT_DIR"
    
    systemctl start docker || true
    export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
    # Stop both possible deployment types
    docker compose -f docker/compose/docker-compose.production.yml down 2>/dev/null || true
    docker compose -f docker/compose/docker-compose.multi-container.yml down 2>/dev/null || true
    # Start multi-container deployment
    docker compose -f docker/compose/docker-compose.multi-container.yml up -d --build
    
    print_status "Repaired with multi-container architecture!"
}

uninstall_deployment() {
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}WARNING: COMPLETE REMOVAL OPERATION${NC}"
    echo -e "${RED}========================================${NC}"
    echo "This will PERMANENTLY remove:"
    echo "  • All Docker containers and images"
    echo "  • Project directory: $PROJECT_BASE_DIR"
    echo "  • SSL certificates for domain: ${DOMAIN:-'all domains'}"
    echo "  • SUE command (/usr/local/bin/sue)"
    echo "  • All configuration files and data"
    echo "  • All environment variables and caches"
    echo "  • All temporary files"
    echo ""
    echo -e "${YELLOW}This action is IRREVERSIBLE!${NC}"
    echo ""
    
    read -p "Type 'REMOVE EVERYTHING' to confirm complete removal: " confirm
    
    if [[ "$confirm" != "REMOVE EVERYTHING" ]]; then
        print_info "Uninstall cancelled"
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}🗑️  Starting complete system cleanup...${NC}"
    echo ""
    
    # Step 1: Stop and remove Docker containers
    print_step "Step 1/8: Stopping and removing Docker containers..."
    if [[ -d "$PROJECT_DIR" ]]; then
        cd "$PROJECT_DIR" 2>/dev/null || true
        docker compose -f docker/compose/docker-compose.production.yml down --volumes --remove-orphans --timeout 30 2>/dev/null || true
        docker compose -f docker/compose/docker-compose.multi-container.yml down --volumes --remove-orphans --timeout 30 2>/dev/null || true
        docker compose -f docker/compose/docker-compose.yml down --volumes --remove-orphans --timeout 30 2>/dev/null || true
    fi
    
    # Remove any containers with our naming pattern
    docker ps -a --format "table {{.Names}}" | grep -E "(chatbot|nginx|sue)" | xargs docker rm -f 2>/dev/null || true
    print_status "Docker containers removed"
    
    # Step 2: Remove Docker images
    print_step "Step 2/8: Removing Docker images..."
    # Remove images by name pattern
    docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep -E "(compose|chatbot|nginx|sue)" | while read image_info; do
        image_id=$(echo "$image_info" | awk '{print $2}')
        image_name=$(echo "$image_info" | awk '{print $1}')
        print_info "  Removing image: $image_name"
        docker rmi -f "$image_id" 2>/dev/null || true
    done
    
    # Remove dangling images
    docker image prune -f >/dev/null 2>&1 || true
    print_status "Docker images removed"
    
    # Step 3: Clean Docker system
    print_step "Step 3/8: Cleaning Docker system..."
    docker system prune -a -f --volumes >/dev/null 2>&1 || true
    docker network prune -f >/dev/null 2>&1 || true
    print_status "Docker system cleaned"
    
    # Step 4: Remove SSL certificates
    print_step "Step 4/8: Removing SSL certificates..."
    if [[ -n "$DOMAIN" ]]; then
        rm -rf "/etc/letsencrypt/live/$DOMAIN/" 2>/dev/null || true
        rm -rf "/etc/letsencrypt/archive/$DOMAIN/" 2>/dev/null || true
        rm -rf "/etc/letsencrypt/renewal/$DOMAIN.conf" 2>/dev/null || true
        print_info "  Removed certificates for: $DOMAIN"
    fi
    
    # Remove any other certificates that might exist
    find /etc/letsencrypt/live/ -name "*sue*" -type d -exec rm -rf {} + 2>/dev/null || true
    find /etc/letsencrypt/archive/ -name "*sue*" -type d -exec rm -rf {} + 2>/dev/null || true
    find /etc/letsencrypt/renewal/ -name "*sue*" -type f -delete 2>/dev/null || true
    
    # Remove from certbot if it exists
    if command_exists certbot && [[ -n "$DOMAIN" ]]; then
        certbot delete --cert-name "$DOMAIN" --non-interactive 2>/dev/null || true
    fi
    print_status "SSL certificates removed"
    
    # Step 5: Remove project directories
    print_step "Step 5/8: Removing project directories..."
    if [[ -d "$PROJECT_BASE_DIR" ]]; then
        print_info "  Removing: $PROJECT_BASE_DIR"
        cd / 2>/dev/null || true
        rm -rf "$PROJECT_BASE_DIR"
        print_status "Project directory removed"
    else
        print_info "  No project directory found"
    fi
    
    # Step 6: Clean up GitHub authentication
    print_step "Step 6/8: Cleaning GitHub authentication..."
    rm -f "$PROJECT_BASE_DIR/.github_auth" 2>/dev/null || true
    print_status "GitHub authentication cleaned"
    
    # Step 7: Clean up configuration and temporary files
    print_step "Step 7/8: Cleaning configuration and temporary files..."
    
    # Remove certbot challenges
    rm -rf /var/www/certbot/* 2>/dev/null || true
    
    # Remove nginx configurations that might reference our domain
    if [[ -n "$DOMAIN" ]]; then
        find /etc/nginx/sites-enabled/ -name "*$DOMAIN*" -delete 2>/dev/null || true
        find /etc/nginx/sites-available/ -name "*$DOMAIN*" -delete 2>/dev/null || true
        find /etc/nginx/conf.d/ -name "*$DOMAIN*" -delete 2>/dev/null || true
    fi
    
    # Remove any sue-related nginx configs
    find /etc/nginx/ -name "*sue*" -type f -delete 2>/dev/null || true
    
    # Clean systemd services
    systemctl stop sue-* 2>/dev/null || true
    systemctl disable sue-* 2>/dev/null || true
    find /etc/systemd/system/ -name "*sue*" -delete 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
    
    print_status "Configuration files cleaned"
    
    # Step 8: Remove environment variables and cron jobs
    print_step "Step 8/8: Cleaning environment variables and cron jobs..."
    
    # Remove cron jobs containing our domain or sue
    if [[ -n "$DOMAIN" ]]; then
        (crontab -l 2>/dev/null | grep -v "$DOMAIN" | crontab -) 2>/dev/null || true
    fi
    (crontab -l 2>/dev/null | grep -v "sue" | crontab -) 2>/dev/null || true
    
    # Clean environment variables from common locations
    sed -i '/# SUE Chatbot/d' ~/.bashrc 2>/dev/null || true
    sed -i '/SUE_/d' ~/.bashrc 2>/dev/null || true
    sed -i '/export.*sue/Id' ~/.bashrc 2>/dev/null || true
    
    # Clean from /etc/environment
    if [[ -f /etc/environment ]]; then
        sed -i '/SUE_/d' /etc/environment 2>/dev/null || true
    fi
    
    print_status "Environment variables and cron jobs cleaned"
    
    # Step 9: Remove SUE command and self-destruct
    print_step "Step 9/8: Removing SUE command..."
    
    # Remove global sue command
    rm -f "$SCRIPT_INSTALL_PATH" 2>/dev/null || true
    rm -f /usr/bin/sue 2>/dev/null || true
    rm -f /bin/sue 2>/dev/null || true
    
    # Clean PATH references
    sed -i 's|:/usr/local/bin/sue||g' ~/.bashrc 2>/dev/null || true
    sed -i '/export PATH.*sue/d' ~/.bashrc 2>/dev/null || true
    
    print_status "SUE command removed"
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ COMPLETE REMOVAL FINISHED${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "All SUE Chatbot components have been permanently removed:"
    echo "  ✓ Docker containers and images"
    echo "  ✓ SSL certificates"
    echo "  ✓ Project directories and files"
    echo "  ✓ GitHub authentication files"
    echo "  ✓ Configuration files"
    echo "  ✓ Environment variables"
    echo "  ✓ Cron jobs"
    echo "  ✓ SUE command"
    echo ""
    echo -e "${CYAN}The system has been restored to its original state.${NC}"
    echo -e "${YELLOW}You may need to restart your shell for PATH changes to take effect.${NC}"
    echo ""
    
    # Self-destruct - remove this script if it's not in the standard location
    if [[ "$0" != "$SCRIPT_INSTALL_PATH" ]] && [[ "$0" == *"deploy-manager.sh" ]]; then
        print_info "Self-destructing deployment script..."
        rm -f "$0" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}Goodbye! 👋${NC}"
    exit 0
}

change_admin_credentials() {
    if [[ ! -f "$DOCKER_ENV_FILE" ]]; then
        print_error "No configuration found"
        return 1
    fi
    
    echo -e "${YELLOW}👤 New Admin Credentials${NC}"
    read -p "New username: " new_username
    read -s -p "New password: " new_password
    echo ""
    
    local new_hash=$(echo -n "$new_password" | sha256sum | cut -d' ' -f1)
    
    sed -i "s/^ADMIN_USERNAME=.*/ADMIN_USERNAME=$new_username/" "$DOCKER_ENV_FILE"
    sed -i "s/^ADMIN_PASSWORD=.*/ADMIN_PASSWORD=$new_password/" "$DOCKER_ENV_FILE"
    sed -i "s/^ADMIN_PASSWORD_HASH=.*/ADMIN_PASSWORD_HASH=$new_hash/" "$DOCKER_ENV_FILE"
    
    if [[ -f "$BACKEND_ENV_FILE" ]]; then
        sed -i "s/^ADMIN_USERNAME=.*/ADMIN_USERNAME=$new_username/" "$BACKEND_ENV_FILE"
        sed -i "s/^ADMIN_PASSWORD=.*/ADMIN_PASSWORD=$new_password/" "$BACKEND_ENV_FILE"
        sed -i "s/^ADMIN_PASSWORD_HASH=.*/ADMIN_PASSWORD_HASH=$new_hash/" "$BACKEND_ENV_FILE"
    fi
    
    if [[ -d "$PROJECT_DIR" ]]; then
        cd "$PROJECT_DIR"
        export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
        docker compose -f docker/compose/docker-compose.multi-container.yml restart
    fi
    
    print_status "Admin credentials updated!"
}

change_api_key() {
    if [[ ! -f "$DOCKER_ENV_FILE" ]]; then
        print_error "No configuration found"
        return 1
    fi
    
    echo -e "${YELLOW}🔑 New API Key${NC}"
    while true; do
        read -p "New OpenAI API key (sk-...): " new_key
        if [[ $new_key =~ ^sk- ]]; then break; fi
        print_error "Invalid format"
    done
    
    sed -i "s/^OPENAI_API_KEY=.*/OPENAI_API_KEY=$new_key/" "$DOCKER_ENV_FILE"
    
    if [[ -f "$BACKEND_ENV_FILE" ]]; then
        sed -i "s/^OPENAI_API_KEY=.*/OPENAI_API_KEY=$new_key/" "$BACKEND_ENV_FILE"
    fi
    
    if [[ -d "$PROJECT_DIR" ]]; then
        cd "$PROJECT_DIR"
        export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
        docker compose -f docker/compose/docker-compose.multi-container.yml restart
    fi
    
    print_status "API key updated!"
}

advanced_configuration() {
    if [[ ! -f "$DOCKER_ENV_FILE" ]]; then
        print_error "No configuration found"
        return 1
    fi
    
    echo -e "${WHITE}Advanced Options:${NC}"
    echo "1. Change Chat Model"
    echo "2. Change Embedding Model" 
    echo "3. Change Chunk Size"
    echo "4. Edit Config File"
    echo "0. Back"
    
    read -p "Choice: " choice
    
    case $choice in
        1)
            read -p "Chat model (default: gpt-4o): " model
            model=${model:-gpt-4o}
            sed -i "s/^CHAT_MODEL=.*/CHAT_MODEL=$model/" "$DOCKER_ENV_FILE"
            print_status "Chat model: $model"
            ;;
        2)
            read -p "Embedding model (default: text-embedding-ada-002): " model
            model=${model:-text-embedding-ada-002}
            sed -i "s/^EMBEDDING_MODEL=.*/EMBEDDING_MODEL=$model/" "$DOCKER_ENV_FILE"
            print_status "Embedding model: $model"
            ;;
        3)
            read -p "Chunk size (default: 512): " size
            size=${size:-512}
            sed -i "s/^CHUNK_SIZE=.*/CHUNK_SIZE=$size/" "$DOCKER_ENV_FILE"
            print_status "Chunk size: $size"
            ;;
        4)
            if command_exists nano; then
                nano "$DOCKER_ENV_FILE"
            elif command_exists vi; then
                vi "$DOCKER_ENV_FILE"
            else
                print_error "No editor available"
            fi
            ;;
    esac
    
    if [[ $choice != "0" ]] && [[ -d "$PROJECT_DIR" ]]; then
        read -p "Restart services? (y/n): " restart
        if [[ $restart =~ ^[Yy]$ ]]; then
            cd "$PROJECT_DIR"
            export $(grep -v "^#" "$DOCKER_ENV_FILE" | grep -v "^$" | xargs)
            docker compose -f docker/compose/docker-compose.multi-container.yml restart
        fi
    fi
}

show_system_status() {
    echo -e "${WHITE}=== System Status ===${NC}"
    echo "OS: $DETECTED_OS ($PKG_MANAGER)"
    echo "Domain: ${DOMAIN:-Not set}"
    echo ""
    
    if command_exists docker && systemctl is-active --quiet docker; then
        echo -e "Docker: ${GREEN}✓ Running${NC}"
        if [[ -d "$PROJECT_DIR" ]]; then
            cd "$PROJECT_DIR"
            echo ""
            echo -e "${WHITE}=== Containers ===${NC}"
            docker compose -f docker/compose/docker-compose.multi-container.yml ps 2>/dev/null || echo "Multi-container deployment not found"
        fi
    else
        echo -e "Docker: ${RED}✗ Not running${NC}"
    fi
    
    if [[ -n "$DOMAIN" ]]; then
        echo ""
        echo -e "${WHITE}=== Connectivity ===${NC}"
        if curl -s --max-time 5 "http://$DOMAIN" >/dev/null 2>&1; then
            echo -e "HTTP: ${GREEN}✓ Working${NC}"
        else
            echo -e "HTTP: ${RED}✗ Failed${NC}"
        fi
        
        if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
            echo -e "SSL: ${GREEN}✓ Installed${NC}"
        else
            echo -e "SSL: ${YELLOW}! Not installed${NC}"
        fi
    fi
}

# ===========================================
# MENU SYSTEM
# ===========================================

show_main_menu() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    print_banner
    
    echo -e "${WHITE}Configuration:${NC}"
    if [[ -n "$DOMAIN" ]]; then
        echo -e "  Domain: ${GREEN}$DOMAIN${NC}"
        if [[ -d "$PROJECT_DIR" ]]; then
            echo -e "  Status: ${GREEN}Installed${NC}"
        else
            echo -e "  Status: ${YELLOW}Not Installed${NC}"
        fi
    else
        echo -e "  Domain: ${RED}Not Configured${NC}"
    fi
    echo -e "  OS: ${CYAN}$DETECTED_OS${NC} ($PKG_MANAGER)"
    echo -e "  Project: ${YELLOW}$PROJECT_BASE_DIR${NC}"
    echo ""
    
    echo -e "${WHITE}Actions:${NC}"
    echo -e "  ${GREEN}1${NC} - 🚀 Fresh Installation (Complete Setup)"
    echo -e "  ${BLUE}2${NC} - 🔄 Update Deployment"
    echo -e "  ${YELLOW}3${NC} - 🔧 Repair/Fix"
    echo -e "  ${RED}4${NC} - 🗑️  Complete Uninstall"
    echo ""
    echo -e "${WHITE}Configuration:${NC}"
    echo -e "  ${CYAN}5${NC} - 🌐 Change Domain"
    echo -e "  ${CYAN}6${NC} - 👤 Change Admin Credentials"
    echo -e "  ${CYAN}7${NC} - 🔑 Change API Key"
    echo -e "  ${CYAN}8${NC} - ⚙️  Advanced Configuration"
    echo ""
    echo -e "  ${WHITE}9${NC} - 📊 System Status"
    echo -e "  ${WHITE}0${NC} - ❌ Exit"
    echo ""
}

# ===========================================
# MAIN EXECUTION
# ===========================================

if [[ $EUID -ne 0 ]]; then
   print_error "Must run as root: sudo $0"
   exit 1
fi

detect_os
load_config

while true; do
    show_main_menu
    read -p "Choice [0-9]: " choice
    
    case $choice in
        1) 
            fresh_installation
            echo ""
            echo -e "${CYAN}Installation completed. Press Enter to continue...${NC}"
            read -p ""
            ;;
        2) 
            update_deployment
            echo ""
            echo -e "${CYAN}Update completed. Press Enter to continue...${NC}"
            read -p ""
            ;;
        3) 
            repair_deployment
            echo ""
            echo -e "${CYAN}Repair completed. Press Enter to continue...${NC}"
            read -p ""
            ;;
        4) 
            uninstall_deployment
            # uninstall_deployment will exit automatically
            ;;
        5) 
            configure_domain
            echo ""
            echo -e "${CYAN}Domain configuration updated. Press Enter to continue...${NC}"
            read -p ""
            ;;
        6) 
            change_admin_credentials
            echo ""
            echo -e "${CYAN}Admin credentials updated. Press Enter to continue...${NC}"
            read -p ""
            ;;
        7) 
            change_api_key
            echo ""
            echo -e "${CYAN}API key updated. Press Enter to continue...${NC}"
            read -p ""
            ;;
        8) 
            advanced_configuration
            echo ""
            echo -e "${CYAN}Configuration updated. Press Enter to continue...${NC}"
            read -p ""
            ;;
        9) 
            show_system_status
            echo ""
            echo -e "${CYAN}Status check completed. Press Enter to continue...${NC}"
            read -p ""
            ;;
        0) 
            echo ""
            echo -e "${GREEN}Thank you for using SUE Chatbot Manager! 👋${NC}"
            echo ""
            exit 0 
            ;;
        *) 
            print_error "Invalid choice. Please select 0-9."
            sleep 2
            ;;
    esac
done 