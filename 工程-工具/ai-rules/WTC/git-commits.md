# 主项目 Git 提交规则

**适用范围**: 仅 WorldTourCasino 主项目

本文件定义主项目**特有的** Git 提交规则。通用规则请参考：
- **提交类型**: `docs/工程-工具/ai-rules/shared/git-commit-types.md`
- **执行流程**: `.claude/skills/git-commit/SKILL.md`

---

## 提交阶段边界

- Git 提交只处理已完成任务收口的范围。收口必须发生在最后一次实质性修改之后，并已完成适用的测试、代码审查、验收和阻断问题处理。
- 待提交范围没有实质变化时，复用当前有效的收口结论；提交不得自动调用 code-review、展开新的实施/广泛测试，或在提交后执行例行复审。
- 用户明确要求“提交”“推送”或等价操作时，该指令即授权自动执行当前已收口且范围明确的 Git 流程；不再请求二次确认，完成后输出实际提交大纲和推送结果。
- 无法确认必要收口时，必须在 `git add`、`git stash`、`git commit` 等 Git 状态改变前报告缺失条件并停止。
- 提交范围含糊、硬门禁失败，或同步冲突存在必须由用户裁决的语义歧义时，必须停止后续 Git 状态变更；语义明确的机械冲突可解决并复验后继续。
- OpenSpec 归档提醒优先复用收口结果；缺少提醒结果时仅运行一次 `npm run --silent list:openspec`。提醒保持非阻断且不得触发无关审查、修复或归档。
- 提交涉及 `openspec/` 时，仍须通过 `npm run check:openspec` 硬门禁。

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
- **非产品/业务变更可省略产品代号**（如工具、规则更新）

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
- `[chore] 更新构建脚本`（无产品代号，通用变更）

---

## 子项目提交顺序

当"全部提交"时，顺序为：

1. docs 子项目
2. extensions 子项目
3. 主项目

---

**最后更新**: 2026-09-02
**维护者**: WorldTourCasino Team
