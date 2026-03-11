# 06 - L4 关卡业务逻辑迁移规范

[返回目录](00-index.md) | [上一章](05-L3-slot-adaptation.md)

---

## 6.1 机械翻译规则集

在 L1/L2/L3 就绪后，L4 关卡逻辑的转换应该遵循以下逐行翻译规则。

### 6.1.1 类声明与继承

```javascript
// JS
var WildsStarburstMachineScene287 = function() { ... };
game.util.inherits(WildsStarburstMachineScene287, SlotMachineScene2022);
```
```csharp
// C#
public class WildsStarburstMachine : SlotMachineBase
{
    // ...
}
```

### 6.1.2 属性访问

```javascript
// JS — CCB 绑定属性
this.node.controller._btnSpin
this.node.controller._labelWin
someNode.controller._nodeEffect
```
```csharp
// C# — NameBinder 自动绑定
[AutoBind] private Transform _btnSpin;
[AutoBind] private TMP_Text _labelWin;
// 或手动查找
NameBinder.Find(someNode, "nodeEffect")
```

### 6.1.3 节点操作

```javascript
// JS
game.nodeHelper.setNodeVisible(this._nodeWin, true);
game.nodeHelper.setNodeText(this._labelCount, "5");
game.nodeHelper.setSpriteFrameName(this._icon, "wild_star_1");
game.nodeHelper.setNodeScale(this._node, 1.5);
game.nodeHelper.setNodeOpacity(this._node, 128);
```
```csharp
// C#
NodeHelper.SetVisible(_nodeWin.gameObject, true);
NodeHelper.SetText(_labelCount, "5");
NodeHelper.SetSpriteFrame(_icon, "wild_star_1");
NodeHelper.SetScale(_node, 1.5f);
NodeHelper.SetOpacity(_node, 128f);
```

### 6.1.4 动作链

```javascript
// JS
node.runAction(cc.sequence(
    cc.delayTime(0.5),
    cc.moveTo(0.3, cc.p(100, 200)).easing(cc.easeBackOut()),
    cc.scaleTo(0.2, 1.2, 1.2),
    cc.callFunc(function() {
        game.nodeHelper.setNodeVisible(self._effect, true);
    })
));
```
```csharp
// C#
CCAction.RunAction(node, CCAction.Sequence(
    CCAction.DelayTime(0.5f),
    CCAction.MoveTo(0.3f, new Vector2(100, 200)).Easing(Ease.OutBack),
    CCAction.ScaleTo(0.2f, 1.2f, 1.2f),
    CCAction.CallFunc(() => {
        NodeHelper.SetVisible(_effect.gameObject, true);
    })
));
```

### 6.1.5 动画播放

```javascript
// JS
game.slotUtil.playAnim(this._nodeAnim, "appear", function() {
    game.slotUtil.playAnim(self._nodeAnim, "idle");
});

game.util.playAnim(this._ccbNode, "show", this, function() {
    // 回调
});
```
```csharp
// C#
SlotUtil.PlayAnim(_nodeAnim.gameObject, "appear", () => {
    SlotUtil.PlayAnim(_nodeAnim.gameObject, "idle");
});

GameUtil.PlayAnim(_ccbNode, "show", () => {
    // 回调
});
```

### 6.1.6 延迟调用

```javascript
// JS
game.slotUtil.delayCall(1.5, function() {
    self.showResult();
}, "showResult");

game.slotUtil.cancelDelayCallByName("showResult");
```
```csharp
// C#
SlotUtil.DelayCall(1.5f, () => {
    ShowResult();
}, "showResult");

SlotUtil.CancelDelay("showResult");
```

### 6.1.7 Flow 流控制

```javascript
// JS
var flow = game.slotUtil.createFlow(function(callNext) {
    // 步骤 1
    self.step1(callNext);
});
flow.addStep(function(callNext) {
    // 步骤 2
    self.step2(callNext);
});
flow.start(function() {
    // 全部完成
    callback();
});
```
```csharp
// C#
var flow = SlotUtil.CreateFlow((callNext) => {
    Step1(callNext);
});
flow.AddStep((callNext) => {
    Step2(callNext);
});
flow.Start(() => {
    callback();
});
```

### 6.1.8 方法覆写

```javascript
// JS
WildsStarburstMachineScene287.prototype.handleSpinResult = function() {
    this._super();
    this.parseWildData();
};
```
```csharp
// C#
protected override void HandleSpinResult()
{
    base.HandleSpinResult();
    ParseWildData();
}
```

### 6.1.9 组件访问

```javascript
// JS
var spinPanel = this.getComponent(CT.SPIN_PANEL);
var symAnim = this.getComponent(CT.SYMBOL_ANIM);
spinPanel.xxx();
```
```csharp
// C#
var spinPanel = GetComponent<SpinPanelComponent>();
var symAnim = GetComponent<SymbolAnimComponent>();
spinPanel.Xxx();
```

### 6.1.10 条件与类型检查

```javascript
// JS
if (cc.sys.isObjectValid(node)) { ... }
if (cc.isFunction(callback)) { callback(); }
if (cc.isUndefined(value)) { value = defaultValue; }
```
```csharp
// C#
if (CC.IsValid(node)) { ... }
if (callback != null) { callback(); }
if (value == null) { value = defaultValue; }
// 注：大多数 cc.isFunction/cc.isUndefined 在 C# 中直接用 null 检查
```

### 6.1.11 几何与颜色

```javascript
// JS
var pos = cc.p(100, 200);
var newPos = cc.pAdd(pos, cc.p(10, 20));
var color = cc.color(255, 0, 0, 128);
```
```csharp
// C#
var pos = new Vector2(100, 200);  // 或 CC.P(100, 200)
var newPos = pos + new Vector2(10, 20);  // 或 CC.PAdd(pos, CC.P(10, 20))
var color = new Color(1f, 0f, 0f, 0.5f);  // 或 CC.Color(255, 0, 0, 128)
```

### 6.1.12 遍历

```javascript
// JS
cc.each(this.winLines, function(line) { ... });
for (var i = 0; i < arr.length; i++) { ... }
game.slotUtil.traverseCell(colCount, rowCount, function(col, row) { ... });
```
```csharp
// C#
foreach (var line in winLines) { ... }
for (int i = 0; i < arr.Count; i++) { ... }
SlotUtil.TraverseCell(colCount, rowCount, (col, row) => { ... });
```

---

## 6.2 Game 287 (Wilds Starburst) 完整转换示例

### 文件对应关系

| JS 源文件 | C# 目标文件 | 归属层 |
|-----------|------------|--------|
| `WildsStarburstMachineScene287.js` (911行) | `WildsStarburstMachine.cs` | L4 |
| `WildsStarburstMachineConfig287.js` (326行) | `WildsStarburstConfig.cs` | L4 |
| `287_components/WildsStarburst_SymbolAnim.js` | `WS_SymbolAnimComponent.cs` | L3+L4 |
| `287_components/WildsStarburst_DrumMode.js` | `WS_DrumModeComponent.cs` | L3+L4 |
| `287_components/WildsStarburst_ColumnStopAnim.js` | `WS_ColumnStopAnimComponent.cs` | L3+L4 |
| `287_components/WildsStarburst_WinLine.js` | `WS_WinLineComponent.cs` | L3+L4 |
| `287_components/WildsStarburst_LinesBlink.js` | `WS_LinesBlinkComponent.cs` | L3+L4 |
| `287_components/WildsStarburst_BonusGame.js` | `WS_BonusGameComponent.cs` | L3+L4 |
| `287_components/WildsStarburst_SymbolTransform.js` | `WS_SymbolTransformComponent.cs` | L3+L4 |
| `287_components/WildsStarburst_JackpotEffect.js` | `WS_JackpotEffectComponent.cs` | L3+L4 |
| `287_action/WildsStarburst_QianyaoAction.js` | `WS_QianyaoAction.cs` | L4 |
| `287_action/WildsStarburst_BonusFGAction.js` | `WS_BonusFGAction.cs` | L4 |
| `287_action/WildsStarburst_SparklePotAction.js` | `WS_SparklePotAction.cs` | L4 |
| `287_process/WildStarburst_ColumnStopAnimProcess.js` | `WS_ColumnStopAnimProcess.cs` | L3+L4 |
| `287_process/WildStarburst_PanelWinUpdateProcess.js` | `WS_PanelWinUpdateProcess.cs` | L3+L4 |
| `287_controller/WildsStarburst_ReelJackpotController.js` | `WS_ReelJackpotController.cs` | L4 |

### 目录结构

```
Assets/Project/AddressableRes/Slots/slot_287_wilds_starburst/
├── WildsStarburstMachine.cs          # 主场景类
├── WildsStarburstConfig.cs           # 配置类
├── Components/
│   ├── WS_SymbolAnimComponent.cs
│   ├── WS_DrumModeComponent.cs
│   ├── WS_ColumnStopAnimComponent.cs
│   ├── WS_WinLineComponent.cs
│   ├── WS_LinesBlinkComponent.cs
│   ├── WS_BonusGameComponent.cs
│   ├── WS_SymbolTransformComponent.cs
│   └── WS_JackpotEffectComponent.cs
├── Actions/
│   ├── WS_QianyaoAction.cs
│   ├── WS_BonusFGAction.cs
│   └── WS_SparklePotAction.cs
├── Processes/
│   ├── WS_ColumnStopAnimProcess.cs
│   └── WS_PanelWinUpdateProcess.cs
└── Controllers/
    └── WS_ReelJackpotController.cs
```

### 287 特有业务逻辑要点

| 特性 | 说明 |
|------|------|
| **3×3 网格** | 3 列 × 3 行 |
| **Wild 系统** | 3 色组 × 3 星级 = 9 个 Wild 符号 ID |
| **FreeSpin 换列** | FreeSpin 模式下 col0 ↔ col1 数据+视觉互换 |
| **SparklePot** | 星级累计达阈值触发 Jackpot（level ≥ 4） |
| **Line Jackpot** | triggerLineJackpotLevelList 配置的线 Jackpot |
| **Respin** | 锁定 col0 重转 |
| **星数阈值** | [5, 6, 7, 8, 9, 11, 13, 15] → Jackpot 等级 0-7 |
| **出现预计算** | processWDAppear/processStarsAppear/processScatterAppear → shouldR3Drum 位掩码 |

---

## 6.3 关卡转换检查清单

每转换一个关卡，需确认以下事项：

- [ ] 所有 JS 文件已读取并理解
- [ ] C# 文件数量与 JS 文件数量一致
- [ ] 主场景类正确继承 `SlotMachineBase`
- [ ] `AppendExtraConfig()` 覆写完整
- [ ] `GetSceneComponentConfig()` 注册了所有自定义组件
- [ ] `GetSpinPanelComponentsConfig()` 注册了面板级自定义组件
- [ ] `HandleSpinResult()` 正确解析自定义数据
- [ ] 所有生命周期钩子（OnRoundStart, OnSubRoundStart 等）已覆写
- [ ] FreeSpin 相关钩子已覆写（如有）
- [ ] 所有自定义 Component 正确继承 L2 基类组件
- [ ] 所有自定义 Action 正确实现 TriggerFilter + OnTrigger
- [ ] 所有自定义 Process 正确实现 OnEnter + AdvanceToNext
- [ ] 无 TODO 占位符
- [ ] 无 Debug.Log 占位符（除非是有意保留的日志）
- [ ] 所有使用的 L1 API 在映射表中标记为 `已实现`

---

[下一章：07 - 执行规范](07-execution-standards.md)
