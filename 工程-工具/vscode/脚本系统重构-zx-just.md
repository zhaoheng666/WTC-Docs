# VS Code 脚本系统重构 - zx + Just

## 概述

将原有的 Shell 脚本系统重构为 **zx (JavaScript) + Just（任务编排）** 的组合方案，提升代码的可维护性、可读性和跨平台兼容性。

- **zx**: Google 的 JavaScript 脚本工具，让 Node.js 写 shell 脚本更简单
- **Just**: 类似 Make 的任务运行器，但更现代和友好

## 架构设计

### 目录结构

```
.vscode/
├── justfile                      # Just 任务编排配置
├── scripts/
│   ├── src/                     # zx 脚本源码
│   │   ├── setup.mjs           # 环境设置主脚本
│   │   ├── cleanup.mjs         # 清理脚本
│   │   ├── modules/            # 功能模块
│   │   │   ├── docs.mjs       # 文档管理
│   │   │   ├── extensions.mjs # 扩展管理
│   │   │   ├── services.mjs   # 服务管理
│   │   │   └── config.mjs     # 配置读取
│   │   └── utils/              # 工具函数
│   │       ├── logger.mjs     # 日志工具
│   │       └── helpers.mjs    # 辅助函数
│   ├── legacy/                 # 旧脚本（保留备份）
│   └── git-hooks/              # Git 钩子（保留）
```

### 技术栈

- **zx**: 处理具体的脚本逻辑（JavaScript 的灵活性）
- **Just**: 负责任务编排和依赖管理（声明式的清晰性）
- **ES Modules**: 使用现代 JavaScript 模块系统

## 核心功能

### 1. Just 命令列表

```bash
# 查看所有可用命令
just --list

# 常用命令
just setup          # 完整环境设置
just start          # 启动所有服务
just stop           # 停止所有服务
just fix-env        # 修复环境问题
just status         # 查看服务状态
just docs           # 打开文档
```

### 实际执行命令

```bash
# 启动文档服务
just start-docs     # 使用 pipe 模式直接输出到终端

# 停止所有服务
just stop           # 清理文档服务、HTTP服务、孤儿进程等

# 快速设置（VS Code 启动时自动运行）
just on-enter       # 检查并设置环境，启动必要服务
```

### 2. 模块说明

#### config.mjs - 配置读取
- 从 `.vscode/settings.json` 读取项目配置
- 支持注释的 JSON 解析
- 提供配置缓存机制

#### docs.mjs - 文档管理
- 自动克隆和更新文档仓库
- 管理文档依赖安装
- ARM64 Mac Rollup 依赖修复
- 文档服务启动和停止
- **启动模式优化**: 使用 `pipe(process.stdout)` 直接输出到终端
  ```javascript
  // 简洁优雅的启动方式
  await $`npm run dev`.cwd(docsDir).pipe(process.stdout)
  ```
  - 实时显示输出，无需复杂的进程管理
  - Ctrl+C 可以正常中断
  - 避免了 spawn/nohup 等复杂模式

#### extensions.mjs - 扩展管理
- 管理 VS Code 扩展仓库
- 为多个编辑器创建符号链接（VS Code、Trae、Cursor 等）
- 扩展的安装和清理

#### services.mjs - 服务管理
- 统一管理所有服务进程
- 清理孤儿进程
- 锁文件管理
- 进程树杀死功能

### 3. VS Code 集成

`tasks.json` 已更新为使用 Just 命令：

```json
{
  "label": "project-onenter",
  "command": "just",
  "args": ["on-enter"]
}
```

## 优势

### 相比原有 Shell 脚本

1. **更好的错误处理**: JavaScript 的 try-catch 和 Promise 支持
2. **统一技术栈**: 与项目主语言（JavaScript）一致
3. **更好的调试**: 可以使用 Node.js 调试工具
4. **跨平台兼容**: zx 自动处理平台差异
5. **模块化**: ES Modules 提供更好的代码组织
6. **类型提示**: VS Code 对 JavaScript 有更好的智能提示

### Just 的优势

1. **清晰的任务依赖**: 声明式定义任务关系
2. **自文档化**: `just --list` 自动生成帮助
3. **参数支持**: 可以传递参数给任务
4. **环境变量**: 内置 dotenv 支持
5. **跨平台**: Rust 编写，各平台都有原生支持

## 使用指南

### 安装依赖

```bash
# 安装 zx（项目依赖）
npm install --save-dev zx

# 安装 Just（全局工具）
brew install just  # macOS
```

### 日常使用

```bash
# 项目设置
cd /path/to/project/.vscode
just setup

# 启动服务
just start

# 查看状态
just status

# 修复问题
just fix-env

# 清理环境
just clean
```

### 开发新功能

1. 在 `scripts/src/modules/` 创建新模块
2. 使用 ES Modules 导出功能
3. 在 `justfile` 中添加新任务
4. 更新 `tasks.json` 如需 VS Code 集成

## 迁移指南

### 从旧脚本迁移

| 旧脚本 | 新命令 |
|--------|--------|
| `onEnter.sh` | `just on-enter` |
| `cleanup-services.sh` | `just stop` |
| `fix-environment.sh` | `just fix-env` |
| `check-docs-setup.sh` | `just setup-docs` |

### 兼容性

- 旧脚本保留在 `legacy/` 目录作为备份
- 新系统向后兼容所有 VS Code 任务
- Git hooks 保持不变

## 故障排查

### 常见问题

1. **模块找不到错误**
   - 确保在正确目录运行：`cd .vscode && just [command]`
   - 检查 `node_modules` 是否包含 zx

2. **权限错误**
   - 确保脚本有执行权限：`chmod +x scripts/src/*.mjs`

3. **服务启动超时**
   - 检查端口占用：`lsof -ti:5173`
   - 手动启动测试：`cd docs && npm run dev`

4. **CLI 命令没有输出（重要）** ⚠️
   - **问题原因**: `import.meta.main` 在 Node.js 中是实验性功能，很多版本不支持
   - **症状**: 运行 `node script.mjs` 没有任何输出
   - **根本原因**:
     - `import.meta.main` 是 Node.js v20.11.0+ 才正式支持的功能
     - 即使在支持的版本中，也需要特定的运行方式才能正确识别
     - 在许多 Node.js 环境中返回 `undefined`
   - **解决方案**: 使用 `fileURLToPath(import.meta.url)` 比较替代
   ```javascript
   // ❌ 不要使用这个（不可靠）：
   if (import.meta.main) {
     // 这段代码在很多环境下永远不会执行
   }

   // ✅ 使用这个替代：
   import { fileURLToPath } from 'url'
   const __filename = fileURLToPath(import.meta.url)
   if (process.argv[1] === __filename) {
     // CLI 代码 - 这种方式在所有 Node.js 版本中都可靠
   }
   ```
   - **验证方法**:
   ```bash
   # 测试你的 Node.js 版本是否支持 import.meta.main
   node -e "console.log(import.meta)" # 如果报错说明版本太低
   node --version # 检查版本，建议 v16+
   ```

## 实施经验总结

### 关键决策

1. **进程管理简化**
   - 初始版本尝试了 spawn、nohup、后台进程等多种模式
   - 最终采用 zx 的 pipe 模式：简洁、可靠、实时输出
   - 避免了复杂的进程生命周期管理

2. **模块检测方案选择**
   - 放弃不可靠的 `import.meta.main`
   - 采用 `fileURLToPath` 比较方案，兼容所有 Node.js 版本
   - 确保 CLI 功能在各种环境下都能正常工作

3. **错误处理策略**
   - 使用 try-catch 包裹所有异步操作
   - 特殊处理 SIGINT 信号（Ctrl+C）
   - 提供清晰的错误信息和恢复建议

### 性能优化

1. **启动速度**
   - 快速检查（quickSetup）跳过已完成的设置
   - 使用标记文件避免重复初始化
   - 并行处理独立的设置任务

2. **资源清理**
   - 分级清理：soft（仅停止服务）、standard（清理临时文件）、deep（完全清理）
   - 使用进程树杀死确保彻底清理
   - 自动清理锁文件防止死锁

## 未来改进

1. **TypeScript 支持**: 迁移到 TypeScript 获得类型安全
2. **测试覆盖**: 添加单元测试和集成测试
3. **性能监控**: 添加执行时间和资源使用监控
4. **并行执行**: 优化可并行的任务
5. **缓存机制**: 添加依赖检查和缓存

## 相关链接

- [zx 官方文档](https://github.com/google/zx)
- [Just 官方文档](https://github.com/casey/just)
- [ES Modules 指南](https://nodejs.org/api/esm.html)