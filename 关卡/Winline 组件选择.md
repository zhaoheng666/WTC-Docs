### 一、选择规则：

### 根据subject\_tmpl\_xxx.json配置文件中是否存在 **specialPayTables** 选择**：**

**存在：**  
**config\[NewSlot.*ComponentType*.WIN\_LINE\] \= {creator: NewSlot.*ClassicWinLineComponent*};**

**不存在：**  
**config\[NewSlot.*ComponentType*.WIN\_LINE\] \= {creator: NewSlot.*WinLineComponent*};**

###  二、winline 服务器数据：

***![image1](/assets/1406489992245014c9ee29e16bdcd2b4.png)***  
原始字段：wl  
客户端解析后字段： winlines  
获取方式：winLineComponent.getAllWinLines()

### 三、前端通用实现逻辑说明：

#### ClassicWinLineComponent：

***1、lineIndex：用于索引subject\_tmpl配置中的 lines，确定坐标；***  
***2、num：用于索引subject\_tmpl配置中的 specialPayTables；***  
***3、matchColMask：col掩码，用于控制前 x 列参与赢钱，需开启 machineConfig.supportMatchColMaskWinLine \= true 配合使用；***  
***4、winRate：该赢钱线实际赔率；***

***specialPaytables\[num\]：***  
***type：用于区分多轮盘，0:单轮盘，1:多轮盘;***  
***symbols：匹配参与赢钱的 symbols；***  
***pays：暂无使用；***

#### WinLineComponent：

***1、lineIndex：用于索引subject\_tmpl配置中的 lines，确定坐标；***  
***2、num、matchColMask 无效，不检查 symbols 和掩码；***  
***3、winRate：该赢钱线实际赔率；***

### 四、常见问题特征：

#### 1、播 win 动画，linesBlinkComponent 报错 undefined；

	检查 **config\[NewSlot.*ComponentType*.WIN\_LINE\]，应**使用ClassWinLineComponent而不是用WinLineComponent；

#### 2、只有赢钱线，没有 symbol win 动画：

	***specialPaytables*** 前后端不一致，跟服务器同步一下；¡

