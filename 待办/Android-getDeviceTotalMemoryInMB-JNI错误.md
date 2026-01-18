# Android getDeviceTotalMemoryInMB JNI 错误

## 问题描述

Android 端启动时日志输出 JNI 错误：

```
JniHelper  E  Failed to find static java method.
Class name: org/cocos2dx/lib/Cocos2dxHelper,
method name: getDeviceTotalMemoryInMB,
signature: ()F
```

## 原因分析

### 调用链

```
JS 层: cc.Device.getDeviceTotalMemoryInMB()
    ↓
C++ 层: cocos2d::Device::getDeviceTotalMemoryInMB()
    ↓ (CCDevice-android.cpp:192)
JNI 调用: JniHelper::callStaticFloatMethod(helperClassName, "getDeviceTotalMemoryInMB")
    ↓
Java 层: Cocos2dxHelper.getDeviceTotalMemoryInMB() ❌ 方法不存在
```

### 根本原因

cocos2d-x 引擎的 C++ 层绑定了 `getDeviceTotalMemoryInMB` 方法到 JS，但 Java 层 `Cocos2dxHelper.java` 没有对应实现。

### JS 层调用点

| 文件 | 用途 |
|-----|-----|
| `src/common/util/DeviceInfo.js:289` | 获取设备总内存 |
| `src/log/model/LogMan.js:1054` | 设备信息日志上报 |
| `src/social/controller/high_rollers_lounge/v2/HR2MainController.js:1138` | 性能监控 |
| `src/social/controller/high_rollers_lounge/v2/HR2EntranceController.js:247` | 性能监控 |
| `src/social/controller/high_rollers_lounge/wheel/HRWheelMainController.js:303` | 性能监控 |

所有调用点都有存在性检查：
```javascript
if (cc.sys.isNative && cc.Device.getDeviceTotalMemoryInMB) {
    totoalMemory = cc.Device.getDeviceTotalMemoryInMB();
}
```

但 `cc.Device.getDeviceTotalMemoryInMB` 在 JS 绑定中存在（返回 true），实际调用时 JNI 失败。

## 影响评估

| 项目 | 评估 |
|-----|-----|
| 是否崩溃 | ❌ 否，C++ 层返回默认值 0 |
| 是否影响逻辑 | ❌ 否，只影响内存数据上报 |
| 影响范围 | 仅 Android 平台 |
| 严重程度 | 🟢 低 |

## 解决方案

### 方案 1：Java 层添加方法（推荐）

在 `Cocos2dxHelper.java` 中添加：

```java
public static float getDeviceTotalMemoryInMB() {
    try {
        ActivityManager activityManager = (ActivityManager) sActivity.getSystemService(Context.ACTIVITY_SERVICE);
        ActivityManager.MemoryInfo memoryInfo = new ActivityManager.MemoryInfo();
        activityManager.getMemoryInfo(memoryInfo);
        return memoryInfo.totalMem / (1024.0f * 1024.0f);
    } catch (Exception e) {
        e.printStackTrace();
        return 0.0f;
    }
}
```

**文件位置**：`frameworks/cocos2d-x/cocos/platform/android/java/src/org/cocos2dx/lib/Cocos2dxHelper.java`

### 方案 2：JS 层增加平台判断

在调用处增加 Android 平台排除：

```javascript
if (cc.sys.isNative && cc.sys.os !== cc.sys.OS_ANDROID && cc.Device.getDeviceTotalMemoryInMB) {
    totoalMemory = cc.Device.getDeviceTotalMemoryInMB();
}
```

## 当前状态

**暂不处理** - 错误不影响游戏功能，仅产生日志警告。

## 相关文件

- `frameworks/cocos2d-x/cocos/platform/android/CCDevice-android.cpp:190-192`
- `frameworks/cocos2d-x/cocos/platform/android/java/src/org/cocos2dx/lib/Cocos2dxHelper.java`
- `src/common/util/DeviceInfo.js`

## 记录

- **发现日期**：2026-01-18
- **发现版本**：DH 测试版本
