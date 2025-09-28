# 添加新 VS Code 扩展规范

## 概述

本文档规范了在 WorldTour Casino 项目中添加新 VS Code 扩展的标准流程。

## 添加新扩展的步骤

### 1. 创建扩展项目结构

在 `vscode-extensions/` 目录下创建新的扩展文件夹：

```bash
vscode-extensions/
└── [扩展名称]/
    ├── package.json          # 扩展配置
    ├── tsconfig.json         # TypeScript 配置
    ├── README.md             # 扩展说明文档
    ├── .gitignore           # Git 忽略文件
    ├── icons/               # 图标资源目录
    └── src/                 # 源代码目录
        └── extension.ts     # 扩展入口文件
```

### 2. 配置 settings.json

在 `.vscode/settings.json` 中的 `WTC.subProjects.extensions.plugins` 添加新扩展配置：

```json
{
  "WTC": {
    "subProjects": {
      "extensions": {
        "plugins": {
          // 添加新扩展配置
          "[插件键名]": {
            "name": "[扩展文件夹名]",
            "symlinkName": "[符号链接名]"
          }
        }
      }
    }
  }
}
```

**示例：**

```json
"docsServer": {
  "name": "wtc-docs-server",
  "symlinkName": "wtc-docs-server"
}
```

### 3. 更新 onEnter.sh 脚本

在 `.vscode/scripts/onEnter.sh` 中添加新扩展的安装调用：

```bash
# Setup all configured plugins
setup_plugin "toolbar"
setup_plugin "googleDrive"
setup_plugin "[插件键名]"  # 添加新扩展
setup_plugin "localServer"
```

**注意：** 插件键名必须与 settings.json 中的键名完全一致。

### 4. 开发扩展

#### 基本 package.json 配置

```json
{
  "name": "[扩展名]",
  "displayName": "[显示名称]",
  "description": "[扩展描述]",
  "version": "0.0.1",
  "publisher": "wtc",
  "engines": {
    "vscode": "^1.85.0"
  },
  "main": "./out/extension.js",
  "activationEvents": [
    "onStartupFinished"
  ],
  "extensionKind": ["workspace"],
  "scripts": {
    "compile": "tsc -p ./",
    "watch": "tsc -watch -p ./"
  }
}
```

#### 编译和安装

```bash
cd vscode-extensions/[扩展名]
npm install                    # 安装依赖
npm run compile               # 编译 TypeScript
```

### 5. 测试扩展

运行 onEnter 脚本安装扩展：

```bash
./.vscode/scripts/onEnter.sh
```

验证安装：

```bash
# 检查符号链接
ls -la ~/.vscode/extensions/ | grep [扩展名]
```

## 扩展命名规范

1. **文件夹名称**：使用小写字母和连字符，如 `wtc-docs-server`
2. **插件键名**：使用驼峰命名，如 `docsServer`
3. **显示名称**：使用空格分隔的标题格式，如 `WTC Docs Server`
4. **符号链接名**：通常与文件夹名称相同

## 扩展类型示例

### 工具型扩展

- 如：`wtc-toolbar-extension` - 提供快捷工具栏按钮
- 激活事件：`onStartupFinished`

### 服务型扩展

- 如：`wtc-docs-server` - 管理后台服务
- 激活事件：`workspaceContains:特定文件`

### 集成型扩展

- 如：`google-drive-uploader` - 与外部服务集成
- 激活事件：按需激活

## 自动化部署

扩展通过以下机制自动部署：

1. **项目打开时**：`.vscode/scripts/onEnter.sh` 自动执行
2. **符号链接**：创建到以下编辑器的扩展目录：
   - VS Code: `~/.vscode/extensions/`
   - Trae: `~/.trae/extensions/`
   - TraeCN: `~/.trae-cn/extensions/`
   - Windsurf: `~/.windsurf/extensions/`
   - Cursor: `~/.cursor/extensions/`

## 注意事项

1. **扩展隔离**：每个扩展应该独立，避免相互依赖
2. **工作区限定**：使用 `extensionKind: ["workspace"]` 确保扩展只在特定工作区激活
3. **权限控制**：避免请求不必要的权限
4. **性能考虑**：延迟激活，避免影响编辑器启动速度

## 故障排查

### 扩展未自动安装

1. 检查 `settings.json` 配置是否正确
2. 检查 `onEnter.sh` 是否包含新扩展
3. 手动运行 `./.vscode/scripts/onEnter.sh`
4. 查看脚本输出日志

### 扩展无法激活

1. 检查 `package.json` 中的 `activationEvents`
2. 确认编译输出存在：`out/extension.js`
3. 查看 VS Code 开发者控制台错误信息

## 相关文件

- [.vscode/settings.json](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/.vscode/settings.json) - 扩展配置
- [.vscode/scripts/onEnter.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/.vscode/scripts/onEnter.sh) - 自动安装脚本
- [vscode-extensions/](https://github.com/LuckyZen/WorldTourCasino/tree/classic_vegas/vscode-extensions) - 扩展源码目录
