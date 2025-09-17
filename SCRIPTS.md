# 📚 文档项目脚本说明

## 🚀 快速开始

```bash
# 首次使用或环境有问题时
npm run init

# 启动开发服务器
npm run dev

# 同步文档到远程
npm run sync
```

## 📝 核心命令

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `npm run init` | 环境初始化和修复 | 首次使用或环境有问题时 |
| `npm run dev` | 启动开发服务器 | 日常文档编写 |
| `npm run build` | 构建生产版本 | 需要构建静态文件时 |
| `npm run sync` | 同步文档到远程 | 提交并推送文档更新 |
| `npm run status` | 检查仓库状态 | 主项目调用，检查文档状态 |

## 🔧 其他可用功能

以下功能可通过直接运行脚本或命令来使用：

### 预览和清理
```bash
npx vitepress preview                    # 预览构建结果
rm -rf .vitepress/dist .vitepress/cache  # 清理缓存
```

### GitHub Actions 监控
```bash
bash .vitepress/scripts/check-actions.sh    # 检查 Actions 状态
bash .vitepress/scripts/watch-actions.sh    # 持续监控 Actions
```

### Git 操作
```bash
git pull origin $(git branch --show-current)  # 拉取当前分支
git push origin $(git branch --show-current)  # 推送当前分支
```

### 修复工具
```bash
bash .vitepress/scripts/fix-rollup.sh        # 修复 Mac ARM64 Rollup 问题
```

## 🔧 脚本文件说明

所有脚本文件位于 `.vitepress/scripts/` 目录：

### 核心脚本

- **`init.sh`** - 环境初始化和修复
  - 检查并安装 Node.js 依赖
  - 配置 GitHub CLI
  - 设置 Git 中文路径支持
  - 支持 `--silent` 和 `--fix` 参数

- **`build.sh`** - 完整构建流程
  - 增量收集图片资源
  - 生成统计数据
  - 执行 VitePress 构建
  - 自动处理构建错误

- **`sync.sh`** - 文档同步流程
  - 暂存本地更改
  - 执行构建测试
  - 自动生成提交信息
  - 使用 rebase 保持线性历史
  - 推送到远程仓库

- **`status.sh`** - 状态检查
  - 自动 stash 本地更改
  - 拉取远程更新
  - 恢复本地更改
  - 供主项目调用

### 辅助脚本

- **`collect-images-incremental.sh`** - 增量图片收集
- **`collect-images.sh`** - 全量图片收集
- **`generate-stats.sh`** - 统计数据生成
- **`check-actions.sh`** - GitHub Actions 状态检查
- **`watch-actions.sh`** - GitHub Actions 持续监控
- **`fix-rollup.sh`** - Rollup ARM64 修复

## 💡 使用建议

### 日常工作流程

1. **首次设置**
   ```bash
   npm run init  # 配置环境
   npm run dev   # 启动开发
   ```

2. **提交更新**
   ```bash
   npm run sync  # 自动构建、提交、推送
   ```

3. **遇到问题**
   ```bash
   npm run init  # 修复环境问题
   ```

### 环境修复

`npm run init` 可以解决大多数环境问题：
- 缺少依赖包
- GitHub CLI 未配置
- Git 配置问题
- 脚本权限问题

支持参数：
- `npm run init -- --silent` - 静默模式
- `npm run init -- --fix` - 自动修复模式

## ⚠️ 注意事项

1. **精简原则**：npm scripts 只保留必要命令，避免冗余
2. **主项目集成**：`status` 和 `sync` 是主项目调用的接口
3. **环境问题**：任何环境问题都可以通过 `npm run init` 解决
4. **自动化**：`sync` 包含完整的构建和提交流程，无需手动操作