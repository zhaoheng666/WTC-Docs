# Slots-SmartCCBController 文档

## 1. ActivityWidgetController.js

### 功能
ui控制器的基类，封装了常见的UI控制逻辑、事件监听、定时任务调度、弹窗动画回调等功能。

### 变量

#### 事件管理
- `this._eventHandlers`: 存储当前控制器注册的所有事件处理函数，用于统一管理添加和移除事件监听器

#### 定时任务
- `this._scheduleFunctions`: 保存所有通过schedule注册的定时任务函数，便于后续取消

#### 图层控制
- `this._maskLayer`: 遮罩层节点
- `this._clipLayer`: 被遮罩图层节点，配合doClipping方法实现裁剪显示效果

#### 回调函数
- `this.confirmCallback`: 确认按钮点击后的回调函数
- `this.closeCallback`: 关闭按钮点击后的回调函数

#### 按钮控制
- `this.buttons`: 需要统一控制启用/禁用状态的按钮列表

#### 裁剪设置
- `this.alphaThreshold`: 裁剪透明度阈值，用于判断是否显示内容

#### 动画配置
- `this.disabledAnim`: 按钮禁用状态下的动画名称
- `this.enabledAnim`: 按钮启用状态下的动画名称

#### 点击检测
- `this.lastCheckSeriesClickedTime`: 记录上一次点击时间，用于判断是否为连续点击
- `this.seriesClickIntervalTime`: 定义连续点击判定的时间间隔，默认为500ms
- `this.initStageClickIntervalTime`: 定义初始化阶段点击间隔时间，默认为500ms

#### 弹窗回调
- `this.popupCallback`: 弹窗加载完成后的回调函数，常用于恢复父级界面状态等
- `this.appearCallback`: 弹窗动画播放完毕后执行的回调函数

### 方法

#### 初始化与生命周期
- `initWith(slotScene, activityTag)`: 初始化绑定场景和活动标签
- `onEnter`: 进入场景时清空并初始化事件处理器和定时任务，如果有自动播放动画，则等待动画结束再执行popupCallback
- `onExit`: 退出场景时调用cleanUpListeners清理所有事件和定时器，执行popupCallback（如果存在）并置空
- `onDidLoadFromCCB`: ccb加载完成后调用，使用doClipping对遮罩层进行裁剪操作
- `close`: 调用父类close方法释放资源

#### 事件管理
- `addListener(eventName, handler, target, priority)`: 创建带作用域绑定的包装函数，并加入到_eventHandlers中
- `removeListener(eventName)`: 从_eventHandlers和全局事件派发器中删除该事件
- `dispatchEvent(eventName, userData)`: 使用全局事件派发器触发指定事件并传递用户数据
- `removeAllListeners`: 遍历_eventHandlers并逐个移除，同时移除NodeHelper.makeTouchable创建的触摸监听器
- `cleanUpListeners`: 调用removeAllListeners和unscheduleAllScheduleFunction

#### 定时任务管理
- `schedule(updateFunction, interval, repeat)`: 注册一个定时任务，使用唯一键标识任务
- `unschedule(updateFunction)`: 取消指定的定时任务
- `unscheduleAllScheduleFunction`: 取消所有定时任务

#### 按钮状态控制
- `setEnabled(enabled)`: 批量启用或禁用按钮
- `onAppear(enabled)`: 设置控件不可用状态
- `onAppearEnd(enabled)`: 设置控件可用状态

#### 回调管理
- `setAppearCallback(callback)`: 设置弹窗完全显现后的回调函数
- `setPopupCallback(callback)`: 设置弹窗弹出完成后的回调函数

#### 点击检测
- `checkIsSeriesClick(intervalTime)`: 判断是否为短时间内连续点击（默认500ms）
- `checkIsInitStageClick(intervalTime)`: 判断点击是否处于初始化阶段（默认500ms）

#### 弹窗控制
- `popupForceUnder(param)`: 强制将弹窗置于其他通用弹窗之下

#### 工厂方法
- `createFromCCB(ccbPath)`: 从CCB文件创建控制器实例

## 使用指南

### ActivityWidgetController 使用场景

#### 基础UI控制器
- **适用场景**: 所有UI控制器的基类
- **核心功能**: 事件管理、定时任务、按钮控制、弹窗管理
- **继承关系**: 其他UI控制器的父类

#### 关键特性
1. **事件管理**: 统一的事件监听器注册和清理机制
2. **定时任务**: 安全的定时任务调度和取消
3. **按钮控制**: 批量按钮状态管理和动画切换
4. **裁剪效果**: 遮罩层裁剪显示功能
5. **点击防护**: 连续点击和初始化阶段点击检测
6. **弹窗管理**: 完整的弹窗生命周期回调

### 核心功能详解

#### 事件管理系统
```javascript
// 添加事件监听
this.addListener("CUSTOM_EVENT", this.onCustomEvent, this);

// 派发事件
this.dispatchEvent("CUSTOM_EVENT", customData);

// 自动清理 - 在onExit时自动调用
this.cleanUpListeners();
```

#### 定时任务管理
```javascript
// 注册定时任务
this.schedule(this.updateFunction, 1.0, cc.REPEAT_FOREVER);

// 取消特定任务
this.unschedule(this.updateFunction);

// 取消所有任务 - 在onExit时自动调用
this.unscheduleAllScheduleFunction();
```

#### 按钮状态控制
```javascript
// 批量控制按钮状态
this.buttons = [btn1, btn2, btn3];
this.setEnabled(false); // 禁用所有按钮
this.setEnabled(true);  // 启用所有按钮
```

#### 点击检测机制
```javascript
// 检测连续点击
if (this.checkIsSeriesClick()) {
    return; // 忽略连续点击
}

// 检测初始化阶段点击
if (this.checkIsInitStageClick()) {
    return; // 忽略初始化阶段点击
}
```

### 开发指导

#### 创建自定义控制器
```javascript
var CustomController = ActivityWidgetController.extend({
    
    // 1. 定义自定义变量
    _customButton: null,
    _customLabel: null,
    
    // 2. 重写生命周期方法
    onEnter: function() {
        this._super();
        this.initCustomUI();
        this.registerCustomEvents();
    },
    
    // 3. 初始化自定义UI
    initCustomUI: function() {
        // 设置按钮列表
        this.buttons = [this._customButton];
        
        // 设置回调
        this.setPopupCallback(this.onPopupComplete.bind(this));
    },
    
    // 4. 注册自定义事件
    registerCustomEvents: function() {
        this.addListener("CUSTOM_UPDATE", this.onCustomUpdate, this);
        this.schedule(this.updateCustomData, 2.0, cc.REPEAT_FOREVER);
    },
    
    // 5. 自定义事件处理
    onCustomUpdate: function(event) {
        if (!this.validateEvent(event)) return;
        // 处理自定义更新
    },
    
    // 6. 定时更新函数
    updateCustomData: function() {
        // 定时更新逻辑
    },
    
    // 7. 按钮点击处理
    onCustomButtonClicked: function(sender) {
        // 防连击检测
        if (this.checkIsSeriesClick()) return;
        
        // 处理点击逻辑
        this.dispatchEvent("BUTTON_CLICKED", {sender: sender});
    },
    
    // 8. 弹窗完成回调
    onPopupComplete: function() {
        // 弹窗显示完成后的逻辑
    }
});

// 工厂方法
CustomController.createFromCCB = function(ccbPath) {
    return cc.BuilderReader.load(ccbPath, new CustomController());
};
```

### 最佳实践

#### 资源管理
1. **事件清理**: 依赖基类自动清理，无需手动处理
2. **定时任务**: 自动取消所有注册的定时任务
3. **按钮状态**: 合理设置buttons数组进行批量管理
4. **回调清理**: 基类会自动清理popupCallback

#### 性能优化
1. **事件过滤**: 使用validateEvent过滤无效事件
2. **连击防护**: 使用checkIsSeriesClick防止误操作
3. **定时任务**: 合理设置更新间隔，避免过于频繁
4. **内存管理**: 依赖基类的自动清理机制

#### 常见问题解决
1. **事件未触发**: 检查事件名称和监听器注册
2. **定时任务异常**: 确认任务函数的作用域绑定
3. **按钮状态错误**: 检查buttons数组的设置
4. **内存泄漏**: 确保继承了基类的onExit方法
5. **弹窗异常**: 正确设置和清理弹窗回调

#### 调试技巧
```javascript
// 调试事件监听器
console.log("Registered events:", Object.keys(this._eventHandlers));

// 调试定时任务
console.log("Active schedules:", Object.keys(this._scheduleFunctions));

// 调试按钮状态
console.log("Buttons enabled:", this.buttons.map(btn => btn.isEnabled()));
```

### 架构设计原理

#### 统一资源管理
- **设计目标**: 避免内存泄漏和资源未清理
- **实现方式**: 统一的事件和定时任务管理
- **生命周期**: 自动在onExit时清理所有资源

#### 防误操作机制
- **连击检测**: 防止用户快速连续点击造成的问题
- **状态管理**: 统一的按钮启用/禁用控制
- **初始化保护**: 防止界面初始化期间的误操作

#### 可扩展性设计
- **事件系统**: 灵活的自定义事件支持
- **回调机制**: 多层级的回调函数支持
- **工厂模式**: 标准的控制器创建方式

### 相关文件链接
- 基类实现: [`ActivityWidgetController.js`](../src/activity/controller/ActivityWidgetController.js)
- 使用示例: [`ActivityBaseWidgetController.js`](ActivityBaseWidgetController.js)
- 相关控制器: [`ActivityMainUIController.js`](ActivityMainUIController.js)
- 活动基类: [`BaseActivity.js`](BaseActivity.js)

此基类为整个UI控制器体系提供了坚实的基础，通过统一的资源管理和事件处理，大大简化了UI控制器的开发和维护工作。