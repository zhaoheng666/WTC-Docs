# CV iOS 激励广告卡死 - 打点分析与广告源定位

## 摘要

| 项目 | 内容 |
|------|------|
| 状态 | 🔍 已定位嫌疑链路（Google 需求 × GMA iOS 11.13 渲染），未根治 |
| 平台 | iOS（Android 同存在老版本风险） |
| 现象 | 玩家反馈 2026-07-09、2026-07-21 观看激励视频时卡死，只能杀进程 |
| 数据实锤 | 30 天内该玩家 498 次展示，63 次（12.7%）**既无播完也无关闭回调**；7/7-7/11 为重灾窗口 |
| 广告源 | 两例截图取证均为 **Google（AdMob）需求**，由 GMA SDK 渲染（置信度 93 / 85） |
| 嫌疑根因 | 2026 新版 Google 自动拼装 web 视频模板 × 19 个月前的 GMA iOS 11.13 渲染管线；创意 WKWebView WebContent 进程死亡/JS 停摆 |
| 关键版本 | AppLovinSDK 13.0.1 + AppLovinMediationGoogleAdapter **11.13.0.0**（GMA 11.13.0，2024-12，已被官方 deprecated） |
| 关键文件 | `src/ads/model/AdControlMan.js`、`src/log/model/LogMan.js`、`src/log/enum/AdStepType.js` |

---

## 一、广告打点体系

### 两张表

| 表 | 上报入口 | 用途 |
|----|---------|------|
| `adInfo` | `LogMan.rewardAdRecord / adRecord`（`src/log/model/LogMan.js:360`） | 页面级统计：`cur_page` 2=RV播完、3=RV就绪统计、6=RV展示、7=点击入口、8=插屏加载成功 |
| `adStepInfo` | `LogMan.adStepRecord`（`src/log/model/LogMan.js:461`） | 广告生命周期步骤，字段 `ad_cur_step` / `ad_channel` / `ad_unit_id` / `ad_priority` / `ad_placement` |

### RV 步骤枚举（`src/log/enum/AdStepType.js`）

| ad_cur_step | 含义 | 带广告源? |
|---|---|---|
| 1100 | RV 请求 | ⚠️ 仅 local/debug 上报（`AdControlMan.js:987`），线上无数据 |
| 1101 | 加载成功 | ✅ ad_channel + ad_unit_id + ad_priority |
| 1102 | 加载失败 | ✅ 但未带错误码 |
| 1103 | 展示 | ❌ channel 传空串，只有 ad_placement |
| 1104 | 广告被点击 | ✅ |
| 1105 | 关闭 | ❌ |
| 1106 | 未完整观看关闭 | ❌（已失真，见下） |
| 1107 | 视频播完 | ❌ |
| 1108 | 开始结算 | ❌ |
| 1109 | 领奖协议返回 | ad_priority 复用为 errorCode |
| 1110 | 连续观看次数 | ad_priority 复用为次数 |

### 打点自身的缺陷（本次排查发现，建议修复）

1. **RV 广告源字段全是占位符**：原生回调 JSON 里 `channelName` 恒为 `"AdMax"`（聚合层名，非胜出网络名）、`unitId` 恒为字面量 `"unitId"`——导致线上无法回答"卡死时是哪家广告网络"。对比：插屏 1001 有真实 unit id。
2. **1106 与 1105/1107/1108 逐日完全相等**：CLOSED_WITHOUT_FULLVIEW 随正常完成一起触发，已失去"提前关闭"的区分意义。
3. 1102 加载失败未带错误码；1103 展示时 channel 传空，无法与广告源直接关联（只能靠同用户时间序关联最近一条 1101）。

---

## 二、玩家打点数据分析（2026-06-23 ~ 07-22）

### adInfo：展示(6) vs 播完(2) 缺口

| 日期 | 展示 | 播完 | 缺口 | 缺口入口 |
|---|---|---|---|---|
| 06-25 | 12 | 3 | **9** | newRewardGame×8 |
| 07-07 | 17 | 12 | 5 | newRewardGame×5 |
| 07-08 | 17 | 11 | 6 | newRewardGame×6 |
| **07-09 反馈日** | 9 | 8 | 1 | newRewardGame×1（当日活跃骤降为平时一半，符合卡死后弃玩） |
| 07-10 | 24 | 11 | **13** | newRewardGame×11（展示 21 次远超日常 9 次，疑似反复重试） |
| 07-11 | 26 | 20 | 6 | newRewardGame×5, BigWin×1 |
| **07-21 反馈日** | 17 | 16 | 1 | TicketPoster×1 |
| 07-22 | 6 | 2 | 4 | newRewardGame×4（反馈次日仍在发生） |

其余日期缺口 0~2。问题集中在 `newRewardGame` 入口（`src/ads/controller/newRvGame/`）。

### adStepInfo：卡死定性

30 天漏斗：**展示(1103) 498 → 关闭(1105) 435 / 播完(1107) 434**。

关键推断：1105 与 1107 逐日几乎完全相等——正常"提前关闭"会产生**有关闭、无播完**的记录，但一条都没有。丢失的 63 次全部是：**广告打开 → 无任何回调 → 玩家杀进程**。这与代码注释自证的现象一致（`AdControlMan.js:795`："存在相当的几率，不回调"）。

辅助信号：加载失败(1102)共 1631 次 vs 成功 676 次；卡死周伴随失败风暴（07-07: 129、07-08: 122、07-10: 162），但 07-05(176)、06-26(111) 有风暴无卡死——是诱因非充分条件。

---

## 三、广告源定位（两例截图取证）

### 项目实际集成的 MAX adapter（候选集）

| 端 | 网络 | 版本证据 |
|---|---|---|
| iOS | Google AdMob、Meta AN、ironSource、Chartboost、Unity Ads | `libZenSDK/platform/ios/Podfile.lock`：Google adapter 11.13.0.0（GMA 11.13.0）、AppLovinSDK 13.0.1 |
| Android | Google AdMob、Meta AN、ironSource、Chartboost | `libZenSDK/platform/android/java/build.gradle`：applovin-sdk 11.5.5 + google-adapter 21.3.0.2（很老） |

### 案例 1：Little Mania 摔跤秀（结束端卡）

![案例1-Little Mania 端卡](/assets/4b8ec94d232800b5250a1bc99a665dfc.png)

- **判定：Google（置信度 93）**，多智能体指纹比对中其余四家均只有 3 分，三路对抗复核未能推翻
- 决定性指纹：深炭灰底 + 平铺菱形 ✕ 暗纹（GMA 端卡模板标志性纹理）；「图标+标题+**裸域名**+白色扁平 Learn More」的文字资产拼装排版（竞品模板无"裸域名"槽位）；Roboto 字体
- 需求端实锤：广告主 Tristan David Events LLC 在 **Google Ads Transparency Center 可查**（advertiser ID AR09335657514357751809），落地页带 Google Ads 转化标签 AW-17054584943，素材截至 7/22 在投

### 案例 2：Life in Indy 城市宣传（播放中冻结帧）⭐ 直接拍到卡死机制

![案例2-Life in Indy 冻结帧](/assets/991c40c0b03166bf8627b10cc73040ff.png)

- **判定：Google（置信度 85）**，Meta 6 / ironSource 6 / Chartboost 4 / Unity 3
- 这张截图本身就是卡死现场证据：
  - 球员/篮球有运动模糊 → **视频播放中途冻结**，非结束端卡
  - **倒计时/静音/关闭X/AdChoices/进度条全部缺失**——正常播放中不可能全缺
  - 广告容器未铺满屏幕，底部露出游戏画面
- 需求端实锤：广告主 Life in Indy（印第安纳波利斯商会 "Speed City" campaign，2026-04-28 上线），经代理 Longworth Media 在 Google Ads 投放，ATC 有 40 条视频素材在投至 7/22
- 复核修正：ironSource 存在 Basis DSP→ironSource Exchange 的程序化通路，"其余网络不可能承载 web 广告主"的论据不成立，但该通路应呈现全屏 VAST 版式，与截图的 Google 拼装模板不符，主结论不受影响

**结论：两例卡死均为 Google 需求，经 `AppLovinMediationGoogleAdapter` 由 GMA SDK 渲染。**

---

## 四、GMA 版本查证：新版是否已修复？

**结论：partial——没有任何官方修复条目能确认对应本症状，升级必要但不充分。**

### Google 官方对该症状族的定性（关键认知）

官方论坛同类帖（"Close button missing (iOS, rewarded video)"）中 Google 明确回复：**倒计时/静音/关闭等控件不是 SDK 原生绘制，而是广告创意 HTML 在 SDK 内部 WKWebView 中渲染**。因此机制为：

> WebContent 进程死亡或 JS 停摆 → 视频残留最后一帧（冻结）+ DOM 控件全消失 + 关闭事件发不出（`GADFullScreenContentDelegate` 永不回调）

一个机制解释案例 2 截图的全部三个症状。Google 将其定性为**创意问题**，不出 SDK 修复，只受理抓包报障后屏蔽创意。

### 疑似相关修复与反例

| 版本 | 内容 | 复核结论 |
|---|---|---|
| GMA 11.12.0 | 修复广告对象提前释放导致 delegate 不回调 | 11.13.0 已包含，非本案 bug |
| GMA 12.8.0 (2025-07) | 关闭 App 内 App Store 页后屏幕无响应；全屏渲染改进 | 最接近但触发路径不同 |
| GMA 13.4.0 (2026-05) | media view 强制主线程访问 | 机理相关但限定 native 格式 |
| 反例 [unity#3841](https://github.com/googleads/googleads-mobile-unity/issues/3841) | 2025-06 在 **GMA 12.x** 上同症状卡死，锁定单一广告主创意，无修复关闭 | 升级后仍可能复现 |
| 反例 2026-01 平台事故 | 全平台"全屏广告关不掉"，与客户端版本无关，Google 服务端修复 | 根因可能部分在服务端 |

### 升级的真实价值与版本路径

价值不在某条修复，而在：11.13.0 是 11.x 绝版（2024-12，已 deprecated），Google 2026 新版自动拼装模板不再对其回归验证；部分修复按最低客户端版本门控；报障只受理新版本。

| 目标 | 版本 | 门槛 |
|---|---|---|
| 首选 | adapter **13.6.0.0**（GMA 13.6.0，2026-06-24） | Xcode 26.2（GMA 13.4+ 要求）；AppLovinSDK 13.0.1 无需动 |
| 退路 | adapter **12.14.0.0**（GMA 12.14.0，12.x 终版） | Xcode 16 即可，已含 12.8.0 修复 + iOS 26 支持 |

---

## 五、行动清单

| # | 动作 | 说明 |
|---|---|---|
| 1 | **看门狗兜底（最高优先，升级替代不了）** | `showRewardVideo()` 后起超时计时，超时无任何回调则主动 dismiss `rootViewController.presentedViewController`、复位 `_isPlayingRewardVideo` 并恢复游戏/音频。当前 `AdControlMan.js:764` 后无任何超时保护 |
| 2 | 升级 iOS Google adapter | 13.6.0.0 或 12.14.0.0（见上表）；Android 的 applovin-sdk 11.5.5 + google-adapter 21.3.0.2 更老，一并评估 |
| 3 | 修打点 | 原生把 MAX 回调真实 `networkName`/`adUnitId`/错误码填入；1103 展示时带上缓存的最近 1101 channel;修复 1106 失真 |
| 4 | 屏蔽创意 + 报障 | Charles 抓包复现 → AdMob 审核中心屏蔽问题广告主/类目；带两张截图与广告主信息走 AdMob Help Center（旧支持论坛已于 2026-01-19 关闭） |
| 5 | 内存假说取证 | 复现时抓 Console/sysdiagnose，查 `Could not signal service com.apple.WebKit.WebContent: 113` 与 jetsam 记录；若命中,升级无效,需在广告展示期暂停 GL 渲染循环、清纹理缓存降内存 |
| 6 | 灰度验证 | 上报"已展示但 N 秒无关闭回调"（看门狗触发计数）作为核心指标，分阶段放量对比,实证升级效果 |

---

## 附：查证方法

三轮多智能体交叉验证（图片取证 / 仓库 adapter 扫描 / 广告主需求端调查 / 各网络模板指纹比对 / 多视角对抗复核），共 25 个子任务全部完成，两例广告源判定与"新版是否修复"结论均经对抗复核检验并如实记录被推翻的辅助论据。

主要来源：

- [GMA iOS release notes](https://developers.google.com/admob/ios/rel-notes)
- [AppLovin MAX iOS Google adapter changelog](https://github.com/AppLovin/AppLovin-MAX-SDK-iOS)
- [Google Ads Transparency Center](https://adstransparency.google.com/)（两例广告主均可查）
- [googleads-mobile-unity #3841](https://github.com/googleads/googleads-mobile-unity/issues/3841)

---

**记录时间**: 2026-07-22
**排查人**: 高亚创
