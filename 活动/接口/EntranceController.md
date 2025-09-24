# Slots-EntranceController 文档

## 1. ActivityEntranceController.js

### 功能
活动大厅入口控制器基类，用于控制大厅或场景中的活动入口UI行为，包括倒计时、红点提示、点击事件、位置适配等。

### 变量

#### 核心绑定
- `this._activity` / `_activityId`: 绑定的Activity实例和ID

#### 时间控制
- `this.redLessThanTime`: 倒计时小于该时间后文本变红（单位毫秒）

#### 特效与提示
- `this.smokeScript`: 烟雾特效脚本
- `this.hasNewMessage`: 是否显示小红点提示

#### 显示配置
- `this.enable99plus`: 道具数量是否启用"99+"显示

### 方法

#### 初始化与生命周期
- `initWith(activityId)`: 初始化绑定活动ID和对应Activity
- `onEnter()`: 节点进入场景时注册事件监听器并初始化倒计时与红点状态
- `onExit()`: 清除事件监听器

#### 红点系统
- `handleRedPointEvent(event)`: 处理红点刷新事件
- `initRedPoint()`: 初始化红点状态，根据`_activity`判断是否显示红点
- `setHasNewMessage(hasNewMessage)`: 设置红点状态并广播变化
- `getHasNewMessage()`: 获取当前红点状态

#### 事件处理
- `onActivityEnd(event)`: 活动结束时移除入口节点
- `onEntranceClicked(sender)`: 入口点击事件，弹出主界面并记录日志
- `onActivityIdChanged(event)`: 活动ID变更时更新

#### 时间显示
- `updateCountTime(event)`: 接收更新倒计时事件
- `_updateCountTime()`: 更新倒计时显示文本

#### 位置适配
- `setPositionIphoneX(posX, posY)`: iPhone X适配特殊处理
- `onMoveMainAttachNode()`: 主要挂点位置偏移控制
- `onMoveBottomLeftAttachNode()`: 左下挂点位置偏移控制
- `onMoveTopRightAttachNode()`: 右上挂点位置偏移控制

#### 特效管理
- `attachSmokeScriptAfterEnter()`: 进入时附加烟雾特效
- `detachSmokeScriptAfterExit()`: 退出时移除烟雾特效
- `resetParticlePositionType()`: 重置粒子系统定位方式（防止乱飘）

#### 特殊适配
- `needPositionNewActivityDh()`: 特殊活动偏移判断（DH主题）

#### 工厂方法
- `createFromCCB(filePath, activityId)`: 从CCB创建控制器实例

---

## 2. RechargeBonanzaEntranceController.js

### 功能
活动大厅入口控制器，继承自 [`ActivityEntranceController`](#1-activityentrancecontrollerjs)，实现了该活动特有的入口行为。

### 变量

#### 时间显示
- `this._leftTimeLabel`: 倒计时标签
- `redLessThanTime`: 红色提醒阈值

#### 音效配置
- `this.btnClickSound`: 按钮音效
- `autoPlayBgm`: 自动播放音乐
- `isUpdateCountTime`: 倒计时标志

#### 显示控制
- `this.enable99plus`: 启用道具数量"99+"显示
- `this._lbPropCount`: 显示道具数量的标签
- `this._redPointNode`: 红点节点

### 方法

#### 生命周期
- `onEnter()`: 注册支付完成刷新事件，并调用父类onEnter

#### 支付刷新
- `onRefreshWhenConsumePurchase()`: 支付完成后刷新红点状态

#### 红点管理
- `initRedPoint(event)`: 根据任务是否有奖励设置红点和道具数量显示

#### 事件处理
- `onEntranceClicked(sender)`: 入口点击事件，记录日志并调用父类点击逻辑

#### 工厂方法
- `createFromCCB(filePath, activityId)`: 从CCB创建控制器实例

## 使用指南

### ActivityEntranceController 使用场景

#### 基础入口控制器
- **适用场景**: 所有活动的大厅入口基类
- **核心功能**: 倒计时显示、红点提示、点击处理
- **继承关系**: 其他具体活动入口控制器的父类

#### 关键特性
1. **自动倒计时**: 支持倒计时显示和红色警告
2. **红点系统**: 自动管理红点状态和事件响应
3. **位置适配**: 支持不同设备和挂点的位置调整
4. **特效支持**: 集成烟雾特效和粒子系统
5. **事件管理**: 完整的生命周期和事件处理

### RechargeBonanzaEntranceController 使用场景

#### 具体活动实现
- **适用场景**: 充值狂欢活动的大厅入口
- **特色功能**: 道具数量显示、支付刷新
- **继承优势**: 复用基类的所有功能

#### 实现特点
1. **道具计数**: 显示当前获得的道具数量
2. **支付联动**: 支付完成后自动刷新状态
3. **99+显示**: 支持大数量的友好显示
4. **音效集成**: 自定义点击音效

### 开发指导

#### 创建新的入口控制器
```javascript
// 1. 继承基类
var NewActivityEntranceController = ActivityEntranceController.extend({
    
    // 2. 定义特有变量
    customProperty: null,
    
    // 3. 重写必要方法
    onEnter: function() {
        this._super();
        // 添加特有的初始化逻辑
    },
    
    // 4. 实现特有功能
    initRedPoint: function() {
        // 自定义红点逻辑
    }
});

// 5. 注册工厂方法
NewActivityEntranceController.createFromCCB = function(filePath, activityId) {
    return cc.BuilderReader.load(filePath, new NewActivityEntranceController(), activityId);
};
```

#### 最佳实践
1. **继承复用**: 优先继承基类，复用通用功能
2. **事件管理**: 正确注册和清理事件监听器
3. **红点状态**: 及时更新红点状态，提升用户体验
4. **位置适配**: 考虑不同设备的显示效果
5. **资源清理**: 在onExit中正确清理资源

#### 常见问题
1. **倒计时不更新**: 检查`isUpdateCountTime`标志和事件注册
2. **红点不显示**: 确认`hasNewMessage`状态和相关活动数据
3. **位置偏移**: 使用合适的位置适配方法
4. **特效异常**: 正确管理粒子系统的生命周期
5. **内存泄漏**: 确保在onExit中清理所有监听器

### 相关文件链接
- 基类实现: [`ActivityEntranceController.js`](../src/activity/controller/ActivityEntranceController.js)
- 示例实现: [`RechargeBonanzaEntranceController.js`](../src/activity/controller/RechargeBonanzaEntranceController.js)
- 活动基类: [`BaseActivity.js`](BaseActivity.js)
- UI控制器: [`ActivityMainUIController.js`](ActivityMainUIController.js)