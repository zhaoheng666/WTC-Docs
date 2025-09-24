## Q1\`25-slots-新增 Jenkins 管道

### 1、鉴于并行研发需求数增加，版本发布管道不够用，新增发布管道 Classic\_Debug\_Res6\_deploy、Classic\_Debug\_Res7\_deploy，DoubleHit\_Debug\_Res3\_deploy， 已整理到 Jenkins debug 页签中，删除了不需要的页签；

![image1](http://localhost:5173/WTC-Docs/assets/1758727509565_13041f5e.png)

### 2、完善了管道排队规则， release 管道与任意管道相斥，Debug\_Res 管道与 release 管道相斥，Debug\_ResX 管道与其他Debug\_ResX 管道相斥，相斥的管道同时发起任务会进入队列排队；

### 3、通知消息中追加外网 ali 域名访问地址，可在外部网络访问各测试资源服；

![image2](http://localhost:5173/WTC-Docs/assets/1758727509566_8b34e025.png)

### 4、代码兼容版本节点：80accdd55c8049495a3ff3c7f8c8d92280f2e856

### 5、新增 Jenkins 发布管道操作方法：

* #### 选择从现有管道 copy 配置：   ![image3](http://localhost:5173/WTC-Docs/assets/1758727509568_4db9d380.png)![image4](http://localhost:5173/WTC-Docs/assets/1758727509569_7a07bd4c.png)

* #### 修正管道命令：   ![image5](http://localhost:5173/WTC-Docs/assets/1758727509571_afc56516.png)![image6](http://localhost:5173/WTC-Docs/assets/1758727509572_92c301d1.png)

* #### 修正排队策略：   ![image7](http://localhost:5173/WTC-Docs/assets/1758727509573_0e23fa8a.png)

* #### 拷贝资源目录：   测试资源服务器：/usr/share/nginx/html，拷贝 wtc\_2 \-\> wtc\_7   拷贝打包机本地资源：LocalResources/，拷贝 wtc\_2 \-\> wtc\_7













