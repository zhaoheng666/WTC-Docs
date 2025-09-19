# Q3`25-Slots-Jenkins 管道迁移+共享工程-程序

## Jenkins 管道迁移

![250813185616266.png](http://localhost:5173/WTC-Docs/assets/1758174594563_bf1986e0.png)​

- #### Debug **管道迁移：**

  Classic\_Debug\_Res5\_deploy (Exclusive)，
  Classic\_Debug\_Res6\_deploy (Exclusive)，
  Classic\_Debug\_Res7\_deploy (Exclusive)，
  DoubleHit\_Debug\_Res2\_deploy (Exclusive)
  迁移到组内共享机器（机器性能有限，暂时只迁移 4 个）

  **迁移后：** 
  各管道独占 workspace，互不影响、不排队、CV、DH 发版期间均可使用；

- #### **新增管道：**

  DoubleHit\_Debug\_deploy (Exclusive)
  新增到组内共享机器，与原管道 DoubleHit\_Debug\_deploy 、DoubleHit\_Release\_deploy 互斥（排队）， CV 发版期间可用；

- #### **<u>解决的问题</u>**​ **：**

  1. <u>疏解原打包机磁盘压力，减少故障率；（释放空间 100G+）</u>

  2. ​<u>研发期版本可随时发布，不用再相互等，不用再等发完版；</u>

  3. <u>CV 发版期间不再影响 DH 内容提测；</u>

‍

## 共享工程

- #### 视频教程：

  [https://ghoststudio.feishu.cn/file/Z7uSbh5kPo2CBuxbDgvcsbYWnDh?from=from_copylink](https://ghoststudio.feishu.cn/file/Z7uSbh5kPo2CBuxbDgvcsbYWnDh?from=from_copylink)

  <video controls="controls" src="https://ghoststudio.feishu.cn/file/Z7uSbh5kPo2CBuxbDgvcsbYWnDh" data-src="" style="width: 714px; height: 357px;"></video>

  [视频文本](#20250908113936-3zoychu)
- #### 多人远程共享：

  1. 组内打包机部署完整的开发环境；
  2. 代码编辑器使用 TraeCN，添加更友好的操作辅助按钮；
  3. 不建议直接在共享机器提交改动；

- #### <u>解决的问题</u>：

  1. <u>美术、动画产出无法及时预览，反复盲调、严重影响自身及上下游工作；</u>
  2. <u>部分基础配置策划无法直接调试、预览，找程序现场调效率低；</u>

‍

## 记录：

- #### 1. slots 组内打包机：

  10.10.31.23
  user：slots
  password: slots

- ##### 2、工作目录：`/Users/slots/work`​

  Jenkins 工作目录：`normal_builder`​

  第三方依赖：`Software`​

  nginx 静态托管：`localResources`​

  Jenkins 美术工程：`WorldTourCasinoResource_builder`​

  **公共工程：（主要给美术、策划用）**

  公共代码工程：`WorldTourCasino`​

  公共美术工程：`WorldTourCasinoResource`​
- #### 3、Jenkins 管道迁移方案：

  - 拆分、同步工作目录到共享机，各管道配备专属工作目录；
  - 原打包机 Jenkins 命令改造为 ssh ，远程调用共享机本地脚本；
  - 共享机搭建 nginx 静态托管，作为新的内网站点使用，404 转发测试资源服；

- #### 4、工具辅助：

  尽量配合抹平使用障碍，期望是美术、动画这边能尽可能的使用共享机做自测；

  ![250814182608816.png](http://localhost:5173/WTC-Docs/assets/1758174594842_0a7bc741.png)​

  - 快速打开目录；

  - 一键打开 CCB 工程；

  - 一键打开指定关卡 CCB 工程；

  - 一切重置共享机的工作目录；

- #### 5、安全设置：

  ​`WorldTourCasino` `WorldTourCasinoResource` 启用 git pre-commit 钩子，共享机禁止提交；

‍

## 使用说明：

- #### 1、连接：

  ![250815101400710.png](http://localhost:5173/WTC-Docs/assets/1758174595218_381101cd.png)![250815101809695.png](http://localhost:5173/WTC-Docs/assets/1758174595631_6d65d696.png)
  ![image](http://localhost:5173/WTC-Docs/assets/1758174596003_0fe844cd.png)
  ![1755225233416.png](http://localhost:5173/WTC-Docs/assets/1758174596004_1d936397.png)​

- #### 2、重置工作区：

  ![250815142225985.png](http://localhost:5173/WTC-Docs/assets/1758174596397_e0878810.png)​

  ![250815142655239.png](http://localhost:5173/WTC-Docs/assets/1758174596796_f3dc7fd0.png)​
- #### 3、文件同步：

  - ##### 方式一：（推荐）

    本机提交-共享机更新
  - ##### 方式二：

    本机-共享机之间文件拖拽；
- #### 4、发布预览：

  ![250815145923208.png](http://localhost:5173/WTC-Docs/assets/1758174597099_12941b5d.png)
  ![250815150034172.png](http://localhost:5173/WTC-Docs/assets/1758174597830_81e7c10d.png)​
- #### 5、协作：

  - 检查共享机占用，使用时间冲突在群里自行协调；

    ![250815145257593.png](http://localhost:5173/WTC-Docs/assets/1758174599223_ff053815.png)​
  - 共享机做了提交限制，任何人不允许在共享机直接提交；

    ![250815145147150.png](http://localhost:5173/WTC-Docs/assets/1758174599500_6d92c74c.png)​
  - 在共享机做的改动及时同步走，其他人不对共享机上的改动丢失等情况负责；
  - 每次使用共享机时，先做“清理工作分支”操作；

‍

‍

#### <span id="20250908113936-3zoychu" style="display: none;"></span>视频文本

1、打开“启动台”，输入“屏幕”找到“屏幕共享”，点击打开；

2、首次连接需要配置一下远程主机；
    输入“10.10.31.23”，点击“连接”，选择“以注册用户身份”，用户名“Slots”，输入密码，“勾选记住密码”，点击登录；

3、屏幕共享类型建议选择“标准”；标准类型支持多人同时连接；高性能连接显示更高清、操作延迟更低，但同一时刻只能存在一个连接；

4、分支选择：打开 fork，一个是代码仓库，一个资源仓库；
    代码仓库的分支默认由程序维护，每周切换为当前提测分支，如有特殊需求找程序，比如要在上周版本、或某个研发中的版本上看效果；
    资源仓库分支由使用着自行维护；
    为避免多人使用时相互干扰，建议使用后清理并且更新代码、资源分支；

5、打开代码工程，找到快捷按钮，点击，等待 15 秒左右启动本地页面；

6、美术、动画效果同步的三种方法：1、在自己电脑上提交，到远程机器上拉取；2、直接拖动文件到远程机器，拖动到目标位置后不要松开，等待电脑识别后放开；可以直接拖动文件到任意目录，但为避免操作失误，建议拖动到中间目录，中间目录自行创建；注意，同目录下已经存在的文件不会覆盖或提醒，而是直接添加后缀存放；3、直接在远程机器的资源工程修改，不建议长时间占用远程机器；

7、发布美术、动画资源：在 CocosBuilder 中找到需要发布的资源，右键，选择“发布到工程”或“发布 CCB 及其引用资源到工程”，在弹出的窗口中输入对应的产品编号，比如 CV 输入 0，回车；没有异常，窗口会自行关闭，点击浏览器，游戏页面可以看到更新弹框，点击 refresh 按钮，更新完成，找到对应功能查看效果；

8、策划发布配置文件：打开代码工程，使用快捷键 commond+P 打开文件搜索框，输入要改动的配置，修改配置文件，保存，点击快捷按钮，点击浏览器，如无异常可以看到更新弹板，点击 refresh 按钮，查看效果；

9、确认效果后，可以选择将文件从远程机器拖动回自己的电脑，也可以在远程机器上直接提交，考虑提交归属问题，建议拷贝回自己的电脑再做提交；

10、为避免干扰他人使用，使用完成后请自觉清理远程机器分支；
