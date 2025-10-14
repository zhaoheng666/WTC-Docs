# 配置文件同步规则

**适用范围**: 仅 WorldTourCasino 主项目

---

## VS Code 配置同步

### 规则

**修改 `.vscode/settings.json` 时，必须同步修改 `WorldTourCasino.code-workspace` 中的 `settings` 部分。**

### 原因

1. **VS Code 支持两种配置方式**:
   - 工作区文件（`.code-workspace`）
   - 文件夹设置（`.vscode/settings.json`）

2. **项目同时使用两种方式**:
   - 需要保持一致
   - 确保无论以哪种方式打开项目，配置都生效

3. **关键配置被扩展依赖**:
   - `WTC.subProjects` 等配置被 VS Code 扩展读取
   - 必须在两处都存在

### 操作流程

```bash
# 步骤 1: 修改 .vscode/settings.json
编辑文件...

# 步骤 2: 将相同的修改同步到 WorldTourCasino.code-workspace 的 settings 字段
编辑文件...

# 步骤 3: 验证两个文件的配置完全一致
diff .vscode/settings.json <(jq '.settings' WorldTourCasino.code-workspace)
```

### 重要配置示例

#### WTC.subProjects

```json
{
  "WTC.subProjects": {
    "docs": {
      "git": "git@github.com:zhaoheng666/WTC-Docs.git",
      "branch": "main",
      "path": "docs",
      "port": 5173
    },
    "extensions": {
      "git": "git@github.com:zhaoheng666/WTC-extensions.git",
      "branch": "main",
      "path": "vscode-extensions"
    }
  }
}
```

此配置必须在两个文件中完全一致。

---

## 检查清单

### 修改配置后检查

- [ ] `.vscode/settings.json` 已修改
- [ ] `WorldTourCasino.code-workspace` 的 `settings` 部分已同步
- [ ] 两个文件的相关配置完全一致
- [ ] 重载 VS Code 窗口验证配置生效

### 常见错误

❌ **只修改一个文件**
- 会导致以不同方式打开项目时配置不一致

❌ **配置不完全一致**
- 会导致扩展行为不可预测

❌ **忘记重载窗口**
- 修改后需要重载 VS Code 窗口才能生效

---

**最后更新**: 2025-10-13
**维护者**: WorldTourCasino Team
