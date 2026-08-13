# OpenSpec 1.8.0 升级说明

> 将 OpenSpec 升级到了 1.8.0，同时重新统一了使用规范。

这不只是一次依赖升级，主要想解决三个问题：Claude Code 和 Codex 流程不统一；英文提案难以直观识别；代码完成后忘记归档，导致正式 spec 没有持续积累。

## 这次有哪些变化

### 1. 统一为 OPSX 工作流

OpenSpec 1.x 开始使用 OPSX 作为标准工作流，将工作拆成探索、提案、实施、修订、同步和归档等动作。实施中发现方案有问题时，可以先更新提案和设计，再继续实施，不再受僵硬的线性阶段限制。

### 2. Claude Code 和 Codex 共享官方 Skill

两个 Agent 现在使用同一版本、同一配置生成的官方工作流，不再分别维护手写规则。

Claude Code 使用 `/opsx:propose`、`/opsx:apply`、`/opsx:archive`；Codex 使用对应的 `$openspec-*` Skill。入口不同，但流程和项目约束是一致的。

### 3. 机器 ID 用英文，人读内容用中文

change ID 和目录名仍然使用英文 kebab-case，例如 `add-resource-cache`，以保证工具稳定。提案标题、正文、设计、任务、Requirement 和 Scenario 默认使用中文，让团队能够直观理解提案意图。

### 4. review 和 commit 会主动提醒归档

代码提交、合并或部署，都不代表 OpenSpec 提案已结束。只有完成归档，delta specs 才会进入 `openspec/specs/`，成为项目的正式规范。

现在 code-review 和 git-commit 会检查 active changes。如果某个 change 的 tasks 已经 100% 完成却没有归档，会在当前回复中显著提醒；没有则不额外输出。该提醒不会阻断当前任务，也不要求其他协作者处理不属于自己的提案。

## 1.8.0 对我们的意义

1.8.0 增强了 Codex 和通用 Agent Skills 支持，能够更准确地区分“规划完成”和“变更完成”，也改进了子任务统计、Scenario 丢失校验、归档提示以及非英文规范的支持。

对项目来说，最大的意义是让“提案、实施、正式规范和历史归档”形成一个可检查的闭环。

## 大家以后怎么用

拉取包含 OpenSpec 升级的提交后，直接重新启动一次游戏，现有的本地启动脚本里已经植入的 npm install 会安装依赖：

只有新机器提示找不到 `openspec` CLI 时，才需要运行 `npm run setup:openspec`。

日常工作只记住三件事：

1. 需求明确后创建 proposal。
2. 按 tasks 实施，方案变化时同步修订文档。
3. 交付条件满足后主动 archive，不要停在“代码已提交”。

## 结尾

这次升级最终想建立一个团队习惯：写代码前把意图和验收条件说清楚，实施中让计划和代码保持一致，交付后通过归档把变更沉淀为长期规范。

## 参考
想要详细了解 openspec 新版本特性的，建议阅读：
- [OpenSpec 1.8.0 Release Notes](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.8.0)
- [OPSX Workflow](https://github.com/Fission-AI/OpenSpec/blob/v1.8.0/docs/opsx.md)
