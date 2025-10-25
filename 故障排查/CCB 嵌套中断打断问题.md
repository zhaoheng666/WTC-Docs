# CCB嵌套时间线子CCB被打断问题

### **情况一、滚动列表;**

![image1](/assets/3ab047fc4fa0fc58c1ec581a7d62a983.png)

#### 

#### 解决办法:

##### 取消removeChild的cleanup，因为EaseTableView组件支持cell复用,会将cell添加到\_cellsFreed保持，并不需要立即释放;

![image2](/assets/20bee9e2d8cf178cc8170f73871f9f8a.png)

#### 另外定位到两个问题:

##### 1、EaseTableView组件,新创建,或没有list数据、排序等变更,不必调用reloadData;

![image3](/assets/7bc7c9895925c7645d5a09d507445b30.png)

##### 2、17年的语法错误

![image4](/assets/714af686fa99677d713df274309c7f7c.png)

### 情况二、节点违规操作产生预期外的动画属性;

![image5](/assets/e92c4424a4c32acf76a8a613384b6987.png)  
![image6](/assets/278033f3b802abc838cfea02c10d0d09.png)

#### 

#### 补充一点: 拷贝的带关键帧的节点,是与当前所属时间线有关的;

![image7](/assets/b62f5ed4776844da0b6e9986578bca0f.png)

#### **解决办法:** 

##### 移除子CCB,重新拖进去添加;

#### **需要动画注意的:**

##### 1、杜绝在CCB节点上做任何关键帧,是在必要的,也尽量直接做到子CCB里;

##### 2、尽量不要直接拷贝带关键帧的节点,同CCB内部也不行;

##### 3、杜绝在图片节点下挂CCB节点;

##### 4、这算是cocos的设计问题,但不是bug,遇到动画不播、播不完的问题,先检查1、2、3步骤;

##### 5、如果动画按步骤解决不了问题,给程序,查CCB该节点下是否有不该存在的动画属性animatedProperties;

## **补充一个场景：代码添加节点到场景后，autoplay 动画只播一轮，loop 被打断。**

### 

### **检查：**

### 是否使用了 RecyclePool 、或逻辑中存在针对动画节点的的 stopAllActions()操作；

![image8](/assets/4b8629ed7dab0610bc4652276389b925.png)

### **原因：**

### 时间线的 loop，依赖于\_animationCompleteCallbackFunc ，本质上这是一个 cc.sequence；虽然在节点 addChild 到场景（onEnter） 时正常触发了 autoplay，但其 loop 驱动逻辑已经被打断；所以表现上只播了一轮；

### **![image9](/assets/7624b1d8bda40557443dac4641ba1d44.png)**

![image10](/assets/20dae4f5a3181bc21e49571df71e6c48.png)

### **解决方案：**

#### 1、使用了内存池等，内部包含了 stopAllActions()逻辑时，在addchild 后代码调用一次playAnim；

#### 2、重新组织逻辑，剔除不必要的 stopAllAction() 逻辑；



















