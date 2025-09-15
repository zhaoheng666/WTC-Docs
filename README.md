# WTC-docs 技术实现

## 🏗️ 系统架构

### 技术栈

- **框架**：VitePress 1.6.4
- **构建**：Vite + Vue 3
- **部署**：GitHub Pages + Actions
- **同步**：Git Hooks 自动化

### 项目结构

```
docs/
├── .github/workflows/deploy.yml   # 自动部署配置
├── .vitepress/
│   ├── config.mjs                # 站点配置
│   └── sidebar.mjs               # 侧边栏生成器
├── 关卡/活动/协议/工具/其他/      # 文档目录
└── index.md                      # 首页
```

## 🚀 核心功能实现

### 1. 侧边栏自动生成

实现了智能扫描目录，自动构建多级侧边栏：

```javascript
// sidebar.mjs 核心逻辑
- 递归扫描所有 .md 文件
- 按 directoryOrder 配置排序
- 支持 ignoreList 过滤规则
- 自动处理中文路径编码
```

**特性**：

- ✅ 无需手动维护侧边栏
- ✅ 支持无限层级嵌套
- ✅ 中文目录友好支持
- ✅ 特殊文件名映射（index → 概览）

### 2. 文档仓库分离

将文档独立为单独仓库，实现主项目与文档解耦：

**优势**：

- 独立的版本控制
- 减小主仓库体积
- 独立的部署流程
- 更灵活的权限管理

### 3. Git Hooks 自动同步

通过 Git Hooks 实现文档自动同步：

```bash
# .vscode/git-hooks/
├── post-merge     # pull 后自动同步
├── post-checkout  # 切换分支时同步
└── pre-push       # push 前检查提醒
```

**同步机制**：

- 主项目 `git pull` → 自动拉取文档更新
- 切换分支 → 同步对应文档
- 推送前 → 检查文档状态并通知

### 4. VS Code 任务集成

配置了完整的 VS Code 任务流：

```json
// .vscode/tasks.json
- check_docs_setup    # 检查、初始化环境
- start_local_docs_server  # 后台启动服务
- open_local_docs          # 打开浏览器
```

**自动化流程**：

1. 打开项目自动检查环境
2. 克隆文档仓库（如需要）
3. 安装依赖并启动服务
4. 标记完成避免重复初始化

### 5. macOS 系统通知

集成 terminal-notifier 实现系统级通知：

```bash
# 文档有未提交更改时
terminal-notifier -title "Git 提示" \
  -message "文档仓库有未提交的更改" \
  -sound Glass
```

### 6. 全文搜索优化

配置 MiniSearch 实现真正的全文搜索，特别优化中文分词：

```javascript
// config.mjs 搜索配置
miniSearch: {
  options: {
    boost: {
      title: 4,    // 标题权重最高
      text: 2,     // 正文内容权重
      titles: 1    // 各级标题权重
    },
    // 自定义分词器
    tokenize: (text) => {
      // 中文采用滑动窗口分词（1-3字）
      // 解决"迟到"等词无法搜索的问题
    }
  },
  searchOptions: {
    fuzzy: 0.2,      // 模糊匹配容错
    prefix: true,    // 前缀匹配
    combineWith: 'OR' // OR逻辑提高召回率
  }
}
```

**搜索特性**：
- ✅ 索引全部文档内容（不仅是标题）
- ✅ 智能权重分配
- ✅ 中文滑动窗口分词（解决分词问题）
- ✅ 支持模糊搜索
- ✅ 中英文混合支持

## 📦 构建与部署

### GitHub Actions 自动部署

**工作流配置**：

```yaml
# .github/workflows/deploy.yml
- 触发：推送到 main 分支
- 环境：Ubuntu + Node.js 20
- 步骤：依赖安装 → 构建 → 部署
- 耗时：Build 18s + Deploy 10s = 40s
```

### 部署优化

1. **NPM 缓存**：减少依赖安装时间
2. **增量构建**：只构建变更文件
3. **死链接处理**：配置 ignoreDeadLinks 规则
4. **基础路径**：配置 base: '/WTC-Docs/'

## 🛠️ 开发环境配置

### 快速启动脚本

```bash
# check_docs_setup.sh
- 快速路径：检查标记文件跳过重复初始化
- 自动安装：terminal-notifier、npm 依赖
- 服务管理：检查端口避免重复启动
```

### 环境初始化优化

```bash
# 首次运行
1. 克隆文档仓库
2. 安装 terminal-notifier
3. 安装 npm 依赖
4. 安装 Git Hooks
5. 启动文档服务
6. 创建完成标记

# 后续运行（< 1秒）
1. 检查标记文件
2. 检查服务状态
3. 按需启动服务
```

## 🔧 问题解决

### 已解决的问题

1. **目录排序失效**

   - 原因：使用了错误的属性名
   - 解决：改用 item.text 进行排序
2. **死链接构建失败**

   - 原因：URL 编码的中文路径
   - 解决：配置 ignoreDeadLinks 规则
3. **GitHub Actions 失败**

   - 原因：缺少 package-lock.json
   - 解决：提交锁文件，使用 npm ci
4. **重复初始化**

   - 原因：每次启动都执行完整流程
   - 解决：添加标记文件快速跳过
5. **通知不显示**

   - 原因：terminal-notifier 未安装
   - 解决：在初始化脚本中自动安装

## 📊 性能指标

- **本地启动**：< 2 秒
- **热更新**：< 100ms
- **构建时间**：18 秒
- **部署时间**：10 秒
- **总部署耗时**：40 秒

## 🎯 最佳实践

1. **文档组织**

   - 按功能模块分类
   - 保持目录层级简洁
   - 使用中文命名提高可读性
2. **提交规范**

   - 文档更新使用 `docs:` 前缀
   - 配置更新使用 `chore:` 前缀
   - 错误修复使用 `fix:` 前缀
3. **协作流程**

   - 文档直接在 main 分支修改
   - 大型重构创建 feature 分支
   - 推送自动触发部署

## 🔗 相关链接

- **在线文档**：https://zhaoheng666.github.io/WTC-Docs/
- **文档仓库**：https://github.com/zhaoheng666/WTC-Docs
- **主项目仓库**：https://github.com/LuckyZen/WorldTourCasino
