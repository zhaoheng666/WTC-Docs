# VSCode 工具和扩展文档

本目录包含 WorldTourCasino 项目的 VSCode 相关工具、扩展和配置文档。

## 📋 目录结构

### 扩展开发
- [扩展开发规则与最佳实践](./扩展开发规则与最佳实践.md) - VSCode 扩展开发的核心规则和经验总结
- [Google Drive 上传](./google-drive-upload.md) - Google Drive 上传功能文档
- [fix-environment 脚本多扩展支持](./fix-environment脚本多扩展支持.md) - 环境修复脚本的多扩展多编辑器支持实现

### 项目扩展

#### 核心扩展
- **wtc-docs-server** - 文档服务器管理扩展 ✨新增
  - 管理 VitePress 文档服务器生命周期
  - QuickPick 菜单提供全功能快速访问
  - Markdown 富文本悬停提示
  - 一键同步到 GitHub Pages
  - 在新窗口打开 docs 功能
  - 版本：0.0.1

- **wtc-local-server** - 本地开发服务器扩展
  - 管理本地 HTTP 服务器
  - 统一的状态栏风格
  - 自动端口管理（默认 3307）
  - 版本：1.0.0

- **wtc-toolbar-extension** - WorldTourCasino 工具栏扩展
  - 提供快速构建、运行、部署等功能
  - 热更新、多风格切换支持
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
# 方法1：项目打开时自动安装（推荐）
# 扩展会在打开项目时通过 onEnter.sh 自动安装

# 方法2：手动运行安装脚本
bash .vscode/scripts/onEnter.sh

# 方法3：运行环境修复脚本（旧版本，仍可用）
bash .vscode/scripts/fix-environment.sh
```

### 开发新扩展
1. 在 `vscode-extensions/` 目录创建新扩展目录
2. 初始化扩展项目：`yo code` 或手动创建
3. 在 `.vscode/settings.json` 的 `WTC.subProjects.extensions.plugins` 中添加扩展配置
4. 更新 `.vscode/scripts/onEnter.sh` 中的 `setup_plugin` 调用
5. 添加激活条件限制扩展仅在 WTC 项目中激活
6. 详细规范参见：[添加新VS Code扩展规范](./添加新VS Code扩展规范.md)

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

## 最新改进

### 环境管理系统重构（2025-01）✨最新

#### 核心改进
- **职责分离架构**：检查器、编排器、控制器、执行器各司其职
- **环境验证机制**：插件只在环境验证完整后启动，避免修复过程中的意外启动
- **模块化设计**：所有功能封装在独立模块中，易于维护和扩展
- **错误修复**：解决 `set -e` 模式下的脚本退出问题

#### 新增功能
- **check-environment.sh** - 独立的环境检查脚本，返回详细的缺失项列表
- **env-control.sh** - 环境控制模块，统一管理验证标记和流程
- **智能初始化** - `init_all_subprojects()` 确保子项目完全干净

#### 代码质量提升
- `onEnter.sh` 精简 68%（277+ 行 → ~90 行）
- `fix-environment.sh` 精简 21%（217 行 → 171 行）
- 所有模块支持独立运行和测试

详见：[环境管理系统重构文档](./环境管理系统重构-2025-01.md)

### 服务管理优化（2024-09）
- 新增 `cleanup-services.sh` 脚本，在 VS Code reload 前自动清理所有服务
- 优化 `onEnter.sh` 脚本，添加延时确保服务清理完成
- 扩展 deactivate 方法确保服务正确停止

### 扩展功能增强（2024-09）
- **wtc-docs-server**: QuickPick 菜单、富文本悬停提示、一键同步 GitHub Pages
- **wtc-local-server**: 统一状态栏风格，停止状态快速启动、环境验证检查
- 所有服务扩展采用统一的 Markdown 悬停提示格式

### 配置管理改进（2024-09）
- 全面配置化 `.vscode` 目录中的参数
- 支持变量替换机制（`${workspaceFolder}`、`${config:*}`）
- 扩展配置集中在 `settings.json` 管理

## 相关文档
- [近期VS Code配置优化总结](./近期VS Code配置优化总结.md)
- [添加新VS Code扩展规范](./添加新VS Code扩展规范.md)
- [VSCode 扩展工作区兼容性问题](../../故障排查/vscode-扩展工作区兼容性问题.md)