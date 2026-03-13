# 04 - L2 Slot 框架层详细设计

[返回目录](00-index.md) | [上一章](03-L1-cocos-compat.md)

---

## 4.1 设计原则

1. **范式转换**：不是 1:1 复制 JS 代码，而是理解 CPA 的设计意图，用 Unity/C# 最佳实践重新实现
2. **生命周期对齐**：JS 的 `ctor → initializeComponent → afterInitializeComponent → onExit` 对齐到 C# 的构造/初始化/销毁流程
3. **扩展点显式化**：所有关卡需要覆写的方法标记为 `virtual`/`abstract`，使 L3/L4 的适配明确
4. **Unity 特性利用**：
   - MonoBehaviour 替代 cc.Class
   - ScriptableObject 替代 machineConfig JSON
   - C# 接口替代 JS 的鸭子类型
   - C# 事件/委托替代 JS 的回调函数传递

---

## 4.2 CPA 架构映射

### 4.2.1 Component 基类

**JS 源**：`src/newdesign_slot/component/Component.js`

#### JS 生命周期

```
ctor(context, args)
  └── initializeConfiguration()       ← Phase 1：只读配置
initializeComponent()                  ← Phase 2：创建 UI 节点
afterInitializeComponent()             ← Phase 3：跨组件引用
handleRoomEnterInfo(info)              ← 入房重连
handleSpinInfo(spinInfo)               ← 每次旋转结果
refreshComponent()                     ← 刷新
onExit()                               ← 退出清理
```

#### C# 映射

```csharp
namespace WTC.Slot.Compat2022.Core.Component
{
    public abstract class SlotComponentBase
    {
        // ── 引用 ──
        protected SlotMachineBase Machine { get; private set; }
        protected MachineConfig Config => Machine.Config;
        
        // ── 生命周期（对应 JS 三阶段初始化）──
        
        /// <summary>Phase 1: 在构造函数中调用。只读配置，不创建节点，不引用其他组件。</summary>
        public virtual void InitConfig() { }
        
        /// <summary>Phase 2: 所有组件构造完成后调用。创建 UI 节点、加载资源。</summary>
        public virtual void InitComponent() { }
        
        /// <summary>Phase 3: 所有组件 InitComponent 完成后调用。可安全引用其他组件的节点。</summary>
        public virtual void AfterInit() { }
        
        /// <summary>入房时如有重连数据，调用此方法恢复状态。</summary>
        public virtual void HandleRoomEnterInfo(RoomEnterInfo info) { }
        
        /// <summary>每次收到旋转结果时调用。</summary>
        public virtual void HandleSpinResult(SpinResult result) { }
        
        /// <summary>手动刷新。</summary>
        public virtual void Refresh() { }
        
        /// <summary>退出清理。</summary>
        public virtual void OnExit() { }
        
        // ── SlotAction 集成 ──
        
        private SlotActionBase _slotActions;
        
        public void SetSlotActions(SlotActionBase actions) { _slotActions = actions; }
        
        /// <summary>检查关联的 Action 是否应触发。</summary>
        protected bool CheckWithActions(object param = null)
        {
            if (_slotActions == null) return false;
            return _slotActions.TriggerFilter(param);
        }
        
        /// <summary>触发关联的 Action。如无 Action 则直接回调。</summary>
        protected void TriggerActions(Action callback, object param = null)
        {
            if (_slotActions != null && _slotActions.TriggerFilter(param))
                _slotActions.OnTrigger(callback, param);
            else
                callback?.Invoke();
        }
    }
}
```

#### 关键设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 基类是否继承 MonoBehaviour | **否** | 组件是逻辑概念，非 Unity 场景节点。由 SlotMachineBase 统一管理生命周期。 |
| 组件间引用方式 | `Machine.GetComponent<T>()` | 与 JS 的 `context.getComponent(CT.xxx)` 一致 |
| 三阶段初始化是否保留 | **保留** | 解决组件间初始化顺序依赖的问题 |

---

### 4.2.2 Process 基类

**JS 源**：`src/newdesign_slot/process/Process.js`

#### JS 生命周期

```
ctor(context)
  └── initializeProcess()
setFlowController(controller)          ← FlowDispatcher 构建时设置
onEnter(args)                           ← 进入流程
  └── setActivatingProcess(this)
update(dt)                              ← 每帧更新（可选）
advanceToNext(args)                     ← 流程完成，前进到下一个
onLeave()                               ← 离开清理
onExit()                                ← 场景退出清理
```

#### C# 映射

```csharp
namespace WTC.Slot.Compat2022.Core.Process
{
    public abstract class SlotProcessBase
    {
        protected SlotMachineBase Machine { get; private set; }
        
        internal IFlowController FlowController { get; set; }
        
        /// <summary>构造后初始化，只调用一次。</summary>
        public virtual void InitProcess() { }
        
        /// <summary>进入此流程时调用。</summary>
        public virtual void OnEnter(object args = null)
        {
            Machine.SetActivatingProcess(this);
        }
        
        /// <summary>每帧更新（仅在此流程处于活跃状态时调用）。</summary>
        public virtual void Update(float dt) { }
        
        /// <summary>流程完成时由子类调用，通知 FlowDispatcher 前进。</summary>
        protected void AdvanceToNext(object args = null)
        {
            FlowController.AdvanceToNext(args);
        }
        
        /// <summary>离开此流程时调用（AdvanceToNext 后自动触发）。</summary>
        public virtual void OnLeave() { }
        
        /// <summary>刷新组件引用（面板切换后）。</summary>
        public virtual void RefreshComponent() { }
        
        /// <summary>场景退出时调用。</summary>
        public virtual void OnExit() { }
        
        // ── 阻塞器支持 ──
        
        protected List<ProcessBlockerType> Blockers { get; } = new();
        
        /// <summary>检查是否有阻塞器阻止流程前进。</summary>
        protected bool IsBlocked()
        {
            foreach (var blocker in Blockers)
                if (Machine.HasBlocker(blocker))
                    return true;
            return false;
        }
    }
    
    /// <summary>
    /// 条件流程：当 CheckCondition() 返回 true 时，FlowLoop 会 break。
    /// 用于 SubRoundEndProcess 控制内层循环退出。
    /// </summary>
    public abstract class ConditionProcess : SlotProcessBase
    {
        /// <summary>返回 true 则跳出当前循环。</summary>
        public abstract bool CheckCondition();
    }
}
```

---

### 4.2.3 SlotAction 基类

**JS 源**：`src/newdesign_slot/actions/SlotActon.js` + `SlotActionEasy.js`

#### JS 模式

```
triggerFliter(data) → bool       ← 检查是否满足触发条件
onTrigger(callback, data)        ← 执行动作，完成后回调
onExit()                         ← 清理
```

#### C# 映射

```csharp
namespace WTC.Slot.Compat2022.Core.SlotAction
{
    /// <summary>
    /// Slot 动作基类。实现 triggerFilter → onTrigger 的触发模式。
    /// </summary>
    public abstract class SlotActionBase
    {
        protected SlotMachineBase Machine { get; private set; }
        
        public string TypeName { get; protected set; }
        
        /// <summary>初始化（在构造后调用）。</summary>
        public virtual void Init() { }
        
        /// <summary>检查是否满足触发条件。</summary>
        public virtual bool TriggerFilter(object data = null) => false;
        
        /// <summary>执行动作，完成后调用 callback。</summary>
        public virtual void OnTrigger(Action callback, object data = null)
        {
            callback?.Invoke();
        }
        
        /// <summary>清理。</summary>
        public virtual void OnExit()
        {
            Machine = null;
        }
    }
    
    /// <summary>
    /// 带事件监听的 SlotAction（对应 JS 的 SlotActon.js）。
    /// 监听 SLOT_NOTICE 事件，分发到 OnStartSpin / OnSpinEnd / OnWaitEnter。
    /// </summary>
    public abstract class SlotActionWithEvents : SlotActionBase
    {
        public virtual void OnStartSpin() { }
        public virtual void OnSpinProcessEnd() { }
        public virtual void OnWaitProcessEnter() { }
        
        public override void Init()
        {
            // 注册 SLOT_NOTICE 事件监听
            EventDispatcher.On(SlotEvents.SLOT_NOTICE, OnSlotNotice);
        }
        
        public override void OnExit()
        {
            EventDispatcher.Off(SlotEvents.SLOT_NOTICE, OnSlotNotice);
            base.OnExit();
        }
        
        private void OnSlotNotice(object data) { /* dispatch to virtual methods */ }
    }
    
    /// <summary>
    /// 期待动画（Qianyao）动作基类。
    /// 当 triggerSpecial 触发时播放期待动画 + 音效。
    /// </summary>
    public abstract class QianyaoActionBase : SlotActionBase
    {
        protected string SoundName { get; set; }
        
        public override bool TriggerFilter(object data = null)
        {
            var result = Machine.ReceivedSpinResult;
            return result?.ExtraInfo?.TriggerSpecial ?? false;
        }
        
        public override void OnTrigger(Action callback, object data = null)
        {
            // 播放期待动画 + 音效
            // 设置 needForwardDelay = true（阻止卷轴停止）
            // 动画完成后 callback
        }
        
        /// <summary>获取动画名称，子类可覆写。</summary>
        protected virtual string GetAnimationName() => "appear";
        
        /// <summary>获取动画节点，子类可覆写。</summary>
        protected virtual GameObject GetAnimationNode() => null;
    }
}
```

---

### 4.2.4 FlowDispatcher — 流程引擎

**JS 源**：`src/newdesign_slot/process/FlowDispatcher.js`

#### 核心概念

FlowDispatcher 实现了一个基于 **嵌套数组 DSL** 的状态机引擎：
- `[P1, P2, P3]` → 顺序执行
- `["loop", P1, P2, P3]` → 循环执行（直到 ConditionProcess break）
- 支持任意深度嵌套

#### C# 映射

```csharp
namespace WTC.Slot.Compat2022.Core.Process
{
    public enum FlowAdvanceResult { Keep, Next, Break }
    
    /// <summary>流程控制器接口，由 SlotMachineBase 实现。</summary>
    public interface IFlowController
    {
        void AdvanceToNext(object args = null);
        void SetActivatingProcess(SlotProcessBase process);
        bool HasBlocker(ProcessBlockerType type);
    }
    
    /// <summary>流程树节点基类。</summary>
    internal abstract class FlowNodeBase
    {
        public abstract void OnEnter(object args = null);
        public abstract void Update(float dt);
        public abstract FlowAdvanceResult AdvanceToNext();
        public abstract void OnLeave();
        public abstract void OnExit();
    }
    
    /// <summary>单流程节点，包装一个 SlotProcessBase。</summary>
    internal class FlowNode : FlowNodeBase
    {
        private SlotProcessBase _process;
        private bool _enterOnNextFrame;
        private bool _readyForEnter;
        private object _enterArgs;
        
        public override void OnEnter(object args)
        {
            if (_enterOnNextFrame)
            {
                _readyForEnter = true;
                _enterArgs = args;
            }
            else
            {
                _process.OnEnter(args);
            }
        }
        
        public override void Update(float dt)
        {
            if (_readyForEnter)
            {
                _readyForEnter = false;
                _process.OnEnter(_enterArgs);
            }
            _process.Update(dt);
        }
        
        public override FlowAdvanceResult AdvanceToNext()
        {
            _process.OnLeave();
            if (_process is ConditionProcess cp && cp.CheckCondition())
                return FlowAdvanceResult.Break;
            return FlowAdvanceResult.Next;
        }
        
        public override void OnLeave() { }
        public override void OnExit() { _process.OnExit(); }
    }
    
    /// <summary>顺序序列节点。</summary>
    internal class FlowSequence : FlowNodeBase
    {
        private List<FlowNodeBase> _children;
        private int _currentIndex;
        
        public override void OnEnter(object args)
        {
            _currentIndex = 0;
            _children[0].OnEnter(args);
        }
        
        public override void Update(float dt) => _children[_currentIndex].Update(dt);
        
        public override FlowAdvanceResult AdvanceToNext()
        {
            var result = _children[_currentIndex].AdvanceToNext();
            if (result == FlowAdvanceResult.Break) return FlowAdvanceResult.Break;
            
            _children[_currentIndex].OnLeave();
            _currentIndex++;
            
            if (_currentIndex >= _children.Count)
                return FlowAdvanceResult.Next;
            
            _children[_currentIndex].OnEnter(null);
            return FlowAdvanceResult.Keep;
        }
        
        public override void OnLeave() { }
        public override void OnExit() { foreach (var c in _children) c.OnExit(); }
    }
    
    /// <summary>循环节点。遇到 Break 时退出循环。</summary>
    internal class FlowLoop : FlowNodeBase
    {
        private List<FlowNodeBase> _children;
        private int _currentIndex;
        
        public override void OnEnter(object args)
        {
            _currentIndex = 0;
            _children[0].OnEnter(args);
        }
        
        public override void Update(float dt) => _children[_currentIndex].Update(dt);
        
        public override FlowAdvanceResult AdvanceToNext()
        {
            var result = _children[_currentIndex].AdvanceToNext();
            if (result == FlowAdvanceResult.Break)
                return FlowAdvanceResult.Next; // 循环退出
            
            _children[_currentIndex].OnLeave();
            _currentIndex = (_currentIndex + 1) % _children.Count; // 回绕
            _children[_currentIndex].OnEnter(null);
            return FlowAdvanceResult.Keep;
        }
        
        public override void OnLeave() { }
        public override void OnExit() { foreach (var c in _children) c.OnExit(); }
    }
    
    /// <summary>
    /// 流程调度器。由 SlotMachineBase 持有并驱动。
    /// </summary>
    public class FlowDispatcher
    {
        private FlowNodeBase _root;
        
        /// <summary>
        /// 从流程定义构建调度器。
        /// processTree 格式：SlotProcessBase 实例或嵌套 List（含 "loop" 标记）。
        /// </summary>
        public static FlowDispatcher Build(
            object processTree, 
            IFlowController controller, 
            bool enterOnNextFrame = true);
        
        public void OnEnter() => _root.OnEnter(null);
        
        /// <summary>每帧由 SlotMachineBase.Update() 调用。</summary>
        public void Update(float dt) => _root.Update(dt);
        
        /// <summary>当前活跃流程完成时调用。</summary>
        public bool AdvanceToNext()
        {
            var result = _root.AdvanceToNext();
            return result == FlowAdvanceResult.Next; // 整棵树完成
        }
        
        public void OnExit() => _root.OnExit();
    }
}
```

---

## 4.3 SlotActionRegistry (SA/SAT)

**JS 源**：`src/newdesign_slot/actions/SlotActionRegistry.js`

```csharp
namespace WTC.Slot.Compat2022.Core.SlotAction
{
    /// <summary>Slot Action 类型枚举（对应 JS 的 SAT）。</summary>
    public static class SAT
    {
        public const string FreeSpinAction = "slotAction_FreeSpinAction";
        public const string QianyaoAction = "slotAction_QianyaoAction";
        public const string SpinResultMultiUpAction = "slotAction_SpinResultMultiUpAction";
        public const string SymbolDrumAction = "slotAction_SymbolDrumAction";
        public const string TapAnyWhereSpinAction = "slotAction_TapAnyWhereSpinAction";
        public const string FastSpinGuideAction = "slotAction_FastSpinGuideAction";
        public const string FastSpinSettlementAction = "slotAction_FastSpinSettlementAction";
        // ... 更多类型按需添加
    }
    
    /// <summary>Slot Action 工厂（对应 JS 的 SA）。</summary>
    public static class SA
    {
        /// <summary>创建并注册一个新的 SlotAction 实例。</summary>
        public static T New<T>(SlotMachineBase machine) where T : SlotActionBase, new();
        
        /// <summary>按类型名获取第一个实例。</summary>
        public static SlotActionBase Get(string typeName);
        
        /// <summary>按类型名获取所有实例。</summary>
        public static List<SlotActionBase> Gets(string typeName);
    }
}
```

---

## 4.4 Reel 卷轴系统（从零构建）

### 设计目标

源代码的卷轴旋转通过一系列 Process 协作完成：
```
ColumnSpinStartProcess          → 启动旋转
ColumnSpinSteadyProcess         → 匀速旋转（等待结果）
ColumnSpinBeforeReceiveResult   → 收到结果前的准备
ColumnSpinDecelerationProcess   → 减速停止
ColumnSpinStopProcess           → 最终停止 + 弹跳
ColumnStopAnimationProcess      → 停轮后动画
```

### 核心类

```csharp
namespace WTC.Slot.Compat2022.Core.Reel
{
    /// <summary>单列卷轴条。管理该列的符号实例和滚动位置。</summary>
    public class ReelStrip
    {
        public int ColumnIndex { get; }
        public int VisibleRowCount { get; }
        
        /// <summary>当前符号 ID 列表（包括可见行 + 上下缓冲行）。</summary>
        public List<int> SymbolIds { get; }
        
        /// <summary>当前滚动偏移量（像素）。</summary>
        public float ScrollOffset { get; set; }
        
        /// <summary>设置最终停止符号。</summary>
        public void SetStopSymbols(int[] symbolIds);
        
        /// <summary>更新滚动位置。</summary>
        public void UpdateScroll(float delta);
        
        /// <summary>立即对齐到停止位置。</summary>
        public void SnapToStop();
    }
    
    /// <summary>单列旋转控制器。管理旋转阶段：启动→匀速→减速→停止→弹跳。</summary>
    public class ReelSpinController
    {
        public enum SpinPhase { Idle, Accelerating, Steady, Decelerating, Stopping, Bouncing }
        
        public SpinPhase Phase { get; private set; }
        public ReelStrip Strip { get; }
        
        /// <summary>启动旋转。</summary>
        public void StartSpin(float accelerationDuration);
        
        /// <summary>进入匀速阶段。</summary>
        public void EnterSteady(float speed);
        
        /// <summary>开始减速停止。</summary>
        public void BeginDeceleration(int[] targetSymbols, float duration);
        
        /// <summary>每帧更新。</summary>
        public void Update(float dt);
        
        /// <summary>旋转完成事件。</summary>
        public event Action OnSpinComplete;
    }
    
    /// <summary>符号对象池。复用符号 GameObject 减少 GC。</summary>
    public class SymbolPool
    {
        public GameObject Get(int symbolId);
        public void Return(GameObject symbolObj);
        public void PreWarm(int symbolId, int count);
    }
    
    /// <summary>卷轴系统管理器。协调所有列的旋转。</summary>
    public class ReelSystem
    {
        public int ColumnCount { get; }
        public int RowCount { get; }
        
        public ReelStrip[] Strips { get; }
        public ReelSpinController[] Controllers { get; }
        public SymbolPool Pool { get; }
        
        /// <summary>启动所有列旋转（按列间隔启动）。</summary>
        public void StartAllSpins(float columnDelay);
        
        /// <summary>设置某列的停止符号。</summary>
        public void SetColumnResult(int col, int[] symbols);
        
        /// <summary>停止某列。</summary>
        public void StopColumn(int col);
        
        /// <summary>所有列停止事件。</summary>
        public event Action OnAllColumnsStopped;
    }
}
```

---

## 4.5 SlotMachineBase — 主场景基类

**JS 源**：`SlotMachineScene.js` + `SlotMachineScene2022.js`（合计约 200+ 方法）

```csharp
namespace WTC.Slot.Compat2022.Core
{
    public abstract class SlotMachineBase : MonoBehaviour, IFlowController
    {
        // ══════ 数据 ══════
        public MachineConfig Config { get; protected set; }
        public SpinResult ReceivedSpinResult { get; protected set; }
        
        // ══════ 子系统 ══════
        protected FlowDispatcher FlowDispatcher { get; private set; }
        protected Dictionary<Type, SlotComponentBase> Components { get; } = new();
        protected Dictionary<string, List<SlotActionBase>> SlotActions { get; } = new();
        
        // ══════ 生命周期 ══════
        
        protected virtual void Awake()
        {
            InitConfig();
            InitComponents();
            InitFlowDispatcher();
        }
        
        protected virtual void Start()
        {
            AfterInit();
            FlowDispatcher.OnEnter();
        }
        
        protected virtual void Update()
        {
            FlowDispatcher?.Update(Time.deltaTime);
        }
        
        protected virtual void OnDestroy()
        {
            FlowDispatcher?.OnExit();
            foreach (var comp in Components.Values) comp.OnExit();
            foreach (var actions in SlotActions.Values)
                foreach (var action in actions) action.OnExit();
        }
        
        // ══════ 关卡覆写点（virtual 方法）══════
        
        /// <summary>追加关卡特有配置。</summary>
        protected virtual void AppendExtraConfig() { }
        
        /// <summary>返回场景级组件配置。关卡覆写以添加/替换组件。</summary>
        protected virtual Dictionary<Type, ComponentConfig> GetSceneComponentConfig();
        
        /// <summary>返回面板级组件配置。</summary>
        protected virtual Dictionary<Type, ComponentConfig> GetSpinPanelComponentsConfig(int panelId);
        
        /// <summary>返回流程树定义。</summary>
        protected virtual object GetProcessTree();
        
        /// <summary>返回列旋转流程构造器。</summary>
        protected virtual List<Func<SlotProcessBase>> GetColumnSpinProcesses(int panelId, int col);
        
        /// <summary>旋转结果接收后的处理。</summary>
        protected virtual void HandleSpinResult() { }
        
        /// <summary>获取符号控制器映射。</summary>
        protected virtual Dictionary<int, Type> GetSymbolControllers() => null;
        
        // ══════ 回合生命周期钩子 ══════
        
        public virtual void OnRoundStart() { }
        public virtual void OnRoundEnd() { }
        public virtual void OnSubRoundStart() { }
        public virtual void OnSubRoundEnd() { }
        
        // ══════ FreeSpin 钩子 ══════
        
        public virtual void OnEnterFreeSpin() { }
        public virtual void OnExitFreeSpin() { }
        public virtual void OnFreeSpinBegin(int totalCount) { }
        public virtual void OnFreeSpinEnd(double totalWin) { }
        public virtual void OnFreeSpinRetrigger(int addCount) { }
        
        // ══════ 组件访问 ══════
        
        public T GetComponent<T>() where T : SlotComponentBase
        {
            Components.TryGetValue(typeof(T), out var comp);
            return comp as T;
        }
        
        // ══════ IFlowController 实现 ══════
        
        private SlotProcessBase _activatingProcess;
        
        public void AdvanceToNext(object args = null)
        {
            FlowDispatcher.AdvanceToNext();
        }
        
        public void SetActivatingProcess(SlotProcessBase process)
        {
            _activatingProcess = process;
        }
        
        public bool HasBlocker(ProcessBlockerType type) { /* ... */ }
        
        // ══════ 状态查询 ══════
        
        public bool IsFreeSpin { get; set; }
        public bool IsAutoSpin { get; set; }
        public bool IsRespin { get; set; }
        public bool IsFastSpin { get; set; }
        public bool IsSpinResultReceived { get; protected set; }
    }
}
```

---

## 4.6 20 个基础组件清单与转换策略

| # | C# 类名 | JS 源 | 职责 | 转换要点 |
|---|---------|-------|------|----------|
| 1 | `SpinPanelComponent` | `SpinPanelComponent.js` | 卷轴面板管理，持有子组件 | 管理 ReelSystem 实例 |
| 2 | `ClassicSpinPanelComponent` | `ClassicSpinPanelComponent.js` | 经典列式卷轴面板 | 继承 SpinPanelComponent |
| 3 | `CellSpinPanelComponent` | `CellSpinPanelComponent.js` | 单元格式面板 | 继承 SpinPanelComponent |
| 4 | `SymbolLayerComponent` | `SymbolLayerComponent.js` | 符号层：管理符号节点的创建和回收 | 配合 SymbolPool |
| 5 | `ClassicSymbolLayerComponent` | `ClassicSymbolLayerComponent.js` | 经典列式符号层 | 继承 SymbolLayerComponent |
| 6 | `CellSymbolLayerComponent` | `CellSymbolLayerComponent.js` | 单元格式符号层 | 继承 SymbolLayerComponent |
| 7 | `DrumModeComponent` | `DrumModeComponent.js` | 鼓点模式：控制停轮节奏和预判 | 停轮延迟、Qianyao 集成 |
| 8 | `MainUIComponent` | `SlotMachineMainUIComponent.js` | 主界面：加载主 CCB/Prefab | NameBinder 绑定所有 UI 节点 |
| 9 | `SpinUIComponent` | `SpinUIComponent.js` | 旋转按钮面板：Spin/Auto/Fast/Bet | Button 事件绑定 |
| 10 | `WinLineComponent` | `WinLineComponent.js` | 赢线显示：赢线高亮、数字展示 | 赢线数据 → 视觉映射 |
| 11 | `LinesBlinkComponent` | `LinesBlinkComponent.js` | 赢线闪烁：逐线轮播闪烁 | DOTween Sequence 循环 |
| 12 | `BlinkWinManComponent` | `BlinkWinManComponent.js` | 赢分闪烁管理：总赢分滚数 | 数字滚动动画 |
| 13 | `SymbolAnimComponent` | `SymbolAnimationComponent.js` | 符号动画：中奖符号播放动画 | Animator 触发 |
| 14 | `WinEffectComponent` | `WinEffectComponent.js` | 赢分特效：Big Win/Mega Win/Ultra Win | 全屏特效 + 数字滚动 |
| 15 | `JackpotEffectComponent` | `JackpotEffectComponent.js` | 奖池特效：Jackpot 中奖展示 | 多层级奖池动画 |
| 16 | `FreeSpinBeginComponent` | `FreeSpinBeginComponent.js` | 免费旋转开始：弹窗 + 过渡动画 | Prefab 弹窗 |
| 17 | `FreeSpinEndComponent` | `FreeSpinEndComponent.js` | 免费旋转结束：结算弹窗 | Prefab 弹窗 |
| 18 | `ScatterGameComponent` | `ScatterGameComponent.js` | Scatter 游戏触发 | 关卡差异大，L3 适配 |
| 19 | `EnterRoomBonusComponent` | `EnterRoomBonusCheckingComponent.js` | 入房 Bonus 检查：重连恢复 | 状态恢复逻辑 |
| 20 | `FastSpinComponent` | `FastSpinComponent.js` | 快速旋转控制 | 配置驱动 |

---

## 4.7 35 个 Process 基类清单与转换策略

| # | C# 类名 | JS 源 | 转换要点 |
|---|---------|-------|----------|
| 1 | `EnterRoomCheckingProcess` | `EnterRoomCheckingProcess.js` | 单次入房检查 |
| 2 | `WaitForSpinProcess` | `WaitForSpinProcess.js` | 等待用户点击 Spin |
| 3 | `FreeSpinBeginCheckingProcess` | `FreeSpinBeginCheckingProcess.js` | 检查免费旋转触发 |
| 4 | `RoundStartProcess` | `RoundStartProcess.js` | 回合开始 |
| 5 | `SubRoundStartProcess` | `SubRoundStartProcess.js` | 子回合开始 |
| 6 | `SpinProcess` | `SpinProcess.js` | 发送请求 + 等待结果 |
| 7 | `PanelSpinProcess` | `PanelSpinProcess.js` | 面板旋转（管理列旋转流程） |
| 8 | `ColumnSpinStartProcess` | `ColumnSpinStartProcess.js` | 列启动旋转 |
| 9 | `ColumnSpinSteadyProcess` | `ColumnSpinSteadyProcess.js` | 列匀速旋转 |
| 10 | `ColumnSpinBeforeReceiveProcess` | `ColumnSpinBeforeReceiveSpinResultProcess.js` | 收到结果前准备 |
| 11 | `ColumnSpinDecelerationProcess` | `ColumnSpinDecelerationProcess.js` | 列减速 |
| 12 | `ColumnSpinSingleStepDecProcess` | `ColumnSpinSingleStepDecelerationProcess.js` | 单步减速变体 |
| 13 | `ColumnSpinStopProcess` | `ColumnSpinStopProcess.js` | 列停止 + 弹跳 |
| 14 | `ColumnStopAnimationProcess` | `ColumnStopAnimationProcess.js` | 停轮后动画 |
| 15 | `SpecialGameProcess` | `SpecialGameProcess.js` | 特殊游戏 |
| 16 | `JackpotProcess` | `JackpotProcess.js` | 奖池展示 |
| 17 | `ShowWinEffectProcess` | `ShowWinEffectProcess.js` | BigWin 展示 |
| 18 | `LevelUpProcess` | `LevelUpProcess.js` | 升级检查 |
| 19 | `VipLevelUpProcess` | `VipLevelUpProcess.js` | VIP 升级 |
| 20 | `BlinkAllWinLineProcess` | `BlinkAllWinLineProcess.js` | 赢线闪烁 |
| 21 | `PanelWinUpdateProcess` | `PanelWinUpdateProcess.js` | 赢分 UI 更新 |
| 22 | `BlinkBonusProcess` | `BlinkBonusProcess.js` | Bonus 闪烁 |
| 23 | `BlinkScatterProcess` | `BlinkScatterProcess.js` | Scatter 闪烁 |
| 24 | `SubRoundEndProcess` | `SubRoundEndProcess.js` | 子回合结束（ConditionProcess） |
| 25 | `PreRoundEndProcess` | `PreRoundEndProcess.js` | 回合预结束 |
| 26 | `RoundEndProcess` | `RoundEndProcess.js` | 回合结束 |
| 27 | `FreeSpinEndCheckingProcess` | `FreeSpinEndCheckingProcess.js` | 免费旋转结束检查 |
| 28 | `CouponFreeSpinCheckingProcess` | `CouponFreeSpinCheckingProcess.js` | 优惠券免费旋转 |
| 29 | `InteractiveGameCheckingProcess` | `InteractiveGameCheckingProcess.js` | 互动游戏检查 |
| 30 | `ShowInterstitialAdProcess` | `ShowInterstitialAdProcess.js` | 插屏广告 |
| 31 | `ConditionProcess` | `ConditionProcess.js` | 条件流程基类 |
| 32 | `SpinResultDelayMultiUpProcess` | `SpinResultDelayMultiUpProcess.js` | 延迟倍率展示 |
| 33 | `CloverClashWaitProcess` | `CloverClashWaitProcess.js` | 活动等待 |

---

## 4.8 27 个 Action 基类清单

| # | C# 类名 | JS 源 | 说明 |
|---|---------|-------|------|
| 1 | `FreeSpinAction` | `FreeSpinAction.js` | 免费旋转流程控制 |
| 2 | `QianyaoAction` | `QianyaoAction.js` | 期待动画 |
| 3 | `QianyaoDialogAction` | `QianyaoDialogAction.js` | 期待弹窗 |
| 4 | `SymbolDrumAction` | `SymbolDrumAction.js` | 符号鼓点 |
| 5 | `TapAnyWhereSpinAction` | `TapAnyWhereSpinAction.js` | 点击任意位置旋转 |
| 6 | `FastSpinGuideAction` | `FastSpinGuideAction.js` | 快速旋转引导 |
| 7 | `FastSpinSettlementAction` | `FastSpinSettlementAction.js` | 快速旋转结算 |
| 8 | `SpinResultMultiUpAction` | `SpinResultMultiUpAction.js` | 结果倍率 |
| 9 | `SlowDrumModeAction` | `SlowDrumModeAction.js` | 慢速鼓点 |
| 10 | `CameraFocusAction` | `CameraFocusAction.js` | 镜头聚焦 |
| 11 | `AddTouchMaskAction` | `AddTouchMaskAction.js` | 添加触摸遮罩 |
| 12 | `BigWinBeforeDelayAction` | `BigWinBeforeDelayAction.js` | 大赢前延迟 |
| 13 | `EarlyStopReelAppearAnimAction` | `EarlyStopReelAppearAnimAction.js` | 提前停止卷轴动画 |
| 14 | `FakeJackpotParseAction` | `FakeJackpotParseAction.js` | 假 Jackpot 解析 |
| 15 | `HighRollerBetTipOffsetAction` | `HighRollerBetTipOffsetAction.js` | HR 下注提示偏移 |
| 16 | `MatchThreeAction` | `MatchThreeAction.js` | 三消玩法 |
| 17 | `ModifySpecialPayTableDataAction` | `ModifySpecialPayTableDataOnWinLineAction.js` | 修改赔率表 |
| 18 | `MuiltiplePanelHRJackpotAction` | `MuiltiplePanelHRJackpotAction.js` | 多面板 HR Jackpot |
| 19 | `ResolveAutoSpinWrongProcessAction` | `ResolveAutoSpinWrongProcessAction.js` | 自动旋转错误修复 |
| 20 | `SupportEarlyStopInRespinAction` | `SupportEarlyStopInRespinAction.js` | 重转中提前停止 |
| 21-27 | `SlotActionArray/Sequence/Spawn/Easy/ChangeBet` | 组合和辅助 Action | Action 组合器 |

---

## 4.9 转译依赖与优先级（src/newdesign_slot）

基于 `require()` 静态扫描得到的目录级依赖，作为先后顺序指导（只统计 `src/newdesign_slot/` 内部依赖）。

### 目录依赖概览（文件数/主要依赖）

| 目录 | 文件数 | 主要依赖 | 说明 |
|------|-------|-----------|------|
| **config/protocol (外部前置)** | — | — | **配置解析/协议模型，必须优先转译**：`src/slot/config/SlotConfigMan.js`（`getSubject`/`getSubjectTmpl`/`getEditableConfig` 解析 `res_oldvegas/config/subject_tmpl_list/*.json` + `editable_config_list/*.json`），数据中心 `src/slot/ClassicSlotMan.js` 继承 `SlotMan`，以及协议文件 `src/slot/protocol/{C2S,S2C}{EnterRoom,LeaveRoom,Spin,SlotParam}.js` |
| enum | 4 | — | 全局枚举，其他目录广泛引用 |
| customShader | 2 | — | Shader 占位，独立可先转 |
| controller_new2022 | 16 | enum | 新版 UI 控制器，供组件/动作引用 |
| actions | 27 | enum, controller_new2022 | SlotAction 基类族 |
| controller | 34 | tools, animation, actions | 与 tools 互相依赖（需要拆环） |
| tools | 8 | controller, enum | SlotUtil/WinEffectHelper 等工具，引用部分控制器 |
| animation | 3 | tools | 动画辅助，轻量 |
| process | 35 | enum, actions, tools, controller(+new2022) | 流程基类及变体 |
| component | 57 | enum, process, controller, tools, actions, customShader | 旧版组件族 |
| component_new2022 | 20 | component, enum, actions, controller(+new2022), tools, customShader | 2022 版组件族 |
| scene | 413 | controller, component_new2022, component, actions, process, enum, tools, (customShader/animation) | 所有关卡，依赖最重 |

### 推荐转译顺序（按依赖拓扑）

0. **配置/协议前置**：先转 `SlotConfigMan`（含 subject_tmpl/editable_config JSON 解析）、`ClassicSlotMan`/`SlotMan` 数据中心，以及 `C2S/S2C EnterRoom/LeaveRoom/Spin/SlotParam` 协议模型，确保机器配置与协议数据结构在 C# 端可用。
1. **enum + customShader**：无外部依赖，最先落地。
2. **controller_new2022**：仅依赖 enum，供 Action/组件引用。
3. **actions**：依赖 enum + controller_new2022，完成后支撑流程和组件。
4. **controller / tools / animation**：存在互相引用，建议先转 Controller 基类与接口，再补齐 Tools（可用接口或占位注入拆环），最后补动画辅助。
5. **process**：依赖 enum/actions/tools/controller，完成后 FlowDispatcher 相关代码可编译。
6. **component → component_new2022**：按旧版组件到 2022 版的顺序推进，确保依赖的流程/控制器已就绪。
7. **scene（各关卡）**：依赖最重，待以上目录均可编译后再逐关卡推进。

> 数据来源：`node` 脚本对 `src/newdesign_slot/**/*.js` 的 `require()` 路径解析（仅统计相对路径且仍在 newdesign_slot 目录内）。

---

[下一章：05 - L3 Slot 框架适配层详细设计](05-L3-slot-adaptation.md)
