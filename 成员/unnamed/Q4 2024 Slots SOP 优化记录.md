# Q4\`24-Slots-SOP-优化记录-SlotAction-程序

# version 1.0：

#### 修订人：赵恒 		修订时间： 2024-11-12 

#### 版本节点：bb88601960c48f0d8049bca8796b66739028f4ac

#### 投放分支：classic\_vegas\_cvs\_v710

## 一、概念、术语、类型约定（ 后文以此为准）：

---

#### Process：基础流程

#### Component：基础组件

#### SlotAction：新的关卡研发设计

#### SlowDrumModeAction：SlotAction 版慢 drummode 组件

## 二、优化目的：

---

### a、现状：

1. #### 每一关根据需求各自重写基础流程、组件；

2. #### 需求点的实现逻辑穿插在多个重写的组件、流程、或其他需求点的实现逻辑中；

3. #### 部分流程控制代码、组件接口等，数量较多、层级过深；

### b、弊端:

1. #### 逻辑分散，内聚性差，不方便组织代码；改动、维护难度大：

2. #### 逻辑层耦合度过高；

3. #### 对研发经验要求高：部分问题的处理，需要开发者对整个 Slots 研发流程、实现细节的掌握达到一定程度；

4. #### 重写粒度过大，冗余代码堆积；

5. #### 代码复用程度低，不能有效积累通用需求实现逻辑；

## 三、优化方案：

---

### 将关卡研发的需求点抽象为 SlotAction 类，遵循以下思路设计、封装：

1. 解耦：遵循单一职责原则，不同需求点封装为不同 SlotAction，实现逻辑与基础流程、组件解耦；  
2. 组合：组合而不是重写；各通用 process 、component提供插槽，以 SlotAction（SlotActionArray、SlotActionSequence） 为单位按需插入；  
3. 内聚：各需求点的实现逻辑内聚于独立的 SlotAction 中，相互隔离，避免逻辑杂糅；  
4. 封装：隐藏基础流程、组件的驱动逻辑、实现细节；隐藏通用需求的实现逻辑；使研发精力集中于新需求点的实现逻辑上；  
5. 规范：要求新增通用逻辑、模块不得直接插入到通用流程、组件的逻辑中，改以 SlotAction 为单位，按照规范注入通用流程、组件的逻辑中；  
6. 细化颗粒度：以 SlotAction 为颗粒，摆脱对通用流程、组件的大面积重写，减少冗余代码；  
7. 继承、复用：积累足够数量的通用SlotAction，供后续开发直接引入、或继承引入；

## 四、实施细节：

---

##### ⚠️*后补的文档，存在实现细节丢失的情况，暂时补充这些：*

#### 组织结构：src/newdesign\_slot/actions/

![image1](http://localhost:5173/WTC-Docs/assets/1758727509913_678fb0bd.png)

#### SlowDrumModeAction：

![image2](http://localhost:5173/WTC-Docs/assets/1758727509922_8a64a39c.png)  
![image3](http://localhost:5173/WTC-Docs/assets/1758727509923_aa73f2a3.png)  
![image4](http://localhost:5173/WTC-Docs/assets/1758727509925_1f564af0.png)  
![image5](http://localhost:5173/WTC-Docs/assets/1758727509925_270c1538.png)

## 五、结果评估：

---

- [x] ### 可以达成“解决当前关卡研发弊端”的目的；

- [x] ### 可以实现“扭转现行关卡开发模式”的目的；

## 六、影响范围、注意事项：

---

#### 1、SlotAction注入逻辑，涉及改动通用流程、组件的检查、触发接口；影响使用 2022 版本 component 的关卡；

#### 2、SlowDrumAction 涉及多出处通用 spin 流程、组件改动；影响使用 2022 版本 component 的关卡；

## 七、测试要点：

---

- [ ] #### 验证老关流程；

- [ ] #### 抽测老关DrumMode、前摇表现；

      

# version 2.0

#### 修订人：赵恒 		修订时间： 2024-11-12 

#### 版本节点：85f554d0dcfa335266bb3579d45d6917133f190c

#### 投放分支：classic\_vegas\_cvs\_v763

## ~~一、概念、术语、类型约定（ 后文以此为准）：~~

---

## 二、优化目的：

---

#### 1、自定义的关卡内 SlotAction 对象直接绑定在 SlotMachineScene上，缺少统一维护、释放，存在内存泄漏情况；

#### 2、事件移除接口存在缺陷，导致内存泄漏；

#### 3、部分需求点不需要时间监听等额外逻辑，直接继承完整的 SlotAction 过于重度、冗余；

## 三、优化方案：

---

#### 1、抽象 SlotActionEasy 层作为基类，避免胖接口；

#### 仅包含：ctor，initialization，onExit，triggerFliter，onTrigger等基础接口；

#### 目的：一些简单的 slotAction 封装直接继承 SlotActionEasy，避免包含不必要的成员；

#### 2、SlotAction 继承 SlotActionEasy，封装事件注册、响应、移除、actionNode等额外成员；

#### 3、删除 onTriggerEnd 方法，该方法人为增加了耦合，改为使用 fliterData、triggerData  中植入 processTag 的方法区分不同的触发时机；

#### 4、优化释放，增加关卡退出时对 SlotAction onExit  的调用，避免内存泄露；

#### 5、修正 SlotAction 的事件移除调用时机，onLeaveRoom 新增到 onExit 方法，避免关卡退出后、Js Object 未及时 GC，导致其仍能收到事件；

## 四、实施细节：

---

#### 1、SlotActionEasy、SlotAction 分层：

#### ![image6](http://localhost:5173/WTC-Docs/assets/1758727509926_370b6fcf.png)

#### 2、优化退出接口：

![image7](http://localhost:5173/WTC-Docs/assets/1758727509928_0b07143a.png)

#### 3、新增工厂类 SlotActionFactory ，提供两种注册（生成）方式：

##### 3.1、生成、注册通用 SlotAction

![image8](http://localhost:5173/WTC-Docs/assets/1758727509929_213fc701.png)

##### 	3.2、生成注册自定义 SlotAction、继承的 SlotAction

##### ![image9](http://localhost:5173/WTC-Docs/assets/1758727509931_99b225f4.png)

##### 	3.3、统一的 get 接口，不建议直接绑定到 SlotMachineScene；

##### ![image10](http://localhost:5173/WTC-Docs/assets/1758727509894_ef407410.png)

## 五、结果评估：

---

- [x] #### 1、有效降低内存泄漏风险；

- [x] #### 2、SlotAction 的继承更灵活，管理更规范；

- [x] #### 3、修复了上个版本的逻辑缺陷，移除部分冗余代码；

## 六、影响范围、注意事项：

---

##### 1、 本次优化影响范围：当前应用了 SlotAction 的所有关卡；

239：LOCKING\_FLAMES  
241：GEMS\_RESPIN\_RITZ  
245：LIGHTNING\_STACKS  
246：WALKING\_WILDS  
247：DIAMOND\_DESTINY  
248：FIREWORK\_STRIKE  
249：DELUXE\_DOLLAR\_SPIN  
252：HAUNTED\_MANOR  
254：ICEBOUND\_RICHES

##### 2、⚠️SlotAction 对象建议使用 RegisterFactory 的 getSlotAction 方法，不建议直接绑定到 SlotMachineScene，更不建议绑定到其他组件、对象，避免影响 jsObject GC；

#### 3、⚠️SlotAction 事件接口有变更；

##### 影响范围：继承、使用了 SlotAction 事件接口的关卡；

## 七、测试要点：

---

- [ ] #### 测试当前应用了 SlotAction 的所有关卡，主要是关卡的基本流程、关卡退出释放；

- [ ] #### 测试继承、使用了 SlotAction 事件接口的关卡：

      - [ ] ##### FireWorkStrikeLinkDrumAction，248的小格子 drum 表现；

      - [ ] ##### FireWorkStrikeLinkDrumAction，248的 respin 次数更新表现；

      - [ ] ##### 使用了 SlowDrumModeAction 的关卡，慢 drum 后下次 spin 是否残留；

		245:  Lightning\_Stacks  
		247:  Diamond\_Destiny  
		241：GEMS\_RESPIN\_RITZ  
		254：ICEBOUND\_RICHES  
239：LOCKING\_FLAMES  
242: Piggys\_Payday  
240: Treasure\_Tempest

# version 3.0

#### 修订人：赵恒 		修订时间： 2025-3-6 

#### 版本节点：3bebc7e5aaa5d0c545f5b2162d83038e158a3ae0

#### 投放分支：classic\_vegas\_cvs\_v797

#### 研发分支：classic\_vegas\_cvs\_v796\_SlotAction\_onExit

## 一、优化目的：

---

#### 1、注册到 Component 中的 SlotAction 会在 SlotMachineScene 退出时被调用两次 onExit；

#### 2、SlotMachineScene.onExit 中，exitSlotActions 调用晚于 componentsMap\[key\].onExit()，不符合依赖关系； eg：如果 SlotAction 实例中存在对 component 的依赖，且 onExit 时操作了 component 依赖，component 提前退出，导致 SlotAction 实例 onExit 逻辑异常；

##### **案例：**

![image11](http://localhost:5173/WTC-Docs/assets/1758727509896_4128c266.png)  
修正：a67bba5aa732b60e6511a30d4f4364dede07fe69

#### 3、补充代码说明、注释；

#### 4、SlotActionFactory 存在两个 Register 接口，不便于推广普及 SlotActionFactory 用法；

## 二、优化方案：

---

#### 1、SlotMahcineScene、component、复合SlotAction（SlotActionSequence、SlotActionArray、SlotActionSpawn）中，onExit 前添加 context 判定； 默认 SlotAction 必定存在 context；

#### 2、调整 component、SlotActions 退出顺序；

#### 3、SlotActionFactory 的 Register 接口归并；

## 三、实施细节：

---

#### 1、onExit 去重;

#### ![image12](http://localhost:5173/WTC-Docs/assets/1758727509898_c91e0b4a.png)

#### 2、优化退出顺序：

![image13](http://localhost:5173/WTC-Docs/assets/1758727509899_70ac9eb0.png)

#### 3、SlotActionFactory ，Register 方法归并：

##### 3.1、SlotAction 基类添加类型标识：

* ##### ⚠️Register 传递的 SlotAction 的构造原型，并非实例，类型定义不能用成员变量；

* ##### 基于 cc.class 内部封装有对原型链的修改，定义为静态成员无效；

![image14](http://localhost:5173/WTC-Docs/assets/1758727509901_1472ca83.png)

##### 	3.2、Register 中分流：

	![image15](http://localhost:5173/WTC-Docs/assets/1758727509902_727f92aa.png)

## 四、影响范围、测试要点：

---

##### 1、 本次优化逻辑影响范围：当前应用了 SlotAction 的所有关卡；

239：LOCKING\_FLAMES  
241：GEMS\_RESPIN\_RITZ  
245：LIGHTNING\_STACKS  
246：WALKING\_WILDS  
247：DIAMOND\_DESTINY  
248：FIREWORK\_STRIKE  
249：DELUXE\_DOLLAR\_SPIN  
252：HAUNTED\_MANOR  
254：ICEBOUND\_RICHES  
…… 后续所有关卡

##### 2、影响逻辑位置：关卡退出；

#### 3、重点测试关卡：254：IceboundRichesMachineScene

# version 4.0

#### 修订人： 赵恒 		修订时间：  2025-3-6 

#### 版本节点： 4df34a683d3b556d019dac3f58ee6554bc70214b

#### 投放分支： classic\_vegas\_cvs\_v826

## 一、优化目的：

#### 1、规范、统一 SlotAction 的使用，推进普及；

#### 2、简化 SlotAction 常用接口，降低使用成本；

## 二、优化方案：

#### 1、优化 SlotActionFactory ， 优化不够简洁的接口，添加老接口废弃标记；

#### 2、补全接口注释、使用说明；

#### 3、新的接口植入到关卡 SlotMachineScene 模板；

## 三、实施细节：

#### 1、修改细节：

#### ![image16](http://localhost:5173/WTC-Docs/assets/1758727509905_70dc5a95.png)

![image17](http://localhost:5173/WTC-Docs/assets/1758727509907_b0231a9e.png)  
![image18](http://localhost:5173/WTC-Docs/assets/1758727509909_e3504139.png)  
![image19](http://localhost:5173/WTC-Docs/assets/1758727509912_26dbd910.png)  
![image20](http://localhost:5173/WTC-Docs/assets/1758727509915_7947a1e0.png)

#### 2、使用范例：

![image21](http://localhost:5173/WTC-Docs/assets/1758727509917_660bb53c.png)  
![image22](http://localhost:5173/WTC-Docs/assets/1758727509920_dcffba7d.png)  
![image23](http://localhost:5173/WTC-Docs/assets/1758727509921_32f78c6e.png)

## 四、影响范围、注意要点：

#### 1、旧的接口保留，不影响旧关卡；

#### 2、新关尽量使用新的接口；

##### 













































