## Link 玩法最后一次 spin levelup 进度条表现异常，赢钱不一致（缺失升级奖励）

### 表现：

1、Link 玩法触发轮，level 进度条更新，但未给升级奖励；  
2、Link 玩法最后一次 spin 时，leve 进度条重复跑了一次，但未给奖励；  
3、Link 结算后持续出现金币不一致提醒；

### 处理方案：

拿到服务器数据后，关闭经验立即刷新开关；条件自行区分；  
handleSpinResult: **function** () {  
   **this**.**receivedSpinResult**.**extraInfo**\[**"triggerSpecial"**\] \= **this**.**receivedSpinResult**.**extraInfo**\[**"isTriggerSpecial"**\];  
   **this**.\_super();

   **if** (\!**this**.**isLinkTriggered**) {  
       **this**.**triggerLinkAction**.parseRespinData();  
       **game**.**SlotMan**.getCurrent().setSyncExpNow(**false**);  
   }

   **this**.**triggerLinkAction**.generateExtraSpinResult();  
},

【注意】Link 玩法结束后，将经验立即刷新开关回置  
**if** (triggerData.**processTag** \=== **"SpecialGameProcess"** && \!**this**.**context**.nextIsRespin()) {  
   **this**.endLink(callback);  
   **this**.**context**.**isLinkTriggered** \= **false**;  
   **game**.**SlotMan**.getCurrent().setSyncExpNow(**true**);  
   **return**;  
}

