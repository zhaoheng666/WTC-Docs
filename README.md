# VitePress 文档系统使用指南

## 📚 关于 VitePress

VitePress 是一个静态站点生成器，专为构建快速、以内容为中心的网站而设计。WorldTourCasino 文档中心使用 VitePress 构建，提供了完整的文档管理解决方案。

## 🚀 快速开始

### 环境要求

- Node.js 16.0+
- npm 7.0+

### 本地运行

```bash
# 1. 进入文档目录
cd docs

# 2. 安装依赖（首次运行）
npm install

# 3. 启动开发服务器
npm run dev
```

访问本地服务器查看文档（默认端口 5173）

### VS Code 快速启动

1. 按 `Cmd+Shift+P` (Mac) 或 `Ctrl+Shift+P` (Windows)
2. 选择 `Tasks: Run Task`
3. 选择 `docs_dev` - 一键启动文档环境

## 📖 文档结构说明

```
docs/
├── .vitepress/         # VitePress 配置
│   ├── config.mjs      # 主配置文件
│   └── sidebar.mjs     # 侧边栏配置
├── 关卡/               # Slots 游戏关卡文档
├── 活动/               # 活动系统文档
├── 协议/               # 通信协议文档
│   ├── frontend/       # 前端协议
│   └── backend/        # 后端协议
├── 工具/               # 开发工具文档
├── 其他/               # 其他文档
│   └── record/         # 会议记录
└── index.md            # 首页
```

## ✏️ 编写文档

### 创建新文档

1. **创建 Markdown 文件**

   在相应目录下创建 `.md` 文件：

   ```shell
   # 例如：在"其他"目录创建新文档
   touch docs/其他/新文档.md
   ```
2. **编写文档内容**

```markdown
# 文档标题

## 章节一

文档内容...

## 章节二

更多内容...
```

3. **添加到侧边栏**（如需要）
   编辑 `.vitepress/sidebar.mjs` 添加链接

### Markdown 增强功能

#### 提示框

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

效果展示：

::: tip 提示
有用的提示信息
:::

::: warning 警告
需要注意的内容
:::

#### 代码高亮

````markdown
```javascript
// 支持语法高亮
function hello() {
  console.log('Hello WorldTourCasino!')
}
```
````

#### 代码组

::: code-group

```javascript
const game = 'WorldTourCasino'
console.log(game)
```

```python
game = 'WorldTourCasino'
print(game)
```

:::

#### 表格

| 功能 | 命令                | 说明           |
| ---- | ------------------- | -------------- |
| 开发 | `npm run dev`     | 启动开发服务器 |
| 构建 | `npm run build`   | 构建静态文件   |
| 预览 | `npm run preview` | 预览构建结果   |

## 🔧 常用操作

### 开发命令

```bash
# 启动开发服务器
npm run dev

# 指定端口
npm run dev -- --port 3000

# 开放网络访问
npm run dev -- --host

# 构建文档
npm run build

# 预览构建结果
npm run preview
```

### VS Code 任务

| 任务名称                    | 功能         | 说明                           |
| --------------------------- | ------------ | ------------------------------ |
| `docs_dev`                | 完整启动流程 | 安装依赖→启动服务→打开浏览器 |
| `start_local_docs_server` | 启动服务器   | 后台运行，项目打开时自动启动   |
| `open_local_docs`         | 打开文档页面 | 在浏览器中打开                 |
| `install_docs_deps`       | 安装依赖     | 安装 npm 包                    |

## 🎨 配置说明

### VitePress 配置

配置文件：`.vitepress/config.mjs`

```javascript
export default {
  title: 'WorldTourCasino',
  description: '文档中心',
  lang: 'zh-CN',

  themeConfig: {
    // 导航栏配置
    nav: [...],

    // 侧边栏配置
    sidebar: {...},

    // 搜索配置
    search: {
      provider: 'local'
    }
  }
}
```

### 侧边栏配置

配置文件：`.vitepress/sidebar.mjs`

```javascript
export default {
  '/关卡/': [
    {
      text: 'Slots 关卡',
      items: [
        { text: '关卡配置', link: '/关卡/config' },
        { text: '数值设计', link: '/关卡/design' }
      ]
    }
  ],
  // 其他目录配置...
}
```

## 📦 构建部署

### 构建静态文件

```bash
# 构建
npm run build

# 输出目录：.vitepress/dist
```

### 部署方式

#### GitHub Pages

已配置 GitHub Actions，推送到主分支自动部署

#### 手动部署

1. 构建文档：`npm run build`
2. 上传 `.vitepress/dist` 到服务器
3. 配置 Nginx/Apache 托管静态文件

#### 云服务部署

- **Vercel**: 连接 Git 仓库，自动部署
- **Netlify**: 支持自定义域名
- **腾讯云/阿里云**: 静态网站托管

## 🐛 故障排除

### 常见问题

**端口被占用**

```bash
# 使用其他端口
npm run dev -- --port 3001
```

**依赖安装失败**

```bash
# 清理并重新安装
rm -rf node_modules package-lock.json
npm install
```

**页面不更新**

- 清理浏览器缓存 `Cmd+Shift+R`
- 重启开发服务器
- 检查文件是否保存

**构建失败**

```bash
# 清理缓存
rm -rf .vitepress/cache .vitepress/dist
npm run build
```

## 📝 文档规范

### 命名规范

- 文件名使用中文或英文
- 英文文件名使用小写，连字符分隔
- 例如：`getting-started.md` 或 `快速开始.md`

### 内容规范

1. **标题层级**

   - 页面标题使用 `#`
   - 主要章节使用 `##`
   - 子章节使用 `###`
   - 最多到 `####`
2. **代码示例**

   - 标注语言类型
   - 添加必要注释
   - 保证可运行
3. **图片使用**

   - 放在 `public` 目录
   - 使用相对路径引用
   - 控制图片大小
4. **链接**

   - 内部链接用相对路径
   - 外部链接建议新窗口打开

## 🔍 搜索功能

文档支持本地搜索，快捷键：

- `Cmd+K` (Mac)
- `Ctrl+K` (Windows/Linux)

## 🔗 相关链接

- [VitePress 官方文档](https://vitepress.dev/)
- [Markdown 语法参考](https://www.markdownguide.org/)
- [Node.js 官网](https://nodejs.org/)
