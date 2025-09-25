### **1、熟悉关卡研发流程图：**

[Q2’24-Slots-关卡流程图-程序](https://drive.google.com/file/d/1M5TkWK4DmQNYrFMUBc98hHlVNxARcHDB/view)  
理解 Classic 和 Video 的组件区别；

### **2、配置resource\_dirs.json**

      resource\_dirs.json，位置为res\_oldvegas/resource\_dirs.json；

      在resource\_dirs.json配置文件chapterDirs字段里配置关卡的资源目录信息，资源目录名称以美术上传到WorldTourCasinoResource/themeXX\_XX里为主；

### **3、找后端要关卡基础配置文件，subject\_temp\_\#.json(\#替换为实际关卡Id)**

### **4、执行关卡创建脚本：**

脚本路径：WorldTourCasino/scripts  
执行脚本：create\_app\_subject.py appname subjectId resRootName configFilePath useSpine

### **5、配置文件说明 ：**

*具体配置可以参考上一关。*

#### 5.1、关卡基础配置文件，subject\_temp\_\#.json(\#替换为实际关卡Id)

     subject\_temp\_\#.json配置文件，位置为res\_oldvegas/config/subject\_tmpl\_list/resource\_dirs.json；

     subject\_temp\_\#.json里配置了关卡基本配置信息，例如赢钱线信息，轮盘区域信息，Symbol信息，Paytable信息等等，每一关根据关卡目录信息要实际调整。其中displayName会在玩家Jackpot提示信息时候用到,

     symbols里面具体Symbol的imgName信息需要根据实际名称来配置；

#### 5.2、editable\_config\_\#.json(\#替换为实际关卡Id)

     subject\_tmpl\_id\_list.json配置文件，位置为res\_oldvegas/config/editable\_config\_list/editable\_config\_\#.json；

     editable\_config\_\#.json包含关卡初始化Symbol配置，关卡Drummode配置，关卡滚动配置等等，每一关可能根据实际情况要调整；

#### 5.3、subject\_tmpl\_id\_list.json

     subject\_tmpl\_id\_list.json配置文件，关卡Id信息，位置为res\_oldvegas/config/subject\_tmpl\_list/subject\_tmpl\_id\_list.json；

#### 5.4、slot\_bet.json

      slot\_bet.json配置文件，关卡的bet信息，位置为res\_oldvegas/config/slot\_bet.json；**注意这里是LineBet**；（脚本会生成，特殊情况需要更新，问策划要最新配置）

### **6、发布关卡资源**：

![image1](http://localhost:5173/WTC-Docs/assets/1758727509770_55e91351.png)

### **7、关卡入口：**

新关自带一个通用入口；  
打开 oldvegas 的 CCB 工程，查找本关入口资源，发布；  
![image2](http://localhost:5173/WTC-Docs/assets/1758727509771_7f21a9a7.png)

### **8、到生成的关卡代码脚本中开启研发：XXXXXMachineScene.js**

生成脚本自带一些常用配置、接口，具体含义可以逐个看代码；

### **9、关卡基础组件说明：（结合关卡流程图看）**

SlotMachineScene和SpinPanelComponent都持有Components数据。SlotMachineScene的Componet通过SlotMachineScene的函数getSceneComponentConfig来获取，

SpinPanelComponent的Componet通过SlotMachineScene的函数getSpinPanelComponentsConfig来获取。如果有需要，也可以定义自己的Component或者重写基类的Component。

#### 9.1、SlotMachineScene的Components

1. SceneUIComponent 生成关卡内的最上方TitleUI，Classic关卡的Tournament，Video关卡的Jackpot Title，如果是通过Freespin Coupon进入的话，还会生成Coupon Freespin  
   相关的UI。该Component也包含对这些UI的一些处理。  
2. SpinUIComponent 生成关卡最下的SpinUI。具体更新SpinUI的赢钱或者对SpinUI按钮状态的处理，或者其他一些对SpinUI相关的操作，外界都是通过调用这个Component来处理的。  
3. FreeSpinBeginComponent 该Component主要是处理Freespin开始弹板或者Freespin开始前的一些动画。  
4. FreeSpinEndComponent 该Component主要是处理Freespin结束赢钱弹板和Freespin结束一些界面切换(比如SpinUI界面还原)。  
5. SpinPanelComponent SpinPanelComponent可以有多个，因为有可能关卡会有多个轮盘。该Component主要是创建ReelBackgroundController(关卡轮盘界面)，生成轮盘滚动区域。  
   轮盘状态(例如，每一列的锁定状态columnLockStatus)或者Symbol图标最终位置getPanelCellPosition等等，跟轮盘相关的显示很多都是在这个Component来处理的。  
6. SceneBackgroundComponent 有时候背景和轮盘部分是拆开的，因为轮盘背景部分可能会有单独的动画，这时候轮盘背景部分就是在该Component里来创建的。  
7. BonusGameComponent  该Component主要是处理赢钱线赢钱之后的特殊玩法，比如有的时候是Pick玩法，有的是转盘玩法等等，很多特殊玩法都是在这个Componet来做的。  
8. ScatterGameComponent 该Component主要是处理特殊的Scatter动画，比如有些关卡Freespin里出现Scatter会增加Freespin次数，有的会弹出额外的弹板，这个时候的动画处理都是在这个Component来完成的。  
9. AudioComponent 播放音效和背景音乐的Component。  
10. GlobalAnimationComponent 该Componet主要是处理关卡全局的非轮盘区域的动画，因为轮盘区域里的动画会被裁剪。toggleOverlayVisible来设置时候显示半透遮罩，addLockedCategory来设置，某一类节点是否被清除。  
11. LevelUpComponent 升级弹板相关的处理。  
12. EnterRoomCheckingComponent 处理进入关卡时候，关卡之前的一些状态。比如有的时候进入关卡会有个弹板或者有的关卡之前列是锁定的，会有锁定的动画等等，这些进入关卡之前的一些状态都可在这里来处理。  
13. InteractiveGameComponent 有的时候关卡特殊玩法需要和服务器进行交互，服务器根据客户端不同的customizedMode返回不同的数据给客户端，这样的处理在该Component来完成。  
14. JackpotEffectComponent Classic关卡有一些对Jackpot弹板的特殊处理在该Component来完成。例如，有的时候会要多弹一个特殊的jackpot弹板。  
15. BlinkWinManComponent 播放所有的赢钱动画或者处理关卡空闲时候重复播放赢钱动画的逻辑。

#### 9.2、SpinPanlComponet的Components

1. DrumModeComponent 处理关卡的Drummode(Drummode就是大概率会中大奖或者中特殊玩法之前，从听觉和视觉来刺激玩家的一种特殊动画还有音效)，每一关的Drummode配置都是在editable\_config\_\#.json来配置的，  
   但是也有可能有的关卡比较特殊，这个时候需要重写该Component来特殊处理。  
2. WinLineComponent 生成关卡所有的赢钱线，赢钱线的位置，颜色，宽度，显示或者隐藏哪条赢钱线都是在该Componet来处理。  
3. WinFrameAnimationComponent Video类关卡好多赢钱时候，图标都会有一个特殊动画边框，边框的生成是在该Componet处理的。  
4. LinesBlinkComponent 该Component主要是处理赢钱线的播放逻辑，播放所有赢钱线，重复播放单条赢钱线，播放Scatter动画都是在该类来处理的。  
5. SymbolLayerComponent 该Component主要是处理Symbol图标的生成，显示，位置更新，Symbol图标移除，进入关卡图标的初始化等等。  
6. LocalAnimationComponent 一些轮盘相关的特殊动画都是调用该类的函数来存储，比如有些关卡图标会有一个锁定的动画或者轮盘位置会弹出一个弹板等等，都可以通过该Componet来实现。  
7. SymbolAnimationComponent 赢钱动画的创建和回收，或者其他Symbol图标动画的创建和回收都可以通过该Component来完成。  
8. PanelSpinEndComponent 轮盘转动停止的一些处理，比如有些appear动画需要轮盘转动才会被清理。  
9. ColumnStopAnimationProcess 轮盘每一类停止的动画处理，有些关卡每一列停止时候需要有特殊的动画，这时候可以在这里来处理。

这里主要有两个Process，类似于状态机，一个是关卡从等待到一次spin开始，直到Spin流程结束的Process，这个Process是SlotMachineScene通过initializeFlowDispatcher调用getProcesses来生成的。

调用。另外一个就是关卡转动逻辑的Process，是SpinPanlComponet里调用SlotMachineScene里的getPanelColumnSpinProcessConstructors来生成的。

### **10、关卡流程Process：（结合关卡流程图看）**

#### 10.1 主流程

![image3](http://localhost:5173/WTC-Docs/assets/1758727509772_16e4f022.png)

1. EnterRoomCheckingProcess 进入关卡时候会首先进入这个流程，在这个流程里会调用EnterRoomComponent检查该关卡是否有特殊的处理，如果有则在EnterRoomComponent里面特殊处理，  
   处理完了调用EnterRoomCheckingProcess的回调，进入到下一个流程。⚠️注意这个流程，每次进入关卡只会执行一次。  
2. WaitForSpinProcess Spin开始前等待的流程。这个流程里会判断玩家下一次是否是Freespin或者Autospin或者Coupon Freespin或者交互玩法，如果是则设置相应的关卡UI状态，并且进入到下一次  
   Process。如果不是，则判断是否有赢钱线，如果有则顺序播放赢钱线，然后会进入Spin待机状态，等待玩家玩家输入。Spin Button的响应，是调用WaitForSpinProcess的onEvent来处理的。  
   如果玩家点击了Spin按钮之后，就会进入下一个流程。  
3. FreeSpinBeginCheckingProcess 在该流程则会检查玩家是否触发了Freespin，在该流程里会设置SlotMan的isInFreeSpin状态，并且调用FreeSpinBeginComponent显示Freespin开始弹板。  
4. RoundStartProcess 该流程里根据玩家的玩法选择是否扣除玩家Bet，并且设置UI状态，就会进入到下一个流程。  
5. SubRoundStartProcess 在这个流程里会重置上次一Spin赢钱数据，向服务器发送Spin协议也是在这个流程里在完成的。该流程里也会清除之前轮盘的一些特效，之后会进入下一个流程。  
6. SpinProcess 这个流程里主要是处理关卡滚动状态，以及是否在Spin过程中点击Stop按钮，也是调用该流程里onEvent来处理的。具体关卡运动状态是在另外一个Process来做的。  
7. SpecialGameProcess 这个流程是关卡运动停止后的第一个流程，主要处理关卡停止后的一个特殊玩法，可以是一个收集玩法或者其他玩法，玩法处理结束后，会进入到下一个流程。  
8. ShowWinEffectProcess 这个流程里是判断玩家是否中了一个特别大的赢钱，如果中的赢钱达到了之前定的一个阈值，会弹出一个BigWin或者MegaWin弹板，告诉玩家中了一个特别大的赢钱，  
   弹板关闭后会进入下一个流程  
9. LevelUpProcess 这个流程里判断玩家是否会升级，处理玩家升级的一个流程。  
10. VipLevelUpProcess 这个流程里是玩家Vip升级相关的处理。  
11. BlinkAllWinLineProcess 这个流程里会播放玩家当次Spin所有的赢钱线。  
12. PanelWinUpdateProcess 该流程会将玩家的SpinUI赢钱和Balance赢钱跟玩家当前的数据做同步表现。  
13. BlinkBonusProcess 该流程里来处理玩家有Bonus玩法的情况，⚠️注意这里的Bonus玩法和上面Special玩法不一样，Special玩法是在赢钱线播放之前来处理的。Bonus玩法是在赢钱线播放之后来处理的，  
    具体情况可以根据实际来调整。  
14. BlinkScatterProcess 如果玩家中了Freespin，该流程是处理Freespin开始弹板弹出之前，所有Scatter图标的特殊动画。  
15. SubRoundEndProcess 这个流程是判断是否跳出上图getProcesses里的第二个loop，因为有的关卡是Respin，现在我们Respin的处理是服务器会发过来多个结果，Respin期间不会再跟服务器交互，  
    直到最后一次Respin结果结束。还有一种是Link关卡情况，会根据服务器发的结果算出来一个Respin结果，在Spin到最后一个Respin结果之前，都是在第二个loop里来循环执行的。  
16. RoundEndProcess 这个流程里会判断是否弹出RateUs弹板，还有活动的回调处理也是在这里处理的。活动回调其实就是一次Spin结束，活动进度有变化可能会有一个动画表现，活动的这个动画结束，  
    关卡这边才能进入到下一个流程。  
17. FreeSpinEndCheckingProcess 判断玩家是否Freespin结束，如果玩家Freespin结束，则弹出Freespin结束弹板。否则，进入下一个流程  
18. CouponFreeSpinCheckingProcess  判断玩家是否Coupon Freespin结束，如果玩家Coupon Freespin结束，则弹出Freespin结束弹板。否则，进入下一个流程。  
19. InteractiveGameCheckingProcess 判断是否有跟服务器交互的玩法，如果有则在该流程调用InteractiveGameComponent。  
20. ShowInterstitialAdProcess 根据一些状态判断是否弹出插屏广告。

#### 10.2、关卡某列滚动流程Process：

![image4](http://localhost:5173/WTC-Docs/assets/1758727509774_79f20ffa.png)

1. ColumnSpinStartProcess 处理关卡图标从静止到开始滚动的流程。  
2. ColumnSpinBeforeReceiveSpinResultProcess 该流程是等待客户端接收到服务器返回的Spin协议，如果服务器没有返回，则一直在该Process等待。如果收到Spin协议，则进入到下一个滚动状态。  
3. ColumnSpinSteadyProcess 该流程就是收到结果后，Symbol图标会以一个稳定的速度匀速滚动的流程。  
4. ColumnSpinDecelerationProcess 该流程就是图标从匀速阶段逐渐减速直到静止。  
5. ColumnSpinStopProcess 该流程会检查图标是否有停止的Appear动画，如果有，则在这个流程播放图标的Appear动画。  
6. ColumnStopAnimationProcess 此流程会检查该列停止时候，是否需要播放特殊的动画或者某些特殊的处理。

### drumConfig配置详解：

**"drumConfig"**: \[//数组，对应多轮盘，每个轮盘对应一组配置  
 {//轮盘 0 对应的drum配置  
   **"commonDrumConfig"**: {//普通 drum 配置，常用  
     **"needStopDrumSoundEachColumn"**: **false**,//是否  
     **"drumGroupConfig"**: \[  
       {  
         **"showDrumAnimation"**: **false**,//是否需要播放 drummmode 动画（通常是轮盘上的特殊光效）  
         **"appearOnColumnMap"**: {//参与 drummode 触发的 symbol 可以出现在哪些列  
           **"1201"**: \[  
             0,  
             1,  
             2,  
             3,  
             4  
           \],  
           **"1202"**: \[  
             0,  
             1,  
             2,  
             3,  
             4  
           \],  
           **"1203"**: \[  
             0,  
             1,  
             2,  
             3,  
             4  
           \]  
         },  
         **"symbolIds"**: \[//参与 drummode 触发的 symbol 都有哪些  
           1201,  
           1202,  
           1203  
         \],  
         **"validInFreeSpin"**: **true**,//该配置是否再 freespin 中生效  
         **"validInNormalSpin"**: **true**,//该配置是否在普通 spin 中生效  
         **"validInReSpin"**: **true**,//该配置是否再 respin 中生效  
         **"needOnWinLine"**: **false**,//参与触发 drummode 的 symbol 是否要求需要出现在赢钱线上  
         **"needConsecutive"**: **false**,//参与触发 drummode 的 symbol 是否需要按列连续出现  
         **"playAppearSoundByCount"**: **false**,//参与触发 drummode 的 symbol 落定时按落定数量播 appear 音效  
         **"playAppearSoundByCol"**: **false**,//参与触发 drummode 的 symbol 落定时按落定的列播 appear 音效  
         **"needPlayAppearAnimation"**: **true**,//参与触发 drummode 的 symbol 落定是否需要播 appear 动画  
         **"columnAppearOnce"**: **false**,//参与触发 drummode 的 symbol 是否每列落定多个时只算一个  
         **"supportRealAppearNum"**: **true**,//是否按当前落定的真实数量计算 drummode 触发  
         **"leastCount"**: 1,//触发 drummode 需要多少个相关 symbol  
         **"appearAnimationSoundName"**: **"248\_bonus\_appear"**,//参与触发 drummode 的 symbol 落定 appear 时的音效名  
         **"appearAnimNormalSpinTimeline"**: **"appear\_base"**,//参与触发 drummode 的 symbol 落定 appear 时的时间线名字  
         **"appearAnimFreeSpinTimeline"**: **"appear\_base"**//参与触发 drummode 的 symbol 落定 appear 时的时间线名字(freespin中使用，通常不需要区分)  
       }  
     \],  
     **"drumCCBPath"**: **""**,//drummode 动画的 CCB（图标的上层）  
     **"drumBottomCCBPath"**: **""//drummode 动画的 CCB （图标的下层）**  
   },  
   **"symbolDrumConfig"**: {//symbolDrum 配置，涉及有缺陷，几乎不用  
     **"drumGroupConfig"**: \[\],  
     **"drumCCBPath"**: **""**  
   }  
 },  
 {//轮盘 1 对应的drum配置（没有多轮盘不用配，可删掉）  
   **"commonDrumConfig"**: {  
     **"needStopDrumSoundEachColumn"**: **false**,  
     **"drumGroupConfig"**: \[\],  
     **"drumCCBPath"**: **""**,  
     **"drumBottomCCBPath"**: **""**  
   },  
   **"symbolDrumConfig"**: {  
     **"drumGroupConfig"**: \[\],  
     **"drumCCBPath"**: **""**  
   }  
 },  
 {//轮盘 2 对应的drum配置（没有多轮盘不用配，可删掉）  
   **"commonDrumConfig"**: {  
     **"needStopDrumSoundEachColumn"**: **false**,  
     **"drumGroupConfig"**: \[\],  
     **"drumCCBPath"**: **""**,  
     **"drumBottomCCBPath"**: **""**  
   },  
   **"symbolDrumConfig"**: {  
     **"drumGroupConfig"**: \[\],  
     **"drumCCBPath"**: **""**  
   }  
 }  
\],  








