## Q1\`25-slots-新增 Jenkins 管道

### 1、鉴于并行研发需求数增加，版本发布管道不够用，新增发布管道 Classic\_Debug\_Res6\_deploy、Classic\_Debug\_Res7\_deploy，DoubleHit\_Debug\_Res3\_deploy， 已整理到 Jenkins debug 页签中，删除了不需要的页签；

![image1](/assets/eee64093a7d035a8b64cab140af358cc.png)

### 2、完善了管道排队规则， release 管道与任意管道相斥，Debug\_Res 管道与 release 管道相斥，Debug\_ResX 管道与其他Debug\_ResX 管道相斥，相斥的管道同时发起任务会进入队列排队；

### 3、通知消息中追加外网 ali 域名访问地址，可在外部网络访问各测试资源服；

![image2](/assets/a6c850f3b4be2bc2c1c598bad78a54e0.png)

### 4、代码兼容版本节点：80accdd55c8049495a3ff3c7f8c8d92280f2e856

### 5、新增 Jenkins 发布管道操作方法：

* #### 选择从现有管道 copy 配置：   ![image3](/assets/906112407c8be394a3504544e1bb707c.png)![image4](/assets/e7c20622c24203a32dfcc7fd8f42745b.png)

* #### 修正管道命令：   ![image5](/assets/6be339fb30857ac73ac1038be37c98d6.png)![image6](/assets/2ac83161dba8ec0bf7921cb317020b58.png)

* #### 修正排队策略：   ![image7](/assets/e90ed7ca128e35435635ba39d5c654ae.png)

* #### 拷贝资源目录：   测试资源服务器：/usr/share/nginx/html，拷贝 wtc\_2 \-\> wtc\_7   拷贝打包机本地资源：LocalResources/，拷贝 wtc\_2 \-\> wtc\_7













