# FlagStone 占位节点未替换 / cellIndex 错位问题

## 现象

大厅 FlagStone 列表（`FlagStoneTableView`）中，某些 cell 长期停留在 `flagstone_loading.ccbi` 占位状态，对应资源**实际已下载完毕**但**未替换**为真实节点。

- **平台**：web 与 native 均复现，与平台无关
- **触发**：首屏静止、滑动中、滑动停止后任何状态都可复现，与滑动状态无关
- **截图特征**：屏幕上同时出现多个连续的 `JACKPOT LOADING…` 占位 cell

![现场截图：DH 大厅首屏出现 3 个并排的 JACKPOT LOADING 占位 cell](/assets/64359ee44dac154f400e288145bcd2b4.png)

## 诱因（触发该问题的因素）

4 月上线的**大厅竖广告牌跟随移动**功能，将原本不计入 cellIndex 的 LobbyBoard 加入了计算，但未同步到 onFlagStoneDownloadFinish方法、且 onFlagStoneDownloadFinish 未预设 LobbyBoard 计算逻辑，导致 cellIndex 错位、加载完成后无法通知到正确的 flagstone cell；

## 根因

`FlagStoneTableView` 中关于"subjects 前固定要插入的前置 cell（preItems）"的累加逻辑**在 4 个位置各写了一遍**，未做统一维护，新特性引入后未能同时覆盖所有位置；

| 调用点 | 累加项 | 是否含 LobbyBoard |
|---|---|---|
| `tableCellSizeForIndex` | LobbyBoard + NewSlotBanner + SpinBattle + Winner + Tower + Clover + Badges | ✅ |
| `tableCellAtIndex` | LobbyBoard + NewSlotBanner + SpinBattle + Winner + Tower + Clover + Badges | ✅ |
| `numberOfCellsInTableView` | LobbyBoard + NewSlotBanner + SpinBattle + Badges + Winner + Clover + Tower（顺序乱但只统计 count） | ✅ |
| `onFlagStoneDownloadFinish` | NewSlotBanner + SpinBattle + Winner + Tower + Clover + Badges | ❌ **漏 LobbyBoard** |

而 `isShowLobbyBoard()` 当前实现是 `return true`——永远返回 true。

**后果**：handler 计算出的 `cellIndex = subjectIdx + preItemsCount` **永远比真实位置少 1**，`updateCellAtIndex(cellIndex)` 调用 `tableCellAtIndex(cellIndex)` 时拿到的是 `_currentSubjects[cellIndex - 1]`（错位的 subject），rebind 时 folder 与事件 folder 不一致，重新走占位分支，**真正需要被刷新的 cell 永远没人刷**。

## 修复

提取私有方法 `_getPreItems()` 作为**单一数据源**，返回数组 `[{data, size}, …]`，让所有调用者按需取 `.length` 或元素：

```javascript
// src/common/custom_node/FlagStoneTableView.js
_getPreItems: function () {
    var preItems = [];
    if (this.isShowLobbyBoard()) {
        preItems.push({
            data: {lobbyBoard: 1},
            size: cc.size(LOBBY_BOARD_WIDTH, this._cellHeight)
        });
    }
    if (this.isNewSlotBannerOpen()) {
        preItems.push({ /* ... */ });
    }
    // spin battle / winnerSlots / towerTrials / cloverClash / badges
    // ...
    return preItems;
},

onFlagStoneDownloadFinish: function (event) {
    // ...
    var preItemsCount = this._getPreItems().length;  // ← 用同一来源
    // ...
    var cellIndex = i + preItemsCount;
    this._tableView.updateCellAtIndex(cellIndex);
}

tableCellAtIndex: function (table, index) {
    var preItems = this._getPreItems();
    if (index < preItems.length) {
        cell.bindData(preItems[index].data, table);
    } else {
        var subject = this._currentSubjects[index - preItems.length];
        cell.bindData(subject, table);
    }
}

tableCellSizeForIndex: function (table, index) {
    var preItems = this._getPreItems();
    if (index < preItems.length) {
        return preItems[index].size;
    }
    return cc.size(this._cellWidth, this._cellHeight);
}

numberOfCellsInTableView: function () {
    var subjectsCount = this._currentSubjects ? this._currentSubjects.length : 0;
    return subjectsCount + this._getPreItems().length;
}
```

## 测试范围

按本次修改的影响面分4层验证。（DH）
**CV 的大厅列表继承自 `FlagStoneTableView`、但未重写 preItems 相关方法，有自己的Subjects 排列计算方式，理论上不受本次修改影响；但保险起见仍需跑一下、排除未预料到的间接影响。**

### 一、直接修复点：占位 → 真实替换链路（必测）

| # | 场景 | 操作步骤 | 预期 |
|---|---|---|---|
| 1.1 | 首屏占位替换（核心 case） | 清缓存后进入大厅，观察首屏可见的 FlagStone cell | 占位 ccbi（`JACKPOT LOADING…`）应在对应资源下载完成后自动替换为真实关卡节点，无需任何手动操作 |
| 1.2 | 滑动停止后替换 | 缓存未命中状态下快速滑动列表 → 立即松手 → 让某个占位停在屏幕内 | 停止后该 cell 在数秒内被替换为真实节点 |
| 1.3 | 切前后台 | 占位状态下切到后台 → 等待几秒 → 切回前台 | 切回后被替换；不出现黑色纹理 |
| 1.4 | Tab 切换 | 大厅切换到其他 Tab 再切回 | 已下载的资源应直接显示真实节点，未下载的显示占位并随后替换 |
| 1.5 | 风格回归 | 在 CV 风格（`ClassicFlagStoneTableView`）大厅重复 1.1-1.4 | 行为与 DH 一致 |

### 二、关联影响：列表布局与 cell 渲染（必测）

`_getPreItems()` 被 `tableCellAtIndex` / `tableCellSizeForIndex` / `numberOfCellsInTableView` 三个 TableView 数据源回调共用，重构后需确认布局未破坏。

| # | 场景 | 检查项 |
|---|---|---|
| 2.1 | LobbyBoard 渲染 | 大厅首位的广告位 (LobbyBoard) 仍正常显示，宽度 = `LOBBY_BOARD_WIDTH`，未被错误识别为关卡 |
| 2.2 | 活动入口位置 | 已开启的活动（CloverClash / SpinBattle / WinnerSlots / TowerTrials / Badges）入口节点位置和宽度正确 |
| 2.3 | NewSlotBanner | 若当前 Slot 配置了 `newSlotBanner`，曝光位宽度 = `LOBBY_NEWSLOT_BANNER_WIDTH`，位置正确 |
| 2.4 | cell 总数 | 列表能完整滑到最右侧的 `Coming Soon` cell，不多不少 |
| 2.5 | 翻页指示器 | `PageIndicator` 圆点数量与实际页数一致；左右箭头显隐正确 |
| 2.6 | 样式切换 | DH 上切换新旧 flagstone 样式（`isUseNewFlagstoneStyle`）后，cell 尺寸切换正常、占位 ccbi 路径正确 |

### 三、活动开关组合（按风险分级抽测）

preItems 元素数量取决于 7 个开关组合。穷举 128 组不现实，按风险分级抽测：

| # | 组合 | 优先级 |
|---|---|---|
| 3.1 | 全部活动关闭（最常见） | P0 |
| 3.2 | 1 个活动开启 + LobbyBoard | P0 |
| 3.3 | 多个活动同时开启（如 CloverClash + SpinBattle + Badges） | P1 |
| 3.4 | 活动从开启切换到关闭（运营结束瞬间） | P2 |

每组都需验证：① 占位能被替换；② 活动入口与关卡入口顺序正确；③ 列表总长度正确。

### 四、临界场景（不能引入新问题）

- ❌ **不能**因为 `numberOfCellsInTableView` 的简化（从 7 个 `if` 改为 `_getPreItems().length`）而导致 `_currentSubjects === null` 时崩溃 → 已通过 `this._currentSubjects ? ... : 0` 兜底，需用"切 Tab 但未加载 subject 列表"的极端时机验证。
- ❌ **不能**让 `tableCellAtIndex` 在 `index >= maxLen` 的 fallback 分支（`Coming Soon` cell）出错 → 滑到列表末尾验证。
- ❌ **不能**让样式切换路径上 `_pendingRefreshCellIndices` 缓存失效 → 后台→前台切换中、`onFlagStoneStyleChanged` 触发后均要看到正确刷新。

## 相关文件

- `src/common/custom_node/FlagStoneTableView.js` — `_getPreItems()` 及 4 个调用点（本次修复主战场）
- `src/common/custom_node/ClassicFlagStoneTableView.js` — CV 风格使用独立的 `_flagStoneData` 预打平模型，已重写 `tableCellAtIndex` / `tableCellSizeForIndex` / `numberOfCellsInTableView`；本次额外添加 `onFlagStoneDownloadFinish` no-op 覆写，显式声明 CV 不走父类精确刷新链路，防止父类该方法未来改动意外影响 CV

--- 
---
> 以下章节为复盘内容，对正在踩坑的读者非必读；如需快速修复，看上面三节即可。

## 误诊路径（复盘）

排查过程中走了两轮错误假说，**两轮失误的共同病因都是"现象信息不完整就开始推理"**——参见下文「可推广的教训」第 1 条。记录如下以警示后人：

### 假说 A（被证伪）：native 滚动停止信号未触发导致下载队列卡 pause

最初看到 native 上 `EaseScrollView` 的速度阈值检测（`_scrollStopValue = 80`）只在 `update()` 内的 if 分支执行，担心**惯性结束时 velocity 一帧跨过阈值**会让 `onScrollViewScrollStop` 永不触发 → `_flagstoneQueue.pause()` 后无法 resume → 下载停顿 → 事件永不分发。

**反证证据**：补充验证发现 web 也复现、首屏静止也复现。web 没有 pause 机制、不滑动也不会触发 pause，假说不成立。

### 假说 B（被证伪）：native CacheManager 的 manifest 校验导致 isDownloaded 始终 false

担心 native 上 `CacheManager.isDownloaded` 的版本检查（`needsVersionCheck`）会让 `_downloadedMap` 内存命中之外的资源持续返回 false。

**反证证据**：`CacheManager.isDownloaded` L206-208 是**先查内存 `_downloadedMap`，命中即返回 true**；而 `_onTaskComplete` 中 `markAsDownloaded` 在 `_dispatchFlagStoneEvent` 之前已经写入内存缓存。时序上 handler 收到事件时缓存一定就绪。

### 假说 C（部分正确）：handler 内部某种判定提前 return

加日志后看到事件链路完整：`dispatchEvent → handler enter → match → calling updateCellAtIndex(N) → updateCellAtIndex done` 全部正常成功，但屏幕仍是占位。说明 `updateCellAtIndex` 被调用了，**但刷的是错的 cell**。

![[FSTV] 调试日志：事件链路全部 success，但 match 报的 cellIndex 比真实少 1，导致刷错位](/assets/70e4abe396e142431a1d18aa279ba8e3.png)

注意上图日志中：
- `match: subjectIdx=2, subjectId=274, ..., cellIndex=2` —— **本应是 cellIndex=3**（subjectIdx=2 + LobbyBoard=1 = 3）；
- 紧接着 `calling updateCellAtIndex(2)` 内部触发的 `getOrCreateFlagStone` 拿到的却是 `subjectId=289, folder=yay_yeti_glitzy`（subjectIdx=1 对应的 subject）—— 正是"刷错位"的铁证。

## 可推广的教训

1. **先把现象空间打满，再开始推理**。本案例最贵的两轮误诊（假说 A、B）都源于一个共同失误：最初仅掌握"native 上停止滑动后未替换"这一条线索就开始推理，下意识把"native 平台特有"、"滑动状态相关"当成约束条件，从而把方向锁死在 EaseScrollView 速度阈值、native CacheManager manifest 校验这些**伪相关代码**上。真正的破局点出现在补充验证 web 也复现、首屏静止也复现之后——现象矩阵从 1×1 扩到 2×2，伪约束立刻被证伪。
   - **方法论**：动手前先主动采集这几类证据，凑齐再推理：
     - **各端差异**：web / native / iOS / Android 是否表现一致？
     - **触发条件**：静止 / 滑动 / 切前后台 / 切 Tab 是否都复现？复现率多少？
     - **数据范围**：所有 cell / 特定 cell？所有 subject / 特定 subject？是否与登录账号、活动状态相关？
     - **现场日志**：报错？警告？完整事件链？是否能 grep 到关键 Tag？
   - **反面提示**：在信息不足时坚持推理，本质上是在用"对现象的揣测"代替"对事实的观察"——越熟悉代码的人越容易掉进去，因为脑子里能编出来的合理故事太多了。
2. **"长度 = 多处条件累加"** 是高危结构。任何时候出现"3 处以上在重复同一份判定列表"，几乎必然在未来某次新增条件时漂移。**单一数据源**比"加注释提醒"可靠 100 倍。
3. **平台/状态无关的 bug，几乎都不在平台/状态相关代码里**。当现象在 web + native + 静止 + 滑动 4 种组合下都复现时，应**立刻放弃**任何平台分支、定时器、状态机相关假说，直接审查共同代码路径——本案例如果第一时间直奔 handler 的 cellIndex 计算，10 分钟就能定位。
4. **加日志要打完整事件链**。本案例最终破案靠的是从 `dispatchEvent → handler enter → match → updateCellAtIndex done` 的串联日志，发现整条链路"全部成功"——这反而是定位 bug 的关键证据（"调用成功但刷到错的位置"远比"调用失败"更难想到）。统一日志 Tag（如 `[FSTV]`）便于一次 grep 看全链路。
5. **TableView 的 `updateCellAtIndex(cellIndex)` 是基于 cellIndex 而不是 subjectId**。当事件回包带的是业务标识（folder、subjectId）时，**业务标识 → cellIndex 的换算函数必须与渲染端使用同一数据源**，否则就是这种"调用成功但刷错位"的隐蔽 bug。

## 时间线

- **2026-05-18**：报告 native 上滑动停止后占位未替换 → 启动调研
- 加 `[FSTV]` 日志诊断 → 排除 2 轮假说 → 定位到 `cellIndex` 错位
- 抽 `_getPreItems()` 单一数据源 → 修复并清理日志 → 验证构建通过
