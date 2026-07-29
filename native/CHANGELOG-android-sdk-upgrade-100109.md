# Android SDK 升级记录（AppVersion 100109）

## 基本信息

- 升级日期：2026-07-29
- 影响平台：Android / Google Play
- 版本标记：`LogicHelper::getAppVersion() = 100109`
- 最低系统版本：`minSdk 23`，本次未提高
- 构建目标：`targetSdk 35 -> 36`、`compileSdk 35 -> 36`、`buildTools 35 -> 36`

## SDK 版本变更

| 模块 | 升级前 | 升级后 |
| --- | --- | --- |
| Firebase Auth | 22.1.2 | 24.0.1 |
| reCAPTCHA Enterprise for Mobile | 18.1.2（旧依赖） | 18.8.0（显式依赖） |
| Google Play Billing | 7.0.0 | 8.0.0 |
| AppLovin MAX SDK | 11.5.5 | 13.6.2 |
| Google Mobile Ads | 24.8.0 | 25.1.0 |
| MAX Chartboost adapter | 9.1.1.1 | 9.11.1.0 |
| MAX Meta adapter | 6.12.0.0 | 6.21.0.0 |
| MAX Google adapter | 21.3.0.2 | 25.1.0.0 |
| MAX ironSource adapter | 7.2.5.0.1 | 9.3.0.0.0 |

> AppLovin `13.6.3` 起要求 `minSdk 24`，因此本次选择兼容 `minSdk 23` 的 `13.6.2`。

## 代码与构建改造

### Google Play Billing 8

- 使用 `PendingPurchasesParams.enableOneTimeProducts()` 开启一次性商品的 Pending Purchase 支持。
- `ProductDetailsResponseListener` 改为读取 `QueryProductDetailsResult`。
- 已移除的 `queryPurchaseHistoryAsync()` 改为 `queryPurchasesAsync()`。
- 删除 `PurchaseHistoryRecord` 数据转换逻辑，统一使用 `Purchase`。

行为变化：升级后的“最近购买记录”接口返回当前有效、未消费或未确认的购买，不再等价于完整历史购买记录。支付补单和恢复购买需要重点回归。

### Firebase Auth 与 reCAPTCHA

- Firebase Auth 升级到 `24.0.1`。
- 显式引入 reCAPTCHA `18.8.0`，替换存在安全风险的 `18.1.2`。
- 应用模块启用 Core Library Desugaring，并添加 `desugar_jdk_libs:2.1.5`。
- Desugaring 配置同时写入生成后的 `app/build.gradle` 和源模板 `res_oldvegas/flavor/gradle/build.gradle`，防止重新生成 Android 工程后丢失。

### AppLovin MAX

- 初始化迁移到 `AppLovinSdkInitializationConfiguration` 和 `AppLovinMediationProvider.MAX`。
- SDK Key 继续读取 AndroidManifest 中的 `applovin.sdk.key`，缺失时输出错误并停止初始化。
- 删除新版不再支持的 `AppLovinPrivacySettings.setIsAgeRestrictedUser()`。
- 删除已移除的 `onRewardedVideoStarted()`、`onRewardedVideoCompleted()` 回调。
- 在 `onAdDisplayed()` 重置完整观看状态，以 `onUserRewarded()` 作为奖励成功和完整观看信号。
- 增加 Chartboost 官方 Maven 仓库：`https://cboost.jfrog.io/artifactory/chartboost-ads/`。
- 删除项目 Manifest 中旧版 ironSource 和 Meta Audience Network Activity 的重复声明，采用新版 SDK AAR 自带配置。

## 主要修改文件

| 文件 | 说明 |
| --- | --- |
| `frameworks/runtime-src/proj.android-studio/gradle.properties` | Android SDK 35 升级到 36，保留 `minSdk 23` |
| `frameworks/runtime-src/proj.android-studio/build.gradle` | 增加 Chartboost Maven 仓库 |
| `frameworks/runtime-src/proj.android-studio/app/build.gradle` | 生成工程的 Desugaring 配置（该文件被 Git 忽略） |
| `res_oldvegas/flavor/gradle/build.gradle` | 持久化 Desugaring 配置的源模板 |
| `frameworks/runtime-src/proj.android-studio/app/AndroidManifest.xml` | 清理旧版 ironSource、Meta Activity 声明 |
| `libZenSDK/platform/android/java/build.gradle` | Firebase、reCAPTCHA、Google Ads、AppLovin 及 adapters 版本 |
| `libZenSDK/platform/android/java/src/com/zegame/max/AdMaxManager.java` | AppLovin 新初始化接口 |
| `libZenSDK/platform/android/java/src/com/zegame/max/AdMaxRvListener.java` | AppLovin 新激励回调逻辑 |
| `libZenSDK/thirdparty/android/libPayGooglePlaySmall/build.gradle` | Billing 8.0.0 |
| `libZenSDK/thirdparty/android/libPayGooglePlaySmall/src/com/zentertain/payment/ZenPaymentChannelGooglePlay.java` | Billing 8 API 迁移 |
| `libZenSDK/thirdparty/android/libPayGooglePlaySmall/src/com/zentertain/payment/PurchaseDataGooglePlay.java` | 删除 PurchaseHistoryRecord 逻辑 |
| `libZenSDK/js-bindings/bindings/manual/LogicHelper.cpp` | AppVersion 100109 及升级注释 |

## 简要测试要点

### P0：构建与安装

- [ ] Gradle Sync 成功，依赖树中 reCAPTCHA、Billing、AppLovin 和各 adapter 版本与上表一致。
- [ ] `googleplay_old_vegasDebug` 可完整编译、安装并冷启动，无 Manifest、Desugaring 或 D8/R8 错误。
- [ ] Release AAB 可生成并上传 Google Play 内部测试轨道。
- [ ] 至少在 Android API 23 和 API 36 设备各完成一次启动与核心流程冒烟测试。

### P0：Google Play 支付

- [ ] 商品列表和价格正常返回，一次性商品可正常拉起支付页。
- [ ] 支付成功后到账一次，消费成功；重启应用不会重复到账。
- [ ] 用户取消、支付失败、Pending Purchase 均能正确回调且不错误发货。
- [ ] 未消费订单的补单/恢复购买正常，重点验证 `queryPurchasesAsync()` 返回结果。
- [ ] 如线上使用订阅，验证订阅商品查询、购买、恢复和过期状态。

### P0：AppLovin 与广告渠道

- [ ] AppLovin 初始化成功，Mediation Debugger 无 SDK Key 或 adapter 版本错误。
- [ ] 插屏广告可加载、展示、点击、关闭，并能继续预加载下一条广告。
- [ ] 激励广告完整观看时只发奖一次，并依次触发开始、奖励、结束业务回调。
- [ ] 激励广告提前关闭时不发奖，并触发“未完整观看”回调。
- [ ] 广告收入回调可正常上报 Adjust。
- [ ] 分别验证 Chartboost、Meta、Google、ironSource adapter 能初始化并返回测试广告；相关 SDK Activity 可正常打开和关闭。

### P1：Firebase Auth 与 reCAPTCHA

- [ ] 现有 Firebase 登录、重新登录、退出登录流程正常。
- [ ] 能触发 reCAPTCHA 的认证场景可正常展示验证页并返回应用。
- [ ] 验证取消、网络失败和验证失败时有正确错误回调，应用不崩溃。
- [ ] 在 API 23 设备验证登录和 reCAPTCHA，确认 Desugaring 运行正常。

### P1：基础回归

- [ ] 首次安装、覆盖安装、前后台切换和进程重启正常。
- [ ] Firebase Analytics、Crashlytics、Messaging 基础初始化无异常日志。
- [ ] Android 16 / targetSdk 36 下登录、支付、广告弹窗及返回行为正常。

## 当前验证状态

- 已通过 `git diff --check`。
- AndroidManifest 已通过 XML 语法检查。
- 已根据实际构建错误完成 Chartboost 仓库、AppLovin 回调、Desugaring、ironSource 和 Meta Manifest 冲突修复。
- 最终完整 Debug/Release 构建及真机业务回归需要按以上清单执行并记录结果。

## 参考资料

- [reCAPTCHA Mobile SDK 弃用政策](https://docs.cloud.google.com/recaptcha/docs/deprecation-policy-mobile?hl=zh-cn)
- [Google Play Billing 版本说明](https://developer.android.com/google/play/billing/release-notes)
- [AppLovin Android SDK 13.6.2](https://github.com/AppLovin/AppLovin-MAX-SDK-Android/tree/release_13_6_2)
- [Chartboost Android 集成](https://docs.chartboost.com/en/monetization/integrate/android/get-started/#setting-up-chartboost-sdk)
- [Android Core Library Desugaring](https://developer.android.com/studio/write/java8-support)
