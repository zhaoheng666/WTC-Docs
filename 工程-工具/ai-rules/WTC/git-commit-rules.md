# 主项目 Git 提交规则

**适用范围**: 仅 WorldTourCasino 主项目

本文件定义主项目特定的 Git 提交流程和规则。

---

## 忽略构建产物

提交时必须忽略 `./build_local_app.sh` 产生的文件。

### 需忽略的文件模式

- `res_*/flavor/index.html`
- `res_*/flavor/main*.css`
- `res_*/flavor/project.json`
- `res_*/flavor/js_src/common/util/Config.js`
- `res_*/resource_list/**/*.json`
- `res_*/resource_dirs.json`

### 原则

**只提交源码修改，不提交构建结果**

---

## Git 操作流程

### 标准流程

```bash
# 1. 保存本地修改（如有需要）
git stash

# 2. 提交本地更改
git add .
git commit -m "提交信息"

# 3. 同步远程更新
git pull --rebase

# 4. 推送到远程
git push

# 5. 恢复 stash（如果第1步有 stash）
git stash pop
```

### 重要事项

- ✅ **必须按顺序**: commit → pull --rebase → push
- ✅ **自动恢复 stash**: 提交后自动恢复（如果有）
- ⚠️ **遇到冲突**: 需手动解决

---

## 提交确认流程

### 严格禁止自动提交

**即使用户说"提交吧"，也必须经过确认流程**

### 必须执行的步骤

1. **生成提交大纲**:
   - 提交信息（commit message）
   - 变更文件列表
   - 变更内容大纲

2. **明确询问**:
   - "是否继续执行提交？"
   - 如有 docs 子项目变更，一并提醒

3. **等待确认**:
   - 只有用户明确确认（如"继续"、"确认"、"yes"）才执行
   - 不接受模糊表述

### 示例对话

```
AI: 我已分析变更内容：

提交信息: cv：关卡100 优化卡片收集逻辑

变更文件列表:
- src/social/controller/card_system/CardCollector.js
- src/social/model/CardSystemMan.js

变更内容大纲:
1. 优化卡片收集算法，提升性能
2. 修复重复收集的 bug
3. 添加新的收集事件日志

是否继续执行提交？

User: 确认

AI: 执行提交...
```

---

## 提交范围规则

### 全部提交

当用户说"全部提交"、"提交全部"、"提交吧"等**未明确指明子项目**时：

1. 表示主项目和所有子项目都要提交
2. **提交顺序**: 先提交子项目，再提交主项目
3. **子项目列表**: 从 `.vscode/settings.json` 的 `WTC.subProjects` 读取
4. 当前子项目包括:
   - docs（文档子项目，路径：`docs/`）
   - extensions（VS Code 扩展子项目，路径：`vscode-extensions/`）

### 子项目特殊规则

- **docs 子项目**: 参考 [docs 子项目规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/auto-commit-rules)
- **extensions 子项目**: 使用与主项目相同的确认流程

---

**最后更新**: 2025-10-13
**维护者**: WorldTourCasino Team
