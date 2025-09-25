## **问题表现：**

	jackpot挂点图标压暗的效果明显比轮盘图标更暗，  
	![image1](http://localhost:5173/WTC-Docs/assets/1758727509842_97aeb2ca.png)

## **原因：**

如果启用了ccbSymbol，SymbolLayerComponent通用的图标压暗方法setOpacityToAllSymbos中，会调用图标SymbolController的setHRNodeColorAndOpacity方法，导致hr挂点图标被压暗了两次。（看代码逻辑貌似只要启用了isCCBSymbol \= true，必然会导致这个问题。）

## **解决办法：**

### 方法一：

在自己所在关卡中，重写SymbolController.prototype.setHRNodeColorAndOpacity方法，取消所有操作即可，在machineConfig.symbolControllers中注册修改后的SymbolController  
	![image2](http://localhost:5173/WTC-Docs/assets/1758727509843_338b6c97.png)	![image3](http://localhost:5173/WTC-Docs/assets/1758727509844_65ba5647.png)

### 方法二：

	重写SymbolLayerComponent.setHRNodeColorAndOpacity方法，在重写的方法中，删掉下图中红框的代码即可。（**不建议这种方式**，后续计划将这段通用代码删掉，验证后如果不影响之前关卡的话，会直接在SymbolLayerComponent中删掉这段代码，**记录于2024.10.24**）  
	![image4](http://localhost:5173/WTC-Docs/assets/1758727509846_04c6f407.png)







