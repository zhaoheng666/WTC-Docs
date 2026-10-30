---
title: Board Adda APK 逆向分析技术验证
---

# Board Adda APK 逆向分析技术验证

> 源自飞书文档 · 最后同步：2026-10-30

## 本次验证更新：REA 已完成原生行为分析

本轮由 REA MCP 检查 Board Adda 原始 ARM64 libil2cpp.so，返回函数、调用路径、汇编和值流证据；Agent 据此解释合并、计分和判负。使用官方源码提交加一处已留档的适配桥补丁，首次分析耗时约 320 秒。第 8 节提供实际调用、行为结论、环境修复与限制；下方第 1–7 节和原流程图保留首次拆包阶段的来源说明，不应当作当前能力上限。

![](/feishu/Board-Adda-APK-逆向分析技术验证/00-Board-Adda-APK-逆向分析技术验证/img-1.png)

补充实测截图：REA 启动并采集官方 Play 安装的 Board Adda 主菜单；REA 拉取的 APK 哈希与最初样本一致。此图证明启动结果，合并、计分和判负结论来自第 8 节的静态机器码证据，尚未进行受控滑动的动态对照。

---

2026年10月13日 · 发布包版本 1.0015 · 静态分析验证

本实验以 Board Adda 的发布 APK 为输入，验证 REA 对专业逆向工具的调用与证据输出，并交付可检查的代码和资源。REA 已完成 APK 提取和 JADX 方法分析；IL2CPP 代码与 Unity 资源批量导出由 Agent 直接调用外部工具完成。

## 1 验证目标与输入

目标包名 com.livegames.boardgames，版本 1.0015，版本号 15。输入为原始 base APK 与 arm64_v8a split APK。游戏采用 Unity IL2CPP：Android 层位于 DEX，主要游戏实现位于 libil2cpp.so，类型与方法映射来自 global-metadata.dat。

验收范围为真实发布包的代码、资源和可复查证据。此次文档记录静态拆包结果，不包含修改重打包或运行行为验证。

## 2 工具链与职责

| 工具与版本 | 实际调用方式 | 本次用途 |
| --- | --- | --- |
| REA 6.4.0 | Agent 调用 REA | APK 内容提取、JADX 方法查询、结构化 Evidence |
| JADX headless 0.7.1 | REA 单方法调用；Agent 直接批量导出 | DEX 反编译；0.7.1 为封装版本，JADX API 自报版本为 dev |
| Apktool 2.12.1 | Agent 直接调用 | Manifest、Android 资源与 Smali 导出 |
| Il2CppDumper 6.7.46 | Agent 直接调用 | 类型声明、字段布局与原生方法地址恢复 |
| Ghidra 12.1.4 | Agent 直接调用 | 选定游戏方法的 AArch64 反编译与反汇编 |
| UnityPy 1.25.4；TypeTreeGeneratorAPI 0.0.10 | Agent 直接调用 | Unity 素材、场景层级与组件字段解析 |

Agent 负责路线选择、环境准备、脚本编排和结果核验；REA 通过已配置的 provider 调用分析引擎并输出证据。安装 REA Skill 本身不会安装这些引擎。

![](/feishu/Board-Adda-APK-逆向分析技术验证/00-Board-Adda-APK-逆向分析技术验证/img-2.png)

图 1 · 实际工具调用关系：绿色路线为本次已完成的 REA → JADX 调用，灰色路线为 Agent 直接调用外部工具。独立 REA → Ghidra 尝试未完成。[ 下载交互图（HTML）](https://ghoststudio.feishu.cn/file/X73GbZ8Fvon8bex6ZMmcDKw9n6H)，下载后用浏览器打开。

## 3 REA 调用验证

验证链路为 Agent → REA inspect_android_method → JADX → Java 方法代码。下列为已完成调用的等价摘要；先加载 bin/rea-lab/env.sh，APK 变量指向原始 base APK。

```bash
npx -y rea-agents@6.4.0 inspect-android-method "$APK" \
  com.unity3d.player.UnityPlayerActivity \
  onWindowFocusChanged --format json --full-output
```

返回结果为 representation=java、body_status=available、fell_back=false；方法体调用 super.onWindowFocusChanged(z3) 与 mUnityPlayer.windowFocusChanged(z3)。Evidence 同时保留样本 SHA-256、provider、调用参数、原始返回值和分析限制。

对应证据 rea-jadx-window-focus.json：`work/livegames-boardgames/decompiled/evidence/rea-jadx-window-focus.json`

## 4 拆包成果

| 产物 | 核验数量 | 覆盖范围与用途 |
| --- | --- | --- |
| Java 与 Smali | 14,163 / 18,177 文件 | Android 入口、SDK 和嵌入 DEX；保留字节码对照 |
| C# 类型声明 | 7,139 类型 / 80 程序集 | 恢复签名、字段和布局；不含原始方法实现 |
| 原生伪代码 | 2,386 方法 / 391 类文件 | 覆盖 19 个选定游戏及公共程序集；最终导出失败数为 0 |
| AArch64 指令 | 188,872 条已解码指令 | 全部选定方法保留原始字节与汇编范围 |
| 可浏览素材 | 632 PNG / 36 WAV | 另有 13 OBJ、10 字体文件及文本等资源 |
| 场景与对象 | 20 场景层级 JSON；15,896 对象 JSON | 完整对象索引覆盖 15,915 个序列化对象 |

可检查 ChessBoard、BoardScript 与 TileManager 等实际游戏代码。这里的 two048.dll 属于 Board Adda 原 APK 内的 2048 模块。交付同时保留 Ghidra 项目、原始伪代码、按地址添加名称注释的阅读版、类型声明和资源图库。

![](/feishu/Board-Adda-APK-逆向分析技术验证/00-Board-Adda-APK-逆向分析技术验证/img-3.png)

图 2 · 真实资源预览：从本次导出的 632 张 PNG 中选取 16 张，保留资源名称。素材包括棋盘、棋子、模块入口与 Logo；由 UnityPy 解析和解码导出，未加入自定义解密步骤。

## 5 资源解码方式

图片导出流程为 APK 提取 → UnityPy 解析 Unity Data → Texture2D／Sprite 解码 → PNG。Apktool 本次用于 Manifest、Android 资源和 Smali，不能单独导出这批 Unity 游戏图片。

脚本直接使用 UnityPy.load(source) 读取资源，通过 data.image 和 image.save(...) 导出 632 张 PNG，未提供密钥或加入自定义解密步骤。二进制封装、压缩与纹理编码不等于加密；成功导出的这批图片未遇到需要额外破解的加密层。

因此，图片部分验证的是资源格式解析和导出能力，不能作为破解加密资源的能力证明，也不能据此认定整个 APP 的所有数据都未加密。组件类型树恢复用于 MonoBehaviour 字段解析，与图片解码是不同步骤。

- 资源导出脚本：`scripts/export_unity_resources.py`
- 工具与调用记录：`work/livegames-boardgames/decompiled/evidence/unity-tool-provenance.json`
## 6 核验方法与结果

原始内容核验：两个 APK 共 830 个普通文件逐项进行 SHA-256 对照，无缺失或不匹配。原生地址核验：按 Ghidra 加载基址 0x100000 映射 RVA，全部 2,386 个方法入口及导出的完整方法范围均与原 ELF 字节匹配。

反编译修正：依据原始指令中通向 __cxa_throw 的调用链，将两处 IL2CPP 异常辅助函数标记为不返回，再重新反编译全部选定方法。最终 2,386 个方法均得到伪代码；该结果表示工具成功输出，不代表已证明所有方法语义等价。

## 7 能力边界与未完成项

REA → Ghidra 的独立尝试在全程序分析阶段阻塞，未获得完成结果，不能计入 REA 的成功能力。本次原生批量导出采用 Agent 直接调用 Ghidra 的路线。

JADX 报告 28 个错误、1,353 个警告，15 个 Java 文件含未恢复的方法；相关 Smali 已保留。Unity 中 18 个 MonoBehaviour 和 1 个 PlayerSettings 未完整解析，保留原始字节；15 个纹理缺少图像 payload，1 个 Shader 文本导出失败但 JSON 保留。

输出为反编译分析工程。C# 声明及 DummyDll 仅为类型骨架；原生伪代码含推断类型与控制流。未逐函数导出全部 Unity 引擎和第三方 native 库，也未恢复可直接构建的原始 Unity 工程。静态结果不等于运行验证。

本次已验证 REA 的 APK 提取、JADX 接入与证据输出；代码与资源规模体现整个 Agent 工具链的交付成果。成果数量和能力归属应分别评价。

- 交付索引：`work/livegames-boardgames/decompiled/README.md`
- 核验报告：`work/livegames-boardgames/decompiled/verification.json`
- 游戏伪代码：`work/livegames-boardgames/decompiled/code/unity-il2cpp/readable-pseudocode/Chess.dll/SubGames.Chess.Scripts.Protocol/05829_ChessBoard.c`
- Unity 资源图库：`work/livegames-boardgames/decompiled/resources/unity/index.html`
证据文件位置均相对于本地实验目录 `bin/rea-lab/`，用于复查原始交付文件，不是飞书在线附件。

## 8. REA 原生行为分析补充验证（2026-10-13）

本轮验证直接向 REA MCP 提交原始 ARM64 二进制，让 REA 返回函数分析、调用关系、指令和值流，再由编程助手解释行为。对象是 Board Adda 内置 two048.dll 对应的 IL2CPP 机器码，区别于前述从开源项目编译的 2048 演示。首次批量导出的来源仍保持原有说明，不计作本轮 REA 结果。

### 8.1 输入与工具调用

输入：原始 split APK 中的 libil2cpp.so，44,974,744 字节；SHA-256：83e7745735758a3d22f9c413d8ed9d96613eef9eb148cb2c3e6789253d80e4bf。REA 从当前 Play 安装拉取的 base/split APK 哈希也与最初样本完全一致。IL2CPP 元数据仅提供函数地址、名称和字段布局提示；没有把先前直接调用 Ghidra 的伪代码喂给 REA。

以下是本轮实际 MCP 请求的节选；完整参数、耗时、原始返回和文件哈希均已保存。

```json
{"name":"open_binary","arguments":{"path":"/Users/ghost/MySpace/bin/rea-lab/work/livegames-boardgames/decompiled/raw/arm64/lib/arm64-v8a/libil2cpp.so","provider_id":"ghidra"}}
{"name":"analyze_function","arguments":{"procedure":"0x23c7f60"}}
{"name":"analyze_function","arguments":{"procedure":"0x23c87dc"}}
{"name":"trace_call_path","arguments":{"start":"0x23c812c","goal":"0x23c7f60","direction":"forward"}}
{"name":"inspect_native_instruction","arguments":{"address":"0x23c8538"}}
```

REA 启动 Ghidra 适配桥并返回 Evidence；记录客户端仅收发 MCP 请求和保存响应，没有实现反编译逻辑。首次函数查询耗时 320.111 秒，包含导入与自动分析；后续查询复用当前数据库。这个结果不能描述为瞬间按函数完成分析。

### 8.2 由 REA 结果解释程序行为

| 分析对象 | REA 实际返回 | 可支持的行为解释 |
| --- | --- | --- |
| OnSwipeFromInput → SwipeGrid → MergeAt | trace_call_path 返回目标可达及三节点路径 | 手势输入进入滑动处理，再记录合并动画 |
| SwipeGrid，0x23c8420 | 函数伪代码、汇编与引用；0x23c8538 为 add w9,w9,#1 | 相等非零格合并时，目标指数加一，来源格清零 |
| MergeAt，0x23c7f60 | 184 字节函数体；列表写入和延时字段赋值 | 记录待合并位置与动画延时，本函数没有加分 |
| GetGridValueByPoint，0x23c80f4；OnScoreUpdate，0x23c90b4 | ldexpf(1.0,n)、整数转换、加法与写回指令 | 格子存指数；计分按 2^输入指数累加，而非直接加指数 |
| CheckGameOver，0x23c87dc | 空格检查、横纵相邻比较、对 OnGameOverConfirm 的直接调用 | 棋盘已满且无横纵相邻同值格时判负；有空格或可合并邻格则继续 |

例如指数 1 对应显示值 2，合并后指数变为 2、显示值为 4；计分函数接收指数 2 时增加 4 分。这是静态指令推导，本轮没有做受控滑动与分数内存的动态对照。合并动画回调会传出格子指数，但间接委托到具体 UI 方法的运行时绑定尚未通过 Hook 验证。

可直接检查的原始指令节选：

```
0x23c8538: add w9, w9, #0x1    // 目标格指数 +1
0x23c853c: str w9, [x8, #0x20]
0x23c8544: str wzr, [x11]      // 来源格归零
0x23c911c: add w8, w8, w22     // 累加旧分数
0x23c9124: str w8, [x21]       // 写回分数
```

分工边界：Ghidra 提供机器码分析引擎；REA 提供 MCP 分析接口、函数资料、调用路径和值流查询及 Evidence 导出；Agent 选择问题，结合元数据解释字段，发现伪代码异常并用指令复核结论。实际分析查询通过 REA 完成，Agent 的解释不等同于引擎观察。

### 8.3 成果、环境修复与限制

本轮记录 25 次 REA 调用，保存全部完整响应，并由 REA 导出 21 条 Evidence 的证据包和会话快照。MergeAt 的 184 字节指令另经文件偏移映射，与原始 ELF 逐字节一致。REA 对官方 Play 包执行了启动及截图，记录可见主菜单；该截图仅证明启动结果，不证明上面的静态行为已完成动态验证。

原始调用台账：/Users/ghost/MySpace/bin/rea-lab/work/livegames-boardgames/rea-behavior/on-demand/mcp-call-ledger.json 行为与指令索引：/Users/ghost/MySpace/bin/rea-lab/work/livegames-boardgames/rea-behavior/behavior-claims.json REA 证据包：/Users/ghost/MySpace/bin/rea-lab/work/livegames-boardgames/rea-behavior/native-evidence-bundle.json

可复现环境：REA 官方仓库源码提交 747e7299141cec0b03774c427f579889d5088d20（包版本仍为 6.4.0），Ghidra 12.1.4、ARM64 OpenJDK 25。发布版配置缺失和旧 x86_64 Java 均已修正。为了让种子导入后指定的分析器禁用设置生效，REA 的 Ghidra 适配桥增加一处清理陈旧分析队列的本地补丁；未修改游戏二进制。此处验证的是“官方源码 + 已记录适配修复”，不宣称原发布版开箱即用。

本样本禁用了 GCC Exception Handlers、Call-Fixup Installer、两个 Non-Returning Functions 分析器、Decompiler Switch Analysis 和 Basic Constant Reference Analyzer。异常辅助函数的不返回属性未完整恢复，部分伪代码会延伸到邻近方法；正文结论均以报告的函数体地址范围内的 ARM64 指令复核。深度为 0 的值流图包含 169 节点、187 边，仍标记截断及未解析调用，不能当作全程序数据流。另一次异常辅助函数查询超过 MCP 10 MiB 响应预算，REA 保留结果供导出，该内联查询按错误记录。

本轮已验证 REA 可向编程助手提供原生 ARM64 行为分析证据；没有据此证明所有目标格式均可逆向，也没有把元数据提示、Agent 推理和外部工具批量导出混为一项 REA 能力。
