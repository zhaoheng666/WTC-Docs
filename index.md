# WorldTourCasino 文档中心

欢迎来到 WorldTourCasino 项目文档中心。这里是项目的技术文档库，包含了游戏开发所需的各类文档、API 参考、配置说明等资料。

## 📚 文档分类

### 游戏系统文档

| 分类                   | 说明                                   | 快速访问        |
| ---------------------- | -------------------------------------- | --------------- |
| 🎮**关卡**       | 老虎机游戏关卡配置、数值设计、特殊玩法 | [查看文档](/关卡/) |
| 📋**活动、系统** | 游戏活动配置、节日活动、运营活动       | [查看文档](/活动/) |
| 🏙️Native             | 城市解锁、地标收集、城市特色玩法       | 开发中          |

### 技术文档

| 分类                   | 说明                         | 快速访问        |
| ---------------------- | ---------------------------- | --------------- |
| 🔌**通信协议**   | 前后端通信协议、数据格式定义 | [查看文档](/协议/) |
| 🛠️**开发工具** | 构建脚本、部署工具、调试工具 | [查看文档](/工具/) |
| 📊**数据配置**   | 游戏数值、配置表、数据结构   | 开发中          |
| 🔧**技术架构**   | 系统架构、技术选型、最佳实践 | 开发中          |

### 其他文档

| 分类                 | 说明                           | 快速访问                 |
| -------------------- | ------------------------------ | ------------------------ |
| 📝**会议记录** | 程序组会议、技术分享、架构讨论 | [查看文档](/其他/工作记录/9%20月程序会) |
| 📖**使用指南** | VitePress 文档系统使用说明     | 本页下方                |
| 🔄**更新日志** | 版本更新、功能迭代记录         | 开发中                   |

## 🚀 快速开始

### 查看文档

直接点击上方链接访问相应的文档分类，或使用左侧导航栏浏览。

### 搜索功能

使用快捷键快速搜索文档：

- `Cmd+K` (Mac)
- `Ctrl+K` (Windows/Linux)

### 本地运行

如需在本地运行文档系统，请参考下方的使用指南部分

## 📊 文档统计

- **文档总数**: 50+ 篇
- **最近更新**: 2025-01-15
- **贡献者**: WorldTourCasino 开发团队

## 📝 文档管理指南

### 新增文档

1. **创建文件**：在相应目录下创建 `.md` 文件
2. **编写内容**：使用 Markdown 语法编写文档
3. **自动显示**：文档会自动出现在侧边栏中（除非被忽略列表屏蔽）

### 修改文档

- 直接编辑对应的 `.md` 文件
- 保存后刷新页面即可看到更新
- 本地开发服务器支持热重载

### 删除文档

- 删除对应的 `.md` 文件
- 侧边栏会自动更新

### 注意事项

- 文件名将作为侧边栏显示名称
- `index.md` 会显示为"概览"
- 中文文件名完全支持
- 避免使用特殊字符

## ⚙️ 配置说明

### 侧边栏配置

**文件位置**：`.vitepress/sidebar.mjs`

**主要功能**：

- **自动扫描**：自动扫描所有文档目录并生成侧边栏
- **目录排序**：通过 `directoryOrder` 配置控制显示顺序
- **忽略列表**：通过 `ignoreList` 屏蔽特定文件或目录
- **特殊格式**：通过 `specialCases` 定义名称映射

**配置示例**：

```javascript
		// 目录排序
const directoryOrder = {
  '活动': 1,    // 数字越小越靠前
  '关卡': 2,
  'Native': 3,
  '协议': 4,
  '工具': 5,
  '其他': 6,
}

// 忽略列表
const ignoreList = [
  '/其他/测试文档.md',  // 忽略特定文件
  'README.md',          // 忽略所有 README.md
  '/临时目录/',         // 忽略整个目录
  'draft-',            // 忽略 draft- 开头的文件
]
```

### 顶部导航栏配置

**文件位置**：`.vitepress/config.mjs`

**配置内容**：

```javascript
themeConfig: {
  nav: [
    { text: '首页', link: '/' },
    { text: '关卡', link: '/关卡/' },
    { text: '活动', link: '/活动/' },
    // 更多导航项...
  ]
}
```

### 搜索使用方法

**快捷键**：

- `Cmd+K` (Mac)
- `Ctrl+K` (Windows/Linux)

**搜索功能**：

- **全文搜索**：搜索所有文档内容
- **标题搜索**：优先匹配文档标题
- **实时预览**：搜索结果实时显示
- **快速跳转**：点击结果直接跳转到对应位置

**搜索技巧**：

- 支持中文和英文搜索
- 支持模糊匹配
- 支持多关键词搜索（空格分隔）
- 搜索结果按相关度排序

### 本地预览说明

**VitePress 热更新行为**：

- **文档内容修改**：自动热更新，实时同步显示
- **新增/删除文档**：需要刷新或重启 VitePress 服务器

**重启服务方法**：

vscode 中，找到运行中任务 start_local_docs_server ，输入 h 进入 vitepress shortcuts，选择 r 重启服务。

```bash
# 停止当前服务（Ctrl+C）
# 重新启动
npm run dev
```

## 🔄 文档同步机制

文档仓库与主项目采用 Git Hooks 自动同步机制，确保文档始终保持最新。

### 自动同步功能

**同步时机**：

- 主仓库执行 `git pull` 后自动拉取文档更新
- 主仓库切换分支时自动拉取文档最新内容
- 主仓库推送前检查并提醒文档状态

**Git Hooks 配置**：

- **post-merge**: pull/merge 后自动同步文档
- **post-checkout**: 分支切换时同步文档
- **pre-push**: 推送前检查文档仓库状态

### 初始化设置

**自动流程**：
VS Code 打开项目时会自动执行 `setup_docs_environment` 任务：

1. 检查并克隆文档仓库（如需要）
2. 安装文档依赖
3. 安装 Git Hooks
4. 启动文档服务

**手动安装**：

```bash
# 完整设置流程
bash .vscode/scripts/check_docs_setup.sh

# 或单独安装 Git Hooks
bash .vscode/git-hooks/install-hooks.sh
```

### 工作流程

1. **开发者 A 更新文档**：

   ```bash
   cd docs
   git add .
   git commit -m "docs: 更新API文档"
   git push
   ```
2. **开发者 B 拉取主项目**：

   ```bash
   git pull  # 自动触发文档同步
   # ✅ 文档仓库同步完成
   ```
3. **切换分支开发**：

   ```bash
   git checkout feature/new-feature
   # 📝 文档仓库自动拉取最新更新
   ```

### 注意事项

- 文档仓库独立维护在: https://github.com/zhaoheng666/WTC-Docs
- 主仓库 `.gitignore` 已忽略 `docs/` 目录
- 每个开发者本地都需要安装 Git Hooks（自动完成）
- 文档同步失败不会影响主仓库操作

## 🚀 GitHub Pages 部署

文档已配置自动部署到 GitHub Pages，访问地址：https://zhaoheng666.github.io/WTC-Docs/

### 自动部署流程

每次推送到 `main` 分支时，GitHub Actions 会自动：
1. **构建阶段** (Build) - 构建 VitePress 静态站点（约 18 秒）
2. **部署阶段** (Deploy) - 部署到 GitHub Pages（约 10 秒）
3. **总耗时**：约 40 秒完成整个部署流程

### 部署状态监控

- **查看部署进度**：[Actions 页面](https://github.com/zhaoheng666/WTC-Docs/actions)
- **部署历史**：每次部署都会在 Actions 中留下记录
- **部署状态徽章**：可在 README 中添加状态徽章显示部署状态

### 手动触发部署

可以在 GitHub 仓库的 Actions 页面手动触发部署：
1. 访问 [Actions 页面](https://github.com/zhaoheng666/WTC-Docs/actions)
2. 选择 "Deploy to GitHub Pages" 工作流
3. 点击 "Run workflow"
4. 选择分支（默认 main）并确认

### 部署配置说明

- **基础路径**：配置在 `.vitepress/config.mjs` 中的 `base: '/WTC-Docs/'`
- **工作流文件**：`.github/workflows/deploy.yml`
- **构建输出**：`.vitepress/dist/`
- **Node 版本**：20.x
- **包管理器**：npm（使用 `package-lock.json`）

### 常见问题排查

#### Build 阶段失败

1. **依赖安装失败**
   - 检查 `package-lock.json` 是否已提交
   - 确保没有将 `package-lock.json` 加入 `.gitignore`
   - 运行 `npm ci` 验证本地依赖是否正常

2. **死链接错误**
   ```
   Found dead link(s) in file...
   ```
   - 检查文档中的链接是否正确
   - 必要时在 `config.mjs` 中配置 `ignoreDeadLinks`
   - 避免使用 `localhost` 等本地链接

3. **构建错误**
   - 检查 Markdown 语法是否正确
   - 确保没有使用不支持的 VitePress 功能
   - 查看详细错误日志定位问题

#### Deploy 阶段失败

1. **权限问题**
   - 进入 Settings → Actions → General
   - 确保 "Workflow permissions" 设置为 "Read and write permissions"
   - 检查 GITHUB_TOKEN 权限配置

2. **GitHub Pages 未启用**
   - 进入 Settings → Pages
   - Source 选择 "GitHub Actions"
   - 确保仓库为 Public 或有 GitHub Pages 权限

3. **部署目标错误**
   - 检查 workflow 中的 `path: .vitepress/dist` 是否正确
   - 确认构建输出目录与配置一致

### 部署优化建议

1. **缓存优化**：workflow 已配置 npm 缓存，加快依赖安装
2. **并行构建**：利用 GitHub Actions 的并行能力
3. **增量部署**：只有文件变更时才触发部署
4. **部署通知**：可配置部署完成后的通知（如 Slack、邮件等）
