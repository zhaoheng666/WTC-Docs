# 海报中心 createProgram is not a function 错误

## 摘要

| 项目 | 内容 |
|------|------|
| 状态 | ✅ 已解决 |
| 提交 | - |
| 文件 | [src/task/controller/poster_center/PosterCenterMainController.js](/../../src/task/controller/poster_center/PosterCenterMainController.js#L88-L91) |
| 原因 | 宣发或海报资源损坏导致 WebGL 上下文丢失 |
| 现场记录 | 👉 [CV发版通知群 2025年11月24日](https://ghoststudio.feishu.cn/wiki/NeDTwn325i5svbkJmujc3CFynaf) |

## 问题描述

**发生时间**：2025年11月24日
**报告人**：曹霞
**分析人**：赵恒
**现象**：正常 loading 进入游戏时偶发卡住，重进就正常了

## 错误信息

### 主要错误
```
Uncaught TypeError: c.createProgram is not a function
    at CCGLProgram.js:146
```

### 伴随错误
```
Uncaught InvalidStateError: Failed to execute 'drawImage' on 'CanvasRenderingContext2D':
The HTMLImageElement provided is in the 'broken' state.
```

## 问题分析

**根本原因**：上边的 InvalidStateError 错误导致 WebGL 渲染中断、GL 上下文丢失，引发下边的 createProgram 报错。

**可能原因**：
1. 宣发或海报资源中某张图片下载异常
2. 宣发或海报资源中某张图片文件损坏

## 解决方案

### 临时解决
重新进入游戏即可恢复正常

### 建议修复
1. 检查刚发布的宣发资源是否有异常
2. 在代码层面增加图像加载状态检查，避免使用损坏的图像资源

## 相关文件

- [PosterCenterMainController.js](/../故障排查/src/task/controller/poster_center/PosterCenterMainController.js#L88-L91)
- [PosterCenterBlurUtil.js](/../故障排查/src/task/controller/poster_center/PosterCenterBlurUtil.js#L56-L91)
- [PosterCenterBoardController.js](/../故障排查/src/task/controller/poster_center/PosterCenterBoardController.js#L38)
- [CCSpriteCanvasRenderCmd.js](/../故障排查/frameworks/cocos2d-html5/cocos2d/core/sprites/CCSpriteCanvasRenderCmd.js#L154)
- [CCGLProgram.js](/../故障排查/frameworks/cocos2d-html5/cocos2d/shaders/CCGLProgram.js#L146)

## 历史记录

### 2025-11-24 问题发现
- **报告人**：曹霞
- **分析人**：赵恒
- **现象**：正常 loading 进入游戏时偶发卡住
- **结论**：宣发或海报资源异常导致渲染中断

## 注意事项

1. 该错误为偶发性，难以稳定复现
2. 通常与新发布的宣发/海报资源相关
3. 重进游戏可暂时解决，但根本问题需要代码层面修复
4. 建议优先检查最近更新的宣发资源

## 标签

`海报中心` `WebGL` `Canvas` `资源加载` `渲染错误` `偶发问题`