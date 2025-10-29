# OpenSpec 实践指南

## 序言

本文档记录了 WorldTourCasino 团队完成的一个**完整 OpenSpec 工作流程**，从创建变更提案、实施代码、到最终归档的全过程。我们使用真实案例（**poster-resourcemanv2-migration**）来演示每一个步骤，希望为团队后续的规范驱动开发提供可复用的模板和最佳实践。

**主要目标**：
- 理解 OpenSpec 的三阶段工作流（Stage 1/2/3）
- 掌握创建、实施、归档变更的完整流程
- 学习如何维护 Spec 作为唯一真相来源
- 理解 OpenSpec 与 CLAUDE.md 的关系和同步机制

**预计阅读时间**：30-45 分钟（完整阅读）或 10 分钟（快速查阅）

---

## 1. 核心概念与理念

### 1.1 OpenSpec 是什么？

OpenSpec 是一个**规范驱动的开发框架**，核心思想是：

```
设计 → 编码 → 部署 → 总结规范
  ↑                    ↓
  ←──────────────────←
```

而不是传统的：
```
需求 → 编码 → 部署 → 文档（常被忘记）
```

### 1.2 三个核心原则

| 原则 | 含义 | 在本项目中的体现 |
|-----|------|-----------------|
| **Spec is Truth** | 规范是唯一真相来源 | `openspec/specs/` 是所有开发的规范基准 |
| **Changes are Proposals** | 变更是提案，不是真相 | `openspec/changes/` 中的内容仅在归档后合并 |
| **Archive is History** | 归档是历史，用于上下文 | `openspec/changes/archive/` 保留决策过程，不作为规范 |

### 1.3 三阶段工作流

```
┌─────────────────────┐
│  Stage 1: 创建提案   │  changes/ → proposal.md, design.md, tasks.md, spec.md
└──────────┬──────────┘
           ↓ 审批通过，开始实施
┌─────────────────────┐
│ Stage 2: 实施变更    │  开发人员按 tasks.md 逐步实现功能
└──────────┬──────────┘
           ↓ 功能完成，部署到生产
┌─────────────────────┐
│ Stage 3: 归档变更    │  Delta → 自动合并到 specs/；Change 移到 archive/
└─────────────────────┘
```

---

## 2. 快速开始

### 2.1 目录结构

```
openspec/
├── project.md                          # 项目技术上下文和约束
├── AGENTS.md                           # AI 助手使用指南
├── specs/                              # ✅ 当前真相 - 已构建的功能
│   ├── resource-management/
│   │   ├── spec.md                    # 资源管理系统规范（权威文档）
│   │   └── design.md                  # 技术设计模式
│   └── code-quality/
│       └── spec.md                    # 代码质量标准
├── changes/                            # 🔄 提案 - 正在规划的功能
│   ├── poster-resourcemanv2-migration/ # 某个具体的变更提案
│   │   ├── proposal.md                # 为什么和做什么
│   │   ├── design.md                  # 技术决策
│   │   ├── tasks.md                   # 实施清单
│   │   └── specs/                     # Delta 规范
│   │       └── resource-management/
│   │           └── spec.md            # 新增/修改的需求
│   └── archive/                        # 📚 历史 - 已完成的变更
│       └── 2025-10-29-poster-resourcemanv2-migration/
│           ├── proposal.md
│           ├── design.md
│           ├── tasks.md
│           └── specs/
```

**关键理解**：
- `specs/` = 当前规范（开发时只查看这里）
- `changes/` = 正在规划（实施时查看设计决策）
- `archive/` = 历史记录（理解背景时查看）

### 2.2 常用命令速查

| 命令 | 用途 | 示例 |
|-----|------|------|
| `openspec list` | 列出活跃的 changes | `openspec list` |
| `openspec list --specs` | 列出所有 specs | `openspec list --specs` |
| `openspec show [name]` | 显示详情 | `openspec show poster-resourcemanv2-migration` |
| `openspec validate [name] --strict` | 验证提案 | `openspec validate poster-resourcemanv2-migration --strict` |
| `openspec archive [id] --yes` | 归档变更 | `openspec archive poster-resourcemanv2-migration --yes` |

---

## 3. Stage 1: 创建变更提案（从 0 到 1）

### 3.1 何时创建 Change

使用**决策树**来判断是否需要创建 Change：

```
收到需求或想法
  ↓
是否修复已有需求中的 Bug（恢复预期行为）?
  ├─ 是 → ✅ 直接修改代码，不需要 Change
  └─ 否 ↓

是否仅改进注释、格式、拼写（无功能影响）?
  ├─ 是 → ✅ 直接修改代码，不需要 Change
  └─ 否 ↓

是否添加新功能或能力?
  ├─ 是 → 🟡 需要 Change
  └─ 否 ↓

是否修改现有需求的行为（Breaking Change）?
  ├─ 是 → 🟡 需要 Change
  └─ 否 ↓

不确定?
  → 🟡 需要 Change（更安全）
```

**案例**：为什么 `poster-resourcemanv2-migration` 需要 Change？
- ✅ 添加**新功能**：Poster 资源通过 ResourceManV2 下载（之前无此功能）
- ✅ **架构变更**：从独立的下载逻辑迁移到统一框架
- ✅ **新规范**：引入事件系统和优先级概念

### 3.2 创建提案的 7 个步骤

#### 步骤 1：选择唯一的 change-id

**命名规则**：
- 格式：`verb-noun-modifier`（动词-名词-修饰符）
- 例：`add-two-factor-auth`、`update-payment-gateway`、`refactor-event-system`
- **不要**：`feature1`、`fix_stuff`、`update`（太模糊）

**验证唯一性**：
```bash
openspec list  # 检查是否已存在
```

**案例中的选择**：
```
change-id: poster-resourcemanv2-migration
解释：migrate posters 到 ResourceManV2
```

#### 步骤 2：创建目录和基础文件

```bash
# 创建目录结构
mkdir -p openspec/changes/poster-resourcemanv2-migration/specs/resource-management

# 创建 4 个必需文件
touch openspec/changes/poster-resourcemanv2-migration/{proposal.md,tasks.md,specs/resource-management/spec.md}
```

#### 步骤 3：编写 proposal.md（为什么和做什么）

**模板结构**：
```markdown
# Proposal: [简明标题]

## 背景（Why）
[1-3 句话描述问题或机会]

## 目标（Goal）
[明确的成功标准，5-10 点]

## 范围（Scope）
### 包括
- [...]
### 不包括
- [...]

## 验收标准
[检查清单]

## 相关规范
- Spec A
- Spec B

## 预期工作量
- [时间估算]

## 风险
| 风险 | 影响 | 缓解 |
```

**案例：poster-resourcemanv2-migration 的背景**：

```markdown
## 背景

当前 PosterCenterActivity 使用旧的 ResourceMan 下载海报资源，存在以下问题：

1. **不统一的下载架构**：海报资源使用独立的下载逻辑，与活动资源分离
2. **缺乏优先级控制**：无法优先加载重要海报（首屏海报）
3. **没有进度追踪**：无法详细展示下载进度
4. **缺乏事件驱动**：下载完成回调为回调函数，不符合现代架构
5. **难以扩展**：添加新海报类型需要修改核心下载逻辑

## 目标

统一海报资源下载到 ResourceManV2 框架，获得：

1. ✅ **统一的下载架构** - 与活动、章节等资源统一管理
2. ✅ **优先级支持** - 首屏海报优先加载
3. ✅ **进度追踪** - 完整的进度事件
4. ✅ **事件驱动** - 符合依赖倒置原则
5. ✅ **扩展性** - 易于添加新的海报类型
```

#### 步骤 4：编写 spec delta（新的规范）

**关键概念**：Delta 是"变化"，而不是完整规范。归档时会自动合并到 `specs/` 中。

**三种操作**：

| 操作 | 用途 | 何时使用 |
|-----|------|---------|
| `## ADDED Requirements` | 新功能 | 引入全新的需求或能力 |
| `## MODIFIED Requirements` | 修改现有功能 | 改变现有需求的行为或范围 |
| `## REMOVED Requirements` | 删除功能 | 弃用现有需求（少见） |

**关键规则**：

✅ **正确的 Scenario 格式**（4 个 `#`）：
```markdown
#### Scenario: Poster resources download by priority
- **WHEN** Multiple poster resources are queued with different priorities
- **THEN** High-priority posters download first
```

❌ **错误的格式**（不会被识别）：
```markdown
- **Scenario**: Poster download priority  # 用 bullet + bold（错误）
## Scenario: ...                           # 用 2 个 #（错误）
```

**案例：poster-resourcemanv2-migration 的 delta**：

```markdown
# Spec Delta: Resource Management - 海报资源下载支持

## ADDED Requirements

### Requirement: Poster Resource Download Support
The system SHALL support downloading poster resources through ResourceManV2
with priority-based queuing.

#### Scenario: Poster resources download by priority
- **WHEN** Multiple poster resources are queued with different priorities
- **THEN** High-priority posters (expiring soon) download first

#### Scenario: Poster download emits events
- **WHEN** Poster download starts
- **THEN** System emits `POSTER_DOWNLOAD_START` event

### Requirement: Unified Poster Download API
External code SHALL access poster downloads through ResourceManV2 unified API,
not separate downloader instances.

#### Scenario: Download via ResourceManV2
- **WHEN** PosterCenterActivity needs to download posters
- **THEN** Calls `ResourceManV2.getInstance().downloadPosters(posterConfigs)`
```

**何时使用 MODIFIED**（常见错误）：

❌ **错误做法**：只写新增的部分
```markdown
## MODIFIED Requirements
### Requirement: Resource Download API
- 新增海报支持  ← 只写了新增，遗漏了原有内容！
```

✅ **正确做法**：复制完整需求，然后修改
```markdown
## MODIFIED Requirements
### Requirement: Resource Download API
System SHALL provide unified resource download API supporting
Activities, Chapters, and Posters with priority queuing.  ← 完整的改后需求

#### Scenario: Download activities
- **WHEN** ...
- **THEN** ...

#### Scenario: Download chapters  ← 保留原有的
- **WHEN** ...
- **THEN** ...

#### Scenario: Download posters  ← 新增的
- **WHEN** ...
- **THEN** ...
```

#### 步骤 5：编写 tasks.md（实施清单）

**目的**：为开发人员提供可追踪的工作清单。

**结构**：
```markdown
## 实施清单

### Phase 1: 基础设施 (3-4 小时)
- [ ] **Task 1.1**: 任务名称
  - 子任务
  - 验收标准
  - 时间估算

- [ ] **Task 1.2**: 另一个任务
  - ...

### Phase 2: 核心逻辑 (2-3 小时)
- [ ] **Task 2.1**: ...
```

**案例：poster-resourcemanv2-migration 的 tasks**：

```markdown
## 实施清单

### Phase 1: 基础设施 (3-4 小时) ✅ 完成

- [x] **Task 1.1**: 调查现有 PosterCenterActivity 实现
  - 审查 `src/task/entity/PosterCenterActivity.js` 的 `startDownloadPoster()`
  - 记录当前下载流程和事件
  - 确定海报配置结构（`posterBoardConfig`, `popupBoardConfig`）
  - 时间: 0.5 小时

- [x] **Task 1.2**: 创建 PosterDownloader 基础类
  - 新建文件: `src/common/resource_v2/downloaders/PosterDownloader.js`
  - 继承 `BaseDownloader`
  - 实现基础方法框架
  - 时间: 1 小时

### Phase 2: 核心下载逻辑 (2-3 小时) ✅ 完成

- [x] **Task 2.1**: 实现 PosterDownloader 下载方法
  - 实现 `downloadPosters(posters, callbacks, priority)`
  - 集成到并发队列
  - 处理失败重试
  - 时间: 1.5 小时
```

**关键点**：
- 分阶段组织（Phase 1/2/3）
- 每个任务可独立完成和验证
- 包含时间估算（便于项目管理）

#### 步骤 6：编写 design.md（技术决策）- 可选

**何时需要 design.md**：
- ✅ 跨多个模块/服务的变更
- ✅ 新的架构模式
- ✅ 安全/性能/迁移的复杂决策

**何时不需要**：
- ❌ 简单的功能补充
- ❌ Bug 修复
- ❌ 仅一个文件的修改

**案例：poster-resourcemanv2-migration 的架构图**：

```markdown
## 架构概览

┌─────────────────────────────────────┐
│   PosterCenterActivity (UI/业务)     │
└──────────────────┬──────────────────┘
                   │ 调用
                   ↓
      ┌────────────────────────┐
      │  ResourceManV2         │
      │  - downloadPosters()   │
      └────────────┬───────────┘
                   │ 创建
                   ↓
      ┌────────────────────────┐
      │  PosterDownloader      │
      │  (extends BaseDownloader)│
      └────────────┬───────────┘
                   │ 发送事件
                   ↓
  ┌─────────────────────────────┐
  │ 事件系统                      │
  │ - POSTER_DOWNLOAD_START     │
  │ - POSTER_DOWNLOAD_PROGRESS  │
  │ - POSTER_DOWNLOAD_COMPLETE  │
  └─────────────────────────────┘
```

#### 步骤 7：验证提案

```bash
# 验证格式和完整性
openspec validate poster-resourcemanv2-migration --strict

# 查看详细信息
openspec show poster-resourcemanv2-migration

# 查看 delta 是否正确解析
openspec show poster-resourcemanv2-migration --json --deltas-only
```

**常见错误和解决**：

| 错误 | 原因 | 解决 |
|-----|------|------|
| "Change must have at least one delta" | 没有 specs/ 目录或文件 | 创建 `specs/[capability]/spec.md` |
| "Requirement must have at least one scenario" | Scenario 标题不是 `#### Scenario:` 格式 | 检查 4 个 `#` 和冒号 |
| "Silent scenario parsing failures" | Scenario 格式接近但不完全正确 | 运行 `openspec show --json --deltas-only` 调试 |

---

## 4. Stage 2: 实施变更（从 1 到 0.9）

### 4.1 实施流程

开发阶段的标准流程：

```
1. 理解需求
   ├─ 阅读 proposal.md → 了解背景和目标
   ├─ 阅读 design.md → 理解架构决策
   └─ 阅读 spec delta → 明确验收标准

2. 逐步实施
   ├─ 创建 TODO 列表（根据 tasks.md）
   ├─ Phase by Phase 完成任务
   ├─ 每完成一个 Phase 测试验证
   └─ 标记任务完成：[x]

3. 代码审查
   ├─ 验证代码符合 code-quality spec
   ├─ 验证 delta 中的所有 Scenario 都满足
   └─ 获得核心贡献者的批准

4. 更新 tasks.md
   └─ 将所有 [x] 改为 [x] 并记录完成时间
```

### 4.2 真实案例：poster-resourcemanv2-migration 实施过程

**Phase 1: 基础设施（✅ 完成）**

Task 1.1: 调查现有实现
- 审查 `src/task/entity/PosterCenterActivity.js` 中的 `startDownloadPoster()` 方法
- 发现当前通过回调处理下载完成，非事件驱动
- 确定海报配置包含 `posterBoardConfig` 和 `popupBoardConfig` 两种

Task 1.2: 创建 PosterDownloader
```javascript
// src/common/resource_v2/downloaders/PosterDownloader.js
'use strict';

/**
 * 海报资源下载器
 * 继承自 BaseDownloader，负责海报资源的并发下载
 */
var PosterDownloader = function() {
    BaseDownloader.call(this);
    this._posterQueue = [];
    this._downloadingPosters = new Map();
};

PosterDownloader.prototype = Object.create(BaseDownloader.prototype);
PosterDownloader.prototype.constructor = PosterDownloader;

/**
 * 下载多个海报资源
 * @param {Array<Object>} posters 海报配置数组
 * @param {Object} callbacks 回调对象 {onProgress, onComplete}
 * @param {Number} priority 下载优先级（0-100）
 */
PosterDownloader.prototype.downloadPosters = function(posters, callbacks, priority) {
    // 按优先级排序
    var sortedPosters = posters.sort(function(a, b) {
        return this._getPriority(b) - this._getPriority(a);
    }.bind(this));

    // 发送开始事件
    game.eventDispatcher.dispatchEvent(
        new cc.Event(CommonEvent.POSTER_DOWNLOAD_START)
    );

    // 添加到下载队列
    this._posterQueue = this._posterQueue.concat(sortedPosters);
    // ... 继续实施
};

/**
 * 获取海报下载优先级
 * @param {Object} posterConfig 海报配置
 * @return {Number} 优先级分数
 */
PosterDownloader.prototype._getPriority = function(posterConfig) {
    var priority = 0;

    // 首屏海报最高优先级
    if (posterConfig.isFeatured) {
        priority += 50;
    }

    // 即将过期的海报优先加载
    var now = Date.now();
    var endTime = posterConfig.endTime * 1000;
    var hoursLeft = (endTime - now) / (1000 * 60 * 60);

    if (hoursLeft < 24) {
        priority += 30;  // 24 小时内过期
    } else if (hoursLeft < 7 * 24) {
        priority += 10;  // 7 天内过期
    }

    return priority;
};

module.exports = PosterDownloader;
```

Task 1.3: 定义事件常量
```javascript
// src/common/events/CommonEvent.js
CommonEvent.POSTER_DOWNLOAD_START = 'poster_download_start';
CommonEvent.POSTER_DOWNLOAD_PROGRESS = 'poster_download_progress';
CommonEvent.POSTER_DOWNLOAD_COMPLETE = 'poster_download_complete';
CommonEvent.POSTER_DOWNLOAD_FAILED = 'poster_download_failed';
```

**Phase 2: 核心下载逻辑（✅ 完成）**

Task 2.1: 实现下载方法
- 集成到 ResourceManV2 的并发队列
- 实现失败重试逻辑
- 处理优先级排序

Task 2.2: 实现事件发送
- 下载开始时发送 `POSTER_DOWNLOAD_START`
- 单个完成时发送 `POSTER_DOWNLOAD_PROGRESS`
- 全部完成时发送 `POSTER_DOWNLOAD_COMPLETE`

**Phase 3: ResourceManV2 集成（✅ 完成）**

Task 3.1: 扩展 ResourceManV2
```javascript
// src/common/resource_v2/ResourceManV2.js
ResourceManV2.prototype.downloadPosters = function(posters, onProgress, onComplete) {
    if (!this._posterDownloader) {
        this._posterDownloader = new PosterDownloader();
    }

    return this._posterDownloader.downloadPosters(
        posters,
        {
            onProgress: onProgress,
            onComplete: onComplete
        }
    );
};
```

Task 3.2: 迁移 PosterCenterActivity
```javascript
// src/task/entity/PosterCenterActivity.js
PosterCenterActivity.prototype.startDownloadPoster = function() {
    var posterConfigs = this._buildPosterConfigs();

    // 使用新的 ResourceManV2 API
    ResourceManV2.getInstance().downloadPosters(
        posterConfigs,
        function(progress) {
            // 更新 UI 进度
            game.eventDispatcher.dispatchEvent(
                new cc.Event(CommonEvent.POSTER_DOWNLOAD_PROGRESS, progress)
            );
        },
        function(result) {
            // 处理完成
            game.eventDispatcher.dispatchEvent(
                new cc.Event(CommonEvent.POSTER_DOWNLOAD_COMPLETE, result)
            );
        }
    );
};
```

### 4.3 实施中的最佳实践

**✅ 做法**：
- 每个 Task 完成后立即运行测试
- 频繁更新 tasks.md（标记完成）
- 代码符合 code-quality spec（ES5、JSDoc、事件驱动）
- 每个任务有明确的验收标准

**❌ 避免**：
- 一次性完成所有任务再测试（难以定位问题）
- 忘记更新 tasks.md 的进度
- 跳过 spec delta 中的某个 Scenario
- 使用 ES6+ 语法

---

## 5. Stage 3: 归档变更（从 0.9 到 1.0）

### 5.1 何时归档

**前置条件**：
- ✅ 所有 tasks.md 中的任务都标记为完成 `[x]`
- ✅ 代码已部署到生产环境
- ✅ 经过测试验证，功能正常
- ✅ 不再有新的修改计划

**命令**：
```bash
openspec archive poster-resourcemanv2-migration --yes
```

### 5.2 归档时发生了什么

```bash
$ openspec archive poster-resourcemanv2-migration --yes

Proposal warnings in proposal.md (non-blocking):
  ⚠ Change must have a Why section. Missing required sections...

Task status: ✓ Complete

Specs to update:
  resource-management: update                    ← 自动检测需要更新的 specs

Applying changes to openspec/specs/resource-management/spec.md:
  + 3 added                                       ← 自动合并 delta

Specs updated successfully.

Change 'poster-resourcemanv2-migration' archived as '2025-10-29-poster-resourcemanv2-migration'.
                                                    ↑ 自动重命名，添加日期前缀
```

**自动化过程**：

| 步骤 | 操作 | 结果 |
|-----|------|------|
| 1 | 验证 `tasks.md` | 所有任务必须完成 |
| 2 | 读取 spec delta | `changes/xxx/specs/` 中的所有 `.md` |
| 3 | 合并到 specs | 将 ADDED/MODIFIED 内容合并到 `specs/` |
| 4 | 移动文件 | `changes/xxx/` → `changes/archive/YYYY-MM-DD-xxx/` |
| 5 | 验证完整性 | 运行 `openspec validate --strict` |

### 5.3 真实案例：poster-resourcemanv2-migration 归档

**归档前的 resource-management spec**：
```
openspec/specs/resource-management/spec.md (包含关于活动、章节的需求)

### Requirement: Activity Resource Download
### Requirement: Chapter Resource Download
### Requirement: Download Progress Tracking
...
```

**归档命令**：
```bash
openspec archive poster-resourcemanv2-migration --yes
```

**归档后的 resource-management spec**：
```
openspec/specs/resource-management/spec.md (新增内容已合并)

### Requirement: Activity Resource Download       ← 原有
### Requirement: Chapter Resource Download       ← 原有
### Requirement: Download Progress Tracking      ← 原有

### Requirement: Poster Resource Download Support  ← 新增
### Requirement: Poster Priority Calculation       ← 新增
### Requirement: Unified Poster Download API       ← 新增

...
```

**验证合并**：
```bash
# 查看更新后的 spec
openspec show resource-management --json | grep -i poster

# 输出应该包含新的 3 个 Poster 相关需求
```

### 5.4 归档后的同步检查

归档后，需要检查 CLAUDE.md 是否需要同步更新。使用新创建的检查清单：

```bash
# 查看检查清单（可选性指导）
cat .claude/commands/openspec-archive-checklist.md

# 按照清单逐项检查
```

**检查清单的 4 项**：

✅ **项目 1：代码规范是否有变化？**
- poster-resourcemanv2-migration 没有引入新的代码规范
- 已有的 code-quality spec 足够覆盖
- **结论**：无需更新 CLAUDE.md 代码规范

✅ **项目 2：是否需要新增触发规则？**
- 这是一个资源管理功能，不是新的工作流程
- 现有的"编写代码"规则足够
- **结论**：无需新增触发规则

✅ **项目 3：是否需要新增详细规则文件？**
- 已有 `docs/工程-工具/ai-rules/WTC/resource-management.md`（假设）
- 新功能已包含在现有规则中
- **结论**：无需新建规则文件

✅ **项目 4：项目上下文是否需要更新？**
- 没有引入新的技术依赖
- 项目信息仍然有效
- **结论**：无需更新

---

## 6. OpenSpec 与 CLAUDE.md 的整合

### 6.1 职责矩阵

经过实践和讨论，我们明确了二者的分工：

| 内容 | OpenSpec | CLAUDE.md | 权威来源 | 何时同步 |
|-----|----------|-----------|--------|---------|
| **功能需求** | ✅ specs/ (完整) | ❌ | OpenSpec | - |
| **技术架构** | ✅ design.md | ❌ | OpenSpec | - |
| **代码规范** | ✅ code-quality/spec.md | ✅ 简化版 | OpenSpec | 每次归档后 |
| **Git 工作流** | ❌ | ✅ | CLAUDE.md | - |
| **项目上下文** | ✅ project.md (技术) | ✅ Context (全局) | CLAUDE.md | 重大变更时 |
| **触发规则** | ❌ | ✅ 任务触发表 | CLAUDE.md | 新工作模式时 |

### 6.2 同步机制

**什么时候需要同步**：

```
归档 OpenSpec Change
  ↓
自动检查
  ├─ 代码规范是否有新规则？
  │  └─ 是 → 更新 CLAUDE.md 代码规范简化版
  │
  ├─ 是否引入新的工作流程？
  │  └─ 是 → 在 CLAUDE.md 任务触发规则表添加
  │
  ├─ 是否需要详细指导文档？
  │  └─ 是 → 创建 docs/工程-工具/ai-rules/*.md
  │
  └─ 技术依赖是否变化？
     └─ 是 → 更新 openspec/project.md
```

**案例：poster-resourcemanv2-migration 的同步检查**

我们在最近的一次提交中执行了这个流程。检查结果如下：

```
✅ 步骤 1: 检查代码规范变化
   → 没有新的代码规范，code-quality 规范足够

✅ 步骤 2: 检查工作流程变化
   → 没有引入新的工作模式

✅ 步骤 3: 检查文档需求
   → 功能已在现有规范中，无需新建

✅ 步骤 4: 检查技术依赖
   → 没有新的技术依赖

结论：无需同步更新
```

### 6.3 实际冲突解决示例

**问题**：最近我们发现 OpenSpec 和 CLAUDE.md 有信息重复和冲突

**冲突类型**：
```
CLAUDE.md 代码规范章节：ES5、Shell、Markdown（约 54 行详细规则）
OpenSpec code-quality/spec.md：ES5、Shell、Markdown（约 100 行完整规范）

❌ 问题：
- 两处各有完整规范，维护两份
- 修改一处遗漏另一处，导致不一致
- AI 不知道查看哪个
```

**解决方案**：
```
✅ 做法：
1. 将 CLAUDE.md 代码规范简化为快速参考（21 行）
2. 添加"权威规范指向"：pointing to openspec/specs/code-quality/spec.md
3. 在 CLAUDE.md 任务触发规则表添加 OpenSpec 触发条件
4. 添加同步机制说明

结果：
- CLAUDE.md = 工作规则 + 快速参考
- OpenSpec = 权威规范
- 清晰的职责划分 + 自动同步检查
```

**我们的成果**：
- 提交 96d69b49eaa：整合 OpenSpec 和 CLAUDE.md
- 创建了 `.claude/commands/openspec-archive-checklist.md`
- 建立了触发优先级规则

---

## 7. 重要概念深入讨论

### 7.1 Archive 的真实作用

**❌ Archive 不是**：
- Archive 不是"备份"或"废弃"
- Archive 不作为开发的规范来源
- Archive 中的旧需求不应该被参考（已合并到 specs）

**✅ Archive 是**：
- Archive 是"历史上下文"
- Archive 保留了设计决策的原因（proposal）和实施过程（tasks）
- Archive 用于理解需求的演变过程

**何时查看 Archive**：

```
场景 1：代码很奇怪，为什么这样设计？
→ 查看 archive/xxx/design.md 的"决策"部分
→ 理解当时的权衡和约束

场景 2：为什么要做这个功能？
→ 查看 archive/xxx/proposal.md 的"背景"和"问题"
→ 避免重复已解决的问题

场景 3：如何实现类似的功能？
→ 查看 archive/xxx/tasks.md 的分阶段任务
→ 学习实施模式和步骤

场景 4：当前的规范是什么？
→ 查看 specs/xxx/spec.md（不是 archive！）
→ archive 中的 delta 已经合并，不要重复查看
```

### 7.2 Spec 作为唯一真相来源

**核心理念**：

```
Current Truth = specs/ (当前规范)
  ↑
  ├─ 包含所有已完成变更的 delta
  ├─ 是开发的权威参考
  └─ 在每次 archive 时自动更新
```

**为什么这样设计**：

假设**没有**这个原则：

```
开发人员要实现新功能，需要查看：
1. specs/resource-management/spec.md (基础规范)
2. archive/2025-01-15-poster-download/specs/ (第一次迭代)
3. archive/2025-03-20-poster-optimize/specs/ (优化)
4. archive/2025-10-29-poster-resourcemanv2/specs/ (最新)

❌ 问题：
- 需要查看 4 个地方
- 容易遗漏、版本混乱
- 规范不一致风险高
```

**有了这个原则**：

```
开发人员要实现新功能，只需查看：
1. specs/resource-management/spec.md

✅ 优势：
- 单一真相来源
- 所有迭代已自动合并
- 规范始终是最新的
```

### 7.3 Delta 的正确使用

#### ADDED vs MODIFIED 的选择

**ADDED**：引入全新的、独立的需求

```markdown
## ADDED Requirements
### Requirement: Poster Resource Download Support
[新的、之前没有的需求]

#### Scenario: ...
```

**何时使用 ADDED**：
- 全新功能，之前代码中没有
- 可以独立理解的新能力
- 不修改现有需求的语义

**MODIFIED**：改变现有需求的行为

```markdown
## MODIFIED Requirements
### Requirement: Resource Download API  ← 这个需求已经存在
The system SHALL support downloading Activities, Chapters,
and **Posters** with priority queuing.  ← 添加了 Posters

#### Scenario: Download activities
- ...

#### Scenario: Download chapters
- ...

#### Scenario: Download posters  ← 新增的 Scenario
- ...
```

**何时使用 MODIFIED**：
- 扩展现有需求（添加新的 Scenario 或选项）
- 修改现有需求的描述或范围
- **关键**：必须复制完整的原需求+修改，不能只写新增部分

#### 常见错误：MODIFIED 陷阱

❌ **错误做法**（只写新增）：
```markdown
## MODIFIED Requirements
### Requirement: Resource Download API
- 新增海报支持  ← 只写了新增，遗漏了原有的 Activities、Chapters！

归档时的结果：原有需求被覆盖，Activities 和 Chapters 需求丢失！
```

✅ **正确做法**（复制完整需求）：
```markdown
## MODIFIED Requirements
### Requirement: Resource Download API
The system SHALL support downloading Activities, Chapters, and Posters
with priority queuing and retry logic.

#### Scenario: Download activities with priority
- **WHEN** Multiple activities queued with different priorities
- **THEN** High-priority activities download first

#### Scenario: Download chapters with priority
- **WHEN** Multiple chapters queued
- **THEN** Chapters load sequentially after activities

#### Scenario: Download posters with priority  ← 新增
- **WHEN** Posters queued with expiration-based priority
- **THEN** Soon-to-expire posters download first
```

---

## 8. 最佳实践与避坑指南

### 8.1 Scenario 格式的严格要求

OpenSpec 对 Scenario 格式有严格要求，以支持自动化解析。

✅ **完全正确的格式**：
```markdown
#### Scenario: Poster resources download by priority
- **WHEN** Multiple poster resources are queued with different priorities
- **THEN** High-priority posters (expiring soon) download first
```

❌ **常见错误**（5 种）：

| 错误 | 示例 | 问题 |
|-----|------|------|
| 标题级别错 | `## Scenario: ...` | 需要 4 个 `#` |
| 使用 bullet | `- **Scenario**: ...` | 需要 `#### Scenario:` |
| 缺少冒号 | `#### Scenario Poster download` | 需要冒号 |
| 格式不统一 | `**WHEN** ...\n**THEN** ...` | 必须用 `- **WHEN**` 格式 |
| 多行 WHEN/THEN | 缺少单独的 WHEN 行 | 每个标记单独成行 |

**调试技巧**：
```bash
# 检查 Scenario 是否被正确解析
openspec show poster-resourcemanv2-migration --json --deltas-only

# 查看 scenarios 数组，应该包含所有你写的 Scenario
# 如果为空，说明格式有问题
```

### 8.2 我们踩过的坑（真实案例）

#### 坑 1：proposal.md 的"Why"和"What Changes"章节缺失

**问题**：
```markdown
# Proposal: ...

## 背景
...
## 目标
...

# 没有 ## Why 和 ## What Changes
```

**错误信息**：
```
Proposal warnings in proposal.md (non-blocking):
  ⚠ Change must have a Why section. Missing required sections.
```

**解决**：添加规范章节
```markdown
## Why
[背景和原因的简化版本]

## What Changes
- 创建 PosterDownloader 类
- 集成到 ResourceManV2
- 添加事件系统支持
- ...
```

#### 坑 2：Scenario 没有被识别（格式问题）

**问题**：
```markdown
## ADDED Requirements
### Requirement: Poster Priority
...

# 忘记了 #### Scenario 部分
```

**错误**：
```
Requirement must have at least one scenario
```

**解决**：添加正确格式的 Scenario
```markdown
#### Scenario: Featured posters prioritized
- **WHEN** Poster type is featured
- **THEN** Priority increases by 30 points
```

#### 坑 3：MODIFIED 陷阱（丢失原有需求）

**问题**：
```markdown
## MODIFIED Requirements
### Requirement: Resource Download
现在支持海报  ← 只写了新增，没有复制原有内容
```

**结果**：归档时只保留"现在支持海报"，Activities 和 Chapters 需求被覆盖。

**解决**：复制完整需求，然后修改
```markdown
## MODIFIED Requirements
### Requirement: Resource Download
The system SHALL download Activities, Chapters, and **Posters**
with concurrent queue management.

#### Scenario: Download activities
- ...

#### Scenario: Download chapters
- ...

#### Scenario: Download posters
- **WHEN** Multiple posters queued
- **THEN** Download by priority
```

#### 坑 4：Tasks.md 不够详细（无法追踪）

**问题**：
```markdown
## 实施清单
- [ ] 实现海报下载
- [ ] 测试
```

**问题**：太大，无法追踪进度，难以估算工作量

**解决**：分阶段、分任务
```markdown
## Phase 1: 基础设施
- [ ] Task 1.1: 调查现有实现 (0.5 小时)
  - 审查 PosterCenterActivity
  - 确定海报配置结构

- [ ] Task 1.2: 创建 PosterDownloader 类 (1 小时)
  - 继承 BaseDownloader
  - 实现基础方法框架

## Phase 2: 核心逻辑
- [ ] Task 2.1: 实现下载方法 (1.5 小时)
  - 集成并发队列
  - 处理失败重试
```

### 8.3 验证技巧和调试

**完整的 3 步验证流程**：

```bash
# 步骤 1：快速验证（基础检查）
openspec validate poster-resourcemanv2-migration

# 步骤 2：严格验证（完整检查）
openspec validate poster-resourcemanv2-migration --strict

# 步骤 3：详细调试（查看解析结果）
openspec show poster-resourcemanv2-migration --json --deltas-only | jq '.deltas'
```

**常见验证错误**及解决：

| 错误信息 | 原因 | 解决 |
|--------|------|------|
| "Change must have at least one delta" | 没有 specs/ 目录 | 创建 `openspec/changes/xxx/specs/[cap]/spec.md` |
| "Requirement must have at least one scenario" | Scenario 格式错 | 检查 `#### Scenario:` |
| Task status: Incomplete | tasks.md 有未完成的任务 | 标记所有 `[x]` |
| "Spec not found: xxx" | 引用了不存在的 spec | 检查 spec 名称拼写 |

---

## 9. 工具命令速查表

### 核心命令

```bash
# 列出所有活跃的 changes（正在进行中）
openspec list

# 列出所有 specs（已完成的规范）
openspec list --specs

# 查看某个 change 的详情
openspec show poster-resourcemanv2-migration

# 查看某个 spec 的详情
openspec show resource-management --type spec

# 显示 delta 的 JSON 格式（用于调试）
openspec show poster-resourcemanv2-migration --json --deltas-only
```

### 验证命令

```bash
# 基础验证
openspec validate poster-resourcemanv2-migration

# 严格验证（推荐）
openspec validate poster-resourcemanv2-migration --strict

# 验证所有 specs
openspec validate --specs --strict

# 验证所有 changes
openspec validate --changes --strict
```

### 归档命令

```bash
# 非交互式归档（推荐在自动化中使用）
openspec archive poster-resourcemanv2-migration --yes

# 交互式归档（会询问确认）
openspec archive poster-resourcemanv2-migration

# 查看归档帮助
openspec archive --help
```

### 初始化和更新

```bash
# 初始化 OpenSpec（仅一次）
openspec init .

# 更新 OpenSpec 指令文件
openspec update .
```

---

## 10. 附录

### 10.1 poster-resourcemanv2-migration 完整文件结构

```
openspec/changes/archive/2025-10-29-poster-resourcemanv2-migration/
├── proposal.md                     (2630 字)
│   ├── 背景（5 个问题）
│   ├── 目标（5 个目标）
│   ├── 范围（包括 5 项，不包括 3 项）
│   ├── 验收标准（功能、代码质量、架构）
│   ├── 预期工作量（6-11 小时分次进行）
│   └── 风险（3 个风险及缓解策略）
│
├── design.md                       (6593 字)
│   ├── 架构概览（ASCII 图）
│   ├── PosterDownloader 设计
│   │   ├── 位置：src/common/resource_v2/downloaders/
│   │   ├── 职责（4 项）
│   │   └── 关键方法（3 个）
│   ├── ResourceManV2 扩展
│   ├── 事件系统设计
│   ├── 优先级算法
│   └── 集成流程
│
├── tasks.md                        (6312 字)
│   ├── Phase 1: 基础设施 (4 个任务，3-4 小时)
│   ├── Phase 2: 核心逻辑 (2 个任务，2-3 小时)
│   ├── Phase 3: 集成 (2 个任务，1-2 小时)
│   └── Phase 4: 测试和优化 (2 个任务，1-2 小时)
│
├── PROGRESS.md                     (5003 字)
│   ├── 完成日期和进度跟踪
│   ├── 各 Phase 的完成情况
│   └── 最终验收状态
│
└── specs/
    └── resource-management/
        └── spec.md                 (delta 规范)
            ├── ## ADDED Requirements
            │   ├── Poster Resource Download Support (4 scenarios)
            │   ├── Poster Priority Calculation (3 scenarios)
            │   ├── Unified Poster Download API (2 scenarios)
            │   ├── Silent Loading Support (2 scenarios)
            │   └── Download Progress Tracking (2 scenarios)
            │
            └── 总计 5 个新需求，13 个 scenarios
```

### 10.2 相关文档链接

| 文档 | 路径 | 用途 |
|-----|------|------|
| OpenSpec 代理指南 | `openspec/AGENTS.md` | AI 助手使用 OpenSpec 的详细规则 |
| 项目规范 | `openspec/project.md` | WorldTourCasino 技术上下文 |
| 代码质量规范 | `openspec/specs/code-quality/spec.md` | ES5、JSDoc、架构原则 |
| 资源管理规范 | `openspec/specs/resource-management/spec.md` | 活动、章节、海报下载规范 |
| CLAUDE.md | `/CLAUDE.md` | 项目全局规则和上下文 |
| 归档检查清单 | `.claude/commands/openspec-archive-checklist.md` | 归档后的同步检查 |
| Shell 脚本规范 | `docs/工程-工具/ai-rules/WTC/shell-scripts.md` | Shell 脚本规范 |

### 10.3 FAQ 和常见问题

**Q: 我应该什么时候创建 Change？**
A: 添加新功能、改变架构、做 Breaking Change 时。不要为简单的 Bug 修复创建 Change。

**Q: Scenario 格式一定要用 `#### Scenario:`？**
A: 是的。OpenSpec 的解析器严格匹配 4 个 `#` 和冒号。其他格式（bullet、其他标题级别）不会被识别。

**Q: 我能同时有多个活跃的 Changes 吗？**
A: 可以。但要避免它们修改同一个 spec，防止冲突。

**Q: Archive 中的文件我能删除吗？**
A: 不建议。Archive 是历史记录，保留完整性对后续理解有帮助。

**Q: 如果我遗漏了 Scenario，会怎样？**
A: 验证时会报错："Requirement must have at least one scenario"。归档时也会失败。

**Q: Delta 自动合并时，如果有重名需求怎么办？**
A: OpenSpec 按需求标题（`### Requirement: ...`）精确匹配。如果标题相同，MODIFIED 会覆盖原需求。要避免，使用 ADDED 创建新需求。

**Q: OpenSpec 和我们的 Code Review 流程如何配合？**
A: 建议在 Stage 2（实施）中进行 Code Review，确保代码符合 spec。归档前验证所有 scenarios 都满足。

---

## 总结

通过完成 **poster-resourcemanv2-migration** 这个完整的 OpenSpec 流程，我们：

✅ **第一次成功地**使用规范驱动开发方法
✅ **清晰地**定义了功能需求（Spec Delta）
✅ **系统地**追踪了实施过程（Tasks）
✅ **完整地**记录了架构决策（Design）
✅ **自动地**更新了规范基准（Specs）

**核心收获**：

1. **Spec 是唯一真相**：所有开发决策都应该基于 `specs/`，而不是分散的各个地方
2. **Delta 驱动演进**：通过 ADDED/MODIFIED/REMOVED 清晰地表达变化
3. **Archive 记录历史**：为什么和怎么做的决策过程保留在 archive，便于未来参考
4. **职责明确**：OpenSpec 管规范，CLAUDE.md 管工作流，各司其职
5. **可重复的流程**：三阶段工作流（创建→实施→归档）可用于所有功能开发

**下一步建议**：

- 在下一个功能开发中应用这个流程
- 根据实际情况调整 tasks.md 的粒度
- 定期检查 `openspec validate --specs` 的一致性
- 记录更多案例，形成团队的最佳实践库

---

**文档版本**: 1.0
**创建时间**: 2025-10-29
**基于真实案例**: poster-resourcemanv2-migration (commit 96d69b49eaa)
**维护者**: WorldTourCasino Team
