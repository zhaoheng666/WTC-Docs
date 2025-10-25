# Q4\`24-Slots-FB-Canvas-沙盒支付

## 操作人员：王建、李沂峰

## 1、Meta developer 后台添加角色：

#### 方法：[Q3’24-Slots-Facebook Canvas 测试服添加用户身份-程序](https://drive.google.com/file/d/1os2BRKI4Oq45sj0ZUFIVT-sPVrK-U1XL/view?usp=sharing)

## 2、Meta developer 后台添加 Web Payment Tester：

![image1](/assets/8eb74cd6eca14d57f42032ab6edd26ce.png)

## 3、确认支付页面显示“正在测试”，否则，回 1、2 步：

![image2](/assets/2e51cc72f855a62be30800893d2b9ce6.png)

## 4、首次测试，需要完成一次信息校验：

#### 卡号：4242424242424242 （ 42 开头，后边随意）

#### MM/YY：有效期，大于本年就行

#### CVV：任意三个数字

![image3](/assets/52debd2e2e3cdea5f3515a5a1365a78b.png)

## 5、有概率请求失败，重试、直到出现 Test Payment 按钮

![image4](/assets/8f0ccab027416c3f9498d70ef814357f.png)

![image5](/assets/42bab8a7bbb414dffe68818bf005ef37.png)

![image6](/assets/d00280f4692f61ba7262aac976601f3c.png)

## 6、支付完成后，FB 会推送订单邮件：

#### 有延迟，几分钟到几个小时不等；

#### 作用不大、知道是沙盒支付产生的邮件就行；

![image7](/assets/633f0b9d0e1df83e83b9f712df8262fb.png)













