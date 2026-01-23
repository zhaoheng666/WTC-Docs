# Casino Royale 业务开发记录

**日期**: 2026-01-23
**开发者**: Claude + 用户
**涉及模块**: 小游戏系统、NPC层级管理

---

## 一、小游戏标注点系统开发

### 1.1 需求背景

在 `CasinoRoyaleMarkerManager` 中实现小游戏标注点的自动管理系统。

**需求**:
- gameType = 1 → 触发 'game' 类型标注点
- gameType = 2 → 触发 'trash' 类型标注点
- gameType = 3 → 触发 'game' 类型标注点
- 从各自对应的标注点随机抽取，不可重复使用
- 根据 leftTime 检测游戏倒计时，倒计时为0时回收标注点

### 1.2 第一版实现（过度复杂）❌

**实现方案**:
```javascript
this.activeGameMarkers = {};    // 当前激活的标注点
this.usedGameMarkers = {};      // 已使用的标注点列表
this.gameTypeToMarkerType = {   // 游戏类型映射
    1: 'game',
    2: 'trash',
    3: 'game'
};
```

**问题**:
- 数据结构过于复杂
- 需要手动调用 `checkAndRefreshMiniGame()`
- API 设计不直观

**用户反馈**: "设计的太复杂了，不需要这么麻烦"

### 1.3 第二版实现（精简版）✅

**简化方案**:
```javascript
this.mapMiniGameInfo = null;    // 小游戏数据
this.usedMarkers = {};          // {gameType: markerId}
```

**核心方法**:

#### initMiniGames()
```javascript
CasinoRoyaleMarkerManager.prototype.initMiniGames = function () {
    this.mapMiniGameInfo = this.activityData.getMapMiniGameInfo(this.sectionId);

    // 启动定时器，每秒自动检测
    this._startMiniGameTimer();
};
```

#### _triggerRandomMarker(gameData)
```javascript
// 1. 根据 gameType 确定标注点类型
var markerType = gameData.gameType === 2 ? 'trash' : 'game';

// 2. 从对应类型中随机选择未使用的标注点
var unusedMarkers = availableMarkers.filter(function(marker) {
    return !isUsed(marker.id);
});

// 3. 记录为已使用
this.usedMarkers[gameType] = selectedMarker.id;

// 4. 触发标注点（调用 triggerMarker 方法）
this.triggerMarker(selectedMarker.pos, 5);
```

### 1.4 需求变更：leftTime → endTime

**变更原因**: leftTime 需要每秒递减，改用时间戳更简洁

**修改**:
```javascript
// 修改前
if (gameData.leftTime === 0) {
    // 回收并重新触发
}

// 修改后
var currentTime = Date.now();
if (currentTime >= gameData.endTime) {
    // 回收并重新触发
}
```

### 1.5 最终优化：自动检测与触发

**优化点**:
1. 定时器每秒自动获取最新的 `mapMiniGameInfo`
2. 检测到有数据且未触发 → 自动触发
3. 检测到已到达 endTime → 回收并重新触发

**实现**:
```javascript
CasinoRoyaleMarkerManager.prototype._updateMiniGameTimer = function () {
    // 获取最新数据
    this.mapMiniGameInfo = this.activityData.getMapMiniGameInfo(this.sectionId);

    if (!this.mapMiniGameInfo || this.mapMiniGameInfo.length === 0) {
        return;
    }

    var currentTime = Date.now();

    for (var i = 0; i < this.mapMiniGameInfo.length; i++) {
        var gameData = this.mapMiniGameInfo[i];
        var isTriggered = this.usedMarkers[gameData.gameType] !== undefined;

        // 情况1：有数据且未触发 → 触发
        if (!isTriggered) {
            this._triggerRandomMarker(gameData);
        }
        // 情况2：已触发且到达结束时间 → 回收并重新触发
        else if (currentTime >= gameData.endTime) {
            delete this.usedMarkers[gameData.gameType];
            this._triggerRandomMarker(gameData);
        }
    }
};
```

### 1.6 最终文件修改

**文件**: `src/activity/casino_royale/controller/main/CasinoRoyaleMarkerManager.js`

**修改内容**:
1. 添加成员变量：`mapMiniGameInfo`、`usedMarkers`、`_miniGameTimer`
2. 实现方法：
   - `initMiniGames()` - 初始化并启动定时器
   - `_startMiniGameTimer()` - 启动定时器
   - `_updateMiniGameTimer()` - 每秒执行的更新逻辑
   - `_triggerRandomMarker(gameData)` - 随机选择并触发标注点
3. 清理逻辑：`clear()` 中清除定时器

---

## 二、NPC与建筑层级关系处理

### 2.1 问题描述

**现象**: NPC 移动时跑到建筑下面，遮挡关系错误

**原因**: 斜45度等距视角地图的层级关系未正确处理

### 2.2 节点结构分析

```
_buildNodes (父节点)
├── buildNode1 (层级=1，默认)
├── buildNode2 (层级=1，默认)
├── ...
└── _startNode (层级=2)
    ├── npc1
    ├── npc2
    └── ...
```

**关键点**:
- `buildNode` 和 `_startNode` 是**兄弟节点**
- 都在 `_buildNodes` 下
- 可以通过调整 buildNode 的 localZOrder 来控制相对于 _startNode 的显示顺序

### 2.3 第一版方案（错误）❌

**错误思路**: 让 NPC 和建筑都根据 Y 坐标动态设置 `zOrder = -Y`

**实现**:
```javascript
// NPC.js
CasinoRoyaleNpc.prototype.setPosition = function (pos) {
    this.baseNode.setPosition(pos);
    var zOrder = Math.floor(-pos.y);
    this.baseNode.setLocalZOrder(zOrder);
};

// MapBuildsController.js
var zOrder = Math.floor(-buildPos.y);
buildNode.setLocalZOrder(zOrder);
```

**问题**: 方案不对，用户要求恢复代码

**执行**: `git checkout` 恢复所有修改

### 2.4 正确方案讨论

**用户确认的需求**:
1. 当 NPC 距离建筑 ≤100 像素时
2. 根据 NPC 相对于建筑的位置调整建筑层级
3. 使得视觉效果上 NPC 在左侧建筑前面，在右侧建筑后面

**核心规则（斜45度地图）**:
- Y 坐标小 → 在屏幕前面 → 层级高
- Y 坐标大 → 在屏幕后面 → 层级低

**判断逻辑**:
```javascript
if (buildPos.y < npcPos.y) {
    // 建筑在 NPC 前面，建筑层级提升到 3
    buildNode.setLocalZOrder(LOCAL_Z_ORDER.BUILD_NODE_UP);
} else {
    // 建筑在 NPC 后面，建筑层级保持 1
    buildNode.setLocalZOrder(LOCAL_Z_ORDER.BUILD_NODE);
}
```

### 2.5 多NPC场景处理

**问题**: 如果多个 NPC 同时靠近同一个建筑怎么办？

**场景分析**:
```
buildA (Y=50)

npc1 (Y=100) - 在 buildA 后面
npc2 (Y=30)  - 在 buildA 前面

如果 npc1 触发调整 → buildA 层级 = 3
如果 npc2 触发调整 → buildA 层级 = 1
结果：层级反复切换！
```

**解决方案**:
1. 记录所有 NPC 的位置
2. 每次更新时，基于**所有靠近该建筑的 NPC**来决定层级
3. 找出 Y 坐标最小的 NPC（最靠前的）
4. 基于最靠前的 NPC 来决定建筑层级

**原因**: 只要建筑在任意一个 NPC 前面，就应该提升层级

### 2.6 最终实现 ✅

**文件**: `src/activity/casino_royale/controller/main/CasinoRoyaleMapBuildsController.js`

#### 添加成员变量
```javascript
this.npcPositions = {};  // {npcId: {x: number, y: number}}
```

#### onNpcReachNode(event)
```javascript
CasinoRoyaleMapBuildsController.prototype.onNpcReachNode = function (event) {
    var npcPos = event.userData.pos;
    var npcId = event.userData.npcId || 'default';

    // 记录该 NPC 的位置
    this.npcPositions[npcId] = {x: npcPos.x, y: npcPos.y};

    // 重新计算所有建筑的层级
    this._updateAllBuildZOrder();
};
```

#### _updateAllBuildZOrder()
```javascript
CasinoRoyaleMapBuildsController.prototype._updateAllBuildZOrder = function () {
    var sectionBoardIds = this.activityData.getSectionBoardIds(this.sectionId);
    var distanceValue = 100;

    // 遍历每个建筑
    sectionBoardIds.forEach(function (buildId) {
        var buildNode = this.getBuildNode(buildId);
        var buildPos = buildNode.getPosition();

        // 找出与该建筑距离 < 100 的所有 NPC
        var nearbyNpcs = [];
        for (var npcId in this.npcPositions) {
            var npcPos = this.npcPositions[npcId];
            var distance = this.getDistance(npcPos, buildPos);

            if (distance <= distanceValue) {
                nearbyNpcs.push({
                    id: npcId,
                    pos: npcPos,
                    distance: distance
                });
            }
        }

        // 如果有 NPC 靠近
        if (nearbyNpcs.length > 0) {
            // 找出 Y 坐标最小的 NPC（最靠前的）
            var minYNpc = nearbyNpcs[0];
            for (var i = 1; i < nearbyNpcs.length; i++) {
                if (nearbyNpcs[i].pos.y < minYNpc.pos.y) {
                    minYNpc = nearbyNpcs[i];
                }
            }

            // 基于最靠前的 NPC 决定建筑层级
            if (buildPos.y < minYNpc.pos.y) {
                // 建筑在最靠前 NPC 前面，层级提升
                buildNode.setLocalZOrder(LOCAL_Z_ORDER.BUILD_NODE_UP);
            } else {
                // 建筑在最靠前 NPC 后面，层级降低
                buildNode.setLocalZOrder(LOCAL_Z_ORDER.BUILD_NODE);
            }
        } else {
            // 没有 NPC 靠近，恢复默认层级
            buildNode.setLocalZOrder(LOCAL_Z_ORDER.BUILD_NODE);
        }
    }.bind(this));
};
```

**文件**: `src/activity/casino_royale/controller/main/CasinoRoyaleNpc.js`

#### 修改事件触发
```javascript
CasinoRoyaleNpc.prototype._onStartMove = function (pos) {
    var targetPos = this.baseNode.parent.convertToWorldSpaceAR(pos);
    game.eventDispatcher.dispatchEvent(CasinoRoyaleEventType.NPC_REACH_NODE, {
        pos: targetPos,
        npcId: this.npcId  // ← 添加 npcId
    });
};
```

### 2.7 关键修正

**问题**: 最初实现中先将所有建筑恢复默认层级，会干扰其他 NPC 已调整的建筑

**修正**:
```javascript
// ❌ 错误做法
sectionBoardIds.forEach(function (buildId) {
    buildNode.setLocalZOrder(LOCAL_Z_ORDER.BUILD_NODE);  // 先全部恢复
});

// 然后再调整靠近的建筑...

// ✅ 正确做法
sectionBoardIds.forEach(function (buildId) {
    var nearbyNpcs = [...];  // 找出靠近的 NPC

    if (nearbyNpcs.length > 0) {
        // 根据最靠前 NPC 决定层级
        buildNode.setLocalZOrder(...);
    } else {
        // 只有没有 NPC 靠近时才恢复默认
        buildNode.setLocalZOrder(LOCAL_Z_ORDER.BUILD_NODE);
    }
});
```

---

## 三、配置参数

### 3.1 层级配置

```javascript
var LOCAL_Z_ORDER = {
    BUILD_NODE: 1,      // 建筑默认层级
    PLAYER_NODE: 2,     // NPC 层级（_startNode 的层级）
    BUILD_NODE_UP: 3    // 建筑提升层级
};
```

### 3.2 距离阈值

```javascript
var distanceValue = 100;  // NPC 距离建筑 <= 100 像素时触发层级调整
```

### 3.3 小游戏定时器

```javascript
setInterval(function () {
    this._updateMiniGameTimer();
}.bind(this), 1000);  // 每秒执行一次
```

---

## 四、测试场景

### 4.1 单个 NPC 测试

**场景**:
```
buildA (Y=50)
npc1 从 Y=0 移动到 Y=100
```

**预期结果**:
- npc1 在 Y=20 时：buildA.Y(50) >= npc.Y(20) → buildA 层级 = 1 ✓
- npc1 在 Y=80 时：buildA.Y(50) < npc.Y(80) → buildA 层级 = 3 ✓

### 4.2 多个 NPC 测试

**场景**:
```
buildA (Y=50)
npc1 (Y=30) - 距离 buildA < 100
npc2 (Y=100) - 距离 buildA < 100
```

**预期结果**:
- 最靠前 NPC = npc1 (Y=30)
- buildA.Y(50) >= npc1.Y(30) → buildA 层级 = 1 ✓
- buildA 显示在两个 NPC 后面

### 4.3 NPC 移动测试

**场景**:
```
buildA (Y=50)
npc1 从 Y=30 移动到 Y=200（远离 buildA）
npc2 (Y=100) 静止
```

**预期结果**:
- npc1 远离后，nearbyNpcs = [npc2]
- 最靠前 NPC = npc2 (Y=100)
- buildA.Y(50) < npc2.Y(100) → buildA 层级 = 3 ✓

---

## 五、已知问题与优化

### 5.1 性能优化

**潜在问题**: 每次 NPC 移动都遍历所有建筑和所有 NPC

**优化方案**（待实现）:
1. 空间分区：按区域划分建筑和 NPC
2. 距离缓存：缓存距离计算结果
3. 增量更新：只更新受影响的建筑

### 5.2 边界情况

**情况1**: NPC 销毁后位置未清理
```javascript
// 需要在 NPC.destroy() 中清理位置记录
CasinoRoyaleNpc.prototype.destroy = function () {
    // TODO: 通知 MapBuildsController 清除该 NPC 的位置记录
};
```

**情况2**: 建筑动态添加/删除
- 当前实现会自动处理，每次都重新遍历所有建筑

### 5.3 调试日志

已添加详细日志输出：
```javascript
cc.log('[CasinoRoyaleMapBuildsController] 建筑在NPC前面，提升层级:', buildId,
    '建筑Y:', buildPos.y, '最靠前NPC(' + minYNpc.id + ') Y:', minYNpc.pos.y,
    '附近NPC数:', nearbyNpcs.length, '→ BUILD_NODE_UP');
```

---

## 六、相关文件清单

### 6.1 核心文件

| 文件 | 修改内容 |
|------|---------|
| `CasinoRoyaleMarkerManager.js` | 小游戏标注点系统 |
| `CasinoRoyaleMapBuildsController.js` | NPC 与建筑层级管理 |
| `CasinoRoyaleNpc.js` | 添加 npcId 传递 |

### 6.2 工具文件

| 文件 | 说明 |
|------|------|
| `/Users/gaoyachuang/Desktop/路线图_线段绘制工具.html` | 路线图编辑工具 |

### 6.3 配置文件

| 文件 | 说明 |
|------|------|
| `res_oldvegas/activity/casino_royale_map_X/path_config_map.json` | 路径配置 |

---

## 七、后续计划

### 7.1 功能增强
- [ ] NPC 销毁时清理位置记录
- [ ] 性能优化（空间分区）
- [ ] 支持更多标注点类型

### 7.2 工具改进
- [ ] 路线图工具添加路径验证
- [ ] 自动检测路径是否闭环
- [ ] 支持批量操作

### 7.3 文档完善
- [ ] 添加更多测试案例
- [ ] 录制操作视频
- [ ] 补充故障排查指南

---

**维护者**: WorldTourCasino Team
**最后更新**: 2026-01-23
**状态**: ✅ 已完成并测试
