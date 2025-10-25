# DH实例升级操作步骤

#  启动备份实例

## 关掉DH-main程序的开机启动

sudo vi /etc/rc.local 注释掉启动命令行

## 制作DH-main的镜像

<!-- ![image1](/assets/1758727509675_8f26199a.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->

## 通过镜像启动备份实例

<!-- ![image2](/assets/1758727509677_b294b08f.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->

## <!-- ![image3](/assets/1758727509678_236071a1.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->

<!-- ![image4](/assets/1758727509679_2beb1404.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->  
<!-- ![image5](/assets/1758727509681_d5aa5b93.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->

添加弹性IP  
<!-- ![image6](/assets/1758727509682_a91bc7f6.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->  
<!-- ![image7](/assets/1758727509683_218d54ca.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->  
<!-- ![image8](/assets/1758727509685_0830d98b.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->  
<!-- ![image9](/assets/1758727509686_3a39a56b.png) -->
<!-- ⚠️ 图片文件缺失，已注释 -->

## 修改实例类型

停止实例: 在控制台中停止实例  
修改实例类型:c5.9xlarge  
<!-- ![image10](/assets/1758727509672_e0950969.png) -->
<!-- ⚠️ 图片文件缺失，已注释 --> 

## 启用ENA

在另外一台实例上执行命令: 

1. aws ec2 modify-instance-attribute \--instance-id instance\_id \--ena-support  
2. 启动实例  
3. 输入命令: modinfo ena 和 ethtool \-i eth0 检查是否开启了

## 测试可用性

1. 本地启动临时redis  
2. 修改服务器上redis连接字符串为 127.0.0.1  
3. 启动游戏进程 cd /home/ec2-user/wtc-server/double\_hit  && sh system\_auto\_restart.sh   
4. top 查看进程是否启动成功  
5. 创建新的域名: doublehit-test.me2zengame.com  
6. 前端新加一个服务器选项 ,用于基本测试

## 制作新的镜像

# 面临的问题

## 如何处理Mongodb的数据?

1. 开启同步  
2. 停服打镜像  
3. 停服备份数据库并恢复到新的服务器上  
   1. mongodump恢复数据  
   2. 拷贝文件

通过上面的方案需要做一些测试

1. 重新打包镜像消耗的时间  
2. 备份Mongodb恢复mongodb消耗的时间

### dump命令备份及恢复Mongodb数据的时间

1. 备份数据: mongodump \--db DoubleHitStore \--out ./  (消耗时间:50min)  
2. 压缩文件: 无  
3. 上传到S3:无  
4. 新服务器下载:无  
5. 新服务器清空数据库:无  
6. 新服务器恢复数据: 无

总消耗时间: 无  
结论: dump命令备份数据消耗时间太长,不适合重新备份

### 复制mongodb文件方式备份及恢复数据的时间

1. 停止数据库服务: sudo service mongod stop (耗时: 20sec)  
2. 拷贝文件: mkdir db\_backup  sudo cp \-r /var/lib/mongo ./db\_backup/ (耗时: 超过30min后手动停止了)	  
3. 启动数据库服务: sudo service mongod start  
4. 压缩文件:  
5. 上传到S3:  
6. 新服务器下载:  
7. 新服务器停止数据库服务:  
8. 新服务器清空数据库:  
9. 新服务器恢复数据:   
10. 新服务器启动数据库服务:

### 重新制作镜像的时间:

1. 停止自动启动项   
2. 创建镜像: 创建名为: doublehit-main-20240815-1  (耗时: 26min)  
3. 启动新实例: 填写信息3min,初始化:3min

### 使用mongoexport和mongoimport增量备份和恢复:

1. 执行mongoexport导出增量数据,需要每个collect分别执行,具体的执行命令整理到文档末尾  
2. 上传到s3中  
3. 从s3上下载到备份服务器上  
4. 执行mongoimport导入增量数据

经过测试,总耗时在:10min左右

| 方案 | 耗时 | 缺点 |
| ----- | ----- | ----- |
| 数据同步 |  |  |
| 停服重新制作镜像 | 创建镜像和启动实例的时间大概是30分钟 但后续的操作(修改实例类型;重启;指定ENA;启动游戏进程) | 时间长  |
| mongodump备份和恢复数据 | 备份已经50分钟了 | 时间长 |
| 拷贝数据文件方案 | 拷贝文件已经超过30分钟了 | 时间长 |
| 使用mongoexport和mongoimport增量备份和恢复 | 虽然每一张collect都需要去执行,但整体执行时间很少  | 脚本迁移,需要人工甄别哪些数据需要迁移哪些不需要 有一些聚合表,还是需要全表导入和导出 |

## 如何切换服务?

前提:  
	因为共用同一个redis服务,如果启两套服务会出现数据冲突的问题 ,所以只能保留一个服务

| 方案 | 优点 | 缺点 |
| ----- | ----- | ----- |
| 修改域名指向 | 操作简单 | 域名解析有延迟,不知道什么时候才能完全生效 |
| 同一域名多IP | 无缝切换 | 不能同时有多套服务存在 |
| 新实例绑定旧IP | 不会出现解析IP地址延迟的问题 |  |

# 实操重启正式服步骤

## 重新制作镜像,防止测试数据污染数据(可提前进行)

1. 制作镜像  
2. 设置弹性IP  
3. 检查数据库是否正常  
4. 将服务器启动起来,但不启动游戏进程

## 发停服公告

1. 向在线玩家发送停服公告

## 停止游戏进程

1. 将游戏进程停止

## 使用mongoexport/mongoimport增量备份和恢复数据

1. 删除S3上的测试资源: [https://us-east-1.console.aws.amazon.com/s3/buckets/me2zen-temp?region=us-east-1\&bucketType=general\&prefix=dh-mongo-bk/](https://us-east-1.console.aws.amazon.com/s3/buckets/me2zen-temp?region=us-east-1&bucketType=general&prefix=dh-mongo-bk/)  
2. 在新服务器上创建目录 md\_backup  
3. 在DH-main服务器上执行 “附页”中的 mongoexport命令合集

正常情况:

## 停止DH-main实例

在控制台中停止实例

## 修改DH-main实例类型

修改实例类型:c5.9xlarge (成败就在这一步)

## 启用DH-main实例的ENA

在另外一台实例上执行命令: 

4. aws ec2 modify-instance-attribute \--instance-id instance\_id \--ena-support  
5. 启动实例  
6. 输入命令: modinfo ena 和 ethtool \-i eth0 检查是否开启了

##  启动游戏进程,检查&测试

1. 此时为不开IP的情况,可以做一些基本的测试和日志的检查  
   cd /home/ec2-user/wtc-server/double\_hit  
   sh web\_restart\_server.sh  
2. 如果没啥问题,开IP

非正常情况,切换服务:

## 修改IP地址绑定关系

1. 将原DH-main服务器的IP地址绑定到备份服务器实例上

## 启动游戏进程,检查&测试

1. 执行命令  
   cd /home/ec2-user/wtc-server/double\_hit   
   sh web\_restart\_server.sh  
2.  如果没啥问题,开IP

# 

# 附页

## mongoexport命令合集

### 导出及上传s3命令:

IapData:  
		mongoexport \--db DoubleHitStore \--collection IapData \--query '{"\_svTime":{"$gt":ISODate("2024-08-19T06:15:00.000Z")}}' \--out ./md\_backup/IapData.json  
		aws s3 cp ./md\_backup/IapData.json s3://me2zen-temp/dh-mongo-bk/  
		  
		DailySlotStat:  
		mongoexport \--db DoubleHitStore \--collection DailySlotStat \--query '{"\_svTime":{"$gt":ISODate("2024-08-19T06:15:00.000Z")}}' \--out ./md\_backup/DailySlotStat.json  
		aws s3 cp ./md\_backup/DailySlotStat.json s3://me2zen-temp/dh-mongo-bk/  
		  
		DeletePlayerMap:  
		mongoexport \--db DoubleHitStore \--collection DeletePlayerMap \--query '{"\_id":{"$gt":ObjectId("66c2d5abb7298d1f1c186b3e")}}' \--out ./md\_backup/DeletePlayerMap.json  
		aws s3 cp ./md\_backup/DeletePlayerMap.json s3://me2zen-temp/dh-mongo-bk/  
		  
		FbNotiClick:  
		mongoexport \--db DoubleHitStore \--collection FbNotiClick \--query '{"\_svTime":{"$gt":ISODate("2024-08-19T06:15:00.000Z")}}' \--out ./md\_backup/FbNotiClick.json  
		aws s3 cp ./md\_backup/FbNotiClick.json s3://me2zen-temp/dh-mongo-bk/  
		  
		PlayerData:  
		mongoexport \--db DoubleHitStore \--collection PlayerData \--query '{"\_svTime":{"$gt":ISODate("2024-08-19T06:15:00.000Z")}}' \--out ./md\_backup/PlayerData.json  
		aws s3 cp ./md\_backup/PlayerData.json s3://me2zen-temp/dh-mongo-bk/  
		  
		PlayerMails:  
		mongoexport \--db DoubleHitStore \--collection PlayerMails \--query '{"\_serverDate":{"$gt":ISODate("2024-08-19T06:15:00.000Z")}}' \--out ./md\_backup/PlayerMails.json  
		aws s3 cp ./md\_backup/PlayerMails.json s3://me2zen-temp/dh-mongo-bk/  
		

### 从s3上下载到备份服务器:

		aws s3 cp s3://me2zen-temp/dh-mongo-bk/IapData.json ./md\_backup/IapData.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/DailySlotStat.json ./md\_backup/DailySlotStat.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/DeletePlayerMap.json ./md\_backup/DeletePlayerMap.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/FbNotiClick.json ./md\_backup/FbNotiClick.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/PlayerData.json ./md\_backup/PlayerData.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/PlayerMails.json ./md\_backup/PlayerMails.json  
		

### 在备份服务器上导入数据:

		mongoimport \--db DoubleHitStore \--collection IapData \--file ./md\_backup/IapData.json \--upsert  
		mongoimport \--db DoubleHitStore \--collection IapData \--file ./md\_backup/DailySlotStat.json \--upsert  
		mongoimport \--db DoubleHitStore \--collection IapData \--file ./md\_backup/DeletePlayerMap.json \--upsert  
		mongoimport \--db DoubleHitStore \--collection IapData \--file ./md\_backup/FbNotiClick.json \--upsert  
		mongoimport \--db DoubleHitStore \--collection IapData \--file ./md\_backup/PlayerData.json \--upsert  
		mongoimport \--db DoubleHitStore \--collection IapData \--file ./md\_backup/PlayerMails.json \--upsert

## 查询备份数据库DeletePlayerMap的最大id

db.DeletePlayerMap.find().sort({\_id:-1})

## 类型比较

当前使用:  c4.8xlarge (36 个 vCPU，61440 内存，仅限于 EBS)  
使用量:  
![image11](/assets/af1887223f6eb91e18219110f0a612f1.png)

备选:  
c5.9xlarge (36 个 vCPU，73728 内存，仅限于 EBS) 比目前使用的稍大一点  
c5.4xlarge (16 个 vCPU，32768 内存，仅限于 EBS) 腰斩不合适  
![image12](/assets/7c0e94d65f4834750170b7967041fba4.png)























