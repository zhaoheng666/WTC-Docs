# ResourceManV2 技术指南

> **定位**：面向需要**扩展、优化 ResourceManV2** 的项目成员，以 `src/resource_v2/` 代码为唯一权威依据。
> **与《ResourceManV2-技术架构报告》的关系**：架构报告偏历史设计过程，部分章节与当前代码不一致（见本文第七节勘误）；两者冲突时**以本文和代码为准**。
>
> **代码基线**：2026-07（27 个文件，约 11,000 行）

---

## 一、架构总览

### 1.1 三层架构

```
┌─────────────────────────────────────────────────────────────┐
│ 业务层                                                       │
│ ActivityMan / CardSystem / FlagStone 大厅入口 / 商店 / ...   │
└──────────────────────────┬──────────────────────────────────┘
                           │ ResourceManV2.getInstance()
┌──────────────────────────▼──────────────────────────────────┐
│ ResourceManV2（单例门面, ResourceManV2.js 1047 行）          │
│                                                             │
│  LoaderRegistry ──── 注册/创建/缓存 12 种 Loader             │
│       │                                                     │
│  ┌────▼─────────────┐   ┌──────────────────┐                │
│  │ DownloadQueue ×2 │   │ CacheManager     │                │
│  │ 全局队列+专用队列 │   │ 已下载校验/搜索路径│               │
│  └────┬─────────────┘   └──────────────────┘                │
│       │      ConfigManager（优先级/并发/开关）               │
│       │      LoaderEventBus + LoaderMonitor（内部监控）      │
└───────┼─────────────────────────────────────────────────────┘
        │
┌───────▼─────────────────────────────────────────────────────┐
│ 平台适配层（adapters/）                                      │
│  NativeDownloader（jsb.AssetsManager）                       │
│  CanvasDownloader（cc.loader + resource_list.json 清单）     │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 目录结构（27 个文件）

```
src/resource_v2/
├── ResourceManV2.js                 # 单例门面，1047 行
├── core/
│   ├── DownloadQueue.js             # 下载队列调度，1088 行（最复杂）
│   ├── ConfigManager.js             # 优先级/并发/平台配置，709 行
│   ├── CacheManager.js              # 缓存与已下载校验，519 行
│   ├── LoaderRegistry.js            # Loader 注册表，422 行
│   ├── LoaderEventBus.js            # 内部事件总线，300 行
│   ├── LoaderMonitor.js             # 监控埋点收集，300 行
│   ├── DownloadTask.js              # 任务对象，243 行
│   ├── ControllerPool.js            # 进度 UI 控制器池，115 行
│   └── Logger.js                    # 日志工厂，69 行
├── enum/
│   └── LoaderTypes.js               # Loader 类型枚举，54 行
├── loaders/
│   ├── BaseLoader.js                # 抽象基类，423 行
│   ├── ActivityLoader.js            # 活动资源，800 行
│   ├── CardSystemLoader.js          # 卡牌系统（lagload/archive），603 行
│   ├── FlagStoneLoader.js           # 大厅机台入口按需加载，542 行
│   ├── FeatureLoader.js             # lobby_res/feature_res 功能资源，539 行
│   ├── SlotLoader.js                # 关卡资源（特殊：不走共享队列），453 行
│   ├── ClubActivityLoader.js        # 工会活动，453 行
│   ├── PosterLoader.js              # 海报，396 行
│   ├── LobbyBoardLoader.js          # 大厅广告牌，368 行
│   ├── LobbyThemeLoader.js          # 大厅主题（Loading 界面），269 行
│   ├── StoreLoader.js               # 商店，256 行
│   ├── CouponLoader.js              # 优惠券，126 行
│   └── GenericLoader.js             # 通用兜底，254 行
├── adapters/
│   ├── NativeDownloader.js          # Native 平台适配，373 行
│   └── CanvasDownloader.js          # Canvas 平台适配，338 行
└── controller/
    └── LoadingProgressIndicatorController.js  # 进度指示器，264 行
```

### 1.3 设计约定（扩展时必须遵守）

| 约定 | 说明 |
| --- | --- |
| **ES5 严格模式** | 禁止箭头函数/const/let/模板字符串；`'use strict'` + `var` + `cc.Class.extend` |
| **共享组件注入** | 所有 Loader 通过构造参数共享同一个 queue / cache / config / eventBus，禁止自建 |
| **优先级统一出口** | 必须用 `this._config.calculateDownloadPriority(type, offset)`，禁止硬编码优先级数值（BaseLoader 已移除自算方法） |
| **对外事件 vs 内部事件** | 对外通知走 `game.eventDispatcher`；内部监控走 `this._emitEvent()`（LoaderEventBus），互不混用 |
| **单例访问** | 业务层只通过 `ResourceManV2.getInstance()`，不直接 new Loader |

---

## 二、下载生命周期与四道闸门

一个资源从业务请求到落地的完整链路：

```
业务调用（如 resourceMan.ensureResources(...) / getLoader(type).load(items)）
  ↓
Loader.load()
  ├─ validateItem() 批量校验（_validateItems）
  ├─ _isDownloaded() 查 CacheManager → 已下载直接回调
  ├─ buildTasks() 构建任务配置（含 calculateDownloadPriority）
  └─ _addTask() → 发 TASK_ENQUEUE 事件 → queue.addTask()
  ↓
DownloadQueue 调度（按优先级排序，数值越小越优先）
  ↓ 每帧调度循环，需通过四道闸门：
  【闸门1】并发上限：全局队列动态并发 = TOTAL(3) − flagstone 队列占用；
           flagstone 专用队列硬编码并发 1
  【闸门2】性能闸：PerformanceMonitor 判定当前帧率不佳时跳过本帧启动；
           连续跳帧 ≥ 10 次保底强制启动 1 个（防饿死）
  【闸门3】节流：每帧最多启动 1 个新任务
  【闸门4】前后台：后台（EVENT_HIDE）暂停调度；前台恢复带 500ms 防抖，
           stuck 任务降权 +100 重新排队
  ↓
平台下载器执行
  ├─ Native：jsb.AssetsManager 按 manifest 下载到可写目录
  └─ Canvas：cc.loader 按 resource_list/<dir>/resource_list.json 逐文件加载
  ↓
完成/失败
  ├─ 成功：CacheManager 标记已下载 + （Native）注册搜索路径
  ├─ 失败：自动重试最多 3 次，每次重试优先级提权 −10
  └─ Loader.onItemComplete() → 业务回调 / game.eventDispatcher 通知
```

### 2.1 特殊入队方式（DownloadQueue）

| 方法 | 行为 | 典型使用者 |
| --- | --- | --- |
| `addTask` | 按优先级插入 pending | 所有常规 Loader |
| `addTaskToFront` | LIFO 插队到最前 | FlagStoneLoader（用户正在看的机台最先下） |
| `addCriticalTask` | **绕过并发上限立即启动**，并冻结普通队列调度直到 critical 完成 | `ensureResources({critical: true})`，如进关卡前的强依赖 |

### 2.2 双队列并发模型（ResourceManV2.js）

```javascript
// 全局队列并发 = 总并发 3 − flagstone 队列当前活跃数
_getGlobalQueueMaxConcurrent: function() { /* TOTAL_MAX_CONCURRENT(3) - flagstoneActive */ }
// flagstone 专用队列并发：硬编码 1
_getFlagstoneQueueMaxConcurrent: function() { return 1; }
```

设计意图：flagstone 大厅入口图属于"弱需求高频"资源，用独立慢速通道避免挤占活动/卡牌等强需求带宽；两队列共享总并发预算 3。

---

## 三、核心组件速查

### 3.1 优先级基值表（ConfigManager.DOWNLOADER_PRIORITY_BASE）

> ⚠️ **数值越小越优先**。这是全系统最容易搞反的约定。

| 类型 | 基值 | 说明 |
| --- | --- | --- |
| CARD_SYSTEM | **500** | 最高（卡牌活动强依赖） |
| LOBBY_THEME | 1500 | 大厅主题（Loading 界面） |
| POSTER | 2500 | 海报 |
| ACTIVITY | 3500 | 活动资源 |
| STORE | 4500 | 商店 |
| CLUB_ACTIVITY | 5500 | 工会活动 |
| LOBBY_BOARD | 6500 | 大厅广告牌 |
| COUPON | 7500 | 优惠券 |
| FEATURE | 8500 | lobby_res / feature_res |
| FLAGSTONE | 9000 | 大厅机台入口（在 SLOT 之前） |
| SLOT | 9500 | 关卡资源 |
| GENERIC | **10500** | 最低（兜底） |

计算方式：`priority = 基值 + offset`，offset 区间约 ±1000；传大负数（如 −10000）可穿透所有类型成为全局最高。

### 3.2 CacheManager：Native 六层已下载校验

`isDownloaded(resourcePath)` 在 Native 端依次通过：

1. 内存 map 命中（会话内缓存）
2. 可写目录下 manifest 文件存在
3. `VERSION_CHECK_PREFIXES` 前缀命中时对比 manifest 版本号与远端版本
4. manifest 中记录的 assets 文件逐一存在性检查
5. 任一 assets 缺失 → **删除 manifest 强制重下**（自愈）
6. 校验通过 → 注册搜索路径（`jsb.fileUtils.addSearchPath`）

> ⚠️ **Canvas 端不做持久化校验（有意的设计取舍，非缺陷）**：只有内存 map，刷新页面后"已下载"状态丢失，重复 load 重新走请求、由浏览器 HTTP 缓存裁决（命中 → disk cache/304 秒回；未命中 → 自动补下）。
>
> **设计依据（两条前提，缺一不可）**：
>
> 1. **标记不可靠**：浏览器缓存对应用**不可查询、不可保证**（LRU 淘汰/清缓存/无痕模式），应用层持久化标记（如 localStorage）只能证明"曾经下载过"，无法证明"字节现在还在"。凭标记跳过下载，缓存失效时故障会推迟到使用现场（同步 API 如 `cc.spriteFrameCache.getSpriteFrame` 拿到空值 → 逻辑错误）。
> 2. **标记无收益（更根本）**：Canvas 端"下载"的真实产物是 **`cc.loader` 内存缓存**（`CanvasDownloader._loadAll` 通过 `cc.loader.load` 将图片/plist/JSON 解析结果载入内存），大量使用现场是假设资源已在内存的同步 API。刷新后内存缓存必然为空，**无论浏览器磁盘缓存是否健在，请求流程都必须重走以重建内存缓存**——持久化标记唯一能跳过的流程恰恰不可跳过。即使浏览器缓存 100% 可靠，标记依然无意义。
>
> 现状"重新走请求、由浏览器 HTTP 缓存裁决"（命中 → disk cache/304 快速重建内存缓存；未命中 → 自动补下）实质是一次廉价的有效性复验。**必须保证资源有效性 > 节省请求开销**。禁止用应用层标记绕过此机制。
>
> 附：浏览器缓存还是**任务重试机制的隐性依赖**——`cc.loader.load` 单文件失败会导致整个目录任务报错重试（最多 3 次），已成功文件靠浏览器缓存使重试变廉价。因此 CDN 强缓存配置对 Canvas 端不是可选项。

### 3.3 LoaderEventBus + LoaderMonitor

- 事件枚举 `LoaderEvent`（定义于 `core/LoaderEventBus.js` 内，**没有独立的 LoaderEvent.js 文件**）：TASK_ENQUEUE / LOADER_START / TASK_COMPLETE / BATCH_COMPLETE 等
- Loader 内通过 `this._emitEvent(type, data)` 发送，自动附加 `loaderType`，异常被吞掉不影响下载流程
- LoaderMonitor 订阅全部事件做耗时统计、后台切换标记（`_markBatchStart / _getBatchStats`）

### 3.4 ensureResources：统一依赖入口

```javascript
ResourceManV2.getInstance().ensureResources(
    [{type: 'ACTIVITY', name: 'clover_clash'}, ...],   // 依赖列表
    function(success, failed) { /* 全部就绪回调 */ },
    {
        critical: true,          // 走 addCriticalTask 通道
        showUI: true,            // 显示进度指示器（UI 引用计数管理）
        restoreClosedUI: false   // 用户手动关过进度条则本次不再弹（记忆）
    }
);
```

关键行为：

- **UI 引用计数**：多处并发调用 ensureResources 共用一个进度 UI，最后一个完成才关闭
- **1s 防闪屏**：下载在 1 秒内完成则不弹进度 UI
- **手动关闭记忆**：用户点关闭后，同批次后续调用默认不再弹出（`restoreClosedUI: true` 可强制恢复）

---

## 四、Loader 清单与职责

| Loader | 类型 | 资源目录 | 特点 |
| --- | --- | --- | --- |
| ActivityLoader | ACTIVITY | `activity/<themeName>` | 按 ActivityConfig.json 的 lagLoadPriority 排序；isSilentLoad 控制进度条 |
| CardSystemLoader | CARD_SYSTEM | `card_system_lagload` / `card_system_archive` | 三段式：基础目录 `casino/card_system` 仍在一段 loading，两个 lagload 目录按需 |
| FlagStoneLoader | FLAGSTONE | `flagstone*/<机台号>/` | 专用队列 + LIFO；占位符 → 下载 → `FLAGSTONE_BIG_LOAD_FINISH` 事件替换（详见《BigFlagStone-资源加载优化》） |
| FeatureLoader | FEATURE | `lobby_res` / `feature_res` | 三段加载；完成后 `_removeDirectories` 清理搜索路径冲突 |
| SlotLoader | SLOT | `slot/<关卡>` | ⚠️ **不走共享队列**，独立管理下载（历史原因，见第七节） |
| ClubActivityLoader | CLUB_ACTIVITY | 工会活动目录 | — |
| PosterLoader | POSTER | 海报目录 | — |
| LobbyBoardLoader | LOBBY_BOARD | 广告牌目录 | — |
| LobbyThemeLoader | LOBBY_THEME | 大厅主题 | Loading 界面主题切换 |
| StoreLoader | STORE | 商店资源 | — |
| CouponLoader | COUPON | 优惠券 | 最简单的 Loader，可作为新 Loader 模板阅读 |
| GenericLoader | GENERIC | 任意 | 兜底，无专属 Loader 时使用 |

**架构例外（不受 V2 管辖）**：

- `src/loader/LoadingController.js`：一段 loading 早于 V2 初始化，直连 SlotAssetsManager
- SlotLoader：注册在 V2 但下载不经过共享 DownloadQueue

---

## 五、新增 Loader 五步扩展指南

以"HighRoller 资源拆分出一段 loading"（约 700 条 / 90MB+）为例：

### 第 1 步：定义类型与优先级

```javascript
// enum/LoaderTypes.js
HIGH_ROLLER: 'HIGH_ROLLER',

// core/ConfigManager.js
DOWNLOADER_TYPE: { HIGH_ROLLER: 'HIGH_ROLLER', ... },
DOWNLOADER_PRIORITY_BASE: {
    HIGH_ROLLER: 4000,  // 在 ACTIVITY(3500) 与 STORE(4500) 之间，按业务重要性定
    ...
}
```

### 第 2 步：实现 Loader（继承 BaseLoader）

```javascript
'use strict';
var BaseLoader = require('./BaseLoader');

var HighRollerLoader = BaseLoader.extend({
    load: function(items, onComplete) {
        var result = this._validateItems(items);
        // 过滤已下载 → buildTasks → this._addTasks(configs)
        // 通过 queue 回调聚合完成状态，最终 onComplete(success, failed)
    },
    buildTasks: function(items) {
        var self = this;
        return items.map(function(item, i) {
            return {
                resourcePath: 'high_roller/' + item.name,
                priority: self._config.calculateDownloadPriority(
                    self._config.DOWNLOADER_TYPE.HIGH_ROLLER, i),
                metadata: {name: item.name}
            };
        });
    },
    validateItem: function(item) {
        if (!item || !item.name) return {valid: false, error: 'name required'};
        return {valid: true};
    }
});
module.exports = HighRollerLoader;
```

> 参考实现：简单场景抄 `CouponLoader.js`（126 行）；带批量统计/事件的抄 `LobbyThemeLoader.js`。

### 第 3 步：注册到 LoaderRegistry

在 `LoaderRegistry.js` 的注册表中添加类型 → 构造器映射（懒创建，共享组件自动注入）。

### 第 4 步：（可选）ResourceManV2 快捷方法 + ensureResources 支持

在 `ResourceManV2.js` 添加 `loadHighRollerResources()` 快捷方法，并在 `ensureResources` 的类型分发中接入。

### 第 5 步：资源侧配套（缺一不可）

1. `res_*/resource_dirs.json`：把目标目录从 `facebookDirs`（一段 loading）移到独立字段
2. `scripts/gen_res_list.py`：为该目录生成独立 `resource_list/<dir>/resource_list.json`（Canvas 端下载依赖此清单；参考 flagstone 拆分的 `is_double_hit` 段落）
3. 业务入口改为 `ensureResources` 按需触发
4. 构建验证：`cd scripts && ./build_local_doublehit.sh 2>&1 | tail -50`，确认无错误/警告

---

## 六、当前优化切入点

基于一段 loading 占比统计（DH 6,508 条 / 550MB；CV 7,655 条 / 602.6MB）：

| 切入点 | 收益（DH） | 收益（CV） | 难度 | 说明 |
| --- | --- | --- | --- | --- |
| `casino/card_system` 基础目录拆分 | 1,090 条 / 74.1MB (13.5%) | 1,090 条 / 74.0MB | 中 | lagload/archive 已拆，基础目录未拆；CardSystemLoader 已具备承接能力 |
| HighRoller 系列拆分 | 710 条 / 97.5MB (17.7%) | 704 条 / 83.0MB | 中 | 全部 high_roller 活动已在 lagLoadActivityDirs，但共享资源仍在主清单；见第五节示例 |
| CV flagstone 移植 | 已完成（171 条 / 9.1MB） | **1,384 条 / 96.0MB (15.9%)** | 中高 | 运行时逻辑（FlagStoneLoader/占位符/事件）全现成；需：①机台资源整理工具扩展覆盖大厅 flagstone/ ②gen_res_list.py 放开 `is_double_hit` 限制 ③打开 `isEnableFlagstoneStyleSwitch` 开关 |
| daily_mission / daily_slot 延迟化 | 小 | 小 | 低 | 移入 lagLoadActivityDirs 即可 |
| 延迟 GPU 上传 | 内存/卡顿 | 同左 | 高 | 引擎层改造，设计已完成未实施（TexturesWebGL `_gpuUploadPending`） |

三者合计占一段 loading：DH 30.3% 条数 / 32.8% 体积；CV 41.5% 条数 / 42.0% 体积。

---

## 七、已知坑与技术债（接手必读）

1. **优先级方向反直觉**：数值越**小**越优先。《技术架构报告》附录 B 的旧表方向与数值均已过时，以本文 3.1 节为准。
2. **LoadingController 不归 V2 管**：一段 loading 早于 V2 初始化，直连 SlotAssetsManager；改一段 loading 行为不要在 V2 里找入口（Canvas 端真正入口在 `main.js` L125 `GameLoaderScene.preload`）。
3. **SlotLoader 不走共享队列**：关卡下载有独立通道，全局并发统计不含它；做全局限流时须单独考虑。
4. **Canvas 端无持久化缓存校验（有意设计，勿"修复"）**：`isDownloaded` 刷新即失效，重复加载重新走请求、由浏览器缓存裁决。这是保证资源有效性的取舍——浏览器缓存不可查询不可保证，应用层标记（localStorage 等）会造成两层记忆失配，把故障推迟到使用现场。详见 3.2 节设计依据。
5. **注释与代码不符**：ConfigManager 注释称 Canvas 并发为 1，实际 `getMaxConcurrent` 返回 5；CouponLoader 注释仍写旧基值 2600（实际 7500）。改代码时顺手修正注释。
6. **flagstone 专用队列并发硬编码为 1**（`_getFlagstoneQueueMaxConcurrent`），且全局队列并发动态让位给它；调整总并发（3）时两处联动。
7. **BaseLoader 后台监听器生命周期**：`_markBatchStart` 惰性注册 EVENT_HIDE 监听，必须通过 `destroy()` 清理，否则 Loader 重建会泄漏监听器。

---

## 附：相关文档

- [ResourceManV2-技术架构报告](/优化重构/resource-v2/ResourceManV2-技术架构报告)（历史设计过程，部分内容已过时）
- [BigFlagStone-资源加载优化](/优化重构/resource-v2/BigFlagStone-资源加载优化)（占位符→下载→替换完整流程）
- [活动资源优化-后置加载方案](/优化重构/resource-v2/活动资源优化-后置加载方案)
- [后台切换导致资源下载卡死-修复方案](/优化重构/resource-v2/后台切换导致资源下载卡死-修复方案)
- `docs/工程-工具/整理机台资源工具使用文档.md`（CV flagstone 移植依赖的资源整理工具）

---

**文档版本**：v1.0
**创建日期**：2026-07-28
**代码基线**：`src/resource_v2/`（27 文件）
