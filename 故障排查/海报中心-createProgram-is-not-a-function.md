# 海报中心 createProgram is not a function 错误

## 问题描述

**发生时间**：2025年11月24日
**报错位置**：海报中心（PostCenter）
**影响**：页面卡住，无法正常进入游戏
**复现概率**：偶发，重进即正常

## 错误堆栈

### 错误1：InvalidStateError（首发错误）
```
Uncaught InvalidStateError: Failed to execute 'drawImage' on 'CanvasRenderingContext2D':
The HTMLImageElement provided is in the 'broken' state.
    at CCSpriteCanvasRenderCmd.js:154
```

### 错误2：TypeError（连锁错误）
```
Uncaught TypeError: c.createProgram is not a function
    at CCGLProgram.js:146
    at c.initWithVertexShaderByteArray (CCGLProgram.js:146:28)
    at c.initWithString (CCGLProgram.js:187:16)
    at Object.getShaderProgram (game.js:569038)
    at Object.createBlurSprite (game.js:569051)
    at PosterCenterMainController.initBg (game.js:569636)
    at PosterCenterBoardController.initUI (game.js:569122:21)
```

## 错误分析

### 根本原因
图像资源加载失败或损坏，导致渲染链条中断：

1. **图像损坏** → Canvas `drawImage` 失败
2. **Canvas 渲染失败** → WebGL 上下文异常
3. **WebGL 上下文丢失** → `createProgram` 方法不可用
4. **Shader 创建失败** → 海报中心初始化失败

### 触发路径
```
PosterCenterMainController.initBg (第91行)
    ↓
PosterCenterBlurUtil.createBlurSprite (创建模糊效果)
    ↓
new cc.GLProgram() (创建着色器程序)
    ↓
initWithVertexShaderByteArray (初始化着色器)
    ↓
locGL.createProgram() ❌ (WebGL上下文已失效)
```

### 可能原因

1. **资源加载异常**
   - 宣发或海报资源中某张图片下载失败（网络问题）
   - 图片文件损坏或格式不支持
   - 资源服务器临时故障

2. **渲染环境问题**
   - Canvas 模式下错误调用 WebGL API
   - WebGL 上下文数量达到浏览器限制
   - GPU 内存不足或驱动问题

3. **时序问题**
   - 资源未完全加载就尝试使用
   - 场景切换时资源释放与创建的竞态条件

## 解决方案

### 临时解决
用户重新进入游戏即可恢复正常

### 代码修复方案

#### 1. 添加图像验证（PosterCenterMainController.js）
```javascript
PosterCenterMainController.prototype.initBg = function (spBg) {
    cc.log("PosterCenterMainController.initBg");
    if (!this._nodeBg || !this._bgMask || !spBg) return;

    // 添加图像状态检查
    var texture = spBg.getTexture();
    if (!texture || !texture.isLoaded()) {
        cc.error("PosterCenterMainController: 背景图像未正确加载");
        return;
    }

    // 检查图像是否有效
    var image = texture.getHtmlElementObj();
    if (image && (image.complete === false || image.naturalWidth === 0)) {
        cc.error("PosterCenterMainController: 背景图像损坏或无效");
        game.BuglyHelper.buglyLogInfo("PosterCenter", "背景图像损坏: " + texture.url);
        return;
    }

    var bg = PosterCenterBlurUtil.createBlurSprite(spBg, 1.5);
    if (!bg) {
        cc.warn("PosterCenterMainController: 创建模糊背景失败，使用原始背景");
        bg = spBg; // 降级使用原始精灵
    }
    // ... 后续代码
};
```

#### 2. 增强模糊效果兼容性（PosterCenterBlurUtil.js）
```javascript
createBlurSprite: function (sprite) {
    cc.log("PosterCenterBlurUtil.createBlurSprite");
    game.BuglyHelper.buglyLogInfo("PosterCenter", "createBlurSprite");

    // 检查渲染模式
    if (cc._renderType === cc.game.RENDER_TYPE_CANVAS) {
        cc.warn("PosterCenterBlurUtil: Canvas模式下不支持模糊效果");
        return sprite; // 返回原始精灵
    }

    // 验证 WebGL 上下文
    if (!cc._renderContext || typeof cc._renderContext.createProgram !== 'function') {
        cc.error("PosterCenterBlurUtil: WebGL上下文无效");
        game.BuglyHelper.buglyLogInfo("PosterCenter", "WebGL上下文无效");
        return sprite; // 降级处理
    }

    // 检查精灵纹理
    var texture = sprite.getTexture();
    if (!texture || !texture.isLoaded()) {
        cc.error("PosterCenterBlurUtil: 精灵纹理未加载");
        return sprite;
    }

    try {
        // 创建着色器程序
        var program = PosterCenterBlurUtil.getShaderProgram();
        if (!program) {
            cc.error("PosterCenterBlurUtil: 无法创建着色器程序");
            return sprite;
        }
        // ... 后续代码
    } catch (e) {
        cc.error("PosterCenterBlurUtil: 创建模糊效果失败", e);
        game.BuglyHelper.buglyLogInfo("PosterCenter", "模糊效果异常: " + e.message);
        return sprite; // 降级处理
    }
};
```

#### 3. Canvas渲染保护（CCSpriteCanvasRenderCmd.js）
```javascript
// 在 drawImage 调用前添加检查（第154行附近）
if (!image || image.complete === false || image.naturalWidth === 0) {
    cc.warn("CCSpriteCanvasRenderCmd: 跳过损坏的图像渲染");
    return;
}

// 使用 try-catch 包装 drawImage
try {
    context.drawImage(image, sx, sy, sw, sh, x, y, w, h);
} catch (e) {
    cc.error("CCSpriteCanvasRenderCmd: drawImage 失败", e);
    // 可选：绘制占位符
    context.fillStyle = '#999';
    context.fillRect(x, y, w, h);
}
```

## 预防措施

### 1. 资源预加载验证
```javascript
// 进入海报中心前确保资源完整
var posterResources = [
    // 海报资源列表
];

cc.loader.load(posterResources, function(err, results) {
    if (err) {
        cc.error("海报中心资源加载失败:", err);
        // 显示错误提示
        return;
    }

    // 验证每个资源
    for (var i = 0; i < results.length; i++) {
        if (!results[i] || (results[i].naturalWidth === 0)) {
            cc.error("资源损坏:", posterResources[i]);
            // 记录到 Bugly
            game.BuglyHelper.buglyLogInfo("PosterCenter", "资源损坏: " + posterResources[i]);
        }
    }

    // 资源验证通过后再进入
    this.enterPosterCenter();
}.bind(this));
```

### 2. 监控和日志
- 增加 Bugly 日志记录关键节点
- 记录资源 URL 和加载状态
- 监控 WebGL 上下文状态

### 3. 降级策略
- Canvas 模式下禁用模糊效果
- 图像加载失败时使用默认图
- WebGL 失败时回退到 Canvas 渲染

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