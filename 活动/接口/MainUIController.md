# Slots-MainUIController 文档

## 1. ActivityBaseController.js

### 功能
活动UI控制器基类，提供通用的UI控制逻辑，如音乐播放、倒计时更新、按钮点击处理等。

### 变量

#### 核心绑定
- `this._activity`: 绑定的Activity实例

#### 回调函数
- `this.confirmCallback`: 确认回调函数
- `this.closeCallback`: 关闭回调函数

#### 界面控制
- `this.doNotAutoClose`: 是否自动关闭界面（用于弹窗控制）

#### 音效配置
- `this.btnClickSound`: 按钮点击音效路径
- `this.autoPlayBgm`: 自动播放背景音乐路径

#### 特效系统
- `this.smokeScript`: 烟雾特效脚本

#### 功能开关
- `this.isUpdateCountTime`: 是否启用倒计时更新
- `this.isDisableActivityEndListen`: 是否禁用活动结束监听

### 方法

#### 生命周期管理
- `onEnter()`: 节点进入场景时初始化事件监听、UI、播放音乐、倒计时
- `onExit()`: 节点退出场景时清理资源、停止音乐
- `initUI()`: 初始化UI（子类实现）

#### 音乐控制
- `playMusic(path)`: 播放指定路径的背景音乐
- `_playMusic()`: 内部播放音乐方法
- `stopMusic()`: 停止播放音乐并恢复上一个背景音乐

#### 事件处理
- `onCloseClicked(sender)`: 关闭按钮点击处理
- `onConfirmClicked(sender)`: 确认按钮点击处理
- `onCollectClicked(sender)`: 收集按钮点击处理
- `onActivityEnd(event)`: 监听活动结束事件并关闭界面
- `onNetworkError()`: 网络断开时关闭界面

#### 音效管理
- `playBtnClickSound()`: 播放按钮点击音效

#### 事件验证与日志
- `validateEvent(event)`: 验证事件是否属于当前活动
- `logEvent(eventName, args)`: 记录UI点击日志

#### 数据获取
- `getActivityId()`: 获取绑定活动ID
- `getActivity()`: 获取绑定活动实例

#### 状态更新
- `onActivityIdChanged(event)`: 活动ID变化时更新控制器中的ID
- `onUpdateCountTime(event)`: 更新倒计时
- `updateCountTime()`: 格式化显示剩余时间并变红提醒

#### 控制器管理
- `onCloseControllerByName(event)`: 根据控制器名称关闭界面

#### 特效管理
- `attachSmokeScriptAfterEnter()`: 进入时附加烟雾特效
- `detachSmokeScriptAfterExit()`: 退出时移除烟雾特效

#### 状态查询
- `isBtnCloseEnabled()`: 判断关闭按钮是否可用

#### 工厂方法
- `createFromCCB(filePath, activity)`: 从CCB文件创建控制器节点

---

## 2. ActivityMainUIController.js

### 功能
活动主界面控制器基类，继承自 [`ActivityBaseController`](#1-activitybasecontrollerjs)，提供基础的主界面交互逻辑，如帮助按钮、日志记录、FAQ页面跳转等。

### 变量

#### 触发信息
- `this.triggerType`: 触发类型（如登录、大厅点击等）

#### FAQ配置
- `this.isFaqOnePage`: 是否单页FAQ

#### 音乐控制
- `this.isBgmAutoPlay`: 是否自动播放背景音乐

#### 日志与音效
- `this._closeLogStr`: 关闭日志字符串
- `this._faqAudio`: FAQ音效

### 方法

#### 生命周期
- `onEnter()`: 入场时播放音乐
- `onExit()`: 退场时停止音乐

#### 事件处理
- `onCloseClicked(sender)`: 关闭按钮点击处理并记录日志
- `onNetworkError()`: 网络错误时关闭界面

#### 日志记录
- `logAccept(arg1)`: 接受操作日志记录
- `logHelp()`: 帮助按钮日志记录
- `logBack()`: 返回操作日志记录

#### FAQ功能
- `onFaqClicked(sender)`: FAQ按钮点击处理，弹出帮助页面

---

## 3. RechargeBonanzaMainUIController.js

### 功能
活动主界面控制器，继承自 [`ActivityMainUIController`](#2-activitymainuicontrollerjs)，实现了任务列表展示、奖励领取流程、倒计时等功能。

### 变量

#### 时间显示
- `this._lbLeftTime`: 倒计时标签
- `redLessThanTime`: 红色提醒阈值

#### 音乐与更新
- `this.autoPlayBgm`: 自动播放音乐
- `isUpdateCountTime`: 倒计时标志

#### 兑换信息
- `this._lbExchangeMoney`: 显示兑换率的文本（金币）
- `this._lbExchangePoint`: 显示兑换率的文本（积分）

#### 滚动视图
- `this._ndContainerMask`: 滚动视图容器遮罩
- `this._spScrollBar`: 滚动条精灵
- `this._spScrollBarBg`: 滚动条背景

#### 奖励面板
- `this._ccbFinalReward`: 最终奖励面板

#### 布局常量
- `ITEM_WIDTH`: 任务项宽度
- `ITEM_HEIGHT`: 任务项高度  
- `FIRST_ITEM_OFFSET_X`: 第一个任务项X偏移

### 方法

#### 生命周期
- `onDidLoadFromCCB()`: CCB加载完成后调用
- `onEnter()`: 注册消费购买刷新事件，播放打开音效
- `onExit()`: 清理资源

#### UI初始化
- `initUI()`: 初始化折扣UI和任务列表UI
- `refreshUI()`: 刷新UI（子类可重写）
- `initGuide()`: 初始化引导（子类可重写）
- `initTitle()`: 初始化标题（子类可重写）

#### 折扣UI
- `initDiscountUI()`: 设置兑换率文本

#### 任务列表
- `initTaskTableViewUI()`: 初始化水平滚动的任务列表
- `resetList()`: 重新加载任务列表
- `scrollToIndex(index, callback)`: 滚动到指定索引位置

#### 滚动条
- `initScrollBar()`: 初始化滚动条
- `scrollViewDidScroll()`: 滚动视图滚动时更新滚动条位置

#### TableView回调
- `tableCellSizeForIndex(table, index)`: 返回单元格大小
- `tableCellAtIndex(table, index)`: 创建并绑定单元格数据
- `numberOfCellsInTableView(table)`: 返回单元格数量

#### 支付刷新
- `refreshOnConsumePurchase(event)`: 接收支付完成事件并刷新UI

#### 交互处理
- `onCliameOpos()`: 处理领取奖励后的关闭操作
- `onCloseClicked(sender)`: 关闭按钮点击处理，防快速重复点击

#### 奖励收集流程
- `doCollectFlow(point, index, ressultData)`: 执行领取奖励动画流程
- `requestCollectReward(point, index)`: 请求领取奖励，触发流程

#### 动画序列
- `doTableViewMoveToLeftSide(callBack, index)`: 将任务列表向左滚动
- `doTaskItemButtonFinishAnim(callBack, index)`: 按钮领取动画
- `doTaskItemFinishAnim(callBack, index)`: 任务领取动画
- `doTaskItemDisappearAnim(callBack, index)`: 任务消失动画

#### 奖励弹窗
- `showCollectPointReward(callBack, resultData)`: 弹出收集奖励面板

#### 最终奖励
- `doFinalRewardGetAnim(callBack)`: 最终奖励获取动画
- `doFinalRewardCollectAnim(callBack, resultData)`: 最终奖励领取动画
- `showCollectFinalReward(callBack, resultData)`: 弹出最终奖励领取结果
- `doFinalRewardCollectDoneAnim(callBack, resultData)`: 最终奖励领取完成动画

#### 状态检查
- `checkIsActivityEnd(callBack, resultData)`: 检查是否活动已结束

#### UI管理
- `delMaskLayer()`: 删除遮罩层
- `refreshWidgetUI()`: 刷新小部件UI

#### 时间更新
- `updateCountTime()`: 更新倒计时显示

#### 工厂方法
- `createFromCCB(activity)`: 从CCB创建主界面控制器

## 使用指南

### ActivityBaseController 使用场景

#### 基础控制器
- **适用场景**: 所有活动UI控制器的基类
- **核心功能**: 音乐播放、事件管理、倒计时、特效
- **继承关系**: 其他UI控制器的父类

#### 关键特性
1. **音乐管理**: 自动播放和停止背景音乐
2. **事件系统**: 完整的事件监听和清理
3. **倒计时显示**: 自动更新和红色警告
4. **特效集成**: 烟雾特效支持
5. **日志记录**: 统一的UI点击日志

### ActivityMainUIController 使用场景

#### 主界面基类
- **适用场景**: 活动主界面控制器的基类
- **特色功能**: FAQ系统、日志记录
- **继承优势**: 复用基础控制器功能

#### 实现特点
1. **FAQ集成**: 支持单页和多页FAQ
2. **日志系统**: 标准化的操作日志
3. **音乐控制**: 主界面音乐管理
4. **网络处理**: 网络错误自动处理

### RechargeBonanzaMainUIController 使用场景

#### 具体活动实现
- **适用场景**: 充值狂欢活动的主界面
- **复杂功能**: 任务列表、动画流程、奖励系统
- **完整示例**: 展示如何实现复杂的活动UI

#### 实现亮点
1. **任务列表**: 水平滚动的任务展示
2. **动画流程**: 完整的奖励领取动画序列
3. **滚动条**: 自定义滚动条实现
4. **折扣显示**: 兑换率信息展示
5. **状态管理**: 复杂的UI状态控制

### 开发指导

#### 创建新的主界面控制器
```javascript
// 1. 继承合适的基类
var NewActivityMainUIController = ActivityMainUIController.extend({
    
    // 2. 定义UI元素
    _customLabel: null,
    _customButton: null,
    
    // 3. 重写初始化方法
    initUI: function() {
        this._super();
        // 自定义UI初始化
        this.initCustomElements();
    },
    
    // 4. 实现自定义功能
    initCustomElements: function() {
        // 初始化自定义元素
    },
    
    // 5. 处理自定义事件
    onCustomButtonClicked: function(sender) {
        this.playBtnClickSound();
        // 自定义点击逻辑
    }
});
```

#### 最佳实践
1. **继承层次**: 选择合适的基类进行继承
2. **资源管理**: 在onExit中正确清理所有资源
3. **事件处理**: 使用validateEvent验证事件有效性
4. **音乐控制**: 合理使用音乐播放和停止
5. **动画管理**: 确保动画序列的正确执行和清理

#### 常见问题解决
1. **倒计时不更新**: 检查`isUpdateCountTime`和事件注册
2. **音乐播放异常**: 确认音乐文件路径和播放时机
3. **内存泄漏**: 在onExit中清理所有监听器和定时器
4. **动画卡顿**: 优化动画序列和回调处理
5. **UI刷新问题**: 正确使用刷新事件和状态管理

### 动画流程设计

#### 奖励领取流程示例
```javascript
// 完整的奖励领取动画流程
doCollectFlow: function(point, index, resultData) {
    var self = this;
    
    // 1. 移动任务列表
    this.doTableViewMoveToLeftSide(function() {
        
        // 2. 按钮动画
        self.doTaskItemButtonFinishAnim(function() {
            
            // 3. 任务完成动画
            self.doTaskItemFinishAnim(function() {
                
                // 4. 显示奖励
                self.showCollectPointReward(function() {
                    
                    // 5. 任务消失动画
                    self.doTaskItemDisappearAnim(function() {
                        
                        // 6. 检查是否完成
                        self.checkIsActivityEnd(null, resultData);
                        
                    }, index);
                }, resultData);
            }, index);
        }, index);
    }, index);
}
```

### 相关文件链接
- 基础控制器: [`ActivityBaseController.js`](../src/activity/controller/ActivityBaseController.js)
- 主界面基类: [`ActivityMainUIController.js`](../src/activity/controller/ActivityMainUIController.js)
- 示例实现: [`RechargeBonanzaMainUIController.js`](../src/activity/controller/RechargeBonanzaMainUIController.js)
- 活动基类: [`BaseActivity.js`](BaseActivity.js)
- 入口控制器: [`ActivityEntranceController.js`](ActivityEntranceController.js)