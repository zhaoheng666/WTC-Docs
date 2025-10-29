# OpenSpec：规范驱动开发实践分享

## 开篇：传统做法的痛点

过去，我们的需求、代码、文档分散在各处：

- ❌ 需求在多份文档中重复（proposal、design、code comments）
- ❌ 哪个是最新的规范？开发者常常困惑
- ❌ 进度靠人工跟踪，tasks.md 容易过期
- ❌ 功能上线后，新的需求何时合并入规范？谁负责？
- ❌ 为什么这样设计的决策，时间久了就丢失了

**结果**：每次都要从头梳理，规范总是不一致，知识难以积累。

---

## OpenSpec 的核心理念

### 三阶段工作流

```
Stage 1: 设计提案          Stage 2: 实施代码           Stage 3: 自动更新规范
(5-10 小时)               (5-20 小时)                (5 分钟 - 自动)

proposal.md          →      CODE                 →    specs/ 自动合并
+ design.md                                          + archive/ 保存历史
+ tasks.md
+ spec delta
```

### 关键概念：Spec is Truth

```
✅ specs/                  当前的唯一规范源
   ├─ resource-management/spec.md  所有已完成功能的规范
   └─ code-quality/spec.md         编码标准

📝 changes/                正在提案阶段
   └─ poster-resourcemanv2-migration/
      ├─ proposal.md      为什么要做？
      ├─ design.md        怎么设计？
      ├─ tasks.md         分成几个任务？
      └─ specs/           新需求的规范 delta

📚 archive/                已完成，历史记录
   └─ 2025-10-29-poster-resourcemanv2-migration/
      └─ 完整的决策和实施过程
```

---

## 真实案例：poster-resourcemanv2-migration

### 问题背景

海报资源下载存在的问题：
1. **架构分散**：独立的下载逻辑，无法优先级控制
2. **进度不清**：无法展示详细的下载进度
3. **事件缺失**：用回调函数，违反依赖倒置原则
4. **难以扩展**：添加新海报类型需要修改核心代码

### 方案设计（Stage 1）

**proposal.md** 明确：
- 目标：统一到 ResourceManV2，获得 5 大优势
- 范围：创建 PosterDownloader，集成现有系统
- 工作量：6-11 小时分阶段进行

**tasks.md** 分解为：
- Phase 1：基础设施 (4 tasks, 3-4 小时) ✅
- Phase 2：核心逻辑 (2 tasks, 2-3 小时) ✅
- Phase 3：集成 (2 tasks, 1-2 小时) ✅
- Phase 4：优化完善 (2 tasks, 1-2 小时) ✅

**spec delta** 定义：
```markdown
## ADDED Requirements

### Requirement: Poster Resource Download Support
The system SHALL support downloading poster resources through
ResourceManV2 with priority-based queuing.

#### Scenario: Featured posters prioritize
- WHEN poster type is featured
- THEN priority increases by 30 points
```

### 实施过程（Stage 2）

开发者按 tasks.md 逐步实现：

- Task 1.1: 调查现有实现 ✅ (0.5h)
- Task 1.2: 创建 PosterDownloader 类 ✅ (1h)
- Task 1.3: 实现优先级排序 ✅ (1h)
- Task 2.1: 实现下载方法 ✅ (1.5h)
- Task 2.2: 事件系统集成 ✅ (1h)
- Task 3.1: ResourceManV2 扩展 ✅ (0.5h)
- ...所有任务完成

### 自动归档（Stage 3）

```bash
openspec archive poster-resourcemanv2-migration --yes
```

**自动执行的操作**：
1. ✅ 验证 tasks.md 所有任务标记完成
2. ✅ 读取 spec delta（5 个新需求）
3. ✅ 自动合并到 specs/resource-management/spec.md
4. ✅ 移动到 archive/2025-10-29-poster-resourcemanv2-migration/
5. ✅ 新规范立即生效

---

## 关键收益对比

| 维度 | 传统做法 | OpenSpec 做法 |
|-----|---------|------------|
| **需求源** | 多份文档，易冲突 | 单一源 (specs/)，自动同步 |
| **进度追踪** | 靠口头沟通 | tasks.md，每个 task 有时间和负责人 |
| **规范更新** | 手动，常遗漏 | 自动合并 delta，归档时触发 |
| **设计决策** | 丢失或散落注释 | proposal + design 永久保存在 archive |
| **知识积累** | 零散的代码注释 | 完整的演进过程可回溯 |
| **新人入职** | 问"怎么做？" | 看 specs/ 了解当前规范 |

---

## 我们的发现

### ✅ 规范自动演进，不再手动维护

从 poster 案例看：
- 不需要"功能上线后手动更新需求文档"
- delta 自动合并，规范在每次归档时自动升级
- 永远不会"规范落后于代码"

### ✅ 决策过程被保留，不再丢失

- **为什么做**？→ proposal.md（背景 + 问题）
- **怎么设计**？→ design.md（架构决策 + 权衡）
- **如何实施**？→ tasks.md + code（分步骤完成）
- **最终规范是什么**？→ specs/（自动合并后的真理）

### ✅ 每个 task 都可追踪，进度透明

- Phase 1：基础设施 ✅ 完成
- Phase 2：核心逻辑 ✅ 完成
- Phase 3：集成 ✅ 完成
- Phase 4：优化 ✅ 完成

不再有"什么时候能完成？"的模糊回答。

### ✅ 规范成为可教学的对象

以前：
```
新人：PosterDownloader 有什么方法？
老人：看代码吧...（找了半天文档）
```

现在：
```
新人：PosterDownloader 的需求是什么？
答：看 specs/resource-management/spec.md 第 XX 行
```

---

## 团队的下一步

1. **下一个功能**用 OpenSpec 流程设计提案
   - 先写 proposal.md（为什么？做什么？）
   - 再写 spec delta（新增什么需求？）
   - 然后写 tasks.md（分几个阶段？）

2. **建立 Code Review 检查清单**
   - ✅ 代码实现符合 spec scenarios 吗？
   - ✅ JSDoc 文档清晰吗？
   - ✅ 错误处理完整吗？

3. **定期回顾 archive/**
   - 学习过去的设计决策
   - 避免重复犯错
   - 建立团队的设计文化

4. **自动化检查**
   - 每次归档后，运行 `/openspec-archive-checklist`
   - 检查 CLAUDE.md 是否需要同步
   - 保持文档一致性

---

## 总结：为什么值得做

| 维度 | 收益 |
|-----|------|
| **可维护性** | 规范永远最新，不需要手动维护 |
| **可追踪性** | 每个需求、每个 task、每个决策都有记录 |
| **可教学性** | 新人可以通过 specs/ 快速了解系统 |
| **可延续性** | 决策过程被保留，避免重复思考 |
| **自动化** | 从提案到规范更新，自动化程度最高 |

**最重要的是**：规范驱动开发成为可重复、可教学、可改进的流程，而不是每次从零开始。

---

**分享时间**: 10-15 分钟
**基于案例**: poster-resourcemanv2-migration (完整的 Stage 1→2→3 流程)
**更新日期**: 2025-10-29
