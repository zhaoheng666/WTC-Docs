# **index.html、game.min.js文件未更新,导致web端无法更新到最新资源**

### **问题描述:**

#### **cv、dh发版,玩家无法更新到最新资源,dh提示强更;**

### **问题分析:**

1、native版本更新正常;  
2、直接访问web端资源,版本无误,可正常访问;  
3、查发版记录,未搜索到error,fatal,skiping等常见错误;  
4、后端查询版本目录映射、cdn刷新无异常;

### **问题定位:**

1、比对后端目录发现index.html,game.mini.js中的版本信息是旧的;  
对比publish资源,定位到文件缺失:  
![image1](/assets/1758727509636_a9e668e7.png)  
2、追溯game.min.js,index.html文件的同步、生成:  
由deploy\_fb\_native.sh同步,日志中找到相应输出:js not found  
由命令frameworks/cocos2d-x/tools/cocos2d-console/bin/cocos compile \-p web \-m release \--source-map生成,  
查找相应位置找到输出:No valid JDK installed.  
3、查No valid JDK installed 原因:  
定位到/Users/apple/normal\_builder/ws\_cvs/frameworks/cocos2d-x/tools/cocos2d-console/plugins/plugin\_compile/build\_web/\_\_init\_\_.py  
![image2](/assets/1758727509637_df953e3d.png)  
check\_jdk\_version依赖java \-version命令选择编译jar包  
4、打包机执行java \-version  
bogon:build\_web apple$ java \-version  
openjdk version "21.0.2" 2024\-01-16  
OpenJDK Runtime Environment Homebrew (build 21.0.2)  
OpenJDK 64\-Bit Server VM Homebrew (build 21.0.2, mixed mode, sharing)  
Bash

### **结论:**

#### **打包机java环境升级,导致cocos compile命令执行失败.**

### **解决方案:**

执行cocos compile命令前先切到旧的jdk版本;尝试失败,cocos内部命令调用脚本会启动新的shell实例;  
export PATH\=$JAVA\_HOME/bin:$PATH;  
frameworks/cocos2d-x/tools/cocos2d-console/bin/cocos compile \-p web \-m release  
Bash

强行修改/frameworks/cocos2d-x/tools/cocos2d-console/plugins/plugin\_compile/build\_web/\_\_init\_\_.py中的check\_jdk\_version,强制返回JDK\_1\_7;  
但需要提交代码到分支,该子仓库使用的官方分支,未拉取公司自用分支;  
拉一个自用分支,cv,dh,vegasstart,dhx都需要重新修正子仓库cocos2d-console地址;

#### **切子仓库命令:**

1、cd到framework/cocos2d-x,修改.gitmodules文件,将cocos2d-console地址修改为:  
[**git@github.com**](mailto:git@github.com)**:zhaoheng666/cocos2d-console.git**  
2、将新修改的url同步到子仓库的配置中:git submodule sync  
3、初始化子模块:git submodule init  
4、更新子模块:git submodule update  
5、重新关联子仓库远程分支:cd到cocos2d-console目录git pull origin v3  
如果pull不下来,手动删掉本地v3分支,重新检出origin/v3分支

### **风险评估:**

#### **脚本里加一个校验,game.min.js文件不存在时,报个错,防止文件未生成仍然执行到推送阶段的情况;**



