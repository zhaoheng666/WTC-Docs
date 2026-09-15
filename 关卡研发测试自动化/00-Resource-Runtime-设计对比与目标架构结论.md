---
title: Resource Runtime 设计对比与目标架构结论
---

# Resource Runtime 设计对比与目标架构结论

> 源自飞书文档 · 最后同步：2026-09-15

## 1. 文档目的

本文记录对当前 `src/resource_runtime/` 设计的架构复核，以及针对

`BundleSession` 暴露问题形成的目标结论。本文只描述资源 Runtime 的边界与

迁移方向，不替代 OpenSpec 行为契约；正式行为以 `openspec/specs/` 与当前

Change 为准。

## 2. 当前设计与目标设计对比

| 维度 | 当前实现 | 目标设计 | 判断 |
| --- | --- | --- | --- |
| Runtime 选择 | `ResourceCompositionRoot` 已能按 product/platform/runtime 选择并固定实例 | 继续由唯一组合根选择；选择结果向下不可变 | 基础方向正确 |
| 会话入口 | `BundleSession` 既是 Bundle 会话编排者，又作为业务公共 API 被多个业务模块直接 `require` | 会话对象只能是 Runtime 内部实现；业务不得依赖 `BundleSession` | 当前存在侵入，需要收敛 |
| 业务接入 | `main.js`、Controller、Manager、`resource_v2` 中直接判断 `isEnabled` 并调用 `BundleSession` / `ActivityRuntimeBridge` | 业务只向统一顶层调度者提交资源意图，消费统一领域结果、取消句柄和生命周期句柄 | 当前仍是运行时分支泄漏 |
| Runtime 隔离 | 三种 Runtime 已有同级目录和选择校验；但共享业务代码内存在 Bundle 判断 | Bundle、resource-list、manifest 的差异只存在调度者与 Runtime 内部 | 结构隔离已有，调用隔离未完成 |
| Bundle 内部 | `BundleSession` 组装 Catalog、Facade、Activity/Feature/Slot/Lobby 服务 | Runtime 内部自行组装，业务只看到稳定的领域端口 | `BundleSession` 位置可保留，公开面必须关闭 |
| 兼容资源 | Bundle Runtime 内懒加载 `ResourceListCompatAdapter`，由登记表控制动态路由 | 兼容路由只能由 Bundle Runtime 内部调度，不得成为业务 fallback | 方向正确 |
| 引擎驻留 | `EngineResidencyGuard` 跨 Bundle/兼容端口保护实际引擎键和物理释放 | 继续作为跨路由基础设施，但不拥有 Bundle 状态、不接触业务 | 方向正确 |
| 领域适配 | Activity、Feature、Slot、Lobby 已有 Adapter/Guard/Bridge | 这些应成为 Runtime 私有适配层，由统一调度者驱动 | 需要调整依赖方向 |

## 3. 关键结论

### 3.1 `BundleSession` 不应暴露给原有业务

这个判断成立，而且是边界是否真正非侵入式的关键标准。当前业务直接依赖

`BundleSession` 的方式，使业务代码知道：

- 当前是否启用 Bundle；
- Bundle 的具体会话 API；
- Startup、Lobby、Slot、Feature、Activity 的 Bundle 专用调用方式；
- 何时释放 Bundle Lease、何时构造或销毁 Bundle 场景。
这会让 Runtime 选择从顶层向业务层泄漏。即便业务仍保留原有业务状态机，资源

语义已经变成了业务代码中的条件分支，因此仍属于侵入式设计。

### 3.2 必须增加“统一顶层资源调度者”边界

目标调用方向应收敛为：

```
原有业务逻辑
    -> 统一顶层资源调度者
        -> ResourceCompositionRoot（一次选择并固定）
            -> BundleResourceRuntime
            -> ResourceListRuntime
            -> ManifestRuntime
        <- 统一领域结果 / 请求句柄 / 生命周期句柄
    <- 原有业务逻辑继续执行
```

这里的“调度者”不是再次复制业务状态机，也不是一个新的业务 Manager。它只

负责把业务提出的资源意图翻译为统一资源请求，把请求交给已固定的 Runtime，

并把 Runtime 的结果归一化后交还业务。

### 3.3 Runtime 层级以下不得反向干预原有业务

从 `BundleResourceRuntime`、`ResourceListRuntime`、`ManifestRuntime` 开始，

只能依赖：

- Host ports：引擎、网络、存储、平台能力；
- Domain ports：由顶层调度者注入的业务身份与结果端口；
- Runtime 自身的资源协议、状态、缓存、调度和生命周期实现。
不得依赖或调用原有业务 Manager、业务 UI 工厂、业务状态机和业务私有回调。

Runtime 可以返回“准备成功、失败、取消、可释放句柄”等资源结果，但不能自行

决定业务激活、奖励、资格、支付或 UI 展示。

### 3.4 三种 Runtime 必须是互斥实现，不是运行时互相 fallback

一次会话只选择一种 Runtime。Bundle 失败时不得退回 resource-list；Native

manifest 不得初始化 Browser Bundle；保留 Browser 也不得构造 DH Bundle

Catalog 或 registry。Bundle 内允许存在“显式登记的旧动态资源兼容路由”，但这

是 Bundle Runtime 的内部能力，不是 Runtime 之间的切换。

## 4. 目标边界与职责

### 顶层调度者

- 接收业务资源意图，例如 `prepareLobby`、`prepareFeature`、`prepareActivity`、
`prepareSlot`、`prefetch`；

- 持有 `ResourceCompositionRoot` 的选择结果；
- 向选定 Runtime 请求资源；
- 将不同 Runtime 的结果映射为统一领域结果；
- 管理请求句柄和交付后的生命周期句柄；
- 负责运行时不透明性，业务不读取 Runtime 类型。
### `ResourceCompositionRoot`

- 读取构建配置与宿主能力；
- 只选择一次 `bundle`、`resource-list` 或 `manifest`；
- 拒绝不支持的 product/platform/runtime 组合；
- 复用同一会话中的兼容选择；
- 在会话结束时关闭 Runtime，隔离旧 generation 的迟到回调。
### `BundleResourceRuntime`

- 组装并持有 Bundle 专用资源服务；
- 管理 Catalog、依赖闭包、Bundle operation、Scheduler、Cache、ReferenceTracker；
- 通过领域适配器处理 Activity、Feature、Slot、Lobby 资源身份；
- 通过兼容登记表处理少量旧动态资源；
- 通过 `EngineResidencyGuard` 保护引擎实际驻留；
- 不调用原有业务逻辑，不直接创建或激活业务对象。
### `ResourceListRuntime` / `ManifestRuntime`

- 作为保留路径的薄边界；
- 只包装既有 resource-list 或 Native manifest 能力；
- 不消费 Bundle Catalog、Bundle registry 或 Bundle Lease；
- 不依赖 BundleSession。
## 5. 迁移原则

1. 先建立统一调度者的稳定接口，再迁移业务入口；不要让业务先适配新的
`BundleSession` API。

1. 将 `BundleSession` 的公开方法拆为 Runtime 内部职责和顶层调度者职责；
迁移完成后，业务源码中不得出现 `require(.../BundleSession)`。

1. `ActivityRuntimeBridge`、`FeatureEntryGuard`、`SlotRuntimeBridge`、Lobby
编排等保留在 `bundle/domains/`，但只能由 Bundle Runtime 或顶层调度者注入和

驱动，不能成为业务自行选择 Bundle 的入口。

1. 删除业务层 `isEnabled` 分支；兼容行为由组合根和调度者屏蔽。
1. 保留业务身份、资格、奖励、支付和 UI 工厂在原业务层；Runtime 只返回资源
结果与句柄。

1. 以静态依赖检查作为硬门禁：业务目录不得反向依赖具体 Runtime 实现；
Runtime 不得依赖业务 Manager。

## 6. 图示

目标全景结构图使用 Archify 表达，源文件为：

`docs/架构/resource-runtime-target.architecture.json`。

图中重点表达三件事：统一顶层调度者是业务与 Runtime 之间的唯一入口；三种

Runtime 在选择后互斥隔离；Bundle 内部核心、兼容路由和引擎驻留保护均不反向

进入原有业务逻辑。

## 7. 当前实现差距

当前代码已经完成 `resource_runtime/` 的功能分层、组合根和三种 Runtime 薄

边界，但还没有达到上述“业务零直接依赖”的目标。代表性差距包括：

- `src/main.js` 直接持有 `BundleSession` 并驱动 Bundle bootstrap；
- 多个 `src/common`、`src/social`、`src/task`、`src/slot` 入口直接调用
`BundleSession`；

- `ActivityRuntimeBridge` 反向依赖 `BundleSession`；
- 共享业务和 `resource_v2` 中仍存在 `isEnabled` 条件分流。
这些不是对现有功能分层的否定，而是下一阶段要清理的接线层侵入。当前

`BundleSession` 可以作为迁移期内部实现继续存在，但不应继续增加新的业务

调用方。
