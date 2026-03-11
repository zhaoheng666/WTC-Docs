# 05 - L3 Slot 框架适配层详细设计

[返回目录](00-index.md) | [上一章](04-L2-slot-framework.md)

---

## 5.1 设计原则

1. **模式提取**：分析 95 个关卡的覆写模式，归纳为有限的几类标准化扩展方式
2. **扩展点预留**：L2 基类的 `virtual` 方法必须覆盖所有已知的覆写需求
3. **适配器模式**：对于复杂的覆写模式（如多面板、特殊 Reel 布局），提供中间适配器类
4. **L3 代码位置**：适配代码与关卡代码放在同一目录（`Slots/slot_{id}_{name}/`），因为适配是关卡特有的

---

## 5.2 覆写模式分类

经分析 11 个模块化关卡（284-297）+ 84 个单文件关卡的覆写行为，归纳为以下 4 大类：

### 类型 A：配置覆写

**覆写方法**：`appendExtraConfig()`, `getSceneComponentConfig()`, `getSpinPanelComponentsConfig()`

**特征**：调用 `_super()` 获取基类配置，然后修改或追加。

**频率**：100% 的关卡都有配置覆写。

#### JS 模式

```javascript
appendExtraConfig: function() {
    this._super();
    this.machineConfig.freeSpinCCBPath = "xxx";
    this.machineConfig.bonusCCBPath = "yyy";
    this.machineConfig.customData = { ... };
}

getSceneComponentConfig: function() {
    var config = this._super();
    // 替换组件
    config[CT.SYMBOL_ANIM] = { creator: MySymbolAnim, args: {} };
    // 添加组件
    config[CT.BONUS_GAME] = { creator: MyBonusGame, args: {} };
    return config;
}
```

#### C# 适配

```csharp
public class WildsStarburstMachine : SlotMachineBase
{
    protected override void AppendExtraConfig()
    {
        base.AppendExtraConfig();
        Config.FreeSpinCCBPath = "xxx";
        Config.Set("bonusCCBPath", "yyy");
        Config.Set("customData", new WildsStarburstData());
    }
    
    protected override Dictionary<Type, ComponentConfig> GetSceneComponentConfig()
    {
        var config = base.GetSceneComponentConfig();
        config[typeof(SymbolAnimComponent)] = ComponentConfig.Create<WS_SymbolAnimComponent>();
        config[typeof(WS_BonusGameComponent)] = ComponentConfig.Create<WS_BonusGameComponent>();
        return config;
    }
}
```

#### 统计

| 配置项 | 使用关卡数（估）| 说明 |
|--------|---------------|------|
| `freeSpinCCBPath` | ~60 | FreeSpin 弹窗 Prefab 路径 |
| `bonusCCBPath` | ~30 | Bonus 弹窗路径 |
| `jackpotCCBPath` | ~20 | Jackpot 展示路径 |
| `symbolControllers` | ~40 | 特殊符号控制器映射 |
| `simulateRandomSymbol` | ~60 | 模拟旋转随机符号配置 |
| 自定义数据 | 各不相同 | 关卡特有业务数据 |

---

### 类型 B：流程树覆写

**覆写方法**：`getProcesses()`, `getPanelColumnSpinProcessConstructors()`

**特征**：大多数关卡不覆写流程树（使用默认的 2022/2025 版本），少数关卡会插入/替换特定流程。

**频率**：~15% 的关卡有流程树覆写。

#### JS 模式

```javascript
// 模式 B1：完全替换流程树（极少）
getProcesses: function() {
    return [
        new EnterRoomCheckingProcess(this),
        ["loop",
            new WaitForSpinProcess(this),
            // ... 自定义流程树
        ]
    ];
}

// 模式 B2：替换列旋转流程构造器（较常见）
getPanelColumnSpinProcessConstructors: function(panelId, columnIndex) {
    var arr = this._super(panelId, columnIndex);
    // 在减速前插入自定义流程
    arr.splice(3, 0, function() { return new MyCustomProcess(self); });
    return arr;
}
```

#### C# 适配

```csharp
// 模式 B1：覆写流程树
protected override object GetProcessTree()
{
    return new object[] {
        new EnterRoomCheckingProcess(this),
        new object[] { "loop",
            new WaitForSpinProcess(this),
            // ... 自定义
        }
    };
}

// 模式 B2：覆写列旋转流程
protected override List<Func<SlotProcessBase>> GetColumnSpinProcesses(int panelId, int col)
{
    var list = base.GetColumnSpinProcesses(panelId, col);
    list.Insert(3, () => new WS_ColumnStopAnimProcess(this));
    return list;
}
```

---

### 类型 C：生命周期钩子覆写

**覆写方法**：`onRoundStart`, `onSubRoundStart`, `onSubRoundEnd`, `onRoundEnd`, `handleSpinResult`, `onFreeSpinBegin`, `onFreeSpinEnd` 等

**特征**：调用 `_super()` 然后执行关卡特有逻辑。

**频率**：~80% 的关卡至少覆写一个钩子。

#### 常见覆写钩子统计

| 钩子 | 估计覆写关卡数 | 典型用途 |
|------|---------------|----------|
| `handleSpinResult()` | ~70 | 解析自定义旋转结果数据 |
| `onSubRoundStart()` | ~40 | 重置特效状态、更新 UI |
| `appendExtraConfig()` | ~95 | 几乎所有关卡 |
| `onFreeSpinBegin/End()` | ~50 | FreeSpin 进入/退出状态切换 |
| `onRoundEnd()` | ~30 | 结算逻辑 |
| `onEnterFreeSpin/onExitFreeSpin()` | ~50 | 背景/音乐切换 |
| `refreshFreeSpinBeginPanel()` | ~30 | 自定义 FreeSpin 弹窗内容 |
| `actionAfterBlinkScatter()` | ~15 | Scatter 闪烁后的特殊逻辑 |
| `showReelEffectForAppear()` | ~20 | 特殊符号出现效果 |
| `onSpinResultReceived()` | ~15 | 提前处理旋转结果 |

#### C# 适配

```csharp
// 标准模式：base 调用 + 关卡逻辑
protected override void HandleSpinResult()
{
    base.HandleSpinResult();
    ParseWildStarburstData();
    ProcessStarsAppear();
}

public override void OnSubRoundStart()
{
    base.OnSubRoundStart();
    if (IsFreeSpin) SwapColumns();
    ResetEffects();
}
```

---

### 类型 D：组件替换与扩展

**覆写方法**：`getSceneComponentConfig()`, `getSpinPanelComponentsConfig()`

**特征**：用自定义组件类替换框架默认组件，自定义组件继承框架组件并覆写特定行为。

**频率**：~60% 的关卡有组件替换。

#### 常见替换模式

| 被替换的基础组件 | 替换频率 | 关卡自定义组件示例 |
|----------------|---------|-------------------|
| `SymbolAnimationComponent` | ~40% | 自定义符号动画逻辑 |
| `DrumModeComponent` | ~30% | 自定义停轮节奏 |
| `ColumnStopAnimationProcess` | ~25% | 自定义停轮动画 |
| `WinLineComponent` | ~20% | 自定义赢线展示 |
| `LinesBlinkComponent` | ~20% | 自定义赢线闪烁 |
| `JackpotEffectComponent` | ~15% | 自定义 Jackpot 展示 |
| `WinEffectComponent` | ~10% | 自定义大赢展示 |

#### C# 适配

```csharp
// 框架组件
public class SymbolAnimComponent : SlotComponentBase
{
    public virtual void PlaySymbolAnim(int col, int row, int symbolId) { /* 默认实现 */ }
    public virtual void StopSymbolAnim(int col, int row) { /* 默认实现 */ }
}

// 关卡自定义组件（L3 适配层 + L4 业务逻辑）
public class WS_SymbolAnimComponent : SymbolAnimComponent
{
    public override void PlaySymbolAnim(int col, int row, int symbolId)
    {
        // 287 特有：Wild 符号有 3 色 × 3 星级的差异化动画
        if (IsWildSymbol(symbolId))
        {
            var colorGroup = GetColorGroup(symbolId);
            var starLevel = GetStarLevel(symbolId);
            PlayWildAnim(col, row, colorGroup, starLevel);
        }
        else
        {
            base.PlaySymbolAnim(col, row, symbolId);
        }
    }
}
```

---

## 5.3 11 个模块化关卡差异分析

以下是 11 个使用独立子目录结构的关卡各自的覆写清单：

### 284 Santa Giftstorm (21 files)

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 8 | SymbolAnim, DrumMode, ColumnStopAnim, WinLine, LinesBlink, BonusGame, SymbolTransform, JackpotEffect |
| Actions | 3 | Qianyao, BonusFG, SparklePot |
| Processes | 2 | ColumnStopAnim, PanelWinUpdate |
| Controllers | 1 | ReelJackpot |

### 285 Carnival Blast (13 files)

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 5 | SymbolAnim, DrumMode, WinLine, LinesBlink, JackpotEffect |
| Actions | 2 | Qianyao, BonusFG |
| Processes | 1 | ColumnStopAnim |

### 286 Halo and Horns (13 files)

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 5 | SymbolAnim, DrumMode, ColumnStopAnim, BonusGame, JackpotEffect |
| Actions | 3 | Qianyao, BonusFG, CustomAction |
| Processes | 1 | ColumnStopAnim |

### 287 Wilds Starburst (16 files) — 参考关卡

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 8 | SymbolAnim, DrumMode, ColumnStopAnim, WinLine, LinesBlink, BonusGame, SymbolTransform, JackpotEffect |
| Actions | 3 | Qianyao, BonusFG, SparklePot |
| Processes | 2 | ColumnStopAnim, PanelWinUpdate |
| Controllers | 1 | ReelJackpot |

### 288 Three Little Piggies (17 files)

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 7 | SymbolAnim, DrumMode, ColumnStopAnim, WinLine, LinesBlink, BonusGame, JackpotEffect |
| Actions | 3 | Qianyao, BonusFG, Custom |
| Processes | 2 | ColumnStopAnim, Custom |

### 289 Yay Yeti Glitzy (19 files)

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 8 | 较全覆盖 |
| Actions | 3 | |
| Processes | 3 | 含自定义流程 |

### 290 Dazzling Diamonds (23 files) — 最大关卡

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 10 | 几乎全部替换 |
| Actions | 4 | 含多个自定义 Action |
| Processes | 3 | |
| Controllers | 2 | |

### 291 Ducky Dollars (19 files)

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 8 | |
| Actions | 3 | |
| Processes | 2 | |

### 292 Rose Romance (9 files) — 最小关卡

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 4 | 最少的自定义 |
| Actions | 2 | |
| Processes | 1 | |

### 293 Trio Wheels Deluxe (16 files)

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 6 | |
| Actions | 3 | |
| Processes | 2 | |

### 297 Goldpot Party (18 files)

| 自定义文件类型 | 数量 | 覆写内容 |
|---------------|------|----------|
| Components | 7 | |
| Actions | 3 | |
| Processes | 2 | |

---

## 5.4 覆写频率热力图

以下是各基础组件/流程被关卡自定义覆写的频率（基于 11 个模块化关卡）：

```
组件被覆写频率：
  SymbolAnimComponent      ████████████  11/11 (100%)
  DrumModeComponent        ████████████  11/11 (100%)
  WinLineComponent         ██████████    9/11
  LinesBlinkComponent      ██████████    9/11
  ColumnStopAnimProcess    ████████████  11/11 (100%)
  JackpotEffectComponent   ██████████    9/11
  BonusGameComponent       ████████      8/11
  SymbolTransformComponent ████          4/11
  PanelWinUpdateProcess    ████          4/11
  WinEffectComponent       ██            2/11
```

**结论**：SymbolAnim、DrumMode、ColumnStopAnim 是**必覆写**组件，L2 必须提供完善的扩展点。

---

## 5.5 L3 适配器类清单

基于覆写频率分析，L3 需要提供以下适配器基类（位于各关卡目录下）：

| 适配器 | 继承自 (L2) | 用途 | 提供的扩展点 |
|--------|------------|------|-------------|
| 关卡 SymbolAnim | `SymbolAnimComponent` | 自定义符号动画 | `PlaySymbolAnim`, `StopSymbolAnim`, `GetAnimKey` |
| 关卡 DrumMode | `DrumModeComponent` | 自定义停轮节奏 | `CalculateDrumConfig`, `ShouldDrum` |
| 关卡 ColumnStopAnim | `ColumnStopAnimationProcess` | 自定义停轮动画 | `OnColumnStop`, `PlayStopAnim` |
| 关卡 WinLine | `WinLineComponent` | 自定义赢线显示 | `ShowWinLine`, `HideWinLines` |
| 关卡 LinesBlink | `LinesBlinkComponent` | 自定义闪烁 | `BlinkLine`, `BlinkAllLines` |
| 关卡 JackpotEffect | `JackpotEffectComponent` | 自定义 Jackpot 展示 | `ShowJackpotHit`, `GetJackpotNode` |
| 关卡 BonusGame | `ScatterGameComponent` | 自定义 Bonus 游戏 | `OnBonusTrigger`, `PlayBonusGame` |

---

[下一章：06 - L4 关卡业务逻辑迁移规范](06-L4-game-migration.md)
