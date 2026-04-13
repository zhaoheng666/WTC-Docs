# Claude Code Opusplan 混合模型

## 简介

Opusplan 是 Claude Code CLI 目前**最智能、最实用的工作模式**。它采用 **"Opus 规划 + Sonnet 执行"** 的混合策略，在保证输出质量的同时优化了速度和成本。

对于任何需要处理中等以上复杂度任务的开发者，启用 Opusplan 都能显著提升开发效率和代码质量。

## 开启方式

在 Claude Code CLI 中通过 `/model` 命令选择 `opusplan` 混合模型。

## 任务场景最佳实践

搭配 `effortLevel` 使用，根据任务复杂度选择合适组合：

| 任务类型 | 推荐模型 | Effort 等级 | 适用场景 |
|------|------|------|------|
| 简单任务 | haiku / sonnet | low / medium | 代码补全、简单问答 |
| 中等复杂度 | opusplan | medium | 功能开发、Bug 修复 |
| 重度任务 | opusplan | high | 复杂架构设计、性能优化 |
| 大型重构 | opusplan | max（临时）| 跨模块重构、技术迁移 |

## 相关文档

- [Claude Code effort 推理能力配置](./Claude%20Code%20effort%20推理能力配置.md)
