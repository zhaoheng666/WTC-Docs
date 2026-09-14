# Bundle 资源运行时改造方案（评审 HandOff）

> 状态：待评审，暂不进入 OpenSpec 提案阶段
> 适用分支：`classic_vegas_web_refactor`
> 目标：在不破坏 `classic_master` 稳定线上逻辑的前提下，完成浏览器端 Bundle 资源加载改造，并为未来 Native Bundle 化保留演进空间。

## 1. 本文目的

本文不是实施提案，也不是当前分支的验收结论，而是供其他开发者和 Agent 独立评审的架构 HandOff。评审重点是：

1. 当前分支哪些改动已经偏离“非侵入、按 Runtime 分流、旧逻辑可并行维护”的初始原则。
2. 如何重新定义 `resource_list`、`manifest`、`Bundles` 三种资源方式及其边界。
3. 如何将 Bundle 改造收敛到少量组合根、资源入口和必要的启动/大厅破坏性变更点。
4. 如何避免该分支合并到 `classic_master` 后，把 Bundle 试验逻辑扩散到稳定在线路径。

本文只修改文档，不修改代码、不创建 Change、不改变当前 OpenSpec 状态。

---

## 2. 需要先统一的设计认识

### 2.1 “新老模式”不应按平台定义

原有表述把“Legacy”和“Browser Bundle”近似当成平台模式，容易造成错误的架构边界。更准确的定义应当是**资源运行时 / 资源加载方式**：

| 资源方式 | 主要服务对象 | 典型工件 | 当前职责 |
| --- | --- | --- | --- |
| `resource_list` | 旧浏览器端 | `resource_list/**/*.json` 与 Cocos Loader | 目录清单驱动的按需加载、旧活动框架和部分动态资源 |
| `manifest` | Native 端 | Native manifest、下载目录和本地缓存 | Native 资源下载、校验、版本和文件系统缓存 |
| `Bundles` | 当前浏览器改造目标；未来可扩展到 Native | Global Catalog、Bundle manifest、registry、Lease | 按业务闭包准备资源、共享 operation、生命周期和缓存治理 |

因此，不能简单说“Browser 用新模式、Native 用旧模式”。正确表达是：

- 当前 DH Browser 的目标入口选择 `BundleResourceRuntime`。
- 当前 DH Native 与 CV 等保留路径继续选择既有资源运行时。
- `BundleResourceRuntime` 内部允许对尚未 Bundle 化、且明确登记为旧动态资源的请求，使用 `resource_list` 适配器完成加载。
- 这不是 Bundle 失败后的兜底，而是**发布/运行时明确声明的资源路由**。
- 未来 Native Bundle 化时，只替换组合根选择或宿主适配，不应重写业务层和 Bundle 语义。

### 2.2 Bundle 目标是最终替代，不等于立即删除 resource_list

短期共存必须有清晰的两个维度：

1. **顶层 Runtime 选择**：决定本次游戏会话由谁负责资源语义和生命周期。
2. **Bundle Runtime 内部的资源路由**：对每个资源身份决定走 Bundle 还是显式的 `resource_list` 兼容适配器。

允许的结构：

```text
组合根选择 BundleResourceRuntime
    ├── BundleResourceAdapter       正式 Bundle 身份
    ├── ResourceListCompatAdapter   已登记的旧动态资源身份
    └── Manifest/Native 不在本次 Browser 组合中
```

不允许的结构：

```text
Bundle prepare 失败
    └── 猜测目录名或回退 resource_list
```

后者会掩盖 Bundle 发布缺陷，破坏失败可诊断性，也会让新旧资源闭包互相污染。

### 2.3 正式 Runtime 分流不能与 local/test/release 混在一起

`local`、`test`、`release` 是部署和验收环境策略；它们不应承担“是否使用 Bundle Runtime”的职责。

当前 `BrowserBundleLocalTestPolicy` 是错误的抽象方向：它把运行时资源所有权绑定到本地验收开关，造成以下风险：

- 本地代码路径和正式代码路径不一致。
- 同一 DH Browser 在不同配置下触发不同的大厅、Flagstone、Activity 逻辑。
- `classic_master` 合并后难以判断某个分支是正式 Runtime 行为还是测试捷径。
- 测试通过的路径不能证明正式 Bundle Runtime 可用。

建议删除该策略在正式业务分流中的职责。测试只应通过注入的 Runtime、宿主端口、Catalog/Loader fixture 和测试配置验证同一套正式语义；不能通过业务代码中的 `if (localTest)` 跳过初始化或伪造数据门禁。

---

## 3. 当前分支的主要偏离点

本结论基于当前分支相对 Bundle 改造基线的代码和提交历史，重点关注运行时边界，不评价所有资源生成工件的内容正确性。

### 3.1 分流点已从组合根扩散到共享业务代码

当前 `DHBrowserBundleSession.isEnabled(...)` 被多个共享模块直接调用，涉及启动、登录加载、场景切换、Flagstone、Slot、Activity、CardSystem、HighRoller、Store、RoyalClub、Inbox、Lottery 等路径；并且部分模块直接持有 `DHBrowserBundleSession`，部分模块持有 `ActivityRuntimeBridge`，另有部分模块持有 `BrowserBundleLocalTestPolicy`。

这形成了多套分流机制：

- Session 级分流。
- Activity Bridge 级分流。
- Local Test Policy 分流。
- `cc.sys.isNative` 分支。
- 个别业务 manager 自己判断后改变行为。

结果是“单一 Runtime 选择”没有真正成立，业务层变成了资源平台适配层。

### 3.2 `resource_v2` 与 Bundle Runtime 的职责边界不清

当前 `resource_v2/loaders/ActivityLoader.js`、`ClubActivityLoader.js`、`FlagStoneLoader.js`、`SlotLoader.js`、`SlotPreDownloadMan.js` 等既保留原有 `resource_list`/Native 逻辑，又直接调用 Bundle Session 或 Activity Bridge。

这会产生两个问题：

1. `resource_v2` 不再只是既有资源运行时，而变成了 Bundle Runtime 的部分组合根。
2. 同一个业务请求可能先经过旧 Loader 的语义，再在 Loader 内部被改写成 Bundle 请求，无法清晰证明哪个 Runtime 持有下载、缓存、错误和 Lease 所有权。

尤其是 `SlotRoomLoadingController` 这类加载流程中，Bundle 准备成功后仍调用 `getSlotLoader().loadSlotResource()`。即使该调用当前可能是空操作或兼容动作，也会让 Bundle 闭包和旧 Slot Loader 的职责重叠，后续维护非常容易重新引入重复加载或旧清单依赖。

### 3.3 大量业务文件承担了资源生命周期接线

当前改动在大量既有 manager/controller 中增加：

- Bundle Session 判断。
- Bundle prepare/open/activate/release。
- 失败后的重试或加载 UI 处理。
- CCB 创建前后的 Lease 交接。
- 旧 Loader 的跳过逻辑。

这些逻辑在 HighRoller、CardSystem、Activity、Club、Store、Inbox、Lottery、Slot 等多个领域重复出现。它们虽然实现了部分正确的 Lease 语义，但从合流维护角度看，已经扩大了稳定业务文件的冲突面，且同一资源生命周期规则分散在不同业务层。

### 3.4 启动、大厅和首屏改动属于允许的破坏性范围，但必须集中

`src/main.js`、登录加载、Lobby 初始化、首屏资源门禁确实是 Bundle 改造必须改变的地方。这里允许类/文件级分流，因为启动资源方式本身发生了变化。

但目前启动分流同时影响：

- 首屏加载和登录顺序。
- Lobby 数据 mask。
- Flagstone 入口创建。
- Activity 后置加载。
- 测试环境静态验收。

因此需要把它们收敛到一个明确的 Browser 组合根和几个有边界的流程适配器，而不是继续把判断散落到业务初始化函数中。

### 3.5 发布侧改动规模远大于运行时改动，但不能反推运行时耦合

当前分支包含大量 `res_doublehit/bundles`、Catalog、Source Descriptor、validation report 和发布脚本变更。这些是资源改造的必要产物，但它们不应成为业务代码直接查询资源路径的理由。

发布侧应只输出：

- 稳定 Bundle identity。
- 依赖关系。
- manifest/version/Catalog。
- 运行时 registry。
- 已明确的 `resource_list` 兼容资源路由。

业务代码不应读取发布目录结构，也不应自行拼接 Bundle ID、资源目录或 `resource_list` 路径。

---

## 4. 目标架构

### 4.1 顶层命名

正式命名统一为：

- `BundleResourceRuntime`：Bundles 资源运行时。当前主要用于 DH Browser，未来可以在 Native 组合根中启用。
- `ResourceListRuntime`：既有浏览器 `resource_list` 运行时，作为保留运行时或 Bundle Runtime 的兼容适配器来源。
- `ManifestRuntime`：既有 Native manifest 资源运行时。
- `ResourceRuntime`：如确实需要公共抽象，可作为接口名或组合根选择结果，不作为三种实现的混合名称。

不再引入 `HybridBrowserResourceRuntime`、`BrowserBundleLocalTestPolicy` 等强调临时平台或临时环境的正式命名。

### 4.2 组合根是唯一顶层分流点

建议增加一个非常薄的组合根，例如：

```text
ResourceCompositionRoot.create({
    product: 'dh',
    platform: 'browser' | 'native',
    runtime: 'bundle' | 'resource-list' | 'manifest',
    hostPorts: ...
})
```

实际字段名可调整，但责任必须固定：

| 组合 | 选择 |
| --- | --- |
| DH Browser Bundle 组合 | `BundleResourceRuntime` |
| DH Browser 保留组合 | `ResourceListRuntime` |
| DH Native 当前组合 | `ManifestRuntime` |
| CV/其他保留组合 | 既有 Runtime，不读取 DH Bundle registry |
| 未来 Native Bundle 组合 | `BundleResourceRuntime` + Native ports |

业务层只拿到稳定的领域资源接口或 `ResourceRuntime`，不判断 platform，不判断 local/test/release，不直接选择 Loader。

### 4.3 `resource_v2` 的关系必须明确为“实现/兼容来源”，不是 Bundle Runtime 本体

建议采用以下边界：

```text
ResourceCompositionRoot
    ├── BundleResourceRuntime
    │     ├── BundleResourceFacade / BundleCoordinator
    │     └── ResourceListCompatAdapter（仅显式登记的旧动态资源）
    ├── ResourceListRuntime
    │     └── resource_v2 既有 Web Loader
    └── ManifestRuntime
          └── resource_v2 Native Loader / manifest 逻辑
```

具体有两种可选落地方式，需评审后定一项：

#### 方案 A：Bundle Runtime 与 resource_v2 完全分离（推荐长期方向）

- Bundle Runtime 自己拥有 Bundle catalog、operation、cache、Lease、错误和取消。
- `resource_v2` 保持旧 Web/Native 资源运行时。
- Bundle Runtime 通过极薄的 `ResourceListCompatAdapter` 调用旧 `resource_v2` 的稳定语义接口。
- Bundle Runtime 不把旧 Loader 注册到自己的 LoaderRegistry，也不让旧 Loader 改写 Bundle operation。

优点是所有权最清楚、未来 Native Bundle 化最容易。缺点是需要为兼容动态资源定义稳定适配接口。

#### 方案 B：抽取 resource_v2 的底层能力，运行时仍分离（过渡方案）

- 保留 `resource_v2` 的外部 Loader 行为。
- 抽取不含平台分流的下载、文件、Cocos asset 和进度端口。
- Bundle Runtime 和旧 Runtime 共享这些底层端口，但不共享上层状态机。

优点是短期复用成本较低。缺点是抽取边界容易反向污染，必须禁止共享全局状态、下载队列和 Lease。

无论选择 A 或 B，都不建议把 Bundle 分支条件直接加进每个 `resource_v2` Loader。

### 4.4 Bundle Runtime 内部允许“显式旧资源路由”，禁止“失败 fallback”

资源身份应由生成 registry 或运行时路由表声明：

```json
{
  "identity": "coupon.some-old-flow",
  "route": "resource-list",
  "reason": "旧框架动态资源，尚未 Bundle 化",
  "owner": "coupon-runtime"
}
```

规则：

- Bundle identity：由 Bundle Facade 准备完整闭包并产生独立 Lease。
- Legacy dynamic identity：由兼容适配器调用 `resource_list` 语义，使用其既有生命周期契约。
- 未登记 identity：失败并阻断，不猜测目录。
- Bundle manifest/catalog/下载/解码/校验失败：失败并阻断，不自动转 `resource_list`。
- 旧资源路由成功：不能伪装成 Bundle Lease，也不能进入 Bundle Catalog 闭包。

---

## 5. 代码改造策略：最小侵入而不是全量包装

### 5.1 不对“所有资源逻辑”增加一层业务包装

全量给每个资源调用加包装器，确实是侵入式方案，会带来大量代码修改、冲突和重复验证，不建议采用。

更好的方式是识别**资源加载的少数真实 choke point**，只在这些位置接入 Runtime：

1. 启动资源准备入口。
2. Lobby 首屏/大厅 Bundle 准备入口。
3. Slot 进入和 Flagstone 入口准备入口。
4. Activity/Feature 的正式入口 Adapter。
5. 仍需动态 `resource_list` 的旧框架资源入口。
6. 统一 Cocos/网络/解码/缓存端口。

普通业务代码继续调用已有业务方法；只有当该业务入口确实改变了资源准备时序，才通过领域 Adapter 接入 Bundle Runtime。

### 5.2 允许破坏性修改的文件级范围

以下范围可以保留明确的类/文件级分流，因为它们的时序契约发生了真实改变：

- `src/main.js`：启动组合根和首屏资源启动。
- 登录加载/首屏加载控制器：Bundle startup plan 与旧启动清单的选择。
- Lobby 场景组合/初始化：Lobby Bundle、数据门禁和入口生命周期。
- Slot 进入加载流程：服务器门禁、Bundle 准备、配置安装、场景激活顺序。
- Bundle Runtime 新目录：Coordinator、Facade、Adapter、registry、ports。

即使在上述文件内，也应将分流写成一个明确的流程入口，例如 `startBundleRuntime()` 与 `startResourceListRuntime()`，不要在同一个业务函数中交错执行两种资源语义。

### 5.3 应尽量回退/收敛的共享业务改动

以下类型的改动应在后续 rework 中优先减少：

- 业务 manager 中到处调用 `DHBrowserBundleSession.isEnabled`。
- 业务层直接调用 `prepare/open/activate/release` 的重复编排。
- `resource_v2` 各 Loader 内部加入 Bundle 分支。
- `BrowserBundleLocalTestPolicy` 改变正式业务行为。
- 为了 Bundle 而在 CV、Native 或其他风格代码中引入 DH Bundle 依赖。
- Bundle 准备成功后再次调用旧 Loader 做同一资源的加载。

这些逻辑应迁移到组合根、领域资源 Adapter 或明确的生命周期绑定组件；业务层只保留“准备成功后创建 UI/场景”和“自身生命周期结束时释放已交付句柄”。

---

## 6. 各领域的建议边界

| 领域 | 必要改造 | 保留旧逻辑 |
| --- | --- | --- |
| Startup | Bundle startup plan、Catalog、loading Bundle、启动顺序 | 非 Bundle 组合原有加载顺序 |
| Lobby | 首屏 Bundle、Lobby 数据门禁、Bundle 入口占位/Lease | 未迁移动态功能显式走旧资源路由 |
| Slot | registry identity、按需配置闭包、场景激活前 Lease | Native/CV/保留 Browser 的旧 Slot Loader |
| Activity | Activity registry、前台 Lease、静默预取 | 未迁移 Activity 的 `resource_list` 动态加载 |
| Feature | Feature identity Adapter、前台 Lease | 尚未 Bundle 化的 Feature 旧入口 |
| CardSystem/HR/Store 等 | 通过领域 Adapter 接入，不在 manager 内重复编排 | 非 DH Bundle Runtime 不读取 Bundle registry |
| 宣发/Coupon 等旧框架 | 登记为 `resource-list` 兼容资源路由 | 继续使用既有动态加载语义 |

“保留旧逻辑”不表示 Bundle Runtime 失败时回退，而表示该资源身份在 Bundle Runtime 的路由表中从一开始就选择旧适配器。

---

## 7. 合并到 `classic_master` 的策略

### 7.1 不建议直接整体合并当前分支

当前分支包含大量共享业务文件、生成产物和验证报告变更。直接将整个分支合并到 `classic_master` 会把：

- Bundle 分支条件。
- 临时测试策略。
- 领域生命周期改动。
- 大量资源工件。
- 可能尚未完成的 active Change 工件。

一次性带入稳定主线，冲突和回归面都过大。

### 7.2 建议采用“新目录先行 + 少量接线 + 分阶段合流”

合流单元建议按以下顺序拆分：

1. **Runtime 核心单元**：Bundle Runtime 新目录、ports、Facade、Coordinator、registry 校验和单元测试；不改变旧业务行为。
2. **资源兼容单元**：`ResourceListCompatAdapter`，只定义已登记旧动态资源的调用协议。
3. **Startup 单元**：组合根接线和启动流程分流；保留旧启动路径可独立运行。
4. **Lobby 单元**：大厅首屏和入口生命周期；只修改必要的 Lobby 组合文件。
5. **领域单元**：按 HR、CardSystem、Slot、Activity 等业务入口逐个接入 Adapter。
6. **发布单元**：Bundle Catalog/manifest/registry 与生成校验；发布产物按对应领域单元进入。
7. **清理单元**：删除重复分流、废弃 LocalTestPolicy 和无调用的兼容代码。

每个单元都应能够独立编译、测试和回退；不要把资源生成大提交和共享业务重构提交混在一起。

### 7.3 主线兼容要求

合流后必须满足：

- CV、DH Native 和未启用 Bundle 的 Browser 组合不读取 DH Bundle registry。
- 旧 `resource_list` 和 Native `manifest` 工件不因 Bundle 发布而改变。
- Bundle Runtime 的新文件即使被打入公共 JS，也不能在未选择该 Runtime 时执行初始化或访问 Bundle Catalog。
- 不向稳定主线引入 local/test 专用业务分支。
- 每个领域可通过组合根关闭/回退到旧 Runtime，而不是通过业务散点开关回退。

---

## 8. 推荐实施阶段与门禁

### 阶段 0：冻结边界

- 确认三种资源方式和四类 Runtime 命名。
- 确认 `resource_v2` 采用方案 A 或 B。
- 列出所有当前仍必须走 `resource_list` 的资源身份。
- 删除/禁止 `BrowserBundleLocalTestPolicy` 作为正式行为开关。

**停止条件**：任何资源身份没有明确 owner、route 或失败语义时，不进入代码重构。

### 阶段 1：建立组合根

- 新建 `BundleResourceRuntime` 组合及宿主 ports。
- 保留 `ResourceListRuntime` 与 `ManifestRuntime` 的原始入口。
- 只在启动入口选择一次 Runtime。
- 增加三种组合的隔离测试。

### 阶段 2：集中处理 Startup/Lobby

- 将启动、首屏、大厅初始化的破坏性变更限制在明确文件。
- Bundle Runtime 负责 startup/lobby Bundle 的 operation、cache 和 Lease。
- 旧组合完全保留旧启动流程。

### 阶段 3：领域 Adapter 接入

- 每次只迁移一个领域入口。
- Adapter 负责 identity 映射、prepare、Lease 交付和失败终态。
- 业务只消费成功句柄，不重复 acquire。
- 未迁移资源通过显式 `resource-list` 路由运行。

### 阶段 4：清理共享污染

- 删除业务层重复 `isEnabled`。
- 从 `resource_v2` Loader 删除 Bundle 分支。
- 删除 LocalTestPolicy 生产语义。
- 检查所有旧 Runtime 不依赖 Bundle 文件和 registry。

### 阶段 5：合流验证

至少需要以下矩阵：

| 组合 | 启动 | Lobby | Slot | 动态旧资源 | 失败行为 |
| --- | --- | --- | --- | --- | --- |
| DH Browser + Bundle | Bundle | Bundle | Bundle | resource_list adapter | fail closed |
| DH Browser + ResourceList | 旧 | 旧 | 旧 | resource_list | 旧语义 |
| DH Native + Manifest | manifest | 旧 | 旧 | Native/旧语义 | 旧语义 |
| CV/其他 | 旧 | 旧 | 旧 | 旧 | 旧语义 |
| 未来 Native + Bundle（预留） | Bundle | Bundle | Bundle | 兼容 adapter | fail closed |

---

## 9. 评审需要明确回答的问题

1. `resource_v2` 与 Bundle Runtime 最终选择方案 A 还是方案 B？共享的最小底层端口是什么？
2. 哪些旧框架资源必须在 Bundle Runtime 中继续使用 `resource_list`？能否形成受版本控制的 route registry？
3. Startup、Lobby、Slot 三个破坏性流程是否接受文件级分流？具体允许修改的文件边界是什么？
4. 是否同意彻底移除 `BrowserBundleLocalTestPolicy` 的正式行为职责，并将 local/test/release 仅保留在测试宿主或配置生成层？
5. 是否同意禁止 Bundle 失败后回退 `resource_list`，只允许发布前登记的旧资源路由？
6. 合流采用分阶段提交，而不是直接合并当前分支，是否符合主线维护要求？
7. 当前已经提交的 Bundle 生成产物是否作为独立资源发布提交保留，还是在运行时架构收敛后重新生成？

---

## 10. 建议的评审结论模板

评审者可以按以下格式反馈：

```text
结论：通过 / 有条件通过 / 不通过

必须修改：
1. ...

需要补充证据：
1. ...

同意的关键原则：
- BundleResourceRuntime 是正式命名
- Runtime 顶层单点分流
- resource_list 仅允许显式旧资源路由
- Bundle 失败不 fallback
- resource_v2 与 Bundle Runtime 保持明确边界
- Startup/Lobby/Slot 允许有限文件级破坏性分流

对方案 A/B 的选择：...
对合流策略的意见：...
```

---

## 附录：当前分支的事实基线

- 当前分支：`classic_vegas_web_refactor`。
- 当前 Bundle Runtime 核心目录：`src/browser_bundle/`。
- 当前正式运行时判断：`DHBrowserBundleSession.isEnabled(config, cc)`，要求 `browserBundleRuntime === true` 且非 Native。
- 当前额外测试策略：`BrowserBundleLocalTestPolicy`，不应继续承担正式 Runtime 分流职责。
- 当前 `resource_v2` 仍包含大量旧 `resource_list`、Native 和 LoaderRegistry 逻辑，同时若干 Loader 已直接引用 Bundle Bridge。
- 当前 OpenSpec active Change：`integrate-dh-card-system-bundle-publication`，32/36 tasks，仍为 in-progress；这不是本文的归档或完成结论。
- 相关正式架构原则见 `openspec/programs/dh-browser-progressive-resource-reorganization/requirements.md` 与 `target-technical-architecture.md`，本文按上述原则补充三种资源方式和合流约束。
