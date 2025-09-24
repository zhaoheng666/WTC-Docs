# 新版收集系统SOP操作手册(s19)

旧版操作文档：[Q2'24-Slots-收集系统赛季更新操作-程序.pdf](https://drive.google.com/file/d/1iLh3GWGtb7LwNiwkcg_YKuPEAVNdBVaj/view)

# 1、代码调整

PATH:  src/social/model/CardSystemMan.js

this.maxSeasonId \= 19; //修改赛季ID

# 2、资源调整

## 2.1 音效&视频

card\_system\_lagload/mp3路径下新增BGM：cardsystem\_bgm\_sXX.mp3  
例：19赛季 card\_system\_lagload/mp3/cardsystem\_bgm\_s19.mp3

card\_system\_lagload/season\_main路径下新增赛季视频：card\_season\_video\_sXX.mp4  
例：21赛季 card\_system\_lagload/season\_main/card\_season\_video\_s21.mp4

## 2.2 配置文件

卡册名称配置：casino/card\_system/album/s\_XX/album\_name\_config.json  
卡片配置：casino/card\_system/cards/s\_XX/card\_names.json

如果没有相应的配置文件，可从之前的老赛季相应的位置复制。  
例：S19赛季   
卡册名称配置：casino/card\_system/album/s\_19/album\_name\_config.json  
卡片配置：casino/card\_system/cards/s\_19/card\_names.json	  
	（新赛季的卡册和卡片的配置文件找策划去要，目前为@马新蓝）

### 2.2.1修改card\_names.json

	替换ID，name、playerWordTitle、playerWordDesc，其中playerWordTitle、playerWordDesc两个字段为第一卡册独有

name：卡片名称  
	playerWordTitle：一般也为卡片名称  
	playerWordDesc：新赛季文档中的玩家寄语  
banner：卡册卡片上的飘带  
border：卡册卡片后面的底框  
![image1](http://localhost:5173/WTC-Docs/assets/1758727509559_151d0b09.png)

### 2.2.2修改album\_name\_config.json

![image2](http://localhost:5173/WTC-Docs/assets/1758727509560_846bf82b.png)

tips：这里可以使用正则表达式快速清理之前的配置，按住鼠标滚轮拖动，可以同时修改多行，一定要注意的是找对路径，修改资源文件中的json而不是发布后的，要不再次发布的时候修改会被覆盖掉。  
![image3](http://localhost:5173/WTC-Docs/assets/1758727509562_6582c8ab.png)

寄语playerWordDesc在实际使用时，存在过长需要手动换行的情况，这个时候可以通过修改CardInfoController.js文件中的initCard方法，根据情况进行调试，每次只会生效一条，修改后，再复制回card\_names.json的playerWordDesc中。  
![image4](http://localhost:5173/WTC-Docs/assets/1758727509563_c105ec75.png)

## 2.3 赛季资源处理

### 2.3.1 清理老资源，发布新资源

在以下路径中查找上个赛季s\_XX的资源，并且删除掉，并检查新赛季资源  
dynamic\_feature/card\_system；casino/card\_system；card\_system\_lagload

### 2.3.2 处理plist文件

casino/card\_system/entrance/card\_system\_entrance.plist解包，删除旧资源，再重新打包plist（这里也可以找美术处理）

## 2.4 闪卡和限时卡册

 	s19赛季，跟美术@李强咨询过，这部分资源后面由美术那边进行替换和添加处理，程序可以不用操心这个地方了。

# 3、资源部署

## 3.1 赛季主体资源

card\_system\_lagload  
casino/card\_system  
dynamic\_feature/card\_system

## 3.2 coupon资源

slot/lobby/coupon/card\_pack\_newseason\_cardpack（coupon）

## 3.3 激励卡包图标资源

common/activity/activity\_card\_wonder\_pack\_s11.plist  
common/activity/activity\_card\_wonder\_pack\_s11.png

# 4、其他问题

### 4.1 

引用资源报错，一般是因为ccb引用的是之前赛季的资源，查找对应位置修改为当前赛季即可。

### 4.2

 	运行之后打开卡册，发现会出现board，item之类的报错，可能是由于配置文件导致的，检查album\_name\_config.json和card\_names.json两个配置是否为最新赛季。

### 4\.3 

数据接口：s2c\_get\_game\_feature

### 4\.4

限时卡册图标：card\_system\_lagload/card\_limited\_set\_2024\_new\_year/card\_limited\_set\_2024\_new\_year\_cards\_bg.png  








