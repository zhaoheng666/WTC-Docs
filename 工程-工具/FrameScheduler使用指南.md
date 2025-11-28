# FrameScheduler 使用指南

## 概述

FrameScheduler 是一个帧感知的任务调度器，用于将重型任务分散到多帧执行，避免单帧卡顿。

**版本**: v3.2.0

**核心特性**:
- 动态读取引擎帧率（`cc.director.getAnimationInterval()`）
- 基于帧预算的任务调度
- 任务成本分级（LIGHT/MEDIUM/HEAVY/VERY_HEAVY）
- 支持任务组和回调

## 基本用法

```javascript
var FrameScheduler = require("../common/util/FrameScheduler");

FrameScheduler.getInstance().addTasks(
    dataArray,
    function(item, index) {
        // 处理每个任务
    },
    {
        name: '任务描述',
        cost: FrameScheduler.Cost.HEAVY
    }
);
```

## 关键模式：闭包节点有效性检查

### 问题场景

当使用 FrameScheduler 处理 UI 创建任务时，存在一个关键的生命周期问题：

1. 任务在 `onEnter` 中添加到调度器
2. 任务通过闭包捕获 `self` 引用
3. **场景切换时**，节点被释放，但任务仍在队列中
4. 任务执行时，`self` 或其子节点已经是无效的 Native 对象
5. 调用 `addChild` 导致崩溃：`Error: js_cocos2dx_Node_addChild : Invalid Native Object`

### 解决方案

**在任务执行时（而非创建时）检查节点有效性**：

```javascript
FrameScheduler.getInstance().addTasks(
    subjectIds,
    function(subjectId, index) {
        // ⚠️ 关键：检查父节点有效性（场景切换后可能已释放）
        var parentNode = self["_machine" + index];
        if (!cc.sys.isObjectValid(parentNode)) {
            return;  // 节点已释放，跳过此任务
        }

        var entrance = LobbyBigFlagStoneController.createFromCCB(subjectId);
        if (cc.sys.isObjectValid(entrance) && entrance.controller) {
            entrance.setScale(0.6);
            parentNode.addChild(entrance);
            entrance.controller.addWinnerSlotNode(1.4);
            self._itemNodes.push(entrance);
        }
    },
    {
        name: 'WinnerSlots level list entrance',
        cost: FrameScheduler.Cost.VERY_HEAVY
    }
);
```

### 检查清单

使用 FrameScheduler 创建 UI 节点时，必须：

| 检查项 | 说明 |
|-------|------|
| ✅ 检查父节点有效性 | `cc.sys.isObjectValid(parentNode)` |
| ✅ 检查创建结果有效性 | `cc.sys.isObjectValid(entrance)` |
| ✅ 在任务函数内部检查 | 不是在添加任务时检查 |

### 完整示例

以下是从 `initMachines` 调用 FrameScheduler 的标准模式：

```javascript
Controller.prototype.initMachines = function () {
    var subjectIds = this._activity.getSubjectIds();
    var self = this;

    // 使用帧调度器分帧创建入口（重型任务：创建 CCB 节点）
    FrameScheduler.getInstance().addTasks(
        subjectIds,
        function(subjectId, index) {
            // 检查父节点有效性（场景切换后可能已释放）
            var parentNode = self["_machine" + index];
            if (!cc.sys.isObjectValid(parentNode)) {
                return;
            }
            var entrance = LobbyBigFlagStoneController.createFromCCB(subjectId);
            if (cc.sys.isObjectValid(entrance) && entrance.controller) {
                entrance.setScale(0.6);
                parentNode.addChild(entrance);
                entrance.controller.addWinnerSlotNode(1.4);
                self._itemNodes.push(entrance);
            }
        },
        {
            name: 'Activity level list entrance',
            cost: FrameScheduler.Cost.VERY_HEAVY
        }
    );
};
```

## 延迟初始化模式

为避免在 `onEnter` 中直接执行重型操作导致的生命周期问题，推荐使用延迟初始化：

```javascript
Controller.prototype.onEnter = function () {
    game.SmartCCBController.prototype.onEnter.call(this);

    // 延迟一帧执行初始化，避免 cobj 和生命周期时序问题
    setTimeout(function () {
        this.initMachines();
    }.bind(this), 0);
};
```

## 成本分级

| 级别 | 常量 | 适用场景 |
|-----|------|---------|
| LIGHT | `FrameScheduler.Cost.LIGHT` | 简单数据处理 |
| MEDIUM | `FrameScheduler.Cost.MEDIUM` | 普通 UI 更新 |
| HEAVY | `FrameScheduler.Cost.HEAVY` | 复杂计算 |
| VERY_HEAVY | `FrameScheduler.Cost.VERY_HEAVY` | CCB 节点创建 |

## 配置

FrameScheduler 自动读取引擎帧率，默认使用 70% 的帧时间作为预算：

```javascript
// 调整预算比例（可选）
FrameScheduler.getInstance().setBudgetRatio(0.8);  // 使用 80% 帧时间
```

## 已应用的文件

以下文件已应用此模式：

- `src/common/controller/LobbyRichSlotsController.js`
- `src/task/controller/tower_trials/ui/TowerTrialsLevelListController.js`
- `src/task/controller/winner_slots/WinnerSlotsLevelListController.js`
- `src/task/controller/clover_clash/CloverClashLobbyFlagStoneEntrance.js`

## 相关提交

- `e41a0be5fc0` - cv：资源加载优化 FrameScheduler 任务执行前检查闭包节点有效性
- `e2dc1124a55` - cv：资源加载优化 活动入口 initMachines 添加生命周期保护
- `b9895060a71` - cv：资源加载优化 FrameScheduler 使用引擎帧率动态计算帧预算
