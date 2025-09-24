# CCB 加载顺序问题分析报告

## 问题现象

在 `PrizePoolController` 中，`this._ccbConner` 对象在不同生命周期和平台上表现不一致：

### Android 平台
- 在 `onDidLoadFromCCB` 中：`_ccbConner` 存在但其 `controller` 属性为 `undefined`
- 在 `onEnter` 中：`_ccbConner.controller` 正常存在
- 日志输出：对象显示为 `{}`（这是 Android 日志系统的特性）

### 浏览器平台（HTML5）
- 在 `onDidLoadFromCCB` 中：`_ccbConner` 及其 `controller` 属性都正常存在
- 日志输出：对象正常显示

## 问题根本原因

CCB 文件加载和控制器创建的顺序在不同平台上存在差异：

### 1. Android 日志显示问题
- 原因：`cc.formatStr` 在 Native 平台上将对象转换为字符串 `"{}"`
- 位置：`/frameworks/cocos2d-x/cocos/scripting/js-bindings/script/jsb_boot.js:764`
```javascript
str = '' + str;  // 将对象转换为字符串表示
```

### 2. 控制器创建时机差异

#### HTML5 平台（深度优先）
- 实现位置：`/frameworks/cocos2d-html5/extensions/ccb-reader/CCNodeLoader.js:745`
- 加载子 CCB 时立即递归处理：
```javascript
var ccbFileNode = myCCBReader.readFileWithCleanUp(false);
// 子节点的控制器在此时创建
```
- 执行顺序：子节点控制器 → 子节点 `onDidLoadFromCCB` → 父节点 `onDidLoadFromCCB`

#### Native 平台（广度优先）
- C++ 收集节点：`/frameworks/cocos2d-x/cocos/editor-support/cocosbuilder/CCBReader.cpp:285-297`
```cpp
if (_jsControlled) {
    _nodesWithAnimationManagers.pushBack(pNode);  // 按广度优先顺序收集
    _animationManagersForNodes.pushBack(manager);
}
```
- JavaScript 批量处理：`/frameworks/cocos2d-x/cocos/scripting/js-bindings/script/jsb_cocosbuilder.js:105-168`
```javascript
for (var i = 0; i < nodesWithAnimationManagers.length; i++) {
    // 按列表顺序创建控制器并调用 onDidLoadFromCCB
    controller.onDidLoadFromCCB();
}
```
- 执行顺序：父节点 `onDidLoadFromCCB` → 子节点控制器创建 → 子节点 `onDidLoadFromCCB`

## 关键代码位置

### 1. 问题代码
- **文件**：`/src/slot/controller/PrizePoolController.js`
- **行号**：103
- **代码**：
```javascript
this._ccbConner && this._ccbConner.controller.initWith(this);
```

### 2. 平台差异实现

#### HTML5 递归加载
- **文件**：`/frameworks/cocos2d-html5/extensions/ccb-reader/CCNodeLoader.js`
- **行号**：745
- **特点**：立即递归处理子 CCB

#### Native 批量处理
- **C++ 收集**：`/frameworks/cocos2d-x/cocos/editor-support/cocosbuilder/CCBReader.cpp:285-297`
- **JS 处理**：`/frameworks/cocos2d-x/cocos/scripting/js-bindings/script/jsb_cocosbuilder.js:105-168`
- **特点**：先收集所有节点，后批量创建控制器

## 解决方案

### 方案一：延迟初始化（推荐）
将子控制器的初始化移到 `onEnter` 中：

```javascript
PrizePoolController.prototype.onEnter = function () {
    PrizePoolBetController.prototype.onEnter.call(this);

    // 在这里初始化子控制器，确保所有平台都已创建完成
    if (this._ccbConner && this._ccbConner.controller) {
        this._ccbConner.controller.initWith(this);
    }
};
```

### 方案二：条件检查
在 `onDidLoadFromCCB` 中添加平台判断：

```javascript
PrizePoolController.prototype.onDidLoadFromCCB = function () {
    // ... 其他代码 ...

    // 只在浏览器端初始化，Native 端等到 onEnter
    if (this._ccbConner && this._ccbConner.controller) {
        this._ccbConner.controller.initWith(this);
    }
};
```

### 方案三：使用事件通知
让子控制器在创建完成后主动通知父控制器：

```javascript
// PrizePoolConnerController.js
PrizePoolConnerController.prototype.onDidLoadFromCCB = function () {
    // 通知父控制器我已准备好
    if (this.rootNode.parent && this.rootNode.parent.controller) {
        this.rootNode.parent.controller.onChildControllerReady(this);
    }
};

// PrizePoolController.js
PrizePoolController.prototype.onChildControllerReady = function(childController) {
    if (childController === this._ccbConner.controller) {
        childController.initWith(this);
    }
};
```

## 调试建议

1. **避免直接打印对象**：在 Native 平台上使用具体属性检查
```javascript
cc.warn("_ccbConner exists:", !!this._ccbConner,
        "has controller:", !!(this._ccbConner && this._ccbConner.controller));
```

2. **添加生命周期日志**：跟踪控制器创建顺序
```javascript
cc.warn(this.constructor.name, "onDidLoadFromCCB called at", Date.now());
```

3. **使用断点调试**：在浏览器端可以更直观地查看对象结构

## 总结

这个问题的核心是 Cocos2d-JS 在不同平台上的 CCB 加载实现存在差异：
- **HTML5**：深度优先，递归加载，子节点先于父节点完成
- **Native**：广度优先，批量处理，父节点先于子节点完成

理解这个差异对于跨平台开发非常重要，建议在涉及父子控制器交互的场景中，统一使用 `onEnter` 生命周期来确保初始化顺序的一致性。