# WorldTourCasino 文档系统

## 🚀 快速开始

```bash
# 初始化环境（首次使用）
npm run init

# 启动开发服务器
npm run dev

# 同步文档到远程
npm run sync
```

## 📚 项目介绍

这是 WorldTourCasino 项目的独立文档仓库，使用 VitePress 构建，通过 GitHub Actions 自动部署到 GitHub Pages。

### 核心特性

- 📝 **Markdown 驱动** - 专注内容创作
- 🔍 **智能中文搜索** - 基于 Intl.Segmenter 的专业分词
- 📁 **自动侧边栏** - 无需手动维护导航
- 🔄 **自动化部署** - 推送即发布
- 🎨 **响应式设计** - 完美适配各种设备

## 🏗️ 系统架构

### 技术栈

- **框架**：VitePress 1.6.4
- **构建**：Vite + Vue 3  
- **部署**：GitHub Pages + Actions
- **脚本**：Bash + Node.js

### 目录结构

```
docs/
├── .vitepress/
│   ├── config.mjs           # 站点配置
│   ├── sidebar.mjs          # 侧边栏生成器
│   └── scripts/             # 自动化脚本
├── .github/
│   └── workflows/           # GitHub Actions
├── public/                  # 静态资源
│   ├── images/             # 图片资源（自动整理）
│   └── stats.json          # 统计数据
├── 关卡/                   # 游戏关卡文档
├── 活动/                   # 活动相关文档
├── 协议/                   # 协议文档
├── 工具/                   # 工具使用文档
└── index.md                # 首页
```

## 📝 核心命令

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `npm run init` | 环境初始化和修复 | 首次使用或环境问题 |
| `npm run dev` | 启动开发服务器 | 日常文档编写 |
| `npm run build` | 构建生产版本 | 需要静态文件 |
| `npm run sync` | 同步到远程 | 提交并推送更新 |
| `npm run status` | 检查仓库状态 | 主项目调用 |

## 🚀 核心功能

### 1. 智能环境管理

`npm run init` 提供完整的环境检查和修复：

- ✅ Node.js 和 npm 依赖检查
- ✅ GitHub CLI 自动配置
- ✅ Git 中文路径支持
- ✅ 脚本权限设置
- ✅ 支持 `--silent` 和 `--fix` 参数

### 2. 自动化文档处理

构建时自动执行：

- 📸 **图片资源整理** - 自动收集并规范化图片路径
- 📊 **统计数据生成** - 实时更新文档统计仪表板
- 🔨 **构建验证** - 确保文档质量

### 3. 智能同步流程

`npm run sync` 包含完整工作流：

- 暂存本地更改
- 执行构建测试
- 生成提交信息
- 使用 rebase 保持线性历史
- 推送到远程仓库
- 检查 GitHub Actions 状态

### 4. 中文搜索优化

使用 Intl.Segmenter API 实现专业中文分词：

```javascript
// 智能分词配置
- 准确识别中文词汇边界
- 长词自动生成 2 字索引
- 模糊匹配提高容错率
- 去重优化减少索引体积
```

### 5. GitHub Actions 监控

自动监控构建状态：

- 构建失败时系统通知
- 实时状态检查
- 持续监控模式

## 🛠️ 开发指南

### 日常工作流程

1. **首次设置**
   ```bash
   npm run init  # 配置环境
   npm run dev   # 启动开发
   ```

2. **编写文档**
   - 在相应目录创建 `.md` 文件
   - 图片放在文档同目录（自动整理）
   - 使用中文命名提高可读性

3. **提交更新**
   ```bash
   npm run sync  # 自动构建、提交、推送
   ```

### 文档组织规范

- 📁 按功能模块分类存放
- 📝 使用清晰的中文命名
- 🏷️ 保持目录层级简洁
- 📸 图片与文档同目录

### 提交信息规范

- `docs:` - 文档内容更新
- `feat:` - 新增功能
- `fix:` - 错误修复
- `chore:` - 配置更新
- `refactor:` - 代码重构

## 📦 部署配置

### GitHub Actions

推送到 `main` 分支自动触发部署：

- **构建时间**：~18 秒
- **部署时间**：~10 秒
- **总耗时**：~40 秒

### 部署优化

- NPM 缓存减少安装时间
- 增量构建只处理变更
- 自动处理死链接
- 配置正确的 base 路径

## 🔧 故障排除

### 环境问题

任何环境问题都可以通过 `npm run init` 解决：

```bash
npm run init          # 交互式修复
npm run init -- --fix # 自动修复模式
```

### 常见问题

1. **构建失败**
   - 运行 `npm run init` 修复环境
   - 检查 Node.js 版本（需要 18+）

2. **GitHub Actions 失败**
   - 检查 GitHub CLI 登录状态
   - 运行 `npm run init` 重新配置

3. **Mac ARM64 问题**
   - `npm run init` 会自动安装兼容包
   - 详见故障排查文档

## 📊 性能指标

- **本地启动**：< 2 秒
- **热更新**：< 100ms
- **构建时间**：~18 秒
- **部署时间**：~10 秒
- **搜索响应**：< 50ms

## 🔗 相关链接

- **在线文档**：https://zhaoheng666.github.io/WTC-Docs/
- **文档仓库**：https://github.com/zhaoheng666/WTC-Docs
- **主项目**：https://github.com/LuckyZen/WorldTourCasino

## 📄 许可证

MIT License

---

> 💡 **提示**：详细的脚本使用说明请查看 [SCRIPTS.md](./SCRIPTS.md)