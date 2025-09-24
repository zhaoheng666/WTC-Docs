## UI 模板库插件重构：

### 重构目的、解决的问题:

1、旧的模板库插件部分实现与最初的设计方案不符；  
2、解决旧的模板库插件各种报错问题，包括目录嵌套报错及其他报错；  
3、增加过滤、删除 plist 中冗余资源功能；  
4、内置关键字替换，解除与活动名的关联，解决旧的模板库插件与活动强关联、不够灵活的问题；  
5、增加模板库选择列表，方便将选中模板一键应用到任何目录；  
6、重新整理通用资源链接，添加 activity 链接，方便直接在模板库工程中挑选、生成所需模板；

## 使用说明：

### 一、创建模板：

![image1](http://localhost:5173/WTC-Docs/assets/1758727509756_1198455c.png)

#### ![image2](http://localhost:5173/WTC-Docs/assets/1758727509758_e0522cc8.png)

![image3](http://localhost:5173/WTC-Docs/assets/1758727509759_f826d1f0.png)

#### 命名规范：

\[一级分类\]\_\[二级分类\]\_\[三级分类\]\_\[tpl\]\_\[版本\]  
一级分类:  slot | casino | common 等,活动如无必要可省略一级分类 activity  
二级分类：功能性命名，tips ｜title｜rank 等  
三....级分类：额外子类型命名，spinning ｜bet\_lock 等  
\_tpl: 自动追加字符，避免与目标目录的原始文件重名  
eg：  
activity\_rank\_tpl\_v1  
activity\_main\_title\_tpl\_v1  
slot\_tips\_spinning\_tpl\_v1  
slot\_tips\_bet\_lock\_tpl\_v1

#### 重点：

生成模板以 CCB 为单位，递归处理其嵌套 CCB，  
如果一个功能模块包含多个 CCB，可将关联 CCB 拖入到主 CCB，实现一键生成；  
eg：排行榜和排行榜列表 item  
![image4](http://localhost:5173/WTC-Docs/assets/1758727509762_78374253.png)

#### 注意：

1、如果输入的 目标名和替换关键字名有重合，将会忽略重复的关键字替换；  
2、如果目标 CCB 为通用（common、slot、casino）资源目录中的 CCB，将会忽略关键字替换，指拷贝 CCB 到模板库，以避免通用资源引用分叉冗余；  
3、默认关闭了裁剪，如果遇到图集过大无法打包会尝试开启裁剪重新打包；  
![image5](http://localhost:5173/WTC-Docs/assets/1758727509763_9dde99db.png)  
因为只存在删减的情况，不大可能出现裁剪后仍无法打包的情况，但不排除美术通过手动打包的资源原本就超过 2048\*2048 的情况；遇到该情况，请手动拆解图集后打包，并修正模板库中的引用；

### 二、应用模板到任意目录：

![image6](http://localhost:5173/WTC-Docs/assets/1758727509765_bb8e23a7.png)  
![image7](http://localhost:5173/WTC-Docs/assets/1758727509766_1b423887.png)  
1、自动列举了模板库中所有已存在的模板，输入对应序号，回车；  
2、1-2 秒内执行完毕，看到应用完”成字”样后，到 cocosbuilder 中刷新目录；

\[注意\]：生成出来的文件默认追加了目标目录的相对路径，以避免与原始资源重名；













