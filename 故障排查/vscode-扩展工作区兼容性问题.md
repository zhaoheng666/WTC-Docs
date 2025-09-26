# VSCode 扩展在工作区模式下不显示的问题

## 问题描述

2025-09-27 发现的问题：

- VSCode 扩展（wtc.toolbar 和 wtc.google-drive-uploader）在直接打开项目文件夹时正常工作
- 但使用 `WorldTourCasino.code-workspace` 工作区文件打开项目时，扩展不显示或不生效
- 在 Trae-CN 编辑器中，wtc.google-drive-uploader 显示已安装但按钮不出现，wtc.toolbar 完全不显示

## 问题排查过程（走了很多弯路）

### 1. 初始误判：以为是软链接问题
- **尝试方案**：检查软链接命名格式，发现 `wtc.google-drive-0.0.1` 应该是 `wtc.google-drive-uploader-0.0.1`
- **结果**：修正后问题依旧存在

### 2. 第二次误判：以为是扩展激活逻辑问题
- **尝试方案**：修改扩展代码，从激活时检查改为命令执行时检查 `WTC.is_wtc`
- **结果**：导致所有编辑器中扩展都不生效了

### 3. 第三次误判：以为软链接不被支持
- **尝试方案**：
  - 删除软链接，改为直接复制扩展目录
  - 使用 `vsce package` 创建 .vsix 包并用 `code --install-extension` 安装
- **结果**：VSCode 中显示已安装但仍不生效

### 4. 关键发现
用户发现了真正的问题：
> "我发现问题所在了，不是软链接的问题，而是 WorldTourCasino.code-workspace 的问题，使用工作区时插件不显示，但是单独打开主项目插件是正常可用的"

这个发现直接指向了问题的根源！

## 根本原因

**工作区文件的设置优先级高于项目设置**：

- 当使用 `.code-workspace` 文件打开项目时，其中的 `settings` 会覆盖 `.vscode/settings.json` 中的设置
- 扩展依赖 `WTC.is_wtc` 标志来判断是否在 WorldTourCasino 项目中激活
- 工作区文件中缺少这个标志和其他 WTC 配置，导致扩展无法激活

## 解决方案

### 1. 同步配置到工作区文件

将 `.vscode/settings.json` 中的所有 WTC 相关配置同步到 `WorldTourCasino.code-workspace`：

```json
{
  "settings": {
    // WorldTourCasino 项目标识（用于扩展激活）
    "WTC.is_wtc": true,
    "WTC.subProjects": {
      "docs": { /* ... */ },
      "extensions": {
        "plugins": {
          "toolbar": { /* ... */ },
          "googleDrive": {
            "folders": {
              // Google Drive 文件夹配置
            }
          }
        }
      }
    },
    // 其他设置...
  }
}
```

### 2. 关键配置项

必须同步的关键配置：

- `WTC.is_wtc`: 扩展激活标志
- `WTC.subProjects.extensions.googleDrive.folders`: Google Drive 上传目标文件夹配置

## 经验教训

1. **不要急于修改代码**：很多时候问题不在代码逻辑，而在配置或环境
2. **注意配置文件的优先级**：VSCode 的设置有多个层级，工作区 > 用户 > 默认
3. **测试多种使用场景**：
   - 直接打开文件夹
   - 使用工作区文件
   - 不同的编辑器（VSCode、Trae、Cursor 等）
4. **观察现象找规律**：单独打开正常但工作区不正常，这个现象直接指向了配置差异

## 故障排查步骤

如果扩展仍然不工作：

1. **检查扩展是否已安装**

   ```bash
   code --list-extensions | grep wtc
   ```
2. **验证配置存在**

   - 检查 `.code-workspace` 文件中是否有 `WTC.is_wtc: true`
   - 检查 Google Drive 文件夹配置是否存在
3. **重新加载窗口**

   - `Cmd+Shift+P` → `Developer: Reload Window`
4. **查看扩展控制台**

   - `Help` → `Toggle Developer Tools` → `Console`
   - 查找扩展相关的错误信息

## 预防措施

为避免此类问题再次发生：

1. **保持配置同步**：当修改 `.vscode/settings.json` 中的 WTC 配置时，同步更新 `.code-workspace` 文件
2. **测试两种打开方式**：

   - 直接打开文件夹：`code /path/to/WorldTourCasino`
   - 使用工作区：`code WorldTourCasino.code-workspace`
3. **文档化配置要求**：在扩展的 README 中说明需要的配置项

## 相关文件

- `/Users/ghost/work/WorldTourCasino/.vscode/settings.json` - 项目设置文件
- `/Users/ghost/work/WorldTourCasino/WorldTourCasino.code-workspace` - 工作区文件
- `/Users/ghost/work/WorldTourCasino/vscode-extensions/` - 扩展源代码目录

## 问题影响范围

此问题影响所有依赖 `WTC.is_wtc` 标志的功能：
- VSCode 工具栏按钮（热更新、启动 CV/DH/VS/DHX、打开文档）
- Google Drive 上传功能
- 未来可能添加的其他 WTC 专用功能

## 参考链接

- [VSCode 工作区文档](https://code.visualstudio.com/docs/editor/workspaces)
- [VSCode 设置优先级](https://code.visualstudio.com/docs/getstarted/settings#_settings-precedence)
