# 近期 VS Code 配置优化总结

## 概述

本文档总结了最近对 WorldTour Casino 项目的 VS Code 配置进行的系列优化工作，包括脚本整理、任务扩展化改造、服务管理机制优化等。

## 主要工作成果

### 1. VS Code 脚本整理与重构

#### 1.1 目录结构优化
- **合并公共目录**：将 `.vscode/common` 目录合并到 `scripts/common`，统一脚本管理位置
- **Git hooks 重构**：重新组织 git hooks 目录结构，提高可维护性

#### 1.2 新增核心脚本
- **cleanup-services.sh**：服务清理脚本
  - 自动停止所有运行的服务（文档服务器、本地服务器等）
  - 在 VS Code reload 前执行，防止进程残留
  - 清理锁文件和孤立进程

- **onEnter.sh 优化**：
  - 添加延时机制，确保服务清理完成
  - 改进扩展自动安装逻辑
  - 支持多个编辑器的扩展同步（VS Code、Cursor、Windsurf、Trae等）

### 2. 任务扩展化改造

#### 2.1 创建独立的 VS Code 扩展

##### wtc-docs-server 扩展
**功能特性**：
- 专门管理 VitePress 文档服务器
- 使用 VS Code Terminal API 保持与 vitepress 的实时交互
- 自动启动、端口管理、状态监控

**交互优化**：
- **QuickPick 菜单**：点击状态栏弹出功能菜单
  - 重启服务器（自动打开浏览器）
  - 同步到 GitHub Pages
  - 在新窗口打开 docs
  - 聚焦终端
- **Markdown 富文本悬停提示**：
  - 显示服务器状态、端口、路径
  - 提供可点击的快捷操作链接
- **优化的消息通知**：减少冗余提示，只在关键时刻通知

##### wtc-local-server 扩展优化
- 统一状态栏风格，与 docs-server 保持一致
- 使用 Markdown 格式的悬停提示
- 停止状态时提供快速启动链接
- 改进状态显示格式

##### wtc-toolbar-extension
- 提供项目快捷操作工具栏
- 集成热更新、构建、运行等常用功能

##### google-drive-uploader 扩展
- 实现文件上传到 Google Drive
- 与项目构建流程集成

#### 2.2 扩展管理机制

**自动安装机制**：
- 通过 `settings.json` 的 `WTC.subProjects.extensions.plugins` 配置扩展列表
- `onEnter.sh` 脚本自动创建符号链接到各编辑器扩展目录
- 支持多编辑器同步（VS Code、Cursor、Windsurf、Trae、TraeCN）

**配置示例**（.vscode/settings.json）：
```json
{
  "WTC": {
    "subProjects": {
      "extensions": {
        "plugins": {
          "docsServer": {
            "name": "wtc-docs-server",
            "symlinkName": "wtc-docs-server"
          },
          "toolbar": {
            "name": "vscode-toolbar-extension",
            "symlinkName": "vscode-toolbar-extension"
          }
        }
      }
    }
  }
}
```

### 3. 服务管理机制优化

#### 3.1 生命周期管理
- **启动时**：自动运行 `onEnter.sh`，安装扩展，启动必要服务
- **运行中**：通过扩展状态栏实时监控服务状态
- **重载前**：执行 `cleanup-services.sh` 清理所有服务
- **关闭时**：扩展的 `deactivate` 方法确保服务正确停止

#### 3.2 端口管理
- 自动检测端口占用
- 智能清理占用进程
- 支持自定义端口配置

### 4. 配置参数化

#### 4.1 全面配置化
将 `.vscode` 目录中的硬编码参数全部提取到 `settings.json`：
- 文档路径、脚本路径
- 扩展配置
- 服务端口
- 构建参数

#### 4.2 变量替换机制
支持在配置中使用变量：
- `${workspaceFolder}` - 工作区根目录
- `${config:*}` - 引用其他配置项

### 5. 插件命名规范化（2025-01-11）

#### 5.1 统一命名规范
将所有 VS Code 插件统一使用 `wtc-` 前缀命名：
- `vscode-toolbar-extension` → `wtc-toolbars`
- `google-drive-uploader` → `wtc-google-drive`
- 新插件必须使用 `wtc-` 前缀

#### 5.2 自动清理机制
- 在 `onEnter.sh` 中添加了旧插件软链接清理功能
- 创建了独立的清理脚本 `cleanup-plugin-symlinks.sh`
- 自动检测并移除无效的软链接

### 6. 端口配置集中管理（2025-01-11）

#### 6.1 配置统一管理
将 wtc-local-server 的端口配置移到统一位置：
```json
{
  "WTC.subProjects": {
    "extensions": {
      "plugins": {
        "localServer": {
          "port": 3307  // 统一配置端口
        }
      }
    }
  }
}
```

#### 6.2 脚本动态读取
更新了所有相关脚本，从配置动态读取端口：
- **config-reader.sh**: 新增 `get_local_server_port()` 函数
- **cleanup-services.sh**: 动态读取端口停止服务
- **open-dev.sh**: 动态读取端口打开浏览器
- **justfile**: status 命令动态显示端口

#### 6.3 插件兼容性
wtc-local-server 插件支持两种配置方式：
- 优先读取 `WTC.subProjects.extensions.plugins.localServer.port`
- 备选方案：传统的 `wtc-local-server.port` 配置

#### 6.4 清理无用配置
移除了 `settings.json` 中已废弃的 `folders` 配置，该配置已被本地配置文件替代。

### 7. 文档建设

#### 7.1 新增文档
- [添加新VS Code扩展规范](./添加新VS Code扩展规范.md)
- [插件命名规范](./插件命名规范.md)
- [VS Code 配置优化总结](./近期VS Code配置优化总结.md)（本文档）

#### 7.2 文档更新
- 更新了扩展的 README 文档
- 完善了故障排查指南
- 记录了配置集中管理方案

## 技术亮点

### 1. 扩展化架构
- 将原本的 tasks.json 任务转化为独立扩展
- 提供更好的用户界面和交互体验
- 支持更复杂的逻辑和状态管理

### 2. 统一的用户体验
- 所有服务扩展使用一致的状态栏风格
- 统一的 Markdown 悬停提示格式
- 一致的交互模式（QuickPick 菜单）

### 3. 自动化程度高
- 扩展自动安装和更新
- 服务自动启动和清理
- 端口冲突自动处理

### 4. 跨编辑器支持
- 不仅支持 VS Code
- 同时支持 Cursor、Windsurf、Trae 等基于 VS Code 的编辑器
- 一次配置，多处使用

## 使用指南

### 快速开始
1. 打开项目，扩展会自动安装
2. 查看状态栏了解服务状态
3. 点击状态栏或使用悬停提示中的快捷操作

### 常用操作
- **文档服务器**：点击状态栏 "Docs: Running/Stopped"
- **本地服务器**：点击状态栏 "Local: Running/Stopped"
- **同步文档**：QuickPick 菜单中选择"同步"或悬停提示中点击"同步"
- **工具栏操作**：使用编辑器顶部的工具栏按钮

### 故障排查
1. **扩展未安装**：手动运行 `./.vscode/scripts/onEnter.sh`
2. **服务无法启动**：检查端口占用，查看终端输出
3. **状态栏不显示**：重新加载窗口（Cmd+R）

## 后续规划

### 短期目标
1. 继续优化扩展的性能和稳定性
2. 添加更多配置选项
3. 改进错误处理和日志记录

### 长期目标
1. 开发更多专用扩展
2. 建立扩展市场发布机制
3. 实现更智能的自动化功能

## 相关文件

### 核心脚本
- [.vscode/scripts/onEnter.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/.vscode/scripts/onEnter.sh)
- [.vscode/scripts/cleanup-services.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/.vscode/scripts/cleanup-services.sh)

### 扩展源码
- [vscode-extensions/wtc-docs-server/](https://github.com/zhaoheng666/WTC-extensions/tree/main/wtc-docs-server)
- [vscode-extensions/wtc-local-server/](https://github.com/zhaoheng666/WTC-extensions/tree/main/wtc-local-server)
- [vscode-extensions/vscode-toolbar-extension/](https://github.com/zhaoheng666/WTC-extensions/tree/main/vscode-toolbar-extension)

### 配置文件
- [.vscode/settings.json](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/.vscode/settings.json)
- [.vscode/tasks.json](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/.vscode/tasks.json)

## 总结

通过这一系列的优化工作，我们成功地：
1. 将 VS Code 配置从简单的任务配置升级为功能丰富的扩展生态
2. 实现了服务的自动化管理和智能监控
3. 统一了用户体验，提升了开发效率
4. 建立了可扩展的架构，为未来的功能增强打下基础

这些改进显著提升了开发体验，减少了手动操作，让开发者能够更专注于核心业务逻辑的开发。