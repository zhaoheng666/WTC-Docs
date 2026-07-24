# 会话交接文档 —— Unity 迁移工具链研发

> **写给**：接续本工作的下一个 Agent 会话
> **交接时间**：2026-07-14
> **工作分支**：`Classic_vegas_analyzer`（已有提交 "规则提取器" ×2；`tools/analyzer/out/` 下有两个重新生成的产物文件未提交，无关紧要）
> **首要约定**：**每轮讨论/交付后必须更新 `docs/unity-migration/10-discussion-log.md`**（用户明确要求的流程，已执行 12 轮）

---

## 一、你在哪条线上，处于什么位置

两层任务栈，当前在内层：

```
外层（⏸ 挂起）：Unity 迁移总体方案讨论（仅关卡部分）
   └─ 内层（▶ 进行中）：规格提取器+录制器+覆盖率验证器 工具链研发
```

- **外层挂起原因**：讨论 N1（规格提取器设计）时，用户判定该工具链是独立的高价值方向（迁移能力底座 + Cocos 关卡测试工具双重价值），决定先做工具再回来继续方案讨论；
- **外层恢复指引**在 `docs/unity-migration/10-discussion-log.md` 顶部挂起块：恢复后从 **N2 比对判定细节**（双端帧率对齐、事件顺序容差）继续，其后 E 档（干净层框架设计）→ G4（追赶收敛模型，需用户提供新关产率 r）；
- **内层已完成三大件中的两件半**（详见第三节）。

## 二、已定案的关键决策（勿重新辩论，否决理由都在讨论记录里）

| 决策 | 内容 | 详见 |
|------|------|------|
| DEC-01 | 过渡期新关仍走 Cocos 2022 轨、不混跑（UAAL/双端并行/冻结等壳全部否决）、终点一次性平替发布 | 10-discussion-log.md |
| DEC-02 | 迁移路线 = "规格提取 + AI 重实现"（路线 C）为主干；代码机翻降级为逃生舱；L1 兼容层从 400 API 缩到最小兜底集 | 同上 |
| N1 收口 | 行为提取流水线：静态分析→插桩计划→定制注入→分片 JSONL 日志→分支覆盖率闭环。**录屏已否决**（太重/盖不住）；意图不靠 AI 读代码考古，靠"代码+事件轨迹"对照 | 同上（第 3-6 轮，含用户 4 次质疑的修正轨迹） |
| Schema-first | 规格包 schema 是三工具间唯一契约，先于工具代码存在；工具间不直接通信，全部通过规格包接力；槽位可空不可缺 | 第 8 轮 |
| SlotAction 规范 | 已落地 `docs/关卡/SlotAction-使用规范.md`（更早的讨论产出，工具链的层判据直接引用其规则） | 该文档第六节有否决方案留档 |

## 三、工具链现状（tools/analyzer/）

| 组件 | 状态 | 说明 |
|------|------|------|
| **schema** | ✅ v0.1.0 | `schema/spec-package.schema.json`，12 静态槽位 + traces；classes 是一等公民（每方法带六层 layer 标注 + stateWrites） |
| **golden** | ✅ | `golden/spec_292/` 人工对照规格（子集语义：analyzer 产出须为其超集）；DashingWin 难点版 golden **未写**（挂起项） |
| **analyzer** | ✅ 可用 | `scripts/analyze.js`：关卡目录/单文件 → 完整规格包。已实测 292（golden 对齐 0 失败）/287/DashingWin（单文件 6 个内联类正确识别） |
| **recorder** | 🔶 组件齐全，**真实会话未验证** | browserify transform + 动态委托探针 + 浏览器 hook + trace 服务器 + 构建脚本；端到端 mock 自检 11 项全过 |
| **coverage-verifier** | 🔶 雏形 | trace-server 的 `GET /coverage` 即实时版；独立离线报告命令未拆出 |

**验收命令**（全绿状态交接）：
```bash
cd tools/analyzer && npm install
npm run test          # = validate + check:golden + test:recorder 三道门禁
```

**真实录制流程**（README.md 有完整版）：
```bash
node scripts/analyze.js ../../src/newdesign_slot/scene/292_rose_romance --out out/spec_292
./scripts/build-recording.sh res_oldvegas tools/analyzer/out/spec_292   # 录制版构建
node scripts/trace-server.js out/spec_292                               # :3308 收集+实时覆盖率
# 浏览器开 localhost:3307 → console 粘贴 runtime/recorder-hook.js →
# __wtcRecorder.start() / .scene("名字") / .inject(s2cJson) / .stop()
```

## 四、必须理解的四个核心设计（改代码前先读这段）

1. **探针 id = 坐标系**：`文件名#L行C列`。插桩是纯文本行内插入（不是 AST 重打印），**行号严格不变**——运行时日志、静态规格、源码三方共享坐标，互相可跳转。改 instrument.js 时绝不能引入换行；
2. **动态委托探针**：插桩产物头部的 `__wtcProbe` 引导每次调用查全局，无 recorder 时 no-op 透传（录制版可当普通版跑），任意时刻装真实探针即刻生效。真实探针在 `runtime/probe-runtime.js`（带 `__real` 标记）；
3. **场景注入接缝**：`PomeloClient.onProtocol(data)` 是所有 s2c 的统一入口（`src/common/net/PomeloClient.js:244`）——伪造完整 s2c JSON 调它，协议解析/事件分发全走真实代码路径。recorder-hook 的 `.inject()` 就是这么做的；
4. **层判据编码了框架语义**：`src/extract.js` 顶部判据表——例如 `triggerFliter` 恒为 data 层（SlotAction 协议）、Action/Component 写 `this.xxx` 是自身状态不算共享写入（isScene 区分，源自 SlotAction 规范规则 2）。**判据改动必须跑 `npm run check:golden` 回归**。

## 五、已知近似与技术债（都已如实写进 manifest.coverageNotes / README）

- `overrides` 以 callsSuper 判定 → 漏报不调 `_super` 的覆写（需基类知识版修正）；
- state-contract 仅识别 `_` 前缀字段 → 漏报 DashingWin 的 `isSpecialDrum` 类字段和模块级变量；
- config 的 `runtimeMutations`（③层回写配置）未自动回填；
- prototype 风格类（`game.util.inherits`）只登记 require 不深入解析；
- ⑥层 ui-binding 判据已进 schema 但 extract.js 尚无自动判定（292 无 controller，未被逼出来）；
- check-golden 的 4 个常驻警告属于上述近似，是预期行为不是回归。

## 六、下一步候选（上轮给用户的建议，用户尚未选择）

| 选项 | 内容 | 说明 |
|------|------|------|
| **F**（上轮建议） | 真实录制会话验证 | build-recording.sh 构建（几分钟）→ Chrome DevTools MCP 驱动浏览器进 292 → spin/注入 → 验证 traces 落盘与覆盖率上涨。整条链最后一个未验证环节 |
| G | coverage-verifier 独立命令 | 读规格包 traces/ 离线出报告 + 未覆盖分支的场景合成提示（scenarioHint 已在 branches.json 里） |
| H | 回外层主线 | 恢复 N2 比对判定细节讨论 |
| （挂起项） | DashingWin 难点版 golden | 巩固单文件关卡验收基线 |

## 七、工作约定（违反会被用户纠正）

1. **每轮更新 `docs/unity-migration/10-discussion-log.md`**——决策记录（DEC-xx 带否决理由）+ 讨论日志（按轮次），这是"决策时间线"文档，误覆盖已有轮次要立即修复（发生过 3 次，都是 Edit 时吞了相邻标题）；
2. 主项目代码 ES5 强制；**工具本身用现代 Node 写（不受限），但注入到关卡的探针代码必须 ES5**；
3. Git 提交必须用户确认、禁止 AI 标识（Co-Authored-By 等）、提交信息中文；
4. 用户是 SlotAction 原作者、资深且直接——方案有弱点直说，他的质疑往往正确（N1 被他连续修正 4 次，每次都让方案变强）；被质疑时先认账再修正，否决的方案要留档否决理由；
5. 持久化记忆在 `~/.claude/projects/-Users-ghost-work-WorldTourCasino/memory/`，索引 MEMORY.md 已指向本文档。

## 八、关键文件索引

```
docs/unity-migration/10-discussion-log.md   # 决策时间线（12 轮）+ 挂起块 + 待议清单 ← 最重要
tools/analyzer/README.md                    # 工具链使用手册 + 验收基线
tools/analyzer/schema/spec-package.schema.json
tools/analyzer/golden/spec_292/             # 对照规格
tools/analyzer/src/{parse,branches,extract,instrument,browserify-transform}.js
tools/analyzer/runtime/{probe-runtime,recorder-hook}.js
tools/analyzer/scripts/{analyze,validate-spec,check-golden,trace-server,test-recorder-chain,spike-292}.js + build-recording.sh
docs/关卡/SlotAction-使用规范.md             # 层判据的语义来源
docs/unity-migration/00-index.md ~ 09        # v1.0 原方案（部分已被 DEC-02 修订，见 00-index 变更记录）
src/common/net/PomeloClient.js:244           # onProtocol 注入接缝
scripts/build_local_alpha.sh                 # 标准本地构建（browserify 直出，transform 接入点）
```

---

**最后更新**: 2026-07-14
**维护者**: 赵恒
