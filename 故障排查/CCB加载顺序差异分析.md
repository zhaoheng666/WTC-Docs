# CCB加载顺序差异分析

## 问题描述

在Native和HTML5平台上，嵌套CCB文件的`onDidLoadFromCCB`回调执行顺序存在差异：

- **HTML5平台**: 子CCB的`onDidLoadFromCCB` → 父CCB的`onDidLoadFromCCB`（深度优先）
- **Native平台**: 父CCB的`onDidLoadFromCCB` → 子CCB的`onDidLoadFromCCB`（广度优先）

## 根本原因

差异源于两个平台对`animationManagers`集合的管理方式不同。

### HTML5实现机制

1. **共享managers字典**
   ```javascript
   // CCNodeLoader.js:742-746
   parsePropTypeCCBFile: function(node, parent, ccbReader) {
       var myCCBReader = new cc.BuilderReader(ccbReader);
       myCCBReader.setAnimationManagers(ccbReader.getAnimationManagers()); // 共享父的managers

       var ccbFileNode = myCCBReader.readFileWithCleanUp(false);
       ccbReader.setAnimationManagers(myCCBReader.getAnimationManagers()); // 更新回父reader

       return ccbFileNode;
   }
   ```

2. **立即加入共享集合**
   ```javascript
   // CCBReader.js:547-548
   readFileWithCleanUp: function(cleanUp) {
       var node = this._readNodeGraph();
       this._animationManagers.setObject(this._animationManager, node); // 子CCB立即加入
       return node;
   }
   ```

3. **结果**: 子CCB节点先被加入managers集合，遍历时先被处理

### Native实现机制

1. **独立的managers实例**
   ```cpp
   // CCNodeLoader.cpp:990
   Node * NodeLoader::parsePropTypeCCBFile(...) {
       CCBReader * reader = new CCBReader(pCCBReader);
       // 每个reader有独立的_animationManagers
       Node * ccbFileNode = reader->readFileWithCleanUp(false, pCCBReader->getAnimationManagers());
       return ccbFileNode;
   }
   ```

2. **仅加入当前reader的集合**
   ```cpp
   // CCBReader.cpp:352
   Node* CCBReader::readFileWithCleanUp(bool bCleanUp, CCBAnimationManagerMapPtr am) {
       setAnimationManagers(am);
       Node *pNode = readNodeGraph(nullptr);
       _animationManagers->insert(pNode, _animationManager); // 只加入当前reader的manager
       return pNode;
   }
   ```

3. **最后统一收集**
   ```cpp
   // CCBReader.cpp:285-297
   for (auto iter = _animationManagers->begin(); iter != _animationManagers->end(); ++iter) {
       if (_jsControlled) {
           _nodesWithAnimationManagers.pushBack(pNode);
           _animationManagersForNodes.pushBack(manager);
       }
   }
   ```

4. **结果**: 父CCB的manager先被收集，遍历时先被处理

## 执行流程对比

### 示例结构
```
MainCCB
└── SubCCB
    └── SubSubCCB
```

### HTML5执行流程
```
1. MainCCB开始加载
2. 遇到SubCCB属性 → parsePropTypeCCBFile
3. SubCCB.readFileWithCleanUp() → SubCCB加入shared managers
4. 遇到SubSubCCB属性 → parsePropTypeCCBFile
5. SubSubCCB.readFileWithCleanUp() → SubSubCCB加入shared managers
6. 返回SubCCB继续处理
7. 返回MainCCB继续处理 → MainCCB加入shared managers
8. BuilderReader.load遍历顺序：[SubSubCCB, SubCCB, MainCCB]
9. 执行顺序：SubSubCCB.onDidLoadFromCCB() → SubCCB.onDidLoadFromCCB() → MainCCB.onDidLoadFromCCB()
```

### Native执行流程
```
1. MainCCB开始加载
2. 遇到SubCCB属性 → parsePropTypeCCBFile（创建独立reader）
3. SubCCB.readFileWithCleanUp() → SubCCB仅加入自己的managers
4. 遇到SubSubCCB属性 → parsePropTypeCCBFile（创建独立reader）
5. SubSubCCB.readFileWithCleanUp() → SubSubCCB仅加入自己的managers
6. 各级独立返回，不影响父级
7. MainCCB的managers只包含MainCCB自己
8. readNodeGraphFromData收集时只看到MainCCB
9. 执行顺序：MainCCB.onDidLoadFromCCB() → SubCCB.onDidLoadFromCCB() → SubSubCCB.onDidLoadFromCCB()
```

## 影响分析

### 可能的问题场景

1. **初始化依赖**: 如果子CCB依赖父CCB的某些初始化，Native平台可能正常，HTML5平台可能出错
2. **资源加载顺序**: 两个平台的资源准备顺序不同，可能导致表现差异
3. **动画播放**: 自动播放动画的触发时机可能不同

### 解决方案

1. **避免依赖执行顺序**: 不要假设`onDidLoadFromCCB`的调用顺序
2. **使用延迟初始化**: 重要的初始化逻辑放在`onEnter`或首帧更新中
3. **显式管理依赖**: 通过事件或回调链明确控制初始化顺序

## 调用堆栈对比

### ccNodeLoader.parseProperties调用堆栈

#### 通用调用链
```javascript
cc.BuilderReader.load()                                     // 入口
    reader.readNodeGraphFromFile(ccbFilePath)              // 读取文件
        this.readNodeGraphFromData(data)                   // 解析数据
            this._readNodeGraph()                           // 构建节点树
                ccNodeLoader.parseProperties(node, parent) // 解析属性

// 递归处理子节点
this._readNodeGraph(parent)
    for (i = 0; i < numChildren; i++) {
        var child = this._readNodeGraph(node)              // 递归
            ccNodeLoader.parseProperties(node, parent)     // 每个子节点
        node.addChild(child)
    }
```

## 技术细节

### 关键差异点

| 特性 | HTML5 | Native |
|------|-------|--------|
| **managers管理** | 共享字典，子CCB直接操作父的managers | 每个reader独立，最后合并 |
| **加入时机** | 解析时立即加入 | 仅加入自己的集合 |
| **收集方式** | 按加入顺序（深度优先） | 按最终reader的集合（广度优先） |
| **数据结构** | cc._Dictionary | std::unordered_map |

### 相关文件

- HTML5实现：
  - `frameworks/cocos2d-html5/extensions/ccb-reader/CCBReader.js`
  - `frameworks/cocos2d-html5/extensions/ccb-reader/CCNodeLoader.js`

- Native实现：
  - `frameworks/cocos2d-x/cocos/editor-support/cocosbuilder/CCBReader.cpp`
  - `frameworks/cocos2d-x/cocos/editor-support/cocosbuilder/CCNodeLoader.cpp`
  - `frameworks/cocos2d-x/cocos/scripting/js-bindings/script/jsb_cocosbuilder.js`

## 记录信息

- 分析日期：2025-09-24
- 涉及版本：Cocos2d-html5 v3.13-lite-wtc
- 影响范围：所有使用嵌套CCB的场景