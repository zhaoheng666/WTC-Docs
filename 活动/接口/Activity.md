# Slots-Activity 文档

## 1. Activity.js

### 功能
活动基类，定义了通用的活动结构与逻辑。

### 变量

#### 任务相关
- `taskGroupsMap` / `taskGroupsArray`: 存储任务组对象，按ID映射或数组存储
- `runningTaskGroupId` / `nextTaskGroupId`: 当前运行的任务组ID和下一个任务组ID

#### 活动基础信息
- `activityId` / `activityName`: 活动ID和名称
- `endTime`: 活动结束时间戳
- `isFinish`: 活动是否完成
- `isStay`: 是否为常驻活动

#### 奖励系统
- `rewards`: 奖励集合（如金币、道具等）
- `rewardClaimed` / `rewardClaimStatus`: 是否已领取奖励，以及领取状态
- `claimType`: 领取奖励的方式（手动/自动）

#### 界面控制
- `callbackStack`: 回调栈计数器，用于防止多次触发回调
- `entranceAttachPointPriority`: 入口挂点优先级
- `setIndicatorTransparentWhenRequest`: 请求时加载圈透明设置

#### 特殊设置
- `specialActivityType`: 特殊活动类型标识

### 方法

#### 活动生命周期管理
- `initActivity(activityConfig)`: 初始化活动数据，包括任务组、奖励、时间等
- `startActivity()`: 启动活动
- `endActivity()`: 结束活动  
- `cleanActivity()`: 清理活动
- `isOpen()`: 判断活动是否处于开放状态
- `getLeftTime()`: 获取剩余时间

#### 定时任务控制
- `stopScheduleActivity()`: 停止定时更新活动状态
- `scheduleActivity()`: 启动定时更新活动状态
- `update()`: 定时执行的活动更新逻辑，如派发事件、停止过期活动

#### 任务组管理
- `isActivityComplete()`: 检查所有任务组是否完成
- `getTaskGroupById(taskGroupId)`: 根据ID获取任务组
- `getAllTaskGroup()`: 获取所有任务组
- `getRunningTaskGroupId()`: 获取当前运行的任务组ID
- `getRunningTaskGroupIndex()`: 获取当前任务组索引
- `getCurrentActivityStage()`: 获取当前活动阶段
- `getTotalTaskGroupNum()`: 获取任务组总数

#### 任务管理
- `getTaskById(taskGroupId, taskId)`: 根据ID获取具体任务
- `getTaskByIndex(taskGroupIndex, taskIndex)`: 根据索引获取具体任务
- `syncTask(syncData)`: 同步任务数据（如进度、奖励状态）

#### 奖励系统
- `onClaimReward(claimReward)`: 处理奖励领取后的逻辑（如任务组状态更新）
- `onClaimActivityReward(claimReward)`: 处理整个活动奖励的领取
- `claimActivityReward()`: 发送领取奖励请求
- `getActivityReward()`: 获取活动奖励
- `getRewardsByType(type)`: 根据类型获取奖励相关数据
- `haveRewardNeedToClaim()`: 检查是否有未领取的奖励
- `isAllTaskGroupRewardClaimed()`: 所有任务组奖励是否都已领取
- `isRewardClaimComplete()`: 检查奖励是否全部领取完毕

#### 任务奖励处理
- `onTaskRewardClaimedComplete(event)`: 任务奖励领取完成后处理逻辑（如开启下一任务组）
- `setTaskGroupStatusFromActivity()`: 设置任务组状态为已完成
- `onCompleteActivity()`: 活动完成后的回调

#### 界面创建
- `createActivityEntrance(parentNode)`: 创建大厅入口节点
- `createActivityEntranceForShop(parentNode)`: 创建商城入口

#### 自旋相关
- `preSpinUpdateActivity(callBack)`: 自旋前更新操作
- `postSpinUpdateActivity(callBack)`: 自旋后更新操作

#### 商城相关
- `getStoreExtraAttachment`: 获取商城额外附件
- `createDiscountExtraAttachment`: 创建折扣额外附件
- `createStoreExtraAttachmentPurchaseResultUI`: 创建商城额外附件购买结果UI

#### 资源管理
- `validAssets()`: 验证资源是否存在
- `getAssetPath2Valid()`: 获取需要验证的资源路径

#### 音频管理
- `playAudioEffect(effect, loop)`: 播放音效
- `stopAudioEffect(effect)`: 停止音效
- `playBackgroundMusic(effect)`: 播放背景音乐

#### 事件处理
- `validateEvent(event)`: 验证事件是否属于当前活动
- `onNotice(noticeType, customData, callback)`: 处理通知消息
- `updateJackpotValue(s2cOtherWinJackpot)`: 更新奖池数值

#### 数据请求
- `requestNewActivity()`: 请求新活动数据
- `startRequestNewActivityRound()`: 开始请求新活动轮次

#### 本地存储（不推荐使用）
- `getStorageItem(key, defaultValue)`: 获取本地缓存数据
- `setStorageItem(key, value)`: 设置本地缓存数据
- `removeStorageItem(key)`: 删除本地缓存数据

#### 缓存存储
- `getStorageCacheItem(key, defaultValue)`: 获取带缓存的本地存储
- `setStorageCacheItem(key, value)`: 设置带缓存的本地存储
- `removeStorageCacheItem(key)`: 删除带缓存的本地存储

#### 便捷方法
- `getRunningTaskGroup()`: 获取当前运行的任务组
- `getRunningTasks()`: 获取当前运行的任务列表
- `getRunningTask(taskIndex)`: 获取指定索引的当前任务
- `getTaskProgressSafe(taskIndex)`: 获取任务进度
- `getRunningTaskSubjects(taskIndex)`: 获取任务主题
- `hasTaskRewardsToClaim(taskIndex)`: 检查指定任务是否有可领取奖励
- `checkAndClaimTaskReward(taskIndex)`: 检查并领取任务奖励
- `getTaskGroupReward(rewardType)`: 获取任务组奖励
- `getTaskReward(rewardType)`: 获取任务奖励
- `getTaskDescription(taskIndex)`: 获取任务描述

#### 活动配置
- `changeActivityId(newActivityId)`: 更改活动ID
- `getIsStay(isPosterFilter)`: 判断是否是常驻活动

#### 数据刷新
- `refreshActivityData(callback, openMainUI, triggerType, blockIndicator)`: 刷新活动数据
- `pullLeaderBoardData(callback, blockIndicator, param1)`: 获取排行榜数据

---

## 2. BaseActivity.js

### 功能
基础活动类，提供通用功能，如入口控制、UI管理、支付逻辑等。

### 变量

#### UI节点
- `_mainUI`: 主UI节点
- `_progressBar`: 进度条节点
- `_indicator`: 指示器节点
- `_entranceNode`: 入口节点

#### 基础配置
- `themeName`: 主题名称
- `stopTime`: 停止时间
- `activityTag`: 活动标签

#### 音频控制
- `playingBgmCount`: 正在播放的背景音乐数量
- `backgroundMusicPath`: 背景音乐路径

#### 界面控制
- `posterPopupFrozenTime`: 海报弹出冷却时间
- `isShowPoster`: 是否显示海报
- `isShowEntrance`: 是否显示入口
- `isShowEndNotice`: 是否显示结束通知

#### 支付相关
- `isOpenPurchase`: 是否开启支付
- `isShowDealBtn`: 是否显示商城按钮
- `productId`: 商品ID
- `funcType`: 功能类型

#### 控制器
- `MainUIController`: 主界面控制器
- `WidgetController`: 小部件控制器
- `EntranceController`: 入口控制器
- `PayResultController`: 支付结果控制器

#### 其他设置
- `isCleanGuide`: 是否清除引导
- `isSettleBillWhenEnd`: 是否结算账单
- `popupHighLightPriority`: 弹窗优先级
- `lastPopupBuffTime`: 上次弹窗时间

#### 保护时间
- `isOpenEndTimeProtect`: 是否开启结束时间保护
- `protectTimeSec`: 保护时间秒数
- `isInProtectedTime`: 是否在保护时间内

#### 角标显示
- `showFlagStoneTag`: 显示角标标签
- `_flagStoneTagOrder`: 角标顺序

#### 新手活动
- `isNewUserActivity`: 是否为新手活动（用于差异化逻辑，如屏蔽排行榜等功能）

### 方法

#### 活动生命周期
- `initActivity(activityConfig)`: 初始化活动数据
- `startActivity()`: 注册支付、商城按钮等监听器
- `endActivity()`: 活动结束逻辑
- `cleanActivity()`: 清理活动资源
- `requestNewActivity()`: 请求新活动数据

#### 界面管理
- `popupActivityPoster(args)`: 弹出活动海报
- `popupActivityMainUI(triggerType, args)`: 弹出主界面
- `mountSlotSceneExtraUI(slotScene)`: 挂载额外UI
- `createActivityEntrance(parentNode)`: 创建大厅入口
- `popupActivityEndUI()`: 弹出结束界面

#### 资源路径
- `getFullPathOfCCB(ccbName)`: 获取CCB完整路径
- `getThemePathOfCCB(ccbName)`: 获取主题CCB路径

#### 引导系统
- `initGuide()`: 初始化引导记录
- `cleanGuide()`: 清除引导记录

#### 事件系统
- `registerNotice(noticeType, callback, target)`: 注册通知监听
- `onNotice(noticeType, customData, callback)`: 处理通知

#### 音乐控制
- `playMusic(backgroundMusicPath)`: 播放背景音乐
- `stopMusic()`: 停止音乐
- `pauseMusic()`: 暂停音乐
- `resumeMusic()`: 恢复音乐

#### 支付系统
- `buyProduct(source)`: 单个商品支付
- `buyMultiProduct(productId, funcType, source)`: 多商品支付
- `getProductInfo(productId)`: 获取商品信息
- `onVerifyPurchase(customData, callback)`: 支付验证
- `checkActivityConsume(proto, callback, consumeLogicCallback)`: 支付消耗处理
- `onPurchaseResult(customData, callback)`: 支付结果处理

#### 购买面板
- `popupBuyPanel(ccbFile, argInfo)`: 弹出购买面板
- `handleBuyPanelController(nodeController)`: 自定义购买面板逻辑

#### 商城相关
- `onDealUpdate(commonTitle, callback)`: 商城按钮更新

#### 对话框
- `showNextRoundDialog()`: 弹出再来一轮提示
- `isHideCardPackCheckOut()`: 是否隐藏结算按钮

#### 主题判断
- `isInThemeStyle(args)`: 判断是否在指定主题中

#### 时间管理
- `getLeftTime()`: 获取剩余时间（考虑保护时间）
- `update()`: 活动更新逻辑

#### 随机宝箱
- `setCommonRandomBoxData(activityData)`: 设置随机宝箱数据
- `addNewCommonRandomBox(chestInfo)`: 添加新的宝箱
- `getCommonRandomBoxData()`: 获取宝箱数据
- `getExtraRandomBoxData()`: 获取额外宝箱数据
- `clearExtraRandomBox()`: 清除额外宝箱
- `isCommonRandomBoxGuide()`: 判断宝箱引导
- `setCommonRandomBoxGuide()`: 设置宝箱引导

---

## 3. RechargeBonanzaActivity.js

### 功能
继承自 [`BaseActivity`](/../活动/接口/BaseActivity.js)，实现充值狂欢活动逻辑。

### 变量

#### 活动标识
- `activityTag`: 活动标签（`RECHARGE_BONANZA_ACTIVITY`）

#### 控制器
- `EntranceController`: 入口控制器
- `WidgetController`: 小部件控制器  
- `MainUIController`: 主界面控制器

#### 时间控制
- `redLessThanTime`: 倒计时变红的时间阈值

#### 功能开关
- `isOpenPurchase`: 是否允许购买
- `isShowEndNotice`: 是否显示结束通知

#### 保护机制
- `isOpenEndTimeProtect`: 是否启用保护时间
- `protectTimeSec`: 保护时间长度

#### 状态标识
- `isInCollectFlow`: 是否在收集流程中
- `isHaveActivityData`: 是否有活动数据

### 方法

#### 初始化
- `initActivity(activityConfig)`: 初始化活动数据，并创建数据管理模块

#### 数据获取
- `getActivityData()`: 获取活动数据管理器
- `getActivityUIMng()`: 获取活动UI管理器

#### 生命周期
- `startActivity(args)`: 注册通知监听器
- `cleanActivity()`: 清理活动资源并取消通知注册

#### UI附加
- `createExtraAttachment(attachNode, type, controller)`: 创建附加UI
- `attachStoreAttachment(attachNode, type)`: 绑定商店界面元素

#### 数据处理
- `getPropsCount()`: 获取道具数量
- `getTaskProgressSafe()`: 获取任务进度
- `customPostSpinUpdateActivity(callback)`: 自定义自旋后更新逻辑
- `syncTask(syncData)`: 同步任务数据

#### 支付处理
- `isContainFuncType(customData)`: 判断支付类型是否匹配
- `initProductData()`: 初始化商品数据
- `onVerifyPurchase(customData, callback)`: 支付验证处理
- `onPurchaseResult(customData, callback)`: 支付结果处理
- `onConsumePurchase(proto, callback)`: 支付消费逻辑

#### 界面控制
- `shouldPopupMain(triggerType, args)`: 判断是否应弹出主界面
- `popupActivityMainUI(triggerType, args)`: 弹出主界面
- `popupActivityEndUI()`: 弹出结束界面

#### 状态更新
- `update()`: 活动更新逻辑
- `hasRewardToClaim()`: 检查是否有可领取奖励
- `isAllTaskFinishedAndClaim()`: 是否所有任务完成
- `isActivityVisible()`: 活动是否可见

#### 资源配置
- `getAssetPath2Valid()`: 获取资源路径
- `getResolutionScale()`: 分辨率缩放

## 使用指南

### Activity.js 使用场景
- 作为所有活动的基础类
- 定义通用的活动结构和行为
- 提供统一的任务组和奖励管理接口

### BaseActivity.js 使用场景  
- 实际活动类的直接父类
- 封装UI管理、支付流程等通用功能
- 提供完整的活动生命周期管理

### RechargeBonanzaActivity.js 使用场景
- 充值狂欢活动的具体实现
- 展示如何继承 [`BaseActivity`](/../活动/接口/BaseActivity.js) 实现特定活动逻辑
- 可作为其他活动实现的参考模板

### 开发建议
1. **新活动开发**：继承 [`BaseActivity`](/../活动/接口/BaseActivity.js)，重写必要的方法
2. **通用功能**：优先使用基类提供的方法，避免重复实现
3. **资源管理**：合理使用资源验证和路径获取方法
4. **事件处理**：正确使用事件验证和通知系统
5. **支付流程**：遵循标准的支付验证消费流程