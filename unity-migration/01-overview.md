# 01 - 项目概述与迁移目标

[返回目录](00-index.md)

---

## 1.1 源项目概况

### 技术栈

| 项目 | 技术 |
|------|------|
| 引擎 | Cocos2d-html5 v3.13-lite-wtc |
| 语言 | ES5 JavaScript（严格模式）|
| UI 编辑 | CocosBuilder (CCB) |
| 模块化 | Browserify |
| 平台 | iOS/Android (JSB) + Web (Facebook Canvas) |

### 关卡规模

| 分类 | 数量 | 架构基类 | 文件结构 |
|------|------|----------|----------|
| 新架构-模块化 | 11 个 (284-293, 297) | SlotMachineScene2022 | 独立子目录，含 _action/_components/_controller/_process |
| 新架构-单文件 | 84 个 | SlotMachineScene2022 | 单个 MachineScene.js 文件 |
| 遗留架构 | 140 个 | SlotMachineScene / ClassicSlotMachineScene | 单个 MachineScene.js 文件 |
| **合计** | **235 个关卡** | | **413 个 JS 文件** |

### 框架文件规模

| 目录 | 文件数 | 说明 |
|------|--------|------|
| `component_new2022/` | 20 | 2022 版基础组件类 |
| `component/` | 57 | 遗留版组件类 |
| `process/` | 35 | 流程基类（含 FlowDispatcher） |
| `actions/` | 27 | 动作基类（含 SlotAction 注册表） |
| `controller_new2022/` | 16 | 2022 版控制器 |
| `controller/` | 34 | 遗留版控制器 |
| `tools/` | 8 | 工具类（SlotUtil, WinEffectHelper 等） |
| `enum/` | 4 | 枚举定义 |
| **合计** | **201 个框架文件** | |

### 核心架构模式：CPA (Component-Process-Action)

源代码库使用统一的 CPA 架构，所有 2022 架构关卡 100% 遵循：

```
SlotMachineScene2022 (基类)
├── Components (可插拔 UI/逻辑模块)
│   ├── SpinPanelComponent      ── 卷轴面板
│   ├── SymbolLayerComponent    ── 符号层
│   ├── DrumModeComponent       ── 鼓点模式
│   ├── WinLineComponent        ── 赢线
│   ├── ... (20 个基类)
│   └── 关卡自定义组件
├── Processes (状态机流水线)
│   ├── FlowDispatcher          ── 流程引擎
│   ├── WaitForSpinProcess      ── 等待旋转
│   ├── SpinProcess             ── 发送请求
│   ├── ... (35 个基类)
│   └── 关卡自定义流程
└── Actions (可插拔行为)
    ├── FreeSpinAction          ── 免费旋转
    ├── QianyaoAction           ── 期待动画
    ├── ... (27 个基类)
    └── 关卡自定义动作
```

### 主循环流程（FlowDispatcher DSL）

```
EnterRoomChecking
["loop",                              ── 外层循环（永续）
    WaitForSpin                       ── 等待用户点击/自动旋转
    FreeSpinBeginChecking             ── 检查是否进入免费旋转
    RoundStart                        ── 开始一局
    ["loop",                          ── 内层循环（子回合：免费旋转/重转）
        SubRoundStart
        Spin                          ── 发送旋转请求，等待结果
        SpecialGame                   ── 特殊游戏
        Jackpot                       ── 奖池展示
        ShowWinEffect                 ── 大赢/超级赢动画
        BlinkAllWinLine               ── 闪烁赢线
        PanelWinUpdate                ── 赢分更新 UI
        BlinkBonus                    ── 闪烁 Bonus 符号
        BlinkScatter                  ── 闪烁 Scatter 符号
        SubRoundEnd                   ── 子回合结束（ConditionProcess 控制循环退出）
    ],
    RoundEnd                          ── 结束一局，结算
    FreeSpinEndChecking               ── 检查免费旋转是否结束
    InteractiveGameChecking           ── 互动游戏检查
]
```

---

## 1.2 迁移范围

### 本期范围

**95 个 SlotMachineScene2022 架构关卡**，包括：
- 11 个模块化关卡（284-293, 297）：独立子目录结构，共 184 个 JS 文件
- 84 个单文件关卡：各自一个 MachineScene.js 文件

### 不在本期范围

- 140 个遗留架构关卡（使用 SlotMachineScene / ClassicSlotMachineScene）
- 活动系统（Activity）、社交系统（CardSystem）、支付系统等非 Slot 模块
- 服务端逻辑（协议层保持不变，客户端只做展示层迁移）

### 范围选择理由

1. **统一架构**：95 个 2022 关卡 100% 共享同一套 CPA 框架，迁移模式高度一致
2. **投入产出比**：覆盖约 40% 的关卡数量，但覆盖近 100% 的新开发关卡
3. **验证优先**：先用统一架构验证流水线，再考虑遗留架构的适配方案

---

## 1.3 迁移目标

### 功能目标

| 目标 | 说明 |
|------|------|
| **功能一致** | 迁移后的 Unity 关卡在玩法、表现上与 Cocos 版本一致 |
| **协议兼容** | 复用现有服务端协议，客户端仅做展示层替换 |
| **性能达标** | Unity 版本性能不低于 Cocos 版本 |

### 工程目标

| 目标 | 说明 |
|------|------|
| **可批量转换** | 建立 4 层架构使关卡逻辑可近乎机械化翻译 |
| **可 AI 协作** | 制定明确的执行规范，使 AI 能独立完成单关卡转换 |
| **可追溯** | 每个 JS API → C# 方法的映射有完整记录，可查可验 |
| **可渐进** | L1 + L2 先独立完成并验证，再逐步推进关卡转换 |

### 质量目标

| 目标 | 说明 |
|------|------|
| **零遗漏映射** | 所有被调用的 JS API 必须有对应的 C# 实现 |
| **零 TODO 交付** | 每层交付时不允许有 TODO 占位符 |
| **双关卡验证** | L1+L2 完成后至少转换 2 个关卡验证流水线有效性 |

---

## 1.4 关键约束

| 约束 | 说明 |
|------|------|
| Unity 版本 | Unity 6（LTS） |
| C# 版本 | C# 9.0+（Unity 6 支持） |
| 补间动画 | DOTween Pro（已决策，替代 cc.Action 体系） |
| 渲染管线 | 待定（不影响本方案的逻辑层迁移） |
| UI 框架 | 待定（Prefab 替代 CCB，NameBinder 替代 controller 绑定） |

---

## 1.5 Cocos API 调用量全景

以下是源代码库中各命名空间的 API 调用量统计，这是 L1 兼容层设计的基础数据：

| 命名空间 | 定义文件 | 唯一方法数 | 总调用次数 |
|----------|----------|-----------|-----------|
| `game.util.*` | `src/common/util/Util.js` (1805 行) | 78 | ~31,237 |
| `game.nodeHelper.*` | `src/common/util/NodeHelper.js` (491 行) | 23 | ~17,283 |
| `game.slotUtil.*` | `src/newdesign_slot/tools/SlotUtil.js` (1211 行) | 62 | ~10,199 |
| `game.aUtil.*` | `src/task/tools/ActivityUtil.js` (1784 行) | 74 | ~5,275 |
| `cc.*` Actions | Cocos 引擎内置 | 27 + 17 easing | ~9,256 |
| `cc.*` 几何/类型 | Cocos 引擎内置 | ~30 | ~14,000+ |
| `.controller.*` | CCB 绑定模式 | — | ~24,000 |
| `.runAction()` | Cocos 引擎内置 | 1 | ~3,124 |
| `game.uIHelper.*` | `src/common/util/UIHelper.js` (1222 行) | 34 | 待统计 |
| `game.aUIHelper.*` | `src/task/tools/ActivityUIHelper.js` (1100+ 行) | 35 | 待统计 |
| `game.eventDispatcher.*` | `src/common/events/EventDispatcher.js` (197 行) | 3+ | ~167 |
| `game.audioPlayer.*` | `src/common/audio/AudioPlayer.js` (381 行) | 15+ | 待统计 |
| 其他辅助类 | 各自独立 | ~30 | 待统计 |
| **合计** | | **~400+** | **~114,000+** |

### 调用集中度

**Top 20 API 覆盖约 65% 的总调用量**：

| 排名 | API | 调用次数 |
|------|-----|----------|
| 1 | `game.nodeHelper.setNodeVisible` | 10,105 |
| 2 | `game.util.playAnim` | 7,369 |
| 3 | `cc.p()` | 4,815 |
| 4 | `game.util.inherits` | 4,170（C# 不需要） |
| 5 | `cc.sys.isObjectValid` | 4,108 |
| 6 | `game.slotUtil.playAnim` | 3,927 |
| 7 | `cc.callFunc()` | 2,781 |
| 8 | `game.util.playCCBAnimation` | 2,647 |
| 9 | `game.util.registerController` | 2,561 |
| 10 | `game.util.unRegisterController` | 2,547 |
| 11 | `cc.delayTime()` | 2,373 |
| 12 | `cc.sequence()` | 2,183 |
| 13 | `game.util.loadNodeFromCCB` | 2,186 |
| 14 | `game.nodeHelper.setNodeText` | 2,692 |
| 15 | `game.nodeHelper.setNodeEnabled` | 1,929 |
| 16 | `game.slotUtil.playEffect` | 1,566 |
| 17 | `game.slotUtil.delayCall` | 1,312 |
| 18 | `game.aUtil.setNodeTextAutoScale` | 1,248 |
| 19 | `cc.isFunction()` | 1,103 |
| 20 | `cc.isUndefined()` | 998 |

---

## 1.6 JS 源文件清单

### 框架文件

```
src/newdesign_slot/
├── scene/
│   ├── SlotMachineScene.js              # 基类（原始版）
│   ├── SlotMachineScene2022.js          # 基类（2022 版，所有新关卡继承此类）
│   ├── NewSlotMachineScene.js           # 包装基类
│   └── SlotMultiPanelMachineScene.js    # 多面板变体基类
├── component/Component.js               # 组件基类
├── component_new2022/                   # 20 个 2022 版基础组件
├── process/Process.js                   # 流程基类
├── process/FlowDispatcher.js            # 流程引擎
├── process/                             # 35 个流程类
├── actions/SlotActon.js                 # 动作基类
├── actions/SlotActionEasy.js            # 轻量动作基类
├── actions/QianyaoAction.js             # 期待动画动作
├── actions/SlotActionRegistry.js        # SA/SAT 注册表
├── actions/                             # 27 个动作类
├── enum/                                # 4 个枚举文件
└── tools/                               # 8 个工具文件
```

### 工具库文件

```
src/common/util/
├── Util.js              # game.util（1805 行，78 方法）
├── NodeHelper.js        # game.nodeHelper（491 行，23 方法）
└── UIHelper.js          # game.uIHelper（1222 行，34 方法）

src/task/tools/
├── ActivityUtil.js      # game.aUtil（1784 行，74 方法）
└── ActivityUIHelper.js  # game.aUIHelper（1100+ 行，35 方法）

src/newdesign_slot/tools/
├── SlotUtil.js          # game.slotUtil（1211 行，62 方法）
├── HighRollerSlotUtil.js
├── SlotPopupUtil.js
└── WinEffectHelper.js

src/common/events/EventDispatcher.js
src/common/audio/AudioPlayer.js
src/common/popup/DialogManager.js
src/gameCommon.js                    # 全局命名空间注册中心（125 行）
```

### 11 个模块化关卡目录

| 关卡 | 目录 | JS 文件数 |
|------|------|----------|
| 284 Santa Giftstorm | `scene/284_santa_giftstorm/` | 21 |
| 285 Carnival Blast | `scene/285_carnival_blast/` | 13 |
| 286 Halo and Horns | `scene/286_halo_and_horns/` | 13 |
| 287 Wilds Starburst | `scene/287_wilds_starburst/` | 16 |
| 288 Three Little Piggies | `scene/288_three_little_piggies/` | 17 |
| 289 Yay Yeti Glitzy | `scene/289_yay_yeti_glitzy/` | 19 |
| 290 Dazzling Diamonds | `scene/290_dazzling_diamonds/` | 23 |
| 291 Ducky Dollars | `scene/291_ducky_dollars/` | 19 |
| 292 Rose Romance | `scene/292_rose_romance/` | 9 |
| 293 Trio Wheels Deluxe | `scene/293_trio_wheels_deluxe/` | 16 |
| 297 Goldpot Party | `scene/297_goldpot_party/` | 18 |

---

[下一章：02 - 4 层架构设计方案](02-architecture.md)
