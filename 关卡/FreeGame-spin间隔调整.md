# Q4\`24-Slots-SOP-元需求-FreeGame-spin间隔调整

###### *一些明确的、独立的、small 需求点*

#### 修订人：赵恒	 	修订时间： 2024-11-12

#### 版本节点：d4173fe61968738150ebe13c1a0b10fb634a69c8

#### 投放分支：classic\_vegas\_cvs\_v710

## 一、概念、术语、类型定义（ 后文以此为准）：

---

#### 关于FreeGame 间隔：

#### FreeGame 每次 spin 之间，需要等待 一轮加钱动画、spinUI 滚钱结束，2 秒； 另加了 0.5 秒的额外间隔，用来统一 spin 流程时间；

## 二、需求：

---

#### 取消 FreeGame 间隔中 0.5 秒的额外等待，使 FreeGame spin衔接更加紧凑；

## 三、实现方法：

---

### 在当前关卡的 XXXSlotMahineScene 中重写以下方法：

#### 1、取消 FreeGame 期间 WaitForSpinProcess 过程触发赢钱线动画

shouldDisableIdleAnimation: function () {
   return this.currentIsFreeSpin();
},

#### 2、取消 FreeGame 期间 WaitForSpinProcess 过程等待时长

getNextSpinInterval: function () {
   return this.currentIsFreeSpin() ? 0 : 0.5;
}

## 四、注意问题：

---

#### 1、有些 FreeGame 玩儿法需求中涉及一些停轮后的表现，注意跟策划沟通要不要等表现结束；

#### 2、注意跟策划沟通，FreeGame 期间是否需要等待 appear 播完； 如果确认不需要等待 appear 动画，未赢钱时前几列appear播到一半直接切走是否接受，最后一列来不及播 appear 是否接受；

## 五、验证、自测：

---

#### FreeGame 滚动结束后：

- #### 有赢钱：只播一轮 win 动画，开始下次 spin；
- #### 没有赢钱：轮盘落定后直接开始下次 spin；
- #### 有赢钱、无赢钱时，appear 表现正常；
- #### 多列 appear、最后一列 appear 表现正常；
