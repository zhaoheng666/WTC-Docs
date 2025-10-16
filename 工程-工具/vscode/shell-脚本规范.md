# Shell 脚本规范

## 解释器选择规则

### 默认使用 zsh 解释器

**规定时间**：2025年9月29日

**适用范围**：
- 所有新建的 shell 脚本
- justfile 配置
- VS Code 任务脚本

**原因**：
1. **ARM64 Mac 兼容性**：zsh 在处理 npm 模块路径时更稳定
2. **解决 rollup 依赖问题**：避免 `@rollup/rollup-darwin-arm64` 找不到的问题
3. **macOS 默认 shell**：macOS Catalina 后默认使用 zsh

### 实施规范

#### 1. Shell 脚本
```bash
#!/bin/zsh
# 脚本内容
```

#### 2. Justfile 配置
```bash
# 设置 shell 选项
set shell := ["zsh", "-euo", "pipefail", "-c"]
```

#### 3. VS Code 任务
```json
{
  "type": "shell",
  "options": {
    "shell": {
      "executable": "/bin/zsh",
      "args": ["-c"]
    }
  }
}
```

### 例外情况

仅在以下情况可以使用 bash：
1. 需要跨平台兼容（Linux 服务器）
2. 依赖特定的 bash 功能
3. 第三方脚本要求

### 已验证的问题解决

1. **Rollup 平台依赖问题**
   - 问题：使用 bash 时无法找到 ARM64 依赖
   - 解决：改用 zsh 后问题自动解决
   - 相关文档：[vscode-rollup-arm64-issue.md](/故障排查/vscode-rollup-arm64-issue)

2. **npm 模块路径解析**
   - 问题：bash 环境下 npm 模块路径解析异常
   - 解决：zsh 能正确处理模块路径

## 模块化架构

### 基础函数库

所有脚本应引入通用基础函数库：

```bash
#!/bin/zsh
# 引入基础函数库
source "$(dirname "${BASH_SOURCE[0]}")/common/base.sh"
```

### 函数库功能

`common/base.sh` 提供：
- 统一的日志函数
- 进程管理工具
- 文件操作辅助
- 环境检测功能
- 错误处理机制

### 脚本组织结构

```
.vscode/scripts/
├── common/
│   ├── base.sh           # 基础函数库
│   └── config-reader.sh  # 配置读取器
├── wtc-docs/             # 文档相关脚本
├── cleanup-services.sh   # 服务清理
├── onEnter.sh           # 项目初始化
└── justfile             # 任务编排
```

## 最佳实践

1. **使用 zsh 作为默认解释器**
2. **引入 common/base.sh 复用代码**
3. **使用 justfile 组织任务**
4. **保持脚本简洁，专注业务逻辑**
5. **统一日志格式和错误处理**

## 相关文档

- [故障排查：Rollup ARM64 问题](/故障排查/vscode-rollup-arm64-issue)
- [VS Code 环境工具开发规范](/工程-工具/vscode/vscode环境工具开发规范)