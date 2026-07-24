# AI 关卡研发流程

**制定时间**：2026-07-23
**适用范围**：`src/newdesign_slot/scene/` 下所有新关卡开发
**关联文档**：[SlotAction-使用规范](/关卡/SlotAction-使用规范)、[多轮盘spin相关注意事项](/关卡/多轮盘spin相关注意事项)、[创建新关卡工具使用指南](/关卡/创建新关卡工具使用指南)、[注意事项](/关卡/注意事项)

---

## 一、核心判断

基于 304（Sweet Gala）这种质量的策划案，AI 可以直接产出约 **80-90%** 的完整关卡代码。剩余 10-20% 是策划案天然无法覆盖的三类外部依赖。

| 不可自动化的依赖 | 原因 | 304 代码中的典型例子 |
|---|---|---|
| **后端协议** | 策划案描述玩法规则，不描述 `extraInfo` 字段结构 | `triggeredColorFlags`、`purpleAddInfoList`、`finalBonusInfoList` |
| **美术资产清单** | 策划案描述效果，不描述 CCB 节点路径和动画名 | `sweet_gala/reels/bg/sweet_gala_dialog_respin_start.ccbi`、`_guo0`、`_multiTL` |
| **时序常数** | 策划案给相对顺序（"先…再…"），不给帧数 | `50/30`、`21/30`、`delayCall(2.5, ...)` |

**关键结论**：这三类依赖可以提前规约为两张表——**协议契约表**和**美术资产清单**——由后端和美术在策划案定稿时同步产出。有了这两张表，AI 产出率可提升到 **95%+**。

---

## 二、自动化边界分析

以 304 为黄金样本，将关卡代码按自动化难度分为四层：

| 代码层 | 304 行数 | 自动化率 | 驱动源 | 说明 |
|---|---|---|---|---|
| **目录脚手架** | — | 100% | 关卡 ID + 资源名 | 已有 VSCode 扩展工具 |
| **MachineConfig** | ~439 | 95% | 模板 + 策划案轮盘规格 | 90% 是标准字段，5% 是关卡特有配置 |
| **Scene 骨架** | ~200 | 85% | 策划案轮盘数 + 玩法类型 | 四大重载方法结构固定 |
| **Process 流水线** | ~35 | 90% | 标准模板 | `getProcessesNewVersion2025` 几乎逐关一致 |
| **Action triggerFliter** | ~60 | 80% | 策划案规则说明 | 直接翻译"触发条件"为代码 |
| **Action onTrigger flow** | ~300 | 65% | 策划案交互说明 + 时序 | 流程顺序可翻译，帧数需占位 |
| **数据预处理** | ~250 | 30% | **后端协议** | 完全依赖 `extraInfo` 结构 |
| **UI helper 方法** | ~350 | 60% | **CCB 节点结构** | 依赖节点命名 |
| **Component 重写** | ~100 | 70% | 策划案 + 框架文档 | 模式固定 |

---

## 三、三张核心表

AI 自动化产出关卡代码的前提是输入三张结构化表。前两张由人工提供，第三张由 AI 从策划案提取。

### 表 1：玩法点矩阵（AI 从策划案提取）

策划案的玩法规则必须能被拆解为离散的"玩法点"，每个玩法点映射到一个 SlotAction。

| 列名 | 含义 | 来源 |
|---|---|---|
| 玩法点 | 简短描述（如"红锅触发"） | 策划案 |
| 触发条件 | 翻译为 `triggerFliter` 的布尔表达式 | 策划案"触发条件"段落 |
| 执行流程 | 翻译为 `onTrigger` 的 flow 步骤 | 策划案"交互说明"段落 |
| 对应 Action | 类名（如 `TriggerRedGameAction`） | AI 命名 |
| 注册位置 | 挂载点（如 `specialGameComponent`） | 框架知识 |

**304 示例**：

| 玩法点 | 触发条件 | 执行流程 | Action | 注册位置 |
|---|---|---|---|---|
| 红锅触发 | respin 中且 `reTriggerColors` 含 2 | 大锅 trigger → 单金饼变双金饼 | TriggerRedGameAction | specialGameComponent |
| 蓝锅触发 | respin 中且蓝区域数据非空 | 大锅 trigger → 初始化倍数节点 → 检查区域填满 | TriggerBlueGameAction | specialGameComponent |
| 紫锅触发 | respin 中且 `purpleAddInfoList` 非空或首次触发 | 大锅 trigger → 给金饼加钱 | TriggerPurpleGameAction | specialGameComponent |
| 绿锅触发 | respin 中且 `reTriggerColors` 含 1 | 大锅 trigger → 计数器变 4 → 重置次数 | TriggerGreenGameAction | specialGameComponent |
| Respin 触发 | `respinTriggered && respinIndex === 0` | 播 trigger 动画 → 弹触发弹板 → 切轮盘 | TriggerLinkGameAction | bonusGameComponent |
| Respin 结算 | `respinTriggered && isLastSpinIndex` | 检查 Grand → 倍数砸棋盘 → 逐个结算 → 弹结算弹板 | LinkOverGameAction | specialGameComponent |
| 金饼落定 | respin 中且该位置是 bonus 图标 | 播 appear → 变金饼 → 检查蓝区域填满 | LinkColumnStopAniAction | columnStopAnimation (panel 1/2) |
| 大锅收集 | `bonusInfoList.length > 0` | 飞糖果到大锅 → 大锅升级动画 | CollectItemsAction | columnStopAnimation (panel 0) |
| Drum 检测 | respin 中且 14 格已落金饼 | 最后一格播 drum | CheckDrumAction | specialGameComponent |

### 表 2：协议契约表（后端提供）

策划案定稿后，后端需同步产出 `extraInfo` 字段结构说明，示例格式：

```yaml
# extraInfo 字段结构
extraInfo:
  triggeredColorFlags: [int, int, int, int]  # [紫, 绿, 红, 蓝] 0/1
  isSuperRespin: bool
  avgTotalBet: number                         # super 时用
  collectLevels: [int, int, int, int]         # 4 个大锅当前等级 0-3
  collectTriggerTimes: int                    # 第几次触发 respin
  respinInfo:
    respins:                                  # 每次 respin 的结果
      - newBonusInfoList:
          - pos: {col, row}
            color: int                        # 0紫 1绿 2红 3蓝 4彩虹
            type: int                         # 1 coin, 2 jp
            param: [number]
            finalParam: [number]
            index: int                        # 0左下 1右上(红锅双饼)
        purpleAddInfoList:
          - toPos: {col, row}
            toIndex: int
            param: number
        reTriggerColors: [int]
        reTriggerRedBonusInfoList: [...]
        reTriggerBlueArea: {...}
    finalBonusInfoList: [...]                 # 结算时的最终列表
    blueArea:                                 # 蓝锅区域 {"x2": {"0": true, ...}}
  secondRespinInfo: {...}                     # super respin 右盘
  initBonusInfoList: [...]                    # 初始带入的金饼
  initBlueArea: {...}                         # 初始蓝区域
  clearCollectLevels: [int, int, int, int]    # 结束后重置的等级
  clearCollectTriggerTimes: int
```

### 表 3：美术资产清单（美术提供）

美术定稿后需同步产出 CCB 路径、节点命名、动画名、音效名，示例格式：

```yaml
# CCB 路径
mainUI: "sweet_gala/reels/bg/sweet_gala_main.ccbi"
respinStartPanel: "sweet_gala/reels/bg/sweet_gala_dialog_respin_start.ccbi"
superRespinStartPanel: "sweet_gala/reels/bg/sweet_gala_dialog_sp_respin_start.ccbi"
respinCollectPanel: "sweet_gala/reels/bg/sweet_gala_dialog_respin_collect.ccbi"
superRespinCollectPanel: "sweet_gala/reels/bg/sweet_gala_dialog_sp_respin_collect.ccbi"
jackpotPanel: "sweet_gala/reels/bg/sweet_gala_dialog_jackpot.ccbi"
reconnectPanel: "sweet_gala/reels/bg/sweet_gala_dialog_duanxian.ccbi"
superReconnectPanel: "sweet_gala/reels/bg/sweet_gala_dialog_duanxian_sp.ccbi"
flyItem: "sweet_gala/reels/symbol/sweet_gala_symbol_batch_link_fly.ccbi"
multiplierFly: "sweet_gala/reels/bg/sweet_gala_whee_beishu_add.ccbi"

# 节点命名
potNodes: ["_guo0", "_guo1", "_guo2", "_guo3"]       # 紫绿红蓝
multiplierNodes: ["_multiTL", "_multiBL", "_multiTR", "_multiBR"]
respinTitleNode: "_bonusTitle"
respinCountNodes: ["_bonus0", "_bonus1", ..., "_bonus6"]  # 7 个进度节点

# 动画名
potAnims: ["1", "2", "3", "4", "5", "trigger"]
potUpgradeAnims: ["1_to_2", "2_to_3", "3_to_4", "4_to_5"]
symbolAnims: ["appear", "base", "jiesuan", "drum", "add", "add_2", "add_2_left", "add_2_right"]

# 音效名
sounds: ["304_pot_trigger", "304_pot_retrigger", "304_pot_upgrade", "304_coin_appear"]
```

---

## 四、七阶段流程

```
策划案定稿
    ↓
阶段0: 契约提取（AI + 人工并行，1天）
    ├─ AI 从策划案提取「玩法点矩阵」→ 交策划确认
    ├─ AI 从策划案提取协议字段需求 → 交后端确认/补充
    └─ AI 从策划案提取资产需求 → 交美术确认/补充
    ↓
阶段1: 脚手架生成（AI，5分钟）
    ├─ VSCode 扩展工具生成目录结构
    └─ AI 生成 MachineConfig 骨架
    ↓
阶段2: Scene + Process（AI，30分钟）
    ├─ AI 根据轮盘数/玩法类型生成 Scene 四大重载
    ├─ AI 生成 Process 流水线
    └─ AI 生成 initSlotActions Action 注册
    ↓
阶段3: Action 生成（AI，1-2小时）
    ├─ 逐个玩法点生成 Action
    ├─ triggerFliter ← 策划案规则说明
    ├─ onTrigger flow ← 策划案交互说明
    └─ 帧数/路径用占位符
    ↓
阶段4: Component 生成（AI，30分钟）
    └─ 仅生成需自定义的组件（进房检查、图标层等）
    ↓
阶段5: 契约填充（人工，1小时）
    ├─ 填入协议字段名（替换占位符）
    ├─ 填入 CCB 路径/节点名（替换占位符）
    ├─ 填入音效名（替换占位符）
    └─ 填入帧数（初值，后续调）
    ↓
阶段6: 构建验证 + 调优（人工 + AI，1-2天）
    ├─ 构建通过
    ├─ 运行时测试，AI 协助排查 bug
    └─ 时序微调
```

**效率对比**（以 304 规模关卡为例）：

| 方式 | 耗时 | 说明 |
|---|---|---|
| 纯人工（当前） | 5-8 工作日 | 含查框架、抄旧关、调时序 |
| AI 辅助（本流程） | 2-3 工作日 | 阶段 0-4 由 AI 主导，人工只做阶段 5-6 |

---

## 五、代码模板

### 5.1 MachineConfig 模板

AI 根据策划案轮盘规格填充以下模板，占位符用 `{{}}` 标记：

```javascript
var {Name}MachineConfig{id} = {
    registerDefaultMachineConfig: function (slotMachineScene) {
        // ===== 基础开关 =====
        slotMachineScene.machineConfig.needOnWinLine = {{needOnWinLine}};
        slotMachineScene.machineConfig.isCCBSymbol = true;
        slotMachineScene.machineConfig.simulateRandomSymbol = true;

        // ===== 赢钱线 =====
        slotMachineScene.machineConfig.winLineWidth = {{winLineWidth}};
        slotMachineScene.machineConfig.displayWinLine = {{displayWinLine}};
        slotMachineScene.machineConfig.supportWinLineBlink = {{supportWinLineBlink}};

        // ===== 压暗 =====
        slotMachineScene.machineConfig.needSetSymbolOpacityDuringWinLineBlink = {{needDim}};
        slotMachineScene.machineConfig.symbolOpacityDuringWinLineBlink = {{dimOpacity}};

        // ===== DrumMode =====
        slotMachineScene.machineConfig.useDrumModeComponent = {{useDrum}};

        // ===== 弹板 CCB =====
        slotMachineScene.machineConfig.reconnectPanelCCB = "{{resRootDir}}/reels/bg/{{resRootDir}}_dialog_duanxian.ccbi";

        // ===== 斜切 =====
        slotMachineScene.machineConfig.supportSymbolTransform = [{{panel0Transform}}, {{panel1Transform}}];
        slotMachineScene.machineConfig.xRotateFactors = {{xRotateFactors}};

        // ===== 音效 =====
        slotMachineScene.machineConfig.qianyaoSound = "{{id}}_qianyao";
    }
};
```

### 5.2 Scene 四大重载决策树

AI 根据策划案轮盘规格做决策：

```text
输入：轮盘数 + 玩法类型
│
├─ 轮盘数 = 1（仅 Base）
│  └─ getPanelSpinProcesses: [new PanelSpinProcess(panel0)]
│     changeActivateSpinPanel(0)
│
├─ 轮盘数 = 2（Base + Respin）
│  └─ getPanelSpinProcesses: [panel0, panel1]
│     Respin 触发时 changeActivateSpinPanel(1)
│     需检查多轮盘注意事项清单（见第六节）
│
└─ 轮盘数 = 3（Base + Respin + Super 双盘）
   └─ getPanelSpinProcesses: [panel0, panel1, panel2]
      Super 触发时 changeActivateSpinPanel(2)
      panel2 内含左右两个子盘
      isSuperRespin 全局标志控制数据偏移（col + 5）
```

**Action 注册位置决策**：

| 玩法类型 | 注册位置 | 说明 |
|---|---|---|
| Base 收集类（大锅/进度条） | `columnStopAnimation` (panel 0) | 停轮时触发 |
| Respin 落定类（金饼 appear） | `columnStopAnimation` (panel 1/2) | 停轮时触发 |
| Respin 触发类（红蓝紫绿） | `specialGameComponent` | specialGame 流程 |
| Respin 入场类（弹板+转场） | `bonusGameComponent` | bonus 流程 |
| Respin 结算类 | `specialGameComponent`（末位） | specialGame 流程末尾 |
| Drum 类 | `drumModeComponent` | drum 流程 |

### 5.3 Action 生成模板

每个玩法点生成一个 Action 文件，遵循 [SlotAction-使用规范](/关卡/SlotAction-使用规范)：

```javascript
'use strict';
var SlotAction = require("../../../actions/SlotActon");

/**
 * {{玩法点描述}}
 * @kind {{effect|flow|data|patch}}
 * @triggeredBy {{注册位置}} {{广播/直调}}
 */
var {Name}_{ActionName}Action = SlotAction.extend({
    // ===== 状态属性（规范规则2：状态不外泄到共享对象）=====
    _localFlag: null,

    // ===== triggerFliter（规范规则1：纯查询，无副作用）=====
    triggerFliter: function (fliterData) {
        // {{从策划案"触发条件"列翻译}}
        if (!this.context.currentIsRespin()) return false;
        var spinResult = this.context.getReceivedSpinResult();
        return /* 布尔表达式 */;
    },

    // ===== onTrigger（流程编排）=====
    onTrigger: function (callback, fliterData) {
        var flow = game.slotUtil.createFlow(this, "{ActionName}");
        // {{从策划案"执行流程"列翻译为 pushAsyncCall / pushInstantCall / pushDelayTime}}
        flow.pushAsyncCall(this.step1);
        flow.pushDelayTime({{frames}} / 30);
        flow.pushAsyncCall(this.step2);
        flow.pushInstantCall(callback);
        flow.run();
    },

    // ===== 私有方法 =====
    step1: function (callNext) {
        // {{演出逻辑}}
        callNext && callNext();
    },
});

module.exports = {Name}_{ActionName}Action;
```

### 5.4 onTrigger flow 翻译规则

策划案交互说明 → flow 编排的映射规则：

| 策划案措辞 | flow 方法 | 说明 |
|---|---|---|
| "播放 XX 动画" | `pushInstantCall(this.playXxxAnim)` | 即时执行 |
| "等待动画播完" | `pushDelayTime(N / 30)` | N 帧延迟 |
| "弹板弹出" | `pushAsyncCall(this.showXxxPanel)` | 异步等待弹板关闭 |
| "依次…" / "然后…" | 按顺序 push | flow 保证串行 |
| "同时…" | 同一个 instantCall 里调多个 | 并行 |
| "如果…则…" | instantCall 内 if 判断 | 条件分支 |

---

## 六、多轮盘检查清单

AI 生成 Scene 后自动校验以下 12 项（来自 [多轮盘spin相关注意事项](/关卡/多轮盘spin相关注意事项)）：

| # | 检查项 | 校验方式 |
|---|---|---|
| 1 | `subject_tmpl_id.json` 配置 lines/panels/simulateReels | grep 配置文件 |
| 2 | `editable_config_id.json` 配置 initializeSymbolSequence 等 | grep 配置文件 |
| 3 | `panelIdComponentType` 映射正确 | 检查 Scene 代码 |
| 4 | 二级组件按 panelId 获取 | grep `this.drumModeComponent`（应为按 panelId 获取）|
| 5 | `getReceivedSpinResult` 按 panelId 返回 | 检查是否重写 |
| 6 | `getPanelWinChips` 叠加多轮盘 | 检查是否重写 |
| 7 | `isLastSpinIndex` 或 `spinPanelIndex` 重置 | 检查 handleSpinResult |
| 8 | `spinPanelSubRoundStart` 按 panelId 获取组件 | 检查是否重写 |
| 9 | `showReelEffectForBigWin` 按 panelId 获取组件 | 检查是否重写 |
| 10 | `multiPlayPanelCount` 设置（不用 setMultiPanelCount）| grep `setMultiPanelCount`（应为 0 结果）|
| 11 | `usingFeatureDependentSpinBet` + `getFeatureDependentSpinBet` 重写 | 如不需要 bet 拆分 |
| 12 | `handleSpinResult` 分发 `receivedSpinResultList` | 检查多轮盘数据分发 |

---

## 七、工具需求

| 工具 | 现状 | 需补齐 |
|---|---|---|
| **脚手架生成器** | 已有 VSCode 扩展 | 补充：接受"玩法点矩阵"自动生成 Action 文件骨架 |
| **MachineConfig 模板** | 无 | 新建：带占位符的模板文件 + AI 填充 |
| **协议契约校验器** | 无 | 新建：lint 脚本，检查代码中引用的 `extraInfo.xxx` 字段是否在协议表中 |
| **多轮盘检查器** | 无 | 新建：lint 脚本，自动检查第六节 12 项 |
| **构建验证** | 已有 `build_local_*.sh` | 无需补齐 |

---

## 八、落地路线

| 步骤 | 内容 | 时机 |
|---|---|---|
| **第一步** | 以 304 为黄金样本，固化三张表的格式，写入本文档 | 立即 |
| **第二步** | 下一关开发时，由 AI 按七阶段流程产出，人工只做阶段 0 + 5 + 6，记录产出率和返工点 | 下一关 |
| **第三步** | 根据第二步数据校准自动化率，迭代模板和流程 | 第二步完成后 |

---

## 九、304 文件结构参考

304（Sweet Gala）作为本流程的黄金样本，其目录结构如下：

```text
src/newdesign_slot/scene/304_sweet_gala/
├── 304_action/                          # SlotAction 文件
│   ├── SweetGala_CheckDrumAction.js
│   ├── SweetGala_CollectItemsAction.js
│   ├── SweetGala_DrumModeAction.js
│   ├── SweetGala_LinkColumnStopAniAction.js
│   ├── SweetGala_LinkOverGameAction.js
│   ├── SweetGala_SlowDrumModeAction.js
│   ├── SweetGala_TriggerBlueGameAction.js
│   ├── SweetGala_TriggerGreenGameAction.js
│   ├── SweetGala_TriggerLinkGameAction.js
│   ├── SweetGala_TriggerPurpleGameAction.js
│   └── SweetGala_TriggerRedGameAction.js
├── 304_components/                      # 自定义组件
│   ├── Link_ClassicSymbolTransformComponent.js
│   ├── SweetGala_CellSpinPanelComponent.js
│   ├── SweetGala_EnterRoomBonusCheckingComponent.js
│   └── SweetGala_LinkSymbolLayerComponent.js
├── 304_controller/                      # 控制器
│   └── Link_SymbolController.js
├── 304_process/                         # 流程
│   └── SweetGala_PanelWinUpdateProcess.js
├── SweetGalaMachineConfig304.js         # 关卡配置
└── SweetGalaMachineScene304.js          # 场景主文件
```

**文件分区原则**（来自 [创建新关卡工具使用指南](/关卡/创建新关卡工具使用指南)）：根据功能类型分区存放，禁止把所有代码写到 MachineScene 中。

---

**最后更新**：2026-07-23
**维护者**：赵恒
