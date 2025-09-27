# Settings.json 配置读取规范

## 概述

项目中所有需要读取 `.vscode/settings.json` 配置的脚本都应该使用统一的配置读取器 `config-reader.sh`。

## 核心文件

**配置读取器**：[.vscode/scripts/common/config-reader.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/scripts/common/config-reader.sh)

## 为什么使用 config-reader.sh

1. **支持带注释的 JSON**
   - VS Code 的 settings.json 支持注释（`//` 和 `/* */`）
   - 标准的 JSON 解析工具不支持注释
   - config-reader.sh 使用 Node.js 预处理，自动移除注释

2. **统一的接口**
   - 提供标准化的函数接口
   - 避免代码重复
   - 便于维护和更新

3. **不依赖外部工具**
   - 仅使用 Node.js（项目必需）
   - 不需要安装额外的 JSON 处理工具（如 jq、node-jq）

## 使用方法

### 1. 在脚本中引入配置读取器

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# 加载配置读取器
source "$SCRIPT_DIR/common/config-reader.sh"
```

### 2. 使用预定义的函数

```bash
# 获取 docs 子项目配置
docs_git=$(get_docs_git)
docs_path=$(get_docs_path)

# 获取 extensions 子项目配置
extensions_git=$(get_extensions_git)
extensions_path=$(get_extensions_path)

# 获取插件配置
plugin_name=$(get_plugin_name "toolbar")
plugin_symlink=$(get_plugin_symlink "toolbar")
```

### 3. 读取自定义配置

```bash
# 读取任意子项目配置
custom_value=$(get_subproject_config "项目名" "配置键")

# 读取插件的任意配置
plugin_value=$(get_plugin_config "插件键" "配置键")
```

## 可用函数列表

### 基础函数
- `get_project_root()` - 获取项目根目录
- `get_subproject_config(project_name, config_key)` - 读取子项目配置
- `check_config()` - 检查配置是否可用

### Docs 相关
- `get_docs_git()` - 获取 docs 仓库地址
- `get_docs_path()` - 获取 docs 路径
- `get_docs_setup_script()` - 获取设置脚本路径
- `get_docs_setup_marker()` - 获取设置标记文件
- `get_docs_script(script_name)` - 获取 docs 脚本路径
- `get_sync_docs_script()` - 获取同步脚本路径
- `get_check_docs_setup_script()` - 获取检查设置脚本路径

### Extensions 相关
- `get_extensions_git()` - 获取扩展仓库地址
- `get_extensions_path()` - 获取扩展路径
- `get_plugin_config(plugin_key, config_key)` - 读取插件配置
- `get_plugin_name(plugin_key)` - 获取插件名称
- `get_plugin_symlink(plugin_key)` - 获取插件软链接名

## 技术细节

### JSON 注释处理

config-reader.sh 在解析 JSON 前会自动移除注释：

```javascript
// 移除单行注释
content = content.replace(/\/\/.*$/gm, '');
// 移除多行注释
content = content.replace(/\/\*[\s\S]*?\*\/g, '');
```

### 错误处理

- 配置不存在时，函数会退出（exit code 1）
- 调用方应检查返回值是否为空

```bash
plugin_name=$(get_plugin_name "$plugin_key")
if [ -z "$plugin_name" ]; then
    echo "Plugin configuration not found"
    exit 1
fi
```

## 历史记录

### 2025-01-27：统一配置读取方式

**问题**：
- 最初尝试使用 npm 的 `jq` 包，但它实际是 jQuery wrapper
- 改用 `node-jq`，但不支持带注释的 JSON
- 多个脚本重复实现 JSON 解析逻辑

**解决方案**：
- 统一使用 `config-reader.sh` 作为配置读取器
- 使用 Node.js 原生方式处理带注释的 JSON
- 移除不必要的依赖（jq、node-jq）

## 相关文件

- [onEnter.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/scripts/onEnter.sh) - 项目启动脚本
- [fix-environment.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/scripts/fix-environment.sh) - 环境修复脚本

## 注意事项

1. **不要直接解析 settings.json**
   - 始终使用 config-reader.sh
   - 避免重复代码和维护问题

2. **扩展 config-reader.sh**
   - 新的配置需求应在 config-reader.sh 中添加函数
   - 保持函数命名规范一致

3. **依赖检查**
   - config-reader.sh 会自动检查 Node.js 是否可用
   - 项目必须有 Node.js 环境