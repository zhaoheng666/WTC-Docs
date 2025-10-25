**AppchargeCheckout**

## 1、流程：

#### a、客户端初始化*AppchargeCheckoutInit —\>* 客户端向服务器请求 session 数据  *—\>* 服务器调用 Create Checkout Session API 返回给客户端（*sessionToken*、*checkoutUrl* ） —\> 客户端执行AppchargeCheckout 拉起支付页面 *—\> 支付页面完成支付操作* —\> *等待 Appcharge 服务器响应*

#### *b、等待 Appcharge 服务器响应*  —\> *Appcharge 服务器调用 webhook* —\> 服务器发放奖励 —\> 通知客户端展示到账

#### *c、等待 Appcharge 服务器响应* —\> *Appcharge 服务器通知 sdk 支付页面支付结果*

---

## 2、前端接入要点：（✅技术人员要注意这些）

* ### sdk 采用最新的 js 的语法，无法直接通过 npm 的方式导入sdk 代码库

  * #### 只能通过手动方式将 sdk 代码集成到项目里；
  * #### 如果 sdk 有更新，我们将无法自动获取；
  * #### 项目代码有 es5 语法校验，只能作为外部扩展脚本集成到项目中，集成灵活度不高，尤其是项目与 sdk 的交互过程；
* ### 代码 cv、dh 统一，通过开关控制，但添加了额外的 sdk 脚本文件，有额外得配置和发布脚本需要改，dh 搞的时候要注意一下；

  ![][image1]

---

## 3、评估  checkoutToken 安全性：（✅遇到明显的订单异常、封 IP）

* #### 前端 sdk 初始化必须要用；
* #### 目前看是可开的参数，但一样存在风险；
* #### 目前是服务器传过来的，但一样会被技术人员轻松拿到；
* #### 我们是否要做异常订单监控？   比如我去扒竞品参数做测试的时候，就被监控到了，竞品就把我们办公 IP 给封了

---

## 4、支付方式： （✅如果出现银行卡退单，先封银行卡，不停用 appcharge checkout）

![][image2]![][image3]

* **额外的三种方式都支持，打开、操作没有问题；但账号问题没有测试是否能到账；**
* **银行卡是默认的，关不了,是不是一样会出 triple 的问题？**

---

## 5、iframe 浏览器 cookie 问题，银行卡信息无法保存，其他付款方式 sdk 内部会做存储	（✅不用做，triple 也不支持保存，玩家习惯了）

因为是 iframe 嵌套到页面里的，浏览器限制直接使用 cookie，所以无法自动填充已经使用过的银行卡信息；
Appcharge 提供了一些参数，比如邮箱，可以在拉起支付页面的时候由sdk填充；
如果要接入，得王建那边带到 session 里去；
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 6、价格要不要做本地化？ （✅不需要，按汇率算下金额，不差太多就行，描述文案统一显示：Classic Vegas In-Store Items）

目前是直接走的 appcharge 的 auto locale 转化
![][image4]
-------------------------------------------------------

## 7、Appcharge 的其他 API 要不要接？官方控制台有显示订单等信息，但没有 api 那么详细； （✅暂时不做，主要用来做更详细的技术查询）

## 8、要不要调整 sdk 的位置？（✅可以接受，暂时不做偏移，等玩家反馈再定）

* 调整位置：iframe 保护，禁止父级页面调整内部元素
* 会有一个上移的过程，且下边遮罩有留空，我觉得效果不好
  ![][image6]
  ![][image7]

---

## 9、付款成功以后，我们游戏先到账，sdk 的状态同步慢的时候，到账过程会被压在下边； （✅可以接受）

## 10、有一些 sdk 内部的警告和错误，有可能无法消除，不影响游戏； 	（✅测试流程一切正常的话，可以不用处理）

## ~~11、不支持 native，需要的话要接入 native sdk（~~✅~~不考虑）~~

---

## 12、和 triple 的关系？取代还是优先？

#### （✅保留 triple，后端提供支付方式字段控制 apcharge 是否开启）

---

### 13、（补充）用内网 ip 访问方式不支持 google 支付方式，平台要求使用 https 访问

（✅测试资源服访问地址由 ip 改为 ali 域名，如：[http://10.10.31.14:8446/wtc\_2/](http://10.10.31.14:8446/wtc_2/)
改为 [https://ali-slots-res.me2zengame.com:8445/wtc\_2](https://ali-slots-res.me2zengame.com:8445/wtc_2)
或等提测后直接使用测试服链接 https://apps.facebook.com/classicvegasalpha/）
![][image11]
![][image12]

# 测试要点：

#### 1、银行卡、google、Link、paypal 支付流程；

#### 2、测试支付成功、支付取消、支付失败的表现；

#### 3、弱网环境支付流程是否能走完，有没有明显异常；

#### 4、各档位支付页面价格、描述，显示是否符合预期（抽检，大中小金额）；不同类型的支付项（抽检，商店的、活动的等）；

#### 5、浏览器兼容：找几个主流的看看（Edge），游戏都进不去的就pass，游戏能正常玩的测一下 appcharge；

#### 6、服务器 appcharge 开关；

#### 7、测试银行卡：

##### 邮箱：用自己的			//用来收订单邮件

##### 银行卡号：

4242 4242 4242 4242   		// 正常
4000 0000 0000 0002  		// 卡被拒绝
4000 0000 0000 9995  		// 余额不足
4000 0000 0000 0127   		// 盗刷风险
银行卡截止时间：12 / 28  	// 月份 / 年份，未来某个月份就行
银行卡 Code：123		// 随便 3 位数字
持卡人姓名：随便编个名字	// 尽量用英文名
国家地区：随便选		// 最好是美国


[image1]: http://localhost:5173/WTC-Docs/assets/4cdf0b38f6909214a220302e2c552f08.png
[image2]: http://localhost:5173/WTC-Docs/assets/e2af9fdcd99078d0b93f7e3ce43c9567.png
[image3]: http://localhost:5173/WTC-Docs/assets/2299ea35564ba3d0e16fba76f307262a.png
[image4]: http://localhost:5173/WTC-Docs/assets/3ae7fc6d5c2d0eb336ab67fbd17be3c5.png
[image5]: http://localhost:5173/WTC-Docs/assets/edff7d36917e1a49d756255be2a2efc0.png
[image6]: http://localhost:5173/WTC-Docs/assets/53fd38f104998c0811deb96691b40943.png
[image7]: http://localhost:5173/WTC-Docs/assets/b9146d933c2ac1230b22df480fcb5d50.png
[image8]: http://localhost:5173/WTC-Docs/assets/474a018e31bd8be4b57b602cf212d653.png
[image9]: http://localhost:5173/WTC-Docs/assets/ac7a05473c1f317a94de9a262c1f6f25.png
[image10]: http://localhost:5173/WTC-Docs/assets/4ea82c352a2a3bcd04cbe0c573e58c48.png
[image11]: http://localhost:5173/WTC-Docs/assets/26c70241ef3868700675407c6ee9eb6a.png
[image12]: http://localhost:5173/WTC-Docs/assets/ad4f081ff6d5205d7c16e5c44834c25a.png
