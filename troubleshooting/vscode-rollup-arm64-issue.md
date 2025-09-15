# VS Code Task 类型导致的 Rollup ARM64 依赖问题

## 问题描述

在 ARM64 架构的 Mac（M1/M2/M3）上，使用 VS Code 自动启动 VitePress 开发服务器时，会遇到以下错误：

```
Error: Cannot find module @rollup/rollup-darwin-arm64. 
npm has a bug related to optional dependencies 
(https://github.com/npm/cli/issues/4828)
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

| 属性 | Shell 类型 | Process 类型 |
|------|-----------|-------------|
| 执行方式 | 通过 shell 解释器执行命令字符串 | 直接执行进程 |
| 环境继承 | 可能不完整继承环境变量 | 正确继承父进程环境 |
| 命令格式 | 单个命令字符串 | 命令和参数分离 |

## 其他尝试过但无效的方案

以下方案虽然在其他场景下可能有效，但对于这个特定问题并不是必需的：

1. **npm overrides** - 添加 `"overrides": { "rollup": "npm:@rollup/wasm-node" }`
2. **显式安装 ARM64 包** - 添加 `@rollup/rollup-darwin-arm64` 为依赖
3. **.npmrc 配置** - 各种 npm 配置调整
4. **运行时检查和修复** - 在启动前检查并修复依赖（影响启动速度）

## 总结

这个问题的核心不是 npm 依赖管理或 Rollup 本身的问题，而是 **VS Code Task 执行环境的差异**。使用 `process` 类型可以确保任务在正确的环境中执行，从而避免平台特定依赖的加载问题。

## 参考信息

- 环境：macOS ARM64 (M1/M2/M3)
- Node.js：v23.6.0
- VS Code Task API：[官方文档](https://code.visualstudio.com/docs/editor/tasks)
- 相关 npm issue：[#4828](https://github.com/npm/cli/issues/4828)