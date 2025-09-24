# CCB嵌套-加载时序差异问题

## 案例现场

![1758706517331](http://localhost:5173/WTC-Docs/assets/故障排查_CCB加载顺序Native-HTML5差异分析_60ba459caf3a.png)

![1758706529154](http://localhost:5173/WTC-Docs/assets/故障排查_CCB加载顺序Native-HTML5差异分析_df0bb10be159.png)

父 CCB controller. `onDidLoadFromCCB` 中调用子 CCB Controller方法，在 native 端报错，子 CCB controller undefined；

## 问题定位

在Native和HTML5平台上，嵌套CCB文件的 `onDidLoadFromCCB` 回调执行顺序存在差异：

- **HTML5平台**: 子CCB的 `onDidLoadFromCCB` → 父CCB的 `onDidLoadFromCCB`
- **Native平台**: 父CCB的 `onDidLoadFromCCB` → 子CCB的 `onDidLoadFromCCB`

![1758698625269](http://localhost:5173/WTC-Docs/assets/故障排查_CCB加载顺序Native-HTML5差异分析_f39e9a625349.png)![1758703526432](http://localhost:5173/WTC-Docs/assets/故障排查_CCB加载顺序Native-HTML5差异分析_9833ce5d17aa.png)

## 原因分析

**nodesWithAnimationManagers 遍历顺序不同**

### cc.BuilderReader.load 对比：

  html5 端：CCBReader.js

```javascript
cc.BuilderReader.load = function (ccbFilePath, owner, parentSize, ccbRootPath) {
    ...
    var node = reader.readNodeGraphFromFile(ccbFilePath, owner, parentSize);
    ...

    // Attach animation managers to nodes and assign root node callbacks and member variables
    for (i = 0; i < nodesWithAnimationManagers.length; i++) {
        var innerNode = nodesWithAnimationManagers[i];
        var animationManager = animationManagersForNodes[i];
        ...
        // Create a controller
        var controllerClass = controllerClassCache[controllerName];
        ...
        innerNode.controller = controller;
        controller.rootNode = innerNode;
        ...
        // Callbacks
        ...

        // Variables
        ...

        if (controller.onDidLoadFromCCB && cc.isFunction(controller.onDidLoadFromCCB))
            controller.onDidLoadFromCCB();

        // Setup timeline callbacks
        ...
    }

    // Assign owner callbacks & member variables
    if (owner) {
        ...
    }
    //auto play animations
    var autoId = animationManager.getAutoPlaySequenceId();
    if (autoId >= 0) {
        animationManager.runAnimations(autoId, 0);
    }

    return node;
};
```

native 端：jsb_cocosbuilder.js

```javascript


cc.BuilderReader.load = function(file, owner, parentSize)
{
    // Load the node graph using the correct function
    var reader = cc._Reader.create();   // CCBReader.cpp
    reader.setCCBRootPath(cc.BuilderReader._resourcePath);

    var node;

    if (parentSize)
    {
        node = reader.load(file, null, parentSize);
    }
    else
    {
        node = reader.load(file);
    }

    // Assign owner callbacks & member variables
    if (owner)
    {
        ...
    }

    ...
    // Attach animation managers to nodes and assign root node callbacks and member variables
    for (var i = 0; i < nodesWithAnimationManagers.length; i++)
    {
        ...

        // Create a controller
        var controllerClass = controllerClassCache[controllerName];
        if(!controllerClass) throw "Can not find controller : " + controllerName;
        var controller = new controllerClass();
        controller.controllerName = controllerName;

        innerNode.controller = controller;
        controller.rootNode = innerNode;

        // Callbacks
        ...

        // Variables
        ...

        // Start animation
        var autoPlaySeqId = animationManager.getAutoPlaySequenceId();
        if (autoPlaySeqId != -1)
        {
            animationManager.runAnimationsForSequenceIdTweenDuration(autoPlaySeqId, 0);
        }
    }

    return node;
};
```

### nodesWithAnimationManagers 插入对比：

**Native端 - 直接遍历Map**：

```cpp
// CCBReader.cpp:285-296
for (auto iter = _animationManagers->begin(); iter != _animationManagers->end(); ++iter) {
    Node* pNode = iter->first;
    CCBAnimationManager* manager = iter->second;
    ...
    if (_jsControlled) {
        _nodesWithAnimationManagers.pushBack(pNode);      // 按迭代器顺序收集
        _animationManagersForNodes.pushBack(manager);
    }
}
```

**HTML5端 - 通过allKeys()收集**：

```javascript
// CCBReader.js:292-297
var locAnimationManagers = this._animationManagers;
var getAllKeys = locAnimationManagers.allKeys();          // 关键：allKeys()的返回顺序
for (var i = 0; i < getAllKeys.length; i++) {
    locNodes.push(getAllKeys[i]);                         // 按allKeys顺序收集
    locAnimations.push(locAnimationManagers.objectForKey(getAllKeys[i]));
}
```

**allKeys()实现**：

```javascript
// CCTypes.js:868-872
allKeys: function () {
    var keyArr = [], locKeyMapTb = this._keyMapTb;
    for (var key in locKeyMapTb)                          // JavaScript for...in遍历
        keyArr.push(locKeyMapTb[key]);
    return keyArr;
}
```

### animationManagers 数据结构对比：

- **Native**: `cocos2d::Map` → `std::unordered_map<Node*, CCBAnimationManager*>`
- **HTML5**: `cc._Dictionary` → JavaScript对象 + `for...in`

### animationManagers 插入方式对比：

**Native端 - 共享引用插入**：

```cpp
// parsePropTypeCCBFile (CCNodeLoader.cpp:990)
Node * ccbFileNode = reader->readFileWithCleanUp(false, pCCBReader->getAnimationManagers());
                                                         // ↑传入父CCB的managers

// readFileWithCleanUp (CCBReader.cpp:348-352)
setAnimationManagers(am);                               // 设置为父CCB的managers（引用）
Node *pNode = readNodeGraph(nullptr);
_animationManagers->insert(pNode, _animationManager);   // 直接插入到共享的map中
```

**HTML5端 - 同样是共享引用插入**：

```javascript
// parsePropTypeCCBFile (CCNodeLoader.js:742-746)
myCCBReader.setAnimationManagers(ccbReader.getAnimationManagers()); // 设置为父的managers（引用）
...
var ccbFileNode = myCCBReader.readFileWithCleanUp(false);
ccbReader.setAnimationManagers(myCCBReader.getAnimationManagers()); // 引用回传

// readFileWithCleanUp (CCBReader.js:548)
this._animationManagers.setObject(this._animationManager, node);    // 插入到共享的managers
```

**setAnimationManagers实现**：

```javascript
// CCBReader.js:511-513
setAnimationManagers: function (animationManagers) {
    this._animationManagers = animationManagers;        // 引用赋值
}
```

### 结论：

native 端数据类型 `std::unordered_map<Node*, CCBAnimationManager*> `，未保证插入、遍历顺序

## 解决方案

1. **避免依赖执行顺序**: 不要假设 `onDidLoadFromCCB`的调用顺序
2. **使用延迟初始化**: 重要的初始化逻辑放在 `onEnter`或首帧更新中
3. **显式管理依赖**: 通过事件或回调链明确控制初始化顺序

## 相关代码位置

- HTML5实现：

  - [`frameworks/cocos2d-html5/extensions/ccb-reader/CCBReader.js`](https://github.com/LuckyZen/cocos2d-html5/blob/60e61653/extensions/ccb-reader/CCBReader.js)
  - [`frameworks/cocos2d-html5/extensions/ccb-reader/CCNodeLoader.js`](https://github.com/LuckyZen/cocos2d-html5/blob/60e61653/extensions/ccb-reader/CCNodeLoader.js)
- Native实现：

  - [`frameworks/cocos2d-x/cocos/editor-support/cocosbuilder/CCBReader.cpp`](https://github.com/LuckyZen/cocos2d-x/blob/e904f3c5de/cocos/editor-support/cocosbuilder/CCBReader.cpp)
  - [`frameworks/cocos2d-x/cocos/editor-support/cocosbuilder/CCNodeLoader.cpp`](https://github.com/LuckyZen/cocos2d-x/blob/e904f3c5de/cocos/editor-support/cocosbuilder/CCNodeLoader.cpp)
  - [`frameworks/cocos2d-x/cocos/scripting/js-bindings/script/jsb_cocosbuilder.js`](https://github.com/LuckyZen/cocos2d-x/blob/e904f3c5de/cocos/scripting/js-bindings/script/jsb_cocosbuilder.js)
  - [`frameworks/cocos2d-x/cocos/scripting/js-bindings/manual/cocosbuilder/js_bindings_ccbreader.cpp`](https://github.com/LuckyZen/cocos2d-x/blob/e904f3c5de/cocos/scripting/js-bindings/manual/cocosbuilder/js_bindings_ccbreader.cpp)
