## **adb\_sync\_natice.sh 使用说明：**

#### 命令：

cd WorldTourCasino/scripts/  
./adb\_sync\_native.sh res\_oldvegas

##### 说明：

* 默认只更新代码；  
* \+ res\_relative\_path 更新代码和指定资源（资源的相对路径）  
* 手机打开开发者模式 ，连接方式选文件传输

#### 生效条件：

* 脚本执行未出现 package not debugable 字样  
  * 如果出现，换包，部分 debug 包可能未启用 debugable 权限  
* 进入大厅出现 Local Deploy Mode 弹板  
  * 该脚本基于最新版本，如果使用该脚本启动时远程存在新的版本会优先走最新的版本更新，此时，重新执行一次该脚本即可；

## **fNOP 问题：**

### native loading 完卡 100%：**![image1](http://localhost:5173/WTC-Docs/assets/1758727509626_e0196471.png)**

#### 原因：browserify 版本过新，代码默认按照 es6 整合，spidermonkey 不兼容；

* #### 检查 browserify 版本，不要使用过新的版本，或者指定 es5 语法

* #### npm install browserify@11.2.0 \-g

---

## **【废弃】**

### **解决adb\_sync\_natice.sh 无法使用的问题：**

### **1、fNop 报错；**

#### **1.1 添加保护代码：**

![image2](http://localhost:5173/WTC-Docs/assets/1758727509627_5b7c0668.png)

#### **1.2将修正后的 jsb\_boot.js文件推送到手机：**

![image3](http://localhost:5173/WTC-Docs/assets/1758727509629_7e497a3d.png)

### **![image4](http://localhost:5173/WTC-Docs/assets/1758727509630_f064106c.png)**

### **2、每次重启后仍然重新去线上拉更新：**

#### **2.1修正 Config.js 配置，serverData.serverUrl是否跟ServerURLType.RESOURCES\_SERVER\_URL一致**

![image5](http://localhost:5173/WTC-Docs/assets/1758727509631_bc788245.png)

#### **2.2 把选服弹板公开出来，方便切换测试资源服，切换 manifest**

![image6](http://localhost:5173/WTC-Docs/assets/1758727509633_b8022bc3.png)











