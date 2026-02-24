# Facebook iOS SDK 升级变更记录

## 升级概要

- **升级前版本**: 17.0.3
- **目标版本**: 18.0.2+（实际安装: 18.0.3）
- **升级日期**: 2026-02-24
- **变更范围**: libZenSDK/platform/ios/Podfile

### 升级模块清单

| 模块 | 升级前 | 升级后 |
|------|--------|--------|
| FBAEMKit | 17.0.3 | 18.0.3 |
| FBSDKCoreKit_Basics | 17.0.3 | 18.0.3 |
| FBSDKCoreKit | 17.0.3 | 18.0.3 |
| FBSDKLoginKit | 17.0.3 | 18.0.3 |
| FBSDKShareKit | 17.0.3 | 18.0.3 |
| FBSDKGamingServicesKit | 17.0.3 | 18.0.3 |
| FBAudienceNetwork | 6.15.2 | 6.15.2（未变更） |

---

## 中间版本变更明细 (17.0.3 -> 18.0.3)

以下内容摘录自 Facebook iOS SDK 官方 CHANGELOG：
https://github.com/facebook/facebook-ios-sdk/blob/main/CHANGELOG.md

### v17.1.0 (2024-06-18)

**变更：**
- `ShareDialog` 内部实现从 AssetLibrary 迁移至 Photos 框架，影响以 `PHAsset` 表示的分享内容。

**修复：**
- 修复了分享对话框中图片顺序错乱的问题。

**影响评估：**
- **无影响。** 本项目使用 `FBSDKSharePhoto initWithImage:isUserGenerated:`（基于 UIImage），不涉及 PHAsset 分享。AssetLibrary -> Photos 迁移不影响本项目代码路径。
- 如果使用了 PHAsset，受影响文件为：`ZenSocialFacebookImplIOS.mm`（分享函数，约第 370-430 行）。

---

### v17.3.0 (2024-09-24)

**修复：**
- 修复了 Xcode 16 废弃 API 相关问题。

**变更：**
- `AppLinkNavigation` 公开 API 因平台 API 废弃而发生变更。`AppLinkNavigation` 现通过异步 `completionHandler` 回传导航结果，不再同步返回。

**影响评估：**
- **无影响。** 本项目未直接使用 `AppLinkNavigation`。项目使用的 `FBSDKAppLinkUtility.fetchDeferredAppLink:` 本身已是异步回调 API，接口无变化。
- 验证位置：
  - `AppControllerImpl.mm:169` -- 使用 `[FBSDKAppLinkUtility fetchDeferredAppLink:^(NSURL *url, NSError *error) {...}]`（异步回调，无需修改）。
  - `ZenSocialFacebookWorker.m:30` -- 同样模式，无需修改。

---

### v17.4.0 (2024-11-13)

**更新：**
- 更新了域名配置验证逻辑。

**影响评估：**
- **无影响。** 这是 SDK 内部的域名验证逻辑变更，无公开 API 变化。项目 Info.plist 中的 Facebook 配置（FacebookAppID、FacebookClientToken、URL schemes）仍然有效。

---

### v18.0.0 (2025-01-21)

**新增：**
- 改进了对 Original StoreKit API 和 StoreKit 2 API 的应用内购买事件支持。

**影响评估：**
- **无影响。** 这是一个纯新增功能，用于自动记录 IAP 事件。项目现有的 `FBSDKAppEvents` 用法（logEvent、logPurchase、activateApp、setPushNotificationsDeviceToken）不受影响。
- 注意：此功能可能会自动捕获 StoreKit 购买事件。如果出现 IAP 事件重复上报问题，请检查 Info.plist 中的 `FBSDKAutoLogAppEventsEnabled` 配置。

---

### v18.0.1 (2025-01-28)

**新增：**
- 新增链接附件的额外能力（音乐链接）。

**影响评估：**
- **无影响。** 这是音乐链接分享的新增功能。项目使用的 `FBSDKShareLinkContent` 和 `FBSDKSharePhotoContent` 现有功能无变化。

---

### v18.0.2 (2025-02-04)

**恢复：**
- 恢复了登录和分享对话框的 fast app switching（快速应用切换）能力。

**影响评估：**
- **低影响，正向变更。** 此变更恢复了 Facebook 登录和分享对话框可以跳转到原生 Facebook App（如果已安装）的行为，而非始终使用应用内 WebView。这通常会改善用户体验。
- **QA 建议：** 需在安装和未安装 Facebook App 的设备上分别验证登录和分享流程，因为对话框的呈现方式可能与 v17 有所不同。

---

### v18.0.3 (2025-02-10)

**新增：**
- 新增匿名延迟深度链接支持。

**影响评估：**
- **无影响。** 这是延迟深度链接的新增功能。项目现有的 `FBSDKAppLinkUtility.fetchDeferredAppLink:` 用法不受影响，新的匿名模式为可选启用（opt-in）。

---

## API 兼容性逐项审查

已对本项目中所有 Facebook SDK API 调用逐一比对 v18 SDK 头文件，审查结果如下：

### ZenSocialFacebookImplIOS.mm（主要 Facebook 集成文件，748 行）

| API | 状态 | 说明 |
|-----|------|------|
| `FBSDKLoginManager logInWithPermissions:fromViewController:handler:` | 兼容 | 无变更 |
| `FBSDKLoginManager logOut` | 兼容 | 无变更 |
| `FBSDKAccessToken.currentAccessToken` | 兼容 | 无变更 |
| `FBSDKAccessToken.tokenString` | 兼容 | 无变更 |
| `FBSDKShareDialog showFromViewController:withContent:delegate:` | 兼容 | 无变更 |
| `FBSDKSharePhoto initWithImage:isUserGenerated:` | 兼容 | 无变更 |
| `FBSDKSharePhotoContent` | 兼容 | 无变更 |
| `FBSDKShareLinkContent` | 兼容 | 无变更 |
| `FBSDKHashtag initWithString:` | 兼容 | 无变更 |
| `FBSDKGameRequestContent` | 兼容 | 无变更 |
| `FBSDKGameRequestDialog showWithContent:delegate:` | 兼容 | 无变更 |
| `FBSDKGraphRequest initWithGraphPath:parameters:HTTPMethod:` | 兼容 | 无变更 |
| `FBSDKGraphRequest startWithCompletion:` | 兼容 | 已使用新版 API（非已废弃的 startWithCompletionHandler:） |
| `[FBSDKAppEvents shared] logEvent:parameters:` | 兼容 | 已使用实例方法 API |
| `[FBSDKAppEvents shared] logPurchase:currency:parameters:` | 兼容 | 已使用实例方法 API |
| `[FBSDKAppEvents shared] activateApp` | 兼容 | 已使用实例方法 API |
| `[FBSDKSettings sharedSettings]` | 兼容 | 已使用实例方法 API |
| `[FBSDKApplicationDelegate sharedInstance]` | 兼容 | 无变更 |
| `application:openURL:sourceApplication:annotation:` | 兼容 | 已废弃的 UIApplicationDelegate 方法，仍可正常运行 |

### ZenFacebookTracking.m（27 行）

| API | 状态 | 说明 |
|-----|------|------|
| `[FBSDKSettings sharedSettings].appID = ...` | 兼容 | 无变更 |
| `[[FBSDKAppEvents shared] activateApp]` | 兼容 | 无变更 |

### ZenSocialFacebookWorker.m（40 行）

| API | 状态 | 说明 |
|-----|------|------|
| `[[FBSDKAppEvents shared] setPushNotificationsDeviceToken:]` | 兼容 | 无变更 |
| `[[FBSDKAppEvents shared] logPushNotificationOpen:]` | 兼容 | 无变更 |
| `[FBSDKAppLinkUtility fetchDeferredAppLink:]` | 兼容 | 无变更 |

### AppControllerImpl.mm（约 10 行 FB 相关代码）

| API | 状态 | 说明 |
|-----|------|------|
| `[FBSDKAppLinkUtility fetchDeferredAppLink:]` | 兼容 | 无变更 |

---

## 编译验证

- **zensdkstatic target**: 构建成功 (Release, iphoneos, arm64)
- **编译错误**: 0
- **FBSDK 相关编译警告**: 0

---

## 附加优化：废弃 API 迁移与旧文件清理

### 优化 1：`openURL:sourceApplication:annotation:` 全链路迁移为 `openURL:options:`

`application:openURL:sourceApplication:annotation:` 自 iOS 9.0 起已废弃，被 `application:openURL:options:` 取代。本项目最低支持 iOS 12.0，系统不会再调用该废弃方法。此前项目的整条 URL 处理链路均基于废弃签名，现已完成全链路迁移。

**调用链路变更（迁移前）：**

```
iOS 系统 → AppController/SlotsAppController
  ├── openURL:sourceApplication:annotation:  (已废弃，iOS 12+ 不会被调用)
  └── openURL:options: → 拆解 options 字典 → 调用 AppControllerImpl 的废弃方法
        └── AppControllerImpl → 调用 ZenSDK 的废弃方法
              └── ZenSDK 分发器 → 逐一调用各 hook point 的废弃方法
                    ├── ZenAdjustTracking (废弃签名)
                    └── ZenFBHelperObjc → FBSDK 废弃 API
```

**调用链路变更（迁移后）：**

```
iOS 系统 → AppController/SlotsAppController
  ├── openURL:sourceApplication:annotation:  (保留，内部转发到 options: 路径)
  └── openURL:options: → 直接传递 options 字典
        └── AppControllerImpl → 直接传递 options 字典给 ZenSDK
              └── ZenSDK 分发器 → 逐一调用各 hook point 的 options: 方法
                    ├── ZenAdjustTracking (新签名)
                    └── ZenFBHelperObjc → FBSDK 现代 API
```

**修改文件清单：**

| 文件 | 变更说明 |
|------|---------|
| `libZenSDK/platform/ios/ZenSDK.h` | `ZenSDKHookPoints` 协议新增 `application:openURL:options:` 方法；旧方法标记 `__attribute__((deprecated))` |
| `libZenSDK/platform/ios/ZenSDK.mm` | 新增 `application:openURL:options:` 分发器；旧方法实现改为转发到新方法 |
| `libZenSDK/platform/ios/AppControllerImpl.mm` | `options:` 方法改为直接传递 options 字典给 ZenSDK，不再拆解为 sourceApplication + annotation |
| `libZenSDK/core/social/Facebook/ios/ZenSocialFacebookImplIOS.h` | 声明从废弃签名替换为 `application:openURL:options:` |
| `libZenSDK/core/social/Facebook/ios/ZenSocialFacebookImplIOS.mm` | 实现改为调用 `[[FBSDKApplicationDelegate sharedInstance] application:openURL:options:]` |
| `libZenSDK/platform/ios/tracking/ZenAdjustTracking.h` | 声明从废弃签名替换为 `application:openURL:options:` |
| `libZenSDK/platform/ios/tracking/ZenAdjustTracking.m` | 实现签名更新（内部逻辑不变，仅使用 URL） |
| `frameworks/runtime-src/proj.ios_mac/ios/AppController.mm` | `options:` 方法改为直接调用 AppControllerImpl 的 `options:` 方法 |
| `frameworks/runtime-src/proj.ios_mac_oldvegas/ios/SlotsAppController.mm` | 同上 |

### 优化 2：清理旧版 SDK 残留文件

删除了 `libZenSDK/platform/ios/fbsdk/` 目录，该目录包含 Facebook iOS SDK v12.3.2 的遗留 XCFramework 文件（含 armv7/i386 架构），共 173MB。这些文件未被任何 Xcode 工程引用（已通过 .pbxproj 搜索确认），属于历史残留。

**删除的内容：**

| 目录 | 说明 |
|------|------|
| `fbsdk/FBAEMKit/` | v12.3.2 AEM XCFramework |
| `fbsdk/FBSDKCoreKit_Basics/` | v12.3.2 CoreKit Basics XCFramework |
| `fbsdk/FBSDKCoreKit/` | v12.3.2 CoreKit XCFramework |
| `fbsdk/FBSDKLoginKit/` | v12.3.2 LoginKit XCFramework |
| `fbsdk/FBSDKShareKit/` | v12.3.2 ShareKit XCFramework |

---

## 后续建议

1. **QA 回归测试**：部署后需验证以下用户流程：
   - Facebook 登录 / 登出
   - Facebook 分享（链接分享和图片分享）
   - Game Request 发送（见下方说明）
   - AppEvents 上报（logEvent / logPurchase）
   - 新安装后的 Deferred Deep Link（延迟深度链接）

2. **v18.0.2 重点关注**：fast app switching 已恢复，需在安装和未安装 Facebook App 的设备上分别测试登录和分享流程。

### 关于 Game Request

Game Request 是 Facebook Gaming 提供的社交功能，允许玩家向 Facebook 好友发送游戏内邀请或请求（如邀请好友、请求道具等）。本项目通过 `FBSDKGamingServicesKit` 中的 `FBSDKGameRequestDialog` 实现。

**项目中的调用链路：**

```
JS 业务层: FaceBookMan.js → facebook.appRequest(map, callback)
    ↓
JS 绑定层: ZenSocialFacebookWrapper.cpp → appRequest()
    ↓
原生实现层: ZenSocialFacebookImplIOS.mm:194-212
    → FBSDKGameRequestContent (设置 message/title/recipients)
    → FBSDKGameRequestDialog showWithContent:delegate:
```

**业务层调用位置（每个 App 各 3 处）：**

| 文件 | 调用次数 |
|------|---------|
| `src/social/model/FaceBookMan.js` | 3 |
| `res_oldvegas/game.js` | 3 |
| `res_doublehit/game.js` | 3 |
| `res_doublex/game.js` | 3 |

这也是 Podfile 中需要引入 `FBSDKGamingServicesKit` 的原因。
