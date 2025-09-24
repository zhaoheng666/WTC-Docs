# Q4\`24-Slots-SOP-新增 coupon 类型-程序

###### *常用的、可固化的业务操作流程规范，如某活动的换皮、赛季资源替换等*

#### 修订人：赵恒	 	修订时间： 2024-11-4

## 一、概念、术语、类型约定（ 后文以此为准）：

---

### coupon 类型:

#### i.   活动通用 coupon：				\[✅\]

#### ii.  早期 coupon：GiftsItemController，废弃; 	\[❌\]

#### iii. 现行 coupon：CouponItemController; 	\[✅\]

## 二、相关协议：

---

### 现行 coupon：

#### 奖励同步：s2c\_reward\_notice

#### 奖励领取：s2c\_claim\_key\_reward

### 活动通用 coupon：

#### 奖励同步：s2c\_get\_activities

#### 奖励领取:   c2s\_claim\_key\_reward

## 三、相关资源：

---

### 1、资源位置：

##### 默认资源位置：res\_xxx/slot/lobby/coupon/

![image1](http://localhost:5173/WTC-Docs/assets/1758727509942_6c267306.png)

### 2、效果图：

##### 待补

## 四、操作步骤 \- 现行 coupon：

---

### 1、确认资源：

##### 1.1、检查默认 coupon 资源；

##### 1.2、检查弹板资源，如果需求需要：

##### 1.3、注意检查冗余资源；

### 2、注册 coupon 类型：

##### 2.1、文件位置：src/social/enum/RewardType.js

##### 2.2、类型值由服务器确定；

##### 2.3、注册到 *RewardType*.isGiftType；

![image2](http://localhost:5173/WTC-Docs/assets/1758727509943_265e9dc1.png)

### 3、注册礼包 handler：

##### 3.1、创建领取弹板；【如果需要】

![image3](http://localhost:5173/WTC-Docs/assets/1758727509945_3c5b8e72.png)

##### 如果直接在 handler 中调用领奖弹板，需【注意】： 不要使用 game 变量,因为此时 game 变量尚未生成，采用 import 的方式引入所需文件，如 Util.inherits 方式继承；

##### 3.2、继承 GiftRewardHandler；

##### 3.3、重写领取方法，弹板后领取、或直接领取，逻辑自行组织；

![image4](http://localhost:5173/WTC-Docs/assets/1758727509947_3076b0ae.png)

##### 3.4、发送领取协议：

![image5](http://localhost:5173/WTC-Docs/assets/1758727509948_612c5980.png)

### 4、注册到通用 CouponItemController：

##### 4.1、初始化显示逻辑：initWith

##### 4.2、注册领取按钮响应：claimClicked

##### 4.3、注册本地默认 CCB 资源路径：getCCBPath

![image6](http://localhost:5173/WTC-Docs/assets/1758727509950_1f60e039.png)

### 5、关联 CouponItemController 到领奖中心（inbox）：

#### 追加类型判定：

![image7](http://localhost:5173/WTC-Docs/assets/1758727509952_63a1aa12.png)

## 四、操作步骤 \- 活动通用 coupon：

### 1、资源检查:

##### 1.1、检查活动 coupon 资源，默认资源位置：各活动资源目录中res\_xxx/activity/xxx\_xxx；

##### 1.2、检查弹板资源，如果需求需要：

##### 1.3、注意检查冗余资源；

### 2、注册 coupon 类型：

##### 2.1、文件位置：src/social/enum/RewardType.js

##### 2.2、类型值由服务器确定；

##### 2.3、注册到 *RewardType*.isGiftType；

### 3、定义、注册 CouponHanlder：

##### 3.1、创建领取弹板；【如果需要】

![image8](http://localhost:5173/WTC-Docs/assets/1758727509953_dfd8809b.png)

##### 如果直接在 handler 中调用领奖弹板，需【注意】： *不要使用 game 变量,因为此时 game 变量尚未生成，采用 import 的方式引入所需文件，如 Util.inherits 方式继承；*

##### 3.2、定义 handler:

type: RewardType.ACTIVITY\_INBOX\_WIDGET  
![image9](http://localhost:5173/WTC-Docs/assets/1758727509954_5c48175d.png)

##### 3.3、注册 coupon 关联事件：

![image10](http://localhost:5173/WTC-Docs/assets/1758727509932_94ac5ccd.png)  
![image11](http://localhost:5173/WTC-Docs/assets/1758727509934_47185027.png)

##### 3.4、activity 中重新 couponItem 创建接口：（此时 coupon 的 handler 为活动本身，需要重写的 coupon 通用方法直接在 activity 中重写）非常难看的实现方式；

![image12](http://localhost:5173/WTC-Docs/assets/1758727509935_bdcce9e8.png)

### 4、注册到通用 CouponItemController：

##### ![image13](http://localhost:5173/WTC-Docs/assets/1758727509936_15525e3c.png)

### 5、领奖、或触发玩儿法，根据需求实现：

![image14](http://localhost:5173/WTC-Docs/assets/1758727509938_095c2c92.png)

## 五、关键接口说明：

---

#### 1、关闭领奖中心：

game.eventDispatcher.dispatchEvent(game.commonEvent.UI\_CLOSE\_GIFTS\_BOX);

#### 2、打开领奖中心：

game.popupMan.popupGifts();

#### 3、领取成功、清理奖励：

this.\_reward && this.\_reward.getHandler() && this.\_reward.getHandler().clearReward(this.\_reward);

#### 4、清理过期奖励：（GiftRewardHandler 有封装，关闭领奖中心的位置有调用）

game.SocialMan.getInstance().clearExpiredRewards();

#### 5、更新inbox图标的红点：

##### game.eventDispatcher.dispatchEvent(game.commonEvent.GIFTS\_REWARD\_UPDATED);

#### 6、优先级、顺序：

重写XXXHandler.getSortPriority，数字越优先级越高，如果需要；

#### 7、设置大小、主要是高度：

重写XXXHandler.getSizeForSocialGiftItem，如果需要；

## 六、注意问题：

---

##### 1、通常 coupon 领取完成后需要自动关闭领奖中心；

##### 2、过期奖励需清除；

##### 3、如果有领取弹板，领取和关闭按钮都要触发领取；

##### 4、如果有领取弹板，领取、关闭按钮要屏蔽连续点击，且要相互屏蔽；

##### 5、排序：buff 永远在最上面显示；

## 七、命令、工具：

---

#### QA 管理工具-清理 inbox：

http://slots-team-test-server-v0.me2zengame.com:9090/qa/qa.php  
![image15](http://localhost:5173/WTC-Docs/assets/1758727509939_9d7021ba.png)![image16](http://localhost:5173/WTC-Docs/assets/1758727509940_eadb3bea.png)

## 八、验证、自测：

---































