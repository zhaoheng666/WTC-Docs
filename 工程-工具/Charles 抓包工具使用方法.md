# Q4\`24-Slots-抓包工具 Charles \

##### 安装包：

[https://drive.google.com/file/d/1zziJUZo-K-WiOSHlx7PbELWU3mzUTLCm/view?usp=sharing](https://drive.google.com/file/d/1zziJUZo-K-WiOSHlx7PbELWU3mzUTLCm/view?usp=sharing)

## 一、charles基础设置：

### 1、安装根证书 "Help" \-\> "SSL Proxying" \-\> "Install Charles Root Certificate"![image1](http://localhost:5173/WTC-Docs/assets/1758727509828_89d5241a.png)

### 2、证书安装位置选择到系统：![image2](http://localhost:5173/WTC-Docs/assets/1758727509829_b4a9403b.png)

### 3、打开钥匙串-\>搜索 charles 找到证书-\>右键显示简介-\>始终信任证书：![image3](http://localhost:5173/WTC-Docs/assets/1758727509830_8d85b5c5.png)![image4](http://localhost:5173/WTC-Docs/assets/1758727509832_5ceaa906.png)

### 4、配置 Proxy Settings：  ![image5](http://localhost:5173/WTC-Docs/assets/1758727509833_4f700c7b.png) ![image6](http://localhost:5173/WTC-Docs/assets/1758727509834_fd67c0e4.png)

### 5、配置 SSL 代理： ![image7](http://localhost:5173/WTC-Docs/assets/1758727509836_0312321c.png)![image8](http://localhost:5173/WTC-Docs/assets/1758727509837_60330f51.png)

#### 可以指定具体域名端口，或使用通配符；

## 二、Android 设备支持：

### 1、连接到同一网络：确保 Android 设备与运行 Charles 的计算机连接到同一网络。

### 2、打开 android 设备当前网络设置：

#### 服务器主机名：链接电脑的局域网 ip

#### 服务器端口：chales 中配置的 HTTP Proxy Port

![image9](http://localhost:5173/WTC-Docs/assets/1758727509839_7c935abb.png)

### 3、安装证书：“Help” \> “SSL Proxying” \> “Install Charles Root Certificate on a Mobile Device or Remote Browser”

![image10](http://localhost:5173/WTC-Docs/assets/1758727509814_d43b3b16.png)

### 4、设备浏览器输入 [chls.pro/ssl，下载证书到手机；](http://chls.pro/ssl)

### 5、设备设置-\>搜索“证书”-\>CA 证书，选择下载的 chls 证书，安装；

## 三、IOS 设备支持：

### 1、连接到同一网络：确保 ios 设备与运行 Charles 的计算机连接到同一网络。

### 2、打开 ios 设备当前网络-\>详情符号-\>配置代理-\>手动：

#### 服务器主机名：链接电脑的局域网 ip

#### 服务器端口：chales 中配置的 HTTP Proxy Port![image11](http://localhost:5173/WTC-Docs/assets/1758727509815_1017d933.png)

### 3、安装证书：“Help” \> “SSL Proxying” \> “Install Charles Root Certificate on a Mobile Device or Remote Browser”

![image12](http://localhost:5173/WTC-Docs/assets/1758727509817_3c3e0123.png)

### 4、设备浏览器输入 [chls.pro/ssl，下载证书到手机；](http://chls.pro/ssl) 或者电脑下载 drop 到设备；

### 5、安装证书：设备设置-\>未安装的描述文件-\>...安装；

### 6、信任证书：设备设置-\>通用-\>关于本机-\>证书信任设置；

## 四、使用场景：

### 1、抓包；

### 2、设置断点

选择要设置断点的请求，右键选择breakpoints，这样每次请求这条链接的时候，都会弹出处理界面，询问要如何处理

![image13](http://localhost:5173/WTC-Docs/assets/1758727509818_2b0b6002.png)  
此时可以选择取消或者返回对应的数据，模拟超时请求的情况  
![image14](http://localhost:5173/WTC-Docs/assets/1758727509819_02fe90bc.png)

### 3、保存和修改返回值

可以根据需要，把协议的返回值保存到本地，在本地进行修改后，替换原有返回值，模拟数值变化、返回值异常、数据量过大等情况的测试

如图，右键选中请求，选择对应选项就可以把返回保存到本地

![image15](http://localhost:5173/WTC-Docs/assets/1758727509821_908fabaa.png)

替换请求数据同样也是右键所需请求，选择本地的对应要替换的文件  
![image16](http://localhost:5173/WTC-Docs/assets/1758727509822_3942f8fc.png)

![image17](http://localhost:5173/WTC-Docs/assets/1758727509823_5bcc3751.png)

### 4、模拟弱网

![image18](http://localhost:5173/WTC-Docs/assets/1758727509825_5d26d3b4.png)

可以根据自己的需要，筛选对应生效的域名，更改带宽，限速等  
![image19](http://localhost:5173/WTC-Docs/assets/1758727509826_0a0f3dee.png)





































