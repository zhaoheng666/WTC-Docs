### **堆栈：**

[console.firebase.google.com/project/classicvegas-41d2f/crashlyti...](https://console.firebase.google.com/project/classicvegas-41d2f/crashlytics/app/ios:com.superant.classicvegasslots/issues/15862b989ffc76985f0bf5f42a05995c?hl=zh-cn&amp;time=last-seven-days&amp;types=crash&amp;sessionEventKey=7070d642d6dd4b2a84940bcfec3e8053_2070034213254120893)

已崩溃：com.apple.main-thread

EXC\_BAD\_ACCESS KERN\_INVALID\_ADDRESS 0x0000000000000000

         

 Crashed: com.apple.main-thread

0  OldVegasCasino                 0x13870e4 cocos2d::Node::onEnter() \+ 1346 (CCNode.cpp:1346)

1  OldVegasCasino                 0x1b04300 js\_cocos2dx\_Node\_onEnter(JSContext\*, unsigned int, JS::Value\*) \+ 17592

2  OldVegasCasino                 0x1ff3ed0 js::Invoke(JSContext\*, JS::CallArgs, js::MaybeConstruct) \+ 1631172

3  OldVegasCasino                 0x1fefd98 Interpret(JSContext\*, js::RunState&) \+ 1614476

4  OldVegasCasino                 0x1fe8ed0 js::RunScript(JSContext\*, js::RunState&) \+ 1586116

5  OldVegasCasino                 0x1ff3fdc js::Invoke(JSContext\*, JS::CallArgs, js::MaybeConstruct) \+ 1631440

6  OldVegasCasino                 0x1f425a8 js\_fun\_apply(JSContext\*, unsigned int, JS::Value\*) \+ 903836

7  OldVegasCasino                 0x1ff3ed0 js::Invoke(JSContext\*, JS::CallArgs, js::MaybeConstruct) \+ 1631172

8  OldVegasCasino                 0x1fefd98 Interpret(JSContext\*, js::RunState&) \+ 1614476

9  OldVegasCasino                 0x1fe8ed0 js::RunScript(JSContext\*, js::RunState&) \+ 1586116

10 OldVegasCasino                 0x1ff3fdc js::Invoke(JSContext\*, JS::CallArgs, js::MaybeConstruct) \+ 1631440

11 OldVegasCasino                 0x1f425a8 js\_fun\_apply(JSContext\*, unsigned int, JS::Value\*) \+ 903836

12 OldVegasCasino                 0x1ff3ed0 js::Invoke(JSContext\*, JS::CallArgs, js::MaybeConstruct) \+ 1631172

13 OldVegasCasino                 0x1fefd98 Interpret(JSContext\*, js::RunState&) \+ 1614476

14 OldVegasCasino                 0x1fe8ed0 js::RunScript(JSContext\*, js::RunState&) \+ 1586116

15 OldVegasCasino                 0x1ff3fdc js::Invoke(JSContext\*, JS::CallArgs, js::MaybeConstruct) \+ 1631440

16 OldVegasCasino                 0x1ff4320 js::Invoke(JSContext\*, JS::Value const&, JS::Value const&, unsigned int, JS::Value const\*, JS::MutableHandle\<JS::Value\>) \+ 1632276

17 OldVegasCasino                 0x1f1e330 JS\_CallFunctionValue(JSContext\*, JS::Handle\<JSObject\*\>, JS::Handle\<JS::Value\>, JS::HandleValueArray const&, JS::MutableHandle\<JS::Value\>) \+ 755748

18 OldVegasCasino                 0x1e4d06c ScriptingCore::executeFunctionWithOwner(JS::Value, char const\*, JS::HandleValueArray const&, JS::MutableHandle\<JS::Value\>) \+ 432

19 OldVegasCasino                 0x1e4e46c ScriptingCore::executeFunctionWithOwner(JS::Value, char const\*, unsigned int, JS::Value\*, JS::MutableHandle\<JS::Value\>) \+ 1928

20 OldVegasCasino                 0x1e4e63c ScriptingCore::handleNodeEvent(void\*) \+ 2392

21 OldVegasCasino                 0x1e50978 ScriptingCore::sendEvent(cocos2d::ScriptEvent\*) \+ 11412

22 OldVegasCasino                 0x16b5f84 cocos2d::ScriptEngineManager::sendNodeEventToJS(cocos2d::Node\*, int) \+ 191 (CCScriptSupport.cpp:191)

23 OldVegasCasino                 0x1387020 cocos2d::Node::onEnter() \+ 1330 (CCNode.cpp:1330)

24 OldVegasCasino                 0x1385bb8 cocos2d::Node::addChildHelper(cocos2d::Node\*, int, int, std::\_\_1::basic\_string\<char, std::\_\_1::char\_traits\<char\>, std::\_\_1::allocator\<char\>\> const&, bool) \+ 1005 (CCNode.cpp:1005)

25 OldVegasCasino                 0x1385d98 cocos2d::Node::addChild(cocos2d::Node\*, int, std::\_\_1::basic\_string\<char, std::\_\_1::char\_traits\<char\>, std::\_\_1::allocator\<char\>\> const&) \+ 968 (CCNode.cpp:968)

26 OldVegasCasino                 0x1385f7c cocos2d::Node::addChild(cocos2d::Node\*, int) \+ 1028 (CCNode.cpp:1028)

27 OldVegasCasino                 0x1b5c51c js\_cocos2dx\_Node\_addChild(JSContext\*, unsigned int, JS::Value\*) \+ 1812

28 OldVegasCasino                 0x1ff3ed0 js::Invoke(JSContext\*, JS::CallArgs, js::MaybeConstruct) \+ 1631172

29 OldVegasCasino                 0x1fefd98 Interpret(JSContext\*, js::RunState&) \+ 1614476

30 OldVegasCasino                 0x1fe8ed0 js::RunScript(JSContext\*, js::RunState&) \+ 1586116

31 OldVegasCasino                 0x1ff3fdc js::Invoke(JSContext\*, JS::CallArgs, js::MaybeConstruct) \+ 1631440

32 OldVegasCasino                 0x1ff4320 js::Invoke(JSContext\*, JS::Value const&, JS::Value const&, unsigned int, JS::Value const\*, JS::MutableHandle\<JS::Value\>) \+ 1632276

33 OldVegasCasino                 0x1f1e330 JS\_CallFunctionValue(JSContext\*, JS::Handle\<JSObject\*\>, JS::Handle\<JS::Value\>, JS::HandleValueArray const&, JS::MutableHandle\<JS::Value\>) \+ 755748

34 OldVegasCasino                 0x1e4d06c ScriptingCore::executeFunctionWithOwner(JS::Value, char const\*, JS::HandleValueArray const&, JS::MutableHandle\<JS::Value\>) \+ 432

35 OldVegasCasino                 0x1e4fd6c ScriptingCore::executeFunctionWithOwner(JS::Value, char const\*, unsigned int, JS::Value\*) \+ 8328

36 OldVegasCasino                 0x1afdb84 JSScheduleWrapper::update(float) \+ 8628

37 OldVegasCasino                 0x1b36e7c void cocos2d::Scheduler::scheduleUpdate\<JSScheduleWrapper\>(JSScheduleWrapper\*, int, bool)::'lambda'(float)::operator()(float) const \+ 36

38 OldVegasCasino                 0x1b36e4c decltype(std::declval\<JSScheduleWrapper\>()(std::declval\<float\>())) std::\_\_1::\_\_invoke\[abi:ue170006\]\<void cocos2d::Scheduler::scheduleUpdate\<JSScheduleWrapper\>(JSScheduleWrapper\*, int, bool)::'lambda'(float)&, float\>(JSScheduleWrapper&&, float&&) \+ 116

39 OldVegasCasino                 0x1b36df8 void std::\_\_1::\_\_invoke\_void\_return\_wrapper\<void, true\>::\_\_call\[abi:ue170006\]\<void cocos2d::Scheduler::scheduleUpdate\<JSScheduleWrapper\>(JSScheduleWrapper\*, int, bool)::'lambda'(float)&, float\>(void cocos2d::Scheduler::scheduleUpdate\<JSScheduleWrapper\>(JSScheduleWrapper\*, int, bool)::'lambda'(float)&, float&&) \+ 32

40 OldVegasCasino                 0x1b36dcc std::\_\_1::\_\_function::\_\_alloc\_func\<void cocos2d::Scheduler::scheduleUpdate\<JSScheduleWrapper\>(JSScheduleWrapper\*, int, bool)::'lambda'(float), std::\_\_1::allocator\<void cocos2d::Scheduler::scheduleUpdate\<JSScheduleWrapper\>(JSScheduleWrapper\*, int, bool)::'lambda'(float)\>, void (float)\>::operator()\[abi:ue170006\](float&&) \+ 2728

41 OldVegasCasino                 0x1b35c38 std::\_\_1::\_\_function::\_\_func\<void cocos2d::Scheduler::scheduleUpdate\<JSScheduleWrapper\>(JSScheduleWrapper\*, int, bool)::'lambda'(float), std::\_\_1::allocator\<void cocos2d::Scheduler::scheduleUpdate\<JSScheduleWrapper\>(JSScheduleWrapper\*, int, bool)::'lambda'(float)\>, void (float)\>::operator()(float&&) \+ 15972

42 OldVegasCasino                 0x13014e8 std::\_\_1::\_\_function::\_\_value\_func\<void (float)\>::operator()\[abi:ue170006\](float&&) const \+ 518 (function.h:518)

43 OldVegasCasino                 0x12f33f8 std::\_\_1::function\<void (float)\>::operator()(float) const \+ 1169 (function.h:1169)

44 OldVegasCasino                 0x12fe840 cocos2d::Scheduler::update(float) \+ 855 (CCScheduler.cpp:855)

45 OldVegasCasino                 0x1335cb8 cocos2d::Director::drawScene() \+ 307 (CCDirector.cpp:307)

46 OldVegasCasino                 0x133a5f8 cocos2d::Director::mainLoop() \+ 1606 (CCDirector.cpp:1606)

47 OldVegasCasino                 0x133a648 cocos2d::Director::mainLoop(float) \+ 1615 (CCDirector.cpp:1615)

48 OldVegasCasino                 0x17363b4 \-\[CCDirectorCaller doCaller:\] \+ 153 (CCDirectorCaller-ios.mm:153)

49 QuartzCore                     0xeb9cc CA::Display::DisplayLinkItem::dispatch\_(CA::SignPost::Interval\<(CA::SignPost::CAEventCode)835322056\>&) \+ 48

50 QuartzCore                     0xeb3a0 CA::Display::DisplayLink::dispatch\_items(unsigned long long, unsigned long long, unsigned long long) \+ 884

51 QuartzCore                     0xeaf38 CA::Display::DisplayLink::dispatch\_deferred\_display\_links(unsigned int) \+ 352

52 UIKitCore                      0x9c710 \_UIUpdateSequenceRun \+ 84

53 UIKitCore                      0x9f040 schedulerStepScheduledMainSection \+ 172

54 UIKitCore                      0x9cc5c runloopSourceCallback \+ 92

55 CoreFoundation                 0x73f4c \_\_CFRUNLOOP\_IS\_CALLING\_OUT\_TO\_A\_SOURCE0\_PERFORM\_FUNCTION\_\_ \+ 28

56 CoreFoundation                 0x73ee0 \_\_CFRunLoopDoSource0 \+ 176

57 CoreFoundation                 0x76b40 \_\_CFRunLoopDoSources0 \+ 244

58 CoreFoundation                 0x75d3c \_\_CFRunLoopRun \+ 840

59 CoreFoundation                 0xc8284 CFRunLoopRunSpecific \+ 588

60 GraphicsServices               0x14c0 GSEventRunModal \+ 164

61 UIKitCore                      0x3ee674 \-\[UIApplication \_run\] \+ 816

62 UIKitCore                      0x14e88 UIApplicationMain \+ 340

63 OldVegasCasino                 0x4cd8 main \+ 8 (main.m:8)

64 ???                            0x1c1aedde8 (缺少)

### **代码路径：**

CCNode.cpp \- 第 1028 行

void Node::addChild(Node \*child, int zOrder)

{

    CCASSERT( child \!= nullptr, "Argument must be non-nil");

    this-\>addChild(child, zOrder, child-\>\_name);//第 1028 行

}

CCNode.cpp \- 第 968 行

void Node::addChild(Node\* child, int localZOrder, const std::string \&name)

{

    CCASSERT(child \!= nullptr, "Argument must be non-nil");

    CCASSERT(child-\>\_parent \== nullptr, "child already added. It can't be added again");

    

    addChildHelper(child, localZOrder, INVALID\_TAG, name, false);//第 968 行

}

CCNode.cpp \- 第 1005 行

void Node::addChildHelper(Node\* child, int localZOrder, int tag, const std::string \&name, bool setTag)

{

    auto assertNotSelfChild

        ( \[ this, child \]() \-\> bool

          {

              for ( Node\* parent( getParent() ); parent \!= nullptr;

                    parent \= parent-\>getParent() )

                  if ( parent \== child )

                      return false;

              

              return true;

          } );

    (void)assertNotSelfChild;

    

    CCASSERT( assertNotSelfChild(),

              "A node cannot be the child of his own children" );

    

    if (\_children.empty())

    {

        this-\>childrenAlloc();

    }

    

    this-\>insertChild(child, localZOrder);

    

    if (setTag)

        child-\>setTag(tag);

    else

        child-\>setName(name);

    

    child-\>setParent(this);

    child-\>updateOrderOfArrival();

    if( \_running )

    {

        child-\>onEnter();// 第 1005 行

        // prevent onEnterTransitionDidFinish to be called twice when a node is added in onEnter

        if (\_isTransitionFinished)

        {

            child-\>onEnterTransitionDidFinish();

        }

    }

    

    if (\_cascadeColorEnabled)

    {

        updateCascadeColor();

    }

    

    if (\_cascadeOpacityEnabled)

    {

        updateCascadeOpacity();

    }

}

CCNode.cpp \- 第 1330 行

void Node::onEnter()

{

    if (\!\_running)

    {

        \++\_\_attachedNodeCount;

    }

\#if CC\_ENABLE\_SCRIPT\_BINDING

    if (\_scriptType \== kScriptTypeJavascript)

    {

        if (ScriptEngineManager::sendNodeEventToJS(this, kNodeOnEnter)) //第 1330 行

            return;

    }

\#endif

    

    if (\_onEnterCallback)

        \_onEnterCallback();

    if (\_componentContainer && \!\_componentContainer-\>isEmpty())

    {

        \_componentContainer-\>onEnter();

    }

    

    \_isTransitionFinished \= false;

    

    for( const auto \&child: \_children)

        child-\>onEnter();

    

    this-\>resume();

    

    \_running \= true;

    

\#if CC\_ENABLE\_SCRIPT\_BINDING

    if (\_scriptType \== kScriptTypeLua)

    {

        ScriptEngineManager::sendNodeEventToLua(this, kNodeOnEnter);

    }

\#endif

}

CCScriptSupport.cpp \- 第 191 行

bool ScriptEngineManager::sendNodeEventToJS(Node\* node, int action)

{

    auto scriptEngine \= getInstance()-\>getScriptEngine();

    

    if (scriptEngine-\>isCalledFromScript())

    {

        // Should only be invoked at root class Node

        scriptEngine-\>setCalledFromScript(false);

    }

    else

    {

        BasicScriptData data(node,(void\*)\&action);

        ScriptEvent scriptEvent(kNodeEvent,(void\*)\&data);

        if (scriptEngine-\>sendEvent(\&scriptEvent)) //第 191 行 

            return true;

    }

    

    return false;

}

ScriptingCore::handleNodeEvent \--\> JS\_CallFunctionValue

int ScriptingCore::handleNodeEvent(void\* data)

{

    if (NULL \== data)

        return 0;

    BasicScriptData\* basicScriptData \= static\_cast\<BasicScriptData\*\>(data);

    if (NULL \== basicScriptData-\>nativeObject || NULL \== basicScriptData-\>value)

        return 0;

    Node\* node \= static\_cast\<Node\*\>(basicScriptData-\>nativeObject);

    int action \= \*((int\*)(basicScriptData-\>value));

    js\_proxy\_t \* p \= jsb\_get\_native\_proxy(node);

    if (\!p) return 0;

    int ret \= 0;

    JS::RootedValue retval(\_cx);

    jsval dataVal \= INT\_TO\_JSVAL(1);

    JS::RootedObject jstarget(\_cx, p-\>obj);

    if (action \== kNodeOnEnter)

    {

        if (isFunctionOverridedInJS(jstarget, "onEnter", js\_cocos2dx\_Node\_onEnter))

        {

            ret \= executeFunctionWithOwner(OBJECT\_TO\_JSVAL(p-\>obj), "onEnter", 1, \&dataVal, \&retval);

        }

        resumeSchedulesAndActions(p);

    }

    else if (action \== kNodeOnExit)

    {

        if (isFunctionOverridedInJS(jstarget, "onExit", js\_cocos2dx\_Node\_onExit))

        {

            ret \= executeFunctionWithOwner(OBJECT\_TO\_JSVAL(p-\>obj), "onExit", 1, \&dataVal, \&retval);

        }

        pauseSchedulesAndActions(p);

    }

    else if (action \== kNodeOnEnterTransitionDidFinish)

    {

        if (isFunctionOverridedInJS(jstarget, "onEnterTransitionDidFinish", js\_cocos2dx\_Node\_onEnterTransitionDidFinish))

        {

            ret \= executeFunctionWithOwner(OBJECT\_TO\_JSVAL(p-\>obj), "onEnterTransitionDidFinish", 1, \&dataVal, \&retval);

        }

    }

    else if (action \== kNodeOnExitTransitionDidStart)

    {

        if (isFunctionOverridedInJS(jstarget, "onExitTransitionDidStart", js\_cocos2dx\_Node\_onExitTransitionDidStart))

        {

            ret \= executeFunctionWithOwner(OBJECT\_TO\_JSVAL(p-\>obj), "onExitTransitionDidStart", 1, \&dataVal, \&retval);

        }

    }

    else if (action \== kNodeOnCleanup) {

        cleanupSchedulesAndActions(p);

        if (isFunctionOverridedInJS(jstarget, "cleanup", js\_cocos2dx\_Node\_cleanup))

        {

            ret \= executeFunctionWithOwner(OBJECT\_TO\_JSVAL(p-\>obj), "cleanup", 1, \&dataVal, \&retval);

        }

    }

    return ret;

}

bool ScriptingCore::executeFunctionWithOwner(jsval owner, const char \*name, const JS::HandleValueArray& args, JS::MutableHandleValue retVal)

{

    bool bRet \= false;

    bool hasFunc;

    JSContext\* cx \= this-\>\_cx;

    JS::RootedValue funcVal(cx);

    JS::RootedValue ownerval(cx, owner);

    JS::RootedObject obj(cx, ownerval.toObjectOrNull());

    do

    {

        if (JS\_HasProperty(cx, obj, name, \&hasFunc) && hasFunc) {

            if (\!JS\_GetProperty(cx, obj, name, \&funcVal)) {

                break;

            }

            if (funcVal \== JSVAL\_VOID) {

                break;

            }

            bRet \= JS\_CallFunctionValue(cx, obj, funcVal, args, retVal);

        }

    }while(0);

    return bRet;

}

​js\_cocos2dx\_Node\_onEnter​

bool js\_cocos2dx\_Node\_onEnter(JSContext \*cx, uint32\_t argc, jsval \*vp)

{

    JS::CallArgs args \= JS::CallArgsFromVp(argc, vp);

    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());

    js\_proxy\_t \*proxy \= jsb\_get\_js\_proxy(obj);

    cocos2d::Node\* cobj \= (cocos2d::Node \*)(proxy ? proxy-\>ptr : nullptr);

    JSB\_PRECONDITION2( cobj, cx, false, "js\_cocos2dx\_Node\_onEnter : Invalid Native Object");//此处检查了 cobj 的有效性

    

    ScriptingCore::getInstance()-\>setCalledFromScript(true);

    cobj-\>onEnter();

    args.rval().setUndefined();

    return true;

}

CCNode.cpp \- 第 1346 行

void Node::onEnter()

{

    if (\!\_running)

    {

        \++\_\_attachedNodeCount;

    }

\#if CC\_ENABLE\_SCRIPT\_BINDING

    if (\_scriptType \== kScriptTypeJavascript)

    {

        if (ScriptEngineManager::sendNodeEventToJS(this, kNodeOnEnter))

            return;

    }

\#endif

    

    if (\_onEnterCallback)

        \_onEnterCallback();

    if (\_componentContainer && \!\_componentContainer-\>isEmpty())

    {

        \_componentContainer-\>onEnter();

    }

    

    \_isTransitionFinished \= false;

    

    for( const auto \&child: \_children)

        child-\>onEnter(); //最终触发 crash 的位置

    

    this-\>resume();

    

    \_running \= true;

    

\#if CC\_ENABLE\_SCRIPT\_BINDING

    if (\_scriptType \== kScriptTypeLua)

    {

        ScriptEngineManager::sendNodeEventToLua(this, kNodeOnEnter);

    }

\#endif

}

### **业务层代码：**

js 代码：

GrandLottoSpinJackpotController.prototype.onEnter \= function () {

    game.SmartCCBController.prototype.onEnter.call(this);

    var node \= new cc.Node();

    this.context.addChild(node);

    cc.warn("==============ChippinVegas\_TopRewardMainController.onEnter");

};

​GameDirector​:

update: function (dt) {

        if (this.\_nextScene) {

            if (this.runningScene) {

                this.runningScene.removeFromParent(true);

                this.runningScene \= null;

            }

            this.runningScene \= this.\_nextScene;

            cc.warn("========= update 旧场景节点已移除 \=========");

            this.addChild(this.runningScene, this.RUNNING\_SCENE\_ZORDER);

            this.\_nextScene.release();

            this.\_nextScene \= null;

            cc.warn("========= update 新场景节点已添加 \=========");

        }

    },

### **运行日志：**

#### **普通关卡运行日志：**

04-14 15:51:14.189 14829 14991 D cocos2d-x debug info: WARN :  \========= update 旧场景节点已移除 \=========

04-14 15:51:14.194 14829 14991 D cocos2d-x debug info: WARN :  \========= ChippinVegas\_TopRewardMainController.onEnter \=========

04-14 15:51:14.243 14829 14991 D cocos2d-x debug info: initUI

04-14 15:51:14.243 14829 14991 D cocos2d-x debug info: anmName:unlocked

04-14 15:51:14.244 14829 14991 D cocos2d-x debug info: acquirePiggyActivities0

04-14 15:51:14.244 14829 14991 D cocos2d-x debug info: displayMaxOutWindow:false||false

04-14 15:51:14.244 14829 14991 D cocos2d-x debug info: acquirePiggyActivities0

04-14 15:51:14.244 14829 14991 D cocos2d-x debug info: isUseCarousel:0

04-14 15:51:14.244 14829 14991 D cocos2d-x debug info: isUseCarousel:0

04-14 15:51:14.259 14829 14991 D cocos2d-x debug info: onExit

04-14 15:51:14.261 14829 14991 D cocos2d-x debug info: initUI

04-14 15:51:14.261 14829 14991 D cocos2d-x debug info: anmName:unlocked

04-14 15:51:14.261 14829 14991 D cocos2d-x debug info: acquirePiggyActivities0

04-14 15:51:14.262 14829 14991 D cocos2d-x debug info: displayMaxOutWindow:false||false

04-14 15:51:14.262 14829 14991 D cocos2d-x debug info: acquirePiggyActivities0

04-14 15:51:14.262 14829 14991 D cocos2d-x debug info: isUseCarousel:0

04-14 15:51:14.262 14829 14991 D cocos2d-x debug info: isUseCarousel:0

04-14 15:51:14.301 14829 14991 D cocos2d-x debug info: anmName:bonus

04-14 15:51:14.421 14829 14991 D cocos2d-x debug info: enter process: enterRoomCheckingProcess

04-14 15:51:14.422 14829 14991 D cocos2d-x debug info: enter process: WaitForSpinProcess

04-14 15:51:14.435 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.435 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.441 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.470 14829 14991 D cocos2d-x debug info: anmName:invisible

04-14 15:51:14.479 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.484 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.484 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.485 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.485 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.506 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.506 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.508 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.508 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.515 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.516 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.539 14829 14991 D cocos2d-x debug info: anmName:normal

04-14 15:51:14.539 14829 14991 D cocos2d-x debug info: anmName:appear

04-14 15:51:14.540 14829 14991 D cocos2d-x debug info: anmName:normal

04-14 15:51:14.544 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.544 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.545 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.545 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.548 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.548 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.558 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.558 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.574 14829 14991 D cocos2d-x debug info: anmName:normal

04-14 15:51:14.630 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.630 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.663 14829 14991 D cocos2d-x debug info: \_playProgressBarAnimation==== 0

04-14 15:51:14.666 14829 14991 D cocos2d-x debug info: anmName:show

04-14 15:51:14.685 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.685 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.707 14829 14991 D cocos2d-x debug info: \_playProgressBarAnimation==== 0

04-14 15:51:14.775 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.775 14829 14991 D cocos2d-x debug info: CCBERROR: parsePropTypeSpriteFrame  

04-14 15:51:14.808 14829 14991 D cocos2d-x debug info: \_playProgressBarAnimation==== 0

04-14 15:51:14.808 14829 14991 D cocos2d-x debug info: anmName:normal

04-14 15:51:14.809 14829 14991 D cocos2d-x debug info: anmName:collect

04-14 15:51:14.811 14829 14991 D cocos2d-x debug info: \_playProgressBarAnimation==== 0

04-14 15:51:14.812 14829 14991 D cocos2d-x debug info: anmName:normal

04-14 15:51:14.812 14829 14991 D cocos2d-x debug info: anmName:join

04-14 15:51:14.813 14829 14991 D cocos2d-x debug info: anmName:play

04-14 15:51:14.817 14829 14991 D cocos2d-x debug info: deallocing Texture2D: 0xb40000776fcc8e60 \- id=34 /data/user/0/com.zentertain.classicvegasslots/files/casino/login/login\_bg.jpg

04-14 15:51:14.817 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:2

04-14 15:51:14.818 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.818 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.818 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.818 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.818 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.818 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.819 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.819 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.819 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.819 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.819 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.819 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.820 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.820 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.820 14829 14991 D cocos2d-x debug info: SlotLog\[Grand Lotto Spin \]: anmName:base

04-14 15:51:14.829 14829 14991 D cocos2d-x debug info: WARN :  \========= update 新场景节点已添加 \=========

#### **HR 关卡运行日志：**

04-14 15:56:01.567 14829 14991 D cocos2d-x debug info: WARN :  \========= runWithScene \=========

04-14 15:56:01.569 14829 14991 D cocos2d-x debug info: logMan send:{"content":{"projName":"ClassicVegas","actions":\[{"type":"uiClick","value":{"arg1":204255,"arg2":"NewSlotBannerChoose","arg3":"","eventId":33391,"openTimeMs":3066,"newLevel":46,"UDID":"1961e05f5a74Bom41ENdO","native\_os\_version":"12","device\_model":"NCO-AL00","networkType":1,"version\_name":"2.3.16","native\_os":"Android","platform":3,"PT":"Google","ADID":"ae27a8fbf04aa491d107fc5877b1e4fb","RC":"hPXeSntvII","cliTs":1744617361569,"clientVer":100102,"commonVer":"93.6.918154","installTs":1744260429219,"connector":7811,"loginUrl":"slots-team-test-server-v0.me2zengame.com","PID":6238,"uid":6238,"IAP":9999,"iap":9999,"g":"c","gV":8000,"chips":2992995271,"level":46,"abtests":\[\[8000,"c"\],\[8001,"e"\],\[8002,"a"\],\[8003,"a"\],\[8004,"a"\],\[2701,"b"\],\[3500,"a"\],\[3300,"a"\],\[3601,"a"\],\[3100,"b"\],\[3800,"a"\],\[3101,"a"\],\[9001,"a"\]\],"FBID":"","createTs":1744164899801,"getData":true,"clientIP":"::ffff:103.50.252.130","purchaseCount":1,"purchaseCountMoreThen10":false,"IAPMoreThen100D":true,"location":1,"subjectId":204255,"s

04-14 15:56:01.738 14829 14991 D cocos2d-x debug info: WARN :  \========= update 旧场景节点已移除 \=========

04-14 15:56:01.742 14829 14991 D cocos2d-x debug info: WARN :  \========= ChippinVegas\_TopRewardMainController.onEnter \=========

04-14 15:56:03.575 15741 15741 F DEBUG   :       \#00 pc 0000000001857744  /data/app/\~\~X2TthADBYyKnJgfkZss8JA==/com.zentertain.classicvegasslots-nZ7sDzw58PCovAxtKiP0\_A==/lib/arm64/libgame.so (cocos2d::Node::onEnter()+340) (BuildId: a9eeb6e82cbbeb65d455196cfe06617d7e9f5ef0)

04-14 15:56:03.575 15741 15741 F DEBUG   :       \#01 pc 000000000105de74  /data/app/\~\~X2TthADBYyKnJgfkZss8JA==/com.zentertain.classicvegasslots-nZ7sDzw58PCovAxtKiP0\_A==/lib/arm64/libgame.so (js\_cocos2dx\_Node\_onEnter(JSContext\*, unsigned int, JS::Value\*)+376) (BuildId: a9eeb6e82cbbeb65d455196cfe06617d7e9f5ef0)

### **分析：**

* **关键特征：**

  1. 日志“ChippinVegas\_TopRewardMainController.onEnter” 在 onEnter 方法的最后打印，此时 onEnter 中的 addChild 已完成；

  2. spidermonkey 接口流转正常结束，js\_cocos2dx\_Node\_onEnter 中 cobj 的有效性检查通过；

  3. 堆栈中未出现嵌套的 addChild 过程，且测试时使用的 new cc.Node(), 可以排除是当前子节点异常；

  4. 如果去掉 onEnter 中的 addchild 普通关卡和 HR 关卡均无异常，可以排除是其他节点导致的；

  5. 关卡场景对象类型为 cc.Node 的派生类，本质上根节点为 cc.Node；

     1. 仅当父节点是关卡根节点（cc.Node），且在关卡根节点的 onEnter 中直接对场景根节点做 addchild 操作时会触发 crash；  
     2. 父节点是关卡根节点（cc.Node）时，在关卡根节点的 onEnter 中操作其他子节点 addChild 无异常；  
     3. 父节点非关卡根节点（cc.Node）时，在父节点的 onEnter 中 addChild 无异常；  
* **判定：**

   最终堆栈应定位为：关卡根节点的 js onEnter 方法执行完后再次调用根节点 cobj 的 onEnter 方法时，遍历关卡根节点时 child 出现了空指针；；

* **推测：**

   onEnter 方法中 addChild 出现了子节点的 jsobj 添加成功，但 cobj 为 nullptr 的情况；

   未查到具体原因；

### **解决方案：**

避免在关卡场景的 onEnter 方法中直接对关卡根节点做 addChild 操作：

1. 可避开 onEnter ，在 ctor 或其他逻辑位置 addChild；  
2. 如必须在 onEnter 中 addChild，需避免直接操作根节点；

