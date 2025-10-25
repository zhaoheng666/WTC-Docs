### 推送证书，是三方发给苹果用户远程通知时使用，比如HelpShift、AIHelp等客服回复时，会向用户发送远程通知，需要将证书配置在这些三方的后台中。

#### 1、确认自己有没有新建证书的权限

[https://developer.apple.com/account/resources/certificates/list](https://developer.apple.com/account/resources/certificates/list)

#### 2、打开KeyChain，创建一个证书请求（macos 14+ 密码APP替代了钥匙串，通过 Spotlight 搜索 Keychain Access 打开，或使用命令行 open /Applications/Utilities/Keychain\\ Access.app）

![image1](/assets/bf9c334301227a65812946a738b4f7b2.png)

邮箱填自己的邮箱，选择保存到本地磁盘，之后会获得一个CertificateSigningRequest.certSigningRequest文件

![image2](/assets/66707b772c91ffc1bfc82cec5b598957.png)

#### 3、登录苹果后台，选择新建证书

[https://developer.apple.com/account/resources/certificates/list](https://developer.apple.com/account/resources/certificates/list)

![image3](/assets/0626b3bdd922718ea087026c7aff4faf.png)

证书类型选择Apple Push Notification service SSL (Sandbox & Production)

![image4](/assets/f881cc76b6fb84d72311e127035ee56f.png)

然后选择你要新建证书的APP，

![image5](/assets/e507bc05305aee4817ed689169343ba5.png)

上传刚才导出的证书请求文件CertificateSigningRequest.certSigningRequest

![image6](/assets/c9115066b243d45542626250f497eb4b.png)

之后苹果会对证书进行签名，然后将证书下载下来，会获得一个.cer文件

![image7](/assets/45e94689d25652b27c182251abd60618.png)

双击打开这个.cer文件，就会自动打开KeyChain，然后就能看到证书在列表中了，检查下证书的失效时间是否正确，一般苹果会发放一个一年的证书，因而失效日期是今天加一年，

#### 4、右键这个证书，选择导出

导出的文件名选择一个好区分的，因为每个APP都有自己的证书，在这里我用文件名apn\_classic.p12，

![image8](/assets/be1223ad513d37221c490ee8150f3542.png)

然后需要输入一个证书的保护密码，建议选一个好记的，比如HappyMe2zen，

如果导出选项不可选，说明证书状态为不受信任，双击证书，将信任策略改为始终信任：

![image9](/assets/060db52f97da58ff2aab504d05d4de3d.png)

然后要输入机器的登录密码，全部输入确认后，会导出证书来。

#### 5、之后将这个证书apn\_classic.p12，以及保护密码，交给运营，这个证书一般用在后台推送上，比如HelpShift、AIHelp的后台。

















