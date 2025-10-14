# 符号链接管理规则

**适用范围**: 仅 extensions 子项目

本文件定义 VS Code 扩展的符号链接管理机制。

---

## 安装位置

扩展通过符号链接（symlink）安装到多个 VS Code 兼容编辑器的扩展目录：

| 编辑器 | 扩展目录 |
|--------|---------|
| VS Code | `~/.vscode/extensions/` |
| Trae Code | `~/.trae/extensions/` |
| Windsurf | `~/.windsurf/extensions/` |
| Cursor | `~/.cursor/extensions/` |

---

## 自动化安装流程

### 1. 主项目 onEnter.sh

打开主项目时自动调用：

```bash
# .vscode/scripts/onEnter.sh
.vscode/scripts/fix-environment.sh
```

### 2. extensions/init.sh

编译所有扩展并创建符号链接：

```bash
#!/bin/zsh
set -e

# 进入扩展目录
cd vscode-extensions

# 编译所有扩展
for ext in wtc-*/; do
    echo "Building ${ext}..."
    cd "${ext}"
    npm install
    npm run compile
    cd ..
done

# 创建符号链接
.vscode/scripts/setup-plugin-symlinks.sh
```

### 3. 创建符号链接

```bash
# 遍历所有编辑器目录
for editor_dir in ~/.vscode ~/.trae ~/.windsurf ~/.cursor; do
    if [ -d "${editor_dir}/extensions" ]; then
        # 创建符号链接
        ln -sf /path/to/vscode-extensions/wtc-toolbars \
               ${editor_dir}/extensions/wtc-toolbars
    fi
done
```

---

## 手动管理

### 创建符号链接

```bash
# 进入扩展目录
cd vscode-extensions

# 为 VS Code 创建链接
ln -sf $(pwd)/wtc-toolbars ~/.vscode/extensions/wtc-toolbars

# 为 Trae Code 创建链接
ln -sf $(pwd)/wtc-toolbars ~/.trae/extensions/wtc-toolbars
```

### 删除符号链接

```bash
# 删除 VS Code 的链接
rm ~/.vscode/extensions/wtc-toolbars

# 删除 Trae Code 的链接
rm ~/.trae/extensions/wtc-toolbars
```

### 验证符号链接

```bash
# 查看 VS Code 扩展目录
ls -la ~/.vscode/extensions/ | grep wtc

# 查看 Trae Code 扩展目录
ls -la ~/.trae/extensions/ | grep wtc
```

---

## 配置管理

### .vscode/settings.json

扩展配置存储在 `.vscode/settings.json` 的 `WTC.subProjects.extensions.plugins` 中：

```json
{
  "WTC.subProjects": {
    "extensions": {
      "plugins": {
        "toolbar": {
          "name": "wtc-toolbars",
          "symlinkName": "wtc-toolbars"
        },
        "docsServer": {
          "name": "wtc-docs-server",
          "symlinkName": "wtc-docs-server",
          "autoStart": true,
          "showStatusBar": true
        }
      }
    }
  }
}
```

### 配置字段说明

| 字段 | 说明 | 示例 |
|------|------|------|
| `name` | 扩展名称 | `wtc-toolbars` |
| `symlinkName` | 符号链接名称 | `wtc-toolbars` |
| `autoStart` | 是否自动启动（可选） | `true` |
| `showStatusBar` | 是否显示状态栏（可选） | `true` |

---

## 清理脚本

### cleanup-plugin-symlinks.sh

删除所有 WTC 扩展的符号链接：

```bash
#!/bin/zsh

# 遍历所有编辑器目录
for editor_dir in ~/.vscode ~/.trae ~/.windsurf ~/.cursor; do
    if [ -d "${editor_dir}/extensions" ]; then
        # 删除 WTC 扩展链接
        find "${editor_dir}/extensions" -type l -name "wtc-*" -delete
    fi
done

echo "Cleanup completed"
```

### 执行清理

```bash
.vscode/scripts/cleanup-plugin-symlinks.sh
```

---

## 故障排查

### 符号链接问题

**检查符号链接是否存在**:
```bash
ls -la ~/.vscode/extensions/ | grep wtc
```

**重新创建符号链接**:
```bash
# 清理旧链接
.vscode/scripts/cleanup-plugin-symlinks.sh

# 重新初始化
cd vscode-extensions
./init.sh
```

### 扩展未显示

**原因**: 符号链接未正确创建或损坏

**解决方案**:
1. 删除旧符号链接
2. 重新编译扩展
3. 重新创建符号链接
4. 重载 VS Code 窗口

### 权限问题

**问题**: 无法创建符号链接

**解决方案**:
```bash
# 检查权限
ls -la ~/.vscode/extensions/

# 修复权限（如果需要）
chmod -R u+w ~/.vscode/extensions/
```

---

**最后更新**: 2025-10-13
**维护者**: WTC-Extensions Team
