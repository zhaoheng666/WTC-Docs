# AI编程模型和RooCode配置教程

## 一、安装Roo Code

1、打开VSCode

2、点击插件按钮，搜索Roo Code

3、点击Install安装

![image1](http://localhost:5173/WTC-Docs/assets/1758727509512_c2bd9e6b.png)

4、点击左侧的小火箭按钮，打开Roo Code

![image2](http://localhost:5173/WTC-Docs/assets/1758727509513_d7c6b3f2.png)

5、点击Roo Code右上角的设置图标

6、API Provider选择**OpenAI Compatible**，  
Base URL填写：**http://chatgpt-corp.ghoststudio.net/v1**  
API Key填写：**sk-au3fWPoVtB54KSwm0356F35915464dD1Bd56120d02A842D2**  
Model名字填写：**gemini-2.5-flash**  
勾选Enable streaming  
点击Done保存

**目前支持的模型列表：**

| Model名字 | 最大上下文窗口 | 速度 | [编程能力评分](https://livebench.ai/#/?Coding=a) | 适合工作 |
| :---- | :---- | :---- | :---- | :---- |
| **deepseek-v3** | **65000** | **11.41t/s 较慢** | **61.77** | **Code** |
| qwen-max | 32000 | 50.81t/s 较快 | 64.41 | Code |
| qwen2.5-coder:32b | 128000 | 62.81t/s 较快 | 56.85 | Code |
| qwen-coder-plus | 131000 | 60.65t/s 较快 | 54.9 | Code |
| **gemini-2.5-flash** | **1000000** | **161.6t/s 很快** | **53.92** | **Code** |
| deepseek-r1 | 65000 | 20.12t/s 较慢 | 66.74 | Architect |
| o3-mini | 200000 | 1061t/s 很快 | 65.38 | Architect |

其中，推理模型适合用来进行Architect，不适合用来生成Code，可以通过在Provider Settings中建立多个Configuration Profile，并在Architect和Code的时候进行选择切换。另外，由于推理模型需要思考，首次输出会在思考结束之后才会有结果，请耐心等待。

![image3](http://localhost:5173/WTC-Docs/assets/1758727509515_ec1985f4.png)

7、配置模型的上下文窗口大小：

展开Model Configuration，将Context Window Size根据上面的表格，填写模型对应的最大的上下文窗口大小，以方便大模型一次就能提交更多的内容上去。

此外，由于编程模型不支持图片识别，还应该取消Image Support勾选。配置完成后点击Done保存。  
![image4](http://localhost:5173/WTC-Docs/assets/1758727509517_63e3bd82.png)  
8、配置思考语言

由于大模型采用英文语料训练，因而让大模型使用英文进行思考可获得更高的智力和准确度，配置方法如下：

点击Roo Code上方第二个按钮，进入Prompts配置，在Preferred language中选择English，点击Done保存。

![image5](http://localhost:5173/WTC-Docs/assets/1758727509518_d9d23856.png)

## 二、使用Roo Code

1、在VSCode的File菜单，点击Open Folder，打开工程

2、点击Roo Code按钮，可以开始工作了。

具体教程可参考官网：  
[https://github.com/RooVetGit/Roo-Code](https://github.com/RooVetGit/Roo-Code)

也可自己去Bilibili搜索Roo Code或Cline教程。  










