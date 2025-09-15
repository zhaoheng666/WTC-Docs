# VitePress 技术文档

本文档介绍 WorldTourCasino 文档中心的技术架构、配置方法、构建部署等技术细节。

## 📚 关于 VitePress

VitePress 是一个静态站点生成器，专为构建快速、以内容为中心的网站而设计。它具有以下特点：

- **性能优越**：基于 Vite 构建，启动速度极快
- **Markdown 增强**：支持各种 Markdown 扩展功能
- **Vue 驱动**：可在 Markdown 中使用 Vue 组件
- **主题定制**：灵活的主题系统
- **搜索功能**：内置全文搜索

## 🛠️ 环境要求

- Node.js 18.0+ (推荐 20.x)
- npm 7.0+ 或 pnpm 8.0+
- Git 2.0+

## 🚀 本地开发

### 快速启动

```bash
# 1. 克隆文档仓库（如果尚未克隆）
git clone git@github.com:zhaoheng666/WTC-Docs.git docs

# 2. 进入文档目录
cd docs

# 3. 安装依赖
npm install

# 4. 启动开发服务器
npm run dev
```

### VS Code 集成

项目配置了 VS Code 任务，可通过以下方式快速启动：

1. 按 `Cmd+Shift+P` (Mac) 或 `Ctrl+Shift+P` (Windows)
2. 选择 `Tasks: Run Task`
3. 选择相应任务：

| 任务名称 | 功能 | 说明 |
| --- | --- | --- |
| `setup_docs_environment` | 初始化环境 | 首次运行，自动设置所有环境 |
| `start_local_docs_server` | 启动服务器 | 后台运行文档服务器 |
| `open_local_docs` | 打开浏览器 | 在浏览器中查看文档 |

### 开发命令

```bash
# 启动开发服务器（默认端口 5173）
npm run dev

# 指定端口
npm run dev -- --port 3000

# 开放网络访问
npm run dev -- --host 0.0.0.0

# 构建静态文件
npm run build

# 预览构建结果
npm run preview
```

## 📁 项目结构

```
docs/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions 部署配置
├── .vitepress/
│   ├── config.mjs             # VitePress 主配置
│   ├── sidebar.mjs            # 侧边栏自动生成逻辑
│   ├── cache/                 # 构建缓存（自动生成）
│   └── dist/                  # 构建输出（自动生成）
├── public/                     # 静态资源目录
├── 关卡/                       # 关卡文档
├── 活动/                       # 活动文档
├── 协议/                       # 协议文档
├── 工具/                       # 工具文档
├── 其他/                       # 其他文档
├── index.md                    # 文档首页
├── README.md                   # 技术文档（本文件）
├── package.json               # 项目配置
└── package-lock.json          # 依赖锁定
```

## ⚙️ 配置说明

### 主配置文件

**文件**：`.vitepress/config.mjs`

```javascript
export default defineConfig({
  // 站点配置
  title: "WorldTourCasino",
  description: "WorldTourCasino 项目文档",
  base: '/WTC-Docs/',           // GitHub Pages 基础路径
  
  // 构建配置
  appearance: true,              // 启用深色模式切换
  ignoreDeadLinks: [            // 忽略死链接检查
    /^http:\/\/localhost/,
    /\/%E/
  ],
  
  // 主题配置
  themeConfig: {
    nav: [...],                 // 顶部导航
    sidebar: {...},             // 侧边栏
    search: {...},              // 搜索配置
    socialLinks: [...],         // 社交链接
    editLink: {...},            // 编辑链接
    lastUpdated: {...},         // 最后更新时间
    footer: {...}               // 页脚
  }
})
```

### 侧边栏配置

**文件**：`.vitepress/sidebar.mjs`

自动扫描目录生成侧边栏，支持以下配置：

```javascript
// 目录排序优先级
const directoryOrder = {
  '活动': 1,
  '关卡': 2,
  'Native': 3,
  '协议': 4,
  '工具': 5,
  '其他': 6
}

// 忽略列表（支持路径和模式匹配）
const ignoreList = [
  'README.md',           // 忽略所有 README 文件
  '.DS_Store',          // 忽略系统文件
  'draft-',             // 忽略草稿文件
  '/temp/',             // 忽略临时目录
]

// 特殊名称映射
const specialCases = {
  'index': '概览',
  'readme': '说明',
  'api': 'API',
  'faq': '常见问题'
}
```

## 🚀 GitHub Pages 部署

### 自动部署配置

项目配置了 GitHub Actions 自动部署：

1. **触发条件**：推送到 main 分支
2. **构建环境**：Ubuntu latest, Node.js 20.x
3. **部署目标**：GitHub Pages
4. **访问地址**：https://zhaoheng666.github.io/WTC-Docs/

### 部署流程

```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    # 构建 VitePress 站点
    - 安装依赖 (npm ci)
    - 构建站点 (npm run build)
    - 上传构建产物
    
  deploy:
    # 部署到 GitHub Pages
    - 使用 actions/deploy-pages
    - 自动发布到 gh-pages
```

### 部署耗时

- **Build 阶段**：约 18 秒
- **Deploy 阶段**：约 10 秒
- **总耗时**：约 40 秒

### 故障排查

#### 构建失败

1. **依赖问题**
   ```bash
   # 确保 package-lock.json 已提交
   git add package-lock.json
   git commit -m "fix: add package-lock.json"
   ```

2. **死链接错误**
   ```javascript
   // 在 config.mjs 中配置忽略规则
   ignoreDeadLinks: [
     /^http:\/\/localhost/,
     // 添加更多规则
   ]
   ```

3. **内存不足**
   ```javascript
   // 增加 Node.js 内存限制
   "scripts": {
     "build": "node --max-old-space-size=4096 node_modules/vitepress/bin/vitepress.js build"
   }
   ```

#### 部署失败

1. **权限问题**
   - Settings → Actions → General
   - Workflow permissions: Read and write

2. **Pages 配置**
   - Settings → Pages
   - Source: GitHub Actions
   - 确保仓库为 Public

## 📝 Markdown 增强功能

### 容器块

```markdown
::: tip 提示
有用的提示信息
:::

::: warning 警告
需要注意的内容
:::

::: danger 危险
重要的警告信息
:::

::: details 点击展开
隐藏的详细内容
:::
```

### 代码块增强

````markdown
```js{1,3-4}
// 行高亮示例
const msg = 'Hello'
console.log(msg) // [!code highlight]
const deprecated = true // [!code --]
const updated = true // [!code ++]
```
````

### 代码组

````markdown
::: code-group

```js [JavaScript]
console.log('Hello')
```

```py [Python]
print('Hello')
```

```java [Java]
System.out.println("Hello");
```

:::
````

### 自定义组件

可以在 Markdown 中使用 Vue 组件：

```markdown
<script setup>
import CustomComponent from './components/CustomComponent.vue'
</script>

<CustomComponent :prop="value" />
```

## 🔧 高级配置

### 自定义主题

```javascript
// .vitepress/theme/index.js
import DefaultTheme from 'vitepress/theme'
import MyComponent from './MyComponent.vue'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('MyComponent', MyComponent)
  }
}
```

### PWA 支持

```javascript
// config.mjs
export default {
  pwa: {
    manifest: {
      name: 'WorldTourCasino Docs',
      short_name: 'WTC Docs',
      theme_color: '#3eaf7c',
    }
  }
}
```

### 国际化

```javascript
// config.mjs
export default {
  locales: {
    root: {
      label: '中文',
      lang: 'zh-CN'
    },
    en: {
      label: 'English',
      lang: 'en-US',
      link: '/en/'
    }
  }
}
```

## 🐛 常见问题

### 开发环境问题

**Q: 端口被占用怎么办？**
```bash
# 使用其他端口
npm run dev -- --port 3001

# 或查找占用端口的进程
lsof -i :5173
kill -9 <PID>
```

**Q: 热更新不生效？**
- 清理缓存：`rm -rf .vitepress/cache`
- 重启服务器
- 检查文件监听数量限制

**Q: 依赖安装失败？**
```bash
# 清理并重装
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### 构建问题

**Q: 构建内存溢出？**
```bash
# 增加内存限制
NODE_OPTIONS="--max-old-space-size=4096" npm run build
```

**Q: 静态资源路径错误？**
- 检查 `base` 配置是否正确
- 使用相对路径引用资源
- 将资源放在 `public` 目录

### 部署问题

**Q: GitHub Pages 404？**
- 确认 `base` 路径配置正确
- 检查仓库名称是否匹配
- 等待 DNS 传播（可能需要几分钟）

**Q: Actions 权限错误？**
- 检查仓库 Settings → Actions 权限
- 确保 workflow 有正确的权限声明

## 📚 参考资源

- [VitePress 官方文档](https://vitepress.dev/)
- [Vite 官方文档](https://vitejs.dev/)
- [Vue 3 文档](https://vuejs.org/)
- [GitHub Actions 文档](https://docs.github.com/actions)
- [GitHub Pages 文档](https://pages.github.com/)

## 🤝 贡献指南

欢迎贡献文档！请遵循以下流程：

1. Fork 文档仓库
2. 创建特性分支
3. 提交更改
4. 创建 Pull Request

提交规范：
- `docs:` - 文档更新
- `fix:` - 错误修复
- `feat:` - 新功能
- `chore:` - 构建/配置更新

---

*更多技术支持，请联系 WorldTourCasino 开发团队。*