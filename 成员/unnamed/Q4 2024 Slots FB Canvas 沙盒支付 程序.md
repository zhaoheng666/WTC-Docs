# Q4\`24-Slots-FB-Canvas-沙盒支付-程序

## 操作人员：王建、李沂峰

## 1、Meta developer 后台添加角色：

#### 方法：[Q3’24-Slots-Facebook Canvas 测试服添加用户身份-程序](https://drive.google.com/file/d/1os2BRKI4Oq45sj0ZUFIVT-sPVrK-U1XL/view?usp=sharing)

## 2、Meta developer 后台添加 Web Payment Tester：

![image1](http://localhost:5173/WTC-Docs/assets/1758727509857_b5767297.png)

## 3、确认支付页面显示“正在测试”，否则，回 1、2 步：

![image2](http://localhost:5173/WTC-Docs/assets/1758727509857_d279d208.png)

## 4、首次测试，需要完成一次信息校验：

#### 卡号：4242424242424242 （ 42 开头，后边随意）

#### MM/YY：有效期，大于本年就行

#### CVV：任意三个数字

![image3](http://localhost:5173/WTC-Docs/assets/1758727509858_43709f02.png)

## 5、有概率请求失败，重试、直到出现 Test Payment 按钮

![image4](http://localhost:5173/WTC-Docs/assets/1758727509860_8618e207.png)

![image5](http://localhost:5173/WTC-Docs/assets/1758727509861_e1bf8c04.png)

![image6](http://localhost:5173/WTC-Docs/assets/1758727509864_48be5ac2.png)

## 6、支付完成后，FB 会推送订单邮件：

#### 有延迟，几分钟到几个小时不等；

#### 作用不大、知道是沙盒支付产生的邮件就行；

![image7](http://localhost:5173/WTC-Docs/assets/1758727509865_104b4365.png)













