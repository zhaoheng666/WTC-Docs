# Slots BigWin 动画之前 Spin 结果加倍流程 - 程序

主要针对类似视频中的加倍过程进行统一封装处理。

该动画过程出现在播赢钱线后、弹出 bigWin 动画之前。

根据左侧页签查看程序相关用法及美术注意事项。

![BigWin 动画流程示例](http://localhost:5173/WTC-Docs/assets/1760346210618_b5dab9d3.gif)

## 程序配置

### 基础配置

已在创建关卡文件时增加以下配置：

```javascript
// 结果加倍流程总开关
this.machineConfig.useSpinResultMultiUpAction = false;

// 动画ccb
this.machineConfig.spinResultMultiUpAnimCCB = "";

// 需注意动画ccb中必须有 _multiLabel、_winChipsLabel 节点，用于展示倍数、赢钱

// 生效的玩法：base/freeSpin/respin 注意大小写，在SpinResultmultiUpAction中判断
this.machineConfig.multiUpActionGameTypeList = ["base", "freeSpin", "respin"];

// 加倍动画的总时长
this.machineConfig.multiUpAnimTime = 3;

// 加倍动画开始后，第几帧开始更新展示的结果，结合动画确定时间点。
this.machineConfig.delayTimeMultiUpWinChips = 1+11/30;

// 倍数区间及对应字体，如果不使用区间不同颜色字体配置，直接注释掉该配置
this.machineConfig.multiUpFontRangeConfig = [
    {multi: 1, fontFile: "", fontColor: cc.color.WHITE}, // 1~5倍对应字体文件
    {multi: 6, fontFile: "", fontColor: cc.color(250, 200, 155)}, // 6~15倍对应字体文件
    {multi: 16, fontFile: ""}, // 16倍及以上对应字体
    // ...
    // ...
]; // 该配置详解看下面的 "动画流程.2"
```

## 动画流程

### 1. 预留数据及状态记录接口

在播放动画前会判断调用 `machineScene.onEnterSpinResultMultiUpAction` 方法，在该接口中做一些特殊的状态记录等相关操作，按需使用。

### 2. 创建并播放动画节点

将动画 ccb 路径配置好，会在 slotMachineScene 的最上层创建动画节点。

- 判断是否有 appear 时间线，播放 appear 或默认时间线
- 根据本次 spin 的结果，设置初始赢钱及倍数展示

#### multiUpFontRangeConfig 配置说明：

- **multi**：区间的起始倍数，代码会自动根据多个配置来定位所在区间。需注意数组中第一个配置的 multi 必须为 1，后续元素按需求进行配置
- **fontFile**：所在区间的字体文件，通常需求会根据倍数的区间使用不同颜色效果的字体展示，可根据需求进行配置使用不同字体。如果使用 ccb 中默认字体的话，删掉 fontFile 字段或保持空字符即可
- **fontColor**：字体颜色，通常用于不使用字体文件时，如果不同倍数区间美术使用同一字体文件，使用颜色 rgb 色号进行区分的话，将美术人员提供的色号填到对应的区间即可。不需要时不配置该字段

> **注意**：fontFile 与 fontColor 可结合使用，两者不冲突。

### 3. delayTimeMultiUpWinChips 控制时机

### 4. 赢钱文本展示更新

动画中的赢钱展示播放 NumberAnimation 动画

### 5. 等待动画全部播放结束

### 6. 清除动画节点

### 7. 进入下一流程，判断 bigWin

## 美术、动画

### 美术注意事项

1. 展示赢钱的文本所用字体，不要缺少逗号 `,` 分隔符

2. 倍数的展示不得使用图片，必须使用字体文本

3. 根据策划需求，根据所需效果，生成多种字体满足倍数区间的不同展示效果

   例如：1~5倍使用字体a、6~10倍使用字体b、11倍及以上使用字体c......

4. 如果不同区间使用同一个字体，采用设置字体颜色的方案来实现不同区间展示效果的话，需要向程序详细提供不同区间所对应的颜色rgb值

![字体配置示例](http://localhost:5173/WTC-Docs/assets/1760346210615_7163febf.png)

### 动画注意事项

1. 赢钱、倍数的展示文本相关的动画效果尽量在上层节点中添加

2. 赢钱、倍数的展示文本 label 必须是动画文件 ccb 中的节点，不可使用嵌套 ccb 的方式

3. 制作时可顺手帮忙设置一下文本节点绑定变量：
   - 赢钱文本：`_winChipsLabel`
   - 倍数文本：`_multiLabel`

![节点绑定示例](http://localhost:5173/WTC-Docs/assets/1760346210616_05b05e2d.png)