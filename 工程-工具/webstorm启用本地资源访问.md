# Q1\`25-Slots-webstorm-启用本地资源访问

## 访问本地资源服性状说明：

### 前端资源服务器：

* 直接映射到本地仓库资源，资源未经压缩；
* 缺少 fb 等 sdk 相关功能，包括登录、支付；
* 走游客账号登录；
* 走局域网下载；
* 内置服务器性能有限，并发链接支撑有限，非必要人员不要同时使用；

### 后端服务器：无差异

* 与正常测试流程一致，自行选择后端服务器；
* 与正常测试流程一致，自行选择服务器管理工具；

### 建议：

* 可用来测试功能完整性；
* 仍需在正常测试环境复核，避免出现:
  * 研发人员本地工作副本、和最终提交版本有差异
  * 研发人员漏提、错提代码、资源；

## 1、使用 webstorm 内置服务器：

![image1](http://localhost:5173/WTC-Docs/assets/1758727509606_60a79ba2.png)

* 端口：低于 63342
* 勾选接受外部链接
* 勾选允许未签名的请求

## 2、本地仓库更新，本地启动一次

    ![image2](http://localhost:5173/WTC-Docs/assets/1758727509608_e7eea6f5.png)

## 3、使用内网 ip 访问：

* option \+ 鼠标左键，查看本机 ip![image3](http://localhost:5173/WTC-Docs/assets/1758727509609_d7f03935.png)![image4](http://localhost:5173/WTC-Docs/assets/1758727509610_e86344aa.png)
* 拼接访问地址：http://本机 ip:内置服务器端口/WorldTourCasino/index.html
  [http://10.10.27.80:63341/WorldTourCasino/index.html](http://10.10.27.80:63341/WorldTourCasino/index.html)
