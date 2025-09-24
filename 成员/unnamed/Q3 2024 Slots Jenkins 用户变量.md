### 目的：

#### jenkins build 通知中添加操作人，告知 QA 这个版本时谁发的：

### 方法：

1. #### 安装插件: "Build User Vars Plugin"

   1. 进入 Jenkins 管理界面。  
   2. 点击 "Manage Jenkins"。  
   3. 点击 "Manage Plugins"。  
   4. 在 "Available" 标签，搜索 "Build User Vars Plugin"，进行安装。

2. #### 配置项目: 在 Jenkins 任务中使用该插件。

   1. 进入任务管道配置界面。  
   2. 在 "构建环境" 中勾选 "Set jenkins user build variables"。

3. #### 使用发布者信息:

   1. BUILD\_USER\_ID: 用户ID  
   2. BUILD\_USER: 用户全名  
   3. BUILD\_USER\_EMAIL: 用户邮箱

![image1](http://localhost:5173/WTC-Docs/assets/1758727509754_46c6b2e7.png)

