# fastSpin组件

# 美术要求

需要ccb中添加fastSpinUI ccb节点。  
   两种形式：  
       1、在main中引用ccb节点。（参考267关卡的ccb结构引用形式，直接引用slot/fast\_spin目录的通用资源即可）  
       2、在spinUI中嵌入ccb节点，（兼容后期可能融合到spinUI中的需求）。  
   无论哪种形式，fastSpinUI节点必须是一个独立的ccb。![image1](/assets/dbb94c71806fcc263d5d742055c91ade.png)

# 程序用法

   在关卡配置中开启开关，this.machineConfig.supportFastSpin \= true;  
![image2](/assets/0742745270a113663a6a43efa0fe3628.png)

   fastSpin控制组件：FastSpinComponent、UI控制器：FastSpinUIController

   editable\_config\_id.json配置中，panelSpinSchemeMap新增fastSpin对应索引id配置  
<!-- ![image3](/assets/1758727509592_8fe68dfc.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->





