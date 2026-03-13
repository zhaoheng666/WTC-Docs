# 07 - 执行规范

[返回目录](00-index.md) | [上一章](06-L4-game-migration.md)

> **本章是所有执行者（人工 + AI）的必读规范。任何不遵守本章规范的交付物将被退回。**

### L1/L2 转译一致性硬性要求

- **类名 / 方法签名 / 属性与字段名 / 行为必须与 JS 源一致**：L1（兼容层）与 L2（框架层）转译时，不得随意更名或改动参数、返回值、状态流转。允许的差异仅限于 C# 语法/命名空间适配（如 PascalCase、命名空间前缀），但语义与可观察行为必须 1:1 对齐。
- 若需重构或调整设计，必须先在 OpenSpec 提案中获批，不能在转译过程中私自改变接口契约。

---

## 7.1 接口映射记录规范

### 核心规则

**每实现一个 L1 兼容层方法，必须同步更新映射记录。**

映射记录是本项目最关键的追溯文档。它确保：
1. 任何 JS API 调用都能找到对应的 C# 实现
2. 未实现的 API 不会被遗漏
3. 后续关卡转换可以快速查表

### 更新位置

| 文件 | 用途 | 更新时机 |
|------|------|----------|
| `03-L1-cocos-compat.md` 中的映射表 | 设计参考（含实现策略说明） | 实现完成后更新状态列 |
| `09-appendix-api-reference.md` | 速查表（扁平化，无叙述） | 实现完成后更新状态列 |

### 更新操作

实现一个方法后，执行以下更新：

```markdown
<!-- 更新前 -->
| `setNodeVisible(node, visible)` | `NodeHelper.SetVisible(GameObject, bool)` | `go.SetActive(visible)` | 10,105 | 待实现 |

<!-- 更新后 -->
| `setNodeVisible(node, visible)` | `NodeHelper.SetVisible(GameObject, bool)` | `go.SetActive(visible)` | 10,105 | 已实现 |
```

### 补充映射规则

如果在转换关卡时遇到映射表中**未收录**的 JS API：

1. **立即停止转换**
2. 在映射表中新增该 API 条目
3. 实现该 API 的 C# 方法
4. 将状态标记为 `已实现`
5. 继续转换

**严禁**：跳过未映射的 API、用 TODO 占位、或在 L4 代码中直接写 Unity 调用绕过 L1。

### 映射完整性验证

每完成一个 L1 文件（如 `NodeHelper.cs`），执行以下检查：

1. 统计该文件中实现的方法数
2. 与映射表中的方法数对比
3. 确认所有 `待实现` 状态已更新为 `已实现`
4. 如有方法标记为 `不需要`，需注明理由

---

## 7.2 命名规范

### 命名空间

| 层级 | 命名空间 | 示例 |
|------|----------|------|
| 机台基类 | `WTC.Slot.Compat2022.Core` | `WTC.Slot.Compat2022.Core.SlotMachineBase` |
| 引擎桥接 | `WTC.Slot.Compat2022.Core.Bridge` | `WTC.Slot.Compat2022.Core.Bridge.CCAction` |
| 组件基类 | `WTC.Slot.Compat2022.Core.Component` | `WTC.Slot.Compat2022.Core.Component.SlotComponentBase` |
| 配置定义 | `WTC.Slot.Compat2022.Core.Config` | `WTC.Slot.Compat2022.Core.Config.MachineConfig` |
| 控制器基础 | `WTC.Slot.Compat2022.Core.Controller` | `WTC.Slot.Compat2022.Core.Controller.NameBinder` |
| 数据解析 | `WTC.Slot.Compat2022.Core.Data` | `WTC.Slot.Compat2022.Core.Data.SpinResult` |
| 枚举常量 | `WTC.Slot.Compat2022.Core.Enums` | `WTC.Slot.Compat2022.Core.Enums.SlotEvents` |
| 流程基础层 | `WTC.Slot.Compat2022.Core.Process` | `WTC.Slot.Compat2022.Core.Process.FlowDispatcher` |
| 卷轴系统 | `WTC.Slot.Compat2022.Core.Reel` | `WTC.Slot.Compat2022.Core.Reel.ReelStrip` |
| 动作基类 | `WTC.Slot.Compat2022.Core.SlotAction` | `WTC.Slot.Compat2022.Core.SlotAction.SlotActionBase` |
| 工具集 | `WTC.Slot.Compat2022.Core.Utils` | `WTC.Slot.Compat2022.Core.Utils.NodeHelper` |
| 具体组件 | `WTC.Slot.Compat2022.Components` | `WTC.Slot.Compat2022.Components.SpinPanelComponent` |
| 具体流程 | `WTC.Slot.Compat2022.Processes` | `WTC.Slot.Compat2022.Processes.WaitForSpinProcess` |
| 具体动作 | `WTC.Slot.Compat2022.SlotActions` | `WTC.Slot.Compat2022.SlotActions.FreeSpinAction` |
| L3+L4 关卡 | `WTC.Slot.Games.{GameName}` | `WTC.Slot.Games.WildsStarburst` |

### 类命名

| 类型 | JS 命名 | C# 命名 | 规则 |
|------|---------|---------|------|
| 主场景 | `WildsStarburstMachineScene287` | `WildsStarburstMachine` | 去掉 Scene/数字后缀 |
| 配置 | `WildsStarburstMachineConfig287` | `WildsStarburstConfig` | 去掉 Machine/数字后缀 |
| 自定义组件 | `WildsStarburst_SymbolAnim` | `WS_SymbolAnimComponent` | 前缀缩写 + Component 后缀 |
| 自定义动作 | `WildsStarburst_QianyaoAction` | `WS_QianyaoAction` | 前缀缩写 + Action 保留 |
| 自定义流程 | `WildStarburst_ColumnStopAnimProcess` | `WS_ColumnStopAnimProcess` | 前缀缩写 + Process 保留 |
| 自定义控制器 | `WildsStarburst_ReelJackpotController` | `WS_ReelJackpotController` | 前缀缩写 |

### 关卡前缀缩写规则

| 关卡 | 前缀 |
|------|------|
| 287 Wilds Starburst | `WS_` |
| 284 Santa Giftstorm | `SG_` |
| 285 Carnival Blast | `CB_` |
| 286 Halo and Horns | `HH_` |
| 288 Three Little Piggies | `TLP_` |
| 289 Yay Yeti Glitzy | `YYG_` |
| 290 Dazzling Diamonds | `DD_` |
| 291 Ducky Dollars | `DkD_` |
| 292 Rose Romance | `RR_` |
| 293 Trio Wheels Deluxe | `TWD_` |
| 297 Goldpot Party | `GP_` |
| 单文件关卡 | 取游戏名首字母缩写（2-3 字母）|

### 方法命名

| JS 风格 | C# 风格 | 规则 |
|---------|---------|------|
| `camelCase` | `PascalCase` | 公共方法首字母大写 |
| `_privateMethod` | `_PrivateMethod` 或 `PrivateMethod` | 私有方法可保留下划线或去掉 |
| `getXxx()` | `GetXxx()` 或用属性 `Xxx { get; }` | 简单 getter 优先用属性 |
| `setXxx(value)` | `SetXxx(value)` 或用属性 `Xxx { set; }` | 简单 setter 优先用属性 |
| `isXxx()` | `IsXxx` 属性 或 `IsXxx()` 方法 | 布尔查询优先用属性 |

### 变量命名

| JS 风格 | C# 风格 | 规则 |
|---------|---------|------|
| `this.xxx` 实例变量 | `private Type _xxx` | 私有字段加下划线前缀 |
| `var xxx` 局部变量 | `var xxx` | 保持 camelCase |
| `CT.SYMBOL_ANIM` 常量 | `typeof(SymbolAnimComponent)` | 用类型替代字符串常量 |
| `SAT.QianyaoAction` | `SAT.QianyaoAction` | 保持 |

---

## 7.3 文件组织规范

### 目录结构

```
Assets/Project/AddressableRes/
├── Scripts/
│   └── framework/
│       └── slot/
│           ├── 2026/                                # 未来新的 Unity 原生框架
│           ├── compat/                              # cocos 项目 Slot 老框架的兼容框架
│           └── compat2022/                          # cocos 项目 Slot 新框架的兼容框架
│               ├── Components/                      # WTC.Slot.Compat2022.Components — 具体机台组件
│               │   ├── SpinPanelComponent.cs
│               │   ├── ClassicSpinPanelComponent.cs
│               │   ├── CellSpinPanelComponent.cs
│               │   ├── SymbolLayerComponent.cs
│               │   ├── ... (20 个基础组件)
│               │   └── FastSpinComponent.cs
│               ├── Controllers/                     # WTC.Slot.Compat2022.Controller — UI 控制器
│               ├── Core/
│               │   ├── SlotMachineBase.cs            # WTC.Slot.Compat2022.Core
│               │   ├── EventDispatcher.cs            # WTC.Slot.Compat2022.Core
│               │   ├── Bridge/                       # WTC.Slot.Compat2022.Core.Bridge
│               │   │   ├── CCCompat.cs
│               │   │   ├── CCAction.cs
│               │   │   ├── AudioBridge.cs
│               │   │   └── DialogBridge.cs
│               │   ├── Component/                    # WTC.Slot.Compat2022.Core.Component
│               │   │   └── SlotComponentBase.cs
│               │   ├── Config/                       # WTC.Slot.Compat2022.Core.Config
│               │   │   └── MachineConfig.cs
│               │   ├── Contrller/                    # WTC.Slot.Compat2022.Core.Controller
│               │   │   └── NameBinder.cs
│               │   ├── Data/                         # WTC.Slot.Compat2022.Core.Data
│               │   │   └── SpinResult.cs
│               │   ├── Enums/                        # WTC.Slot.Compat2022.Core.Enums
│               │   │   ├── ComponentType.cs
│               │   │   ├── ProcessBlockerType.cs
│               │   │   ├── SlotEvents.cs
│               │   │   └── SymbolAnimationType.cs
│               │   ├── Processe/                     # WTC.Slot.Compat2022.Core.Process
│               │   │   ├── ConditionProcess.cs
│               │   │   ├── FlowDispatcher.cs
│               │   │   ├── IFlowController.cs
│               │   │   └── SlotProcessBase.cs
│               │   ├── Reel/                         # WTC.Slot.Compat2022.Core.Reel
│               │   │   ├── ReelSystem.cs
│               │   │   ├── ReelStrip.cs
│               │   │   ├── ReelSpinController.cs
│               │   │   └── SymbolPool.cs
│               │   ├── SlotAction/                   # WTC.Slot.Compat2022.Core.SlotAction
│               │   │   ├── SlotActionBase.cs
│               │   │   ├── SlotActionRegistry.cs
│               │   │   ├── QianyaoActionBase.cs
│               │   │   └── ...
│               │   └── Utils/                        # WTC.Slot.Compat2022.Core.Utils
│               │       ├── NodeHelper.cs
│               │       ├── GameUtil.cs
│               │       ├── SlotUtil.cs
│               │       ├── ActivityUtil.cs
│               │       ├── UIHelper.cs
│               │       ├── SlotPopupUtil.cs
│               │       ├── WinEffectHelper.cs
│               │       └── HighRollerSlotUtil.cs
│               ├── Processes/                        # WTC.Slot.Compat2022.Processes — 具体流程
│               │   ├── EnterRoomCheckingProcess.cs
│               │   ├── WaitForSpinProcess.cs
│               │   ├── ... (31 个基础流程)
│               │   └── CloverClashWaitProcess.cs
│               └── SlotActions/                      # WTC.Slot.Compat2022.SlotActions — 具体动作
│                   ├── FreeSpinAction.cs
│                   ├── QianyaoAction.cs
│                   ├── ... (21 个基础动作)
│                   └── TapAnyWhereSpinAction.cs
└── Slots/                                       # L3 + L4 关卡逻辑
    ├── slot_284_santa_giftstorm/
    │   ├── SantaGiftstormMachine.cs
    │   ├── SantaGiftstormConfig.cs
    │   ├── Components/
    │   ├── Actions/
    │   ├── Processes/
    │   └── Controllers/
    ├── slot_287_wilds_starburst/
    │   ├── WildsStarburstMachine.cs
    │   ├── WildsStarburstConfig.cs
    │   ├── Components/
    │   │   ├── WS_SymbolAnimComponent.cs
    │   │   └── ...
    │   ├── Actions/
    │   ├── Processes/
    │   └── Controllers/
    └── ... (其他关卡)
```

### 文件组织规则

| 规则 | 说明 |
|------|------|
| **L1/L2 不放关卡目录** | 框架代码只在 `Scripts/framework/slot/compat2022/` |
| **L3/L4 不放框架目录** | 关卡代码只在 `Slots/slot_{id}_{name}/` |
| **一个 JS 文件对应一个 C# 文件** | 不合并、不拆分 |
| **关卡目录命名** | `slot_{subjectId}_{snake_case_name}` |
| **子目录固定** | `Components/`, `Actions/`, `Processes/`, `Controllers/` |

---

## 7.4 代码质量规范

### C# 编码标准

| 规则 | 说明 |
|------|------|
| **无 TODO 交付** | 每个文件交付时不允许有 `// TODO` 占位符 |
| **无 Debug.Log 占位** | 不允许用 `Debug.Log("TODO")` 代替未实现的逻辑 |
| **空值安全** | 所有 L1 方法必须处理 null 输入（与 JS 版本行为一致） |
| **using 声明** | 按 System → Unity → DOTween → WTC 排序 |
| **访问修饰符** | 显式标注所有成员的访问级别 |
| **XML 文档** | L1/L2 的所有 public 方法必须有 `<summary>` 注释 |
| **L4 注释** | 关卡特有逻辑需注明对应的 JS 源文件和行号 |

### L4 代码注释规范

```csharp
/// <summary>
/// 解析 Wild Starburst 自定义数据。
/// 对应 JS: WildsStarburstMachineScene287.js:245-310
/// </summary>
private void ParseWildData()
{
    // 对应 JS: line 248 - processWDAppear
    ProcessWDAppear();
    
    // 对应 JS: line 270 - processStarsAppear
    ProcessStarsAppear();
}
```

---

## 7.5 验证规范

### L1 验证标准

| 验证项 | 方法 | 通过标准 |
|--------|------|----------|
| **编译通过** | Unity 编译 | 零错误 |
| **映射完整性** | 对比映射表与源码 | 所有 `已实现` 的方法在 C# 中有对应实现 |
| **空值安全** | 单元测试 | null 输入不抛异常（与 JS 行为一致） |
| **DOTween 动作链** | 视觉测试 | Sequence/Spawn/Repeat 行为与 cc.sequence/spawn/repeat 一致 |
| **NameBinder** | 测试 Prefab | [AutoBind] 字段正确绑定到子节点 |

### L2 验证标准

| 验证项 | 方法 | 通过标准 |
|--------|------|----------|
| **编译通过** | Unity 编译 | 零错误 |
| **FlowDispatcher** | 单元测试 | 流程树正确执行：Sequence 串行、Loop 循环、Break 退出 |
| **组件生命周期** | 集成测试 | 三阶段初始化顺序正确 |
| **Reel 卷轴** | 视觉测试 | 启动→匀速→减速→停止→弹跳 流畅 |
| **无框架 TODO** | 代码扫描 | L2 代码中零 TODO |

### L3+L4 验证标准（单关卡）

| 验证项 | 方法 | 通过标准 |
|--------|------|----------|
| **编译通过** | Unity 编译 | 零错误 |
| **文件完整** | 对比 JS 文件列表 | C# 文件数 ≥ JS 文件数 |
| **流程完整** | 手动运行 | 完整走通：进房→旋转→赢分→FreeSpin→结束 |
| **视觉一致** | 对比截图 | 主要 UI 元素位置/动画与 Cocos 版本一致 |
| **无 TODO** | 代码扫描 | 零 TODO、零 Debug.Log 占位 |
| **映射完整** | 检查映射表 | 本关卡使用的所有 API 在映射表中标记为 `已实现` |

---

## 7.6 进度记录规范

### L1 进度追踪

在 `03-L1-cocos-compat.md` 的每个子章节头部维护进度统计：

```markdown
### 3.3.3 NodeHelper.cs — 节点操作
**进度：15/23 方法已实现（65%）**
```

### L2 进度追踪

在 `04-L2-slot-framework.md` 维护：

```markdown
## 4.6 20 个基础组件
**进度：8/20 已实现**
```

### 关卡转换进度

维护一个专门的进度表（可在 `08-roadmap.md` 中）：

```markdown
| 关卡 | 文件数 | 已转换 | 状态 | 验证 |
|------|--------|--------|------|------|
| 287 Wilds Starburst | 16 | 16 | 完成 | 通过 |
| 290 Dazzling Diamonds | 23 | 0 | 未开始 | — |
```

---

## 7.7 AI 协作规范

### 向 AI 下达转换任务的模板

```
请将关卡 {subject_id} ({game_name}) 从 JS 迁移到 C#。

源文件目录：src/newdesign_slot/scene/{dir_name}/
目标目录：Assets/Project/AddressableRes/Slots/slot_{id}_{name}/

请遵循以下规范：
1. 阅读所有 JS 源文件
2. 按照 06-L4-game-migration.md 的机械翻译规则转换
3. 按照 07-execution-standards.md 的命名规范命名
4. 如遇未映射的 API，停止并报告
5. 转换完成后执行 06-L4-game-migration.md 第 6.3 节的检查清单
6. 更新映射表中新使用的 API 状态
```

### AI 交付物检查清单

AI 完成单关卡转换后，人工审阅时检查：

- [ ] C# 文件数量是否与 JS 文件数量匹配
- [ ] 所有类是否正确继承 L2/L3 基类
- [ ] 是否有未映射的 API 被绕过（直接使用 Unity API 而非 L1 方法）
- [ ] 映射表是否已更新
- [ ] 代码中是否有 TODO / Debug.Log 占位
- [ ] 方法命名是否符合 7.2 节规范
- [ ] 文件是否放在正确的目录
- [ ] 关键业务逻辑是否有 JS 行号注释

### AI 执行边界

| 允许 | 不允许 |
|------|--------|
| 使用 L1 映射方法 | 在 L4 代码中直接使用 Unity API 绕过 L1 |
| 在 L4 中继承 L2/L3 基类 | 修改 L1/L2 框架代码 |
| 新增映射表条目 | 删除或修改已有映射表条目的实现策略 |
| 标记发现的问题 | 忽略问题继续转换 |

---

[下一章：08 - 实施路线图与验证计划](08-roadmap.md)
