# CV 线上 crash - convertRGB888ToFormat (OOM 根因)

## 1. 摘要 (TL;DR)

iOS 包 `OldVegasCasino`（Classic Vegas）线上 crash，发生在 `cocos2d::Texture2D::convertRGB888ToFormat`，类型 `EXC_BAD_ACCESS (KERN_INVALID_ADDRESS) at 0x0`。95% 集中在 iPadOS 26，2026-04 起明显上升。**关键观测：crash 时设备可用 RAM 普遍 < 100 MiB、多数在 50 MiB 左右**——这是后续 OOM 根因判断的决定性现场证据（详见 §2.2、§3.2）。

经多轮分析，结论是：**这是一次由 OOM 触发的空指针解引用 crash，而非数据损坏。**

根因可拆为三层叠加：

1. **iPadOS 26 系统侧**：新版本引入 xzone 内存分配器、jetsam 前台限额收紧、系统驻留内存上升，使旧系统能勉强通过的大纹理分配在新系统直接失败。
2. **本仓库资源侧**：`res_oldvegas/` 内存在解压后单图 12–16 MiB 的大资源（如 `my_dream_casino_puzzle_01..05` 五张 2048² PNG，单次加载即 ~80 MiB RGBA）。
3. **代码防御侧**：
   - cocos2d-x 引擎在 `malloc / new[]` 失败时无 nullptr 守卫，直接对 0x0 写入像素数据；
   - iOS 原生层已派发 `memoryWarning` 事件到 JS，但 `src/` 内无任何代码监听——系统的最后一道缓冲机制完全失效（见 §4.4）；
   - 项目历来沿用「加载即缓存、不主动释放」的资源范式，13 个 Loader 中仅 `SlotLoader` 是少数例外，Activity 等其余资源加载后永驻至 app 重启（详见 §4.5）。

单看任何一层都解释不了 crash 现象。**三者叠加**才形成现在的曲线。

---

## 2. 问题背景

### 2.1 信息来源与数据范围

本文档的数据基础是 Firebase Crashlytics 报表（[Firebase 控制台 issue `d81a0d…`](https://console.firebase.google.com/u/0/project/classicvegas-41d2f/crashlytics/app/ios:com.superant.classicvegasslots/issues/d81a0d784d802e289afa492b5e6439cc?time=90d&sessionEventKey=297f3c4bc64e4366bf9c5ecae1d3ce1f_2216782717408001878)）以及随报告附带的设备状态信息。

**直接可证事实**：

- Crashlytics issue 命中函数：`cocos2d::Texture2D::convertRGB888ToFormat`；异常类型：`EXC_BAD_ACCESS (KERN_INVALID_ADDRESS) at 0x0`；
- 过去 90 天事件数、设备 / 系统分布、时间趋势（见 §2.2）；
- 调用堆栈顶部为 `convertRGB888ToFormat`、底部为 `handleTouchEvent` → `touchesEnded:withEvent:`，表明 **crash 发生在一次主线程触摸事件处理过程中**；
- crash 时设备可用 RAM 普遍 < 100 MiB，常见 50 MiB 左右。

**尚未取得的用户感知数据**（开放问题，见 §12）：

- 玩家是否能感知到 crash 前的卡顿 / 黑屏；
- 是否存在"重启后必现 / 偶现"的玩家反馈；
- 客服侧是否有 iPadOS 26 用户的内存类反馈聚集。

> 注：本文档不基于玩家行为叙事，仅基于 Crashlytics + 代码 + 资源 + 系统侧的可证事实推理。

### 2.2 Crashlytics 关键数据（过去 90 天）

| 指标 | 值 |
|------|---|
| 事件数 | 180 |
| 影响用户 | 110 |
| 设备分布 | **98% iPad** |
| 操作系统分布 | **95% iPadOS 26**、2% iOS 26、2% iPadOS 18 |
| 时间分布 | **2026-04 起明显上升，5 月达峰值** |
| 设备状态 | 0% 后台（全部发生在前台） |
| 关键设备状态 | **多数 crash 时设备可用 RAM < 100 MiB，常见 50 MiB 左右** |
| 版本分布 | **78 (3.2.18) ≈ 95%（171 事件）**、77 (3.2.17) 约 3%（5 事件）、71 (3.2.11) 约 1%（2 事件）、其他 < 1% |

> 3.2.18 集中度高的解读见 §3.3 排除性假设。

### 2.3 主线程顶端调用堆栈（关键帧）

```
0  Texture2D::convertRGB888ToFormat        ← Crash 现场 (EXC_BAD_ACCESS at 0x0)
1  Texture2D::initWithImage
2  TextureCache::addImage
3  NodeLoader::parsePropTypeSpriteFrame
4  NodeLoader::parseProperties
5  CCBReader::readNodeGraph (重复多层 = CCB 嵌套加载)
…
14 js_cocos2dx_CCBReader_readNodeGraphFromFile
…
27 ScriptingCore::handleTouchEvent
…
35 -[CCEAGLView touchesEnded:withEvent:]
```

**特征**：JS 触摸事件回调中**同步**加载 CCB 文件 → CCB 引用纹理 → 内存分配 → crash。

### 2.4 涉及代码与资源路径

- C++ 引擎主 crash 位置：`frameworks/cocos2d-x/cocos/renderer/CCTexture2D.cpp`
- C++ 引擎相关：`frameworks/cocos2d-x/cocos/renderer/CCTextureCache.cpp`、`frameworks/cocos2d-x/cocos/platform/CCImage.cpp`
- iOS 原生：`libZenSDK/platform/ios/AppControllerImpl.mm`
- JS 业务：`src/common/model/NativeFunCallbackMan.js`、`src/resource_v2/loaders/*`
- 资源：`res_oldvegas/`

---

## 3. 假设演进过程

为了让分析过程可追溯，下面记录假设的两次迭代。

### 3.1 v1 假设（已被推翻为主因）：图片数据损坏

**初始假设**：iPadOS 26 在 progressive JPEG / Exif 解码路径上行为变化，让某些图片解码"成功但 buffer 为空"或返回**异常长度（< 3 字节）**，触发 `convertRGB888To*` 系列循环中的 `ssize_t l = dataLen - N` 在 dataLen 极小时下溢，产生越界读取。

**支撑迹象**：

- 2026-04 后确实有 `millionaire_s_riches_pt3/pt4.jpg` 等被改造为 progressive JPEG；
- 循环边界确实有"信任输入"反模式。

**为何被降权为次要因素**：

1. 后续提供的关键证据「crash 时设备可用 RAM < 100 MiB」无法用"数据损坏"解释——内存不足与 JPEG 编码方式无直接关联；
2. Crash 类型是 `KERN_INVALID_ADDRESS at 0x0`（明确的空指针），而越界访问通常是 `KERN_PROTECTION_FAILURE` 在非零地址；
3. progressive JPEG 数据本身完整，iOS ImageIO 解码结果通常是有效的 RGB888，不会返回长度为 0/1/2 的"残片"。

**保留**：边界检查作为「次要防线」保留，零成本，能挡其他未来潜在的畸形数据。

### 3.2 v2 假设（现行主因）：OOM + 系统变化 + 防御缺失

**修订假设**：在 iPadOS 26 上，前台 app 可用预算变紧；当用户进入大资源场景时，`malloc()` 在已用 RAM 接近上限时返回 NULL；cocos2d-x 未做 nullptr 检查，直接对 0x0 写入像素数据 → `EXC_BAD_ACCESS at 0x0`。

下一节展开三类佐证。

### 3.3 排除性假设：3.2.18 版本变更（FB SDK 升级）

**假设来源**：见 §2.2 版本分布——crash 95% 集中在版本号 78 (3.2.18)，该版本于 2026-3-20 起发布上线，相对前一版的变更声明为「iOS 升级 Facebook iOS SDK 17.0.3 → 18.0.3」。版本集中度如此之高，自然怀疑：**是否是 3.2.18 的某项变更直接引入了本次 crash？**

**验证过程**：

1. **FB SDK 18.0.x changelog 不涉及内存/纹理**：v18.0.0 官方 changelog 仅 StoreKit 内购事件改进 1 条；v18.0.1/.2/.3 为小功能补丁（链接附件、fast app switching 等）；未涉及内存管理、纹理处理、系统级 swizzle、memory pressure 处理。GitHub Issues 检索：FB SDK 18 在 iOS 26 暴露的问题（#2595、#2580）均为逻辑空指针，与 OOM 无关。

2. **本仓库 FB SDK 与 cocos2d-x 完全隔离**：FB SDK 集成位于 `libZenSDK/platform/ios/Podfile`；启动期调用 `[FBSDKAppEvents shared] activateApp]`、`[FBSDKAppLinkUtility fetchDeferredAppLink:]`，**均不涉及大纹理加载**；FB 图片分享走 SDWebImage → UIImage → FBSDKSharePhoto，与 cocos2d-x TextureCache 不共享调用链、不共享内存池；全代码搜索 FB SDK 不调用 `CCTextureCache` / `CCTexture2D` / `Image` 任何接口。Crash 栈 `convertRGB888ToFormat` 是 cocos2d CPU 端像素转换，FB SDK 不进此路径。

3. **设备分布反证**：crash 95% 集中在 iPadOS 26。若 FB SDK 升级是元凶，影响应跨 iOS 版本均匀分布（SDK 对所有 iOS 版本生效），实际曲线明显指向**系统版本**而非**SDK 版本**。

4. **时间窗反证**：3.2.18 commit 时间为 2026-02-24，发布上线为 2026-03-20，crash 上升起点为 2026-04 初。若 FB SDK 升级是直接致因，crash 应在 03-20 发布后立即显现而非延迟一个月；**实际 1 个月的延迟期与 iPadOS 26 渗透率爬升曲线吻合**。

**附记**：经 commit `178fe174f77` diff 复核，3.2.18 实际变更除 FB SDK 升级外，还包含 `AppController.mm` / `SlotsAppController.mm` 中 `openURL` options 处理从「提取 sourceApplication/annotation」改为「整字典透传」。该改动属 iOS deep link 路径，**与 Texture2D 调用链同样无交叉**，不入主线根因。

**结论**：3.2.18 的所有变更（FB SDK 升级、openURL 透传）均与本案 crash **无因果关联**。3.2.18 与 crash 上升的相关性来自**时间重合**（同期 iPadOS 26 普及），**非因果**。本节作为对 §3.2 主因的反向佐证保留——「我们也排除了 3.2.18 自身的代码变更」。

---

## 4. 证据链

### 4.1 外部佐证：iPadOS 26 系统侧内存策略变化（独立来源交叉验证）

| 来源 | 内容 | 与本案的关联 |
|------|------|--------------|
| [Apple Developer Forums #821168](https://developer.apple.com/forums/thread/821168) | iOS 26.4 起，大内存应用 OOM 频率显著上升 | 同期效应 |
| [Apple Developer Forums #814550](https://developer.apple.com/forums/thread/814550) | iOS 26 引入 **xzone** 新内存分配器，疑似与 OOM 回归相关 | 分配器内部行为变化 |
| [three.js forum](https://discourse.threejs.org/t/memory-limit-crash-on-ios-26/86978) | WebGL 应用在 iOS 18 正常，**iOS 26 切换大纹理时 crash** | 与本案"纹理路径触发"完全同构 |
| [Expo GitHub #40158](https://github.com/expo/expo/issues/40158) | iOS 26.0 SDK 上处理大图触发 EXC_RESOURCE | 大图处理路径在新系统更易爆 |
| [Apple Developer Forums #777370](https://developer.apple.com/forums/thread/777370) | Apple 工程师确认：jetsam 同时考量**总量**与**分配速度**；前台 app 也可能因后台抢占跟不上速度而被杀 | 解释为何"重场景一次性加载"特别危险 |
| [Apple — Jetsam Event Reports](https://developer.apple.com/tutorials/data/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports.md) | 官方 jetsam 机制说明 | 理论依据 |
| [Apple — Responding to low-memory warnings](https://developer.apple.com/documentation/xcode/responding-to-low-memory-warnings) | 官方对内存压力的标准应对：监听 low-memory 通知 | 本项目未实施 |

**小结**：iPadOS 26 的内存生态确实有可观测的回归——并且**多个独立项目**都看到了同一类症状。这与本案 95% iPadOS 26、2026-04 后激增的曲线高度吻合。

### 4.2 内部佐证 A：解压后单图内存占用清单

通过 `sips` 扫描 `res_oldvegas/` 中体积 > 1.5 MB 的图片，计算解压后 RGBA8888 占用：

| 体积 (MB) | 分辨率 | RGBA 占用 | 文件 |
|----------:|--------|----------:|------|
| 5.5 | 2772×1536 | **16.2 MiB** | `res_oldvegas/activity/casino_royale_map_5/xgt5.jpg` |
| 3.2 | 2048×2048 | **16.0 MiB** | `res_oldvegas/fortune_reels/reels/symbol/fortune_reels_anim_batch1.png` |
| 3.7 | 2048×2048 | **16.0 MiB** | `res_oldvegas/activity/my_dream_casino/my_dream_casino_puzzle_05.png` |
| 3.6 | 2048×2048 | **16.0 MiB** | `res_oldvegas/activity/my_dream_casino/my_dream_casino_puzzle_01.png` |
| 3.5 | 1992×2048 | **15.6 MiB** | `res_oldvegas/goldpot_party/reels/bg/goldpot_party_dialog_ui.png` |
| 4.3 | 1977×1834 | **13.8 MiB** | `res_oldvegas/activity/casino_royale/casino_royale_main_map_ui.png` |
| 4.3 | 1798×1855 | **12.7 MiB** | `res_oldvegas/activity/my_dream_casino/my_dream_casino_main_build.png` |

**关键解读**：

- cocos2d-x 在 `convertRGB888ToFormat` 路径上需要**同时持有源缓冲（RGB888，~12 MiB）+ 目标缓冲（RGBA8888，~16 MiB）= ~28 MiB 连续堆内存**——单张 2K 图就足以在「可用 RAM 50 MiB」机器上让 `malloc` 返回 NULL。
- 像 `my_dream_casino_puzzle_01..05` 这种**同活动 5 张 2048² PNG 同时加载**的设计是放大器：合计 ~80 MiB RGBA，叠加大厅常驻和当前关卡的纹理，**必然撞破 jetsam 上限**。
- 这同时解释了 Crashlytics 报告中 crash 集中在**活动入口、大资源关卡、CCB 嵌套场景**（堆栈中 5 层 `readNodeGraph` 嵌套），日常 spin 路径反而不显著。

### 4.3 内部佐证 B：cocos2d-x 内存分配点的防御缺失

引擎层在多处对 `malloc / new[]` 返回值**不做检查**就使用，是 OOM 转为 crash 的直接原因。已审计点：

**`frameworks/cocos2d-x/cocos/renderer/CCTexture2D.cpp`**

| 行号 | 函数 | malloc 处数 | 分配规模典型 |
|------|------|-------------|--------------|
| L895–L921 | `convertI8ToFormat` | 5 | dataLen × 1–4 |
| L944–L975 | `convertAI88ToFormat` | 6 | dataLen × 1–4 |
| **L999–L1030** | **`convertRGB888ToFormat`**（主 Crash 帧） | **7** | **dataLen / 3 × 4**（典型 16 MiB） |
| L1053–L1084 | `convertRGBA8888ToFormat` | 7 | dataLen × 0.5–1 |
| L871 | `initWithImage` 调 `convertDataToFormat` 后未校验出参 | — | — |
| L1229 | 另一处 `convertDataToFormat` 调用未校验 | — | — |

**`frameworks/cocos2d-x/cocos/platform/CCImage.cpp`**（软解码路径）

| 行号 | 场景 | 分配 | 典型大小 |
|------|------|------|----------|
| L1223 | PNG 行指针 | malloc | height × sizeof(ptr) |
| L1564 | PVRTC2 软解 | new(nothrow) 后无判空 | w × h × 4 |
| L1578 | PVRTC4 软解 | 同上 | w × h × 4 |
| L1718 | PVRv3 PVRTC2 | 同上 | w × h × 4 |
| L1749 | ETC1 软解 | 同上 | w × h × 3 |
| L1934 | ASTC 软解 | malloc | w × h × 4 |
| L1945 | ASTC 硬解 | malloc | w × h × 1 |

**`frameworks/cocos2d-x/cocos/renderer/CCTextureCache.cpp`**

| 行号 | 路径 | 状态 |
|------|------|------|
| L351 | `addImageAsyncCallBack`：`new(nothrow) Texture2D` 后无判空直接 `initWithImage` | ❌ |
| L425 | `addImage` 同步路径 | ✓（有短路） |
| L494 | 另一同步路径：无判空 | ❌ |

这是闪退的直接代码位置：任一处 `malloc` 在 OOM 时返回 NULL，下一行立即写入像素数据 → `EXC_BAD_ACCESS at 0x0`，与 Crashlytics 现场完全吻合。

### 4.4 内部佐证 C：Native↔JS 事件断链（"沉默式"缺陷）

iOS 原生层在 `libZenSDK/platform/ios/AppControllerImpl.mm:292-296` 的 `applicationDidReceiveMemoryWarning` 中已经通过 `Utils::onMemoryWarning(memory)` 把事件 + 当前可用内存值派发到 JS 层；JS 侧也具备订阅框架 `src/common/model/NativeFunCallbackMan.js:24` 的 `addNativeFunCallback(funName, callback, target)`。但在整个 `src/` 全局 grep `memoryWarning`：**零结果**——没有任何业务代码注册这个事件。

后果：iOS 系统在内存压力来临时已经向 JS 层喊话，但没人接听。**这条系统级缓冲机制——让 app 在被 jetsam 之前主动释放可释放资源——在本项目内完全失效**，是上述 §4.3 的 OOM 直接转 SEGV 之外、缺失的另一道防线。

这种「派发已就绪、订阅未接入」的事件断链，没有编译错误、没有运行时报警、没有日志痕迹，本文档中称为「**沉默式**」缺陷（术语，不展开；跨案例的工程实践警示见 §9.2）。

### 4.5 内部佐证 D：资源生命周期管理不完整

`src/resource_v2/loaders/` 中存在 13 个 Loader：

```
ActivityLoader.js          ❌ 无 release
BaseLoader.js
CardSystemLoader.js        ❌ 无 release
ClubActivityLoader.js      ❌ 无 release
CouponLoader.js            ❌ 无 release
FeatureLoader.js           ❌ 无 release
FlagStoneLoader.js         ❌ 无 release
GenericLoader.js
LobbyBoardLoader.js        ❌ 无 release
LobbyThemeLoader.js        ❌ 无 release
PosterLoader.js            ❌ 无 release
SlotLoader.js              ✓ 有 releaseSlotResource (L227, L388)
StoreLoader.js             ❌ 无 release
```

**结论**：

- 本项目的资源管理范式是**"加载即缓存、不主动释放"**——依赖 Cocos2d-x 引用计数 + 进程退出时的整体回收。13 个 Loader 中只有 `SlotLoader` 是**少数主动逆传统**的例外（；其余 12 个 Loader **沿用了项目历来的传统**。
- 这种范式在内存宽裕的旧机型 + 旧系统上长期稳定，但在 iPadOS 26 把"前台预算"收紧后，**任何加载即驻留的资源都会变成 jetsam 候选**。
- 具体表现：**活动资源（Activity）加载后基本永驻**——badges_2025、my_dream_casino、casino_royale 等大型活动一旦打开过，纹理与 SpriteFrame 就常驻直到 app 重启；
- 这与「日积月累后某次重活动入口压垮系统」的 crash 触发模式完全一致。
- 视角校准（重要）：本节不应被读作"Loader 设计有缺陷需要修补"，而应被读作"项目历来的资源管理假设（『内存够用、无须主动释放』）在新系统下不再成立、需要补充新范式"。这对修复方案的归类有影响——见 §7.2 不是"修缺失"，是"首次引入主动释放范式到 Activity 域"。

### 4.6 内部佐证 E：场景切换缺少缓存清理

`src/` 全局 grep：

- `removeUnusedTextures` 调用点：基本未见于业务路径；
- 主动 GC（`__jsc__.garbageCollect()` / `JS_GC`）：未见业务层调用。

意味着 Cocos2d-x 的 `TextureCache::_textures` 字典只会**单向增长**，引用计数为 0 的纹理也不会被回收。

---

## 5. 根因综合判断

把 §4.1–4.6 的证据合并成一条因果链：

```
[长期] 资源美术规范缺失
        ↓ 产出
   单图解压后 12–16 MiB 的大纹理
        ↓ 且
   活动设计允许一次性加载 5 张 2048² 拼图
        ↓ 加上
   JS 层无 memoryWarning 监听 + Loader 无 release
        ↓ 形成
   app 长期驻留高水位（高峰 200+ MiB 纹理）

[变量] iPadOS 26 引入 xzone + jetsam 收紧 + 系统驻留上升
        ↓ 使
   老 iPad 上前台 app 可用预算变紧（常见到 < 100 MiB）

[触发] 用户在重活动入口/CCB 嵌套场景下点击触摸
        ↓ 同步加载大 CCB → 引用大纹理
        ↓ 进入 TextureCache::addImage → initWithImage → convertRGB888ToFormat
        ↓ malloc(~16 MiB) 返回 NULL（OOM）

[爆点] cocos2d-x 几十处 malloc 无 nullptr 守卫
        ↓
   *outData = NULL；下一步 memcpy/像素写入 → 解引用 0x0
        ↓
   EXC_BAD_ACCESS (KERN_INVALID_ADDRESS) at 0x0
```

**为什么是 2026-04 开始上升？**
推测两条同时发生的曲线：① iPadOS 26 升级渗透率在 4 月达到关键质量（升级后用户群体扩大）；② 4-5 月的活动节奏（badges_2025、ducky_dollars、millionaire's_riches 等）刚好新增了大资源场景，把潜在风险显性化。

**为什么是 iPad？**
本项目主要付费用户使用 iPad（98% 占比佐证），iPad 横屏分辨率更高、UI 资源天然偏大；同时低 RAM 老款 iPad 在新系统压力下首当其冲。

---

## 6. 风险评估

| 维度 | 评估 |
|------|------|
| 当前影响面 | 110 用户 / 90 天，看似可控，但只在 iPadOS 26 起步阶段测得 |
| 趋势 | 单调上升；iPadOS 26 普及率仍在爬升 → 事件量大概率持续放大 |
| 付费用户暴露 | 高——iPad 用户为主要付费群体 |
| 不修复的最坏走向 | 后续大型活动（高资源量）发版日可能出现尖峰，影响留存与营收 |
| 错误修复的代价 | 若仅做"循环边界检查"，对 OOM 路径完全无效，会误导后续排查 |

---

## 7. 解决方案（三层并行，从止血到治本）

### 7.1 第一层 — C++ OOM 防御（紧急止血）

位置：`frameworks/cocos2d-x/` git submodule（仓库 `https://github.com/LuckyZen/cocos2d-x`）

改动模式：所有 `malloc / new[] / new(nothrow)` 后立刻 `if (ptr == nullptr) return error`，把 OOM 转化为**正常错误返回**而非 SEGV。

核心修改点（汇总自 §4.3）：

- `CCTexture2D.cpp::convertRGB888ToFormat` (L993–L1044)、`convertRGBA8888ToFormat` (L1046–L1099)、`convertI8ToFormat`、`convertAI88ToFormat` — 每个 `*outData = malloc(...)` 后补判空，失败置 `*outDataLen = 0` 并 `return format`；
- `CCTexture2D.cpp::initWithImage` (L871、L1229) — `convertDataToFormat` 返回后校验 `outTempData != nullptr`，否则返回 `false`；
- `CCTexture2D.cpp` 的 14 个 `convertRGB888To*` / `convertRGBA8888To*` 子函数（L326–L482） — 循环边界改为 `i + N < dataLen` 形式（次要防线，挡 dataLen 异常）；
- `CCImage.cpp` 软解码路径 L1223 / L1564 / L1578 / L1718 / L1749 / L1934 / L1945 — 全部补判空；
- `CCTextureCache.cpp` L351、L494 — `new(nothrow) Texture2D` 后判空。

拦截后效果：

- 纹理显示为**透明**而非闪退；
- `CCLOGERROR` 留痕，可用于后续诊断；
- 4 个风格（CV/DH/VS/DHX）共用同一 submodule，**一次合入全部受益**。

### 7.2 第二层 — JS 层内存治理（治本，跨风格共享）

**A. 接通 memoryWarning 事件（对应 §4.4 的核心缺口）**

新建 `src/common/model/MemoryWarningMan.js`（ES5），通过 `NativeFunCallbackMan.getInstance().addNativeFunCallback('memoryWarning', ...)` 注册，回调内执行：

1. `cc.textureCache.removeUnusedTextures()`；
2. `cc.spriteFrameCache.removeUnusedSpriteFrames()`；
3. （若可用）`__jsc__.garbageCollect()`；
4. 派发自定义事件让业务侧关闭非关键弹窗；
5. BI 上报当前内存值。

在 `src/main.js` 启动序列初始化阶段注册一次。建议 5 秒节流，避免反复触发。

**B. 场景切换主动清理**

在以下入口的 loading 完成、显示新场景之前调用 `cc.textureCache.removeUnusedTextures()`：

- `src/loader/SlotLobbyLoadingController.js`（进入大厅）；
- `src/loader/SlotRoomLoadingController.js`（进入关卡）；
- 各 Activity 主控（在 onExit 时调用）。

**C. 将主动释放范式扩展到 Activity 域**

> 这不是"修补 ActivityLoader 漏掉的释放"，而是把 `SlotLoader` 现有的主动释放范式**首次扩展**到 Activity 域（参考 §4.5 的视角校准）。项目历来无此范式，本次是范式引入而非缺陷修复。

`src/resource_v2/loaders/ActivityLoader.js` 新增 `releaseActivityResource(activityId)`，对齐 `SlotLoader._unloadMachineSceneResource`（L388）的实现模式：读 `activity/<name>/resource_preload_list.json` → 遍历 `cc.textureCache.removeTextureForKey` + `cc.spriteFrameCache.removeSpriteFramesFromFile`。

后续可视收益决定是否推广到其他 11 个 Loader——但应**评估业务侧使用频率与释放成本**后再扩，而非批量补丁式铺开（避免破坏现有依赖"缓存常驻"的业务路径）。本次先解决 Activity（badges_2025 等直接相关）。

### 7.3 第三层 — 资源治理 + 监控（长期防线）

**A. 大图治理（针对 §4.2 清单）**

| 图片 | 治理建议 |
|------|----------|
| `my_dream_casino_puzzle_01..05.png` (5×16 MiB) | 拼图天然分块——拆为 4 张 1024² 子图，或合并 atlas |
| `xgt5.jpg` 2772×1536 (16 MiB) | 降分辨率到 1536×860，或裁切非视觉区域 |
| `fortune_reels_anim_batch1.png` 2048² (16 MiB) | 评估是否可拆 atlas、走 PVRTC/ASTC GPU 压缩 |
| `goldpot_party_dialog_ui.png` 1992×2048 (15.6 MiB) | UI 弹窗类降到 1024 视觉损失通常可接受 |
| `casino_royale_main_map_ui.png` 1977×1834 (13.8 MiB) | 同上 |

**B. 构建期资源体检**

新增 `scripts/check_image_budget.sh`，扫描所有图片解压后 RGBA 占用，超阈值（如单图 > 12 MiB）则**构建警告**（先警告后阻断）。挂到各风格 `build_local_*.sh` 前置阶段。

**C. 设计规范**

将「单图 RGBA ≤ 12 MiB、单场景同时加载图总 RGBA ≤ 80 MiB」写入资源 / 美术规范，纳入 `docs/工程-工具/ai-rules/` 资源约束章节。

**D. 内存埋点**

抽 `HR2EntranceController._getMemoryInfo` 到 `src/common/util/MemoryUtil.js`，在 app 启动、大厅进入、关卡进入、活动入口、内存警告等关键节点上报可用 RAM；建立内存水位的现网监控。

**E. 预算守门（可选，挂远程 Toggle）**

进入重资源活动 / 关卡前测可用 RAM；低于阈值（iPad 200 MiB / iPhone 150 MiB）先主动清理，仍不足则弹「内存不足，请重启应用」并 BI 上报。

---

## 8. 验证与灰度

### 8.1 复现路径

1. iPadOS 26 真机，借助内存压力工具把可用 RAM 压到 < 80 MiB；
2. 进入 CV → Millionaire's Riches → 开 badges_2025 → 切 Ducky Dollars；
3. 现网包应在某次纹理加载时 crash 在 `convertRGB888ToFormat`；
4. Xcode → Scheme → Diagnostics 启用 **Malloc Scribble + Guard Edges**，可精确定位 NULL 解引用点。

### 8.2 补丁分级验证

| 加载补丁 | 预期效果 |
|----------|----------|
| 仅 §7.1 C++ 防御 | Crashlytics 该 issue 归零；部分纹理可能显示透明 |
| 加 §7.2 JS 治理 | 透明纹理消失，整体内存水位下降 |
| 加 §7.3 资源治理 | 大图数量减少，OOM 概率根本性下降 |
| 加 §7.3 预算守门 | 低内存设备进入重场景前被提示，UX 优于闪退 |

### 8.3 灰度路径

1. **C++ 补丁先发**（独立于其他改动，最短路径见效）：4 风格 submodule SHA 同步 → 内测 1 天 → TF 5% → 50% → 100%；
2. **JS 治理**：内测 2 天 → 灰度滚动；
3. **预算守门**：默认 Toggle 关闭 → 10% → 50% → 100%；
4. **资源治理**：随后续版本节奏推进，构建期校验作为长期机制。

### 8.4 观察指标

- [Crashlytics issue `d81a0d…`](https://console.firebase.google.com/u/0/project/classicvegas-41d2f/crashlytics/app/ios:com.superant.classicvegasslots/issues/d81a0d784d802e289afa492b5e6439cc?time=90d&sessionEventKey=297f3c4bc64e4366bf9c5ecae1d3ce1f_2216782717408001878) 事件数（目标：3 天内阶梯式归零）；
- 现网内存埋点 P50/P95 可用 RAM 走势；
- 重场景进入阻塞率（预算守门启用后）；
- 用户活动留存 / 关卡完成率（防回归）。

---

## 9. 风险、回滚与工程实践警示

### 9.1 风险与回滚

| 风险点 | 措施 |
|--------|------|
| C++ 补丁误伤正常路径 | 改动仅在异常分支生效（malloc 返回 NULL 时）；可通过回滚 submodule SHA 回退 |
| `removeUnusedTextures` 误删即将引用的纹理 | 5 秒节流 + Toggle 控制；最坏情况是临时重新加载 |
| 预算守门误判 | 阈值远程下发 + BI 监控阻塞率，可随时调整或关闭 |
| 资源压缩 / 拆分影响视觉 | 美术评审 + A/B 灰度 |
| 4 风格同步成本 | submodule 共享 C++ 一次；`src/` 共享 JS 一次；`res_*/` 独立，资源治理按需 |

### 9.2 工程实践警示（来自 §4.4）

本案暴露的"沉默式内存事故"模式值得团队沉淀：

1. **建立 Native ↔ JS 事件 registry**：任何由 native 派发的事件应有显式注册清单，新事件加入或长期无监听都应触发警告。
2. **审计现有 native 事件接入率**：除 memoryWarning 外，检查其他事件（低电量、网络切换、远程通知、应用前后台切换）是否也有"派发但无监听"的情况。
3. **iOS 标准生命周期方法的对接 checklist**：`applicationDidReceiveMemoryWarning`、`applicationWillTerminate`、`applicationDidEnterBackground` 等应纳入跨端契约文档（建议沉淀到 `docs/工程-工具/ai-rules/` 或 native 章节）。

---

## 10. 关键文件索引

C++ 引擎层：

- `frameworks/cocos2d-x/cocos/renderer/CCTexture2D.cpp`
- `frameworks/cocos2d-x/cocos/renderer/CCTextureCache.cpp`
- `frameworks/cocos2d-x/cocos/platform/CCImage.cpp`

iOS 原生层：

- `libZenSDK/platform/ios/AppControllerImpl.mm:292-296`

JS 业务层：

- `src/common/model/NativeFunCallbackMan.js`
- `src/resource_v2/loaders/SlotLoader.js`（参考模式）
- `src/resource_v2/loaders/ActivityLoader.js`（待补 release）

大图集中区：

- `res_oldvegas/activity/my_dream_casino/`
- `res_oldvegas/activity/casino_royale/`
- `res_oldvegas/activity/casino_royale_map_5/`
- `res_oldvegas/fortune_reels/reels/symbol/fortune_reels_anim_batch1.png`
- `res_oldvegas/goldpot_party/reels/bg/goldpot_party_dialog_ui.png`

---

## 11. 参考资料

- [Apple Developer Forums — Increased crash occurrence in iOS 26.4](https://developer.apple.com/forums/thread/821168)
- [Apple Developer Forums — iOS 26 Crash: xzone allocator regression](https://developer.apple.com/forums/thread/814550)
- [Apple Developer Forums — Increased Memory Limit, Extended Virtual Addressing](https://developer.apple.com/forums/thread/777370)
- [three.js forum — Memory limit crash on iOS 26](https://discourse.threejs.org/t/memory-limit-crash-on-ios-26/86978)
- [GitHub expo/expo#40158 — Memory crash on iOS 26](https://github.com/expo/expo/issues/40158)
- [Apple Developer Documentation — Responding to low-memory warnings](https://developer.apple.com/documentation/xcode/responding-to-low-memory-warnings)
- [Apple Developer Documentation — Identifying high memory use with jetsam event reports](https://developer.apple.com/tutorials/data/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports.md)

---

## 12. 待跟进事项（开放问题）

- [ ] Crashlytics 拉取**设备型号分布**（验证"老款低 RAM iPad 在 iPadOS 26 上首当其冲"的推论）
- [ ] 拉取 iPadOS 26 vs iPadOS 18 的事件占比时间序列（确认时间相关性）
- [ ] 评估接入 `Increased Memory Limit` entitlement 的可行性（仅缓解，非根治）
- [ ] 检查 res_doublehit / res_vegasstar / res_doublex 是否存在同类大图（其他风格的潜在隐患）
- [ ] 与美术 / 策划评审「单图 ≤ 12 MiB、场景 ≤ 80 MiB」规范的可执行性
- [ ] 审计 native 事件接入率（来自 §9.2 工程实践警示）
- [ ] 联合客服 / 社区收集 iPadOS 26 玩家反馈，验证用户感知层（来自 §2.1 标注的开放项）

> 本文档定位：技术分析与方案陈述，不包含立即执行的代码改动。修复落地需要单独的实施计划与评审流程。
