# onDidLoadFromCCB 生命周期问题

‍

![image](/assets/55b04b426c2b877706dd96ea9f1a004e.png)

![image](/assets/b6931fa26a610ff82b0a34b5766169d5.png)

![image](/assets/94da6c2cae8c2112e34cf0444f39a97f.png)

![image](/assets/f0a99508d72a8454c297c5dd4a3a7c00.png)

‍

![image](/assets/6d6be2cf16d1e19d23cf0f0c1bf7b6a3.png)

![image](/assets/bdd6d1ca784bac36c3378b52d2362094.png)

执行顺序差异的根本原因

  在浏览器端（HTML5）：

1. 深度优先遍历：当解析 CCB 文件时，遇到嵌套的 CCB  
    文件引用会立即递归加载  
    - 在 CCNodeLoader.js:745  
    中，parsePropTypeCCBFile 会立即调用  
    myCCBReader.readFileWithCleanUp(false)  
    - 这会递归地加载子 CCB 文件  
    - 子节点的 controller 先创建和初始化
2. 执行顺序：
3. 主 CCB 开始加载
4. 遇到 _ccbConner (子 CCB 引用)
5. 立即加载子 CCB -> 创建  
    PrizePoolConnerController -> 调用其  
    onDidLoadFromCCB
6. 继续加载主 CCB
7. 主 CCB 加载完成 -> 调用  
    PrizePoolBetController.onDidLoadFromCCB

  在 Native 端（Android/iOS）：

1. 广度优先处理：Native 的 C++  
    实现可能使用了不同的加载策略  
    - 先完成整个节点树的构建  
    - 然后在 cc.BuilderReader.load 中统一处理所有  
    controller
2. 执行顺序：
3. 主 CCB 加载，构建完整节点树（包括子 CCB 节点）
4. 主控制器的 onDidLoadFromCCB 先被调用
5. 在 cc.BuilderReader.load  
    的后处理阶段（第994-1055行）
6. 遍历所有需要 controller 的节点
7. 创建并初始化子 controller -> 调用  
    PrizePoolConnerController.onDidLoadFromCCB

  关键代码差异：

  HTML5 版本（CCNodeLoader.js:744-745）：  
  // 立即递归加载子 CCB  
  var ccbFileNode =  
  myCCBReader.readFileWithCleanUp(false);

  Native 版本：

- C++ 层的实现可能延迟了子 CCB controller 的创建
- 在 js_bindings_ccbreader.cpp  
  中，readNodeGraphFromFile 的 C++ 实现策略不同

1. Native 端收集节点信息

  在 /frameworks/cocos2d-x/cocos/editor-support/cocosbuilder/CCBReader.cpp 的第 285-297  
   行：

  for (auto iter = _animationManagers->begin(); iter != _animationManagers->end();  
  ++iter)  
  {  
      Node* pNode = iter->first;  
      CCBAnimationManager* manager = iter->second;

      pNode->setUserObject(manager);

      if (_jsControlled)  
      {  
          _nodesWithAnimationManagers.pushBack(pNode);  // 收集所有带动画管理器的节点  
          _animationManagersForNodes.pushBack(manager);   // 收集对应的动画管理器  
      }  
  }

  这里 C++ 层收集了所有带有动画管理器的节点，然后通过 JSB 返回给 JavaScript 层。

2. JavaScript 端批量处理

  在 /frameworks/cocos2d-x/cocos/scripting/js-bindings/script/jsb_cocosbuilder.js 的第  
  105-168 行：

  // 遍历所有带动画管理器的节点  
  for (var i = 0; i < nodesWithAnimationManagers.length; i++)  
  {  
      var innerNode = nodesWithAnimationManagers[i];  
      var animationManager = animationManagersForNodes[i];

      // ... 创建控制器 ...

      // 第 165-168 行：调用 onDidLoadFromCCB  
      if (typeof(controller.onDidLoadFromCCB) == "function")  
      {  
          controller.onDidLoadFromCCB();  
      }  
  }

  执行顺序差异的根源：

  关键点：C++ 端在 readNodeGraphFromData  
  方法完成后，一次性返回了所有节点（包括父节点和所有子节点）的列表。然后 JavaScript  
  端按照这个列表的顺序逐个调用 onDidLoadFromCCB。

  这个列表的顺序取决于 C++ 端 _animationManagers map 的遍历顺序，而这个 map  
  在构建节点树时是按照广度优先的顺序添加的（先添加父节点，后添加子节点）。

  所以：

- Native：所有节点收集完成后，JavaScript 端按列表顺序调用，导致父节点的  
  onDidLoadFromCCB 先于子节点
- HTML5：每个节点加载完成后立即调用其  
  onDidLoadFromCCB，深度优先遍历导致子节点先于父节点
