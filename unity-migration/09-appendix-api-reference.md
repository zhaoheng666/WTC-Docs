# 09 - 附录：完整 API 映射速查表

[返回目录](00-index.md) | [上一章](08-roadmap.md)

> **用途**：实施时的快速查表工具。扁平化列出所有 JS API → C# 映射，无叙述。  
> **更新规范**：每实现一个方法，必须将状态从 `待实现` 更新为 `已实现`。参见 [07-execution-standards.md](07-execution-standards.md) 第 7.1 节。

---

## A. CCCompat.cs

| JS | C# | 次数 | 状态 |
|----|----|------|------|
| `cc.p(x,y)` | `CC.P(float,float)→Vector2` | 4815 | 待实现 |
| `cc.size(w,h)` | `CC.Size(float,float)→Vector2` | 970 | 待实现 |
| `cc.color(r,g,b,a)` | `CC.Color(int,int,int,int)→Color` | 643 | 待实现 |
| `cc.rect(x,y,w,h)` | `CC.Rect(float,float,float,float)→Rect` | 73 | 待实现 |
| `cc.pAdd(p1,p2)` | `CC.PAdd(Vector2,Vector2)→Vector2` | 136 | 待实现 |
| `cc.pSub(p1,p2)` | `CC.PSub(Vector2,Vector2)→Vector2` | 35 | 待实现 |
| `cc.pMult(p,f)` | `CC.PMult(Vector2,float)→Vector2` | 22 | 待实现 |
| `cc.pNormalize(p)` | `CC.PNormalize(Vector2)→Vector2` | 27 | 待实现 |
| `cc.pDistance(p1,p2)` | `CC.PDistance(Vector2,Vector2)→float` | 16 | 待实现 |
| `cc.pLength(p)` | `CC.PLength(Vector2)→float` | 14 | 待实现 |
| `cc.pToAngle(p)` | `CC.PToAngle(Vector2)→float` | 3 | 待实现 |
| `cc.pMidpoint(p1,p2)` | `CC.PMidpoint(Vector2,Vector2)→Vector2` | 7 | 待实现 |
| `cc.pointEqualToPoint(p1,p2)` | `CC.PointEqual(Vector2,Vector2)→bool` | 7 | 待实现 |
| `cc.pLerp(p1,p2,t)` | `CC.PLerp(Vector2,Vector2,float)→Vector2` | 2 | 待实现 |
| `cc.pDot(p1,p2)` | `CC.PDot(Vector2,Vector2)→float` | 1 | 待实现 |
| `cc.rectContainsPoint(r,p)` | `CC.RectContainsPoint(Rect,Vector2)→bool` | 75 | 待实现 |
| `cc.rectIntersectsRect(r1,r2)` | `CC.RectIntersects(Rect,Rect)→bool` | 11 | 待实现 |
| `cc.sys.isObjectValid(obj)` | `CC.IsValid(object)→bool` | 4108 | 待实现 |
| `cc.isFunction(obj)` | `CC.IsFunction(object)→bool` | 1103 | 待实现 |
| `cc.isUndefined(obj)` | `CC.IsUndefined(object)→bool` | 998 | 待实现 |
| `cc.isNumber(obj)` | `CC.IsNumber(object)→bool` | 522 | 待实现 |
| `cc.isArray(obj)` | `CC.IsArray(object)→bool` | 447 | 待实现 |
| `cc.isObject(obj)` | `CC.IsObject(object)→bool` | 94 | 待实现 |
| `cc.isString(obj)` | `CC.IsString(object)→bool` | 87 | 待实现 |
| `cc.sys.isNative` | `CC.IsNative→bool` | 715 | 待实现 |
| `cc.sys.os` | `CC.SysOS→string` | 131 | 待实现 |
| `cc.sys.openURL(url)` | `CC.OpenURL(string)` | 36 | 待实现 |
| `cc.clampf(v,min,max)` | `CC.Clampf(float,float,float)→float` | 8 | 待实现 |
| `cc.random0To1()` | `CC.Random01()→float` | 7 | 待实现 |
| `cc.lerp(a,b,t)` | `CC.Lerp(float,float,float)→float` | 4 | 待实现 |

## B. CCAction.cs

| JS | C# | 次数 | 状态 |
|----|----|------|------|
| `node.runAction(action)` | `CCAction.RunAction(Transform,ITweenAction)` | 3124 | 待实现 |
| `cc.sequence(...)` | `CCAction.Sequence(params ITweenAction[])` | 2183 | 待实现 |
| `cc.callFunc(func)` | `CCAction.CallFunc(Action)` | 2781 | 待实现 |
| `cc.delayTime(d)` | `CCAction.DelayTime(float)` | 2373 | 待实现 |
| `cc.moveTo(d,pos)` | `CCAction.MoveTo(float,Vector2)` | 643 | 待实现 |
| `cc.scaleTo(d,sx,sy)` | `CCAction.ScaleTo(float,float,float?)` | 353 | 待实现 |
| `cc.bezierTo(d,pts)` | `CCAction.BezierTo(float,Vector2[])` | 233 | 待实现 |
| `cc.progressTo(d,pct)` | `CCAction.ProgressTo(float,float)` | 223 | 待实现 |
| `cc.moveBy(d,delta)` | `CCAction.MoveBy(float,Vector2)` | 164 | 待实现 |
| `cc.fadeIn(d)` | `CCAction.FadeIn(float)` | 108 | 待实现 |
| `cc.spawn(...)` | `CCAction.Spawn(params ITweenAction[])` | 94 | 待实现 |
| `cc.fadeTo(d,opacity)` | `CCAction.FadeTo(float,float)` | 79 | 待实现 |
| `cc.fadeOut(d)` | `CCAction.FadeOut(float)` | 71 | 待实现 |
| `cc.hide()` | `CCAction.Hide()` | 68 | 待实现 |
| `cc.repeatForever(a)` | `CCAction.RepeatForever(ITweenAction)` | 62 | 待实现 |
| `cc.show()` | `CCAction.Show()` | 42 | 待实现 |
| `cc.removeSelf()` | `CCAction.RemoveSelf()` | 33 | 待实现 |
| `cc.rotateTo(d,angle)` | `CCAction.RotateTo(float,float)` | 32 | 待实现 |
| `cc.rotateBy(d,angle)` | `CCAction.RotateBy(float,float)` | 28 | 待实现 |
| `cc.tintTo(d,r,g,b)` | `CCAction.TintTo(float,Color)` | 27 | 待实现 |
| `cc.jumpTo(d,pos,h,n)` | `CCAction.JumpTo(float,Vector2,float,int)` | 20 | 待实现 |
| `cc.scaleBy(d,sx,sy)` | `CCAction.ScaleBy(float,float,float?)` | 8 | 待实现 |
| `cc.place(x,y)` | `CCAction.Place(Vector2)` | 5 | 待实现 |
| `cc.repeat(a,n)` | `CCAction.Repeat(ITweenAction,int)` | 2 | 待实现 |
| `cc.speed(a,s)` | `CCAction.Speed(ITweenAction,float)` | 1 | 待实现 |

### Easing

| JS | DOTween Ease | 次数 | 状态 |
|----|-------------|------|------|
| `cc.easeIn(rate)` | `Ease.InQuad/InCubic` | 119 | 待实现 |
| `cc.easeBackOut()` | `Ease.OutBack` | 50 | 待实现 |
| `cc.easeInOut(rate)` | `Ease.InOutQuad` | 30 | 待实现 |
| `cc.easeSineInOut()` | `Ease.InOutSine` | 21 | 待实现 |
| `cc.easeOut(rate)` | `Ease.OutQuad` | 21 | 待实现 |
| `cc.easeBounceOut()` | `Ease.OutBounce` | 20 | 待实现 |
| `cc.easeSineOut()` | `Ease.OutSine` | 13 | 待实现 |
| `cc.easeSineIn()` | `Ease.InSine` | 11 | 待实现 |
| `cc.easeBezierAction(a,b,c,d)` | `AnimationCurve` | 8 | 待实现 |
| `cc.easeExponentialOut()` | `Ease.OutExpo` | 6 | 待实现 |
| `cc.easeCircleActionOut()` | `Ease.OutCirc` | 5 | 待实现 |
| `cc.easeExponentialInOut()` | `Ease.InOutExpo` | 5 | 待实现 |
| `cc.easeElasticOut()` | `Ease.OutElastic` | 4 | 待实现 |
| `cc.easeBackIn()` | `Ease.InBack` | 4 | 待实现 |
| `cc.easeBackInOut()` | `Ease.InOutBack` | 3 | 待实现 |

## C. NodeHelper.cs

| JS | C# | 次数 | 状态 |
|----|----|------|------|
| `setNodeVisible(n,v)` | `NodeHelper.SetVisible(GameObject,bool)` | 10105 | 待实现 |
| `setNodeText(n,t,s)` | `NodeHelper.SetText(Component,string,bool)` | 2692 | 待实现 |
| `setNodeEnabled(n,e)` | `NodeHelper.SetEnabled(Component,bool)` | 1929 | 待实现 |
| `setSpriteFrameName(s,n)` | `NodeHelper.SetSpriteFrame(Image,string)` | 726 | 待实现 |
| `setNodePosition(n,p)` | `NodeHelper.SetPosition(Transform,Vector2)` | 315 | 待实现 |
| `removeCCBFromParent(n,c)` | `NodeHelper.RemoveFromParent(GameObject,bool)` | 301 | 待实现 |
| `setNodeLocalZOrder(n,z)` | `NodeHelper.SetZOrder(Transform,int)` | 283 | 待实现 |
| `removeNodeFromParent(n,c)` | `NodeHelper.RemoveNode(GameObject,bool)` | 187 | 待实现 |
| `setNodeColor(n,c)` | `NodeHelper.SetColor(Component,Color)` | 136 | 待实现 |
| `setCascadeColorEnabledRecursive(n,b)` | `NodeHelper.SetCascadeColor(Transform,bool)` | 110 | 待实现 |
| `setNodeOpacity(n,o)` | `NodeHelper.SetOpacity(Component,float)` | 103 | 待实现 |
| `setNodeRotationSafe(n,r)` | `NodeHelper.SetRotation(Transform,float)` | 88 | 待实现 |
| `makeTouchable(n,s,p)` | `NodeHelper.MakeTouchable(GameObject,bool,int)` | 79 | 待实现 |
| `autoAlignNodes(ns,g,i,c)` | `NodeHelper.AutoAlign(Transform[],float,float,float)` | 65 | 待实现 |
| `setCascadeOpacityEnabledRecursive(n,b)` | `NodeHelper.SetCascadeOpacity(Transform,bool)` | 57 | 待实现 |
| `setNodeScale(n,sx,sy)` | `NodeHelper.SetScale(Transform,float,float?)` | 55 | 待实现 |
| `isNodeVisible(n)` | `NodeHelper.IsVisible(GameObject)→bool` | 22 | 待实现 |
| `setNodeOpacityRecursive(n,o)` | `NodeHelper.SetOpacityRecursive(Transform,float)` | 16 | 待实现 |
| `setNodeTextAutoChangeLine(n,t,w,a)` | `NodeHelper.SetTextAutoWrap(TMP_Text,string,float,...)` | 8 | 待实现 |
| `disableMultiTouch(r)` | `NodeHelper.DisableMultiTouch(GameObject)` | 2 | 待实现 |
| `autoAlignTextNodes(ns,o,i,c)` | `NodeHelper.AutoAlignText(Transform[],float,float,float)` | 2 | 待实现 |
| `verticalAlignNodes(ns,i,c)` | `NodeHelper.VerticalAlign(Transform[],float,float)` | 1 | 待实现 |
| `stopNodeAction(n)` | `NodeHelper.StopAction(Transform)` | 1 | 待实现 |

## D. GameUtil.cs（高频方法）

| JS | C# | 次数 | 状态 |
|----|----|------|------|
| `playAnim(n,name,t,cb)` | `GameUtil.PlayAnim(GameObject,string,Action)` | 7369 | 待实现 |
| `playCCBAnimation(n,name,t,cb)` | `GameUtil.PlayCCBAnim(GameObject,string,Action)` | 2647 | 待实现 |
| `loadNodeFromCCB(ccb,p,c)` | `GameUtil.LoadPrefab(string,Transform,...)→GameObject` | 2186 | 待实现 |
| `seekNodeByTag(root,tag)` | `GameUtil.SeekByTag(Transform,int)→Transform` | 1841 | 待实现 |
| `sprintf(fmt,...)` | `GameUtil.Sprintf(string,params object[])→string` | 1281 | 待实现 |
| `floorPrecision(n)` | `GameUtil.FloorPrecision(double)→long` | 871 | 待实现 |
| `getCommaNum(n)` | `GameUtil.GetCommaNum(long)→string` | 818 | 待实现 |
| `formatAbbrNumAutoComma(n)` | `GameUtil.FormatAbbrAuto(double)→string` | 675 | 待实现 |
| `animManRunSeqName(n,seq)` | `GameUtil.RunAnimSeq(GameObject,string)` | 459 | 待实现 |
| `deepCopyObject(t,s)` | `GameUtil.DeepCopy<T>(T)→T` | 447 | 待实现 |
| `getFormatTime(ms,h,d)` | `GameUtil.FormatTime(long,bool,bool)→string` | 422 | 待实现 |
| `delayCall(s,cb,n,tag)` | `GameUtil.DelayCall(float,Action,...)` | 418 | 待实现 |
| `isFileExist(name)` | `GameUtil.FileExists(string)→bool` | 261 | 待实现 |
| `recordLabelScale(l)` | `GameUtil.RecordLabelScale(TMP_Text)` | 242 | 待实现 |
| `randomNextInt(n)` | `GameUtil.RandomInt(int)→int` | 227 | 待实现 |
| `shuffle2(arr)` | `GameUtil.Shuffle<T>(List<T>)` | 180 | 待实现 |
| `formatAbbrNumOneComma(n)` | `GameUtil.FormatAbbrOne(double)→string` | 136 | 待实现 |
| `ceilPrecision(n)` | `GameUtil.CeilPrecision(double)→long` | 131 | 待实现 |
| `delayCallWithTarget(s,t,cb)` | `GameUtil.DelayCallTarget(float,object,Action)` | 125 | 待实现 |
| `isCCBHasAnimation(n,name)` | `GameUtil.HasAnimation(GameObject,string)→bool` | 124 | 待实现 |
| `deepClone(obj)` | `GameUtil.DeepClone<T>(T)→T` | 112 | 待实现 |

## E. SlotUtil.cs（高频方法）

| JS | C# | 次数 | 状态 |
|----|----|------|------|
| `playAnim(n,name,...cbs)` | `SlotUtil.PlayAnim(GameObject,string,params Action[])` | 3927 | 待实现 |
| `playEffect(name,loop)` | `SlotUtil.PlayEffect(string,bool)` | 1566 | 待实现 |
| `delayCall(s,f,name)` | `SlotUtil.DelayCall(float,Action,string)` | 1312 | 待实现 |
| `playAnimEasy(n,name,...cbs)` | `SlotUtil.PlayAnimEasy(GameObject,string,params Action[])` | 731 | 待实现 |
| `createFlow(h,name)` | `SlotUtil.CreateFlow(Action<Action>,string)→SlotFlow` | 626 | 待实现 |
| `setNodeText(n,t)` | `SlotUtil.SetText(Component,string)` | 346 | 待实现 |
| `getAnimationKeyByPos(c,r,p)` | `SlotUtil.AnimKeyByPos(int,int,string)→string` | 344 | 待实现 |
| `setNodeTextWithForAbbrChipsAppropriate(n,c)` | `SlotUtil.SetChipsTextAuto(Component,double)` | 226 | 待实现 |
| `stopEffect(name)` | `SlotUtil.StopEffect(string)` | 146 | 待实现 |
| `getWorldPosition(n)` | `SlotUtil.GetWorldPos(Transform)→Vector3` | 125 | 待实现 |
| `cancelDelayCallByName(name)` | `SlotUtil.CancelDelay(string)` | 91 | 待实现 |
| `setNodeTextForCommaChips(n,c,m)` | `SlotUtil.SetCommaChips(Component,double,bool)` | 91 | 待实现 |
| `flyCCBItemWithRecycle(...)` | `SlotUtil.FlyCCBRecycle(...)` | 64 | 待实现 |
| `setNodeTextWithForAbbrChips(n,c,t)` | `SlotUtil.SetChipsText(Component,double,int)` | 63 | 待实现 |
| `getWinLevel(w)` | `SlotUtil.GetWinLevel(double)→int` | 59 | 待实现 |
| `flyItemByWorldPos(...)` | `SlotUtil.FlyByWorldPos(...)` | 59 | 待实现 |
| `stopMusic()` | `SlotUtil.StopMusic()` | 44 | 待实现 |
| `getNodePosition(n,wp)` | `SlotUtil.WorldToLocal(Transform,Vector3)→Vector3` | 39 | 待实现 |
| `setWinLevel(w,p)` | `SlotUtil.SetWinLevel(double,SpinPanel)` | 34 | 待实现 |

## F. ActivityUtil.cs（Slot 相关高频方法）

| JS | C# | 次数 | 状态 |
|----|----|------|------|
| `setNodeTextAutoScale(n,t,s)` | `AUtil.SetTextAutoScale(Component,string,bool)` | 1248 | 待实现 |
| `delayCallWithNode(s,cb,r,tag)` | `AUtil.DelayCallNode(float,Action,GameObject,int)` | 650 | 待实现 |
| `getCurrentSequenceName(n)` | `AUtil.GetAnimSequenceName(GameObject)→string` | 372 | 待实现 |
| `createFlowNode(root)` | `AUtil.CreateFlowNode(GameObject)→FlowNode` | 366 | 待实现 |
| `convertToNodeSpace(n,r,o)` | `AUtil.ConvertToNodeSpace(Transform,Transform,Vector2)→Vector2` | 337 | 待实现 |
| `showOneChildByTag(r,tag)` | `AUtil.ShowOneChild(Transform,int)` | 328 | 待实现 |
| `safelyButtonClicked(s,cb)` | `AUtil.SafeButtonClick(Button,Action)` | 229 | 待实现 |
| `showPanel(p,toggle)` | `AUtil.ShowPanel(GameObject,bool)` | 135 | 待实现 |
| `arraySearch(arr,pred,def)` | `AUtil.ArraySearch<T>(T[],Func<T,bool>,T)→T` | 138 | 待实现 |
| `playAnimOnce(n,name,t,cb)` | `AUtil.PlayAnimOnce(GameObject,string,Action)` | 88 | 待实现 |
| `cancelDelayCall(tag,root)` | `AUtil.CancelDelay(int,GameObject)` | 84 | 待实现 |
| `hidePanel(p,noAnim)` | `AUtil.HidePanel(GameObject,bool)` | 81 | 待实现 |
| `safelyButtonClickedV2(s,cb,d)` | `AUtil.SafeButtonClickV2(Button,Action,float)` | 74 | 待实现 |
| `centralizeCoinLabel(c,l,t,n)` | `AUtil.CenterCoinLabel(Transform,TMP_Text,string,bool)` | 71 | 待实现 |
| `arraySum(arr,it)` | `AUtil.ArraySum<T>(T[],Func<T,double>)→double` | 56 | 待实现 |
| `arrayFilter(arr,f)` | `AUtil.ArrayFilter<T>(T[],Func<T,bool>)→T[]` | 39 | 待实现 |
| `hideAllChildren(r)` | `AUtil.HideAllChildren(Transform)` | 28 | 待实现 |

## G. 不需要映射的 API

| JS | 次数 | C# 直接替代 |
|----|------|------------|
| `game.util.inherits(Sub,Super)` | 4170 | `class Sub : Super` |
| `game.util.registerController(n,c)` | 2561 | NameBinder 替代 |
| `game.util.unRegisterController(n)` | 2547 | NameBinder 替代 |
| `cc.each(arr,func)` | 845 | `foreach` |
| `cc.log(...)` | 2910 | `Debug.Log(...)` |
| `cc.error(...)` | 617 | `Debug.LogError(...)` |
| `cc.warn(...)` | 608 | `Debug.LogWarning(...)` |
| `cc.assert(...)` | 14 | `Debug.Assert(...)` |
| `cc.extend(t,s)` | 26 | 对象初始化器 |
| `cc.Class.extend({...})` | 242 | `class` 继承 |

---

> **统计汇总**  
> - 总映射 API 条目：~300+（含不需要映射的 ~30 项）  
> - 已实现：0  
> - 待实现：~270+  
> - 不需要：~30
