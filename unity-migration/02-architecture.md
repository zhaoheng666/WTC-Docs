# 02 - 4 层架构设计方案

[返回目录](00-index.md) | [上一章](01-overview.md)

---

## 2.1 架构总览

```
┌─────────────────────────────────────────────────────────────────┐
│  L4  关卡业务逻辑层                                              │
│  每个具体游戏（287、288…）的特有逻辑                                │
│  策略：近乎机械翻译                                               │
│  位置：Assets/Project/AddressableRes/Slots/slot_{id}_{name}/    │
├─────────────────────────────────────────────────────────────────┤
│  L3  Slot 框架适配层                                             │
│  识别提取不同关卡对框架层的覆写、继承，做相应适配                       │
│  策略：提取差异模式，提供扩展点                                      │
│  位置：Assets/Project/AddressableRes/Slots/slot_{id}_{name}/    │
├─────────────────────────────────────────────────────────────────┤
│  L2  Slot 框架层                                                │
│  CPA 架构基类、FlowDispatcher、Reel 系统、20 组件基类              │
│  策略：范式转换，用 Unity 成熟技术合理重构（非 1:1）                   │
│  位置：Assets/Project/AddressableRes/Scripts/framework/slot/compat2022/ │
├─────────────────────────────────────────────────────────────────┤
│  L1  Cocos 兼容层                                               │
│  ~400 个 JS API → Unity C# 静态方法 1:1 接口映射                  │
│  策略：接口名一致，内部用 Unity 原生 API 实现                        │
│  位置：Assets/Project/AddressableRes/Scripts/framework/slot/compat2022/ │
└─────────────────────────────────────────────────────────────────┘
         ↕ Unity 6 引擎层（DOTween、Addressables、UGUI/UIToolkit）
```

### 核心设计思想

**L1 + L2 与关卡业务逻辑完全解耦，可以先独立完成并验证。**

- **L1 向下适配**：把 Cocos 的 API 语义「翻译」为 Unity 原生调用，对上层屏蔽引擎差异
- **L2 向上抽象**：把 CPA 架构模式「重构」为 Unity 风格的基类体系，对上层提供稳定接口
- **L3 桥接差异**：把各关卡对框架的覆写模式分类归纳，提供标准化的扩展点
- **L4 机械翻译**：在 L1/L2/L3 就绪后，单关卡转换可以逐行翻译

---

## 2.2 L1 Cocos 兼容层

### 定位

提供一组 **C# 静态类**，将 Cocos2d-x JavaScript API **1:1 映射**为 Unity 调用。接口名称与 JS 版本保持一致，内部实现使用 Unity 原生 API。

### 边界

| 属于 L1 | 不属于 L1 |
|---------|----------|
| `cc.p()` → `new Vector2()` | Reel 卷轴系统 |
| `cc.sequence()` → DOTween Sequence | FlowDispatcher 流程引擎 |
| `game.nodeHelper.setNodeVisible()` → `go.SetActive()` | Component 基类设计 |
| `game.util.loadNodeFromCCB()` → `Instantiate(prefab)` | 关卡特有逻辑 |
| `game.slotUtil.playAnim()` → Animator/Timeline 播放 | |
| `game.slotUtil.createFlow()` → 异步流控制 | |
| `.controller._propName` → NameBinder 自动绑定 | |

### 设计原则

1. **接口一致性**：C# 方法名与 JS 方法名保持一致（仅命名风格从 camelCase 转为 PascalCase）
2. **无业务逻辑**：L1 只做 API 翻译，不包含任何 Slot 业务逻辑
3. **零状态**：所有方法为静态方法或无状态的扩展方法
4. **Unity 原生**：内部实现必须使用 Unity 成熟的原生 API，不做二次封装

### 文件清单

| C# 文件 | 映射源 | 方法数 | 调用次数 |
|---------|--------|--------|----------|
| `CCCompat.cs` | `cc.p/cc.color/cc.size/cc.rect/cc.sys/cc.is*/cc.each/cc.log` | ~45 | ~25,000+ |
| `CCAction.cs` | `cc.sequence/moveTo/callFunc/delayTime/...` + 17 easing → DOTween | 44 | ~9,256 |
| `NodeHelper.cs` | `game.nodeHelper.*` | 23 | ~17,283 |
| `GameUtil.cs` | `game.util.*` | 72 | ~31,237 |
| `SlotUtil.cs` | `game.slotUtil.*` | 62 | ~10,199 |
| `ActivityUtil.cs` | `game.aUtil.*` | 74 | ~5,275 |
| `NameBinder.cs` | `.controller._` 自动绑定 | — | ~24,000 |
| `UIHelper.cs` | `game.uIHelper.*` | 34 | 待统计 |
| `EventDispatcher.cs` | `game.eventDispatcher.*` | 3+ | ~167 |
| `AudioBridge.cs` | `game.audioPlayer.*` + `game.slotUtil.playEffect/stopEffect` | 15+ | 待统计 |
| `DialogBridge.cs` | `game.dialogManager.*` | 10+ | 待统计 |
| `SlotPopupUtil.cs` | `game.slotPopupUtil.*` | 4 | 待统计 |
| `WinEffectHelper.cs` | `game.winEffectHelper.*` | 10 | 待统计 |

### 不需要映射的项（C# 天然解决）

| JS 模式 | 调用次数 | C# 处理方式 |
|---------|----------|------------|
| `game.util.inherits(Sub, Super)` | 4,170 | C# `class Sub : Super` |
| `cc.Class.extend({...})` | 242 | C# `class` 继承 |
| `cc.each(arr, func)` | 845 | C# `foreach` |
| `cc.log/error/warn` | 4,135 | `Debug.Log/Error/LogWarning` |
| `game.util.registerController` | 2,561 | NameBinder 替代 |
| `game.util.unRegisterController` | 2,547 | NameBinder 替代 |

---

## 2.3 L2 Slot 框架层

### 定位

将 Cocos 源码的 **CPA 架构** 用 Unity 成熟技术进行 **范式转换**，建立 Slot 游戏的核心运行框架。

**不追求 1:1 转换**，而是理解源码的设计意图后，用 Unity/C# 最佳实践重新实现。

### 边界

| 属于 L2 | 不属于 L2 |
|---------|----------|
| `SlotMachineBase` 基类 | 具体关卡的 `appendExtraConfig()` 实现 |
| `SlotComponentBase` 组件生命周期 | 具体关卡的自定义组件 |
| `SlotProcessBase` 流程生命周期 | 具体关卡的自定义流程 |
| `SlotActionBase` 动作触发模式 | 具体关卡的自定义动作 |
| `FlowDispatcher` 流程引擎 | 具体关卡的流程树覆写 |
| Reel 卷轴旋转系统 | 具体关卡的特殊停轮逻辑 |
| 20 个 component_new2022 基类 | 关卡对基类的覆写 |
| SpinResult 数据模型 | 服务端协议解析 |

### 设计原则

1. **范式转换**：利用 C# 语言特性（接口、泛型、事件）和 Unity 特性（MonoBehaviour、ScriptableObject）合理重构
2. **生命周期对齐**：CPA 三大基类的生命周期（构造→初始化→运行→退出）在 C# 中有明确对应
3. **扩展点清晰**：所有关卡需要覆写的方法标记为 `virtual`/`abstract`，有明确文档
4. **Reel 从零建**：卷轴系统不依赖第三方，完全根据源码的列旋转/减速/停止流程自建

### 核心类设计

```csharp
// 框架基类层次
SlotMachineBase : MonoBehaviour          // ← SlotMachineScene + SlotMachineScene2022
├── SlotComponentBase                    // ← Component.js
├── SlotProcessBase                      // ← Process.js
│   └── ConditionProcess                 // ← 循环退出控制
├── SlotActionBase                       // ← SlotActon.js / SlotActionEasy.js
│   └── QianyaoActionBase               // ← QianyaoAction.js
├── FlowDispatcher                       // ← FlowDispatcher.js
│   ├── FlowNode                        // ← 单流程节点
│   ├── FlowSequence                    // ← 顺序序列
│   └── FlowLoop                        // ← 循环序列
├── SlotActionRegistry (SA/SAT)          // ← SlotActionRegistry.js
├── SpinResult                           // ← 旋转结果数据模型
├── MachineConfig                        // ← 关卡配置数据模型
└── ReelSystem                           // ← 卷轴旋转系统（从零构建）
    ├── ReelStrip                        // ← 单列卷轴
    ├── ReelSpinController               // ← 旋转控制（启动/匀速/减速/停止）
    └── SymbolPool                       // ← 符号对象池
```

### L2 需要实现的 20 个基础组件

| # | JS 源文件 | C# 类名 | 职责 |
|---|-----------|---------|------|
| 1 | `SpinPanelComponent.js` | `SpinPanelComponent` | 卷轴面板管理 |
| 2 | `ClassicSpinPanelComponent.js` | `ClassicSpinPanelComponent` | 经典卷轴面板 |
| 3 | `CellSpinPanelComponent.js` | `CellSpinPanelComponent` | 单元格卷轴面板 |
| 4 | `SymbolLayerComponent.js` | `SymbolLayerComponent` | 符号层管理 |
| 5 | `ClassicSymbolLayerComponent.js` | `ClassicSymbolLayerComponent` | 经典符号层 |
| 6 | `CellSymbolLayerComponent.js` | `CellSymbolLayerComponent` | 单元格符号层 |
| 7 | `DrumModeComponent.js` | `DrumModeComponent` | 鼓点模式控制 |
| 8 | `SlotMachineMainUIComponent.js` | `MainUIComponent` | 主界面 |
| 9 | `SpinUIComponent.js` | `SpinUIComponent` | 旋转按钮面板 |
| 10 | `WinLineComponent.js` | `WinLineComponent` | 赢线显示 |
| 11 | `LinesBlinkComponent.js` | `LinesBlinkComponent` | 赢线闪烁 |
| 12 | `BlinkWinManComponent.js` | `BlinkWinManComponent` | 赢分闪烁管理 |
| 13 | `SymbolAnimationComponent.js` | `SymbolAnimComponent` | 符号动画 |
| 14 | `WinEffectComponent.js` | `WinEffectComponent` | 赢分特效 |
| 15 | `JackpotEffectComponent.js` | `JackpotEffectComponent` | 奖池特效 |
| 16 | `FreeSpinBeginComponent.js` | `FreeSpinBeginComponent` | 免费旋转开始 |
| 17 | `FreeSpinEndComponent.js` | `FreeSpinEndComponent` | 免费旋转结束 |
| 18 | `ScatterGameComponent.js` | `ScatterGameComponent` | Scatter 游戏 |
| 19 | `EnterRoomBonusCheckingComponent.js` | `EnterRoomBonusComponent` | 入房 Bonus 检查 |
| 20 | `FastSpinComponent.js` | `FastSpinComponent` | 快速旋转 |

---

## 2.4 L3 Slot 框架适配层

### 定位

识别并提取 **各关卡对 L2 框架层的覆写和继承差异**，将这些差异模式归类，在 L2 基类中预留扩展点，在 L3 中提供标准化的适配实现。

### 边界

| 属于 L3 | 不属于 L3 |
|---------|----------|
| 关卡对 `getSceneComponentConfig()` 的覆写模板 | 框架基类本身 |
| 关卡对 `getProcesses()` 的流程树变体 | 通用流程引擎 |
| 关卡对生命周期钩子的通用覆写模式 | 关卡特有的业务逻辑 |
| 组件替换/扩展的标准化适配器 | |

### 设计原则

1. **模式提取**：分析 95 个关卡的覆写模式，归纳为有限的几类标准模式
2. **扩展点预留**：确保 L2 基类的 `virtual` 方法覆盖了所有已知的覆写需求
3. **适配器模式**：对于复杂的覆写模式，提供中间适配器类

### 覆写模式分类

经分析，关卡对框架的覆写可归纳为以下 4 大类：

#### 类型 A：配置覆写

```javascript
// JS 模式：覆写配置方法
appendExtraConfig: function() {
    this._super();
    this.machineConfig.xxx = yyy;
}

getSceneComponentConfig: function() {
    var config = this._super();
    config[CT.SYMBOL_ANIM] = { creator: MyCustomSymbolAnim, args: {} };
    return config;
}
```

**C# 适配策略**：`override` + `base.Method()` 调用链

#### 类型 B：流程树覆写

```javascript
// JS 模式：修改流程树
getProcesses: function() {
    return [
        new EnterRoomCheckingProcess(this),
        ["loop",
            new WaitForSpinProcess(this),
            // ... 插入自定义流程或替换默认流程
            new MyCustomProcess(this),
        ]
    ];
}
```

**C# 适配策略**：提供 `BuildProcessTree()` 虚方法 + 插入点枚举

#### 类型 C：生命周期钩子覆写

```javascript
// JS 模式：覆写回调钩子
onSubRoundStart: function() {
    this._super();
    // 关卡特有逻辑
    this.swapColumns();
}

handleSpinResult: function() {
    this._super();
    // 解析自定义数据
    this.parseExtraData();
}
```

**C# 适配策略**：`virtual` 方法 + `base.Method()` 调用

#### 类型 D：组件替换与扩展

```javascript
// JS 模式：替换基类组件为自定义版本
getSpinPanelComponentsConfig: function(panelId) {
    var config = this._super(panelId);
    config[CT.COLUMN_STOP_ANIM] = {
        creator: WildsStarburst_ColumnStopAnim,
        args: {}
    };
    return config;
}
```

**C# 适配策略**：组件注册表 + 工厂模式，允许按类型替换

---

## 2.5 L4 关卡业务逻辑层

### 定位

每个具体关卡的 **特有业务逻辑**。在 L1/L2/L3 就绪后，这一层的转换应该是 **近乎机械化的逐行翻译**。

### 边界

| 属于 L4 | 不属于 L4 |
|---------|----------|
| 关卡特有的组件实现 | 组件基类 |
| 关卡特有的动作实现 | 动作基类 |
| 关卡特有的流程实现 | 流程基类 |
| 关卡配置文件 (MachineConfig) | 配置基类 |
| 关卡主场景类 (MachineScene) | SlotMachineBase |

### 设计原则

1. **机械翻译**：依赖 L1 的 API 映射，JS 代码逐行翻译为 C#
2. **结构保持**：JS 文件结构 → C# 文件结构保持 1:1 对应
3. **命名保持**：关卡特有的变量名、方法名保持语义一致

### 关卡文件对应关系（以 287 为例）

| JS 文件 | C# 文件 | 类型 |
|---------|---------|------|
| `WildsStarburstMachineScene287.js` | `WildsStarburstMachine.cs` | 主场景 (L4) |
| `WildsStarburstMachineConfig287.js` | `WildsStarburstConfig.cs` | 配置 (L4) |
| `287_components/WildsStarburst_ColumnStopAnim.js` | `WS_ColumnStopAnimComponent.cs` | 组件 (L3+L4) |
| `287_components/WildsStarburst_DrumMode.js` | `WS_DrumModeComponent.cs` | 组件 (L3+L4) |
| `287_components/WildsStarburst_SymbolAnim.js` | `WS_SymbolAnimComponent.cs` | 组件 (L3+L4) |
| `287_action/WildsStarburst_QianyaoAction.js` | `WS_QianyaoAction.cs` | 动作 (L4) |
| `287_action/WildsStarburst_BonusFGAction.js` | `WS_BonusFGAction.cs` | 动作 (L4) |
| `287_process/WildStarburst_ColumnStopAnimProcess.js` | `WS_ColumnStopAnimProcess.cs` | 流程 (L3+L4) |

---

## 2.6 层间依赖关系与解耦原则

### 依赖方向

```
L4 ──依赖──→ L3 ──依赖──→ L2 ──依赖──→ L1 ──依赖──→ Unity 引擎 + DOTween
                                                        ↑
                                                  无反向依赖
```

### 解耦规则

| 规则 | 说明 |
|------|------|
| **L1 不依赖 L2** | 兼容层是纯 API 翻译，不知道 Slot 业务 |
| **L2 可依赖 L1** | 框架层可调用兼容层的工具方法 |
| **L3 不被 L2 依赖** | 框架层不知道有哪些具体的适配器 |
| **L4 不被 L1/L2/L3 依赖** | 关卡逻辑是叶子节点，无反向依赖 |
| **L2 和 L4 之间通过 L3 桥接** | L4 不直接继承 L2 基类，而是通过 L3 的适配器扩展 |

### 实施顺序约束

```
Phase 1: L1 Cocos 兼容层
    ↓ （L1 完成并单元测试通过）
Phase 2: L2 Slot 框架层
    ↓ （L2 完成并集成测试通过）
Phase 3: L3 适配层 + L4 试点关卡（287 + 第二个关卡）
    ↓ （双关卡验证通过）
Phase 4: L4 批量转换（剩余 93 个关卡）
```

### Unity 目录结构

```
Assets/Project/AddressableRes/
├── Scripts/
│   └── framework/
│       └── slot/
│           ├── 2026/                              # 未来新的 Unity 原生框架
│           ├── compat/                            # cocos 项目 Slot 老框架的兼容框架
│           └── compat2022/                        # cocos 项目 Slot 新框架的兼容框架
│               ├── Components/                    # WTC.Slot.Compat2022.Components — 具体机台组件
│               │   ├── SpinPanelComponent.cs
│               │   ├── SymbolLayerComponent.cs
│               │   ├── WinEffectComponent.cs
│               │   └── ... (20 个基础组件)
│               ├── Controllers/                   # WTC.Slot.Compat2022.Controller — UI 控制器
│               ├── Core/
│               │   ├── SlotMachineBase.cs          # WTC.Slot.Compat2022.Core — 机台基类
│               │   ├── EventDispatcher.cs          # WTC.Slot.Compat2022.Core — 事件分发器
│               │   ├── Bridge/                     # WTC.Slot.Compat2022.Core.Bridge — 引擎桥接
│               │   │   ├── CCCompat.cs
│               │   │   ├── CCAction.cs
│               │   │   ├── AudioBridge.cs
│               │   │   └── DialogBridge.cs
│               │   ├── Component/                  # WTC.Slot.Compat2022.Core.Component — 组件基类
│               │   │   └── SlotComponentBase.cs
│               │   ├── Config/                     # WTC.Slot.Compat2022.Core.Config — 配置定义
│               │   │   └── MachineConfig.cs
│               │   ├── Contrller/                  # WTC.Slot.Compat2022.Core.Controller — 控制器基础
│               │   │   └── NameBinder.cs
│               │   ├── Data/                       # WTC.Slot.Compat2022.Core.Data — 数据解析
│               │   │   └── SpinResult.cs
│               │   ├── Enums/                      # WTC.Slot.Compat2022.Core.Enums — 枚举常量
│               │   │   ├── ComponentType.cs
│               │   │   ├── ProcessBlockerType.cs
│               │   │   ├── SlotEvents.cs
│               │   │   └── SymbolAnimationType.cs
│               │   ├── Processe/                   # WTC.Slot.Compat2022.Core.Process — 流程基础层
│               │   │   ├── ConditionProcess.cs
│               │   │   ├── FlowDispatcher.cs
│               │   │   ├── IFlowController.cs
│               │   │   └── SlotProcessBase.cs
│               │   ├── Reel/                       # WTC.Slot.Compat2022.Core.Reel — 卷轴系统
│               │   │   ├── ReelStrip.cs
│               │   │   ├── ReelSpinController.cs
│               │   │   ├── ReelSystem.cs
│               │   │   └── SymbolPool.cs
│               │   ├── SlotAction/                 # WTC.Slot.Compat2022.Core.SlotAction — 动作基类
│               │   │   ├── SlotActionBase.cs
│               │   │   ├── SlotActionRegistry.cs
│               │   │   ├── QianyaoActionBase.cs
│               │   │   └── ...
│               │   └── Utils/                      # WTC.Slot.Compat2022.Core.Utils — 工具集
│               │       ├── NodeHelper.cs
│               │       ├── GameUtil.cs
│               │       ├── SlotUtil.cs
│               │       └── ...
│               ├── Processes/                      # WTC.Slot.Compat2022.Processes — 具体机台流程
│               │   ├── WaitForSpinProcess.cs
│               │   ├── SpinProcess.cs
│               │   ├── RoundEndProcess.cs
│               │   └── ... (31 个基础流程)
│               └── SlotActions/                    # WTC.Slot.Compat2022.SlotActions — 具体动作
│                   ├── FreeSpinAction.cs
│                   ├── QianyaoAction.cs
│                   └── ... (21 个基础动作)
└── Slots/
    ├── slot_287_wilds_starburst/            # L3 + L4
    │   ├── WildsStarburstMachine.cs
    │   ├── WildsStarburstConfig.cs
    │   ├── Components/
    │   │   ├── WS_ColumnStopAnimComponent.cs
    │   │   ├── WS_DrumModeComponent.cs
    │   │   └── ...
    │   ├── Actions/
    │   │   ├── WS_QianyaoAction.cs
    │   │   └── ...
    │   └── Processes/
    │       ├── WS_ColumnStopAnimProcess.cs
    │       └── ...
    ├── slot_288_three_little_piggies/
    ├── slot_289_yay_yeti_glitzy/
    └── ...
```

---

[下一章：03 - L1 Cocos 兼容层详细设计](03-L1-cocos-compat.md)
