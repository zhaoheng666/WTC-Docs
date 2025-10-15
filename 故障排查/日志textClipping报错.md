# Q1\`25-Slots-load报错\[.textClipping\]

###### *记录常见问题的处理过程*

## 一、问题描述：

![image1](/assets/1758727509582_a46b233a.png)

## 二、原因：

### .textClipping 类型的文件是 macos 用来保存拖出的文本片段用的，通常都是由于拖动文件的时候有连点，触发了更名，实际拖动的是文件名而不是文件本身导致的；

![image2](/assets/1758727509583_554c0491.png)  
![image3](/assets/1758727509584_15550e5c.png)

## 三、处理方法：

### 1、.textClipping 以后遇到这个拓展名的文件记得删掉；

### 2、.textClipping 类型文件 webstorm 如果未经配置默认是打不开的，需要切到目录里删除；

### 3、已添加忽略到 .gitignore；

### 4、添加到 resource\_list 忽略列表: (58926cf)

![image4](/assets/1758727509586_441a9196.png)







