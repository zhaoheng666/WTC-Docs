# 主项目 Git 提交规则

**适用范围**: 仅 WorldTourCasino 主项目

本文件定义主项目**特有的** Git 提交规则。通用规则请参考：
- **提交类型**: `docs/工程-工具/ai-rules/shared/git-commit-types.md`
- **执行流程**: `.claude/skills/git-commit/SKILL.md`

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

## 主项目提交格式

```
[类型] 产品代号：描述
[关卡X] 产品代号：描述
```

**格式说明**：
- 类型用方括号包裹，放在最前面
- 产品代号从当前分支推定（见下表）
- 使用中文冒号 `：`
- 描述紧随其后

### 分支与产品代号映射

| 分支模式 | 产品代号 |
|---------|---------|
| `classic_vegas_cvs_v*` | cv |
| `classic_vegas_dbh_v*` | dh |
| `classic_vegas_dh_v*` | dh |
| `classic_vegas_dhx_v*` | dhx |
| `classic_vegas_vs_v*` | vs |

**示例**：
- `[fix] cv：修复加载错误`（在 cvs 分支）
- `[fix] dh：修复加载错误`（在 dbh 分支）
- `[关卡100] cv：优化卡片收集`

---

## 子项目提交顺序

当"全部提交"时，顺序为：

1. docs 子项目
2. extensions 子项目
3. 主项目

---

**最后更新**: 2025-01-19
**维护者**: WorldTourCasino Team
