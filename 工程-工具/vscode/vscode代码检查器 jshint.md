# vscode代码检查器 jshint

### 一、代码检查器的必要性

- 1、将重要的语法错误暴露在开发过程，而不是依赖 build 检查、或遗留到发布报错；

  - 例如实参列表中的尾随逗号，es8 语法是支持的，现代浏览器运行也不会出现报错，'Trailing comma in arguments lists' is only available in ES8 (use 'esversion: 8'). (W 119) jshint (W119)

  - 如果本地启动时未做语法检查，该问题将不会在本地运行时暴露；

- 2、规范统一代码风格，代码合规、避免潜在风险；

### 二、jshint 效果：

- 开启前：

![image](http://localhost:5173/WTC-Docs/assets/1758174599842_86f13173.png)​

- 开启后：

ge![image](http://localhost:5173/WTC-Docs/assets/1758174599843_d38e6e34.png)​

### 三、webstrom 开启集成 jshint：

使用项目公用配置

![image](http://localhost:5173/WTC-Docs/assets/1758174599845_34926313.png)​

### 四、vscode 开启 jshint：

- 1、安装 jshint: `npm install jshint --save-dev`​

  ![image](http://localhost:5173/WTC-Docs/assets/1758174599845_f4e01897.png)​

- 2、安装 vscode-插件：

![image](http://localhost:5173/WTC-Docs/assets/1758174599846_cbe1bbfb.png)​

- 使用项目公用配置：

  ![image](http://localhost:5173/WTC-Docs/assets/1758174599846_717240cb.png)​

‍
