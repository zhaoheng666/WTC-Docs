# WTC 资源加载优化任务跟踪

**创建日期**: 2025-10-16
**状态**: 进行中
**优先级**: 高

---

## 任务概述

优化 WorldTourCasino 主项目（老项目）的资源加载方式，提升游戏性能和用户体验。

### 强制规则

- 所有代码修改必须保持 ES5 兼容
- 保持文档精简、准确

### 关注点

- 关注内存泄漏风险
- 向后兼容性

### 目标

- 改善游戏启动速度：减少进入大厅前加载资源量，缩短 loading 时间
- 优化内存占用
- 提升资源管理效率

---

## 相关文档

- [Cocos2d-html5 官方文档](https://docs.cocos2d-x.org/cocos2d-x/v3/zh/)
- [活动资源优化-后置加载方案](/其他/优化重构/resource-v2/活动资源优化-后置加载方案) - 最终方案文档

---

## 系统架构分析（2025-10-16）

### 核心模块

| 模块 | 文件 | 职责 |
|-----|------|------|
| AssetsManager | `src/common/asset/AssetsManager.js:130` | JSB 资源下载、版本比对、失败重试 |
| LoadingController | `src/loader/LoadingController.js:136` | 第1阶段加载入口、manifest 刷新 |
| ResourceMan | `src/common/model/ResourceMan.js:218` | 关卡资源管理、manifest 生成 |
| FeatureResMan | `src/common/model/FeatureResMan.js:106` | 分阶段加载调度（LobbyRes/FeatureRes） |
| SlotPreDownloadMan | `src/slot/model/SlotPreDownloadMan.js:120` | 关卡预下载队列（最多3线程） |

### 三阶段加载流程

```
阶段1（启动）: LoadingController → 基础资源（占10%或97%进度）
阶段2（Game.js加载后）: FeatureResMan → LobbyRes（分iOS/Android）
阶段3（登录后）: FeatureResMan → FeatureRes（高级功能）
游戏内: SlotPreDownloadMan → 关卡预下载（3线程并发）
```

### Manifest 机制

- **优先级**: `documents/project.manifest` > `documents/assets_config/project.manifest` > 包内 manifest
- **资源质量**: HD(`_hd`) / SD(无后缀) / LD(`_ld`)
- **版本控制**: `@version` 快速比对 + `@manifest` 完整清单

### 已识别的优化点

1. ⚠️ Manifest 重复读写（每次启动都重新生成备份）
2. ⚠️ 资源释放时机（切关卡时批量释放）
3. ⚠️ CCB 文件加载无缓存
4. ⚠️ 图片资源批量加载（无懒加载）
5. ⚠️ 预下载队列无优先级调度

---

## ResourceManV2 架构重构（2025-10-21）

### 重构背景

在讨论活动延迟加载优化方案的过程中，发现现有 ResourceMan 存在以下问题：

1. **职责混乱**：配置、下载、资源管理混在一起
2. **重复代码**：多处相似的下载逻辑（章节、活动、商店、动态资源）
3. **并发缺失**：所有下载强制串行，效率低
4. **难以扩展**：新增下载场景需大量重复代码
5. **状态分散**：3个独立的下载状态 Map

### 新架构设计

#### 模块划分

```
ResourceManV2
├── core/                          # 核心模块
│   ├── DownloadTask.js            # 任务模型
│   └── DownloadQueue.js           # 队列管理（优先级 + 并发）
│
├── managers/                      # 管理模块
│   ├── ConfigManager.js           # 配置管理（CDN、质量、Manifest）
│   └── CacheManager.js            # 缓存管理（下载状态）
│
└── adapters/                      # 平台适配
    ├── NativeDownloader.js        # Native 热更新
    └── CanvasDownloader.js        # Canvas 资源加载
```

#### 核心特性

1. **统一任务模型**（DownloadTask）
   - 支持任务类型：chapter, activity, folder, store, dynamic 等
   - 优先级：0-100
   - 重试策略：可配置重试次数和延迟
   - 状态管理：pending, downloading, completed, failed, cancelled

2. **智能队列管理**（DownloadQueue）
   - 优先级队列：自动按优先级排序
   - 并发控制：可配置最大并发数（默认3）
   - 自动重试：失败任务自动重试，优先级降低
   - 去重检测：防止重复下载

3. **清晰配置管理**（ConfigManager）
   - 资源质量类型（LD/SD/HD）
   - CDN 地址管理
   - Manifest 路径生成

4. **平台适配层**
   - NativeDownloader：封装 SlotAssetsManager
   - CanvasDownloader：封装 cc.loader
   - 统一接口，平台透明

### 关键改进对比

| 特性 | 旧 ResourceMan | 新 ResourceManV2 |
|-----|--------------|----------------|
| **代码行数** | 1059行（单文件） | ~1900行（7个模块） |
| **职责划分** | ❌ 混乱 | ✅ 清晰（单一职责） |
| **并发控制** | ❌ 强制串行 | ✅ 可配置并发（默认3） |
| **优先级** | ❌ 无 | ✅ 0-100 优先级 |
| **重试策略** | ❌ 部分支持 | ✅ 统一重试机制 |
| **扩展性** | ❌ 差（重复代码多） | ✅ 优秀（只需添加任务类型） |
| **向后兼容** | - | ✅ 100%兼容 |

---

## ActivityDownloader 依赖倒置重构（2025-10-24）

### 重构背景

**问题**：ActivityDownloader 既负责下载又管理 UI（Placeholder），持有 UI 层 Node 引用，违反了依赖倒置原则和单一职责原则。

**架构缺陷**：
- 资源层（ActivityDownloader）持有 UI 层的 Node 引用
- 资源层直接操作 UI（创建/移除 placeholder）
- 存在跨层引用和生命周期管理风险

### 重构方案

**核心原则**：
- ✅ **依赖倒置** - 资源层不依赖 UI 层
- ✅ **职责分离** - 资源层负责下载，UI 层负责显示
- ✅ **事件驱动** - 通过事件实现完全解耦
- ✅ **生命周期安全** - 无跨层引用，无野指针风险

### 新架构

```
ActivityDownloader (src/common/resource_v2/downloaders/)
  ├─ 职责：纯资源下载逻辑
  ├─ 输入：活动信息数组 [{activityId, themeName, ...}]
  ├─ 输出：事件通知（DOWNLOAD_START / DOWNLOAD_COMPLETE）
  └─ 特点：完全不涉及 UI，不持有任何 Node 引用

ResourceManV2 (src/common/resource_v2/)
  └─ downloadActivities(activities) - 调度 ActivityDownloader

ActivityMan (src/task/model/)
  ├─ getLagLoadActivities() - 返回活动信息数组
  └─ downloadLagLoadActivities() - 触发下载

ActivityEntranceGroupController (src/task/controller/activity_center/)
  ├─ 职责：完全接管 Placeholder 生命周期管理
  ├─ 监听：ACTIVITY_RESOURCE_DOWNLOAD_START
  ├─ 监听：ACTIVITY_RESOURCE_DOWNLOAD_COMPLETE
  ├─ _placeholderMap - 管理 placeholder 引用
  ├─ _onActivityDownloadStart() - 创建 placeholder
  └─ _onActivityDownloadComplete() - 移除 placeholder，创建真实入口
```

### 新增事件

**位置**：`src/common/events/CommonEvent.js`

```javascript
// 单个活动资源下载开始（UI层监听）
ACTIVITY_RESOURCE_DOWNLOAD_START: "activity_resource_download_start"

// 单个活动资源下载完成（UI层监听）
ACTIVITY_RESOURCE_DOWNLOAD_COMPLETE: "activity_resource_download_complete"
```

### 架构对比

| 层级 | 旧架构（v1.0） | 新架构（v2.0） |
|-----|-------------|-------------|
| **资源层** | 下载 + UI操作 ❌ | 只负责下载和通知 ✅ |
| **UI层** | 只触发，UI由资源层管理 ❌ | 监听事件，完全管理 UI ✅ |
| **耦合** | 资源层持有 Node 引用 ❌ | 完全事件驱动解耦 ✅ |
| **职责** | 混乱 ❌ | 清晰分离 ✅ |

### 成果

- 资源层（ActivityDownloader）：只负责下载，通过事件通知
- UI层（ActivityEntranceGroupController）：监听事件，完全管理 Placeholder 生命周期
- 符合依赖倒置原则，无跨层引用，无生命周期风险

**提交**: [e8b62e66889](https://github.com/LuckyZen/WorldTourCasino/commit/e8b62e66889)

**详细文档**: [活动资源优化-后置加载方案](/活动/活动资源优化-后置加载方案)

---

## 附录：需求分析和方案设计

### 初期需求讨论（第一轮）

#### Q1: resource_dirs.json 的 activity 配置如何工作？

**A**: 通过读取 `scripts/` 下的构建和部署脚本获取信息，脚本中的 fb 代表浏览器 Canvas 平台。

#### Q2: 活动资源的组织结构？

**A**:
- 以 CV（res_oldvegas）为基准进行优化
- 活动资源都位于 `res_oldvegas/activity` 目录下
- 活动入口资源包含在各个活动资源中
- 需要考虑用默认活动入口作为占位，真实资源下载完成后再替换
- 存在共享资源（common、casino 等基础功能），保留在第一阶段 loading

#### Q3: 登录后如何获取活动配置？

**A**:
- 从服务器接口获取当前开放的活动列表
- 配置包含活动ID、资源名、开放时间等
- 协议：C2SGetActivities，S2CGetActivities

#### Q4: 活动入口展示逻辑？

**A**:
- 目前没有"占位入口"
- 需要添加默认活动入口作为占位
- 真实活动资源下载完成后再替换

#### Q5: LagLoadActivity 现有逻辑？

**A**:
- 可理解为需求的原始、不完全版本
- 仍与主体资源版本号强关联
- 可借鉴但不能直接修改，需要重新生成更合理的代码

#### Q6: FeatureRes 是否包含活动资源？

**A**:
- FeatureRes 不包含活动资源
- 用于下载特定功能依赖的资源
- 实现与 LagLoadActivity 基本一致，但用途不同

#### Q7: 下载失败的降级策略？

**A**:
- 允许用户看到活动入口但无法进入
- 日志记录下载失败信息
- 预留错误修复机制（删除本地资源重新下载）

#### Q8: Canvas 和 Native 端处理？

**A**: 需要保持一致，确保不同平台体验一致

#### Q9: 构建脚本调整？

**A**: 旧的构建脚本、逻辑、配置都需要保留，设计应该是独立的

#### Q10: 方案选择

**决策**：选择方案 A - 活动资源完全分离
- 第一阶段: 主体 + 关卡入口 + 活动入口框架（无具体活动资源）
- 第二阶段: 登录后获取活动配置 → 按需下载当前开放的活动资源

### 方案细化（第二轮讨论）

#### 关键决策点

1. **活动资源 Manifest 管理策略**
   - **决策**：方案 A - 完全独立版本号
   - 每个活动有自己的版本号，独立于主体版本更新

2. **活动资源从第一阶段剔除的实现方式**
   - **决策**：方案 B - 新增独立配置文件
   - 创建 `activity_lazy_load_config.json`
   - `resource_dirs.json` 保持不变（向后兼容）

3. **活动入口占位资源设计**
   - 占位资源是全局统一的默认图标
   - 作为基础资源在第一阶段加载
   - 对应活动资源下载完成后立即替换

4. **活动下载时机与优先级**
   - 登录后立即后台下载
   - 多线程并发，并发数可配置
   - 增加专用的活动优先级列表

5. **Canvas 和 Native 端统一处理**
   - Canvas 端的 `resource_list.json` 也需要从第一阶段剔除活动资源
   - Canvas 端也需要占位资源机制

6. **向后兼容与灰度发布**
   - 优先修改 JS 层代码
   - 需要开关控制（`SwitchMan.isEnableActivityLazyLoad()`）

### 资源隔离优化（第三轮讨论）

#### 关键改进

**问题**：直接修改 `activity/` 目录可能影响原有逻辑

**优化方案**：
- 延迟加载的活动资源生成到 **`res_oldvegas/activity_lazy/`** 独立目录
- 对应的 resource_list 和 manifest 文件也使用独立路径
- 根据开关决定使用 `activity/` 还是 `activity_lazy/`

#### 目录结构

```
res_oldvegas/
├── activity/                          # 原有活动资源（保留不变）
├── activity_lazy/                     # 新增：延迟加载活动资源
├── resource_list/
│   ├── activity/                      # 原有
│   └── activity_lazy/                 # 新增
└── activity_lazy_load_config.json     # 延迟加载配置

assets_config/
├── res_oldvegas/activity/             # 原有
└── activity_lazy/                     # 新增
```

#### 优势

| 对比项 | 原方案 | 优化方案（activity_lazy/） |
|--------|--------|---------------------------|
| **原有逻辑** | 可能被影响 | 完全不受影响 |
| **资源隔离** | 部分隔离 | 完全隔离 |
| **回滚风险** | 需要重新构建 | 关闭开关即可 |
| **测试独立性** | 互相影响 | 完全独立 |

---

## CanvasDownloader Local 模式进度回调修复（2025-11-05）

### 问题背景

在测试 CardSystemLoader 进度更新时，发现 Local Canvas 模式下只显示 0% 和 100%，缺少中间进度更新。

**问题根源**：
- CanvasDownloader 在 Local 模式使用 `cc.loader._handleAliases`
- `_handleAliases` API 不支持进度回调（只有完成回调）

### 对比分析

#### ResourceMan vs CardSystemDownloadMan

| 实现 | Local 模式处理 | 进度回调 |
|-----|--------------|---------|
| **ResourceMan** | 使用 `cc.loader._handleAliases` | ❌ 无 |
| **CardSystemDownloadMan** | 统一使用 `cc.loader.load` | ✅ 有 |

#### cc.loader API 对比

| API | 进度回调 | 完成回调 | 用途 |
|-----|---------|---------|------|
| `cc.loader.load(arr, progressCb, completeCb)` | ✅ 有 | ✅ 有 | 正常资源加载 |
| `cc.loader._handleAliases(aliases, completeCb)` | ❌ 无 | ✅ 有 | 快速注册别名 |

### 设计方案

**原则**：不取缔 `_handleAliases`，而是让 Loader 通过 metadata 控制 Local 模式行为。

#### 1. 新增控制参数

在 DownloadTask metadata 中添加 `useLoadInLocalCanvas` 参数：

```javascript
// CardSystemLoader
metadata: {
    loaderType: 'CARD_SYSTEM_FOLDER',
    folderName: folderName,
    useLoadInLocalCanvas: true  // 强制 Local Canvas 使用 cc.loader.load
}
```

#### 2. CanvasDownloader 支持参数

```javascript
download: function (task, onProgress, onComplete) {
    var useLoadInLocalCanvas = task.metadata && task.metadata.useLoadInLocalCanvas;

    // Local 模式判断
    if (Config.isLocal() && !useLoadInLocalCanvas) {
        // 默认：使用 _handleAliases（快速，无进度）
        this._loadLocalResources(...);
    } else {
        // 1. 正常模式
        // 2. 或 Local 模式但需要进度回调
        this._loadResources(...);
    }
}
```

### 修改内容

**文件**:
- `src/common/resource_v2/loaders/CardSystemLoader.js`
- `src/common/resource_v2/adapters/CanvasDownloader.js`

**效果**:
- CardSystemLoader: Local Canvas 模式显示完整进度（0% → 25% → 50% → 100%）
- 其他 Loader: 保持原有行为（Local 模式使用 `_handleAliases`）
- 灵活性: 任何 Loader 都可通过 `useLoadInLocalCanvas: true` 启用进度回调

**原因**:
- `_handleAliases` 用于快速注册别名映射，不适合需要进度反馈的下载场景
- CardSystem 等需要显示下载进度的模块，应使用 `cc.loader.load`
- LobbyBoard、Poster 等远程资源依然可以使用 `_handleAliases` 快速加载

---

## Phase 8: 统一日志系统（2025-11-06）

### 背景

ResourceManV2 各模块日志格式不统一，缺少文件路径前缀，调试时难以快速定位问题。BaseLoader 自定义的 `_log`、`_warn` 方法造成代码冗余。

### 实现方案

#### 1. 新增 Logger.js 工厂函数

**文件**: `src/common/resource_v2/core/Logger.js`

**核心机制**:
```javascript
module.exports = function(prefix) {
    if (Config.isRelease()) {
        return function() { return ''; };
    }

    return function() {
        var args = Array.prototype.slice.call(arguments);

        // 添加文件路径前缀
        if (args.length > 0 && typeof args[0] === 'string') {
            args[0] = "[" + prefix + "] " + args[0];
        } else {
            args.unshift("[" + prefix + "]");
        }

        // 智能返回类型
        var hasComplexArg = false;
        for (var i = 0; i < args.length; i++) {
            var type = typeof args[i];
            if (type !== 'string' && type !== 'number') {
                hasComplexArg = true;
                break;
            }
        }

        // 复杂类型 → 返回数组（保留 console 展开性）
        if (hasComplexArg) {
            return args;
        }

        // 简单类型 → 返回字符串（节省性能）
        return args.join('');
    };
};
```

**特性**:
- **闭包捕获前缀**: 每个模块创建时传入文件路径
- **智能返回类型**:
  - 对象/函数 → 返回数组，保留 console.log 的对象展开能力
  - 字符串/数字 → 返回拼接字符串，性能更优
- **Release 模式优化**: 生产环境自动禁用日志

#### 2. 重构 BaseLoader

**移除方法**:
- `_log()`
- `_warn()`
- `_error()`

**强制规范**:
- 所有子类直接使用 `cc.log(_G(...))`
- 简化日志调用链路

**差异对比**:
```javascript
// 旧方式（已移除）
this._log('Loading', count, 'items');
this._warn('Failed:', error);

// 新方式（统一规范）
cc.log(_G('Loading', count, 'items'));
cc.warn(_G('Failed:', error));
```

#### 3. 全面应用 _G 前缀

**涉及文件** (19 个):

**核心模块**:
- `ResourceManV2.js`
- `core/DownloadQueue.js`
- `core/LoaderRegistry.js`
- `core/ConfigManager.js`
- `core/DownloadTask.js`

**适配器**:
- `adapters/CanvasDownloader.js`
- `adapters/NativeDownloader.js`

**所有 Loader**:
- `loaders/BaseLoader.js`
- `loaders/ActivityLoader.js`
- `loaders/CardSystemLoader.js`
- `loaders/CouponLoader.js`
- `loaders/FeatureLoader.js`
- `loaders/GenericLoader.js`
- `loaders/LobbyBoardLoader.js`
- `loaders/LobbyThemeLoader.js`
- `loaders/PosterLoader.js`
- `loaders/SlotLoader.js`
- `loaders/StoreLoader.js`

**统一格式**:
```javascript
var _G = require('../core/Logger')('模块路径');

cc.log(_G('message', arg1, arg2));
cc.warn(_G('warning', error));
cc.error(_G('error', details));
```

### 技术细节

#### cc.log 实现原理

```javascript
// Cocos2d-html5/CCDebugger.js:331
cc.log = Function.prototype.bind.call(console.log, console);

// 等价于
cc.log = console.log.bind(console);
```

**特性**:
- 接受多个参数，原样传递给 console.log
- 支持对象展开、数组展开等所有原生特性
- 无需 `apply` 或特殊处理

#### 为什么不用 `cc.log.apply()`?

```javascript
// ❌ 错误（过度设计）
cc.log.apply(cc, _G('message', obj));

// ✅ 正确（简洁直接）
cc.log(_G('message', obj));
```

**原因**: `_G()` 返回的数组/字符串可以直接作为参数传递给 `cc.log`，后者会自动处理。

### 日志输出示例

#### 简单类型（字符串拼接）

```javascript
cc.log(_G('Loading', 10, 'items'));
// 输出: "[ResourceManV2.js] Loading10items"
```

#### 复杂类型（数组展开）

```javascript
cc.log(_G('Task config:', {id: 1, path: '/res/'}));
// 输出: ["[DownloadQueue.js] Task config:", {id: 1, path: "/res/"}]
// Console 中可展开对象查看详情
```

### 验证结果

**构建脚本**: ✅ 通过
```bash
cd scripts && ./build_local_oldvegas.sh
```

**语法检查**: ✅ 无错误

**变更统计**:
- 修改文件: 19 个
- 新增文件: 1 个 (`Logger.js`)
- 变更行数: +283 / -288

### 提交记录

**Commit**: `0def18057af`
**消息**: `cv: ResourceManV2 统一日志系统并应用 _G 前缀`
**日期**: 2025-11-06

---

## 动态帧负载平衡优化（2025-12-28）

### 优化背景

- 资源批量加载集中在同一帧执行，导致卡帧与进度抖动
- 活动下载完成后大量事件同步派发，引发 UI 峰值开销
- 固定批次大小无法适配设备性能与实时帧压力

### 核心策略（三层防护：加载层、调度层、队列层）

| 层级 | 防护策略 | 关键组件 |
|------|----------|----------|
| 加载层 | 动态批次大小 + 帧空闲检测 | CanvasDownloader、PerformanceMonitor |
| 调度层 | 重任务与事件分帧执行 | FrameScheduler、ActivityLoader |
| 队列层 | 帧感知的队列启动节流 | DownloadQueue、FrameScheduler |

### 关键组件改动

| 提交 | 变更 | 影响 |
|------|------|------|
| `ae116c2b378` | LoadingProgressIndicator 优化超时策略 | 减少误判与抖动 |
| `c292d07dacd` | ActivityLoader 通过 FrameScheduler 调度激活与事件派发 | 避免同帧集中开销 |
| `68fe49b2d1a` | 统一帧预算模型 + CanvasDownloader 动态批次 | 任务预算更稳定 |
| `b5b2861ea58` | CanvasDownloader 帧空闲检测 + 动态调整 batchSize | 降低单帧阻塞 |

### 代码示例

```javascript
var PerformanceMonitor = require("../common/util/PerformanceMonitor");

var monitor = PerformanceMonitor.getInstance();
var remaining = monitor.getRemainingBudget();
var batchSize = Math.max(3, Math.min(10, Math.floor(remaining / avgTimePerResource)));

if (monitor.isFrameIdle()) {
    loadBatch(batchSize);
} else {
    requestAnimationFrame(loadNextBatch);
}
```

### 优化效果

- 资源加载与 UI 创建解耦，峰值开销分散到多帧
- 批次大小随帧预算动态调整，卡帧概率降低
- 活动激活与事件派发分帧执行，主线程更稳定

**最后更新**: 2025-11-06
**维护者**: WTC Team
