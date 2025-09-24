# DH线上crash-ProgressTimer::initWithSprite问题

![image](http://localhost:5173/WTC-Docs/assets/1758174593042_8f4d94b1.png)

### 目前掌握的一手信息：

1、无法复现，ios、android 都有；

2、玩家有 start_after_crashed 记录，有正常游戏操作记录；

3、崩溃数据在 3.1 到达峰值后自然回落；

4、按堆栈定位到两处逻辑： a、hourlyBonus 大厅入口上的进度条（DH 特有）；b、HighRoller 大厅入口上的进度条；

5、cv 没有问题，排除 b 处逻辑问题；

6、19 年逻辑，后续未做变更，相关资源近期无变更；

---

### 首次修正，问题未解决：

##### a、hourlyBonus 大厅入口

> removeFromParent 改为 false，问题未解决；

![image](http://localhost:5173/WTC-Docs/assets/1758174593043_001fc221.png)

##### b、HighRoller 大厅入口

> 增加 native object 检查

![image](http://localhost:5173/WTC-Docs/assets/1758174593044_aaadc11d.png)

### 解决方案：

#### 分析：

1、无效的 native 节点：

`节点数组循环中 remove 节点，原始节点树已经发生改变，导致 js 数组存的对象和 native object 不匹配，或节点树与渲染树不同步`

2、js & native 内存管理机制细节变更：

`node 环境变更等因素，影响到 js & native 内存管理细节、触发 gc 的时机、代码执行效率等；`

#### 措施：

1、增加类型保护、增加 native 对象检查；

2、拷贝使用节点对象，避免在数组循环中操作 remove；

3、延后 remove；

![image](http://localhost:5173/WTC-Docs/assets/1758174593045_c413730f.png)

![image](http://localhost:5173/WTC-Docs/assets/1758174593046_c6e9d271.png)

‍

### 分析二：

![image](http://localhost:5173/WTC-Docs/assets/1758174593047_13c80512.png)

![image](http://localhost:5173/WTC-Docs/assets/1758174593048_95262908.png)

![image](http://localhost:5173/WTC-Docs/assets/1758174593048_5dbcda77.png)

#### 1、按照堆栈分析，问题只能出现在 sp->getTexture();否则堆栈至少应该多一层；

#### 2、android 堆栈有明显的 null 指针，所以仍旧定位是 removeFromParent 问题；

    但仍让无法解释“为何突然出现问题”

#### 3、检查 browserify 导出的 js 文件：

版本一（当前线上）：

```js
(function e(t, n, r) { ... 内部代码 })({ ... 内部代码 }, {}, [ 377 ]);
```

 版本二 (打包机坏之前的版本)：

```js
(function() { function e(t,n,r){ ... 内部代码 } return e })()({ ... 内部代码 }, {}, [ 377 ]);
```

#### 对比：

版本一：IIFE 立即执行函数，browserify@`11.2.0`

版本二：包裹了一层匿名函数，涉及作用域、闭包问题，可能更合理一点；不清楚从哪个版本开始，本地用的版本 browserify@12

‍
