# docs 子项目提交规则（兼容入口）

**适用范围**: 仅 docs 子项目

本文件不再维护一套独立于主项目的提交工作流。提交和推送统一使用主项目
`.claude/skills/git-commit/SKILL.md`，提交类型使用
[Git 提交类型规范](/工程-工具/ai-rules/shared/git-commit-types)。

用户明确要求提交或推送时，该指令即授权执行当前已收口且范围明确的任务，
不再请求二次确认。未收到提交或推送请求时，不改变 Git 状态。

提交信息保持简洁，不添加 AI 标识。多仓库提交顺序、同步、stash 恢复、
OpenSpec 提醒和失败停止条件均以 `git-commit` Skill 的当前版本为准。

---

**最后更新**: 2026-09-02
**维护者**: WTC-Docs Team
