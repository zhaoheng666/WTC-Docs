# Link 玩法结算：

## 进 link 清空 win 框赢钱：（看策划需求）

*// 表现win框加钱*  
**this**.**context**.**spinUIComponent**.updateWinChips(0);  
*// 更新当前赢钱和当前总赢钱*  
**game**.**SlotMan**.getCurrent().setCurWinChips(0);

## link 结算：

#### 1、计算每个图标赢钱；

#### 2、更新 win 框；updateWinChipsWithDuration

#### 3、更新 SlotMan 数据；addCurWinChips

addBonusSymbolWinChips: **function** (bonusInfo) {  
   **var** winChips \= 0;

   **if** (bonusInfo.**multi** \> 1000) { *// mini、minor、major 等固定倍数的 jackpot link 图标（具体看服务器怎么发送的数据）*       
 **var** jackpotLevel \= bonusInfo.**multi** \- 1001;  
       **var** ratio \= **this**.**context**.**machineConfig**.**JackpotRatioList**\[jackpotLevel\];  
       winChips \= ratio \* **game**.**SlotMan**.getCurrent().getCurrentTotalBet();  
   } **else** {  
       winChips \= bonusInfo.**multi** \* **game**.**SlotMan**.getCurrent().getCurrentTotalBet();  
   }

   **if** (bonusInfo.**area\_multi**)*// 有些 link 图标会受玩儿影响产生倍数效果*  
       winChips \= winChips \* bonusInfo.**area\_multi**;

   *// cc.warn("addBonusSymbolWinChips:", winChips, bonusInfo, game.SlotMan.getCurrent().totalWinChips);*

   *// 计算当前总赢钱*  
   **var** currentTotalWinChips \= **game**.**SlotMan**.getCurrent().**totalWinChips** \+ winChips;  
   *// 表现win框加钱*  
   **this**.**context**.**spinUIComponent**.updateWinChipsWithDuration(currentTotalWinChips, 1);  
   *// 更新当前赢钱和当前总赢钱*  
   **game**.**SlotMan**.getCurrent().addCurWinChips(winChips);

   **this**.**bonusTotalWinChips** \+= winChips;

   *// 通常 link 结算阶段加钱的时候会给有一个 win 框的光效*  
   **var** spinUI\_effect \= **this**.**context**.**mainUIComponent**.getMainUINode(**"spinUI\_effect"**);  
   **game**.**slotUtil**.playAnim(spinUI\_effect, **"win"**);  
},

#### 4、link 结束、切换到 base 轮盘后，更新 player chips

settleBonusWinChips: **function** () {  
   *// var baseWinChips \= this.context.receivedSpinResult.extraInfo\["baseWinChips"\];*  
   *// cc.warn("settleBonusWinChips:", this.bonusTotalWinChips);*  
   *// 更新玩家金币数*  
   ***PlayerMan***.getInstance().addChips(**this**.**bonusTotalWinChips**, **true**);*//参数二通知commonTitle和 spinUI 的 balance 更新；参数三为balance 更新时的音效*  
   *// 更新后的玩家金币数同步给slotMan*  
   **game**.**SlotMan**.getCurrent().updateCurChips();

   *//respin,freespin每次spin不走roundEnd过程，如有即时更新的bonus赢钱时，需判断一下客户端和服务器当次Spin赢钱金币是否一致，用来消除MonitorChipsMan中的记录，防止下次spin金币不一致警告；*  
   **game**.**eventDispatcher**.dispatchEvent(**game**.**monitorEvent**.**CHECK\_CHIPS\_ON\_SPIN\_ROUND\_END**, **this**);  
}  
