# 教育AI Agent 前端界面

基于React构建的现代化聊天界面，支持与Claude Sonnet 4教育AI助手进行交互。

## ✨ 功能特性

- 🎨 **现代化UI设计** - 使用毛玻璃效果和渐变背景
- 💬 **实时对话** - 流畅的聊天体验，支持Markdown渲染
- 🔧 **工具集成** - 显示Python执行、物理仿真等工具结果
- 📊 **数学公式** - 支持KaTeX数学公式渲染
- 🎬 **动画效果** - 使用Framer Motion实现丰富的动画
- 📱 **响应式设计** - 适配不同屏幕尺寸
- 🌙 **自适应主题** - 支持系统主题切换

## 🛠️ 技术栈

- **框架**: React 18
- **状态管理**: Context API + useReducer
- **样式**: Styled Components
- **动画**: Framer Motion
- **图标**: React Icons
- **数学渲染**: React KaTeX
- **代码高亮**: React Syntax Highlighter
- **Markdown**: React Markdown
- **HTTP客户端**: Axios

## 📦 安装和运行

### 前置要求

- Node.js 16+ 
- npm 或 yarn

### 安装依赖

```bash
cd edu-agent/frontend
npm install
```

### 启动开发服务器

```bash
npm start
```

应用将在 http://localhost:3000 启动

### 构建生产版本

```bash
npm run build
```

## 🎯 使用说明

### 基本使用

1. 启动后端服务（确保在 http://localhost:8000 运行）
2. 启动前端开发服务器
3. 在聊天框中输入问题
4. AI将根据问题调用相应工具并返回答案

### 支持的功能

- **物理学习**: 询问物理概念、定律、公式等
- **数学学习**: 解方程、函数图像、几何问题等  
- **代码执行**: Python代码编写和执行
- **可视化**: 数学图表、物理仿真动画
- **知识搜索**: 在OpenStax教材中查找相关内容

### 示例问题

```
- 解释牛顿第二定律并演示
- 画出正弦函数的图像
- 模拟抛物运动
- 解二次方程 x²-5x+6=0
- 什么是量子隧穿效应？
- 用Python计算圆的面积
```

## 📁 项目结构

```
src/
├── components/          # 组件目录
│   ├── chat/           # 聊天相关组件
│   │   ├── ChatInterface.jsx    # 主聊天界面
│   │   ├── MessageBubble.jsx    # 消息气泡
│   │   └── TypingIndicator.jsx  # 输入指示器
│   └── common/         # 通用组件
│       ├── Header.jsx           # 头部组件
│       └── Sidebar.jsx          # 侧边栏组件
├── hooks/              # 自定义Hook
│   └── useChat.jsx     # 聊天状态管理
├── styles/             # 样式文件
│   └── App.css         # 全局样式
├── App.jsx             # 主应用组件
└── index.js            # 应用入口
```

## 🔧 环境配置

前端通过 `package.json` 中的 `proxy` 配置连接后端：

```json
{
  "proxy": "http://localhost:8000"
}
```

如需修改后端地址，请更新此配置。

## 🎨 主题和样式

应用使用CSS变量定义主题色彩：

```css
:root {
  --primary-color: #667eea;
  --secondary-color: #764ba2;
  --accent-color: #4f46e5;
  /* ... 更多变量 */
}
```

## 📱 响应式设计

- **桌面端**: 完整的侧边栏和工具面板
- **平板端**: 可折叠的侧边栏
- **移动端**: 底部导航栏（待实现）

## 🚀 部署

### 使用Docker

```bash
# 构建镜像
docker build -t edu-agent-frontend .

# 运行容器
docker run -p 3000:3000 edu-agent-frontend
```

### 使用Nginx

```bash
# 构建静态文件
npm run build

# 将build文件夹内容部署到Nginx
cp -r build/* /var/www/html/
```

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

MIT License - 详见 [LICENSE](../LICENSE) 文件

## ❓ 常见问题

### Q: 前端无法连接后端怎么办？
A: 检查后端是否在 http://localhost:8000 运行，并确保CORS配置正确。

### Q: 数学公式不显示怎么办？
A: 确保KaTeX CSS已正确加载，检查网络连接。

### Q: 动画效果卡顿怎么办？
A: 可能是设备性能问题，可以在设置中关闭动画效果。

## 📞 技术支持

如有问题请提交Issue或联系开发团队。 