# 扩展激活条件规则

**适用范围**: 仅 extensions 子项目

本文件定义 VS Code 扩展的激活条件规则，确保扩展只在 WorldTourCasino 项目中激活。

---

## 核心规则

**所有扩展必须配置激活条件，确保只在 WorldTourCasino 项目中激活**

---

## 标准配置

在 `package.json` 中配置 `activationEvents`：

```json
{
  "activationEvents": [
    "workspaceContains:WorldTourCasino",
    "workspaceContains:WorldTourCasino.code-workspace"
  ]
}
```

---

## 激活条件说明

### workspaceContains:WorldTourCasino

- 检测工作空间是否包含名为 "WorldTourCasino" 的文件夹
- 适用于文件夹方式打开项目

### workspaceContains:WorldTourCasino.code-workspace

- 检测工作空间是否包含 `WorldTourCasino.code-workspace` 文件
- 适用于工作区方式打开项目

---

## 工作原理

### 检测逻辑

扩展会在以下情况下激活：

1. 工作空间包含名为 "WorldTourCasino" 的文件夹
2. **或** 工作空间包含 `WorldTourCasino.code-workspace` 文件
3. **或** 工作空间名称包含 "WorldTourCasino"

### 不激活的情况

在其他项目中，扩展会保持静默状态，不会：
- 显示状态栏按钮
- 注册命令
- 执行任何初始化代码

---

## 扩展入口代码

### 标准模板

```typescript
import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    console.log('WTC extension activated');

    // 验证是否在 WorldTourCasino 项目中
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders) {
        return;
    }

    // 注册命令、状态栏等...
}

export function deactivate() {
    console.log('WTC extension deactivated');
}
```

---

## 验证方法

### 1. 打开 WorldTourCasino 项目

扩展应该激活，可以在开发者控制台看到激活日志。

### 2. 打开其他项目

扩展应该不激活，不显示任何UI元素。

### 3. 检查激活事件

**打开开发者控制台**:
- macOS: `Cmd+Shift+P` > "Developer: Toggle Developer Tools"
- Windows/Linux: `Ctrl+Shift+P` > "Developer: Toggle Developer Tools"

**查看控制台输出**:
```
WTC extension activated
```

---

## 配置示例

### wtc-toolbars

```json
{
  "name": "wtc-toolbars",
  "activationEvents": [
    "workspaceContains:WorldTourCasino",
    "workspaceContains:WorldTourCasino.code-workspace"
  ],
  "contributes": {
    "commands": [
      {
        "command": "wtc.hotReload",
        "title": "WTC: Hot Reload"
      }
    ]
  }
}
```

### wtc-docs-server

```json
{
  "name": "wtc-docs-server",
  "activationEvents": [
    "workspaceContains:WorldTourCasino",
    "workspaceContains:WorldTourCasino.code-workspace"
  ],
  "contributes": {
    "configuration": {
      "title": "WTC Docs Server",
      "properties": {
        "wtc-docs-server.autoStart": {
          "type": "boolean",
          "default": true
        }
      }
    }
  }
}
```

---

## 故障排查

### 扩展未激活

**检查清单**:
1. 确认在 WorldTourCasino 工作空间中
2. 查看 VS Code 输出面板 > "扩展主机"
3. 检查扩展是否已安装（扩展面板搜索 `wtc-`）
4. 重载 VS Code 窗口

### 扩展在其他项目中也激活

**原因**: 激活条件配置不正确

**解决方案**: 检查 `package.json` 中的 `activationEvents` 配置

---

**最后更新**: 2025-10-13
**维护者**: WTC-Extensions Team
