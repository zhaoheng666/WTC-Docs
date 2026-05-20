# DH Android 外链支付切后台触发 Pomelo 断线

## 摘要

| 项目 | 内容 |
|------|------|
| 状态 | ✅ 已定位根因 |
| 风格 | DH (Double Hit) |
| 平台 | Android（设备 OS Version 12） |
| 现象 | 切后台 8-30 秒区间后回前台立即触发 Pomelo `onClose`，连接断开 |
| 触发场景 | 接入外链支付（`cc.sys.openURL` 跳转 Chrome Custom Tab）后才放大 |
| 根因 | **Android 进程状态变化**：外链支付让游戏 Activity 从 Paused-Visible 变为 Stopped 状态，OS 在后台对 socket 的限制策略被触发 |
| 服务端 | Pomelo `heartbeat=30s, timeout=600s`，配置正常，**非服务端断连** |
| 文件 | `src/store/model/StoreMan.js:2825` `questAppchargeCheckoutOnAndroid` |

---

## 问题描述

接入 DH Android 外链支付分支（commit `a0eeb78e618`）后，用户反馈"切后台不到 6 秒 Pomelo 就断线"。

实测后修正：

- **真实阈值在 8-30 秒之间**（不是 6 秒）
- **断线 100% 发生在回前台瞬间**（69ms ~ 670ms 内触发 `onClose`），后台中无任何 SDK 日志

---

## 排查过程

### 实测样本汇总

| # | 后台时长 | 是否断线 | 断线检测时刻 |
|---|---------|---------|-------------|
| 1 | 8.2s | ✅ 不断 | — |
| 2 | 12.1s | ✅ 不断 | — |
| 3 | 28.3s | ❌ 断 | gameOnShow 后 670ms |
| 4 | 30.7s | ❌ 断 | gameOnShow 后 69ms |
| 5 | 33.3s | ❌ 断 | gameOnShow 后 130ms |
| 6 | 36.6s | ❌ 断 | gameOnShow 后 60ms |
| 7 | 87.3s | ❌ 断 | gameOnShow 后 40ms |

### 加诊断日志后的关键证据

在 SDK + 业务层加 `[BG-TRACE]` 日志后定位：

| 信号 | 含义 |
|------|------|
| `handshake sys.heartbeat=30s interval=30000ms timeout=60000ms` | 客户端 SDK 容忍 60 秒不发心跳 |
| 无 `heartbeatTimeoutCb` 日志 | **非 SDK 自校正触发** |
| 无 `heartbeat send`（后台中） | OS 冻结了 JS timer，心跳没发出 |
| `sdk.onclose code=undefined reason=undefined wasClean=undefined` | **非标准 WebSocket close**，是 native 层手工派发 |
| `clientDisconnect=false` | 非业务代码主动断 |

### 排除清单

| 嫌疑 | 状态 | 证据 |
|------|------|------|
| Pomelo `timeout` 配置 | ❌ 排除 | `timeout: 600` 远大于 30s |
| Pomelo `heartbeat` 配置 | ❌ 排除 | `heartbeat: 30s`，正常 |
| nginx `proxy_read_timeout` | ❌ 排除 | 未配置，默认 60s |
| 客户端 SDK 自校正 | ❌ 排除 | 无 `heartbeatTimeoutCb` 日志 |
| 客户端业务主动断 | ❌ 排除 | `clientDisconnect=false` |

---

## 根本原因

### 核心结论

**Android Activity 生命周期的两种"切后台"状态有本质区别**：

| 场景 | Activity 状态 | 进程状态 | OS 对 socket 限制 |
|------|--------------|---------|------------------|
| 内嵌 SDK 浮层（广告/iframe 支付） | Paused-Visible | Foreground | 不受限 |
| 跳转外部 Activity（Custom Tab / 浏览器） | **Stopped** | **Background** | **明显受限** |

之前所有"切后台"场景都未触发完整的 `onStop`，所以 Pomelo 断线问题被掩盖；接入外链支付后**首次让游戏 Activity 进入 Stopped 状态**，OS 的后台 socket 限制才被触发。

### 证据 1：内嵌 dialog/WebView 浮层不会触发 `onStop`

Android 官方生命周期文档明确说明：dialog/overlay 不完全遮挡底层 Activity 时，**只触发 `onPause()`，不触发 `onStop()`**：

> "`onStop()` is invoked when the activity is no longer visible to the user… Since a dialog (including one hosting a WebView) does not fully obscure the underlying activity, the activity is still considered visible — so `onStop()` is correctly skipped."

> 常见只触发 `onPause` 的场景：系统对话框、多窗口模式、通知抽屉下拉、**Dialog 内嵌的 WebView**。

来源：
- [The activity lifecycle | Android Developers](https://developer.android.com/guide/components/activities/activity-lifecycle)
- [Activity state changes | Android Developers](https://developer.android.com/guide/components/activities/state-changes)
- [Understanding the Android Activity Lifecycle: When Only onPause() or onStop() is Called](https://medium.com/@mkcode0323/understanding-the-android-activity-lifecycle-when-only-onpause-or-onstop-is-called-881dc99c57d0)

**推论**：本项目原有的 AppCharge iframe 内嵌支付、广告 SDK 浮层、内嵌 WebView 支付，**全部都不会触发 `onStop`**，Activity 保持 Paused-Visible 状态，进程优先级仍为 Foreground。

### 证据 2：Chrome Custom Tab / 外部 Intent 触发完整 onStop

Chrome 官方文档与社区实证明确说明：

> "Chrome Custom Tabs run as a separate Activity (in the Chrome process), but Android's lifecycle treats the calling app's activity as if it has gone into the background once the Custom Tab takes over the screen."

> "When the Custom Tab launches, your calling Activity receives `onPause()` → `onStop()` as it goes to the background."

Android 官方生命周期文档同样确认：

> "If a new activity or dialog appears in the foreground, **taking focus and completely covering the activity in progress**, the covered activity loses focus and enters the **Stopped state**. The system then, in rapid succession, calls `onPause` and `onStop`."

> "When the user taps the Overview or Home button, the system behaves as if the current activity has been completely covered."

来源：
- [Overview of Android Custom Tabs | Chrome for Developers](https://developer.chrome.com/docs/android/custom-tabs)
- [Detecting Chrome Custom Tab Closure in Android](https://logickoder.medium.com/detecting-chrome-custom-tab-closure-in-android-a-coroutine-based-solution-ad3ee7b6204c)
- [The activity lifecycle | Android Developers](https://developer.android.com/guide/components/activities/activity-lifecycle)

**推论**：本项目 `cc.sys.openURL` 启动外链支付，等价于启动一个外部 Activity，**必然触发完整的 `onPause → onStop` 序列**，进程进入 Background 状态。

### 证据 3：Android 后台对 WebSocket/TCP socket 有明确限制

这是一个**广为人知的 Android 平台特性**，多个引擎和服务商都遇到并记录过：

**Defold 引擎论坛实测**：

> "On Android, websocket disconnection happens when the app is in background, when native share popup or admob rewarded video is showing. The connection only lasts around 7 seconds."

**Backendless 后端服务的总结**：

> "Android aggressively suspends sockets in background, so a clean disconnect-on-background / reconnect-on-foreground strategy is generally required."
> 典型错误信号："Code 1005 is reserved and may not be used"（非标准 close code）

**Android 官方网络文档**确认这种限制的存在，并提供了 `SocketKeepalive` API 作为对策（需要 native 层接入）：

- [SocketKeepalive | Android Developers](https://developer.android.com/reference/android/net/SocketKeepalive)
- [Defold 论坛：WebSocket connection closed after few seconds the app in background](https://forum.defold.com/t/websocket-connection-closed-after-few-seconds-the-app-in-background/75969)
- [Backendless Support：Websocket connection lost in app background](https://support.backendless.com/t/websocket-connnection-lost-in-app-background/13158)

**注意**：本案例中的 `event.code=undefined` 与 Backendless 提到的"非标准 close code"特征**完全吻合**——都是 Android 底层 socket 被回收时构造的非标准 close 事件。

### 证据 4：Cocos2d-x WebSocket 在后台生命周期问题已有官方认知

Cocos2d-x 社区与游戏引擎厂商对此问题已有共识：

**Photon 官方对 cocos2d-x + 长连接的建议**：

> "Hook into AppDelegate.cpp lifecycle callbacks (`applicationDidEnterBackground` / `applicationWillEnterForeground`). LoadBalancing::Client offers a `reconnectAndRejoin()` function that reconnects to the game server and rejoins the room."

**Cocos2d-x GitHub 已知 Issue（后台生命周期相关）**：

- [#17709 Android WebSocket SIGSEGV on GLThread](https://github.com/cocos2d/cocos2d-x/issues/17709)
- [#18972 iOS WebSocket crash on app close](https://github.com/cocos2d/cocos2d-x/issues/18972)
- [#19162 Android crashes when the game goes into background](https://github.com/cocos2d/cocos2d-x/issues/19162)

**社区推荐方案的核心要点**：

> "Explicitly close the WebSocket in `AppDelegate::applicationDidEnterBackground()` rather than letting Android's Doze/background socket throttling kill it uncleanly. Reconnect in `applicationWillEnterForeground()`, ideally with a session-resume token."

来源：[Photon SDK with cocos2d-x reconnect when app returns back from the background](https://forum.photonengine.com/discussion/15462/photon-sdk-with-cocos2d-x-reconnect-when-app-returns-back-from-the-background)

### 同类问题的阈值参考

| 来源 | 实测阈值 |
|------|---------|
| 本案例（Cocos2d-x + Pomelo + Android 12） | 8-30 秒 |
| [Defold 引擎论坛](https://forum.defold.com/t/websocket-connection-closed-after-few-seconds-the-app-in-background/75969) | 约 7 秒 |
| [Backendless](https://support.backendless.com/t/websocket-connnection-lost-in-app-background/13158) | "几秒到十几秒" |

不同引擎、不同厂商 ROM、不同 Android 版本的具体阈值有差异，但 **Activity 进入 `Stopped` 状态后 socket 终将被回收**这一行为是一致的。

### 完整断线时序

```
[用户点击购买]
    ↓
cc.sys.openURL → Intent.ACTION_VIEW → 启动 Chrome Custom Tab
    ↓
Game Activity onPause → onStop          ← Custom Tab 完全遮挡
    ↓
Game Process 优先级 Foreground → Background
    ↓
[8-30 秒后] Android 限制后台 socket
    ↓
底层 TCP socket 被 OS 回收（无标准 close frame）
    ↓
[用户回到游戏]
    ↓
Game Activity onResume → onStart → JS 上下文恢复
    ↓
OS 投递积压的 socket close 事件 → native 派发 onclose
    ↓
PomeloClient.onClose（code/reason/wasClean 全为 undefined）
```

### 完整证据链

1. 服务端 `timeout=600s` → **不可能是服务端关的**
2. 客户端 SDK `timeout=60000ms` → **不可能是 SDK 自校正断的**
3. close event 全字段 undefined → **非标准 WebSocket close frame**，与 Android 后台 socket 回收特征吻合
4. 内嵌 SDK 一直没问题 → **未触发 `onStop`**（Android 官方文档支持）
5. 外链支付后才出现 → **首次触发 `onStop`**（Chrome 官方文档 + Android 生命周期文档支持）
6. Defold/Backendless/Photon 都遇到过相同问题 → **业内共识**，需"disconnect-on-background + reconnect-on-foreground"

---

## 解决方案

### 短期（推荐）：接受断线，完善自动重连

**思路**：承认"切到外部 App 必断"是 Android 平台特性，把工程重点转向"回前台无缝重连"。这与 Photon 官方推荐方案一致。

涉及位置：

- `src/common/net/PomeloClient.js` `onClose` / `onDisconnected`
- `src/common/model/LogicMan.js:78` `gameOnShow` 入口

改造要点：

1. `PomeloClient.onClose` 触发后自动调起重连流程
2. `gameOnShow` 检查 `isConnected()`，若断开立即重连
3. UI 加 loading 遮罩 + "网络恢复中" 提示，覆盖重连期间的请求空窗
4. 服务端会话做幂等性处理，重连后能恢复状态

### 中期：缩短切后台窗口

- 优化外链支付的 deep link 回跳速度，减少用户切走的时长
- 承接页支付完成立即 `wtcasino://` deep link 唤起 App，避免用户手动切回

### 长期：架构层选择

| 方案 | 优点 | 代价 |
|------|------|------|
| 支付改回 App 内 WebView | Activity 保持 Paused-Visible，无断线 | 失去"独立站点"的解耦优势 |
| 用 Android Foreground Service 维持长连接 | 不依赖 Activity 状态，彻底解决 | 需 native 改造，电量/权限提示 |
| 接入 `SocketKeepalive` API | OS 层面允许后台维持 socket | 需 native 改造，Android 6.0+ |
| 保持现状 + 完善重连 | 改动小，符合 OS 设计意图 | 用户偶尔感知短暂重连 |

---

## 验证方法

### 对照实验

| 测试场景 | Activity 状态 | 预期 |
|---------|-------------|------|
| 按 Home 键切桌面 30s 再回来 | Stopped | 断线 |
| 切到设置 App 30s 再回来 | Stopped | 断线 |
| 弹出内嵌广告浮层 30s | Paused-Visible | 不断 |
| 触发外链支付 5s 内回 | Stopped 但短于阈值 | 不断 |
| 触发外链支付 30s 后回 | Stopped 超阈值 | 断线 |

### 现有诊断日志

加入的 `[BG-TRACE]` 日志已合入开发分支，便于后续复测：

```bash
adb logcat | grep BG-TRACE
```

输出示例：

```
[BG-TRACE] handshake sys.heartbeat=30s interval=30000ms timeout=60000ms
[BG-TRACE] gameOnHide ts=... pomelo.isConnected=true
[BG-TRACE] gameOnShow ts=... pomelo.isConnected=true bgDurationMs=30741
[BG-TRACE] sdk.onclose ts=... code=undefined reason=undefined wasClean=undefined
[BG-TRACE] PomeloClient.onClose ts=... code=undefined clientDisconnect=false
```

### Native 层生命周期日志

在 native 层加日志，可直接观察"内嵌 SDK 弹出"与"启动外链支付"两种场景下 `onStop` 的触发差异：

```cpp
// frameworks/runtime-src/Classes/AppDelegate.cpp
void AppDelegate::applicationDidEnterBackground() {
    CCLOG("[BG-TRACE] applicationDidEnterBackground");
}
void AppDelegate::applicationWillEnterForeground() {
    CCLOG("[BG-TRACE] applicationWillEnterForeground");
}
```

```java
// AppActivity.java
@Override protected void onStop() {
    super.onStop();
    Log.d("BG-TRACE", "Activity onStop");
}
@Override protected void onStart() {
    super.onStart();
    Log.d("BG-TRACE", "Activity onStart");
}
```

---

## 关键文件

| 文件 | 作用 |
|------|------|
| `src/store/model/StoreMan.js:2825` | `questAppchargeCheckoutOnAndroid` 外链支付入口 |
| `src/common/net/PomeloClient.js:177` | Pomelo onClose 处理 |
| `src/common/model/LogicMan.js:78` `gameOnShow` | 切前台事件处理（重连入口） |
| `src/common/model/LogicMan.js:145` `gameOnHide` | 切后台事件处理（已确认无主动断连） |
| `node_modules/@me2zen/pomelo-jsclient-websocket/lib/pomelo-client.js:528-535` | SDK heartbeat 配置初始化 |

---

## 参考资料

### Android 官方文档

- [The activity lifecycle | Android Developers](https://developer.android.com/guide/components/activities/activity-lifecycle)
- [Activity state changes | Android Developers](https://developer.android.com/guide/components/activities/state-changes)
- [SocketKeepalive API | Android Developers](https://developer.android.com/reference/android/net/SocketKeepalive)

### Chrome Custom Tabs 官方文档

- [Overview of Android Custom Tabs | Chrome for Developers](https://developer.chrome.com/docs/android/custom-tabs)
- [Detecting Chrome Custom Tab Closure in Android](https://logickoder.medium.com/detecting-chrome-custom-tab-closure-in-android-a-coroutine-based-solution-ad3ee7b6204c)

### 社区实证与同类问题报告

- [Defold 论坛：WebSocket connection closed after few seconds in background](https://forum.defold.com/t/websocket-connection-closed-after-few-seconds-the-app-in-background/75969)
- [Backendless：Websocket connection lost in app background](https://support.backendless.com/t/websocket-connnection-lost-in-app-background/13158)
- [Photon SDK + cocos2d-x reconnect pattern](https://forum.photonengine.com/discussion/15462/photon-sdk-with-cocos2d-x-reconnect-when-app-returns-back-from-the-background)
- [Activity lifecycle: When only onPause() is called](https://medium.com/@mkcode0323/understanding-the-android-activity-lifecycle-when-only-onpause-or-onstop-is-called-881dc99c57d0)

### Cocos2d-x 相关 Issue

- [#17709 Android WebSocket SIGSEGV](https://github.com/cocos2d/cocos2d-x/issues/17709)
- [#18972 iOS WebSocket crash on app close](https://github.com/cocos2d/cocos2d-x/issues/18972)
- [#19162 Android crashes when game goes background](https://github.com/cocos2d/cocos2d-x/issues/19162)

---

## 经验总结

| 教训 | 说明 |
|------|------|
| "代码没改但行为变了" | 优先排查业务上下文变化（用户行为、调用模式、OS 版本），不要只在技术栈内打转 |
| Android "切后台" 不是单一行为 | Paused-Visible（dialog/overlay）vs Stopped（外部 Activity）系统调度策略截然不同 |
| Foreground SDK 浮层 ≠ 真后台 | 内嵌支付/广告掩盖了真正的后台行为问题 |
| `event.code=undefined` 是关键信号 | 非标准 close frame 是 Android 后台 socket 回收的典型特征 |
