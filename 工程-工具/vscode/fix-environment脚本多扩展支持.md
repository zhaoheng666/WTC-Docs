# fix-environment.sh 环境管理系统

## 更新时间
2025-01-11

## 重要提示
⚠️ **本文档描述的是 2025-01 重构后的架构**

如需查看历史版本信息，请参考 Git 历史记录。

## 背景
环境管理系统经历了多次迭代：
1. **初版**：只支持单个扩展和两个编辑器
2. **多扩展支持**（2024-09）：支持多个扩展和五个编辑器
3. **架构重构**（2025-01）：职责分离、模块化设计 ✨当前版本

## 当前架构（2025-01重构版）

### 1. 核心脚本和模块

#### 主要脚本
- **onEnter.sh** - 环境检查器（纯检查，不执行修复）
- **check-environment.sh** - 环境完整性检查
- **fix-environment.sh** - 环境修复流程编排器（纯编排，调用模块）

#### 功能模块（env-tools/）
- **env-control.sh** - 环境控制和流程管理
- **system-tools.sh** - 系统工具安装
- **subprojects.sh** - 子项目管理
- **npm-deps.sh** - NPM 依赖管理
- **plugin-links.sh** - 插件链接管理

### 2. 支持的扩展
所有扩展配置从 `settings.json` 的 `WTC.subProjects.extensions.plugins` 读取：

- **wtc-toolbar** - WorldTourCasino 工具栏扩展
- **wtc-local-server** - 本地开发服务器扩展
- **wtc-docs-server** - 文档服务器管理扩展
- **wtc-google-drive** - Google Drive 上传扩展

### 3. 支持的编辑器
- **VSCode** - `~/.vscode/extensions`
- **Trae** - `~/.trae/extensions`
- **Trae-CN** - `~/.trae-cn/extensions`
- **Windsurf** - `~/.windsurf/extensions`
- **Cursor** - `~/.cursor/extensions`

### 4. 关键特性

#### 职责分离
```
检查器 (onEnter.sh)
  ├── 检查环境完整性
  ├── 弹窗询问用户
  └── 创建环境验证标记

编排器 (fix-environment.sh)
  ├── 参数解析
  ├── 调用高级流程函数
  └── 显示最终结果

控制器 (env-control.sh)
  ├── 环境验证标记管理
  ├── 通知管理
  └── 高级流程封装

执行器 (各功能模块)
  └── 具体任务实现
```

#### 环境验证机制
```bash
# 检查环境 → 创建标记
.vscode/.env-verified

# 插件启动时检查标记
if (isEnvironmentVerified()) {
    // 允许自动启动
}
```

#### 配置驱动
```typescript
// 从配置读取扩展信息
const plugins = settings["WTC.subProjects"].extensions.plugins;

// 动态处理所有插件
for (const [key, config] of Object.entries(plugins)) {
    setupPlugin(config.name, config.symlinkName);
}
```

## 使用方法

### 基本用法
```bash
# 完整修复（推荐）
./.vscode/scripts/fix-environment.sh

# 快速修复（只更新子项目，不删除重建）
./.vscode/scripts/fix-environment.sh --quick

# 查看帮助
./.vscode/scripts/fix-environment.sh --help
```

### 高级用法
```bash
# 仅安装系统工具
./.vscode/scripts/fix-environment.sh --system

# 仅处理子项目
./.vscode/scripts/fix-environment.sh --subprojects

# 仅安装依赖
./.vscode/scripts/fix-environment.sh --deps

# 仅配置插件链接
./.vscode/scripts/fix-environment.sh --links

# 仅清理（不安装）
./.vscode/scripts/fix-environment.sh --clean
```

### 独立模块使用
```bash
# 单独检查环境
./.vscode/scripts/check-environment.sh

# 单独清理插件
source ./.vscode/scripts/env-tools/plugin-links.sh
cleanup_invalid_symlinks
cleanup_old_plugin_names
```

## 执行效果

### 完整修复输出示例
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  环境修复工具
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[15:04:21] ℹ️  INFO: 项目根目录: /Users/ghost/work/WorldTourCasino
[15:04:21] ℹ️  INFO: 执行模式: all
[15:04:21] ✅ SUCCESS: 配置文件检查通过

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  开始完整修复
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/4] 安装系统工具
[15:04:21] ✅ SUCCESS: terminal-notifier 已安装
[15:04:21] ✅ SUCCESS: Just 已安装: just 1.43.0
[15:04:21] ✅ SUCCESS: Git Hooks 安装成功

[2/4] 初始化子项目
[15:04:22] ℹ️  INFO: [1/2] 删除已存在的 docs
[15:04:22] ℹ️  INFO: [1/2] 克隆: docs
    Cloning into 'docs'...
[15:04:25] ℹ️  INFO: [2/2] 删除已存在的 extensions
[15:04:25] ℹ️  INFO: [2/2] 克隆: extensions
    Cloning into 'vscode-extensions'...
[15:04:28] ✅ SUCCESS: 子项目初始化完成 (成功: 2/2)

[3/4] 重置依赖
[15:04:28] ℹ️  INFO: 安装 主项目 的依赖
    added 245 packages in 15s
[15:04:43] ✅ SUCCESS: 主项目 依赖安装成功

[4/4] 配置插件
[15:04:43] ℹ️  INFO: 清理无效的符号链接
[15:04:43] ℹ️  INFO: 清理旧插件名称
[15:04:43] ℹ️  INFO: [1/4] 处理插件: toolbar
[15:04:43] ✅ SUCCESS:   VS Code: 链接创建成功
[15:04:43] ✅ SUCCESS:   Trae: 链接创建成功
[15:04:43] ✅ SUCCESS: 环境验证标记已创建

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  修复完成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[15:04:44] ✅ SUCCESS: 环境修复已完成！
[15:04:44] ℹ️  INFO: 请重新打开项目以应用更改
```

## 相关文件
- 脚本位置：[.vscode/scripts/fix-environment.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/scripts/fix-environment.sh)
- 扩展仓库：https://github.com/zhaoheng666/WTC-extensions.git
- 配置文件：[.vscode/settings.json](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/settings.json)

## 注意事项
1. 扩展信息目前硬编码在脚本中，添加新扩展需要手动更新 `EXTENSIONS` 数组
2. 编辑器目录路径遵循各编辑器的标准扩展目录规范
3. 脚本使用符号链接，需要文件系统支持
4. 首次运行会克隆整个 vscode-extensions 仓库，需要 git 访问权限