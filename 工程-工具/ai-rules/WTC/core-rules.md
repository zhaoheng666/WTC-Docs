# 核心规则

**⚠️ 历史遗留文档**

本文件是旧规则体系的遗留文档，保留作为参考。

**当前状态**：
- ✅ 核心规则已重构并内联到 `CLAUDE.md`
- ✅ 详细规则已拆分到各专项文件（git-commits.md、shell-scripts.md 等）
- ℹ️ 本文件仅供历史参考，不会自动加载

**最新规则**：请查看主项目 `CLAUDE.md` 和 `docs/工程-工具/ai-rules/` 下的各专项规则文件。

---

## 历史内容

以下内容为历史参考：

---

## 🔧 开发规则

### 代码风格

- 只使用 ES5 JavaScript
- 启用严格模式：`'use strict';`
- 使用 Browserify 模块系统
- 禁止使用：箭头函数、模板字符串、const/let、ES6+ 特性

示例：

```javascript
'use strict';
var MyClass = function() {
    this.value = 0;
};
MyClass.prototype.getValue = function() {
    return this.value;
};
```

### 文件操作规则

**源码文件链接**：
- 编写文档时，源码文件链接必须使用 GitHub 格式
- 格式：`https://github.com/zhaoheng666/WorldTourCasino/blob/classic_vegas/路径`

**Docs 文档链接**：
- 在 docs 子项目中，所有相对链接必须转换为绝对 HTTP 链接
- 本地：`http://localhost:5173/WTC-Docs/路径`
- 生产：`https://zhaoheng666.github.io/WTC-Docs/路径`
- 链接处理器在构建时自动运行

**配置文件同步**：
- 修改 `.vscode/settings.json` 时，必须同步更新 `WorldTourCasino.code-workspace`
- 使用 `.vscode/scripts/` 中的自动化脚本
- 修改后测试

### Shell 脚本

Shebang：

```bash
#!/bin/zsh
```

错误处理：

```bash
set -euo pipefail
```

最佳实践：
- 使用绝对路径
- 尽可能避免 `cd` 命令
- 引用所有变量：`"$var"`
- 操作前检查文件是否存在

---

## 📝 Git 工作流

### 主项目提交

**格式**：`cv：关卡X [描述]` 或 `type(scope): subject`

**确认流程**（强制）：
1. 生成提交大纲（提交信息、文件列表、变更大纲）
2. 明确询问："是否继续执行提交？"
3. 等待用户确认（"确认"、"继续"、"yes"）
4. 执行提交

**忽略构建产物**：
- `res_*/flavor/index.html`
- `res_*/flavor/main*.css`
- `res_*/flavor/project.json`
- `res_*/flavor/js_src/common/util/Config.js`
- `res_*/resource_list/**/*.json`
- `res_*/resource_dirs.json`

### docs 子项目提交

- 自动化提交，满足触发条件即可执行
- 使用标准格式：`type(scope): subject`
- 不添加 AI 标识

---

## 🎯 子项目规则

### 进入 docs 子项目时

应用以下规则：
- VitePress 开发规范
- 链接处理规则（强制）
- 图片自动处理
- 自动化提交流程

### 进入 extensions 子项目时

应用以下规则：
- 扩展必须只在 WTC 项目激活（强制）
- TypeScript 标准配置
- 符号链接安装到多个编辑器

---

## 📚 术语速查

### 风格系统

- **Flavor**：游戏变体/品牌
  - CV = Classic Vegas (res_oldvegas/)
  - DH = Double Hit (res_doublehit/)
  - DHX = Double X (res_doublex/)
  - VS = Vegas Star (res_vegasstar/)

- **res_*/** 目录：风格特定资源
- **src/** 目录：所有风格共享代码
- **flavor/** 子目录：风格特定 JavaScript 代码

### 核心系统

- **CardSystem**：收集系统/卡册系统
- **resource_dirs.json**：资源版本控制（debug/release）
- **project.json**：Cocos2d 项目配置

---

## 🔗 详细规则

完整规则索引和详细说明，请查看：

- WTC 主项目规则：`docs/工程-工具/ai-rules/WTC/`
- 通用规则：`docs/工程-工具/ai-rules/shared/`
- docs 子项目规则：`docs/工程-工具/ai-rules/docs/`
- extensions 子项目规则：`docs/工程-工具/ai-rules/extensions/`

---

**最后更新**: 2025-10-14
**维护者**: WorldTourCasino Team
