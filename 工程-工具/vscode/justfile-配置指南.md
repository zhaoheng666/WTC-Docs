# Justfile 配置指南

## Just 命令系统概述

Just 是一个现代的命令运行器，类似 Make 但更简单易用。本文档详细说明 justfile 的配置选项和最佳实践。

## 全局设置选项

### 1. Shell 配置

```bash
# 设置执行命令的 shell
set shell := ["sh", "-euc"]
```

**Shell 选项说明：**
- `-e` (errexit): 遇到错误立即退出
- `-u` (nounset): 使用未定义变量时报错
- `-c`: 执行字符串命令
- `-x` (xtrace): 调试模式，打印执行的命令
- `-o pipefail`: 管道中任何命令失败都返回错误（bash/zsh）

**性能对比：**
| Shell | 启动时间 | 适用场景 |
|-------|---------|---------|
| sh    | ~0.01s  | 简单命令，最快速度 |
| bash  | ~0.05s  | 需要 bash 特性 |
| zsh   | ~1.2s   | 需要 zsh 特性（如 ARM64 Mac 的 rollup） |

### 2. 环境变量设置

```bash
# 自动加载 .env 文件
set dotenv-load := true

# 导出所有变量到命令环境
set export := true

# 允许位置参数（$1, $2 等）
set positional-arguments := true
```

### 3. 其他设置

```bash
# 设置临时目录
set tempdir := "/tmp"

# Windows 特定设置
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
set windows-powershell := true
```

## 命令配置技巧

### 1. 实时输出 vs 缓冲输出

```bash
# 缓冲输出（脚本执行完后才显示）
task-buffered:
    @echo "This is buffered"
    @command

# 实时输出（立即显示）
task-realtime:
    echo "This is realtime"
    command
```

- **带 `@`**：隐藏命令本身，输出被缓冲
- **不带 `@`**：显示命令，实时输出

### 2. 特定 Shell 使用

```bash
# 全局使用 sh
set shell := ["sh", "-euc"]

# 特定任务使用 zsh
docs-check:
    zsh {{scripts_dir}}/wtc-docs/docs-check-setup.sh

# 特定任务使用 bash
complex-task:
    bash -c 'source ~/.bashrc && complex_command'
```

### 3. 错误处理

```bash
# 忽略错误继续执行
task-ignore-errors:
    -@failing-command
    @echo "Continue even if previous failed"

# 条件执行
task-conditional:
    @test -f file.txt && echo "File exists" || echo "File not found"
```

### 4. 变量使用

```bash
# 定义变量
project_root := env_var_or_default("PROJECT_ROOT", `pwd`)
scripts_dir := project_root + "/.vscode/scripts"

# 使用变量
task:
    @echo "Project: {{project_root}}"
    @echo "Scripts: {{scripts_dir}}"
```

### 5. 依赖和别名

```bash
# 任务依赖
build: clean compile test

# 别名
alias b := build
alias t := test
```

## 最佳实践

### 1. 性能优化

```bash
# ✅ 推荐：使用 sh 作为默认 shell
set shell := ["sh", "-euc"]

# ✅ 推荐：单个 printf 输出多行
info:
    @printf "Line 1\nLine 2\nLine 3\n"

# ❌ 避免：多个 echo 命令
info-slow:
    @echo "Line 1"
    @echo "Line 2"
    @echo "Line 3"
```

### 2. 跨平台兼容

```bash
# 检测操作系统
os := if os() == "windows" { "windows" } else { if os() == "macos" { "macos" } else { "linux" } }

# 条件命令
clean:
    @if [ "{{os}}" = "windows" ]; then \
        del /Q *.tmp; \
    else \
        rm -f *.tmp; \
    fi
```

### 3. 调试支持

```bash
# 调试模式变量
debug := env_var_or_default("DEBUG", "0")

# 条件调试输出
task:
    @if [ "{{debug}}" = "1" ]; then \
        set -x; \
    fi
    @command
```

## ARM64 Mac 特殊考虑

由于 ARM64 Mac 上的 npm/rollup 兼容性问题，某些任务必须使用 zsh：

```bash
# 文档相关任务需要 zsh
check-docs:
    zsh {{scripts_dir}}/wtc-docs/check-docs-setup.sh

# 其他任务使用 sh 以提高性能
status:
    @printf "Checking status...\n"
```

## 常见问题

### Q: 为什么命令执行很慢？
A: 检查是否使用了 zsh。zsh 启动需要 ~1.2s，改用 sh 可以降到 ~0.01s。

### Q: 为什么输出不是实时的？
A: 带 `@` 前缀的命令会缓冲输出。去掉 `@` 可以实时输出。

### Q: 如何在不同任务间共享代码？
A: 使用函数定义或引入共享脚本：

```bash
# 定义共享函数
_log := "printf '[%s] %s\n' \"$(date +%H:%M:%S)\""

task1:
    @{{_log}} "Task 1 starting"

task2:
    @{{_log}} "Task 2 starting"
```

## 相关文档

- [Shell 脚本规范](./shell-脚本规范.md)
- [脚本系统重构](./脚本系统重构-zx-just.md)
- [VS Code 环境工具开发规范](./vscode环境工具开发规范.md)