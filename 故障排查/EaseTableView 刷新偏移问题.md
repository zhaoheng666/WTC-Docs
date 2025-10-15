

# EaseTableView创建刷新偏移问题

# 1、现象

	  
[EaseTableView创建刷新偏移问题.mp4](https://drive.google.com/file/d/1EqDBRVe6BnFZg3cRgGSeCmui26DcLAeV/view?usp=drive_link)

# 2、原因分析

![image1](/assets/1758727509646_18ffbd76.png)

tableView在创建的时候会获取当前的cellSize的总和然后设置ContentSzie,如果当前cell没满屏，那么会出现ContentSzie小于ViewSize,此时创建或者刷新的时候，setContentSizeOffset会偏移异常导致肉眼可见的cell移动的bug

# 

# 3、解决方案

![image2](/assets/1758727509647_fa12dfce.png)

设置contentSzie最小的宽度为ViewSize.width  
由于EaseTableView是一个通用组件，直接修改影响较大，所以本次加了\_enableFixViewsize的开关，后续上线验证稳定后直接再修正。

# 4、其他修改

   1、新增禁止滑动方法,可用于cell未满屏情况禁止滑动的相关需求  
  ![image3](/assets/1758727509648_c215d5e6.png)





