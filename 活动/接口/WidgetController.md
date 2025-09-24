# Slots-WidgetController 文档

## 1. ActivityWidgetController.js

### 功能
活动关卡入口控制器基类，提供通用的关卡内活动入口控制逻辑，如进度条、倒计时、点击交互、动画控制等。

### 变量

#### 核心绑定
- `this._activity`: 绑定的Activity实例

#### UI节点
- `this._slotScene`: 场景节点
- `this._node_spinning`: 自旋节点
- `this._progressBar`: 进度条节点
- `this._node_task_panel`: 任务面板节点

#### 进度条配置
- `this.progressBarCreator`: 进度条创建器（如水平、垂直、圆形）

#### 显示控制
- `this.isShowBetTips`: 是否显示下注提示
- `this.isGotoSpinShowTaskPanel`: 是否在Spin时弹出任务面板
- `this.isEnterShowTaskPanel`: 是否进入界面时自动展开面板

#### 特效系统
- `this.smokeScript`: 烟雾特效脚本

#### 奖励控制
- `this.isAutoClaimTaskReward`: 是否自动领取任务奖励
  - 0: 不自动
  - 1: 自动preSpin
  - 2: postSpin

#### 时间更新
- `this.isUpdateCountTime`: 是否启用倒计时更新

#### 位置配置
- `this.isLeftWidget`: 是否为左侧小部件
- `this.leftWidgetOffset`: 左侧小部件偏移
- `this.leftWidgetHideOffset`: 左侧小部件隐藏偏移
- `this.leftWidgetSize`: 左侧小部件尺寸
- `this.leftWidgetPriority`: 左侧小部件优先级

#### 整合入口
- `this.centerWidgetController`: 活动整合入口控制器
- `this.centerWidgetPriority`: 整合入口优先级
- `this.doNotUseCenterWidget`: 是否使用整合入口
- `this.doublehitWidgetCenter`: DoubleHit特殊处理

#### 红点系统
- `this.hasNewMessage`: 是否有新消息红点

### 方法

#### 初始化与绑定
- `initWith(slotScene, activityTag)`: 初始化绑定场景和活动标签
- `initWithActivity(activity)`: 绑定活动并初始化UI
- `onDidLoadFromCCB()`: CCB加载完成回调

#### 进度条管理
- `initProgressBar()`: 初始化进度条
- `onUpdateProgress(callback)`: 更新进度条
- `setProgress()`: 设置进度条动画
- `setProgressWithoutAni()`: 设置进度条无动画
- `playProgressBarAnimation(progress, time)`: 执行进度条动画

#### 生命周期
- `onEnter()`: 节点进入场景时注册事件监听、播放音乐、初始化UI
- `onExit()`: 节点退出时清理资源
- `initUI()`: 初始化UI（子类实现）

#### 位置管理
- `initWidgetPosition()`: 设置小部件位置
- `initLeftWidgetPosition()`: 设置左侧小部件位置

#### 动画控制
- `playClaimButtonAnim(enabled, anim)`: 奖励按钮动画（点亮/熄灭）
- `playHideWidgetAnim()`: 收起小部件动画
- `playShowWidgetAnim()`: 展开小部件动画
- `initWidgetAnimMask()`: 使用_animMask设置边界

#### 事件处理
- `onActivityEnd(event)`: 活动结束时的行为
- `onActivityComplete(event)`: 活动完成时的行为
- `onNewTaskGroup(event)`: 新任务组触发时的行为
- `onSpinDisabled(event)`: 自旋禁用时禁用按钮
- `onSpinEnabled(event)`: 自旋启用时启用按钮

#### 按钮控制
- `disableButtons()`: 禁用所有按钮
- `enableButtons()`: 启用所有按钮

#### 交互处理
- `onWidgetClicked(sender)`: 小部件点击处理
- `onProgressClicked(sender)`: 进度条点击处理
- `onOpenMainUIClicked()`: 打开主界面按钮点击

#### 日志记录
- `logEvent(eventName, args)`: 记录UI点击日志

#### 状态查询
- `isRunningTask()`: 判断当前是否正在运行任务

#### 下注提示
- `showBetTip()`: 显示下注提示
- `hideBetTip()`: 隐藏下注提示
- `isBetTipCanShow()`: 判断下注提示是否可显示

#### 自旋事件
- `onGotoSpinEvent(event)`: 接收GotoSpin事件并弹出任务面板

#### 自动奖励
- `tryClaimTaskReward()`: 尝试自动领取任务奖励
- `onPreSpinUpdate(callback)`: 自旋前更新
- `onPostSpinUpdate(callback)`: 自旋后更新
- `onRewardClaimDataReceived(event)`: 领取奖励成功处理
- `onRewardClaimError(event)`: 领取奖励失败处理

#### 时间更新
- `updateCountTime()`: 更新倒计时文本

#### 红点管理
- `setHasNewMessage(hasNewMessage)`: 设置红点状态
- `getHasNewMessage()`: 获取红点状态

#### 整合入口控制
- `isCenterWidgetHidden()`: 是否被隐藏在整合入口中
- `setCenterWidgetEnabled(enabled)`: 控制整合入口是否可滑动
- `playShowCenterWidgetAnim(callback)`: 播放展示整合入口动画

#### 工厂方法
- `createFromCCB(activity, ccbPath)`: 从CCB创建控制器实例

---

## 2. ActivityBaseWidgetController.js

### 功能
活动关卡入口控制器抽象基类，继承自 [`ActivityWidgetController`](#1-activitywidgetcontrollerjs)，支持进度条动画、道具收集、BUFF效果等功能。

### 变量

#### 飞行道具
- `this.isNeedFlyProps`: 是否需要飞行道具动画
- `this._appearDelayTime`: 出现延迟时间
- `this.propsCount`: 当前获得道具数
- `this.MAX_PROPS_COUNT`: 最大道具数

#### BUFF系统
- `this._hasBuffAbs`: 是否支持BUFF
- `this._isInBuffState`: 是否处于BUFF中

#### 显示配置
- `this.enable99plus`: 道具数量是否启用"99+"显示

### 方法

#### UI初始化
- `initUI()`: 初始化UI
- `initProgressBar()`: 初始化进度条

#### 进度控制
- `setProgressWithoutAni()`: 无动画设置进度
- `updateProgressWithAni(callback)`: 带动画更新进度
- `playProgressBarAnimation(progress, time, callback)`: 进度条动画
- `_playProgressBarAnimation(progress, time, callback)`: 内部进度条动画逻辑

#### 状态管理
- `setState()`: 根据道具数量切换动画状态
- `onPostSpinUpdate(callback)`: Spin完成后更新进度与动画

#### 飞行动画
- `flyItemToEvent(data)`: 飞行动画到指定事件
- `flyItem(callback)`: 飞行动画

#### 任务完成
- `onTicketMax()`: 进度满时的回调（子类实现）

#### BUFF系统
- `onUpdateCountTime(event)`: 更新倒计时并更新BUFF状态
- `getBuffLeftTime()`: 获取BUFF剩余时间
- `updateBuffState()`: 更新BUFF状态UI
- `showBuffStartTips()`: BUFF开始提示（子类实现）
- `showBuffEndTips()`: BUFF结束提示（子类实现）

#### 时间显示
- `updateCountTime()`: 更新倒计时

#### 道具显示
- `setKeyCountLabel(propsCount)`: 设置道具数量文本（支持99+）

---

## 3. RechargeBonanzaWidgetController.js

### 功能
活动关卡入口控制器，继承自 [`ActivityBaseWidgetController`](#2-activitybasewidgetcontrollerjs)，实现了该活动特有的UI行为。

### 变量

#### UI节点
- `this._node_maxout`: 显示满奖励节点
- `this._node_spinning`: 自旋动画节点
- `this._progressBar`: 进度条节点
- `this._nodeBuff`: BUFF动画节点

#### 飞行道具
- `this.isNeedFlyProps`: 是否需要飞行道具动画
- `this._appearDelayTime`: 出现延迟时间

#### 道具系统
- `this.propsCount`: 当前获得道具数
- `this.MAX_PROPS_COUNT`: 最大道具数

#### BUFF系统
- `this._hasBuffAbs`: 是否有BUFF
- `this._isInBuffState`: 是否处于BUFF状态

#### 显示配置
- `this.enable99plus`: 道具数量是否显示"99+"

### 方法

#### 生命周期
- `onEnter()`: 注册消费购买刷新事件

#### UI管理
- `initUI()`: 初始化UI并刷新动画与红点状态
- `refreshAnimAndRed()`: 刷新动画状态和红点

#### 红点控制
- `showRedPoint(enabled)`: 显示/隐藏红点

#### 任务完成
- `onTicketMax()`: 进度条满时执行动作

#### 支付刷新
- `onRefreshWhenConsumePurchase()`: 支付完成后刷新UI

#### 交互处理
- `onWidgetClicked(sender)`: 小部件点击行为

#### 工厂方法
- `createFromCCB(activity, ccbPath)`: 从CCB创建控制器实例

## 使用指南

### ActivityWidgetController 使用场景

#### 基础小部件控制器
- **适用场景**: 所有活动关卡入口小部件的基类
- **核心功能**: 进度条管理、位置控制、动画系统、红点提示
- **继承关系**: 其他小部件控制器的父类

#### 关键特性
1. **进度条系统**: 支持多种进度条类型和动画
2. **位置适配**: 灵活的位置配置和适配
3. **整合入口**: 支持活动入口整合显示
4. **自动奖励**: 可配置的自动奖励领取
5. **下注提示**: 智能的下注提示系统
6. **红点管理**: 完整的红点状态管理

### ActivityBaseWidgetController 使用场景

#### 抽象基类
- **适用场景**: 具体活动小部件的直接父类
- **特色功能**: 道具收集、BUFF系统、飞行动画
- **继承优势**: 复用基础控制器功能

#### 实现特点
1. **道具系统**: 完整的道具收集和显示
2. **BUFF支持**: 时间相关的BUFF状态管理
3. **飞行动画**: 道具收集的视觉效果
4. **进度联动**: 进度条与道具数量的联动

### RechargeBonanzaWidgetController 使用场景

#### 具体活动实现
- **适用场景**: 充值狂欢活动的关卡入口
- **完整功能**: 展示完整的小部件实现
- **参考价值**: 其他活动小部件的开发参考

#### 实现亮点
1. **状态刷新**: 支付完成后的UI刷新
2. **红点控制**: 精确的红点显示控制
3. **动画集成**: 完整的动画状态管理
4. **事件处理**: 标准的点击和刷新事件

### 开发指导

#### 创建新的小部件控制器
```javascript
// 1. 继承基础抽象类
var NewActivityWidgetController = ActivityBaseWidgetController.extend({
    
    // 2. 定义UI节点
    _customProgressBar: null,
    _customButton: null,
    _customLabel: null,
    
    // 3. 配置基础属性
    isNeedFlyProps: true,
    enable99plus: true,
    MAX_PROPS_COUNT: 10,
    
    // 4. 重写初始化方法
    initUI: function() {
        this._super();
        this.initCustomElements();
        this.refreshAnimAndRed();
    },
    
    // 5. 初始化自定义元素
    initCustomElements: function() {
        this.setKeyCountLabel(this.propsCount);
    },
    
    // 6. 重写关键回调
    onTicketMax: function() {
        // 进度满时的处理
        this.showRedPoint(true);
    },
    
    // 7. 自定义点击处理
    onWidgetClicked: function(sender) {
        this.logEvent("custom_widget_click");
        // 自定义点击逻辑
    },
    
    // 8. 支付刷新处理
    onRefreshWhenConsumePurchase: function() {
        this.refreshAnimAndRed();
    }
});

// 工厂方法
NewActivityWidgetController.createFromCCB = function(activity, ccbPath) {
    return cc.BuilderReader.load(ccbPath, new NewActivityWidgetController(), activity);
};
```

#### 进度条配置示例
```javascript
// 水平进度条
this.progressBarCreator = {
    type: "horizontal",
    maxValue: 100,
    animationType: "smooth"
};

// 圆形进度条
this.progressBarCreator = {
    type: "circular",
    maxValue: 360,
    clockwise: true
};

// 垂直进度条
this.progressBarCreator = {
    type: "vertical",
    maxValue: 100,
    direction: "bottom-to-top"
};
```

#### BUFF系统使用
```javascript
// 检查BUFF状态
if (this._hasBuffAbs && this._isInBuffState) {
    var leftTime = this.getBuffLeftTime();
    if (leftTime > 0) {
        this.showBuffStartTips();
    } else {
        this.showBuffEndTips();
        this._isInBuffState = false;
    }
}
```

### 最佳实践

#### 性能优化
1. **进度更新**: 合理设置进度条更新频率
2. **动画控制**: 避免同时播放过多动画
3. **红点管理**: 及时更新红点状态，减少无效刷新
4. **资源清理**: 在onExit中清理所有定时器和动画

#### 用户体验
1. **响应速度**: 快速响应用户点击
2. **视觉反馈**: 提供清晰的状态变化反馈
3. **防误操作**: 合理的点击间隔控制
4. **状态一致**: 确保UI状态与数据状态同步

#### 常见问题解决
1. **进度条不更新**: 检查进度条创建器和数据绑定
2. **飞行动画异常**: 确认起止位置和动画参数
3. **红点显示错误**: 检查红点状态逻辑和刷新时机
4. **BUFF显示问题**: 确认BUFF时间计算和状态更新
5. **内存泄漏**: 正确清理事件监听器和定时任务

#### 调试技巧
```javascript
// 调试进度条状态
console.log("Progress:", this._progressBar.getProgress());
console.log("Props count:", this.propsCount);

// 调试BUFF状态
console.log("Has BUFF:", this._hasBuffAbs);
console.log("In BUFF state:", this._isInBuffState);
console.log("BUFF left time:", this.getBuffLeftTime());

// 调试红点状态
console.log("Has new message:", this.getHasNewMessage());
```

### 架构设计思路

#### 分层设计
1. **基础层**: [`ActivityWidgetController`](#1-activitywidgetcontrollerjs) - 通用UI控制
2. **抽象层**: [`ActivityBaseWidgetController`](#2-activitybasewidgetcontrollerjs) - 活动特有功能
3. **实现层**: [`RechargeBonanzaWidgetController`](#3-rechargebonanzawidgetcontrollerjs) - 具体活动逻辑

#### 功能模块化
- **进度系统**: 独立的进度条管理
- **道具系统**: 完整的收集和显示逻辑
- **BUFF系统**: 时间相关的状态管理
- **动画系统**: 统一的动画控制接口

#### 可扩展性
- **配置驱动**: 通过配置控制功能开关
- **事件驱动**: 基于事件的状态同步
- **模板方法**: 预留扩展点供子类实现

### 相关文件链接
- 基础控制器: [`ActivityWidgetController.js`](../src/activity/controller/ActivityWidgetController.js)
- 抽象基类: [`ActivityBaseWidgetController.js`](../src/activity/controller/ActivityBaseWidgetController.js)
- 示例实现: [`RechargeBonanzaWidgetController.js`](../src/activity/controller/RechargeBonanzaWidgetController.js)
- 活动基类: [`BaseActivity.js`](BaseActivity.js)
- 主界面控制器: [`ActivityMainUIController.js`](ActivityMainUIController.js)

此控制器体系为活动关卡入口提供了完整的解决方案，从基础的UI控制到复杂的业务逻辑，都有相应的抽象和实现。