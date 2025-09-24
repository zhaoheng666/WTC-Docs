# Q4\`24-Slots- websocket 协议压缩 Gzip-程序

#### 修订人：赵恒	 	修订时间： 2024年12月19日

#### 版本节点：classic\_vegas\_cvs\_v777\_gzlib

#### 投放分支：

## 一、概念、术语、类型约定（ 后文以此为准）：

---

#### Gzip：GNU zip 基于 DEFLATE 算法；无损压缩；跨平台；压缩比率高；解压速度快；网络传输效率提升； 网页内容压缩,日志文件压缩,数据库备份压缩,软件包分发;API 响应压缩；

#### 前端 pomelo 库：

"@me2zen/pomelo-cocos2d-js@0.1.14"  
\- "@me2zen/pomelo-jsclient-websocket": "^0.1.5",  
– "@me2zen/pomelo-protocol": "^0.1.6",

## 二、需求：

---

#### 服务器回传数据做 gzip 压缩：

##### 1、降本增效；

##### 2、高频、大数据量协议，传输、响应压缩；

## 三、实现方法：

---

### 1、增加控制字段 openGzip：

##### 前后端约定并保持一致

![image1](http://localhost:5173/WTC-Docs/assets/1758727509956_de31dcfe.png)  
![image2](http://localhost:5173/WTC-Docs/assets/1758727509957_4ebe24e0.png)

### 2、路由分离： 修正 protocol route，需支持压缩的协议，增加 \_gzip 路由；

##### 前后端约定并保持一致：

##### 原因：客户端收到返回协议，经过 decode 后的 msgbody 统一为 Uint8Array 类型，无法仅通过 msgbody 类型区分是否为需解压数据；

![image3](http://localhost:5173/WTC-Docs/assets/1758727509958_329a2c4e.png)

### 3、后端 gzip 压缩： 在约定开启 gzip 的协议返回前，对协议进行 gzip 压缩；

[Q4'24-Center-Tech-Slots-Slots压缩](https://docs.google.com/document/d/1ayLhQ9wSB5iCw4gsAVoGBcs6JtgyRaZ261QaCeAVd2I/edit?usp=sharing)

### 4、前端 gunzip 解压： 修正 pomelo-jsclient-websocket 库源码，根据返回协议的 route，做 gunzip 解压：

##### **前端协议代码响应路径：**

webcocket.onMessage  
Pomelo.Package.decode  
Pomelo.processPackage  
Pomelo.onData  
Pomelo.Message.decode  
Pomelo.doCompress  
Pomelo.processMessage  
Pomelo.onProtocol  
… 业务层

##### **核心修改：**[pomelo-client.js](https://drive.google.com/file/d/1kkaz5K30y97Ro3h6jlF2F48zgeo_sHNF/view?usp=sharing)

var onData \= function(data) {  
 var msg \= Message.decode(data);

 if(msg.id \> 0){  
   msg.route \= routeMap\[msg.id\];  
   delete routeMap\[msg.id\];  
   if(\!msg.route){  
     processMessage(pomelo, msg);  
     return;  
   }  
 }

 msg.body \= deCompose(msg);

 if(msg.route && msg.route.indexOf && msg.route.indexOf("\_gzip") \> \-1) {  
   zlib.gunzip(new Buffer(msg.body), function (error, unzip\_d) {  
     if (error) {  
       processMessage(pomelo, msg);  
       console.warn("gunzip error:", msg);  
       return;  
     }

     // console.warn("pomelo gunzip result:", msg.route, Protocol.strdecode(unzip\_d));  
     msg.body \= JSON.parse(Protocol.strdecode(unzip\_d));  
     processMessage(pomelo, msg);  
   });  
   return;  
 }

 processMessage(pomelo, msg);  
 //\#endregion  
};

var deCompose \= function(msg) {  
 var route \= msg.route;

 //Decompose route from dict  
 if(msg.compressRoute) {  
   if(\!abbrs\[route\]){  
     return {};  
   }

   route \= msg.route \= abbrs\[route\];  
 }

 if(protobuf && serverProtos\[route\]) {  
   return protobuf.decodeStr(route, msg.body);  
 } else if(decodeIO\_decoder && decodeIO\_decoder.lookup(route)) {  
   return decodeIO\_decoder.build(route).decode(msg.body);  
 } else {  
   //\#region Support gunzip compression  
   if(route && route.indexOf && route.indexOf("\_gzip") \> \-1) {  
      return msg.body;  
   }  
   //\#endregion

   return JSON.parse(Protocol.strdecode(msg.body));  
 }

 return msg;  
};

### 5、\[附加\] 日志上报接口压缩：

##### 服务器：

![image4](http://localhost:5173/WTC-Docs/assets/1758727509960_81c9c4f0.png)

##### 客户端：

var headers \= {};  
headers\["Content-Type"\] \= "application/json;charset=UTF-8";  
headers\["Content-Encoding"\] \= "gzip";  
var zlib \= require("zlib");  
zlib.gzip(JSON.stringify(sendObj), function (error, data) {  
   HttpClient.doPost(url, data, headers, function (error, txt) {  
   if (error) {  
       cc.log("HttpClient doPost error:" \+ error \+ ", " \+ txt);  
   }  
   });  
});

## 四、注意问题：

---

#### 1、Slots 前端并没有使用 pomelo-cocos2d-js，而是直接使用其依赖库 pomelo-jsclient-websocket，pomelo-cocos2d-js 本身只用来做依赖导入；

#### 2、Slots 前端并没有基于 EventEmitter 重新封装 Pomelo 类；而是直接使用了 window.pomelo ，window.pomelo 指向 pomelo-jsclient-websocket 库，通过 pomelo.on 注入基本的响应事件；

#### 3、Npm包维护问题：

#### 3.1、修改 npm 包 git 引用地址；需要注意，git 读取权限和项目仓库权限绑定；

#### 3.2、npm提交一个新版本；需要对 pomelo-cocos2d-js，pomelo-jsclient-websocket 同步提交版本，避免影响其他已经在使用的项目；

#### 4、Slots-Native 端使用的 spiadermonkey 引擎，对 sync 语法支持有限，尽量使用 zlib.gunzip();

#### 5、注意检查 pomelo 库版本差异，注意检查前后端 deCompress 代码差异；

#### 6、gzip 适合压缩文本文件，图片、视频等已压缩文件不适合再压缩；

#### 7、gzip 可定义压缩级别，压缩级别越高 CPU 消耗越高；需平衡压缩率和 CPU 资源消耗；

#### 8、小文件不适合 gzip 压缩；

#### 9、避免重复压缩；

## 五、验证、自测：

---

### 效果验证：

##### 对比工具：Chrome Debug Tool \-\> 网络 \-\> WS ｜native \-\>  [charles 使用说明](https://docs.google.com/document/d/13qhNSaPfDM6lhDQXUUHIBHIqsGNDFdeGtAEXFO03cGs/edit?usp=sharing)

![image5](http://localhost:5173/WTC-Docs/assets/1758727509961_09ae25c0.png)

#### 1、相同服务器，相同等级账号，login协议对比：

压缩前：2.5K，压缩后：1.4K

#### 2、同一个服务器、相同等级账号、相同关卡、相同结果，enter\_room协议对比：

压缩前：9.1K，压缩后：2.1K

#### 3、同一个服务器、相同等级账号、相同关卡、相同结果，spin协议对比：

压缩前：1.4K，压缩后：464B

### 测试点：

- [ ] #### 1、涉及压缩的协议；（主要）

- [ ] #### 2、后端主动推送协议是否正常；（主要）

- [ ] #### 3、native 相关协议是否正常；（主要）

- [ ] #### 4、极端条件测试：弱网；（次要）

- [ ] #### 5、新老包兼容测试；（次要）

- [ ] #### 6、服务器升级，客户端不更新测试；（次要）

## 六、补充：

npm git 仓库：  
[https://github.com/LuckyZen/pomelo-cocos2d-js](https://github.com/LuckyZen/pomelo-cocos2d-js)  
[https://github.com/LuckyZen/pomelo-jsclient-websocket](https://github.com/LuckyZen/pomelo-jsclient-websocket)  
[https://github.com/LuckyZen/pomelo-protocol](https://github.com/LuckyZen/pomelo-protocol)









