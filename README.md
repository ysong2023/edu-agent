# 教育AI代理系统 (Education AI Agent)

一个基于Claude AI的智能教育系统，专注于数学和物理学习，提供交互式问答、可视化和代码执行功能。

## 🚀 功能特点

- **智能问答**：基于Claude AI的自然语言理解和回答
- **可视化支持**：数学公式渲染、图形绘制、物理模拟
- **代码执行**：安全的Python代码执行环境
- **知识检索**：智能知识库搜索和上下文提供
- **现代化UI**：响应式Web界面，优秀的用户体验

## 🏗️ 技术架构

### 后端
- **FastAPI**: 高性能Web框架
- **Anthropic Claude**: AI模型API
- **Redis**: 缓存和会话管理
- **Python**: 科学计算生态系统

### 前端
- **React**: 现代化前端框架
- **Nginx**: 静态文件服务和反向代理

### 基础设施
- **Docker**: 容器化部署
- **GitHub Actions**: CI/CD流水线
- **Docker Compose**: 多容器编排

## 📦 快速开始

### 方式一：一键部署（推荐）

1. **克隆仓库**
   ```bash
   git clone https://github.com/ysong2023/edu-agent.git
   cd edu-agent
   ```

2. **设置环境变量**
   ```bash
   cp env.example .env
   # 编辑 .env 文件，设置你的 ANTHROPIC_API_KEY
   ```

3. **一键部署**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. **访问应用**
   - 前端界面: http://localhost:3000
   - 后端API: http://localhost:8000
   - API文档: http://localhost:8000/docs

### 方式二：手动部署

#### 开发环境

1. **后端开发**
   ```bash
   cd backend
   pip install -r requirements.txt
   uvicorn app.main:app --reload
   ```

2. **前端开发**
   ```bash
   cd frontend
   npm install
   npm start
   ```

#### 生产环境

1. **使用Docker Compose**
   ```bash
   docker-compose up -d
   ```

2. **使用预构建镜像**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

## 🔧 配置说明

### 环境变量

创建 `.env` 文件并配置以下变量：

```env
# Claude API配置
ANTHROPIC_API_KEY=your_claude_api_key_here
CLAUDE_MODEL=claude-3-5-sonnet-20241022

# 应用配置
APP_NAME=Math & Physics Education AI
DEBUG=false

# 服务器配置
HOST=0.0.0.0
PORT=8000

# CORS配置
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

### Docker配置

- `docker-compose.yml`: 开发环境配置
- `docker-compose.prod.yml`: 生产环境配置

## 🛠️ 开发指南

### 项目结构

```
edu-agent/
├── backend/                 # 后端服务
│   ├── app/
│   │   ├── api/            # API路由
│   │   ├── core/           # 核心配置
│   │   ├── knowledge/      # 知识管理
│   │   ├── services/       # 业务逻辑
│   │   └── tools/          # 工具集成
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/               # 前端应用
│   ├── src/
│   │   ├── components/     # React组件
│   │   ├── hooks/          # 自定义Hook
│   │   └── styles/         # 样式文件
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
├── .github/workflows/      # GitHub Actions
├── docker-compose.yml      # Docker编排
└── deploy.sh              # 一键部署脚本
```

### 添加新功能

1. **后端API**: 在 `backend/app/api/` 中添加新的路由
2. **前端组件**: 在 `frontend/src/components/` 中添加新的React组件
3. **工具集成**: 在 `backend/app/tools/` 中添加新的工具

## 🚀 部署到生产环境

### GitHub Actions自动部署

1. **设置GitHub Secrets**
   ```
   ANTHROPIC_API_KEY: 你的Claude API密钥
   ```

2. **推送代码触发部署**
   ```bash
   git push origin main
   ```

### 手动部署到服务器

1. **在服务器上克隆仓库**
   ```bash
   git clone https://github.com/ysong2023/edu-agent.git
   cd edu-agent
   ```

2. **设置环境变量**
   ```bash
   cp env.example .env
   # 编辑 .env 文件
   ```

3. **使用生产配置部署**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

## 📊 监控和日志

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend
```

### 服务状态
```bash
# 查看服务状态
docker-compose ps

# 查看服务健康状态
docker-compose exec backend curl http://localhost:8000/health
```

## 🔒 安全考虑

- API密钥通过环境变量管理，不提交到代码库
- 代码执行在隔离的容器环境中
- 使用HTTPS和安全的CORS配置
- 定期更新依赖包以修复安全漏洞

## 🤝 贡献指南

1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 📄 许可证

本项目基于MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持

如果您遇到问题或有建议，请：

1. 查看 [Issues](https://github.com/ysong2023/edu-agent/issues)
2. 创建新的Issue
3. 联系维护者

---

**愉快的学习！🎓** 