# BigFlagStone 小机台入口资源加载优化

## 概述

- BigFlagStone：小机台入口、或活动相关机台样式，历史原因命名不匹配，后文忽略该问题；
- 在 DH（Double Hit）等支持样式切换的风格中，BigFlagStone 资源采用按需下载策略，通过 **占位符 → 下载 → 替换** 的流程实现无感加载，避免进入大厅时一次性加载所有关卡入口资源导致的卡顿。
- 其他风格（如 CV）直接加载资源，待后续移植按需下载策略时同步该优化项。

### 与 FlagStone 的区别

| 特性 | FlagStone | BigFlagStone（小机台入口） |
|------|---------------------|------------------------|
| 用途 | 大厅 TableView 关卡列表 | 活动内关卡选择列表 |
| 资源路径 | `slot/lobby/flagstone/` | `slot/lobby/flagstone_big/` |
| 事件名 | `FLAGSTONE_LOAD_FINISH` | `FLAGSTONE_BIG_LOAD_FINISH` |
| 控制器 | `FlagStoneController` | `LobbyBigFlagStoneController` |
| 调用方 | 大厅 TableView | 活动入口（WinnerSlots、CloverClash、TowerTrials 等） |

---

## 架构设计

### 核心模块

```
LobbyBigFlagStoneController (src/common/controller/)
  ├─ 职责：BigFlagStone 节点的创建与生命周期管理
  ├─ createFromCCB(subjectId) - 工厂方法（对外唯一入口）
  ├─ loadFromCCB(subjectId) - 从 CCB 加载真实节点
  └─ 角标管理：addClashNode / addWinnerSlotNode / addRichSlotsNode / addFavoriteNode

FlagStoneLoader (src/resource_v2/loaders/)
  ├─ 职责：BigFlagStone 资源的下载与缓存管理
  ├─ loadFlagStoneBig(subjectId, callback) - 触发下载
  ├─ getOrCreateFlagStoneBig(subjectId) - 获取或创建（含占位符逻辑）
  └─ _createFlagStoneBigPlaceholder(subjectId) - 创建占位符节点

调用方控制器（活动入口）
  ├─ WinnerSlotsLevelListController
  ├─ CloverClashLobbyFlagStoneEntrance
  ├─ TowerTrialsLevelListController
  ├─ LobbyRichSlotsController
  └─ BadgesFlagStoneEntranceController
```

### 风格差异

| 风格 | 是否按需下载 | 资源路径格式 |
|------|-------------|-------------|
| **CV**（Classic Vegas） | 否，直接加载 | `slot/lobby/flagstone_big/<id>_big.ccbi` |
| **DH**（Double Hit） | 是，占位符+下载 | `slot/lobby/flagstone_big/<id>/slot_lobby_flagstone_big_<id>.ccbi` |

判断依据：`game.switchMan.isEnableFlagstoneStyleSwitch()` 返回 `true` 时走按需下载逻辑。

---

## 工作流程

### 创建流程（`createFromCCB`）

```
调用方: LobbyBigFlagStoneController.createFromCCB(subjectId)
  │
  ├─ isEnableFlagstoneStyleSwitch() === false（CV 风格）
  │   └─ 直接调用 loadFromCCB(subjectId) → 返回真实节点
  │
  └─ isEnableFlagstoneStyleSwitch() === true（DH 风格）
      └─ FlagStoneLoader.getOrCreateFlagStoneBig(subjectId)
          │
          ├─ 资源已下载（isLoaded: true）
          │   └─ 返回标记，调用方创建真实节点
          │
          └─ 资源未下载
              ├─ 触发 loadFlagStoneBig(subjectId)
              ├─ 创建占位符节点（_createFlagStoneBigPlaceholder）
              └─ 返回占位符
```

### 下载与替换流程

```
FlagStoneLoader.loadFlagStoneBig(subjectId)
  │
  ├─ 创建 DownloadTask，添加到 _flagstoneQueue 队列头部（LIFO）
  │
  ├─ 下载完成 → _onTaskComplete()
  │   ├─ _cache.markAsDownloaded(resourcePath)
  │   ├─ 分发事件 FLAGSTONE_BIG_LOAD_FINISH
  │   └─ 触发等待的回调
  │
  ↓
调用方监听 FLAGSTONE_BIG_LOAD_FINISH
  │
  ├─ 校验 subjectId 是否属于自己管理
  ├─ 校验占位符节点有效性
  ├─ 记录占位符的 scale / position / zOrder
  ├─ 创建真实节点 LobbyBigFlagStoneController.createFromCCB(subjectId)
  ├─ 移除占位符，添加真实节点（保持原有属性）
  └─ 添加角标（addWinnerSlotNode / addClashNode 等）
```

---

## 事件定义

**位置**：`src/common/events/CommonEvent.js`

```javascript
FLAGSTONE_BIG_LOAD_FINISH: "flagstone_big_load_finish"
```

**事件数据**：

```javascript
{
    folderName: String,   // 文件夹名称（= subjectId 字符串）
    subjectId: Number,    // 关卡 ID
    success: Boolean      // 是否下载成功
}
```

---

## 占位符机制

### 占位符创建

**方法**：`FlagStoneLoader._createFlagStoneBigPlaceholder(subjectId)`

**占位符 CCB**：
- 优先使用：`slot/lobby/flagstone_loading/flagstone_small_loading.ccbi`
- 降级使用：`slot/lobby/flagstone_loading/flagstone_loading.ccbi`

**占位符标记**：
- `node._placeholderSubjectId = subjectId` — 标识这是占位符
- `node.controller._isPlaceholder = true`
- 补齐缺失方法（`showLevelLimitAnimation`、`canShowLevelLimitAnim`）

### 占位符替换

所有调用方使用统一的替换模式（以 `_onFlagStoneBigLoadFinish` 方法实现）：

```javascript
Controller.prototype._onFlagStoneBigLoadFinish = function (event) {
    // 1. 校验事件数据
    if (!event || !event.userData || !event.userData.success) return;

    // 2. 校验 subjectId 归属
    var subjectId = parseInt(event.userData.subjectId, 10);
    if (!this._subjectIdMap.hasOwnProperty(subjectId)) return;

    // 3. 校验占位符有效性
    var placeholder = this._itemNodes[itemIndex];
    if (!placeholder._placeholderSubjectId) return;  // 已是真实节点

    // 4. 记录原始属性
    var scale = placeholder.getScale();
    var position = placeholder.getPosition();
    var zOrder = placeholder.getLocalZOrder();

    // 5. 创建真实节点并替换
    var realNode = LobbyBigFlagStoneController.createFromCCB(subjectId);
    placeholder.removeFromParent(true);
    realNode.setScale(scale);
    realNode.setPosition(position);
    parentNode.addChild(realNode, zOrder, 7777);

    // 6. 更新引用 + 添加角标
    this._itemNodes[itemIndex] = realNode;
};
```

---

## 调用方一览

### 1. WinnerSlotsLevelListController

| 项目 | 说明 |
|------|------|
| 路径 | `src/task/controller/winner_slots/WinnerSlotsLevelListController.js` |
| 角标 | `addWinnerSlotNode(1.4)` |
| 缩放 | 0.6 |
| 特性 | 支持展开/收起动画 |

### 2. CloverClashLobbyFlagStoneEntrance

| 项目 | 说明 |
|------|------|
| 路径 | `src/task/controller/clover_clash/CloverClashLobbyFlagStoneEntrance.js` |
| 角标 | `addClashNode(1.4)` |
| 缩放 | 0.6 |
| 特性 | 使用 FrameScheduler 分帧创建 |

### 3. TowerTrialsLevelListController

| 项目 | 说明 |
|------|------|
| 路径 | `src/task/controller/tower_trials/ui/TowerTrialsLevelListController.js` |
| 角标 | `addWinnerSlotNode(1.4)` |
| 缩放 | 0.6 |
| 特性 | 支持 HR（High Roller）关卡选择 |

### 4. LobbyRichSlotsController

| 项目 | 说明 |
|------|------|
| 路径 | `src/common/controller/LobbyRichSlotsController.js` |
| 角标 | `addRichSlotsNode(1.4)` + `addFavoriteNode(1.2)` |
| 缩放 | 0.8 |
| 特性 | 双角标（Rich + Favorite） |

### 5. BadgesFlagStoneEntranceController

| 项目 | 说明 |
|------|------|
| 路径 | `src/task/controller/badges/BadgesFlagStoneEntranceController.js` |
| 角标 | `createFlagStoneTagSymbol`（自定义） |
| 缩放 | 0.55 |
| 特性 | 支持 ScrollView 滚动列表，未监听 `FLAGSTONE_BIG_LOAD_FINISH`（直接创建） |

---

## 角标系统

`LobbyBigFlagStoneController` 提供多种角标挂载方法，挂载在 `_clashNode` 或 `_favoriteNode` 节点上：

| 方法 | 角标类型 | 加载的 CCB |
|------|---------|-----------|
| `addClashNode(scale)` | CloverClash 活动图标 | 活动主题 `_icon.ccbi` |
| `addWinnerSlotNode(scale)` | WinnerSlots 活动图标 | 活动主题 `_icon.ccbi` |
| `addRichSlotsNode(scale)` | RichSlots / CasinoChallenge | `lobby_flagstone_tag_rich.ccbi` / `lobby_flagstone_tag_diamond.ccbi` |
| `addFavoriteNode(scale)` | Variate 收藏角标 | `lobby_flagstone_favorite_mid.ccbi` |
| `fixTagNodeScale(scale)` | 统一调整角标缩放 | — |

---

## FrameScheduler 集成

所有调用方使用 FrameScheduler 分帧创建 BigFlagStone 节点，避免一帧内创建过多 CCB 节点导致卡顿：

```javascript
FrameScheduler.getInstance().addTasks(subjectIds, function(subjectId, index) {
    // 1. 检查父节点有效性（场景切换保护）
    var parentNode = self["_machine" + index];
    if (!cc.sys.isObjectValid(parentNode)) return;

    // 2. 创建 BigFlagStone（工厂方法，内部处理占位符）
    var entrance = LobbyBigFlagStoneController.createFromCCB(subjectId);
    if (!cc.sys.isObjectValid(entrance)) return;

    // 3. 设置属性并添加到父节点
    entrance.setScale(0.6);
    parentNode.addChild(entrance, 0, 7777);

    // 4. 记录映射关系
    self._itemNodes.push(entrance);
    self._subjectIdMap[subjectId] = itemIndex;

    // 5. 真实节点立即添加角标
    if (!entrance._placeholderSubjectId && entrance.controller) {
        entrance.controller.addXxxNode(1.4);
    }
}, {
    name: 'Activity Machines',
    cost: FrameScheduler.Cost.HEAVY
});
```

**关键安全检查**：
- `cc.sys.isObjectValid(parentNode)` — 防止场景切换后节点已释放
- `entrance._placeholderSubjectId` — 区分占位符与真实节点

---

## 生命周期管理

### onEnter

1. 重置 `_isExiting = false`
2. 注册 `FLAGSTONE_BIG_LOAD_FINISH` 事件监听
3. 调用 `initMachines()` 开始分帧创建

### onExit

1. 设置 `_isExiting = true`（阻止异步任务继续执行）
2. 清空 `_itemNodes` 和 `_subjectIdMap`
3. 移除 `FLAGSTONE_BIG_LOAD_FINISH` 事件监听

---

## Jackpot 更新

`LobbyBigFlagStoneController` 自动监听 `SLOT_UPDATE_JACKPOT` 事件，实时更新关卡入口的 Jackpot 数值：

```javascript
LobbyBigFlagStoneController.prototype.onUpdateJackpot = function (event) {
    var subject = game.SlotConfigMan.getInstance().getSubject(this._subjectId);
    var jackpotInfoList = subject.jackpotInfoList;
    if (jackpotInfoList && jackpotInfoList.length) {
        var jackpotValue = game.SlotMan.getCurrent().getNewJackpotValue(
            jackpotInfoList[0].jackpotValue, subject.subjectId
        );
        game.activityUtil.setNodeText(this._jackpotLabel, game.util.getCommaNum(jackpotValue));
    }
};
```

**特殊处理**：关卡 141 使用 `jackpotLevelRatioMap[6]` 系数；关卡 208 无 Jackpot 时显示默认值 `9,999,999,999`。

---

## 资源工具

BigFlagStone 资源整理有专用工具支持，详见：[整理机台资源工具使用文档](/工程-工具/整理机台资源工具使用文档)

### 工具功能

- 自动扫描 CCB 引用的 plist 和散图
- 统一打包为 `slot_lobby_flagstone_big_<id>.plist`
- 整理到标准目录结构 `flagstone_big/<id>/`
- 支持 CV → DH 工程移植

### 标准目录结构

```
slot/lobby/flagstone_big/
└── <subjectId>/
    ├── slot_lobby_flagstone_big_<subjectId>.ccb
    ├── slot_lobby_flagstone_big_<subjectId>.plist
    └── slot_lobby_flagstone_big_<subjectId>.png
```

---

## 关键代码位置

| 模块 | 路径 | 关键方法 |
|------|------|---------|
| LobbyBigFlagStoneController | `src/common/controller/LobbyBigFlagStoneController.js` | `createFromCCB()`, `loadFromCCB()` |
| FlagStoneLoader | `src/resource_v2/loaders/FlagStoneLoader.js` | `loadFlagStoneBig()`, `getOrCreateFlagStoneBig()` |
| CommonEvent | `src/common/events/CommonEvent.js` | `FLAGSTONE_BIG_LOAD_FINISH` |
| SwitchMan | `src/common/model/SwitchMan.js` | `isEnableFlagstoneStyleSwitch()` |
| WinnerSlotsLevelList | `src/task/controller/winner_slots/WinnerSlotsLevelListController.js` | `initMachines()`, `_onFlagStoneBigLoadFinish()` |
| CloverClashEntrance | `src/task/controller/clover_clash/CloverClashLobbyFlagStoneEntrance.js` | `initMachines()`, `_onFlagStoneBigLoadFinish()` |
| TowerTrialsLevelList | `src/task/controller/tower_trials/ui/TowerTrialsLevelListController.js` | `initMachines()`, `_onFlagStoneBigLoadFinish()` |
| LobbyRichSlots | `src/common/controller/LobbyRichSlotsController.js` | `initMachines()`, `_onFlagStoneBigLoadFinish()` |
| BadgesEntrance | `src/task/controller/badges/BadgesFlagStoneEntranceController.js` | `createFlagStoneNode()` |

---

## 调试技巧

**关键日志**：

```javascript
// FlagStoneLoader
"[FlagStoneLoader] pauseQueueProcessing"
"[FlagStoneLoader] resumeQueueProcessing"

// 各调用方
"[WinnerSlotsLevelListController] Replaced placeholder for subjectId: %d"
"[CloverClashLobbyFlagStoneEntrance] Replaced placeholder for subjectId: %d"
"[TowerTrialsLevelListController] Replaced placeholder for subjectId: %d"
"[LobbyRichSlotsController] Replaced placeholder for subjectId: %d"

// LobbyBigFlagStoneController
"LobbyBigFlagStoneController loadFromCCB error,subjectId:"
```

## 常见问题

| 问题 | 排查方向 |
|------|---------|
| 活动入口显示加载中不消失 | 检查 `FLAGSTONE_BIG_LOAD_FINISH` 事件是否触发，下载是否成功 |
| 真实节点创建失败 | 检查 CCB 文件是否存在，路径格式是否与风格匹配 |
| 角标不显示 | 检查 `_placeholderSubjectId` 判断逻辑，确认替换后是否调用角标方法 |
| 占位符替换后位置偏移 | 检查 scale / position / zOrder 是否正确保存和恢复 |
| 场景切换崩溃 | 检查 `cc.sys.isObjectValid()` 节点有效性校验 |

---

**最后更新**：2026-03-31
**维护者**：WTC Team
