# VSCode 工具和扩展文档

本目录包含 WorldTourCasino 项目的 VSCode 相关工具、扩展和配置文档。

## 📋 目录结构

### 扩展开发
- [扩展开发规则与最佳实践](./扩展开发规则与最佳实践.md) - VSCode 扩展开发的核心规则和经验总结
- [Google Drive 上传](./google-drive-upload.md) - Google Drive 上传功能文档
- [fix-environment 脚本多扩展支持](./fix-environment脚本多扩展支持.md) - 环境修复脚本的多扩展多编辑器支持实现

### 项目扩展
- **wtc-toolbar** - WorldTourCasino 工具栏扩展
  - 提供快速构建、运行、部署等功能
  - 版本：0.0.1

- **google-drive-uploader** - Google Drive 上传扩展
  - 支持文件上传到 Google Drive
  - OAuth2 自动认证
  - 版本：0.0.1

## 扩展仓库
- GitHub: https://github.com/zhaoheng666/WTC-extensions.git
- 本地路径: `/Users/ghost/work/WorldTourCasino/vscode-extensions/`

## 支持的编辑器
1. **VSCode** - Visual Studio Code
2. **Trae** - Trae 编辑器
3. **Trae-CN** - Trae 中文版（注意：目录是 `.trae-cn`）
4. **Windsurf** - Windsurf 编辑器
5. **Cursor** - Cursor 编辑器

## 快速开始

### 安装扩展
```bash
# 运行环境修复脚本（会自动安装所有扩展到所有支持的编辑器）
bash .vscode/scripts/fix-environment.sh
```

### 开发新扩展
1. 在 `vscode-extensions/` 目录创建新扩展目录
2. 初始化扩展项目：`yo code`
3. 更新 `fix-environment.sh` 中的 `EXTENSIONS` 数组
4. 添加激活条件限制扩展仅在 WTC 项目中激活

### 调试扩展
```bash
# 检查扩展链接状态
ls -la ~/.vscode/extensions/ | grep wtc

# 查看所有编辑器的扩展
for editor in .vscode .trae .trae-cn .windsurf .cursor; do
    echo "=== $editor ==="
    ls -la ~/$editor/extensions/ | grep -E "wtc|google" 2>/dev/null
done
```

## 重要提醒
- vscode-extensions 是独立的 Git 仓库，不是子模块
- 扩展通过符号链接安装，不会污染全局环境
- 敏感配置应使用本地配置文件（如 `.local.json`）
- 提交代码时注意三个独立仓库：主项目、docs、vscode-extensions

## 相关故障排查
- [VSCode 扩展工作区兼容性问题](../../故障排查/vscode-扩展工作区兼容性问题.md)