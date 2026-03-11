# Cocos2d-x Slot 关卡迁移 Unity 6 技术方案

> **版本**: v1.0  
> **创建日期**: 2026-03-10  
> **状态**: 设计阶段  
> **适用范围**: WorldTourCasino 项目 95 个 SlotMachineScene2022 架构关卡的 Unity 6 迁移

---

## 文档用途

本技术方案是指导 **Cocos2d-x JavaScript 老虎机关卡** 迁移至 **Unity 6 C#** 的完整实施指南。

**核心目标**：建立一套可重复的、系统化的转换流水线，使得关卡迁移可以近乎机械化地批量完成。

**目标读者**：
- 负责实施迁移的开发人员（人工 + AI）
- 负责审阅转换结果的技术负责人
- 后续维护 Unity 版本的开发团队

---

## 文档目录

| 编号 | 文件 | 内容 | 用途 |
|------|------|------|------|
| 01 | [01-overview.md](01-overview.md) | 项目概述与迁移目标 | 理解全貌和范围 |
| 02 | [02-architecture.md](02-architecture.md) | 4 层架构设计方案 | 理解分层策略和设计原则 |
| 03 | [03-L1-cocos-compat.md](03-L1-cocos-compat.md) | L1 Cocos 兼容层详细设计 | 实现 L1 层的完整参考 |
| 04 | [04-L2-slot-framework.md](04-L2-slot-framework.md) | L2 Slot 框架层详细设计 | 实现 L2 层的完整参考 |
| 05 | [05-L3-slot-adaptation.md](05-L3-slot-adaptation.md) | L3 Slot 框架适配层详细设计 | 理解关卡覆写模式 |
| 06 | [06-L4-game-migration.md](06-L4-game-migration.md) | L4 关卡业务逻辑迁移规范 | 单关卡转换的操作手册 |
| 07 | [07-execution-standards.md](07-execution-standards.md) | 执行规范 | **必读** — 所有执行者必须遵守 |
| 08 | [08-roadmap.md](08-roadmap.md) | 实施路线图与验证计划 | 项目计划和里程碑 |
| 09 | [09-appendix-api-reference.md](09-appendix-api-reference.md) | 完整 API 映射速查表 | 实施时的快速查表工具 |

---

## 阅读顺序建议

### 首次阅读（理解全貌）

```
01-overview.md → 02-architecture.md → 07-execution-standards.md
```

### 实施 L1 层

```
03-L1-cocos-compat.md → 09-appendix-api-reference.md → 07-execution-standards.md（映射记录规范）
```

### 实施 L2 层

```
04-L2-slot-framework.md → 07-execution-standards.md
```

### 转换具体关卡

```
05-L3-slot-adaptation.md → 06-L4-game-migration.md → 07-execution-standards.md
```

---

## 关键术语

| 术语 | 含义 |
|------|------|
| **CPA** | Component-Process-Action，源代码库的核心架构模式 |
| **CCB** | CocosBuilder 文件，UI 布局和动画的可视化编辑产物 |
| **FlowDispatcher** | 流程引擎，用嵌套数组 DSL 定义状态机 |
| **SlotMan** | 服务端数据管理器，持有关卡配置、下注信息、结果等 |
| **SpinResult** | 一次旋转的服务端返回结果（符号面板、赢线、奖金等） |
| **L1 / L2 / L3 / L4** | 本方案定义的 4 层架构 |
| **NameBinder** | 本方案设计的 CCB 属性自动绑定系统 |
| **DOTween** | Unity 补间动画插件，用于替代 cc.sequence/cc.moveTo 等动作链 |

---

## 架构决策摘要

以下是已确认的核心架构决策，详细分析见各章节：

| # | 决策 | 选择 | 替代方案 | 理由 |
|---|------|------|----------|------|
| D1 | 分层策略 | 4 层架构 | 2 层/3 层 | L2/L3 拆分解耦框架本体与关卡差异适配 |
| D2 | Action 链映射 | DOTween Sequence | async/await、Coroutine | ~9,000 次调用，DOTween 语义最接近且性能好 |
| D3 | CCB 属性绑定 | NameBinder (Transform.Find) | 手动拖拽、反射 | ~24,000 次 .controller._ 访问，自动化是唯一可行方案 |
| D4 | Reel 卷轴系统 | 从零构建 | 第三方插件 | 源码卷轴逻辑高度定制，无现成插件匹配 |
| D5 | L1 兼容层策略 | 1:1 接口映射 | 直接重写 | 使 L4 关卡逻辑可机械翻译 |
| D6 | L2 框架层策略 | 范式转换 | 1:1 复制 | 利用 Unity/C# 成熟技术合理重构 |
| D7 | 迁移范围 | 95 个 2022 架构关卡 | 全部 235 个 | 2022 架构统一，投入产出比最高 |

---

## 变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-10 | v1.0 | 初始版本 |
