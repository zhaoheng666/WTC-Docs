# AI 关卡产出蓝图模板

**蓝图版本**：2.0  
**评审基线**：304 Sweet Gala  
**复核日期**：2026-07-24  
**适用范围**：`src/newdesign_slot/scene/` 下包含 Base / Link / Respin / 收集 / 多轮盘玩法的客户端关卡包

**可视化总览**：[AI 关卡产出蓝图可视化](/关卡/AI关卡产出蓝图可视化.html)  
**关联文档**：[304-SweetGala-可视化手册](/关卡/304-SweetGala-可视化手册)、[304-sweet-gala-研发手册](/关卡/304-sweet-gala-研发手册)、[AI关卡研发流程](/关卡/AI关卡研发流程)

---

## 一、交付定义

本文件不是玩法摘要，也不是供 Agent 自由发挥的提示词。它是从策划案、协议、框架、关卡源码、配置、CCB 和资源清单编译出的**代码生成合约**。

Agent 只有同时满足以下条件，才可以声明关卡产出完成：

1. 所有输入证据已登记，散落在 PDF、代码、配置和资源中的事实均可追溯。
2. 所有冲突均有唯一决议；不存在 `blocking: true` 且未决的条目。
3. 需求、实体、状态机、流程节点、Action、方法、协议字段、资源和测试之间可双向追踪。
4. `fileManifest` 中的每个文件和 `requiredMethods` 均已产出。
5. `machineConfigSnapshot` 中的有效赋值和设备分支均已产出。
6. 通用 Process 链、自定义 Action 链、回调边界和异常分支均闭环。
7. 最终代码可加载、可进入 Base、可进入/退出普通 Respin 和 Super Respin，并能重连。
8. 最终代码、配置和资源引用中不存在 `__TODO__`、占位实现、空回调或臆造字段。
9. 自动检查和运行验收全部通过，并输出机器可读的覆盖报告。

生成过程允许在“证据整理阶段”记录缺口，但**最终交付不允许带缺口运行**。如果缺失信息会影响行为、金额、坐标、时序或资源加载，Agent 必须停止生成并输出阻断报告。

---

## 二、证据与裁决

### 2.1 证据类型

| 证据类型 | 决定内容 | 304 样本 |
|---|---|---|
| `productSpec` | 玩法意图、顺序、文案、视觉验收 | 89 页 Sweet Gala 策划案 PDF |
| `serverContract` | 结果、金额、概率、RTP、Feature 数据 | `SpinPanel.extraInfo`、`RespinInfo`、`BonusInfo` |
| `frameworkSource` | 生命周期、Process、Component API、回调约束 | `SlotMachineScene2022`、通用 Process / Component |
| `levelSource` | 当前有效实现及兼容行为 | `304_sweet_gala` 下 19 个源码文件 |
| `runtimeConfig` | Panel、符号、赔率展示、转轴、MachineConfig | `subject_tmpl_*`、`editable_config_304`、MachineConfig |
| `presentationAsset` | CCB 节点、动画序列、贴图、字体、音效 | 每主题 234 个资源 |
| `acceptanceEvidence` | 真机录像、日志、协议样例、测试结果 | 生成前必须补入 `verificationEvidence` |

### 2.2 权威规则

不能使用简单的“代码优先”或“策划优先”。必须按字段归属裁决：

- 玩法目标和交互顺序由已批准 `productSpec` 决定。
- 中奖结果、概率、RTP、JP 和 Feature 数值由 `serverContract` 决定；客户端不得重算或随机决定。
- Process 顺序、生命周期、回调签名由 `frameworkSource` 决定。
- CCB 路径、节点名、动画名由可加载的 `presentationAsset` 决定。
- 当前 `levelSource` 是实现证据，不自动等于目标真相；与策划冲突时必须进入 `conflictLedger`。
- 配置和源码不一致时，必须同时修正或明确单一 owner，禁止只修一侧。
- 无法裁决时设置 `blocking: true`，禁止继续写代码。

### 2.3 304 已审计输入

```yaml
sourceCatalog:
  productSpec:
    path: "/Users/ghost/Downloads/文档/Q1’26-slots-关卡304：Sweet Gala .pdf"
    pages: 89
    sha256: eeef75467e2850ae1491a37d2dc22e069199bcb55f3a8421023d03a01f251546
    reviewedPages:
      fullVisualReview: "1-89"
      gameplayAndFlow: "4-19"
      paytableAndMath: "61-72"
  levelSource:
    root: src/newdesign_slot/scene/304_sweet_gala
    files: 19
    composition: { scene: 1, config: 1, actions: 11, components: 4, controllers: 1, processes: 1 }
  runtimeConfig:
    editable:
      path: res_*/config/editable_config_list/editable_config_304.json
      themeParity: true
      sha256: 0f703d95d9c9a0205f278a4ec6c705d20971bc8dfb75633642c7f8ad114800b5
    subjectTemplates:
      - res_*/config/subject_tmpl_list/subject_tmpl_304.json
      - res_*/config/subject_tmpl_list/subject_tmpl_204304.json
    templateIdDifference: "304 与 204304 仅 subjectTmplId 不同"
    themeDifferences:
      - "spinUiTitleName: casino/casino_ui_title -> casino/ui_title"
      - "doublehit 增加 dailyMissionStyle / dailyMissionOffset"
  presentationAsset:
    themes: [res_oldvegas, res_doublehit]
    perThemeFiles: 234
    byType: { ccbi: 71, png: 83, plist: 37, mp3: 30, fnt: 10, jpg: 3 }
    parity: "关卡资源文件列表一致；主题级 UI 配置差异单独保留"
```

## 三、评审发现与冲突决议

以下决议是 304 的代码生成目标，不应被现有实现中的偏差覆盖。

| ID | 冲突 / 风险 | 证据 | 生成目标 | Owner | 状态 |
|---|---|---|---|---|---|
| `CF-304-01` | Super 触发写有第 7 次和第 10 次两种口径 | PDF 多处第 7 次；p.17 旧图写第 10 次；代码固定 7 节点；赔率页写 Step 7 | 统一为第 7 次；第 10 次视为过期图文 | 策划/客户端/文案 | 已决 |
| `CF-304-02` | 策划对紫锅双金饼“独立加值”和“每格仅一个加值”表述冲突 | PDF p.13；现有 Action 支持 index 0/1 | 后端下发 `purpleAddInfoList` 是唯一结果；客户端逐条执行，可处理两个 index，不做随机选择 | 服务端/客户端 | 客户端已决 |
| `CF-304-03` | 文档使用 3×5，项目配置使用 5×3 | PDF 行×列口径；代码列×行口径 | 蓝图一律 `cols x rows`，普通 Respin=`5x3` | 全链路 | 已决 |
| `CF-304-04` | 入场弹板时序不一致 | 策划：普通手点 START，Super 3 秒自动；现有代码两者都 2 秒后转场 | 普通仅在确认/消失回调后转场；Super 自动 3 秒后转场；回调只完成一次 | 客户端/CCB | 目标已定 |
| `CF-304-05` | 结算顺序自然语言可能被实现成不同遍历 | PDF p.16“从上到下从左到右”；现有 comparator 为列升序、后端行降序 | 固定 comparator：`col asc -> backend row desc -> index asc`，双槽 index0 后 index1 | 客户端/验收 | 已决 |
| `CF-304-06` | 结算弹板关闭与回 Base 未绑定 | 策划：关闭后转场；现有代码展示弹板后独立延时调用 `respin2Base` | `respin2Base` 只由弹板 disappear/confirm 完成回调触发；超时仅作幂等 watchdog | 客户端 | 必修 |
| `CF-304-07` | Grand 判定可能被客户端按满盘重算 | 策划：15 格满触发；源码使用 `linkJackpotWin > 0` | 服务端结果权威；客户端仅展示并可记录“协议 Grand 与满盘不一致”诊断，不改奖 | 服务端/客户端 | 已决 |
| `CF-304-08` | 赔率配置八组均为 10，与策划赔率表不一致 | PDF p.61；`subject_tmpl_304.specialPayTables` | 生成配置使用 `50/30/20/10/10/7/5/2`；发布前同时核对服务端数学和 FAQ | 策划/服务端/配置 | 必修 |
| `CF-304-09` | Average Bet 文案提到 1~10 次平均，实际协议直接下发 | PDF p.17；`extraInfo.avgTotalBet` | 客户端只消费服务端 `avgTotalBet`，禁止按本地历史下注重算 | 服务端/客户端 | 已决 |
| `CF-304-10` | 紫色 Action 文件无 `.js` 后缀 | 现有文件和 `require` 可运行 | 304 对账模式保留精确路径；新关卡统一 `.js`，迁移必须同一提交改文件和 require | 客户端 | 兼容项 |

发布 304 前，`CF-304-04`、`CF-304-06`、`CF-304-08` 必须有代码/配置改动或正式变更单；蓝图生成器不得把现有偏差复制为新标准。

---

## 四、关卡包模型

一个可生成的 `levelPackage` 必须同时包含以下 12 层：

| 层 | 必须回答的问题 | 机器产物 |
|---|---|---|
| 证据层 | 每条事实来自哪里、版本和 hash 是什么 | `sourceCatalog` |
| 决议层 | 冲突选择什么、谁负责、是否阻断 | `authorityPolicy`、`conflictLedger` |
| 身份层 | slot、scene、目录、主题、注册入口是什么 | `identity` |
| 玩法层 | 触发、循环、结算、恢复的规则是什么 | `requirementLedger`、`mechanics` |
| 轮盘层 | Panel、列行、坐标、左右盘如何映射 | `panels`、`coordinateSystem` |
| 符号层 | ID、语义、动画、Controller、允许出现条件 | `symbols` |
| 协议层 | 服务端字段、类型、不变量、默认和 owner | `protocol` |
| 实体层 | 状态属于谁、生命周期和读写者是谁 | `entities`、`stateMachines` |
| 行为层 | Process、Action、方法、guard、副作用是什么 | `runtimeTimeline`、`actionRegistry` |
| 表现层 | CCB、节点、动画、音效、时序如何绑定 | `resources`、`timing` |
| 产出层 | 文件、继承、方法、依赖和生成顺序是什么 | `fileManifest`、`codeGenerationPlan` |
| 验收层 | 如何证明完整、可运行、无回归 | `acceptanceScenarios`、`validationGates` |

### 4.1 生成流水线

```mermaid
flowchart LR
    A[Discover 读取全部证据] --> B[Normalize 统一 ID/坐标/术语]
    B --> C[Resolve 冲突裁决]
    C --> D[Model 需求/实体/状态机]
    D --> E[Compile 编译时序与节点图]
    E --> F[Scaffold 生成全部文件骨架]
    F --> G[Implement 按依赖实现]
    G --> H[Static Verify 静态门禁]
    H --> I[Runtime Verify 运行验收]
    I --> J[Report 覆盖与证据报告]
    C -->|存在 blocking 未决项| X[停止并输出阻断报告]
```

每一阶段必须有明确输入、输出和退出条件：

| 阶段 | 输入 | 输出 | 退出条件 |
|---|---|---|---|
| Discover | PDF、代码、配置、协议、资源 | `sourceCatalog` | 文件可读、hash/版本可追溯 |
| Normalize | 原始术语和数据 | 统一的 `cols x rows`、ID、owner | 无同义词或坐标歧义 |
| Resolve | 差异清单 | `conflictLedger` | 所有 client-blocking 项已决 |
| Model | 已决需求 | 实体、状态机、协议、不变量 | 每条需求可映射到模型 |
| Compile | 模型 | 完整时序节点和边 | 所有节点可达、所有边端点存在 |
| Scaffold | 文件清单 | 完整文件/方法签名 | 19/19 文件、方法无遗漏 |
| Implement | 行为合约 | 可加载代码和配置 | 无占位、回调闭环、资源存在 |
| Static Verify | 代码/配置 | lint、require、字段、资源报告 | 所有硬门禁通过 |
| Runtime Verify | 构建产物/协议夹具 | 场景验收结果 | Base/Respin/Super/重连全部通过 |
| Report | 全部产物 | 覆盖矩阵和变更摘要 | 需求到测试覆盖率 100% |

---

## 五、304 需求基线

### 5.1 玩法与责任边界

| Requirement ID | 目标行为 | Owner | 主要证据 |
|---|---|---|---|
| `REQ-304-001` | Base 为 3×3、5 条线，空符号参与盘面但不参与中奖 | client config + server | PDF p.4-10、subject template |
| `REQ-304-002` | Wild 为 1；倍数 Wild 为 1101/1102/1103/1104，对应 2x/5x/10x/50x | client config + server | PDF、subject template |
| `REQ-304-003` | 紫/绿/红/蓝/彩糖为 1200~1204；彩糖可给所有未满锅增加进度 | server result + client presentation | PDF p.7-13、symbol config |
| `REQ-304-004` | 大锅等级使用协议 0~4；CCB 序列为 1~5；4 表示激活 | server + client | PDF、CollectItemsAction |
| `REQ-304-005` | Base 糖果飞锅与升级不阻断下一次 SPIN 节奏 | client | PDF、CollectItemsAction |
| `REQ-304-006` | R1/R2 同一赢钱线有任意有效符号与 10x/50x Wild 时，R3 慢 Drum | client | PDF、SlowDrumModeAction |
| `REQ-304-007` | Link 是否触发、初始金饼、颜色锅、后续 respin 全由协议决定 | server | `extraInfo.respinInfo` |
| `REQ-304-008` | 普通 Respin 为 5×3；Super 是左右两个 5×3，视觉总布局 10×3 | client config | PDF、subject template |
| `REQ-304-009` | Super 第 7 次触发；初始左盘金饼镜像到右盘；后续右盘只读 `secondRespinInfo` | server + client | PDF、Scene/TriggerLink |
| `REQ-304-010` | 普通初始次数为 3，绿锅激活为 4；任意新图标落定恢复对应盘次数 | server + client | PDF、counter methods |
| `REQ-304-011` | Respin 只允许未触发颜色糖果；仍有未触发锅时才允许彩糖 | server result filter + client safety filter | LinkSymbolLayer |
| `REQ-304-012` | 新糖果先播放糖变饼表现，再作为 1501 锁定 | client | PDF、LinkColumnStop action |
| `REQ-304-013` | 再触发固定顺序：红 -> 蓝 -> 紫 -> 绿 -> 差一格 Drum -> 结束判断 | client | PDF、actionRegistry |
| `REQ-304-014` | 红锅把已有单饼变双饼；左下 index0 先结算，右上 index1 后结算 | server + client | PDF、Red/Settlement actions |
| `REQ-304-015` | 紫锅只执行 `purpleAddInfoList`；目标槽位和加值由服务端决定 | server + client | PDF、Purple action |
| `REQ-304-016` | 绿锅将计数器由 3 升为 4，并恢复剩余次数 | server + client | PDF、Green action |
| `REQ-304-017` | 蓝区有 4 个共享边连通区；每区 2~6 格，横向<=3、纵向<=2；倍数 x2~x5 | server validation + client render | PDF p.11-16 |
| `REQ-304-018` | 蓝区填满时先倍数飞入、砸盘、区域内奖励更新，再进入逐币结算 | client | PDF、LinkOver action |
| `REQ-304-019` | 每个 5×3 盘只剩一格空且不是最后一轮时，对空格播放 Drum | client | PDF、CheckDrum action |
| `REQ-304-020` | 15 格满对应 Grand；奖项金额由服务端 `linkJackpotWin` 权威返回 | server + client presentation | PDF、LinkOver action |
| `REQ-304-021` | JP：Grand progressive 500x、Major 25x、Minor 10x、Mini 5x | server + client display | PDF p.61-72 |
| `REQ-304-022` | 结算 comparator 为 col 升序、后端 row 降序、index 升序 | client | PDF p.16、buildSortedSettlementList |
| `REQ-304-023` | Super 金额使用服务端 `avgTotalBet`；普通 Respin 使用触发时 Total Bet | server + client | Scene bet methods |
| `REQ-304-024` | 普通与 Super 分别使用独立入场、结束、重连表现 | client + CCB | PDF、resource package |
| `REQ-304-025` | 回 Base 必须清锁列、蓝区、锅、计数器、平均 bet、BGM、活动入口和 bonus record | client | LinkOver `respin2Base` |
| `REQ-304-026` | 前摇概率、RTP、Feature 触发率由服务端/数学配置决定，客户端只消费结果 | server/math | PDF p.61-72 |
| `REQ-304-027` | 八组 Base 赔率依次为 50/30/20/10/10/7/5/2 | server + config + FAQ | PDF p.61、`CF-304-08` |

### 5.2 实体模型

| Entity ID | Owner | 核心状态 | 生命周期 |
|---|---|---|---|
| `Panel` | Scene/SpinPanelComponent | active panel、panel0/1/2 | scene |
| `LinkSession` | MachineScene | `respinTriggered`、`respinIndex`、`isSuperRespin`、`linkData` | feature |
| `CollectPot` | MachineScene | `mCollectLevels`、`mOldCollectLevels`、`triggerLinkType` | room + feature |
| `RespinProgress` | MachineScene | `mCollectTriggerTimes`、7 个进度节点 | room |
| `RespinCounter` | MachineScene | left/right index、all respin count | feature |
| `LinkBoard` | MachineScene/SpinPanel | left/right occupied map、locked categories | feature |
| `LinkCoin` | `Link_SymbolController` | `BonusInfo`、slot0/1、AddMulti | symbol pool item |
| `ColorFeature` | special Action sequence | purple/green/red/blue trigger flags | respin step |
| `BlueAreaRegion` | MachineScene | left/right BlueArea、cell color | feature |
| `MultiplierCorner` | MachineScene/CCB | x2/x3/x4/x5 corner node | feature |
| `RegionLineLayer` | MachineScene/CCB | border and glow lines | feature |
| `SettlementQueue` | LinkOverAction | sorted coin queue、current win、JP | settlement |
| `PopupPanel` | BasePopupPanelController | start/end/JP/reconnect callback | transient |
| `BetMode` | MachineScene/SpinUI | `respinAvgTotalBet`、`_useAverageBet` | feature |
| `DrumProbe` | Drum Actions | base slow drum、respin one-empty drum | subround |
| `WinUpdateProcess` | PanelWinUpdateProcess | win label and settled amount | subround |

实体硬约束：

- 共享状态只能由 owner 创建和清理，Action 不得临时发明跨轮字段。
- `triggerFliter` 只读；所有状态写入必须发生在 `onTrigger` 或明确的 Scene 生命周期函数。
- `LinkCoin.reset` 必须重置节点可见性、颜色、AddMulti 和数字动画，防止对象池脏状态。
- `LinkSession` 和 `BetMode` 的清理必须幂等，重复调用不得扣款、加奖或二次跳转。

---

## 六、规范化生成蓝图

下面的 YAML 是 304 的参考实例。新关卡必须保留字段结构并替换值，不得删除未使用层；未使用能力应显式写 `enabled: false`。

```yaml
blueprint:
  schemaVersion: "2.0"
  blueprintId: slot-304-sweet-gala
  generationMode: reconcile-existing
  zeroPlaceholderPolicy: true

  identity:
    slotId: 304
    subjectTemplateIds: [304, 204304]
    sceneTypeId: 1304
    name: SweetGala
    codeRoot: src/newdesign_slot/scene/304_sweet_gala
    resRootDir: sweet_gala
    themes: [res_oldvegas, res_doublehit]

  ownership:
    server:
      - spin outcome and pay result
      - RTP / hit rate / qianyao probability
      - respin length and left/right SpinInfo
      - BonusInfo / purpleAddInfoList / BlueArea / jackpotWin / avgTotalBet
    client:
      - Process and Action order
      - panel switching and coordinate transforms
      - animation/audio timing and callback completion
      - rendering, sorting, cleanup and reconnect presentation
    art:
      - CCB node names and animation sequences
      - sprites, fonts, audio files and panel copy
    framework:
      - lifecycle and ComponentType contracts
      - Process blockers and SlotAction callback contract

  panels:
    - { id: 0, name: Base, cols: 3, rows: 3, component: ClassicSpinPanelComponent, symbolLayer: ClassicSymbolLayerComponent }
    - { id: 1, name: Respin, cols: 5, rows: 3, component: SweetGala_CellSpinPanelComponent, symbolLayer: SweetGala_LinkSymbolLayerComponent }
    - { id: 2, name: SuperRespin, cols: 10, rows: 3, component: SweetGala_CellSpinPanelComponent, symbolLayer: SweetGala_LinkSymbolLayerComponent, logicalBoards: 2 }

  coordinateSystem:
    notation: cols-x-rows
    backendPosition: { colOrigin: left, rowOrigin: bottom }
    visualPosition: { colOrigin: left, rowOrigin: top }
    linkFlattenedStopIndex: "col * 3 + (2 - backendRow)"
    blueAreaCellId: "localCol * 3 + backendRow"
    blueAreaVisualRow: "rows - 1 - backendRow"
    superRight:
      resultColOffset: 5
      localBlueAreaColOffset: 0
      flattenedBoundary: 15
    settlementComparator:
      - "pos.col ascending"
      - "pos.row descending"
      - "index ascending"

  symbols:
    base:
      1: Wild
      3: Empty
      1001: Red7
      1002: Blue7
      1003: Green7
      1004: 3Bar
      1005: 2Bar
      1006: Bar
    multiplierWild: { 1101: 2, 1102: 5, 1103: 10, 1104: 50 }
    candy: { 1200: purple, 1201: green, 1202: red, 1203: blue, 1204: rainbow }
    link: { 1500: legacyFreeLink, 1501: LinkCoin, 1502: RespinEmpty }
    colorIndex: { 0: purple, 1: green, 2: red, 3: blue, 4: rainbow }
    linkCoinType: { 1: coin, 2: jackpot }
    allowedDuringRespin:
      rule: "1501 + only untriggered candy colors; rainbow only if at least one color remains untriggered"
      clientSafetyMethod: SweetGala_LinkSymbolLayerComponent.localCheckSymbolIDIsValid

  paytable:
    lineCount: 5
    lines:
      - [1, 1, 1]
      - [0, 0, 0]
      - [2, 2, 2]
      - [0, 1, 2]
      - [2, 1, 0]
    specialPays:
      - { symbols: [1001, 1001, 1001], pay: 50 }
      - { symbols: [1002, 1002, 1002], pay: 30 }
      - { symbols: [1003, 1003, 1003], pay: 20 }
      - { symbols: [any7, any7, any7], pay: 10 }
      - { symbols: [1004, 1004, 1004], pay: 10 }
      - { symbols: [1005, 1005, 1005], pay: 7 }
      - { symbols: [1006, 1006, 1006], pay: 5 }
      - { symbols: [anyBar, anyBar, anyBar], pay: 2 }
    sourceConflict: CF-304-08

  protocol:
    authoritativeRoot: SpinPanel
    roomEnterInfo:
      subjectRoomExtraInfo.collectLevels: "int[4]"
      subjectRoomExtraInfo.collectTriggerTimes: int
      subjectRoomExtraInfo.fakeJackpotConfig: "number[4]; mini/minor/major/grand ratios"
      bonusRecord: "[link_game|super_link_game, ...] | []"
    extraInfo:
      collectLevels: "int[4]; range 0..4; order purple/green/red/blue"
      collectTriggerTimes: "int; target Super step 7"
      bonusInfoList: "CollectBonusInfo[]"
      triggeredColorFlags: "int[4]; each 0|1"
      isSuperRespin: "bool|0|1"
      avgTotalBet: "number >= 0; server authoritative"
      initBonusInfoList: "BonusInfo[]"
      initBlueArea: "BlueArea|null"
      secondInitBlueArea: "BlueArea|null; Super only"
      respinInfo: "RespinInfo"
      secondRespinInfo: "RespinInfo|null; Super only"
      clearCollectLevels: "int[4]"
      clearCollectTriggerTimes: "int"
      jackpotSymbolPositionsMap: "framework JP/drum lookup map; optional"
    RespinInfo:
      respins: "SpinInfo[]"
      finalBonusInfoList: "BonusInfo[]"
      blueArea: "BlueArea|null"
    SpinInfo:
      newBonusInfoList: "BonusInfo[]"
      purpleAddInfoList: "PurpleAddInfo[]"
      reTriggerColors: "int[]"
      reTriggerRedBonusInfoList: "BonusInfo[]"
      reTriggerBlueArea: "BlueArea|null"
    BonusInfo:
      pos: "{col:int,row:int}"
      color: "0..4"
      type: "1|2"
      param: number
      finalParam: number
      index: "0|1"
    PurpleAddInfo:
      toPos: "{col:int,row:int}"
      index: "0|1"
      param: number
    BlueArea:
      shape: "{x2?: CellMap, x3?: CellMap, x4?: CellMap, x5?: CellMap}"
      CellMap: "Record<cellId, boolean>"
      validation:
        - product layout targets 4 logical zones; protocol may contain a subset of x2..x5 keys
        - each present multiplier key maps to one region in the current protocol shape
        - each present region has 2..6 cells
        - cells are edge-connected
        - horizontal span <= 3
        - vertical span <= 2
    spinPanelRoot:
      chips: number
      extraChips: number
      jackpotWin: number
      jackpotTriggered: bool
      winLevel: int
    derivedAtPreprocess:
      linkJackpotWin: "original spinPanel.jackpotWin before zeroing base result"
      mergeInitBonusInfoList: "merge by pos; merge duplicate same index/type; sort index asc; max two slots"
      finalBonusInfoList: "respinInfo.finalBonusInfoList"
      blueArea: "respinInfo.blueArea"
      secondfinalBonusInfoList: "secondRespinInfo?.finalBonusInfoList || []"
      secondblueArea: "secondRespinInfo?.blueArea || {}"
    invariants:
      - final outcomes are never generated by client RNG
      - right subsequent results come only from secondRespinInfo
      - initial Super coin layout mirrors left list with colOffset 5
      - only final synthetic SpinPanel carries final settlement and clear fields
      - missing optional arrays normalize to [] and optional areas normalize to null/{}

  stateMachines:
    LinkSession:
      initial: BASE_IDLE
      states: [BASE_IDLE, LINK_DETECTED, ENTRY_PRESENTING, RESPIN_ACTIVE, SETTLING, RETURNING, BASE_IDLE]
      transitions:
        - "BASE_IDLE -> LINK_DETECTED: isTriggerLink()"
        - "LINK_DETECTED -> ENTRY_PRESENTING: BlinkBonusProcess invokes TriggerLink"
        - "ENTRY_PRESENTING -> RESPIN_ACTIVE: panel switch callback completed exactly once"
        - "RESPIN_ACTIVE -> RESPIN_ACTIVE: next synthetic respin"
        - "RESPIN_ACTIVE -> SETTLING: isLastSpinIndex"
        - "SETTLING -> RETURNING: end panel disappear/confirm callback"
        - "RETURNING -> BASE_IDLE: idempotent respin2Base cleanup complete"
    RespinCounter:
      initial: "3 or 4 from triggeredColorFlags[1]"
      onSubRoundStart: decrement
      onNewSymbol: restore corresponding board to max
      onGreenRetrigger: upgrade 3 to 4 and restore
      superIsolation: left and right counters update independently
    CollectPot:
      levels: [0, 1, 2, 3, 4]
      ccbSequences: ["1", "2", "3", "4", "5"]
      activated: 4
      rainbow: applies to every still-eligible pot

  processChain:
    outer:
      - EnterRoomCheckingProcess
      - WaitForSpinProcess
      - FreeSpinBeginCheckingProcess
      - RoundStartProcess
      - subRoundLoop
      - PreRoundEndProcess
      - RoundEndProcess
      - FreeSpinEndCheckingProcess
      - CouponFreeSpinCheckingProcess
      - InteractiveGameCheckingProcess
      - ShowInterstitialAdProcess
    subRoundLoop:
      - SubRoundStartProcess
      - SpinProcess
      - CloverClashWaitProcess
      - SpecialGameProcess
      - JackpotProcess
      - LevelUpProcess
      - VipLevelUpProcess
      - BlinkAllWinLineProcess
      - SpinResultDelayMultiUpProcess
      - ShowWinEffectProcess
      - SweetGala_PanelWinUpdateProcess
      - BlinkBonusProcess
      - BlinkScatterProcess
      - SubRoundEndProcess

  actionRegistry:
    roomParse: [FakeJackpotParseAction]
    qianyao: [QianyaoAction]
    slowDrum: [SweetGala_SlowDrumModeAction]
    panel0ColumnStop: [SweetGala_CollectItemsAction, StopWheel2PlayAppearEffectAction]
    panel1ColumnStop: [SweetGala_CollectItemsAction, SweetGala_LinkColumnStopAniAction]
    panel2ColumnStop: [SweetGala_CollectItemsAction, SweetGala_LinkColumnStopAniAction]
    specialGame:
      - SweetGala_TriggerRedGameAction
      - SweetGala_TriggerBlueGameAction
      - SweetGala_TriggerPurpleGameAction
      - SweetGala_TriggerGreenGameAction
      - SweetGala_CheckDrumAction
      - SweetGala_LinkOverGameAction
    bonusGame: [SweetGala_TriggerLinkGameAction]
    drumMode: [SweetGala_DrumModeAction]
```
### 6.1 完整运行时序

`elementId` 是所有可视化和覆盖报告的稳定主键；只有真正进入 SlotAction 注册表的节点才额外拥有 `eventId`。禁止把通用 Process、Scene hook 和 CCB 回调伪装成 Action。

```yaml
runtimeTimeline:
  lanes: [Lifecycle, FrameworkProcess, SceneHook, PanelSpin, CustomAction, EntityState, Presentation, Validation]
  edgeTypes: [control, branch, read, write, render, await, cleanup, verify]
  nodes:
    - { id: L00, lane: Lifecycle, phase: Boot, kind: lifecycle, label: Load scene/config/components, next: [L01] }
    - { id: L01, lane: FrameworkProcess, phase: Enter, kind: process, label: EnterRoomCheckingProcess, next: [L02, C00] }
    - { id: C00, lane: CustomAction, phase: Enter, kind: component, eventId: enterRoom.reconnect, guard: bonusRecord, next: [L02] }
    - { id: L02, lane: FrameworkProcess, phase: Base, kind: process, label: WaitForSpinProcess, next: [L03] }
    - { id: L03, lane: FrameworkProcess, phase: Base, kind: process, label: FreeSpinBeginCheckingProcess, next: [L04] }
    - { id: L04, lane: FrameworkProcess, phase: Base, kind: process, label: RoundStartProcess, next: [L05] }
    - { id: L05, lane: FrameworkProcess, phase: SubRound, kind: process, label: SubRoundStartProcess, next: [S00] }
    - { id: S00, lane: SceneHook, phase: SubRound, kind: hook, label: onSubRoundStart, guard: respinTriggered, writes: [RespinCounter], next: [L06] }
    - { id: L06, lane: FrameworkProcess, phase: Spin, kind: process, label: SpinProcess, next: [S01] }
    - { id: S01, lane: SceneHook, phase: Spin, kind: hook, label: onPreprocessSpinResult, reads: [SpinPanel.extraInfo], writes: [LinkSession, syntheticSpinResults], next: [P00] }
    - { id: P00, lane: PanelSpin, phase: ReelStop, kind: branch, label: active PanelSpinProcess, next: [A00, A01, A02] }
    - { id: A00, lane: CustomAction, phase: ReelStop, kind: action, eventId: base.slowDrum, guard: Base-R3-and-10x-or-50x, next: [A01] }
    - { id: A01, lane: CustomAction, phase: ReelStop, kind: action, eventId: base.collectCandy, guard: bonusInfoList-not-empty, next: [A02] }
    - { id: A02, lane: CustomAction, phase: ReelStop, kind: action, eventId: respin.coinAppear, guard: Respin-and-symbol1501, next: [L07] }
    - { id: L07, lane: FrameworkProcess, phase: PostSpin, kind: process, label: CloverClashWaitProcess, next: [L08] }
    - { id: L08, lane: FrameworkProcess, phase: Feature, kind: process, label: SpecialGameProcess, next: [A10] }
    - { id: A10, lane: CustomAction, phase: Feature, kind: action, eventId: respin.redFeature, order: 1, next: [A11] }
    - { id: A11, lane: CustomAction, phase: Feature, kind: action, eventId: respin.blueFeature, order: 2, next: [A12] }
    - { id: A12, lane: CustomAction, phase: Feature, kind: action, eventId: respin.purpleFeature, order: 3, next: [A13] }
    - { id: A13, lane: CustomAction, phase: Feature, kind: action, eventId: respin.greenFeature, order: 4, next: [A14] }
    - { id: A14, lane: CustomAction, phase: Feature, kind: action, eventId: respin.checkDrum, order: 5, next: [A15] }
    - { id: A15, lane: CustomAction, phase: Feature, kind: action, eventId: respin.settlement, order: 6, branch: [notLast-to-L09, last-to-E00] }
    - { id: L09, lane: FrameworkProcess, phase: PostSpin, kind: process, label: JackpotProcess, next: [L10] }
    - { id: L10, lane: FrameworkProcess, phase: PostSpin, kind: process, label: LevelUpProcess, next: [L11] }
    - { id: L11, lane: FrameworkProcess, phase: PostSpin, kind: process, label: VipLevelUpProcess, next: [L12] }
    - { id: L12, lane: FrameworkProcess, phase: Win, kind: process, label: BlinkAllWinLineProcess, next: [L13] }
    - { id: L13, lane: FrameworkProcess, phase: Win, kind: process, label: SpinResultDelayMultiUpProcess, next: [L14] }
    - { id: L14, lane: FrameworkProcess, phase: Win, kind: process, label: ShowWinEffectProcess, next: [A20] }
    - { id: A20, lane: CustomAction, phase: Win, kind: process, eventId: process.panelWinUpdate, next: [L15] }
    - { id: L15, lane: FrameworkProcess, phase: Bonus, kind: process, label: BlinkBonusProcess, next: [A21, L16] }
    - { id: A21, lane: CustomAction, phase: Bonus, kind: action, eventId: link.enter, guard: respinTriggered-and-index0, next: [E10] }
    - { id: L16, lane: FrameworkProcess, phase: End, kind: process, label: BlinkScatterProcess, next: [L17] }
    - { id: L17, lane: FrameworkProcess, phase: End, kind: process, label: SubRoundEndProcess, branch: [respin-to-L05, roundEnd-to-L18] }
    - { id: L18, lane: FrameworkProcess, phase: End, kind: process, label: PreRoundEndProcess, next: [L19] }
    - { id: L19, lane: FrameworkProcess, phase: End, kind: process, label: RoundEndProcess, next: [L20] }
    - { id: L20, lane: FrameworkProcess, phase: End, kind: process, label: FreeSpinEndCheckingProcess, next: [L21] }
    - { id: L21, lane: FrameworkProcess, phase: End, kind: process, label: CouponFreeSpinCheckingProcess, next: [L22] }
    - { id: L22, lane: FrameworkProcess, phase: End, kind: process, label: InteractiveGameCheckingProcess, next: [L23] }
    - { id: L23, lane: FrameworkProcess, phase: End, kind: process, label: ShowInterstitialAdProcess, next: [L02] }

    # Link 入场子流程
    - { id: E10, lane: Presentation, phase: LinkEntry, kind: animation, label: progress/title trigger, next: [E11] }
    - { id: E11, lane: Presentation, phase: LinkEntry, kind: animation, label: triggered pots + dim symbols, next: [E12] }
    - { id: E12, lane: Presentation, phase: LinkEntry, kind: popup, label: normal manual START / Super auto 3s, next: [E13] }
    - { id: E13, lane: EntityState, phase: LinkEntry, kind: state, label: switch panel + initialize coins/areas/lines/counters/bet, next: [L16] }

    # 结算子流程
    - { id: E00, lane: CustomAction, phase: Settlement, kind: branch, label: server Grand presentation, next: [E01] }
    - { id: E01, lane: CustomAction, phase: Settlement, kind: action, label: full BlueArea regions, next: [E02] }
    - { id: E02, lane: CustomAction, phase: Settlement, kind: action, label: sorted coin queue and JP panels, next: [E03] }
    - { id: E03, lane: Presentation, phase: Settlement, kind: popup, label: collect/end panel, next: [E04] }
    - { id: E04, lane: EntityState, phase: Return, kind: cleanup, label: respin2Base idempotent cleanup, next: [L16] }
```

### 6.2 Action 行为合约

| eventId | Guard（纯查询） | 必须执行的命令 | 完成条件 |
|---|---|---|---|
| `enterRoom.reconnect` | `bonusRecord[0]` 为 `link_game` 或 `super_link_game` | 选择对应 CCB，恢复 Feature 展示 | 弹板回调一次调用 `onEnterRoomEnd` |
| `base.slowDrum` | Base、非前摇、R3、赢钱线上包含 1103/1104 与有效前两列 | 延迟 20.5 帧、播放强制 Drum、禁用停轮按钮 | Drum 建立后交回列停止流程 |
| `base.drum` | Base、非 Free/Respin、非前摇 | 播 `_drum`，重播命中图标 Drum，结束时清理 | 所有 Drum 节点可回收 |
| `base.collectCandy` | `bonusInfoList.length > 0` | 按列飞糖、更新对应锅、播放升级/加值音效 | 当前列 callback 立即且只调用一次，飞行动画异步继续 |
| `respin.coinAppear` | Respin 且停轮结果为 1501 | appear/糖变饼、锁 cell、恢复对应盘计数、检查蓝区填满 | 所有本 cell 表现结束后 callback 一次 |
| `respin.redFeature` | `reTriggerColors` 含 2 | 锅 retrigger、合并 index1、单饼 `to_2` | 50 帧后完成 |
| `respin.blueFeature` | `reTriggerBlueArea` 非空 | 锅 retrigger、倍数、格背景、边界线、填满检查 | 50 帧后完成 |
| `respin.purpleFeature` | `purpleAddInfoList` 非空 | 按 `toPos + index` 更新 param、数字和 add 动画 | 首触发 55 帧，否则 30 帧；写数据延迟 7 帧 |
| `respin.greenFeature` | `reTriggerColors` 含 1 | 锅 retrigger、计数器 `to_4`、恢复至 4 | 50 帧后完成 |
| `respin.checkDrum` | Respin、非最后一轮 | 左右盘独立判断只空一格，创建局部 Drum | 所有需建节点已登记后完成 |
| `respin.settlement` | Respin 且最后一轮 | Grand -> 满蓝区 -> 排序金饼/JP -> 结束弹板 -> 回 Base | cleanup 完成后 callback 一次 |
| `link.enter` | `respinTriggered && respinIndex===0` | title、锅、弹板、转场、初始化盘面/蓝区/计数器/bet/BGM | 入场弹板真正关闭且状态初始化完成 |
| `process.panelWinUpdate` | Process 进入 | BigWin/Respin 立即更新，Base 正常滚动，派发赢分事件 | 调用 `advanceToNext` 一次 |

### 6.3 19 文件与完整方法清单

`requiredMethods` 是结构门禁，不是建议。方法可调用私有 helper，但不得省略或用空实现通过检查。

```yaml
fileManifest:
  - file: SweetGalaMachineConfig304.js
    inherits: object
    requiredMethods: [registerDefaultMachineConfig]

  - file: SweetGalaMachineScene304.js
    inherits: SlotMachineScene2022
    requiredMethods:
      - appendExtraConfig
      - getSceneComponentConfig
      - getSpinPanelComponentsConfig
      - getPanelSpinProcesses
      - getProcessesNewVersion2025
      - afterInitialize
      - initSlotActions
      - addEventListener
      - removeEventListener
      - onSpinEnabled
      - onSpinDisabled
      - switchTipQiPao
      - initRoomExtraInfo
      - onSubRoundStart
      - handleSpinResult
      - getReceivedExtraSpinResult
      - getSpinExtraData
      - clearJackpotEffect
      - usingFeatureDependentSpinBet
      - getFeatureDependentSpinBet
      - enableFeatureSpinBet
      - disableFeatureSpinBet
      - initRespinCountCCB
      - regainRespinCount
      - updateRespinsCount
      - isTriggerRed
      - isTriggerGreen
      - clearLinkState
      - onPreprocessSpinResult
      - isTriggerLink
      - generateSpinResult
      - getDefaultSymbolId
      - getDefaultExtraPanel
      - mergeBonusInfoByPosition
      - getRespinTitleNode
      - getRespinCountListNode
      - initRespinCountNode
      - flipCellRow
      - flipMultiData
      - getRandomColor
      - getSuperMultiplierNodeList
      - getMultiplierNodeList
      - resetMultiplierNodes
      - applyMultiplierNodes
      - initAllLinesVisible
      - setAllLinesVisible
      - applyLineVisibility
      - getRegionBorderNodes
      - playRegionWinAnimation
      - isRegionFull
      - checkAndPlayTriggerAnimation
      - resetAllCellBg
      - applyCellBgColors
      - getPotNodeList
      - initPotState

  - file: 304_action/SweetGala_CollectItemsAction.js
    inherits: SlotAction
    eventIds: [base.collectCandy]
    requiredMethods: [onStartSpin, triggerFliter, onTrigger, getTypeColMax, startTrygger, startFlyItem, playEffect, flyCoinToTitle, flyCoinToTitleByColor, updateBoxCCBState]

  - file: 304_action/SweetGala_LinkColumnStopAniAction.js
    inherits: SlotAction
    eventIds: [respin.coinAppear]
    requiredMethods: [onStartSpin, triggerFliter, clearAllDrumBuyCount, onTrigger, updateLandedAndCheckRegion, playEffect, playAppearAnim]

  - file: 304_action/SweetGala_TriggerLinkGameAction.js
    inherits: SlotAction
    eventIds: [link.enter]
    requiredMethods: [triggerFliter, onTrigger, playLinkTriggerAnim, playPotAnim, openLinkRespinPanel, changeToTurnTableGame, initBonusInfoListSymbol, placeBonusSymbols, initMultiplierNodes, initLinesVisible]

  - file: 304_action/SweetGala_TriggerRedGameAction.js
    inherits: SlotAction
    eventIds: [respin.redFeature]
    requiredMethods: [triggerFliter, onTrigger, playPotTriggerAnim, convertAllSingleToDouble]

  - file: 304_action/SweetGala_TriggerBlueGameAction.js
    inherits: SlotAction
    eventIds: [respin.blueFeature]
    requiredMethods: [triggerFliter, checkIsHasMulti, onTrigger, playPotTriggerAnim, initMultiplierNodes, checkFullRegionAndPlayAnim]

  - file: 304_action/SweetGala_TriggerPurpleGameAction
    inherits: SlotAction
    eventIds: [respin.purpleFeature]
    compatibility: extensionless-existing-file
    requiredMethods: [triggerFliter, onTrigger, playPotTriggerAnim, groupByPosition, addInfoByData, getAddAnimName]

  - file: 304_action/SweetGala_TriggerGreenGameAction.js
    inherits: SlotAction
    eventIds: [respin.greenFeature]
    requiredMethods: [triggerFliter, onTrigger, playPotTriggerAnim]

  - file: 304_action/SweetGala_CheckDrumAction.js
    inherits: SlotAction
    eventIds: [respin.checkDrum]
    requiredMethods: [triggerFliter, onTrigger, checkAndShowDrum]

  - file: 304_action/SweetGala_LinkOverGameAction.js
    inherits: SlotAction
    eventIds: [respin.settlement]
    requiredMethods: [triggerFliter, onTrigger, checkGrandJackpot, processFullRegions, getFullRegions, processOneFullRegion, flyMultiItemEndAdd, getRegionCenterWorldPos, buildSortedSettlementList, getCellRegionMulti, settleSingleCoin, showJpTitleWin, showJpPanel, getJpChips, showJieSuanEndPanel, respin2Base, clearAllDrum]

  - file: 304_action/SweetGala_DrumModeAction.js
    inherits: SlotAction
    eventIds: [base.drum]
    requiredMethods: [isDrumModeEnabled, showDrumAnimation, getSlowDrumModeSymbolSpriteList, _replayAllSymbolDrumAnim, newPlayshowDrumAnimation, stopDrumAnimation, _clearDrumNodeSpriteList, getSymbolOpacity, getSymbolColor, onStartSpin]

  - file: 304_action/SweetGala_SlowDrumModeAction.js
    inherits: SlowDrumModeAction
    eventIds: [base.slowDrum]
    requiredMethods: [checkNeedShowForceDrum, forceShowDrumAnimation]

  - file: 304_components/SweetGala_CellSpinPanelComponent.js
    inherits: CellSpinPanelComponent
    requiredMethods: [getStepIncreaseMultiplier, getPanelCellPositionX, getPanelCellPositionY, getPanelCellByColRow]

  - file: 304_components/SweetGala_LinkSymbolLayerComponent.js
    inherits: CellSymbolLayerComponent
    requiredMethods: [getSymbolIsValid, localCheckSymbolIDIsValid, checkSymbolIsValid, needMaskLayer, createSymbol, createCellContainer]

  - file: 304_components/Link_ClassicSymbolTransformComponent.js
    inherits: ClassicSymbolTransformComponent
    requiredMethods: [calSymbolTransfom]

  - file: 304_components/SweetGala_EnterRoomBonusCheckingComponent.js
    inherits: EnterRoomBonusCheckingComponent
    eventIds: [enterRoom.reconnect]
    requiredMethods: [startEnterRoom]

  - file: 304_controller/Link_SymbolController.js
    inherits: SymbolController
    requiredMethods: [onDidLoadFromCCB, onEnter, upCoinNumAni, onExit, onBetChanged, setSymbolData, getSymbolData, reset, updateTotalWinChips]

  - file: 304_process/SweetGala_PanelWinUpdateProcess.js
    inherits: PanelWinUpdateProcess
    eventIds: [process.panelWinUpdate]
    requiredMethods: [onEnter]
```

关键纠正：`Link_ClassicSymbolTransformComponent` 的真实方法是 `calSymbolTransfom`，不是 `isInRespinMode`；Controller 必须包含 `onExit` 和 `onBetChanged`。

### 6.4 关键方法后置条件

| 方法 | 必须保证的后置条件 |
|---|---|
| `initRoomExtraInfo` | 从 roomExtraInfo 恢复锅等级和 7 步进度；注册 `FakeJackpotParseAction`，使 `fakeJackpotConfig` 成为 `JackpotRatioList` |
| `onPreprocessSpinResult` | 缓存 JP 后再清 Base 展示值；生成 synthetic result；最后一轮携带结算/清理字段；`currentSlotMan.spinResult` 替换完成 |
| `generateSpinResult` | 长度为左右 respin 最大值；右盘列偏移 5；右盘不复用左盘 retrigger；缺轮次生成空盘而不是越界 |
| `mergeBonusInfoByPosition` | 同位置同 index/type 合并 param；`finalParam` 取最大；index 升序；每格最多 2 槽；JP 重复记录诊断 |
| `getReceivedExtraSpinResult` | Base 返回原结果；Respin 返回当前 synthetic extra panel，并注入 col/row/symbolId/mainCtrl |
| `placeBonusSymbols` | 使用后端 row；锁列使用翻转后的 flattened index；左右 occupied map 使用各自 local col |
| `applyLineVisibility` | 只展示区域边界，不展示内部共享边；无 BlueArea 时恢复默认隐藏状态 |
| `buildSortedSettlementList` | `col asc -> row desc -> index asc`，Super 右盘仍使用全局 col 5~9 |
| `showJieSuanEndPanel` | disappear/confirm 才推进；callback exactly-once；不得独立抢跑 `respin2Base` |
| `respin2Base` | 幂等清理所有 Feature 状态并恢复 Base UI/BGM/活动入口；再次调用无副作用 |
| `Link_SymbolController.reset` | 所有 chips/JP/add/color 节点隐藏，数字动画停止，`mdata` 和 AddMulti 残留清空 |

### 6.5 MachineConfig 完整性

MachineConfig 不能只复制十几个“关键开关”。304 的生成基线是整个 `registerDefaultMachineConfig` 的所有可执行赋值及设备分支。Agent 必须先从 AST/结构化解析中提取赋值集合，再与下列分类逐项对账；注释示例不得误当成有效配置。

```yaml
machineConfigSnapshot:
  exactSource: src/newdesign_slot/scene/304_sweet_gala/SweetGalaMachineConfig304.js
  extractionRule: "only executable assignments in registerDefaultMachineConfig; preserve expression values and device branches"
  categories:
    uiAndPaytable:
      needOnWinLine: false
      supportUseClassicSpinUI: true
      supportClassicPaytableUI: true
      supportShowTournament: false
      supportShowPhoneTitle: false
      supportStoreBuy: true
      newPaytablePath: sweet_gala/reels/bg/sweet_gala_faq.ccbi
      useSmallLevelTips: false
      enterOnNextFrame: false
    winLineAndDim:
      fixDrumSymbolAppearOnWinLineBug: true
      supportMatchColMaskWinLine: false
      supportWinLineOffset: false
      customWinLineOffsetX: [[], []]
      customWinLineOffsetY: [[], []]
      winLineBlinkDuration: 2
      scatterBlinkDuration: 2
      bonusBlinkDuration: 2
      winLineWidth: 3
      blinkSpriteByAction: false
      displayWinLine: true
      supportWinLineBlink: false
      needSetSymbolOpacityDuringWinLineBlink: true
      symbolOpacityDuringWinLineBlink: 255
      symbolColorDuringWinLineBlink: { r: 127, g: 127, b: 127 }
      supportDimSpriteBlink: false
      overlayOpacity: 150
      blinkAllWinLinesWithoutRepeatedly: true
    symbolAndTransform:
      isCCBSymbol: true
      supportKeepSymbolAppearAnim: false
      arrKeepSymbolAnimSymbolIds: null
      supportEarlyStopNoAppear: false
      earlyStopWaitForAppear: true
      supportSymbolTransform: [true, true, true, false]
      xRotateFactors: [[5, 0, 5], [5, 0, 5]]
      xOffsetFactors: [[5, 0, 5], [5, 0, 5]]
      scaleFactors: [[0.95, 1, 0.95], [0.95, 1, 0.95]]
      initializeSymbolSequence: null
      headAndTailSymbolSequence: null
      simulateRandomSymbol: true
      supportResetParticleType: true
      supportSymbolAnimationTopWheel: false
      newSymbolAnimationParent: true
      enableInitHRAttach: false
    reelAndDrum:
      columnStopAnimationDelayTime: "20 / 30"
      supportDrumModeUpSymbolLayer: true
      forceUseDrumModePosition: null
      forceUseCCBDrumModePosition: false
      checkDrumAnimationWhenColumnStop: false
      checkDrumAnimationStopTime: true
      drummodeStartDelay: 0.1
      supportDrumModeInDecProcess: false
      supportSymbolDrumMode: false
      drumSymbolGroupList: [[1, 1101, 1102], [2]]
      drumOnWinLineList: [true, false]
      drumNeedSymbolCountList: [null, 2]
      needSameSymbolList: [false, true]
      mustDifferentSymbolList: [true, false]
      stopAllReelsWhenTriggerQianyao: [true, false]
      useDrumModeComponent: true
    audio:
      supportRespinBgMusicLoop: true
      classicAudioMode: false
      supportClassicBgMusic: false
      forcePlayMusicInWait: false
      drummodeAudioEffect: fx-reel-stop-drum-roll
      scatterBlinkSound: HitFreespin
      qianyaoSound: 304_qianyao
    triggerPresentation:
      bonusTriggerSymbolId: null
      bonusTriggerBlinkDuration: 3
      bonusTriggerBlinkAnimName: trigger
      bonusTriggerBlinkNeedSetSymbolsOpacity: false
      needShowMaskLayerDuringBonusTriggerBlink: false
      bonusTriggerMaskLayerOpacity: 255
      bonusTriggerMaskLayerColor: "cc.color(0,0,0,0)"
      bonusTriggerBlinkSound: ""
      jackpotTriggerSymbolIds: null
      blinkJackpotTriggerNeedAllOnWinLine: false
      jackpotTriggerBlinkDuration: 3
      jackpotTriggerBlinkAnimName: trigger
      jackpotTriggerBlinkNeedSetSymbolsOpacity: false
      needShowMaskLayerDuringjackpotTriggerBlink: false
      jackpotTriggerMaskLayerOpacity: 255
      jackpotTriggerMaskLayerColor: "cc.color(0,0,0,0)"
      jackpotTriggerBlinkSound: ""
    popupNullContracts:
      freespinBeginPanelCCB: null
      freespinEndPanelCCB: null
      freespinLuckyPanelCCB: null
      freespinRetiggerPanelCCB: null
      reconnectPanelCCB: sweet_gala/reels/bg/sweet_gala_dialog_duanxian.ccbi
      jackpotPanelCCB: null
      bonusStartPanelCCB: null
      bonusWinPanelCCB: null
      eitherPanelCCB: null
      linkStartPanelCCBPath: null
      linkEndPanelCCBPath: null
      respinTriggerPanelCCB: null
      freeSpinBeginPanelSound: null
      freeSpinEndPanelSound: null
      freespinLuckyPanelSound: null
      freespinRetiggerPanelSound: null
      jackpotPanelSound: null
      fakeJackpotPanelSound: null
      bonusStartPanelSound: null
      bonusWinPanelSound: null
      reconnectPanelSound: null
      eitherSelectPanelSound: null
      linkStartPanelSound: null
      linkEndPanelSound: null
      respinTriggerPanelSount: null
      lookupPanelSound: null
    freeSpinDisabledContract:
      needFreeSpinAction: false
      freeSpinBeginTransferAnimCCB: null
      freeSpinBeginTransferAnimTime: 0
      doSomeThingInFreeSpinBeginTransDelayTime: 0
      freeSpinBeginTransferSound: null
      freespinBeginPanelAutoCloseDelayTime: 5
      freeSpinRetriggerPanelAutoCloseDelayTime: 5
      freeSpinEndPanelAutoCloseDelayTime: 5
      freeSpinLuckyPanelAutoCloseDelayTime: 5
      freeSpinCounterNodeName: freeSpinCounter
      retriggerFreeSpinUpdateDelayTime: 0
      retriggerFreeSpinAddAnimTime: 0
      delayBeforeFreeSpinBeginPanelClose: 0
      delayBeforeFreeSpinEndPanelClose: 0
      delayBeforeFreeSpinRetriggerPanelClose: 0
      delayAfterFreeSpinBeginPanelClose: 0
      delayAfterFreeSpinEndPanelClose: 0
      delayAfterFreeSpinRetriggerPanelClose: 0
    processAndSettlement:
      supportFreeSpinEndAddChips: true
      useBigWinProcess2025: true
      delayAfterBlinkAllWinLine: 0.5
      disableCommonJackpotPanel: true
      keepJackpotAnim: false
      donotBlinkWinLinkWhenFreeToBase: true
      fixAutoSpinWrongProcess: true
      useSpinResultMultiUpAction: false
      spinResultMultiUpAnimCCB: ""
      spinResultMultiUpSound: null
      multiUpActionGameTypeList: [base, freeSpin, respin]
      multiUpAnimTime: 3
      delayTimeMultiUpWinChips: "1 + 11 / 30"
      multiUpFontRangeConfig:
        - { multi: 1, fontFile: "", fontColor: cc.color.WHITE }
        - { multi: 6, fontFile: "", fontColor: "cc.color(250,200,155)" }
        - { multi: 16, fontFile: "" }
    interactionAndMultiPanel:
      tapAnyWhereSpin: true
      isShowAutoSpinBtnSound: true
      supportFastSpin: true
      needFastSpinSettlement: true
      useSinglePanelBet: false
      supportMultiPanelCloverClash: true
      supportMultiPanelHRJP: true
      needFixHRBetTipOffset: true
      needFixMaxBetTipOffset: true
      fixEarlyStopReelAppearBug: true
      supportEarlyStopInRespin: true
      popupPanelAutoCloseProgressDelay: 1
      reconnectAutoCloseDelayTime: 4
      useMultiPanelRespin: false
      hideCloverClashInBonusGame: true
      needCameraFocusAction: false
      cameraFocusConfig: {}
      switchPanelLayerClipType: true
    appear:
      HookAppearData: true
      hasSymbolListAppear: [1200, 1201, 1202, 1203, 1204, 1501]
      inLineSymbolListAppear:
        - [[1, 1101, 1102, 1103, 1104], [], []]
        - [[], [1, 1101, 1102, 1103, 1104], []]
      inLineSymbolFilterID: [3]
      winLineHasSymbolListAppear: [1, 1101, 1102, 1103, 1104]
      appearAudioNameList:
        1: 304_wild_appear
        1101: 304_wild_appear
        1102: 304_wild_appear
        1103: 304_wild_appear
        1104: 304_wild_appear
        1200: 304_bonus_appear
        1201: 304_bonus_appear
        1202: 304_bonus_appear
        1203: 304_bonus_appear
        1204: 304_bonus_appear
      useColumnStopAnimationComponent: true
  deviceBranches:
    machineUI: "high resolution -> sweet_gala_main_pad.ccbi; otherwise sweet_gala_main.ccbi"
    doubleHitOffsets: "native/non-high-res condition preserved exactly"
  sceneAssignments:
    highResolutionOffect: "cc.p(0,0)"
    skipStopAutoSpinWhenFreeSpinEnd: true
```

完整性检查必须比较“解析出的可执行赋值键 + 表达式 + 分支”，不能只做字符串搜索；`symbolColorDuringWinLineBlink` 以最后一次有效赋值为准。

### 6.6 配置文件合约

```yaml
runtimeConfigContract:
  subjectTemplate:
    source: res_*/config/subject_tmpl_list/subject_tmpl_304.json
    aliases: [subject_tmpl_204304.json]
    required:
      subjectTmplId: "304 or 204304 according to filename"
      editableConfigId: 304
      bonusId: 2
      reelCol: 3
      reelRow: 3
      virtualLineNum: 50
      panels:
        - { panelId: 0, slotCols: 3, slotRows: 3, spinLayerType: 304 }
        - { panelId: 1, slotCols: 5, slotRows: 3, spinLayerType: 304 }
        - { panelId: 2, slotCols: 10, slotRows: 3, spinLayerType: 304 }
      lineSets: "panel0 exactly 5; panel1/panel2 empty"
      symbols: [1, 3, 1001, 1002, 1003, 1004, 1005, 1006, 1101, 1102, 1103, 1104, 1200, 1201, 1202, 1203, 1204, 1500, 1501, 1502]
      controllerBindings: "1500/1501 -> Link_SymbolController"
      specialPayTables: "must match blueprint.paytable.specialPays, not the audited stale all-10 values"
    aliasRule: "204304 must be structurally identical to 304 except subjectTmplId"
    themeRule: "preserve explicit spinUiTitleName and dailyMission differences"
  editableConfig:
    source: res_*/config/editable_config_list/editable_config_304.json
    copyPolicy: "304 reconciliation copies the complete JSON structure and decimal values; no curve rounding"
    required:
      commonConfig.initializeSymbolSequenceLayouts: [3x3, 5x3, 10x3]
      commonConfig.headAndTailSymbolSequence: "panel0 two columns of 1005"
      drumConfigCount: 3
      spinSchemeConfigCount: 7
      panelSpinSchemeMap:
        panel0: { normalSpin: 1, freeSpin: 1, autoSpin: 1, respin: 1, fastSpin: 0, fastRespin: 6 }
        panel1: { normalSpin: 1, freeSpin: 1, autoSpin: 1, respin: 4, fastSpin: 0, fastRespin: 6 }
        panel2: { normalSpin: 1, freeSpin: 1, autoSpin: 1, respin: 4, fastSpin: 0, fastRespin: 6 }
    parityRule: "oldvegas and doublehit files must remain byte-identical"
```

`editable_config_304` 内的贝塞尔曲线和浮点速度必须结构化复制，禁止手抄、四舍五入或把 JSON 当字符串替换。

### 6.7 资源、节点与时序

```yaml
resources:
  roots: [res_oldvegas/sweet_gala, res_doublehit/sweet_gala]
  ccbi:
    machine: sweet_gala/reels/bg/sweet_gala_main.ccbi
    machinePad: sweet_gala/reels/bg/sweet_gala_main_pad.ccbi
    faq: sweet_gala/reels/bg/sweet_gala_faq.ccbi
    respinStart: sweet_gala/reels/bg/sweet_gala_dialog_respin_start.ccbi
    superRespinStart: sweet_gala/reels/bg/sweet_gala_dialog_sp_respin_start.ccbi
    respinCollect: sweet_gala/reels/bg/sweet_gala_dialog_respin_collect.ccbi
    superRespinCollect: sweet_gala/reels/bg/sweet_gala_dialog_sp_respin_collect.ccbi
    jackpot: sweet_gala/reels/bg/sweet_gala_dialog_jackpot.ccbi
    reconnect: sweet_gala/reels/bg/sweet_gala_dialog_duanxian.ccbi
    superReconnect: sweet_gala/reels/bg/sweet_gala_dialog_duanxian_sp.ccbi
    coinFly: sweet_gala/reels/symbol/sweet_gala_symbol_batch_link_fly.ccbi
    candyFly: sweet_gala/reels/symbol/sweet_gala_symbol_batch_tang_fly.ccbi
    multiplierFly: sweet_gala/reels/bg/sweet_gala_whee_beishu_add.ccbi
    drum: sweet_gala/reels/bg/sweet_gala_wheel_effect_drum.ccbi
  dynamicNodes:
    pots: "_guo0.._guo3"
    progress: "_bonus0.._bonus6"
    progressTitle: _bonusTitle
    superTip: _superTipCCB
    baseCounter: _baserespinCount
    superCounters: [_leftSpinCount, _rightSpinCount]
    panels: [panel_1, panel_2, _leftPanel, _rightPanel]
    multipliers: [_multiTL, _multiBL, _multiTR, _multiBR, _right_multiTL, _right_multiBL, _right_multiTR, _right_multiBR]
    cells: "_cell_0.._cell_14 per logical board"
    regionLines: [_line_t_*, _line_b_*, _line_l_*, _line_r_*, _line_N_M]
    win: [_winEffect, winLabel, jackpotEffectNode, respinJackpotEffectNode]
    coinSlots: [_chips0, _chips1, _jp00.._jp03, _jp10.._jp13, _norJp0, _norJp1, _addMulti0, _addMulti1, _jpGold0, _jpGold1, _color0.._color4]
  animations:
    potState: ["1", "2", "3", "4", "5"]
    potUpgrade: [1_to_2, 2_to_3, 3_to_4, 4_to_5]
    pot: [trigger, "{level}_add"]
    coin: [base, base_2, appear, appear_2, change, to_2, add, add_2, add_2_left, add_2_right, jiesuan, jiesuan_2_left, jiesuan_2_right]
    counter: ["3", "4", to_4, loop, appear, disappear]
    area: [appear, loop, base, to_glow, glow]
    mainUI: [base, respin, super, respin_shake, super_shake]
  audioFiles:
    background: [bg_music, bonus_game_bg_music, bonusgame_bgm]
    effects:
      - 304_bonus_appear
      - 304_bonus_fly
      - 304_boost_add
      - 304_coin_appear
      - 304_coin_fly
      - 304_coin_jp
      - 304_double_2doublecoins
      - 304_extra_3to4
      - 304_jp_menu
      - 304_jp_multy
      - 304_pot_retrigger
      - 304_pot_trigger
      - 304_pot_upgrade
      - 304_qianyao
      - 304_respin_candy2coin
      - 304_respin_drum
      - 304_respin_end
      - 304_respin_reelstop
      - 304_respin_start
      - 304_super_add
      - 304_super_end
      - 304_super_start
      - 304_super_trigger
      - 304_wild_appear
      - 304_zhuanchang
      - 304_zone_appear
      - 304_zone_fly
  validation:
    - every source-referenced CCB exists in both themes
    - every dynamic node exists in its owning CCB/controller
    - every played sequence exists in the target CCB
    - every local audio key resolves through resource_list/project.manifest
    - oldvegas and doublehit level-resource file lists are identical

timing:
  fps: 30
  base:
    slowDrumDelayFrames: 20.5
    collectPotUpdateFrames: 15
    columnStopAnimationDelayFrames: 20
  linkEntry:
    potAdvanceSeconds: 2
    dimCleanupSeconds: 2.5
    regularStartPanel: manual-confirm
    superStartPanelAutoCloseSeconds: 3
    bgmAfterEntrySeconds: 0.4
    auditedImplementationDeviation: "current source transitions both modes after 2s; see CF-304-04"
  respinStop:
    coinAppearFrames: 21
    candyToCoinExtraFrames: 20
  colorFeature:
    redFrames: 50
    blueFrames: 50
    purpleFirstFrames: 55
    purpleNormalFrames: 30
    purpleDataWriteFrames: 7
    greenFrames: 50
  settlement:
    beforeEndPanelFrames: 25
    fullRegionTotalFrames: 45
    regionSlamFrames: 30
    coinFlyFrames: 15
    coinHitFrames: 15
    nextCoinFrames: 10
    jpPanelAutoCloseSeconds: 4
    jpProgressDelayNormalSeconds: 1
    jpProgressDelayMultipliedSeconds: 4
    jpMultiNumberTickFrames: 32
    jpMultiNumberStartFrames: 78
    endPanelAutoCloseSeconds: 4
    returnToBase: on-panel-close-callback
  reconnect:
    autoCloseSeconds: 4
  numberAnimation:
    linkCoinTickFrames: 14
```

任何 `delayCall`、`pushDelayTime`、`setAutoCloseDelay` 和数字动画 tick 都必须引用 `timing` 的命名常量。CCB 自身控制的时长要标记 `owner: artTimeline`，不能在 JS 中再猜一个近似值。

---

## 七、代码生成顺序

```yaml
codeGenerationPlan:
  - stage: 0-validate-input
    outputs: [sourceCatalog, requirementCoverage, conflictResolution]
    stopWhen: "any blocking conflict or missing protocol/resource"
  - stage: 1-config-and-schema
    outputs: [subject templates, editable config, MachineConfig]
    gates: [panel-shape, symbol-ids, paytable, executable-config-assignments]
  - stage: 2-state-and-rendering
    outputs: [Link_SymbolController, four Components]
    gates: [node-bindings, pool-reset, coordinate-tests]
  - stage: 3-actions
    outputs: [eleven Actions]
    order: [collect, column-stop, link-entry, red, blue, purple, green, check-drum, settlement, base-drum, slow-drum]
    gates: [pure-trigger-filter, exactly-once-callback, resource-and-timing-references]
  - stage: 4-process
    outputs: [SweetGala_PanelWinUpdateProcess]
    gates: [advance-exactly-once]
  - stage: 5-scene-integration
    outputs: [SweetGalaMachineScene304]
    gates: [component-registry, process-chain, action-order, preprocess, cleanup]
  - stage: 6-static-verification
    outputs: [static-report.json]
  - stage: 7-runtime-verification
    outputs: [runtime-report.json, screenshots-or-video, protocol-fixture-results]
  - stage: 8-final-report
    outputs: [coverage-report.json, human-summary]
```

实现规则：

1. 优先复用本项目的 `SlotAction`、`SlotActionSequence`、`createFlow`、Component 和 Process API。
2. 不新增抽象，除非蓝图中至少两个行为共享同一不变量且现有框架没有对应 helper。
3. `triggerFliter` 必须是无副作用布尔查询；保留项目中的拼写以兼容框架。
4. 每个异步 Action 的所有分支必须 exactly-once 调用 callback，包括节点缺失和空数组分支。
5. 服务端字段先在 `protocol` 声明再读取；禁止通过 UI 状态推导中奖结果。
6. 资源、节点、动画、音效和时序不得散落裸字符串；若项目既有代码无法集中常量化，覆盖报告仍须映射到蓝图 ID。
7. 普通 Respin 和 Super Respin 必须分别测试，不能用“panel2 只是 panel1 加宽”替代双盘状态隔离。
8. 断线重连必须恢复可继续执行的状态，而不仅是显示一张提示弹板。
9. 结算和回 Base 的函数必须可重入且幂等，防止手点与自动关闭双回调。
10. 最终代码中 `TODO/FIXME/__TODO__/throw new Error('not implemented')` 数量必须为 0。

---

## 八、验收场景

每个场景必须有协议夹具、预期状态迁移、预期资源事件和最终断言。

| Test ID | 场景 | 核心断言 |
|---|---|---|
| `AC-304-001` | 进房无 bonus record | Base 3×3 可 SPIN，无 Feature 残留 |
| `AC-304-002` | 普通 Link 触发 | 手点 START 后才转场，panel1、计数 3、初始金饼正确 |
| `AC-304-003` | 绿锅初始激活 | 普通计数直接为 4，不重复播放 retrigger 升级 |
| `AC-304-004` | Super Link | 3 秒自动转场，panel2，左右初始盘镜像，平均 bet 启用 |
| `AC-304-005` | Super 左右 respin 长度不同 | synthetic 轮数取 max，短侧空轮不越界、不串数据 |
| `AC-304-006` | 普通新金饼 | 目标 cell 锁定并把左计数恢复到最大 |
| `AC-304-007` | Super 仅右盘新金饼 | 只恢复右计数，左计数不变 |
| `AC-304-008` | 新颜色糖果 | 糖变饼后锁定；已激活颜色被过滤 |
| `AC-304-009` | 彩糖且仍有未激活锅 | 彩糖允许出现并更新所有符合条件的锅 |
| `AC-304-010` | 所有锅已激活 | 彩糖被过滤，不进入最终结果渲染 |
| `AC-304-011` | 红锅再触发 | 已有单饼生成 index1；结算 index0 后 index1 |
| `AC-304-012` | 紫锅加一个槽 | 只更新协议指定槽，不影响同格另一槽 |
| `AC-304-013` | 紫锅加两个槽 | 按两条 `purpleAddInfoList` 分别更新，无客户端随机 |
| `AC-304-014` | 蓝锅新增多区域 | x2~x5 节点、格背景、边界线均与 cell map 一致 |
| `AC-304-015` | 蓝区刚好填满 | 播 to_glow，结算先倍数砸盘再逐币 |
| `AC-304-016` | 非最后一轮只空一格 | 对唯一空格播放 Drum；左右盘独立 |
| `AC-304-017` | 服务端 Grand | 先弹 Grand JP，再区域、金饼和结束弹板 |
| `AC-304-018` | 普通完整结算 | comparator 和金额正确；结束弹板关闭后才回 Base |
| `AC-304-019` | Super 完整结算 | 左右数据、colOffset、区域倍数、JP 均不串盘 |
| `AC-304-020` | 普通 Respin 断线重连 | 正确重连 CCB，关闭后继续普通 Feature |
| `AC-304-021` | Super Respin 断线重连 | 正确 Super CCB，恢复双计数和平均 bet |
| `AC-304-022` | early stop / fast spin | callback 不丢失、不重复，appear 和结算完整 |
| `AC-304-023` | 对象池复用 LinkCoin | 旧 JP/add/color/数字动画完全清除 |
| `AC-304-024` | 重复调用 `respin2Base` | 第二次无状态变化、无重复音效/转场/加奖 |
| `AC-304-025` | 两主题资源验证 | 所有引用在 oldvegas/doublehit 均存在，主题差异符合清单 |
| `AC-304-026` | 赔率展示 | FAQ、subject template、服务端数学均为 50/30/20/10/10/7/5/2 |

协议夹具至少覆盖：空数组、缺失可选 `secondRespinInfo`、左右轮数不等、双槽、JP、多个满蓝区、0 赢分和异常重复 JP 数据。

---

## 九、质量门禁

| Gate ID | 检查 | 通过条件 |
|---|---|---|
| `G-SRC-01` | 证据完整性 | 每条 Requirement 至少一个来源，源文件有路径/版本/hash |
| `G-CNF-01` | 冲突完整性 | 无未决 `blocking` 项；决议有 owner 和理由 |
| `G-REQ-01` | 需求覆盖 | 每条 Requirement 映射到代码节点和 Acceptance Test |
| `G-FILE-01` | 文件完整性 | 19/19 文件存在，路径和大小写精确 |
| `G-METHOD-01` | 方法完整性 | `requiredMethods` 100% 存在且非空实现 |
| `G-INHERIT-01` | 继承关系 | 每文件继承/require 与 manifest 一致 |
| `G-CONFIG-01` | MachineConfig | 可执行赋值、表达式和设备分支与 snapshot 一致 |
| `G-CONFIG-02` | JSON 配置 | Panel、符号、线、赔率、spin scheme 和主题差异正确 |
| `G-PROTO-01` | 协议字段 | 每个字段在 schema 中存在，类型/可选性/owner 明确 |
| `G-SERVER-01` | 责任边界 | 客户端不重算概率、RTP、中奖、Grand 或紫锅目标 |
| `G-COORD-01` | 坐标 | backend row、visual row、flattened index、右盘 offset 单测通过 |
| `G-STATE-01` | 状态归属 | 每个跨 Action 字段属于一个 Entity owner |
| `G-FLOW-01` | Process 链 | 通用 Process 顺序逐项一致 |
| `G-ACTION-01` | Action 注册 | panel0/1/2、special、bonus、drum 顺序逐项一致 |
| `G-FILTER-01` | Guard 纯度 | 所有 `triggerFliter` 无写状态/动画/音效/协议副作用 |
| `G-CALLBACK-01` | 异步闭环 | 所有分支 exactly-once 完成；手点/自动关闭不双触发 |
| `G-RES-01` | 资源 | CCB、音效、贴图、plist、字体均存在于两主题和 manifest |
| `G-NODE-01` | CCB 契约 | 动态节点和动画序列可在实际 CCB 中解析 |
| `G-TIME-01` | 时序 | 每个 JS wait 映射到 `timing`；无未登记 magic delay |
| `G-SUPER-01` | 双盘 | 右盘数据、坐标、计数、蓝区和结算独立 |
| `G-RECONNECT-01` | 重连 | 普通/Super 两套路径均能继续并完成玩法 |
| `G-CLEAN-01` | 清理 | 锁列、局部动画、锅、蓝区、计数、bet、BGM、活动入口清零 |
| `G-POOL-01` | 对象池 | LinkCoin 回收复用无 UI/数据残留 |
| `G-PAY-01` | 金额 | `param/finalParam * avgTotalBet * regionMulti` 与 JP 夹具一致 |
| `G-RUN-01` | 可运行 | 构建通过，Base/Respin/Super/重连 smoke test 通过 |
| `G-ZERO-01` | 零占位 | TODO/FIXME/空实现/臆造字段为 0 |
| `G-REPORT-01` | 最终报告 | 覆盖、测试、资源、冲突、变更和残余风险字段齐全 |

### 9.1 最终报告结构

```yaml
finalAgentReport:
  blueprintId: slot-304-sweet-gala
  generatedFiles: []
  modifiedConfigs: []
  requirementCoverage:
    total: 27
    covered: 27
    entries: []
  conflictResolutions: []
  methodCoverage:
    expected: 0
    implemented: 0
    missing: []
  implementedTimelineNodes: []
  protocolFieldReferences: []
  resourceReferences: []
  timingReferences: []
  validationGates: []
  acceptanceResults: []
  buildResults: []
  placeholders: []
  remainingBlockers: []
```

`placeholders` 和 `remainingBlockers` 必须为空，才能把状态标记为 `complete`。

---

## 十、给 Agent 的执行指令

```text
你正在实现一个由 blueprint 驱动的完整可运行关卡。不要把它当作示例代码任务。

执行顺序：
1. 读取 sourceCatalog 中的全部证据，不得只读 MachineScene 或 Action。
2. 结构化提取 PDF 需求、协议字段、源码方法、配置赋值、CCB 节点/动画和资源清单。
3. 建立 requirementCoverage，并逐项应用 conflictLedger 的选定决议。
4. 若存在未决 blocking 项，停止生成，只输出阻断报告；不得填默认值或 TODO。
5. 按 coordinateSystem、protocol、entities 和 stateMachines 建立规范化模型。
6. 按 runtimeTimeline 编译控制流；通用 Process、自定义 Action、Scene hook、表现回调不得混为一层。
7. 按 fileManifest 和 codeGenerationPlan 生成全部文件与方法。
8. MachineConfig 必须覆盖全部可执行赋值和设备分支；JSON 配置必须结构化读写。
9. 所有 triggerFliter 保持纯查询；所有异步分支 exactly-once 完成。
10. 服务端结果是金额、概率、JP、Feature 目标的唯一真相；客户端只负责校验、转换和表现。
11. 所有资源、节点、动画、音效和时序必须能回溯到 blueprint 条目。
12. 普通 Respin、Super 双盘、断线重连、early stop、fast spin 和幂等清理全部实现。
13. 执行 validationGates 和 acceptanceScenarios，修复失败项后再交付。
14. 最终代码不得包含 TODO/FIXME/__TODO__/空实现，最终报告的 missing/placeholders/blockers 必须为空。
15. 输出 finalAgentReport，并给出每条 Requirement -> 文件/方法 -> Test 的三向映射。
```

---

## 十一、评审结论

304 已经具备完整玩法实现的主体，但不能直接把“当前代码”当成新关卡模板。此次审计确认：

- 现有 19 文件和双主题资源足以提炼完整关卡包。
- Process 与 Action 必须分层建模；13 个 `eventId` 不能代表全部运行流程。
- 直接代码生成必须增加冲突裁决、协议 owner、方法级 manifest、完整配置快照和运行验收。
- 当前 304 仍有三个应在发布前关闭的偏差：入场弹板时序、结束弹板回 Base 竞态、赔率配置。
- 概率、RTP、前摇命中率和 Feature 结果属于服务端/数学，不应被客户端生成器实现。

可视化页面使用同一套 `elementId / eventId / Entity / edgeType` 模型展示完整时序轴、可连线节点蓝图和冲突评审，适合做生成前设计审查与生成后覆盖核对。

---

## 十二、预览方式

- Markdown：在 VitePress 中打开 `/关卡/AI关卡产出蓝图模板`。
- 交互视图：打开 `/关卡/AI关卡产出蓝图可视化.html`。
- 独立文件模式可直接打开 `docs/public/关卡/AI关卡产出蓝图可视化.html`。

---
