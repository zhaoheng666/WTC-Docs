### 推送证书，是三方发给苹果用户远程通知时使用，比如HelpShift、AIHelp等客服回复时，会向用户发送远程通知，需要将证书配置在这些三方的后台中。

#### 1、确认自己有没有新建证书的权限

[https://developer.apple.com/account/resources/certificates/list](https://developer.apple.com/account/resources/certificates/list)

#### 2、打开KeyChain，创建一个证书请求（macos 14+ 密码APP替代了钥匙串，通过 Spotlight 搜索 Keychain Access 打开，或使用命令行 open /Applications/Utilities/Keychain\\ Access.app）

![image1](http://localhost:5173/WTC-Docs/assets/1758727509690_6e1efe91.png)

邮箱填自己的邮箱，选择保存到本地磁盘，之后会获得一个CertificateSigningRequest.certSigningRequest文件

![image2](http://localhost:5173/WTC-Docs/assets/1758727509692_6e19b1c0.png)

#### 3、登录苹果后台，选择新建证书

[https://developer.apple.com/account/resources/certificates/list](https://developer.apple.com/account/resources/certificates/list)

![image3](http://localhost:5173/WTC-Docs/assets/1758727509693_29555bd9.png)

证书类型选择Apple Push Notification service SSL (Sandbox & Production)

![image4](http://localhost:5173/WTC-Docs/assets/1758727509695_8d0f2928.png)

然后选择你要新建证书的APP，

![image5](http://localhost:5173/WTC-Docs/assets/1758727509696_7fc3a8e7.png)

上传刚才导出的证书请求文件CertificateSigningRequest.certSigningRequest

![image6](http://localhost:5173/WTC-Docs/assets/1758727509698_070488f4.png)

之后苹果会对证书进行签名，然后将证书下载下来，会获得一个.cer文件

![image7](http://localhost:5173/WTC-Docs/assets/1758727509699_ab47b3a0.png)

双击打开这个.cer文件，就会自动打开KeyChain，然后就能看到证书在列表中了，检查下证书的失效时间是否正确，一般苹果会发放一个一年的证书，因而失效日期是今天加一年，

#### 4、右键这个证书，选择导出

导出的文件名选择一个好区分的，因为每个APP都有自己的证书，在这里我用文件名apn\_classic.p12，

![image8](http://localhost:5173/WTC-Docs/assets/1758727509701_ac91dbbe.png)

然后需要输入一个证书的保护密码，建议选一个好记的，比如HappyMe2zen，

如果导出选项不可选，说明证书状态为不受信任，双击证书，将信任策略改为始终信任：

![image9](http://localhost:5173/WTC-Docs/assets/1758727509703_0bf8e9ac.png)

然后要输入机器的登录密码，全部输入确认后，会导出证书来。

#### 5、之后将这个证书apn\_classic.p12，以及保护密码，交给运营，这个证书一般用在后台推送上，比如HelpShift、AIHelp的后台。

















