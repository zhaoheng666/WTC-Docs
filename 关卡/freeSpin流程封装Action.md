# FreeSpin 流程 Action

## 1. 注册 freeSpinAction

在生成的关卡脚本文件中，打开开关，即可自行注册 freeSpinAction 对象：

```javascript
this.machineConfig.needFreeGameAction = true;
```

## 2. 开始 freeSpin 流程

### 预留接口：onEnterFreeSpin

用于在关卡脚本中记录 freeSpin 玩法中的一些自定义状态。

### 流程步骤：

1. **调整节奏**：弹出开始弹板前的 delayTime
   ```javascript
   machineConfig.delayBeforeFreeSpinBeginPanelClose
   ```

2. **弹出开始 freeSpin 弹板**
   - 弹板 ccb：`machineConfig.freespinBeginPanelCCB`
   - 音效：`machineConfig.freespinBeginPanelSound`
   - 自动关闭等待时长：`machineConfig.freespinBeginPanelAutoCloseDelayTime`
   - 自定义样式：`machineScene.refreshFreeSpinBeginPanel()`

3. **调整节奏**：弹板关闭后的 delayTime
   ```javascript
   machineConfig.delayAfterFreeSpinBeginPanelClose
   ```

4. **过场动画**（某些关卡需求会插入）
   - 动画 ccb：`machineConfig.freeSpinBeginTransferAnimCCB`
   - 音效：`machineConfig.freeSpinBeginTransferSound`

5. **播放 freeSpin 背景音乐**
   ```javascript
   machineConfig.freeSpinBgMusic
   ```

6. **调整节奏**：过场动画时长，也可用于在轮盘、logo、计数器变状态前的 delayTime
   ```javascript
   machineConfig.freeSpinBeginTransferAnimTime
   ```

7. **轮盘、标题变色**，调用 machineScene 中的接口
   - 方法：`machineScene.onFreeSpinBeginWheelStyleChange()`

8. **调整节奏**：显示计数器之前的 delayTime
   ```javascript
   this.freeSpinAction.setBeforeShowFreeSpinCounterDelayTime(delayTime)
   ```

9. **显示计数器**

### 计数器格式要求

#### 1. spinUI 处常规展示：当前次数/总次数 的形式

作为单独的 ccb 节点：
- ccb 节点命名：`freeSpinCounter`，需有 appear、disappear、add 动画
- 当前次数 label 节点命名：`_curCountLabel`
- 总次数 label 节点命名：`_totalCountLabel`

![计数器格式示例1](http://localhost:5173/WTC-Docs/assets/1760346210615_7163febf.png)

#### 2. 只显示剩余次数，又细分为两种情况：

**(1) 纯粹单独的 freeSpin 剩余次数展示**（不与其他节点相互掺杂在一起）
- ccb 节点命名：`freeSpinCounter`，需有 appear、disappear、add 动画
- 剩余次数 label 节点命名：`_leftCountLabel`

![计数器格式示例2](http://localhost:5173/WTC-Docs/assets/1760346210616_05b05e2d.png)

**(2) 通过其他节点的动画切换到展示剩余次数**

可使用上述方式，只是将切换的动画名对应设置为 appear、disappear。

也可以选择使用自定义接口，在轮盘变色的接口中进行同时切换。切换时需要手动调用 freeSpinAction 中更新次数展示的接口：
```javascript
this.freeSpinAction.updateFreeSpinCounter()
```

10. **调整节奏**：显示计数器之后，进入 freeSpin 前的 delayTime
    ```javascript
    this.freeSpinAction.setAfterShowFreeSpinCounterDelayTime(delayTime)
    ```

11. **流程控制，进入 freespin**

## 3. Retrigger 再次触发 freeSpin 流程

### 新增配置：
```javascript
machineConfig.freeSpinRetriggerPanelAutoCloseDelayTime
machineConfig.retriggerFreeSpinUpdateDelayTime
machineConfig.retriggerFreeSpinAddAnimTime
```

### 原有配置：
```javascript
machineConfig.delayBeforeFreeSpinRetriggerPanelClose
machineConfig.delayAfterFreeSpinRetriggerPanelClose
machineConfig.freespinRetiggerPanelCCB
machineConfig.freespinRetiggerPanelSound
```

## 4. 结束 freeSpin 流程

### 预留接口：onExitFreeSpin

在弹板流程前，在关卡中清除状态等操作。

### 流程步骤：

1. **调整节奏**：弹出结束弹板前的 delayTime
   ```javascript
   machineConfig.delayBeforeFreeSpinEndPanelClose
   ```

2. **弹出结束 freeSpin 弹板、停止 freeSpin 的背景音乐**

   **弹板配置：**
   - 有赢钱：`machineConfig.freespinEndPanelCCB`
   - 无赢钱：`machineConfig.freespinLuckyPanelCCB`

   **弹板音效：**
   - 有赢钱：`machineConfig.freeSpinEndPanelSound`
   - 无赢钱：`machineConfig.freespinLuckyPanelSound`

   **自动关闭弹板等待时长：**
   - 有赢钱：`machineConfig.freeSpinEndPanelAutoCloseDelayTime`
   - 无赢钱：`machineConfig.freeSpinLuckyPanelAutoCloseDelayTime`

   **自定义样式：**
   - 有赢钱：`machineScene.refreshFreeSpinEndPanel()`
   - 无赢钱：`machineScene.refreshFreeSpinEndLuckyPanel()`

3. **调整节奏**：弹板关闭后的 delayTime
   ```javascript
   machineConfig.delayAfterFreeSpinEndPanelClose
   ```

4. **轮盘、标题切换为 base 状态**，调用 machineScene 中的接口
   - 接口：`machineScene.onFreeSpinEndWheelStyleChange()`

5. **调整节奏**：隐藏计数器之前的 delayTime
   ```javascript
   this.freeSpinAction.setBeforeHideFreeSpinCounterDelayTime(delayTime)
   ```

6. **隐藏计数器**

   与开始 freeSpin 时显示计数器的用法一致，只是这里不需要再调用 update 方法更新展示次数。如果使用 `freeSpinCounter` 命名节点的话，将隐藏的动画命名为 `disappear` 即可。

7. **调整节奏**：隐藏计数器之后，结束 freeSpin 前的 delayTime
   ```javascript
   this.freeSpinAction.setAfterHideFreeSpinCounterDelayTime(delayTime)
   ```

8. **流程控制，结束 freespin**