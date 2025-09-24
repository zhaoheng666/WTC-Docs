# Q1\`25-Slots-android随机崩溃问题优化记录-程序

###### *程序向的优化、重构，需记录版本迭代*

# version 1.0：

#### 修订人： 赵恒	 	修订时间：  2025.1.24

#### 版本节点：

#### 投放分支： classic\_vegas\_cvs\_v781\_dh\_ios\_hot 子仓库分支:  classic\_vegas\_native\_cv\_100102

## 一、优化前 android 包情况：

---

### 1、用户感知崩溃率：

### 稳定在 5%+，缓慢上升；

### 升级 android sdk target 33 后迅速飙升至 %7-%8；

### 升级 android sdk target 34 后一度飙升到 13.4%；

### ![image1](http://localhost:5173/WTC-Docs/assets/1758727509575_cdb9e24f.png)

### 2、android 用户占比：

### CV：22%+  DH：28%+

### 3、问题排查历史记录：

[https://www.wolai.com/fegnze/5zbad1gTEoBFVaS2xzHuCY](https://www.wolai.com/fegnze/5zbad1gTEoBFVaS2xzHuCY)

## 二、优化记录：

---

### 24 年 Q4 期间，陆续做了一些相关工作：

#### 1、 接入firebase Crashlytics 替代 bugly；

#### 2、 通过 firebase crashlytics 监控到一些比之前 bugly 更详细的 crash 堆栈，处理了几个问题； 其中影响最大的可能是一个数组越界的问题，跟点击事件的分发有关，亚闯那边对 native 层的代码做了下数组越界的保护；

#### 3、 引擎升级，目前和 TP 那边的版本保持一致；

#### 4、 做过几次 sdk 升级的工作；

#### 5、 内存泄露的优化；

### 最终于 2025.1.1 前后，推送到线上，目前用户感知崩溃率得到了明显抑制；

## 三、结果评估：

---

#### 1、google console 总体走势：

#### ![image2](http://localhost:5173/WTC-Docs/assets/1758727509576_48dca377.png)

#### 2、google console 中最新发布版本的崩溃率、及所有版本均值走势：

![image3](http://localhost:5173/WTC-Docs/assets/1758727509577_72f63f7b.png)

#### 3、firebase cashlytics 中未遇到崩溃的用户占比走势：

![image4](http://localhost:5173/WTC-Docs/assets/1758727509579_4af03417.png)

#### 4、firebase cashlytics 中监控到的最严重问题的走势：

![image5](http://localhost:5173/WTC-Docs/assets/1758727509580_76cd7129.png)

##### 可以看在更包后，曲线极速下降，并且我们在 firebase 并未找到其他大规模异常； 但是，受限于某些玩家死活不更包，这个问题仍然无法归零；

## 三、后续规划：

#### 计划在 25 年 Q2 阶段，待新包数据稳定之后，我们会针对监控到的一些高频问题再做一次集中排查，期望可以将 crash 率控制在不良阈值以下；

# version 2.0

#### 修订人：	 	修订时间： 

#### 版本节点：

#### 投放分支：

## 一、概念、术语、类型约定（ 后文以此为准）：

---

## 二、优化目的：

---

## 三、优化方案：

---

## 四、实施细节：

---

## 五、结果评估：

---

## 六、影响范围、注意事项：

---

## 七、测试要点：

---

- [ ] 









