# Rollup 平台特定依赖问题

## 问题描述

在使用 VitePress 时，可能会遇到 Rollup 平台特定依赖缺失的错误：

**ARM64 架构（M1/M2/M3 Mac）：**

```
Error: Cannot find module @rollup/rollup-darwin-arm64.
```

**x86_64 架构（Intel Mac 或 Rosetta 2 模式）：**

```
Error: Cannot find module @rollup/rollup-darwin-x64.
```

这是一个 npm 的已知 bug，与可选依赖（optionalDependencies）的处理有关：
https://github.com/npm/cli/issues/4828

### 特殊情况：M3 Mac 需要 x64 版本

**发现时间**：2025年9月

在某些情况下，即使是 ARM64 架构的 M3 Mac 也可能需要 x64 版本的 Rollup：

1. **Rosetta 2 兼容模式**：如果开发工具（VS Code、Trae CN 等）在 Rosetta 2 下运行
2. **混合环境**：某些组件在 x86_64 模式下运行，即使主程序是 ARM64

**检测方法**：

```bash
# 检查当前架构
arch              # 可能显示 i386 或 x86_64
uname -m          # 可能显示 x86_64
node -p process.arch  # 可能显示 arm64

# 检查是否在 Rosetta 2 下运行
sysctl -n sysctl.proc_translated  # 1 表示在 Rosetta 2 下
```

### 问题特征

1. 手动运行 `npm run dev` 正常工作
2. 运行环境修复脚本后，问题暂时解决
3. **关闭并重新打开 VS Code 后，自动启动任务失败，出现同样错误**
4. 手动在终端执行相同命令却能正常运行

## 根本原因

问题的根本原因是 **VS Code Task 的 `type` 配置**：

- 当 Task 类型设置为 `"shell"` 时，VS Code 创建的 shell 环境与普通终端环境存在差异
- Shell 类型的 Task 可能无法正确继承或设置某些环境变量
- 这导致 npm 无法正确识别和加载 ARM64 平台特定的依赖

## 解决方案

修改 `.vscode/tasks.json` 中的任务配置，将 `type` 从 `"shell"` 改为 `"process"`：

### 修改前（问题配置）

```json
{
  "label": "start_local_docs_server",
  "detail": "启动本地文档服务器（自动运行）",
  "type": "shell",
  "command": "npm run dev",
  "isBackground": true,
  "options": {
    "cwd": "${workspaceFolder}/docs"
  }
}
```

### 修改后（正确配置）

```json
{
  "label": "start_local_docs_server",
  "detail": "启动本地文档服务器（自动运行）",
  "type": "process",
  "command": "npm",
  "args": ["run", "dev"],
  "isBackground": true,
  "options": {
    "cwd": "${workspaceFolder}/docs"
  }
}
```

## 关键差异

| 属性     | Shell 类型                      | Process 类型       |
| -------- | ------------------------------- | ------------------ |
| 执行方式 | 通过 shell 解释器执行命令字符串 | 直接执行进程       |
| 环境继承 | 可能不完整继承环境变量          | 正确继承父进程环境 |
| 命令格式 | 单个命令字符串                  | 命令和参数分离     |

## 其他尝试过但无效的方案

以下方案虽然在其他场景下可能有效，但对于这个特定问题并不是必需的：

1. **npm overrides** - 添加 `"overrides": { "rollup": "npm:@rollup/wasm-node" }`
2. **显式安装 ARM64 包** - 添加 `@rollup/rollup-darwin-arm64` 为依赖
3. **.npmrc 配置** - 各种 npm 配置调整
4. **运行时检查和修复** - 在启动前检查并修复依赖（影响启动速度）

## 推荐的完整解决方案

### 方案一：添加所有平台的可选依赖（推荐 ✅）

**实施时间**：2025年9月28日
**状态**：已在 WorldTourCasino docs 项目中实施并验证

在 `package.json` 中添加所有平台的 Rollup 依赖作为可选依赖：

```json
{
  "optionalDependencies": {
    "@rollup/rollup-darwin-arm64": "^4.52.0",
    "@rollup/rollup-darwin-x64": "^4.52.0",
    "@rollup/rollup-linux-x64-gnu": "^4.52.0",
    "@rollup/rollup-win32-x64-msvc": "^4.52.0"
  },
  "overrides": {
    "rollup": "^4.52.0"
  }
}
```

**优点**：

- 一次配置，永久解决
- 支持所有平台和架构
- 自动适应 Rosetta 2 等混合环境
- npm 会自动选择正确的二进制包

### 方案二：使用修复脚本

创建 `.vitepress/scripts/fix-rollup.sh` 脚本，在遇到问题时快速修复：

```bash
#!/bin/bash
rm -rf node_modules package-lock.json
npm install
```

### 方案三：Shell 解释器差异问题

**发现时间**：2025年9月28日

在某些环境下，bash 和 zsh 执行构建脚本的行为不同：

- **bash**：构建成功 ✅
- **zsh**：可能导致 VitePress 错误地包含子模块文件

**解决方法**：保持构建脚本使用 bash 解释器

### ~~方案四：VS Code Task 配置优化~~

**注意**：此方案对于 Rollup 依赖问题效果有限，主要适用于其他环境变量问题。

## 总结

1. **根本原因**：npm 在处理可选依赖时的 bug，以及不同平台需要不同的二进制包
2. **特殊发现**：M3 Mac 在某些编辑器（如 Trae CN）中可能运行在混合架构环境
3. **最佳实践**：在 package.json 中预先配置所有平台的可选依赖（方案一）
4. **已验证**：2025年9月28日在 WorldTourCasino 项目中成功实施

## 参考信息

- 环境：macOS ARM64 (M1/M2/M3)
- 编辑器：VS Code、Trae CN、Cursor、Windsurf
- Node.js：v23.6.0+
- Node.js：v23.6.0
- VS Code Task API：[官方文档](https://code.visualstudio.com/docs/editor/tasks)
- 相关 npm issue：[#4828](https://github.com/npm/cli/issues/4828)
