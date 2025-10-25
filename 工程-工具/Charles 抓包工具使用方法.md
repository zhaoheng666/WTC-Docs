# Q4\`24-Slots-抓包工具 Charles \

##### 安装包：

[https://drive.google.com/file/d/1zziJUZo-K-WiOSHlx7PbELWU3mzUTLCm/view?usp=sharing](https://drive.google.com/file/d/1zziJUZo-K-WiOSHlx7PbELWU3mzUTLCm/view?usp=sharing)

## 一、charles基础设置：

### 1、安装根证书 "Help" \-\> "SSL Proxying" \-\> "Install Charles Root Certificate"![image1](/assets/3db713b49f737bb8f4e6c12b6be9e949.png)

### 2、证书安装位置选择到系统：![image2](/assets/aa25f31ef3034cb7f007be54777e6e42.png)

### 3、打开钥匙串-\>搜索 charles 找到证书-\>右键显示简介-\>始终信任证书：![image3](/assets/1a02cc71f855cfb2d76dbdff78ca708a.png)![image4](/assets/7ba7aa80258514f1c8f973daf06dd600.png)

### 4、配置 Proxy Settings：  ![image5](/assets/bc6129451e8d9e329479e409ef6dbdc5.png) ![image6](/assets/820686dbe81e04a09921c01bc09e74cf.png)

### 5、配置 SSL 代理： ![image7](/assets/6d62f40890e1ed806a09d63cb28d4c2e.png)![image8](/assets/20ec59bed786f22611a055257dd9cf09.png)

#### 可以指定具体域名端口，或使用通配符；

## 二、Android 设备支持：

### 1、连接到同一网络：确保 Android 设备与运行 Charles 的计算机连接到同一网络。

### 2、打开 android 设备当前网络设置：

#### 服务器主机名：链接电脑的局域网 ip

#### 服务器端口：chales 中配置的 HTTP Proxy Port

![image9](/assets/e0f664dfd65894ea30c19d19fbf7c7ff.png)

### 3、安装证书：“Help” \> “SSL Proxying” \> “Install Charles Root Certificate on a Mobile Device or Remote Browser”

![image10](/assets/a10ff77c42b3fe6c51dfc4393910badb.png)

### 4、设备浏览器输入 [chls.pro/ssl，下载证书到手机；](http://chls.pro/ssl)

### 5、设备设置-\>搜索“证书”-\>CA 证书，选择下载的 chls 证书，安装；

## 三、IOS 设备支持：

### 1、连接到同一网络：确保 ios 设备与运行 Charles 的计算机连接到同一网络。

### 2、打开 ios 设备当前网络-\>详情符号-\>配置代理-\>手动：

#### 服务器主机名：链接电脑的局域网 ip

#### 服务器端口：chales 中配置的 HTTP Proxy Port![image11](/assets/53ac6e249b1e60d4bc4ba9558e2951df.png)

### 3、安装证书：“Help” \> “SSL Proxying” \> “Install Charles Root Certificate on a Mobile Device or Remote Browser”

![image12](/assets/648346832caabf89de33c1b8b7a566d3.png)

### 4、设备浏览器输入 [chls.pro/ssl，下载证书到手机；](http://chls.pro/ssl) 或者电脑下载 drop 到设备；

### 5、安装证书：设备设置-\>未安装的描述文件-\>...安装；

### 6、信任证书：设备设置-\>通用-\>关于本机-\>证书信任设置；

## 四、使用场景：

### 1、抓包；

### 2、设置断点

选择要设置断点的请求，右键选择breakpoints，这样每次请求这条链接的时候，都会弹出处理界面，询问要如何处理

![image13](/assets/6ec44d2bd1dc9f8be08ff9405dce2632.png)  
此时可以选择取消或者返回对应的数据，模拟超时请求的情况  
![image14](/assets/ff8f7e9827e6ee4831106b3e564491ba.png)

### 3、保存和修改返回值

可以根据需要，把协议的返回值保存到本地，在本地进行修改后，替换原有返回值，模拟数值变化、返回值异常、数据量过大等情况的测试

如图，右键选中请求，选择对应选项就可以把返回保存到本地

![image15](/assets/6c511f80d6a06cf44d8029ad646524a3.png)

替换请求数据同样也是右键所需请求，选择本地的对应要替换的文件  
![image16](/assets/d4bb568cccbde3fbe6dcdc6ba8975ce9.png)

![image17](/assets/0c72a556a87fad4ad937776e4249acd8.png)

### 4、模拟弱网

![image18](/assets/bae45cf99def9dc92d4a5a4fe828d387.png)

可以根据自己的需要，筛选对应生效的域名，更改带宽，限速等  
![image19](/assets/142c03347abea5a26205366191a86d9b.png)





































