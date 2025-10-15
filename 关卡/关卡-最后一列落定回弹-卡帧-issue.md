# Q4\`24-Slots-SOP-问题记录-253最后一列落定回弹过程卡帧

###### *记录常见问题的处理过程*

#### 修订人：赵恒	 	修订时间：2024-11-4

#### 版本节点：

#### 投放分支：

## 一、概念、术语、类型约定（ 后文以此为准）：

---

## 二、现场记录：(特征、表现)

---

#### 最后一列落定回弹最后阶段跳帧，视觉上类似于卡顿、symbol 落定时位置突然上移；

## 三、问题分析：

---

### 1、未启用流程插帧：

#### enterOnNextFrame \= false； 回弹最后一帧未更新完 symbol 位置时，流程控制流转到下一个流程，后续流程存在停止 symbol 动作、刷新 symbol 显示、启动赢钱线表现等逻辑，导致回弹表现缺失一帧；

### 2、SpinProcess 流程间缺少隔离：

#### 253 为加快 spin 节奏，落定立即恢复 spin 按钮，取消了 appear 等待， 取消了columnStopAnimationDelayTime 配置：导致 ColumnStopAnimationProcess 流程直接结束，流转时未做等待；

## 四、解决方案：

---

### 方案一：开启 enterOnNextFrame；

#### 不建议，会导致spin 按钮恢复节奏变慢

### 方案二：重写 columnStopAnimationComponent 组件：

#### 该组件无其他逻辑时可用， 强制进入 ColumnStopAnimationProcess 流程，流转前插一帧延时；

### 方案三：SpinProcess 流程后插入一个自定义流程：

#### columnStopAnimationComponent 有占用不方便重写时可用， 强制隔断主流程 SpinProcess 流转；该自定义流程流转前插入一帧延时；

![image1](/assets/1758727509963_c5c91587.png)

**var** SpinEndWaitProcess \= ***Process***.**extend**({
   **name**: **"CloverClashWaitProcess"**,

   onEnter: **function** (args) {
    **this**.\_super(args);

    **if** (**this**.**context**.**machineConfig**.**enterOnNextFrame**)
    **this**.advanceToNext();
    **else**
    **game**.**slotUtil**.delayCall(0.0001, **function** () {
    **this**.advanceToNext();
    }.bind(**this**));
   }
});

## 五、测试、验证：

#### 1、无落定卡顿表现；

#### 2、spin 节奏、spin 按钮恢复时机符合策划预期；

#### 3、无流程异常；
