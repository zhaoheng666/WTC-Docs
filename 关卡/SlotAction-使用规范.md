# SlotAction 使用规范

**制定时间**：2026-07-08
**适用范围**：`src/newdesign_slot/actions/` 及所有使用 SlotAction 的关卡代码
**关联文档**：[SlotAction-优化记录](/关卡/SlotAction-优化记录)（历次代码优化的版本日志）、[freeSpin流程封装Action](/关卡/freeSpin流程封装Action)

---

## 一、定位：SlotAction 是什么

SlotAction 是关卡框架的**可插拔拦截器系统**（AOP 思想的 ES5 实现）：宿主（Process / Component / MachineScene）在关键时刻暴露钩子点，Action 以"条件检查（`triggerFliter`）+ 触发执行（`onTrigger`）"两阶段协议响应。

设计目标（见优化记录 v1.0）：解耦、组合、内聚、封装，让关卡需求点以 Action 为颗粒插入通用流程，避免大面积重写 Process / Component。

**本规范不限定 Action 能做什么**——演出插片、流程编排、数据处理、临时补丁都允许。限定过死会把逻辑挤回 MachineScene 巨型文件，得不偿失。本规范只约束三件影响"系统行为可推理性"的事，见第三节。

---

## 二、两种触发语义的判别（核心概念）

写 Action 前先判断：**调用方知不知道对方是谁？**

| | 拦截语义（Push / 广播） | 协作语义（Pull / 点名） |
| --- | --- | --- |
| 场景 | 宿主不知道谁在监听，广播"现在是 XX 时刻" | 宿主明确需要某个具体 Action 的服务 |
| 走法 | `triggerFliter` / `onTrigger` 统一协议 | 具名方法直调（如 `onFreeSpinBeginTrigger`、`needDelay`） |
| tag 参数 | 由框架自动注入 `processTag`（`Component.checkWithSlotActions` 内部处理），**调用方无需手写** | **不需要 tag**——调用方本来就知道当前时刻，强制传 tag 是纯仪式负担 |
| 典型例子 | Component 中 `triggerSlotActions()` 广播；QianyaoAction 检查 `extraInfo["triggerSpecial"]` | `FreeSpinBeginCheckingProcess` 直调 `freeSpinAction.onFreeSpinBeginTrigger(cb)` |

**两种走法都是合法的、正统的。** 不要求所有调用统一收拢到 `triggerFliter`/`onTrigger` 两个出入口：

- 把点名协作硬塞进统一协议，等于在 `onTrigger` 内部做 `processTag` 字符串 switch 分发——具名方法退化为字符串路由，IDE 无法跳转、堆栈不可读、拼写错误延迟到运行时才暴露；
- 查询类接口（如 `needDelay(columnIndex, stepCount)`，带参数、有返回值、每帧调用）在语义上既不是"该不该触发"也不是"执行"，塞进协议是概念错配；
- 协议路径每次调用有 `deepCopyObject` 开销，高频查询走协议会产生真实的 GC 压力。


---

## 三、硬规则（仅三条，违反即需修改）

### 规则 1：`triggerFliter` 必须无副作用

`triggerFliter` 是纯查询：只读状态、返回布尔，**不得修改任何状态、不得触发任何行为**。

原因：`SlotActionSequence.triggerOne`（`src/newdesign_slot/actions/SlotActionSequence.js` 第 77 行）依赖"条件检查可被安全地延迟、反复调用"——序列容器轮到某个子 Action 时才做检查，以保证前项执行改变后项条件的场景正确。在 filter 里写状态会破坏所有容器 Action 的语义。

### 规则 2：状态不外泄到共享对象

Action 的控制状态放在 **Action 自身属性**上，禁止写入：

- ❌ 服务器数据对象：`receivedSpinResult._disableQianyao` 这类做法（QianyaoAction 遗留，作者已在代码注释中标记为设计污染）
- ❌ `context`（MachineScene）上的临时标志字段：如 `context.needForwardDelay`

跨模块需要读取时，通过 `SA.get(SAT.XxxAction).xxx` 取 Action 实例再读其属性，成本几乎为零。

原因：写进共享对象的标志是"超距作用"——排查时序 bug 时现场看不出谁写的，只能全局搜字段名。这是历次线上问题中排查成本最高的一类。

### 规则 3：特设接口必须在 Action 头部声明触发方

**直调合法，但要留下路标。** 凡是提供具名方法供宿主点名直调的 Action，建议在文件头注释中声明：

```javascript
/**
 * FreeSpin 全流程演出编排
 * @kind flow
 * @triggeredBy FreeSpinBeginCheckingProcess 直调 onFreeSpinBeginTrigger
 *              FreeSpinEndCheckingProcess   直调 onFreeSpinEndTrigger
 *              BlinkBonusProcess            直调 onFreeSpinRetriggerTrigger
 */
```

原因：一个 Action 可能被点名直调、被广播过滤、被自己监听的事件唤醒，三条路可能并存。没有声明时，读代码的人无法从定义处回答"它什么时候跑"，只能全局反搜调用方。写的人 3 行注释，读的人省半小时。

---

## 四、约定（软性，照最近的样例抄即可）

### 4.1 `@kind` 分类标注

在文件头注释声明 Action 的实际身份，仅作声明、无运行时检查：

| kind | 含义 | 样例 |
| --- | --- | --- |
| `effect` | 演出插片（动画/音效/遮罩），与协议契合度最高 | QianyaoAction、AddTouchMaskAction、CameraFocusAction |
| `flow` | 多步流程编排 | FreeSpinAction、Link 玩法结算序列 |
| `data` | 数据预处理/解析 | OnReceivedSpinResultGetAppearData |
| `patch` | 临时补丁，**必须**附加 `@removeWhen` 说明可移除条件 | ResolveAutoSpinWrongProcessAction |

`patch` 类示例：

```javascript
/**
 * 修复 autoSpin 停止后立刻重开导致流程重复触发
 * @kind patch
 * @since 2024-xx  @removeWhen autoSpin 流程重构合入后删除
 * @triggeredBy WaitForSpinProcess 直调
 */
```

每次版本收尾时过一遍 `patch` 类 Action 的 `@removeWhen`，到期即删（git 历史可查，不留注释尸体）。

### 4.2 对象获取

- 推荐 `SA.get(SAT.XxxAction)` / `SA.gets(...)` 统一获取（与优化记录 v2.0 的建议一致）；
- 场景属性缓存（`this.freeSpinAction = SA.new(SAT.FreeSpinAction)`）**允许**——本质是 get 结果的缓存，热路径更快；前提是规则 3 的声明到位，且只绑定在 SlotMachineScene 上，不绑定到其他组件/对象（避免影响 jsObject GC，见优化记录 v2.0 注意事项）。

### 4.3 规模与命名

- 新 Action 建议单一职责、50 行以内；超过 150 行时考虑是否应拆分，或它实际是 `flow`/`data` 类（允许，但标注 kind）；
- 命名统一英文（存量的 Qianyao 等拼音术语保留，新增不再使用）；
- 注册类型名走 `SlotActionRegistry.js` 的 `SAT` 常量，避免裸字符串散落。

---

## 五、快速自查清单

新增或修改 Action 时过一遍：

- [ ] `triggerFliter` 里没有任何赋值/调用副作用（规则 1）
- [ ] 控制标志在 Action 自身，没写进 `receivedSpinResult` / `context`（规则 2）
- [ ] 有特设直调方法的，文件头声明了 `@triggeredBy`（规则 3）
- [ ] 文件头标了 `@kind`；`patch` 类附带 `@removeWhen`
- [ ] 只绑定在 SlotMachineScene / 经 `SA.get` 获取，未绑定到其他组件对象

---

## 六、设计背景（为什么是这三条而不是更多）

评估过"统一收紧到 `triggerFliter`/`onTrigger` 两个出入口"的强规范方案，结论是**净价值为负**，已否决：

1. 使用负担重（每次调用先 `SA.get`、手工构造 tag 参数），而 tag 在点名直调路径上是调用方本来就有的知识，传递它是零信息量的仪式；
2. 具名方法退化为 `onTrigger` 内的字符串分发，损失 IDE 可跳转性、堆栈可读性和编译期检查；
3. 查询类接口（`needDelay`）在协议语义上无处安放；
4. 协议路径的 deepCopy 开销不适合每帧级高频调用。

约束的性价比排序：**语义完整性（规则 1）> 数据边界（规则 2）> 可发现性（规则 3）>> 调用路径统一（否决）**。前三条保护"系统行为可推理"，最后一条只保护"分类表好看"。

框架治理遵循"正门原则"：与其用规则拦住某种用法，不如让正确用法成为阻力最小的路径。`flow` 类 Action 的长期归宿是流程框架提供"关卡可注入的演出子树"原语（待规划），届时自然分流，存量不强制迁移。

---

**最后更新**: 2026-07-08
**维护者**: 赵恒
