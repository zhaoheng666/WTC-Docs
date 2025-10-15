# CV实例升级操作步骤

#  启动备份实例

## 关掉slots-wtc-main2程序的开机启动

1. sudo vi /etc/rc.local 注释掉启动命令行

## 制作slots-wtc-main2的镜像

镜像名称: cv-main-20240820-1  
![image1](/assets/1758727509660_07fb5765.png)

## 通过镜像启动备份实例

名称: cv-main-20240820-1  
镜像: cv-main-20240820-1  
![image2](/assets/1758727509662_8ab97083.png)

## ![image3](/assets/1758727509663_1953d035.png)

安全组: slots-classicvegas-prod-sg  
![image4](/assets/1758727509664_d9aef7c4.png)  
![image5](/assets/1758727509666_ed3e5644.png)

添加弹性IP  
![image6](/assets/1758727509667_1fe38e2f.png)  
![image7](/assets/1758727509668_d41e1291.png)  
![image8](/assets/1758727509670_2b0d2642.png)  
![image9](/assets/1758727509671_a3c9e8f7.png)

## 修改实例类型

停止实例: 在控制台中停止实例  
修改实例类型:c5.9xlarge  
![image10](/assets/1758727509659_3257297d.png)

## 启用ENA

在另外一台实例上执行命令: 

1. aws ec2 modify-instance-attribute \--instance-id i-02f4551161086bd6e \--ena-support  
2. 启动实例  
3. 输入命令: modinfo ena 和 ethtool \-i eth0 检查是否开启了

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
3. 在slots-wtc-main2服务器上执行 “附页”中的 mongoexport命令合集

正常情况:

## 停止slots-wtc-main2实例

在控制台中停止实例

## 修改slots-wtc-main2实例类型

修改实例类型:c5.9xlarge (成败就在这一步)

## 启用slots-wtc-main2实例的ENA

在另外一台实例上执行命令: 

1. aws ec2 modify-instance-attribute \--instance-id i-00c5386321788839b \--ena-support  
2. 启动实例  
3. 输入命令: modinfo ena 和 ethtool \-i eth0 检查是否开启了

##  启动游戏进程,检查&测试

1. 此时为不开IP的情况,可以做一些基本的测试和日志的检查  
   cd /home/ec2-user/wtc-server/classic\_vegas  
   sh web\_restart\_server.sh  
2. 如果没啥问题,开IP

非正常情况,切换服务:

## 修改IP地址绑定关系

1. 将原slots-wtc-main2服务器的IP(35.170.3.187)地址绑定到备份服务器实例上

## 启动游戏进程,检查&测试

1. 执行命令  
   cd /home/ec2-user/wtc-server/classic\_vegas   
   sh web\_restart\_server.sh  
2.  如果没啥问题,开IP

# 

# 附页

## mongoexport命令合集

### 导出及上传s3命令:

IapData:  
		mongoexport \--db ClassicVegasStore \--collection IapData \--query '{"\_svTime":{"$gt":ISODate("2024-08-20T06:00:00.000Z")}}' \--out ./md\_backup/IapData.json  
		aws s3 cp ./md\_backup/IapData.json s3://me2zen-temp/dh-mongo-bk/  
		  
		DailySlotStat:  
		mongoexport \--db ClassicVegasStore \--collection DailySlotStat \--query '{"\_svTime":{"$gt":ISODate("2024-08-20T06:00:00.000Z")}}' \--out ./md\_backup/DailySlotStat.json  
		aws s3 cp ./md\_backup/DailySlotStat.json s3://me2zen-temp/dh-mongo-bk/  
		  
		DeletePlayerMap:  
		mongoexport \--db ClassicVegasStore \--collection DeletePlayerMap \--query '{"\_id":{"$gt":ObjectId("66c427d24b63bd64fd71fa8a")}}' \--out ./md\_backup/DeletePlayerMap.json  
		aws s3 cp ./md\_backup/DeletePlayerMap.json s3://me2zen-temp/dh-mongo-bk/  
		  
		FbNotiClick:  
		mongoexport \--db ClassicVegasStore \--collection FbNotiClick \--query '{"\_svTime":{"$gt":ISODate("2024-08-20T06:00:00.000Z")}}' \--out ./md\_backup/FbNotiClick.json  
		aws s3 cp ./md\_backup/FbNotiClick.json s3://me2zen-temp/dh-mongo-bk/  
		  
		PlayerData:  
		mongoexport \--db ClassicVegasStore \--collection PlayerData \--query '{"\_svTime":{"$gt":ISODate("2024-08-20T06:00:00.000Z")}}' \--out ./md\_backup/PlayerData.json  
		aws s3 cp ./md\_backup/PlayerData.json s3://me2zen-temp/dh-mongo-bk/  
		  
		PlayerMails:  
		mongoexport \--db ClassicVegasStore \--collection PlayerMails \--query '{"\_serverDate":{"$gt":ISODate("2024-08-20T06:00:00.000Z")}}' \--out ./md\_backup/PlayerMails.json  
		aws s3 cp ./md\_backup/PlayerMails.json s3://me2zen-temp/dh-mongo-bk/  
		

### 从s3上下载到备份服务器:

		aws s3 cp s3://me2zen-temp/dh-mongo-bk/IapData.json ./md\_backup/IapData.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/DailySlotStat.json ./md\_backup/DailySlotStat.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/DeletePlayerMap.json ./md\_backup/DeletePlayerMap.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/FbNotiClick.json ./md\_backup/FbNotiClick.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/PlayerData.json ./md\_backup/PlayerData.json  
		aws s3 cp s3://me2zen-temp/dh-mongo-bk/PlayerMails.json ./md\_backup/PlayerMails.json  
		

### 在备份服务器上导入数据:

		mongoimport \--db ClassicVegasStore \--collection IapData \--file ./md\_backup/IapData.json \--upsert  
		mongoimport \--db ClassicVegasStore \--collection DailySlotStat \--file ./md\_backup/DailySlotStat.json \--upsert  
		mongoimport \--db ClassicVegasStore \--collection DeletePlayerMap \--file ./md\_backup/DeletePlayerMap.json \--upsert  
		mongoimport \--db ClassicVegasStore \--collection FbNotiClick \--file ./md\_backup/FbNotiClick.json \--upsert  
		mongoimport \--db ClassicVegasStore \--collection PlayerData \--file ./md\_backup/PlayerData.json \--upsert  
		mongoimport \--db ClassicVegasStore \--collection PlayerMails \--file ./md\_backup/PlayerMails.json \--upsert

## 查询备份数据库DeletePlayerMap的最大id

db.DeletePlayerMap.find().sort({\_id:-1})



















