# Shell 脚本规范

**适用范围**: 仅 WorldTourCasino 主项目

**生效日期**: 2025年9月29日起

---

## 默认解释器

### 规则

**所有新建的 shell 脚本必须使用 zsh 作为解释器**

```bash
#!/bin/zsh
```

### 原因

1. **npm 模块路径解析更稳定**

   - zsh 环境下 Node.js 模块路径解析更可靠
3. **macOS 默认 shell**

   - macOS Catalina (10.15) 之后，系统默认 shell 从 bash 改为 zsh

---

## 脚本编写规范

### Shebang（解释器声明）

明确指定解释器：

```bash
#!/bin/zsh
```

或

```bash
#!/bin/bash
```

### 错误处理

使用 `set -e` 在命令失败时退出：

```bash
#!/bin/zsh
set -e  # 遇到错误立即退出

# 你的脚本内容...
```

### 变量引用

使用 `"${var}"` 而不是 `$var`：

```bash
# ❌ 不推荐
file_path=$1
echo $file_path

# ✅ 推荐
file_path="$1"
echo "${file_path}"
```

### 路径处理

使用绝对路径或 `$(dirname "$0")` 获取脚本目录：

```bash
#!/bin/zsh

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 使用绝对路径
cd "${SCRIPT_DIR}"
```

---

## Justfile 配置

Justfile 也应使用 zsh：

```bash
# 设置默认 shell
set shell := ["zsh", "-cu"]

# 任务定义
build:
    echo "Building project..."
    npm run build
```

---

## 相关文档

详细说明请参考: [Shell 脚本规范](../../vscode/shell-脚本规范)

---

**最后更新**: 2025-10-13
**维护者**: WorldTourCasino Team
