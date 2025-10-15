## jenkins发版-检查参数阶段-增加自动读取线上文档活动配置功能

### 一、借助 Google Cloud Api 实现：

#### 1、新建项目：

[https://console.cloud.google.com/apis/dashboard?hl=zh-cn\&orgonly=true\&project=sheets-api-437103\&supportedpurview=organizationId](https://console.cloud.google.com/apis/dashboard?hl=zh-cn&orgonly=true&project=sheets-api-437103&supportedpurview=organizationId)  
![image1](/assets/1758727509885_6163b50e.png)

#### 2、启用 Google Sheets API：

![image2](/assets/1758727509886_467f0133.png)】  
![image3](/assets/1758727509888_7a1b1bea.png)

#### 3、创建服务账号：

![image4](/assets/1758727509889_878b6ba6.png)  
![image5](/assets/1758727509890_ffbc215e.png)

#### 4、创建服务密钥（选择 json 格式）：

![image6](/assets/1758727509892_580d4f15.png)  
创建完成后，会自动将 json 文件下载到本地，这个文件将是后续脚本创建服务的基础配置文件；

#### 5、为服务账号添加共享权限：

![image7](/assets/1758727509893_d4b32eaa.png)

#### 6、编写脚本读取未来两周活动：

##### 6.1 安装依赖：

pip install \--upgrade oauth2client  
pip install \--upgrade google-api-python-client

##### 6.2 读取未来两周配置：ggs.py

\#\!/usr/bin/env python  
\#coding: utf-8

from apiclient.discovery import build  
from oauth2client.service\_account import ServiceAccountCredentials

global json\_key\_file  
json\_key\_file \= './server\_secret.json'

*def* getWeeklyActivtyService(*spreadsheet\_id*):  
   \# 定义要使用的 scopes  
   scopes \= \['https://www.googleapis.com/auth/spreadsheets.readonly'\]

   \# 创建凭证  
   credentials \= ServiceAccountCredentials.from\_json\_keyfile\_name(json\_key\_file, scopes)

   \# 建立服务对象  
   return build('sheets', 'v4', *credentials*\=credentials)

*def* getWeeklyActivity():  
   \# 表格 ID  
   spreadsheet\_id \= '1n9-hHrvvzyGcvktimZVQU9hwydTJn5bIWV-QpnPZNjw'  
   \# 工作表名称  
   SHEETNAME \= '未来两周活动资源'  
   \# 要获取的数据范围（第三列）  
   RANGENAME \= SHEETNAME \+ '\!D1:D'

   service \= getWeeklyActivtyService(spreadsheet\_id)

   result \= service.spreadsheets().values().get(*spreadsheetId*\=spreadsheet\_id, *range*\=RANGENAME).execute()  
   values \= result.get('values', \[\])

   return values

### 二、继承到 jenkins 发版脚本：

#### 1、 读取resource\_dirs.json，写入未来两周配置：

\#\!/usr/bin/env python  
\#coding: utf-8

import sys  
import os

import ggs  
import json

app\_res\_map \= {  
   'res\_oldvegas':0,  
   'res\_doublehit':1  
}

if len(sys.argv) \<= 1:  
   print("useage: get-activities-sheets.py \*/resource\_dirs.json")  
   exit(1)

\# 解析 app\_res 参数  
resource\_dirs\_config\_file \= sys.argv\[1\]  
res\_dir \= os.path.split(os.path.dirname(resource\_dirs\_config\_file))\[1\]

\# 解析数据索引  
target\_app\_index \= app\_res\_map\[res\_dir\]  
if target\_app\_index \== None:  
   print('get activities from Google Sheet faild\! Target app not support.')  
   exit(0)

\# 获取数据  
values \= ggs.getWeeklyActivity()  
if not values:  
   print('get activities from Google Sheet faild\! No data found.')  
   exit(2)  
else:  
   app\_index \= \-1  
   activities\_list \= \[\]

   for row in values:  
       if len(row) \> 0:  
           if *u*"活动资源名称" \== row\[0\]:  
               app\_index \+= 1  
               if len(activities\_list) \<= app\_index:  
                   activities\_list.append(\[\])  
                   continue  
            
           if app\_index \>= 0:  
               activities\_list\[app\_index\].append(row\[0\])

\# 写入数据  
content \= activities\_list\[target\_app\_index\]  
if len(content) \== 0:  
   print('get activities from Google Sheet faild\! No match data found.')  
   exit(3)

json\_data \= None  
with open(resource\_dirs\_config\_file,'r') as file:  
   json\_data \= json.load(file)  
    
json\_data\['activity'\] \= content

with open(resource\_dirs\_config\_file,'w') as file:  
   json.dump(json\_data,file,*indent*\=2)

#### 2、添加 Jenkins 脚本调用

./get-activities-sheets.py ../$workspace/$res\_dir/resource\_dirs.json  
cd ../$workspace

git add .  
git commit \-m "\! ${display\_name}\_JS\_V${common\_ver} 同步 smoke 活动配置"  
git push

### 三、问题记录：

#### 1、打包机 python 环境问题：

打包机使用 xocde 自带的 python 版本，未安装 pynev、未安装pip；无法安装依赖库；  
解决：

1.1 获取python 版本、路径：  
xcode 自带 python 版本 2.7；  
path: */Library/Frameworks/Python.framework/Versions/2.7/bin/*  
link：*/usr/local/bin/python*

1.2 安装 pip：  
curl https://bootstrap.pypa.io/get-pip.py \-o get-pip.py  
sudo /usr/bin/python get-pip.py

1.3 添加 link 到可执行目录:  
ln \-s /Library/Frameworks/Python.framework/Versions/2.7/bin/pip /usr/local/bin/pip

1.4 重开终端或 export 到环境变量；













