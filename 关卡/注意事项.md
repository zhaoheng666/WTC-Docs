## 以252（haunted\_manor）为例，关卡可能同时解锁多个轮盘spin，列出几个开发过程中需要注意的比较重要的细节。

### 一：多轮盘相关配置

subjefct\_tmpl\_id.json：以下数据需要根据轮盘数量添加相关配置。  
	lines  
panels  
simulateReels

editable\_config\_id.json：以下数据需要根据轮盘数量添加相关配置。  
	initializeSymbolSequence  
headAndTailSymbolSequence  
drumConfig  
panelSpinSchemeMap

### 二：轮盘组件初始化

	SlotMachineScene2022.initializeSpinPanelData，根据最大的轮盘数量调整this.panelIdComponentType，目前已调整为最多5轮盘(base \+ 4额外轮盘)，如果没有相应的配置，spinPanel无法初始化。

### 三：SpinPanelComponent的二级组件使用

所有用到SpinPanelComponent的二级子组件的地方，例如drumModeCompoent、symbolLayerComponent，全部根据轮盘id来获取对应组件再使用，不可直接使用this.xxxxxxComponent

### 四：多轮盘闪赢钱线组件

BlinkWinManComponent多数方法需要重写，里面用到了SpinPanelComponent的二级组件。需要重写的相关方法可参考**HauntedManorBlinkWinManComponent。**

### 五：多轮盘获取对应展示的spin结果

需重写getReceivedSpinResult方法，根据轮盘id获取对应轮盘的结果。spinPanelComponent中调用该方法时其实是传了panelId参数的，但逻辑中并没有用到，所以无法根据轮盘id获取对应的spin结果，需要重写。否则多轮盘同时转的时候，最终展示的结果都是一样的。

### 六：修正多轮盘赢钱数统计

重写getPanelWinChips，叠加多轮盘结果的chips，否则计算totalWinChips时只计入第一个结果的chips，会导致计算winChips不一致。

### 七：重置winLevel

需要初始化resetWinLevelAction，并将重新计算后的winLevel覆盖this.receivedSpinResult，winEffectComponent.checkNeedShowBigWin没有判断多轮盘，是以常规的单轮盘结果作为判断依据的。所以只需将更新后的winLevel覆盖常规的结果即可。

### 八：多轮盘freeSpin不自动结束、结束后金币不一致，spinPanelIndex修正

多轮盘freeSpin如果后端给的数据是多个spin结果的话，需要重置spinIndex，否则freeSpin结束时的SubRoundEndProcess会判断错误导致继续自动spin一次，进不到检查freeSpin结束的流程。也会导致freeSpin结束后金币数量不一致。  
两种解决方式：  
1、handleSpinResult时，添加如下代码：this.currentSlotMan.spinPanelIndex \= this.currentSlotMan.getSpinPanelLength();  
if (this.currentIsFreeSpin() && \!this.nextIsFreeSpin()) {  
   this.currentSlotMan.spinPanelIndex \= this.currentSlotMan.getSpinPanelLength();  
}

2、重写isLastSpinIndex()，判断在相应条件下返回true。  
isLastSpinIndex: function () {  
   if (this.currentIsFreeSpin())  
       return true;  
    
   return this.\_super();  
},

### 九：修正多轮盘每轮spin开始时轮盘光效操作

重写spinPanelSubRoundStart方法，根据轮盘id获取spinPanelComponent，否则subRoundStart时轮盘光效无法重置。  
spinPanelSubRoundStart: function () {  
   if (this.currentIsFreeSpin()) {  
       for (var panelId=1; panelId\<this.panelLockStatus.length; panelId++) {  
           if (\!this.panelLockStatus\[panelId\] && panelId\!==0) {  
               var spinPanelComponent \= this.getSpinPanelByPanelId(panelId);  
               spinPanelComponent.onSubRoundStart();  
           }  
       }  
   } else {  
       this.\_super();  
   }  
},

### 十：bigwin的轮盘光效

重写showReelEffectForBigWin方法，根据轮盘id获取spinPanelComponent，否则多轮盘bigWin时，会播放base轮盘的光效。

### 十一：SlotMan.multiPlayPanelCount轮盘数量控制

	切换到多轮盘spin之前，需要调用game.SlotMan.getCurrent().multiPlayPanelCount \= panelCount;方法设置轮盘数量，否则父类中在处理加钱时只会获取第一个轮盘的结果，其余轮盘的赢钱会被丢弃导致金币不一致。在切换回base轮盘时，再重置multiPlayPanelCount \= 1；  
	**不要使用this.getCurrentSlotMan().setMultiPanelCount(1);进行设置，该方法中同时封装了重新计算推荐bet的逻辑，会导致向后端发送C2SSpin时带的bet参数不正确。**  
	设置了轮盘数量之后，会影响获取当前的bet，根据需求考虑是否进行bet拆分，如果不需要拆分的话，在切换轮盘数量之前记录真实bet，并在machineScene中重写两个方法来校正bet：  
usingFeatureDependentSpinBet: function () { // 进入多轮盘后，计算totalBet会乘以轮盘数量，这个方法用于改写原逻辑，用关卡自己的bet逻辑  
   return true;  
},

getFeatureDependentSpinBet: function () {  
   if (this.\_freeGameTotalBet) {  
       return this.\_freeGameTotalBet;  
   } else {  
       return this.getCurrentSlotMan().getSinglePanelBet();  
   }  
},

### 十二：多轮盘补位图标不正确问题

	首先检查模拟卷轴，如果模拟卷轴和后端的extraPa结果可以匹配的话，打印一下多轮盘的spinResult数据，如果结果中没有前端格式化后的extraPanel属性的话，在handleSpinResult方法中，根据轮盘id添加如下代码：  
var slotMan \= this.getCurrentSlotMan();  
this.receivedSpinResultList \= game.util.deepClone(slotMan.spinResult);  
this.componentsMap\[NewSlot.***ComponentType***.SPIN\_PANEL\_ONE\].handleSpinInfo(this.receivedSpinResultList\[0\]);  
this.componentsMap\[NewSlot.***ComponentType***.SPIN\_PANEL\_TWO\].handleSpinInfo(this.receivedSpinResultList\[1\]);  
this.componentsMap\[NewSlot.***ComponentType***.SPIN\_PANEL\_THREE\].handleSpinInfo(this.receivedSpinResultList\[2\]);  
this.componentsMap\[NewSlot.***ComponentType***.SPIN\_PANEL\_FOUR\].handleSpinInfo(this.receivedSpinResultList\[3\]);

