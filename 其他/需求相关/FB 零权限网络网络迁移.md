# FB 零权限网络网络迁移

![250813175243350.png](http://localhost:5173/WTC-Docs/assets/1758174593069_26be0f9f.png)​

### 零权限网络：

FB 将集中、统一管理用户授权，游戏运行将不再需要单独的网络授权，其他权限也不再需要单独请求用户授权；（可以理解为把即时游戏做为 FB APP 的一部分）

### 差异：

![250813175153774.png](http://localhost:5173/WTC-Docs/assets/1758174594167_0b141766.png)​

### 影响：

1、现有的 web game 平台将关停，届时我们所有产品的 web 端将面临停用，需要迁移到零权限小游戏；

2、对 FB 头像、name 等用户信息的获取和展示方式发生了改变，新的方式限制性更强、更加不灵活了；

### 需要做的工作：

1、按照[官方引导](https://developers.facebook.com/docs/games/build/instant-games/network-enabled-zero-permissions/app-onboarding-and-migration)开启零网络权限，确认是否会对 native 端产生影响，目前我没有找到官方文档中引导的操作入口，无法做出更具体的判断，可能是 FB 并未同步，需要过一段时间再看；

2、接入新版本的 sdk；

3、验证 fbid 是否继承；（官方提供了多种方式，其中一种宣称跟之前的 fbid 一致，需要验证）

4、修改游戏中使用、展示 fb 用户信息的地方；

5、其他合规要求、审核；

预估处理周期：1 个月（涉及合规、审核，所以整个周期会比较长）
