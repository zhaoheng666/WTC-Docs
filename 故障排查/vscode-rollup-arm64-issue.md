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

**更新（2025年9月29日）**：发现真正的根本原因是 **shell 解释器的差异**：

- 使用 `#!/bin/zsh` 作为脚本解释器时，rollup 依赖能正常工作 ✅
- 使用 `#!/bin/bash` 作为脚本解释器时，会导致 rollup 无法找到 ARM64 平台特定的依赖 ❌
- 这是因为 zsh 和 bash 在处理 npm 的环境变量和模块解析路径时存在差异，zsh 能更好地处理 ARM64 Mac 的环境

### 历史误诊（已废弃）

之前认为问题的根本原因是 VS Code Task 的 `type` 配置，但实际测试表明这并非真正原因：

- ~~当 Task 类型设置为 `"shell"` 时，VS Code 创建的 shell 环境与普通终端环境存在差异~~
- ~~Shell 类型的 Task 可能无法正确继承或设置某些环境变量~~
- ~~这导致 npm 无法正确识别和加载 ARM64 平台特定的依赖~~

## 解决方案

### 主要解决方案：修改脚本解释器

将所有相关脚本的解释器从 `#!/bin/bash` 改为 `#!/bin/zsh`：

```bash
# 错误的配置（会导致 rollup 依赖问题）
#!/bin/bash

# 正确的配置（ARM64 Mac 环境）
#!/bin/zsh
```

**需要修改的脚本**：
- `.vscode/scripts/wtc-docs/check-docs-setup.sh` - 已修改为 zsh ✅
- `.vitepress/scripts/dev.sh` - 已使用 zsh ✅
- 其他启动文档服务的脚本

### 备用解决方案（已验证但非必要）

以下方案在某些情况下也可以解决问题，但修改解释器是最简单直接的方案：

#### 1. 修改 VS Code Task 配置

将 `.vscode/tasks.json` 中的任务配置，从 `"shell"` 类型改为 `"process"` 类型：

```json
// 使用 process 类型可以绕过 shell 解释器问题
{
  "label": "start_local_docs_server",
  "type": "process",
  "command": "npm",
  "args": ["run", "dev"],
  "options": {
    "cwd": "${workspaceFolder}/docs"
  }
}
```

#### 2. 环境检测和自动修复

在脚本中添加 ARM64 依赖检测和自动修复逻辑：

```bash
# ARM64 Mac 需要特殊处理 rollup 依赖
if [[ "$OSTYPE" == darwin* ]] && [[ $(uname -m) == "arm64" ]]; then
    if ! npm list @rollup/rollup-darwin-arm64 >/dev/null 2>&1; then
        echo "修复 ARM64 依赖..."
        rm -rf node_modules package-lock.json
        npm install
    fi
fi
```

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

### ~~方案三：Shell 解释器差异问题~~ （已作为主要解决方案）

**发现时间**：2025年9月28日
**更新时间**：2025年9月29日 - 提升为主要解决方案

详见上方主要解决方案部分。

### ~~方案四：VS Code Task 配置优化~~

**注意**：此方案对于 Rollup 依赖问题效果有限，主要适用于其他环境变量问题。

## 总结

1. **根本原因**：**shell 解释器差异** - bash 和 zsh 在处理 npm 模块路径时的行为不同（2025年9月29日更新）
2. **最简单的解决方案**：将脚本解释器从 `#!/bin/bash` 改为 `#!/bin/zsh`（ARM64 Mac 环境）
3. **npm bug 相关**：虽然 npm 确实存在可选依赖的 bug，但在本案例中，解释器差异才是主因
4. **特殊发现**：
   - M3 Mac 在某些编辑器（如 Trae CN）中可能运行在混合架构环境
   - zsh 在 ARM64 Mac 上对 npm 模块解析的兼容性更好
5. **最佳实践**：
   - ARM64 Mac 环境优先使用 zsh 作为脚本解释器
   - 在 package.json 中预先配置所有平台的可选依赖作为保险
6. **已验证**：
   - 2025年9月28日：在 WorldTourCasino 项目中发现问题
   - 2025年9月29日：确认 zsh 解释器解决了 rollup 依赖问题，已应用到 check-docs-setup.sh

## 相关改进

### 2025年9月29日 - 脚本重构尝试与回退

尝试使用 zx (Google 的 shell 脚本 JavaScript 化工具) 重构所有 shell 脚本，但发现：

1. **过度工程化**：简单的 shell 任务被复杂的 JavaScript 模块系统包装
2. **可读性下降**：原本直观的 shell 命令变成了层层封装的函数调用
3. **维护成本增加**：需要理解额外的抽象层和依赖关系

**结论**：不是所有脚本都适合 JavaScript 化。对于系统级任务和简单的自动化脚本，shell 脚本更加直观和高效。最终决定保持原有的 shell 脚本架构。

## 参考信息

- 环境：macOS ARM64 (M1/M2/M3)
- 编辑器：VS Code、Trae CN、Cursor、Windsurf
- Node.js：v23.6.0+
- Node.js：v23.6.0
- VS Code Task API：[官方文档](https://code.visualstudio.com/docs/editor/tasks)
- 相关 npm issue：[#4828](https://github.com/npm/cli/issues/4828)
