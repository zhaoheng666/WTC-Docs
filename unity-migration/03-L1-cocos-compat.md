# 03 - L1 Cocos 兼容层详细设计

[返回目录](00-index.md) | [上一章](02-architecture.md)

---

## 3.1 设计原则

1. **接口一致性**：C# 方法签名与 JS 保持语义一致，仅命名风格从 camelCase 转为 PascalCase
2. **无业务逻辑**：L1 只做 API 翻译，不包含任何 Slot 业务语义
3. **静态无状态**：所有方法为 `static` 方法，不持有实例状态
4. **Unity 原生**：内部实现使用 Unity 原生 API（DOTween、Transform、Animator 等）
5. **容错一致**：保持与 JS 版本相同的空值保护行为（JS 版本大量使用 `cc.sys.isObjectValid` 检查）

---

## 3.2 文件规划

所有 L1 文件位于：`Assets/Project/AddressableRes/Scripts/framework/slot/compat2022/Core/` 下各子目录

| 文件 | 目录 | 命名空间 | 映射源 | 实现优先级 |
|------|------|----------|--------|-----------|
| `CCCompat.cs` | `Core/Bridge/` | `WTC.Slot.Compat2022.Core.Bridge` | cc.p/cc.color/cc.size/cc.sys/cc.is* | P0 — 零依赖基础 |
| `CCAction.cs` | `Core/Bridge/` | `WTC.Slot.Compat2022.Core.Bridge` | cc.sequence/moveTo/callFunc... → DOTween | P0 — 高频核心 |
| `NodeHelper.cs` | `Core/Utils/` | `WTC.Slot.Compat2022.Core.Utils` | game.nodeHelper.* | P1 — 最高调用量 |
| `GameUtil.cs` | `Core/Utils/` | `WTC.Slot.Compat2022.Core.Utils` | game.util.* | P1 — 核心工具 |
| `SlotUtil.cs` | `Core/Utils/` | `WTC.Slot.Compat2022.Core.Utils` | game.slotUtil.* | P1 — Slot 专用 |
| `ActivityUtil.cs` | `Core/Utils/` | `WTC.Slot.Compat2022.Core.Utils` | game.aUtil.* | P2 |
| `NameBinder.cs` | `Core/Contrller/` | `WTC.Slot.Compat2022.Core.Controller` | .controller._ 自动绑定 | P1 — 高频绑定 |
| `UIHelper.cs` | `Core/Utils/` | `WTC.Slot.Compat2022.Core.Utils` | game.uIHelper.* | P2 |
| `EventDispatcher.cs` | `Core/`（根） | `WTC.Slot.Compat2022.Core` | game.eventDispatcher.* | P2 |
| `AudioBridge.cs` | `Core/Bridge/` | `WTC.Slot.Compat2022.Core.Bridge` | game.audioPlayer.* | P2 |
| `DialogBridge.cs` | `Core/Bridge/` | `WTC.Slot.Compat2022.Core.Bridge` | game.dialogManager.* | P3 |
| `SlotPopupUtil.cs` | `Core/Utils/` | `WTC.Slot.Compat2022.Core.Utils` | game.slotPopupUtil.* | P3 |
| `WinEffectHelper.cs` | `Core/Utils/` | `WTC.Slot.Compat2022.Core.Utils` | game.winEffectHelper.* | P3 |
| `HighRollerSlotUtil.cs` | `Core/Utils/` | `WTC.Slot.Compat2022.Core.Utils` | game.highRollerSlotUtil.* | P3 |

---

## 3.3 完整 API 映射表

### 映射表格式说明

每个 API 的映射条目包含：

| 列 | 说明 |
|---|---|
| **JS API** | JavaScript 中的完整方法调用 |
| **C# 方法** | 对应的 C# 静态方法签名 |
| **Unity 实现策略** | 内部使用的 Unity API 或实现思路 |
| **调用次数** | 源代码库中的总调用次数 |
| **状态** | `待实现` / `已实现` / `不需要`（C# 天然解决） |

> **执行规范**：每实现一个方法，必须将状态从 `待实现` 更新为 `已实现`，并补充实际的 C# 方法签名。
> 参见 [07-execution-standards.md](07-execution-standards.md) 第 7.1 节。

---

### 3.3.1 CCCompat.cs — 类型、几何与系统兼容

**JS 源**：Cocos2d 引擎内置 `cc.*`  
**C# 文件**：`CCCompat.cs`  
**调用总量**：~25,000+

#### 几何构造

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `cc.p(x, y)` | `CC.P(float x, float y)` → `Vector2` | `new Vector2(x, y)` | 4,815 | 待实现 |
| `cc.size(w, h)` | `CC.Size(float w, float h)` → `Vector2` | `new Vector2(w, h)` | 970 | 待实现 |
| `cc.color(r, g, b, a)` | `CC.Color(int r, int g, int b, int a)` → `Color` | `new Color(r/255f, g/255f, b/255f, a/255f)` | 643 | 待实现 |
| `cc.rect(x, y, w, h)` | `CC.Rect(float x, float y, float w, float h)` → `Rect` | `new Rect(x, y, w, h)` | 73 | 待实现 |

#### 点运算

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `cc.pAdd(p1, p2)` | `CC.PAdd(Vector2, Vector2)` → `Vector2` | `p1 + p2` | 136 | 待实现 |
| `cc.pSub(p1, p2)` | `CC.PSub(Vector2, Vector2)` → `Vector2` | `p1 - p2` | 35 | 待实现 |
| `cc.pMult(p, f)` | `CC.PMult(Vector2, float)` → `Vector2` | `p * f` | 22 | 待实现 |
| `cc.pNormalize(p)` | `CC.PNormalize(Vector2)` → `Vector2` | `p.normalized` | 27 | 待实现 |
| `cc.pDistance(p1, p2)` | `CC.PDistance(Vector2, Vector2)` → `float` | `Vector2.Distance(p1, p2)` | 16 | 待实现 |
| `cc.pLength(p)` | `CC.PLength(Vector2)` → `float` | `p.magnitude` | 14 | 待实现 |
| `cc.pToAngle(p)` | `CC.PToAngle(Vector2)` → `float` | `Mathf.Atan2(p.y, p.x)` | 3 | 待实现 |
| `cc.pMidpoint(p1, p2)` | `CC.PMidpoint(Vector2, Vector2)` → `Vector2` | `(p1 + p2) * 0.5f` | 7 | 待实现 |
| `cc.pointEqualToPoint(p1, p2)` | `CC.PointEqual(Vector2, Vector2)` → `bool` | `Vector2.Distance < epsilon` | 7 | 待实现 |
| `cc.pLerp(p1, p2, t)` | `CC.PLerp(Vector2, Vector2, float)` → `Vector2` | `Vector2.Lerp(p1, p2, t)` | 2 | 待实现 |
| `cc.pDot(p1, p2)` | `CC.PDot(Vector2, Vector2)` → `float` | `Vector2.Dot(p1, p2)` | 1 | 待实现 |

#### 矩形运算

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `cc.rectContainsPoint(rect, p)` | `CC.RectContainsPoint(Rect, Vector2)` → `bool` | `rect.Contains(p)` | 75 | 待实现 |
| `cc.rectIntersectsRect(r1, r2)` | `CC.RectIntersects(Rect, Rect)` → `bool` | `r1.Overlaps(r2)` | 11 | 待实现 |
| `cc.rectOverlapsRect(r1, r2)` | `CC.RectOverlaps(Rect, Rect)` → `bool` | `r1.Overlaps(r2)` | 2 | 待实现 |

#### 类型检查

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `cc.sys.isObjectValid(obj)` | `CC.IsValid(object)` → `bool` | `obj != null`；如果是 `UnityEngine.Object` 则用隐式 bool | 4,108 | 待实现 |
| `cc.isFunction(obj)` | `CC.IsFunction(object)` → `bool` | `obj is Delegate` 或 `obj is Action` | 1,103 | 待实现 |
| `cc.isUndefined(obj)` | `CC.IsUndefined(object)` → `bool` | `obj == null` | 998 | 待实现 |
| `cc.isNumber(obj)` | `CC.IsNumber(object)` → `bool` | `obj is int or float or double or long` | 522 | 待实现 |
| `cc.isArray(obj)` | `CC.IsArray(object)` → `bool` | `obj is IList` | 447 | 待实现 |
| `cc.isObject(obj)` | `CC.IsObject(object)` → `bool` | `obj != null && !(obj is ValueType)` | 94 | 待实现 |
| `cc.isString(obj)` | `CC.IsString(object)` → `bool` | `obj is string` | 87 | 待实现 |

#### 系统信息

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `cc.sys.isNative` | `CC.IsNative` → `bool` | `!Application.isEditor`（或平台判断） | 715 | 待实现 |
| `cc.sys.os` | `CC.SysOS` → `string` | `Application.platform` 映射 | 131 | 待实现 |
| `cc.sys.OS_IOS` | `CC.OS_IOS` → `string` | `"iOS"` 常量 | 74 | 待实现 |
| `cc.sys.OS_ANDROID` | `CC.OS_ANDROID` → `string` | `"Android"` 常量 | 53 | 待实现 |
| `cc.sys.openURL(url)` | `CC.OpenURL(string)` | `Application.OpenURL(url)` | 36 | 待实现 |
| `cc.sys.localStorage` | `CC.LocalStorage` | `PlayerPrefs` 封装 | 4 | 待实现 |
| `cc.sys.garbageCollect()` | `CC.GarbageCollect()` | `System.GC.Collect()` | 4 | 待实现 |
| `cc.sys.isMobile` | `CC.IsMobile` → `bool` | `Application.isMobilePlatform` | 2 | 待实现 |

#### 数学工具

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `cc.clampf(v, min, max)` | `CC.Clampf(float, float, float)` → `float` | `Mathf.Clamp(v, min, max)` | 8 | 待实现 |
| `cc.random0To1()` | `CC.Random01()` → `float` | `UnityEngine.Random.value` | 7 | 待实现 |
| `cc.lerp(a, b, t)` | `CC.Lerp(float, float, float)` → `float` | `Mathf.Lerp(a, b, t)` | 4 | 待实现 |
| `cc.radiansToDegrees(r)` | `CC.RadToDeg(float)` → `float` | `r * Mathf.Rad2Deg` | 1 | 待实现 |

#### 不需要映射（C# 天然解决）

| JS API | 次数 | C# 替代 |
|--------|------|---------|
| `cc.each(arr, func)` | 845 | `foreach` 循环 |
| `cc.log(...)` | 2,910 | `Debug.Log(...)` |
| `cc.error(...)` | 617 | `Debug.LogError(...)` |
| `cc.warn(...)` | 608 | `Debug.LogWarning(...)` |
| `cc.assert(...)` | 14 | `Debug.Assert(...)` |
| `cc.extend(target, src)` | 26 | 对象初始化器或手动赋值 |
| `cc.arrayRemoveObject(arr, obj)` | 2 | `list.Remove(obj)` |
| `cc.copyArray(arr)` | 1 | `new List<T>(arr)` |

---

### 3.3.2 CCAction.cs — 动作链 → DOTween Sequence

**JS 源**：Cocos2d 引擎内置 `cc.*` 动作系统  
**C# 文件**：`CCAction.cs`  
**依赖**：DOTween Pro  
**调用总量**：~9,256 (动作) + ~324 (easing) + ~3,124 (runAction)

#### 核心设计

```csharp
// JS 模式：
node.runAction(cc.sequence(
    cc.delayTime(0.5),
    cc.moveTo(0.3, cc.p(100, 200)),
    cc.callFunc(function() { ... })
));

// C# 映射：
CCAction.RunAction(transform, CCAction.Sequence(
    CCAction.DelayTime(0.5f),
    CCAction.MoveTo(0.3f, new Vector2(100, 200)),
    CCAction.CallFunc(() => { ... })
));

// 内部实现：构建并播放一个 DOTween Sequence
```

#### 容器动作

| JS API | C# 方法 | DOTween 映射 | 次数 | 状态 |
|--------|---------|-------------|------|------|
| `cc.sequence(a1, a2, ...)` | `CCAction.Sequence(params ITweenAction[])` | `DOTween.Sequence().Append(...)` 依次串接 | 2,183 | 待实现 |
| `cc.spawn(a1, a2, ...)` | `CCAction.Spawn(params ITweenAction[])` | `DOTween.Sequence().Join(...)` 并行 | 94 | 待实现 |
| `cc.repeat(action, times)` | `CCAction.Repeat(ITweenAction, int)` | `SetLoops(times)` | 2 | 待实现 |
| `cc.repeatForever(action)` | `CCAction.RepeatForever(ITweenAction)` | `SetLoops(-1)` | 62 | 待实现 |
| `cc.speed(action, speed)` | `CCAction.Speed(ITweenAction, float)` | `SetTimeScale(speed)` | 1 | 待实现 |
| `node.runAction(action)` | `CCAction.RunAction(Transform, ITweenAction)` | 构建 Sequence 并 Play | 3,124 | 待实现 |
| `node.stopAllActions()` | `CCAction.StopAll(Transform)` | `DOTween.Kill(transform)` | 待统计 | 待实现 |
| `node.stopAction(action)` | `CCAction.Stop(Tween)` | `tween.Kill()` | 待统计 | 待实现 |

#### 即时动作

| JS API | C# 方法 | DOTween 映射 | 次数 | 状态 |
|--------|---------|-------------|------|------|
| `cc.callFunc(func, target, data)` | `CCAction.CallFunc(Action)` | `AppendCallback(func)` | 2,781 | 待实现 |
| `cc.show()` | `CCAction.Show()` | `AppendCallback(() => go.SetActive(true))` | 42 | 待实现 |
| `cc.hide()` | `CCAction.Hide()` | `AppendCallback(() => go.SetActive(false))` | 68 | 待实现 |
| `cc.removeSelf()` | `CCAction.RemoveSelf()` | `AppendCallback(() => Destroy(go))` | 33 | 待实现 |
| `cc.place(x, y)` | `CCAction.Place(Vector2)` | `AppendCallback(() => transform.localPosition = pos)` | 5 | 待实现 |

#### 间隔动作

| JS API | C# 方法 | DOTween 映射 | 次数 | 状态 |
|--------|---------|-------------|------|------|
| `cc.delayTime(d)` | `CCAction.DelayTime(float)` | `AppendInterval(d)` | 2,373 | 待实现 |
| `cc.moveTo(d, pos)` | `CCAction.MoveTo(float, Vector2)` | `DOLocalMove(pos, d)` | 643 | 待实现 |
| `cc.moveBy(d, delta)` | `CCAction.MoveBy(float, Vector2)` | `DOLocalMove(current+delta, d)` | 164 | 待实现 |
| `cc.scaleTo(d, sx, sy)` | `CCAction.ScaleTo(float, float, float?)` | `DOScale(new Vector3(sx,sy,1), d)` | 353 | 待实现 |
| `cc.scaleBy(d, sx, sy)` | `CCAction.ScaleBy(float, float, float?)` | `DOScale(current*s, d)` | 8 | 待实现 |
| `cc.fadeTo(d, opacity)` | `CCAction.FadeTo(float, float)` | `DOFade(opacity/255f, d)` on CanvasGroup/SpriteRenderer | 79 | 待实现 |
| `cc.fadeIn(d)` | `CCAction.FadeIn(float)` | `DOFade(1f, d)` | 108 | 待实现 |
| `cc.fadeOut(d)` | `CCAction.FadeOut(float)` | `DOFade(0f, d)` | 71 | 待实现 |
| `cc.rotateTo(d, angle)` | `CCAction.RotateTo(float, float)` | `DOLocalRotate(new Vector3(0,0,-angle), d)` | 32 | 待实现 |
| `cc.rotateBy(d, angle)` | `CCAction.RotateBy(float, float)` | `DOLocalRotate(delta, d, RotateMode.LocalAxisAdd)` | 28 | 待实现 |
| `cc.bezierTo(d, points)` | `CCAction.BezierTo(float, Vector2[])` | `DOLocalPath(path, d, PathType.CubicBezier)` | 233 | 待实现 |
| `cc.bezierBy(d, points)` | `CCAction.BezierBy(float, Vector2[])` | 类似，基于相对偏移 | 1 | 待实现 |
| `cc.jumpTo(d, pos, h, jumps)` | `CCAction.JumpTo(float, Vector2, float, int)` | `DOLocalJump(pos, h, jumps, d)` | 20 | 待实现 |
| `cc.tintTo(d, r, g, b)` | `CCAction.TintTo(float, Color)` | `DOColor(color, d)` on SpriteRenderer | 27 | 待实现 |
| `cc.progressTo(d, percent)` | `CCAction.ProgressTo(float, float)` | `DOValue(percent, d)` on Slider/Image.fillAmount | 223 | 待实现 |
| `cc.progressFromTo(d, from, to)` | `CCAction.ProgressFromTo(float, float, float)` | `DOValue` with from/to | 3 | 待实现 |
| `cc.animate(anim)` | `CCAction.Animate(AnimationClip)` | Animator 播放 | 9 | 待实现 |
| `cc.orbitCamera(d, ...)` | `CCAction.OrbitCamera(...)` | 自定义旋转 Tween | 4 | 待实现 |

#### Easing 函数

| JS API | C# 映射 | DOTween Ease | 次数 | 状态 |
|--------|---------|-------------|------|------|
| `action.easing(cc.easeIn(rate))` | `.SetEase(Ease.InQuad)` | rate≈2: InQuad, rate≈3: InCubic | 119 | 待实现 |
| `cc.easeOut(rate)` | `.SetEase(Ease.OutQuad)` | 同上映射 | 21 | 待实现 |
| `cc.easeInOut(rate)` | `.SetEase(Ease.InOutQuad)` | 同上映射 | 30 | 待实现 |
| `cc.easeBackOut()` | `.SetEase(Ease.OutBack)` | | 50 | 待实现 |
| `cc.easeBackIn()` | `.SetEase(Ease.InBack)` | | 4 | 待实现 |
| `cc.easeBackInOut()` | `.SetEase(Ease.InOutBack)` | | 3 | 待实现 |
| `cc.easeSineIn()` | `.SetEase(Ease.InSine)` | | 11 | 待实现 |
| `cc.easeSineOut()` | `.SetEase(Ease.OutSine)` | | 13 | 待实现 |
| `cc.easeSineInOut()` | `.SetEase(Ease.InOutSine)` | | 21 | 待实现 |
| `cc.easeBounceOut()` | `.SetEase(Ease.OutBounce)` | | 20 | 待实现 |
| `cc.easeElasticOut()` | `.SetEase(Ease.OutElastic)` | | 4 | 待实现 |
| `cc.easeExponentialOut()` | `.SetEase(Ease.OutExpo)` | | 6 | 待实现 |
| `cc.easeExponentialIn()` | `.SetEase(Ease.InExpo)` | | 2 | 待实现 |
| `cc.easeExponentialInOut()` | `.SetEase(Ease.InOutExpo)` | | 5 | 待实现 |
| `cc.easeCircleActionOut()` | `.SetEase(Ease.OutCirc)` | | 5 | 待实现 |
| `cc.easeBezierAction(a,b,c,d)` | `.SetEase(AnimationCurve)` | 自定义贝塞尔曲线 | 8 | 待实现 |
| `cc.easeQuadraticActionInOut()` | `.SetEase(Ease.InOutQuad)` | | 2 | 待实现 |

#### ITweenAction 接口设计

```csharp
// 所有 CCAction 方法返回 ITweenAction，用于组合
public interface ITweenAction
{
    void ApplyTo(Sequence seq, Transform target);
}

// 使用示例
CCAction.RunAction(transform, CCAction.Sequence(
    CCAction.DelayTime(0.5f),
    CCAction.MoveTo(0.3f, new Vector2(100, 200)).Easing(Ease.OutBack),
    CCAction.CallFunc(() => Debug.Log("done"))
));
```

---

### 3.3.3 NodeHelper.cs — 节点操作

**JS 源**：`src/common/util/NodeHelper.js` (491 行)  
**C# 文件**：`NodeHelper.cs`  
**调用总量**：~17,283

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `setNodeVisible(node, visible)` | `NodeHelper.SetVisible(GameObject, bool)` | `go.SetActive(visible)` | 10,105 | 待实现 |
| `setNodeText(node, text, isScaleY)` | `NodeHelper.SetText(Component, string, bool)` | `TMP_Text.text = text`；如有 `__oriLabelScale` 则自动缩放 | 2,692 | 待实现 |
| `setNodeEnabled(node, enabled)` | `NodeHelper.SetEnabled(Component, bool)` | `Selectable.interactable` 或自定义 `ISetEnabled` | 1,929 | 待实现 |
| `setSpriteFrameName(sprite, name)` | `NodeHelper.SetSpriteFrame(Image, string)` | `image.sprite = Resources.Load<Sprite>(name)` 或 Addressable | 726 | 待实现 |
| `setNodePosition(node, pos)` | `NodeHelper.SetPosition(Transform, Vector2)` | `transform.localPosition = pos` | 315 | 待实现 |
| `removeCCBFromParent(node, cleanup)` | `NodeHelper.RemoveFromParent(GameObject, bool)` | `Destroy(go)` 或回收到池 | 301 | 待实现 |
| `setNodeLocalZOrder(node, z)` | `NodeHelper.SetZOrder(Transform, int)` | `transform.SetSiblingIndex(z)` | 283 | 待实现 |
| `removeNodeFromParent(node, cleanup)` | `NodeHelper.RemoveNode(GameObject, bool)` | `Destroy(go)` | 187 | 待实现 |
| `setNodeColor(node, color)` | `NodeHelper.SetColor(Component, Color)` | `Graphic.color = color` 或 `SpriteRenderer.color` | 136 | 待实现 |
| `setCascadeColorEnabledRecursive(node, b)` | `NodeHelper.SetCascadeColor(Transform, bool)` | Unity UI 天然级联颜色，可能不需要操作 | 110 | 待实现 |
| `setNodeOpacity(node, opacity)` | `NodeHelper.SetOpacity(Component, float)` | `CanvasGroup.alpha` 或 `color.a` | 103 | 待实现 |
| `setNodeRotationSafe(node, rot)` | `NodeHelper.SetRotation(Transform, float)` | `transform.localEulerAngles = new Vector3(0,0,-rot)` | 88 | 待实现 |
| `makeTouchable(node, swallow, priority)` | `NodeHelper.MakeTouchable(GameObject, bool, int)` | 添加 `Graphic.raycastTarget = true` 或 EventTrigger | 79 | 待实现 |
| `autoAlignNodes(nodes, groupI, innerI, cx)` | `NodeHelper.AutoAlign(Transform[], float, float, float)` | 计算总宽度后居中排列 | 65 | 待实现 |
| `setCascadeOpacityEnabledRecursive(node, b)` | `NodeHelper.SetCascadeOpacity(Transform, bool)` | `CanvasGroup` 控制级联透明 | 57 | 待实现 |
| `setNodeScale(node, sx, sy)` | `NodeHelper.SetScale(Transform, float, float?)` | `transform.localScale = new Vector3(sx, sy ?? sx, 1)` | 55 | 待实现 |
| `isNodeVisible(node)` | `NodeHelper.IsVisible(GameObject)` → `bool` | 遍历父链检查 `activeSelf` | 22 | 待实现 |
| `setNodeOpacityRecursive(node, opacity)` | `NodeHelper.SetOpacityRecursive(Transform, float)` | 递归设置所有子节点透明度 | 16 | 待实现 |
| `setNodeTextAutoChangeLine(node, text, maxW, align)` | `NodeHelper.SetTextAutoWrap(TMP_Text, string, float, TextAlignmentOptions)` | TMP 自动换行 + `rectTransform.sizeDelta` | 8 | 待实现 |
| `disableMultiTouch(rootNode)` | `NodeHelper.DisableMultiTouch(GameObject)` | `Input.multiTouchEnabled = false` 或自定义 | 2 | 待实现 |
| `autoAlignTextNodes(nodes, outerI, innerI, cx)` | `NodeHelper.AutoAlignText(Transform[], float, float, float)` | 类似 autoAlignNodes，处理嵌套文本+图标组合 | 2 | 待实现 |
| `verticalAlignNodes(nodes, interval, cy)` | `NodeHelper.VerticalAlign(Transform[], float, float)` | 垂直居中排列 | 1 | 待实现 |
| `stopNodeAction(node)` | `NodeHelper.StopAction(Transform)` | `DOTween.Kill(transform)` | 1 | 待实现 |

---

### 3.3.4 GameUtil.cs — 核心工具方法

**JS 源**：`src/common/util/Util.js` (1805 行)  
**C# 文件**：`GameUtil.cs`  
**调用总量**：~31,237（扣除不需要映射的 inherits/registerController 后约 ~22,000）

#### 动画与 CCB

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `playAnim(node, name, target, cb, arg)` | `GameUtil.PlayAnim(GameObject, string, Action)` | `Animator.Play(name)` + 回调等待动画结束 | 7,369 | 待实现 |
| `playCCBAnimation(node, name, target, cb, arg)` | `GameUtil.PlayCCBAnim(GameObject, string, Action)` | 同 PlayAnim（DEPRECATED 版本，内部转发） | 2,647 | 待实现 |
| `playDefaultAnim(node, target, cb, arg)` | `GameUtil.PlayDefaultAnim(GameObject, Action)` | `Animator.Play("default")` | 50 | 待实现 |
| `isCCBHasAnimation(node, name)` | `GameUtil.HasAnimation(GameObject, string)` → `bool` | 检查 Animator 是否含指定 State | 124 | 待实现 |
| `loadNodeFromCCB(ccb, parent, ctrl, ctrlNode)` | `GameUtil.LoadPrefab(string, Transform, ...)` → `GameObject` | `Addressables.InstantiateAsync` 或 `Instantiate(prefab)` + NameBinder | 2,186 | 待实现 |
| `loadNodeFromSpine(spine, skin)` | `GameUtil.LoadSpine(string, string)` → `GameObject` | Spine-Unity runtime 加载 | 26 | 待实现 |
| `animManRunSeqName(node, seqName)` | `GameUtil.RunAnimSeq(GameObject, string)` | `Animator.Play(seqName)` | 459 | 待实现 |
| `animManRunSeqId(node, seqId, duration)` | `GameUtil.RunAnimSeqById(GameObject, int, float)` | 根据 ID 播放（需建立映射） | 41 | 待实现 |
| `seekNodeByTag(root, tag)` | `GameUtil.SeekByTag(Transform, int)` → `Transform` | 递归 `Transform.Find` 或预建 tag 索引 | 1,841 | 待实现 |
| `recordLabelScale(label)` | `GameUtil.RecordLabelScale(TMP_Text)` | 存储原始 scale/width 到自定义组件 | 242 | 待实现 |
| `recordCCLabelScale(label)` | `GameUtil.RecordCCLabelScale(TMP_Text)` | 同上 | 32 | 待实现 |

#### 字符串格式化

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `sprintf(fmt, ...)` | `GameUtil.Sprintf(string, params object[])` | `string.Format()` 适配 %d/%s/%f 格式 | 1,281 | 待实现 |
| `getCommaNum(num)` | `GameUtil.GetCommaNum(long)` → `string` | `num.ToString("N0")` | 818 | 待实现 |
| `formatAbbrNumAutoComma(num, round)` | `GameUtil.FormatAbbrAuto(double, ...)` → `string` | K/M/B/T 缩写 + 自动小数 | 675 | 待实现 |
| `formatAbbrNumOneComma(num, round)` | `GameUtil.FormatAbbrOne(double, ...)` → `string` | 最多 1 位小数 | 136 | 待实现 |
| `formatAbbrNumWithoutComma(num, round)` | `GameUtil.FormatAbbrInt(double, ...)` → `string` | 无小数 | 44 | 待实现 |
| `formatAbbrNumThreeComma(num, round)` | `GameUtil.FormatAbbrThree(double, ...)` → `string` | 最多 3 位小数 | 3 | 待实现 |
| `formatAbbrNumWithPrecision(num, r, p)` | `GameUtil.FormatAbbrPrecision(double, ...)` → `string` | 可配精度 | 5 | 待实现 |
| `formatNumForSlotMachine(num, round)` | `GameUtil.FormatSlotNum(double, ...)` → `string` | 3+ 位整数无小数 | 49 | 待实现 |
| `getFormatTime(ms, showH, showD)` | `GameUtil.FormatTime(long, bool, bool)` → `string` | `TimeSpan` 格式化 | 422 | 待实现 |
| `getFormatTimeDays(ms, ...)` | `GameUtil.FormatTimeDays(long, ...)` → `string` | "X DAYS HH:MM:SS" | 75 | 待实现 |
| `getFormatTimeDaysPlus(ms, ...)` | `GameUtil.FormatTimeDaysPlus(long, ...)` → `string` | "Xd Yh" | 63 | 待实现 |
| `getFormatDate(fmt, date)` | `GameUtil.FormatDate(string, DateTime)` → `string` | `DateTime.ToString(fmt)` | 6 | 待实现 |
| `getTwoDigit(num)` | `GameUtil.TwoDigit(int)` → `string` | `num.ToString("D2")` | 34 | 待实现 |
| `getRankSuffix(rank, upper)` | `GameUtil.RankSuffix(int, bool)` → `string` | 1st/2nd/3rd/4th... | 14 | 待实现 |
| `omitText(text, maxLen)` | `GameUtil.OmitText(string, int)` → `string` | 截断 + "..." | 16 | 待实现 |

#### 数学与随机

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `floorPrecision(num)` | `GameUtil.FloorPrecision(double)` → `long` | `Math.Floor(num + 1e-11)` | 871 | 待实现 |
| `ceilPrecision(num)` | `GameUtil.CeilPrecision(double)` → `long` | `Math.Ceiling(num - 1e-11)` | 131 | 待实现 |
| `randomNextInt(upper)` | `GameUtil.RandomInt(int)` → `int` | `UnityEngine.Random.Range(0, upper)` | 227 | 待实现 |
| `randomNextIntInRange(lower, upper)` | `GameUtil.RandomRange(int, int)` → `int` | `Random.Range(lower, upper)` | 85 | 待实现 |
| `shuffle2(array)` | `GameUtil.Shuffle<T>(List<T>)` | Fisher-Yates 原地洗牌 | 180 | 待实现 |
| `deepCopyObject(target, source)` | `GameUtil.DeepCopy<T>(T)` → `T` | JSON 序列化/反序列化 或手动深拷贝 | 447 | 待实现 |
| `deepClone(obj)` | `GameUtil.DeepClone<T>(T)` → `T` | 同上 | 112 | 待实现 |
| `clone(obj)` | `GameUtil.Clone<T>(T)` → `T` | `MemberwiseClone` | 72 | 待实现 |
| `arrContain(arr, elem)` | `GameUtil.Contains<T>(IList<T>, T)` → `bool` | `list.Contains(elem)` | 16 | 待实现 |

#### 标签缩放

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `scaleCCLabelBMFont(label, maxW, defScale)` | `GameUtil.ScaleLabel(TMP_Text, float, float)` | 根据文本宽度计算缩放 | 3 | 待实现 |
| `scaleCCLabelBMFontWithOriScale(l, w, s, sy)` | `GameUtil.ScaleLabelOri(TMP_Text, float, float, float)` | 保持原始比例缩放 | 7 | 待实现 |

#### 延迟调用

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `delayCall(sec, cb, node, tag, arg)` | `GameUtil.DelayCall(float, Action, ...)` | `DOVirtual.DelayedCall(sec, cb)` 或 Coroutine | 418 | 待实现 |
| `delayCallWithTarget(sec, target, cb, ...)` | `GameUtil.DelayCallTarget(float, object, Action, ...)` | 同上，带目标生命周期绑定 | 125 | 待实现 |
| `cancelDelayCall(tag, node)` | `GameUtil.CancelDelay(int, ...)` | Kill 对应 Tween | 20 | 待实现 |

#### 文件与资源

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `isFileExist(fileName)` | `GameUtil.FileExists(string)` → `bool` | `Addressables.GetDownloadSizeAsync` 或 Resources 检查 | 261 | 待实现 |
| `loadJson(url)` | `GameUtil.LoadJson<T>(string)` → `T` | `JsonUtility.FromJson` 或 `Newtonsoft.Json` | 27 | 待实现 |

#### 平台与设备

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `isAndroidOneSixAdapter()` | `GameUtil.IsAndroid16Ratio()` → `bool` | `Screen.width / Screen.height` 计算 | 71 | 待实现 |
| `getScreenSize()` | `GameUtil.GetScreenSize()` → `Vector2` | `new Vector2(Screen.width, Screen.height)` | 待统计 | 待实现 |

#### 不需要映射（C# 天然解决）

| JS API | 次数 | C# 替代 |
|--------|------|---------|
| `inherits(Sub, Super)` | 4,170 | `class Sub : Super` |
| `registerController(name, cls)` | 2,561 | NameBinder 替代 |
| `unRegisterController(name)` | 2,547 | NameBinder 替代 |
| `getCurrentTime()` | 待统计 | `DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()` |

---

### 3.3.5 SlotUtil.cs — Slot 专用工具

**JS 源**：`src/newdesign_slot/tools/SlotUtil.js` (1211 行)  
**C# 文件**：`SlotUtil.cs`  
**调用总量**：~10,199

#### 动画与音效

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `playAnim(node, name, ...cbs)` | `SlotUtil.PlayAnim(GameObject, string, params Action[])` | Animator 播放 + 多回调链接 | 3,927 | 待实现 |
| `playAnimEasy(node, name, ...cbs)` | `SlotUtil.PlayAnimEasy(GameObject, string, params Action[])` | 同上，静默忽略无效节点 | 731 | 待实现 |
| `playEffect(name, loop)` | `SlotUtil.PlayEffect(string, bool)` | AudioBridge 播放音效 | 1,566 | 待实现 |
| `stopEffect(name)` | `SlotUtil.StopEffect(string)` | AudioBridge 停止音效 | 146 | 待实现 |
| `stopMusic()` | `SlotUtil.StopMusic()` | AudioBridge 停止背景音乐 | 44 | 待实现 |
| `playChipsUpEffect(duration)` | `SlotUtil.PlayChipsUpEffect(float)` | 播放筹码上升音效 | 5 | 待实现 |

#### 延迟与流控制

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `delayCall(sec, func, name)` | `SlotUtil.DelayCall(float, Action, string)` | `DOVirtual.DelayedCall` 绑定到当前 SlotMachine 生命周期 | 1,312 | 待实现 |
| `cancelDelayCallByName(name)` | `SlotUtil.CancelDelay(string)` | Kill 指定名称的 Tween | 91 | 待实现 |
| `clearDelayCall()` | `SlotUtil.ClearAllDelay()` | Kill 所有关联 Tween | 3 | 待实现 |
| `createFlow(handler, name)` | `SlotUtil.CreateFlow(Action<Action>, string)` → `SlotFlow` | 异步流控制（串行回调队列） | 626 | 待实现 |

#### 飞行动画

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `flyItemByWorldPos(node, root, from, to, d, cb, pre, mid, ease)` | `SlotUtil.FlyByWorldPos(...)` | 贝塞尔曲线 DOTween 动画 | 59 | 待实现 |
| `flyItem(node, from, to, d, cb, pre)` | `SlotUtil.FlyItem(...)` | 同上简化版 | 19 | 待实现 |
| `flyCCBItem(ccb, root, from, to, d, cb, pre, mid, ease)` | `SlotUtil.FlyCCB(...)` | 加载 Prefab + 飞行 + 销毁 | 27 | 待实现 |
| `flyCCBItemWithRecycle(...)` | `SlotUtil.FlyCCBRecycle(...)` | 飞行 + 对象池回收 | 64 | 待实现 |
| `flyCCBItemWithCleanup(...)` | `SlotUtil.FlyCCBCleanup(...)` | 飞行 + 完全清理 | 2 | 待实现 |

#### 坐标转换

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `getWorldPosition(node)` | `SlotUtil.GetWorldPos(Transform)` → `Vector3` | `transform.position` | 125 | 待实现 |
| `getNodePosition(node, worldPos)` | `SlotUtil.WorldToLocal(Transform, Vector3)` → `Vector3` | `transform.InverseTransformPoint(worldPos)` | 39 | 待实现 |
| `getAngle(from, to, offset)` | `SlotUtil.GetAngle(Transform, Transform, float)` → `float` | `Mathf.Atan2` 计算角度 | 8 | 待实现 |
| `getDistance(from, to)` | `SlotUtil.GetDistance(Transform, Transform)` → `float` | `Vector3.Distance` | 1 | 待实现 |

#### 文本格式

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `setNodeText(node, text)` | `SlotUtil.SetText(Component, string)` | 转发到 `NodeHelper.SetText` | 346 | 待实现 |
| `setNodeTextWithForAbbrChipsAppropriate(node, chips)` | `SlotUtil.SetChipsTextAuto(Component, double)` | 智能缩写：100K / 10.1K / 1.01K | 226 | 待实现 |
| `setNodeTextWithForAbbrChips(node, chips, type)` | `SlotUtil.SetChipsText(Component, double, int)` | 按类型缩写 | 63 | 待实现 |
| `setNodeTextForCommaChips(node, chips, modPos)` | `SlotUtil.SetCommaChips(Component, double, bool)` | 千分位格式 | 91 | 待实现 |
| `getAnimationKeyByPos(col, row, prefix)` | `SlotUtil.AnimKeyByPos(int, int, string)` → `string` | `$"{prefix}_{col}_{row}"` | 344 | 待实现 |
| `formatAbbrNumAutoCommaFloor(chips)` | `SlotUtil.FormatAbbrFloor(double)` → `string` | 缩写 + floor | 15 | 待实现 |
| `padString(str, len, pad)` | `SlotUtil.PadLeft(string, int, char)` → `string` | `str.PadLeft(len, pad)` | 4 | 待实现 |

#### 赢分等级

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `setWinLevel(totalWin, panel)` | `SlotUtil.SetWinLevel(double, SpinPanel)` | 根据 bet 倍率设置 BIG/MEGA/SMALL | 34 | 待实现 |
| `getWinLevel(totalWin)` | `SlotUtil.GetWinLevel(double)` → `int` | 纯计算，无副作用 | 59 | 待实现 |
| `hasBigWin(totalWin)` | `SlotUtil.HasBigWin(double)` → `bool` | `winLevel >= BIG_WIN` | 15 | 待实现 |

#### 遍历工具

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `traverseCell(cols, rows, func)` | `SlotUtil.TraverseCell(int, int, Action<int,int>)` | 双层循环 | 7 | 待实现 |
| `traverseCellNature(cols, rows, func)` | `SlotUtil.TraverseCellNature(int, int, Action<int,int>)` | 双层循环（底→顶） | 1 | 待实现 |

#### 杂项

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `getCurrentSlotMachine()` | `SlotUtil.GetCurrentMachine()` → `SlotMachineBase` | 静态引用 | 21 | 待实现 |
| `getCurrentMachineConfig()` | `SlotUtil.GetCurrentConfig()` → `MachineConfig` | 通过 CurrentMachine 获取 | 21 | 待实现 |
| `shakeScreen(d, inT, outT, scale, pos, shakeD)` | `SlotUtil.ShakeScreen(...)` | DOTween.Shake | 14 | 待实现 |
| `stopShakeScreen()` | `SlotUtil.StopShake()` | Kill Shake Tween | 2 | 待实现 |
| `randomDataFromList(list, prob)` | `SlotUtil.WeightedRandom<T>(T[], float[])` → `T` | 按权重随机 | 25 | 待实现 |
| `getRandomFromArray(arr, count)` | `SlotUtil.RandomPick<T>(T[], int)` → `T[]` | 洗牌取前 N | 3 | 待实现 |
| `resetParticlePositionType(node)` | `SlotUtil.ResetParticlePos(Transform)` | 重置粒子系统 SimulationSpace | 11 | 待实现 |
| `copyNodePerspective(anim, sprite)` | `SlotUtil.CopyPerspective(Transform, Transform)` | 复制 scale/rotation | 2 | 待实现 |
| `sendSlotParam(cb, param)` | `SlotUtil.SendSlotParam(Action, object)` | 网络层转发（需协议适配） | 5 | 待实现 |
| `getJackpotLevelRatioMap(subjectId)` | `SlotUtil.GetJackpotRatios(int)` → `Dictionary` | 配置查表 | 2 | 待实现 |
| `getJackpotMaxValue(subjectId)` | `SlotUtil.GetJackpotMax(int)` → `double` | 配置查表 | 1 | 待实现 |
| `getNewVirtualLineNum()` | `SlotUtil.GetVirtualLineNum()` → `int` | 特殊关卡虚拟线数调整 | 9 | 待实现 |
| `recordSpinPanel(context)` | `SlotUtil.RecordPanel(SlotMachineBase)` | 深拷贝当前面板符号 | 1 | 待实现 |
| `restoreSpinPanel(context)` | `SlotUtil.RestorePanel(SlotMachineBase)` | 恢复面板 | 1 | 待实现 |

---

### 3.3.6 ActivityUtil.cs — 活动工具

**JS 源**：`src/task/tools/ActivityUtil.js` (1784 行)  
**C# 文件**：`ActivityUtil.cs`  
**调用总量**：~5,275

> 注：ActivityUtil 中有相当比例的方法是活动系统（Activity）专用的，不在 Slot 关卡中直接使用。
> 此处仅列出在 Slot 关卡代码中实际被调用的方法。完整列表见 [09-appendix-api-reference.md](09-appendix-api-reference.md)。

#### Slot 关卡高频使用

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `setNodeTextAutoScale(node, text, isScaleY)` | `AUtil.SetTextAutoScale(Component, string, bool)` | TMP_Text + 自动宽度缩放 | 1,248 | 待实现 |
| `delayCallWithNode(sec, cb, root, tag, arg)` | `AUtil.DelayCallNode(float, Action, GameObject, int)` | 绑定 GameObject 生命周期的延迟调用 | 650 | 待实现 |
| `getCurrentSequenceName(node)` | `AUtil.GetAnimSequenceName(GameObject)` → `string` | 获取当前播放的 Animator State 名 | 372 | 待实现 |
| `createFlowNode(rootNode)` | `AUtil.CreateFlowNode(GameObject)` → `FlowNode` | 创建异步流节点 | 366 | 待实现 |
| `convertToNodeSpace(node, root, offset)` | `AUtil.ConvertToNodeSpace(Transform, Transform, Vector2)` → `Vector2` | `InverseTransformPoint` | 337 | 待实现 |
| `showOneChildByTag(root, tag)` | `AUtil.ShowOneChild(Transform, int)` | 隐藏所有子节点，只显示指定 tag 的 | 328 | 待实现 |
| `safelyButtonClicked(sender, cb)` | `AUtil.SafeButtonClick(Button, Action)` | 防重复点击 | 229 | 待实现 |
| `arraySearch(arr, pred, def)` | `AUtil.ArraySearch<T>(T[], Func<T,bool>, T)` → `T` | `arr.FirstOrDefault(pred) ?? def` | 138 | 待实现 |
| `cancelDelayCall(tag, root)` | `AUtil.CancelDelay(int, GameObject)` | Kill 指定 Tween | 84 | 待实现 |
| `playAnimOnce(node, name, target, cb, arg)` | `AUtil.PlayAnimOnce(GameObject, string, Action)` | 仅当非当前动画时播放 | 88 | 待实现 |
| `hidePanel(panel, noAnim)` | `AUtil.HidePanel(GameObject, bool)` | 播放 "disappear" 动画或直接隐藏 | 81 | 待实现 |
| `safelyButtonClickedV2(sender, cb, delay)` | `AUtil.SafeButtonClickV2(Button, Action, float)` | 带冷却时间的防重复 | 74 | 待实现 |
| `centralizeCoinLabel(coin, label, text, noScale)` | `AUtil.CenterCoinLabel(Transform, TMP_Text, string, bool)` | 图标+文本水平居中 | 71 | 待实现 |
| `arraySum(arr, iterator)` | `AUtil.ArraySum<T>(T[], Func<T,double>)` → `double` | `arr.Sum(iterator)` | 56 | 待实现 |
| `arrayFilter(arr, filter)` | `AUtil.ArrayFilter<T>(T[], Func<T,bool>)` → `T[]` | `arr.Where(filter).ToArray()` | 39 | 待实现 |
| `hideAllChildren(root)` | `AUtil.HideAllChildren(Transform)` | 遍历隐藏 | 28 | 待实现 |
| `showPanel(panel, isToggle)` | `AUtil.ShowPanel(GameObject, bool)` | 播放 "appear" 动画或直接显示 | 135 | 待实现 |
| `getSequenceDuration(node, name)` | `AUtil.GetAnimDuration(GameObject, string)` → `float` | `AnimatorStateInfo.length` | 10 | 待实现 |
| `replaceLabelString(label, value, search, ...)` | `AUtil.ReplaceLabel(TMP_Text, string, string, ...)` | 文本占位符替换 | 24 | 待实现 |
| `flyExistItemToPoint(from, end, time, spawn, cb)` | `AUtil.FlyToPoint(Transform, Transform, float, ...)` | DOTween 移动 | 19 | 待实现 |
| `seekAllNodesByTag(root, tag, result)` | `AUtil.SeekAllByTag(Transform, int)` → `List<Transform>` | 递归查找 | 25 | 待实现 |
| `getStorageCacheItem(ctrl, key, def, prefix)` | `AUtil.GetCache(string, string, string)` → `string` | PlayerPrefs 带内存缓存 | 30 | 待实现 |
| `setStorageCacheItem(ctrl, key, val, prefix)` | `AUtil.SetCache(string, string, string)` | PlayerPrefs + 内存缓存 | 32 | 待实现 |

#### 数组工具

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `arrayContain(arr, elem)` | `AUtil.Contains<T>(T[], T)` → `bool` | `Array.IndexOf >= 0` | 12 | 待实现 |
| `arrayRemoveFirst(arr, pred, def)` | `AUtil.RemoveFirst<T>(List<T>, Func<T,bool>)` → `T` | 找到并移除 | 16 | 待实现 |
| `arrayRemove(arr, pred, max)` | `AUtil.Remove<T>(List<T>, Func<T,bool>, int)` | 批量移除 | 7 | 待实现 |
| `arrayMax(arr, iterator)` | `AUtil.ArrayMax<T>(T[], Func<T,double>)` → `double` | `arr.Max(iterator)` | 8 | 待实现 |
| `arrayMin(arr, iterator)` | `AUtil.ArrayMin<T>(T[], Func<T,double>)` → `double` | `arr.Min(iterator)` | 5 | 待实现 |
| `arrayTrain(arr, iterator, cb)` | `AUtil.ArrayTrain<T>(T[], Action<T,Action>, Action)` | 异步串行执行 | 5 | 待实现 |

---

### 3.3.7 NameBinder.cs — CCB 属性自动绑定

**模式来源**：`.controller._propertyName` 访问（~24,000 次）  
**C# 文件**：`NameBinder.cs`

#### 问题描述

Cocos CCB 文件通过 CocosBuilder 的 "Owner Variable" 机制将节点绑定到 controller 的属性上。代码中通过 `node.controller._btnSpin` 这样的模式访问这些绑定节点。

这 ~24,000 次访问分布在 2,514 个文件中，是最普遍的 Cocos 特有模式。

#### 设计方案

```csharp
/// <summary>
/// 自动绑定系统：通过 Transform.Find 按名称查找子节点，
/// 绑定到 MonoBehaviour 的字段上。
/// 替代 Cocos CCB 的 controller._propertyName 模式。
/// </summary>
public class NameBinder : MonoBehaviour
{
    /// <summary>
    /// 扫描目标组件上标记了 [AutoBind] 的字段，
    /// 通过 Transform.Find(fieldName) 自动绑定。
    /// </summary>
    public static void Bind(MonoBehaviour target, Transform root = null);
    
    /// <summary>
    /// 手动按名称查找并返回子节点。
    /// 兼容嵌套路径如 "panel/btnSpin"。
    /// </summary>
    public static Transform Find(Transform root, string name);
    
    /// <summary>
    /// 批量查找，返回字典。
    /// </summary>
    public static Dictionary<string, Transform> FindAll(Transform root, params string[] names);
}

/// <summary>
/// 标记字段为自动绑定目标。
/// 字段名（去掉下划线前缀）作为查找名称。
/// </summary>
[AttributeUsage(AttributeTargets.Field)]
public class AutoBindAttribute : Attribute
{
    public string OverrideName { get; set; }
}

// 使用示例：
public class WildsStarburstMachine : SlotMachineBase
{
    [AutoBind] private Transform _btnSpin;        // 查找名为 "btnSpin" 的子节点
    [AutoBind] private Transform _nodeWinEffect;  // 查找名为 "nodeWinEffect"
    [AutoBind("customName")] private Transform _special; // 指定查找名
    
    protected override void OnInit()
    {
        NameBinder.Bind(this);  // 一次调用完成所有绑定
    }
}
```

#### 映射规则

| JS 模式 | C# 模式 |
|---------|---------|
| `this.node.controller._btnSpin` | `this._btnSpin`（通过 [AutoBind] 自动绑定） |
| `this.node.controller.initWith(data)` | `this.InitWith(data)`（直接方法调用） |
| `someNode.controller._label` | `NameBinder.Find(someNode, "label")` |
| `game.util.loadNodeFromCCB("xxx", parent)` | `GameUtil.LoadPrefab("xxx", parent)` → 自动执行 NameBinder.Bind |

---

### 3.3.8 其他辅助类

以下类优先级较低，方法数和调用量也相对较少，可在主要类完成后再实现。

#### UIHelper.cs

| JS API | C# 方法 | 次数 | 状态 |
|--------|---------|------|------|
| `showFlyCoins(...)` | `UIHelper.ShowFlyCoins(...)` | 高 | 待实现 |
| `showFlyCoinsFromNode(...)` | `UIHelper.FlyCoinsFrom(...)` | 中 | 待实现 |
| `getCoinIconWorldPosition()` | `UIHelper.GetCoinIconPos()` → `Vector3` | 中 | 待实现 |
| `getBezierControlPosition(from, to)` | `UIHelper.GetBezierCtrl(Vector3, Vector3)` → `Vector3` | 中 | 待实现 |
| `addMaskLayer(root, opacity, cb)` | `UIHelper.AddMask(Transform, float, Action)` | 低 | 待实现 |
| `removeMaskLayer(root)` | `UIHelper.RemoveMask(Transform)` | 低 | 待实现 |
| `createTouchPanel(root, cb)` | `UIHelper.CreateTouchPanel(Transform, Action)` | 低 | 待实现 |
| 其余 ~27 个方法 | 见 [09-appendix-api-reference.md](09-appendix-api-reference.md) | | 待实现 |

#### EventDispatcher.cs

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `addEventListener(event, cb, target, priority)` | `EventDispatcher.On(string, Action<object>, int)` | C# event 或自定义发布-订阅 | 高 | 待实现 |
| `removeEventListener(event, cb, target)` | `EventDispatcher.Off(string, Action<object>)` | | 高 | 待实现 |
| `dispatchEvent(event, data)` | `EventDispatcher.Emit(string, object)` | | 高 | 待实现 |

#### AudioBridge.cs

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `playEffectByKey(name, loop)` | `AudioBridge.PlayEffect(string, bool)` | `AudioSource.PlayOneShot` 或音频管理器 | 高 | 待实现 |
| `stopEffect(name)` | `AudioBridge.StopEffect(string)` | | 中 | 待实现 |
| `playMusic(key, loop)` | `AudioBridge.PlayMusic(string, bool)` | | 中 | 待实现 |
| `stopMusic()` | `AudioBridge.StopMusic()` | | 中 | 待实现 |
| `setAudioOn(on)` | `AudioBridge.SetEnabled(bool)` | | 低 | 待实现 |

#### DialogBridge.cs

| JS API | C# 方法 | Unity 实现策略 | 次数 | 状态 |
|--------|---------|---------------|------|------|
| `show(dlg, params)` | `DialogBridge.Show(string, object)` | Prefab 实例化 + 入场动画 | 中 | 待实现 |
| `close(dlg, cleanup)` | `DialogBridge.Close(GameObject, bool)` | 退场动画 + 销毁 | 中 | 待实现 |
| `pushToWaitingStack(dlg, params)` | `DialogBridge.PushToQueue(string, object)` | 弹窗队列 | 低 | 待实现 |

---

## 3.4 特殊处理项

### 3.4.1 `game.util.inherits()` — 消除

JS 中用 `game.util.inherits(SubClass, SuperClass)` 实现原型链继承（4,170 次调用）。

**C# 处理**：完全不需要。直接使用 `class SubClass : SuperClass` 语法。

**转换规则**：
```javascript
// JS
game.util.inherits(WildsStarburstMachineScene287, SlotMachineScene2022);
// → C# 不生成任何代码，继承关系体现在类声明中：
// public class WildsStarburstMachine : SlotMachineBase
```

### 3.4.2 `cc.Class.extend()` — 消除

JS 中用 `cc.Class.extend({ ... })` 定义新类（242 次）。

**C# 处理**：同上，直接用 class 语法。

### 3.4.3 `registerController` / `unRegisterController` — NameBinder 替代

JS 中 `game.util.registerController("MyController", MyClass)` 用于将 CCB controller 类注册到全局表（~5,108 次合计）。

**C# 处理**：由 NameBinder 系统完全替代。Unity Prefab 直接挂载 MonoBehaviour，无需注册/反注册。

### 3.4.4 `loadNodeFromCCB` → Prefab + NameBinder

JS 中 `game.util.loadNodeFromCCB("path.ccbi", parent, "ControllerName")` 加载 CCB 文件并绑定 controller（2,186 次）。

**C# 处理**：
```csharp
// GameUtil.LoadPrefab 内部流程：
// 1. Addressables.InstantiateAsync(prefabPath) 或 Instantiate(Resources.Load<GameObject>(path))
// 2. 设置 parent
// 3. 获取目标 MonoBehaviour 组件
// 4. 调用 NameBinder.Bind(component) 自动绑定子节点
// 5. 返回 GameObject
```

### 3.4.5 `cc.Node` 构造 → Unity GameObject

JS 中 `new cc.Node()` 创建空节点（989 次），`new cc.Sprite()` 创建精灵节点（445 次）。

**C# 处理**：
```csharp
// cc.Node() → new GameObject()
// cc.Sprite(frame) → 创建 GameObject + 添加 Image/SpriteRenderer 组件
// cc.ProgressTimer() → 创建 GameObject + Image(type=Filled)
// cc.Scale9Sprite() → 创建 GameObject + Image(type=Sliced)
// cc.ClippingNode() → 创建 GameObject + Mask 组件
// cc.LayerColor() → 创建 GameObject + Image(color fill)
```

---

## 3.5 实现优先级

```
P0（零依赖基础，最先实现）
├── CCCompat.cs       ← 所有其他文件的基础类型
└── CCAction.cs       ← 3,124 个 runAction 调用依赖

P1（高频核心，P0 完成后实现）
├── NodeHelper.cs     ← 17,283 次调用，最高单文件
├── GameUtil.cs       ← 31,237 次调用（扣除不需要的仍有 ~22,000）
├── SlotUtil.cs       ← 10,199 次调用
└── NameBinder.cs     ← 24,000 次 .controller._ 依赖

P2（中频辅助，P1 完成后实现）
├── ActivityUtil.cs   ← 5,275 次调用
├── UIHelper.cs       ← 中频
├── EventDispatcher.cs ← 事件系统
└── AudioBridge.cs    ← 音效系统

P3（低频/可延后）
├── DialogBridge.cs
├── SlotPopupUtil.cs
├── WinEffectHelper.cs
└── HighRollerSlotUtil.cs
```

---

[下一章：04 - L2 Slot 框架层详细设计](04-L2-slot-framework.md)
