# Education AI Agent

[![CI/CD Pipeline](https://github.com/ysong2023/edu-agent/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/ysong2023/edu-agent/actions/workflows/ci-cd.yml)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![React](https://img.shields.io/badge/react-%2320232a.svg?style=flat&logo=react&logoColor=%2361DAFB)](https://reactjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=flat&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Claude AI](https://img.shields.io/badge/Claude%20AI-FF6B35?style=flat&logo=anthropic&logoColor=white)](https://www.anthropic.com/)

An intelligent education system powered by Claude AI, specializing in mathematics and physics learning with interactive Q&A, advanced visualizations, and secure code execution capabilities.

## 🌟 Features

### Core Capabilities
- **🤖 AI-Powered Learning**: Advanced natural language understanding using Claude 3.5 Sonnet
- **📊 Dynamic Visualizations**: Real-time mathematical plotting and physics simulations
- **🔬 Interactive Code Execution**: Secure Python environment with scientific computing libraries
- **📐 LaTeX Math Rendering**: Professional mathematical formula display with KaTeX
- **💾 Persistent Conversations**: Local storage with conversation history management
- **🎨 Modern UI/UX**: Responsive design with Markdown support and syntax highlighting

### Educational Tools
- **Mathematical Modeling**: Calculus, algebra, statistics, and advanced mathematics
- **Physics Simulations**: Mechanics, thermodynamics, electromagnetism, and quantum physics
- **Data Visualization**: Interactive plots, animations, and scientific diagrams
- **Historical Context**: Rich educational background and discovery stories

## 🏗️ Architecture

### System Overview
```
┌──────────────────┐    ┌──────────────────┐    ┌───────────────────┐
│   React Frontend │    │  FastAPI Backend │    │   Claude AI API   │
│                  │◄──►│                  │◄──►│                   │
│  • UI Components │    │  • REST API      │    │  • AI Processing  │
│  • State Mgmt    │    │  • Tool Manager  │    │  • NLP & Reasoning│
│  • Markdown      │    │  • Code Executor │    │  • Content Gen    │
└──────────────────┘    └──────────────────┘    └───────────────────┘
         │                       │                       
         │              ┌─────────────────┐              
         └─────────────►│   Redis Cache   │              
                        │                 │              
                        │  • Sessions     │              
                        │  • Tool Results │              
                        └─────────────────┘              
```

### Technology Stack

**Backend Services**
- **FastAPI**: High-performance async web framework
- **Anthropic Claude**: State-of-the-art AI model (Claude 3.5 Sonnet)
- **Redis**: In-memory caching and session management
- **Python Ecosystem**: NumPy, Matplotlib, SciPy, SymPy for scientific computing

**Frontend Application**
- **React 18**: Modern frontend framework with hooks
- **React Markdown**: Full Markdown rendering with LaTeX support
- **KaTeX**: Mathematical formula rendering
- **React Syntax Highlighter**: Code syntax highlighting

**Infrastructure & DevOps**
- **Docker**: Containerized deployment with multi-stage builds
- **GitHub Actions**: Automated CI/CD pipeline with container registry
- **Nginx**: High-performance reverse proxy and static file serving
- **Docker Compose**: Multi-container orchestration

## 📁 Project Structure

```
edu-agent/
├── backend/                    # FastAPI Backend Service
│   ├── app/
│   │   ├── api/v1/            # REST API endpoints
│   │   ├── core/              # Claude AI integration & config
│   │   ├── services/          # Business logic
│   │   └── tools/             # AI tools & code execution
│   ├── tests/                 # Test suite
│   └── requirements.txt
├── frontend/                  # React Frontend
│   ├── src/
│   │   ├── App.jsx           # Main component
│   │   └── styles/           # CSS styles
│   └── package.json
├── docker/                    # Docker configuration
│   ├── backend/Dockerfile
│   ├── frontend/Dockerfile
│   ├── docker-compose.yml    # Development
│   └── docker-compose.prod.yml # Production
├── .github/workflows/         # CI/CD pipeline
├── deploy.sh                  # Production deployment
└── .env.example               # Environment template
```

## 🚀 Quick Start

### Prerequisites
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Anthropic API Key**: Required for Claude AI integration

### Production Deployment (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/ysong2023/edu-agent.git
   cd edu-agent
   ```

2. **Run the deployment script**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```
   
   The script will interactively prompt for:
   - Anthropic API Key (required)
   - Claude Model selection (optional)
   - Debug mode settings (optional)

3. **Access the application**
   - **Frontend**: http://localhost
   - **Backend API**: http://localhost:8000
   - **API Documentation**: http://localhost:8000/docs

### Development Environment

1. **Start development services**
   ```bash
   docker-compose -f docker/docker-compose.yml up -d
   ```

2. **Access development endpoints**
   - **Frontend**: http://localhost:3000
   - **Backend**: http://localhost:8000

### Manual Installation

<details>
<summary>Click to expand manual installation instructions</summary>

#### Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set environment variables
export ANTHROPIC_API_KEY="your_api_key_here"

# Start the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### Frontend Setup
```bash
cd frontend
npm install
npm start
```

</details>

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# Required: Anthropic API Configuration
ANTHROPIC_API_KEY=your_claude_api_key_here
CLAUDE_MODEL=claude-3-5-sonnet-20241022

# Application Settings
APP_NAME=Math & Physics Education AI
DEBUG=false
HOST=0.0.0.0
PORT=8000

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# CORS Settings
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Cache Settings
KNOWLEDGE_CACHE_DIR=/app/data/knowledge_cache
```

### Docker Configuration

- **`docker/docker-compose.yml`**: Development environment with hot reloading
- **`docker/docker-compose.prod.yml`**: Production environment with optimized images

## 🔧 Development

### Adding New Features

#### Backend API Endpoints
1. Create new route in `backend/app/api/v1/`
2. Implement business logic in `backend/app/services/`
3. Add tests in `backend/tests/`

#### Frontend Components
1. Create component in `frontend/src/components/`
2. Add styles in `frontend/src/styles/`
3. Update main App.jsx if needed

#### AI Tools
1. Define tool schema in `backend/app/tools/schema/`
2. Implement tool logic in `backend/app/tools/`
3. Register tool in `backend/app/tools/manager.py`

### Code Quality

```bash
# Backend linting and formatting
cd backend
black app/
flake8 app/

# Frontend linting
cd frontend
npm run lint
npm run format

# Run tests
npm test
```

## 🚀 Deployment

### GitHub Actions CI/CD

The project includes automated CI/CD pipeline:

1. **Continuous Integration**
   - Automated testing for backend and frontend
   - Code quality checks
   - Security vulnerability scanning

2. **Continuous Deployment**
   - Docker image building and pushing to GitHub Container Registry
   - Automated deployment to production environment

#### Setting up CI/CD

1. **Configure GitHub Secrets**
   ```
   ANTHROPIC_API_KEY: Your Claude API key
   ```

2. **Trigger deployment**
   ```bash
   git push origin main
   ```

### Manual Production Deployment

#### On Google Cloud Platform

1. **Create VM instance**
   ```bash
   # Install Docker and Docker Compose
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   sudo usermod -aG docker $USER
   
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **Deploy application**
   ```bash
   git clone https://github.com/ysong2023/edu-agent.git
   cd edu-agent
   ./deploy.sh
   ```

#### On AWS/Azure/Other Cloud Providers

Similar process - ensure Docker and Docker Compose are installed, then run the deployment script.

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Check service status
docker-compose -f docker/docker-compose.prod.yml ps

# View logs
docker-compose -f docker/docker-compose.prod.yml logs -f

# Check API health
curl http://localhost:8000/health
```

### Performance Monitoring
- Backend response times via FastAPI metrics
- Frontend performance via React DevTools
- Container resource usage via Docker stats

### Backup & Recovery
- Redis data persistence via Docker volumes
- Application logs rotation and archival
- Environment configuration backup

## 🔒 Security

### Security Measures
- **API Key Management**: Environment-based configuration, never committed to code
- **Code Execution Isolation**: Sandboxed Python execution environment
- **CORS Protection**: Configurable allowed origins
- **Input Validation**: Comprehensive request validation using Pydantic
- **Container Security**: Non-root user execution, minimal base images

### Security Best Practices
- Regular dependency updates
- Security vulnerability scanning in CI/CD
- HTTPS enforcement in production
- Rate limiting on API endpoints

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support & Contact

### Maintainers
- **Primary Maintainer**: [@ysong2023](https://github.com/ysong2023)

---

<div align="center">

**Happy Learning! 🎓✨**

*Empowering education through AI-driven interactive learning experiences*

</div> 