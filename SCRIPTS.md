# 📚 文档项目脚本说明

## 🚀 快速开始

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建文档
npm run build
```

## 📝 脚本命令详解

### 开发命令

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `npm run dev` | 启动开发服务器 (默认端口 5173) | 日常文档编写 |
| `npm run dev:host` | 启动开发服务器并暴露到局域网 | 需要手机或其他设备访问 |
| `npm run dev:port` | 在 4000 端口启动开发服务器 | 默认端口被占用时 |

### 构建命令

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `npm run build` | 完整构建（含检查） | 正式构建，推荐使用 |
| `npm run build:quick` | 快速构建（跳过检查） | 紧急情况或已确认无问题时 |
| `npm run build:test` | 测试构建 | 验证构建是否能成功 |
| `npm run preview` | 预览构建结果 | 构建后本地查看效果 |
| `npm run serve` | 启动静态服务器 | 部署前的最终验证 |

### 工具命令

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `npm run stats` | 生成统计数据 | 更新文档统计仪表板 |
| `npm run images:collect` | 全量收集图片 | 初次整理或大规模清理 |
| `npm run images:collect:inc` | 增量收集图片 | 日常使用（只处理变更文件） |
| `npm run fix:rollup` | 修复 Rollup ARM64 问题 | Mac M系列芯片遇到构建问题 |

### Git 工作流

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `npm run precommit` | 提交前检查 | 验证是否可以安全提交 |
| `npm run commit` | 智能提交 | 自动检查、添加文件并提交 |

### 维护命令

| 命令 | 说明 | 使用场景 |
|------|------|----------|
| `npm run clean` | 清理构建缓存 | 遇到构建问题时 |
| `npm run clean:build` | 清理并重新构建 | 需要完全重新构建 |
| `npm run fresh` | 全新开始 | 清理、重装依赖、构建 |

## 🔧 脚本文件说明

所有脚本文件位于 `.vitepress/scripts/` 目录：

### 核心脚本

- **`pre-commit-check.sh`** - 提交前检查脚本
  - 检查未暂存的更改
  - 增量收集图片资源
  - 更新统计数据
  - 执行构建测试

- **`collect-images-incremental.sh`** - 增量图片收集
  - 只处理 git 中新增或修改的文件
  - 自动整理图片到 public/images
  - 更新 MD 文件中的引用路径
  - 删除原始图片文件

- **`collect-images.sh`** - 全量图片收集
  - 扫描所有 MD 文件
  - 批量整理所有图片
  - 清理遗留文件
  - 适合初次整理或大规模清理

- **`generate-stats.sh`** - 统计数据生成
  - 统计文档数量、贡献者等
  - 生成 public/stats.json
  - 更新统计仪表板页面

- **`test-build.sh`** - 构建测试
  - 快速验证构建是否能成功
  - 不影响实际文件

- **`fix-rollup.sh`** - Rollup 修复
  - 解决 Mac ARM64 架构问题
  - 安装必要的依赖包

## 💡 使用建议

### 日常开发流程

1. **开始工作**
   ```bash
   npm run dev
   ```

2. **提交代码前**
   ```bash
   npm run precommit  # 检查是否有问题
   npm run commit     # 如果没问题，直接提交
   ```

3. **遇到问题时**
   ```bash
   npm run clean      # 清理缓存
   npm run fix:rollup # Mac M系列芯片构建问题
   ```

### 图片管理

- 日常使用无需手动运行图片收集，`precommit` 会自动处理
- 如需手动整理：
  - `npm run images:collect:inc` - 只处理新增/修改的文件
  - `npm run images:collect` - 全量整理（较慢）

### 构建部署

- 正式构建：`npm run build`（包含所有检查）
- 快速构建：`npm run build:quick`（跳过检查，不推荐）
- 预览结果：`npm run preview`

## ⚠️ 注意事项

1. **首次使用**需要运行 `npm install` 安装依赖
2. **Mac M系列芯片**可能需要运行 `npm run fix:rollup`
3. **图片路径**会自动整理，无需手动管理
4. **提交前**建议使用 `npm run precommit` 检查