# Native 资源下载缓存优化

## 概述

优化 Native 端资源下载流程，通过 **manifest 文件存在性 + 版本检查 + 资源完整性校验** 避免重复触发 `jsb.AssetsManager` 下载任务。

**优化效果**：重启应用后，已下载的资源可跳过网络请求，显著提升加载速度。

## 问题背景

### 原有问题

Native 端每次启动都会触发资源下载任务，即使版本号相同也会发起 `version.manifest` 网络请求：

```
App 启动
  ↓
isDownloaded("activity/xxx") → false（内存缓存丢失）
  ↓
触发 jsb.AssetsManager.update()
  ↓
下载 version.manifest（网络请求）
  ↓
比对版本号 → 相同
  ↓
返回 ALREADY_UP_TO_DATE
```

**根本原因**：`CacheManager._downloadedMap` 是纯内存缓存，应用重启后丢失。

### 优化后流程

```
App 启动
  ↓
isDownloaded("activity/xxx")
  ↓
检查本地 manifest 文件 + 多层校验
  ↓
校验通过 → 返回 true（跳过下载）
  ↓
添加搜索路径 → 资源可用
```

## 技术方案

### 核心设计

**使用 manifest 文件作为"已下载"标记**：
- 下载完成时 `jsb.AssetsManager` 自动写入 `project.manifest` 到 storagePath
- 检查缓存时，直接读取本地 manifest 文件的版本号与 `Config.commonVersion` 比对
- 无需额外的 localStorage 缓存层

**版本检查基于路径前缀自动判断**：
- `activity/*` - 需要版本检查
- `card_system_lagload/*` - 需要版本检查
- 其他路径 - 不检查版本

### 校验流程

```
isDownloaded(resourcePath)
    │
    ├─ 1. 内存缓存检查（快速路径）
    │      └─ 已在 _downloadedMap → 返回 true
    │
    ├─ 2. 非 Native 平台跳过
    │      └─ !cc.sys.isNative → 返回 false
    │
    ├─ 3. manifest 文件存在性检查
    │      └─ storagePath + 'project.manifest' 不存在 → 返回 false
    │
    ├─ 4. 版本检查（根据资源路径前缀自动判断）
    │      ├─ needsVersionCheck(resourcePath) → true
    │      │   └─ 读取 manifest.version 与 Config.commonVersion 比对
    │      │   └─ 不一致 → 返回 false（触发重新下载）
    │      └─ needsVersionCheck(resourcePath) → false
    │          └─ 跳过版本检查
    │
    ├─ 5. 资源文件完整性检查
    │      └─ 遍历 manifest.assets，检查所有文件是否存在
    │      └─ 有缺失 → 删除 manifest，返回 false
    │
    └─ 6. 确保搜索路径已添加（高优先级）
           └─ 校验通过 → unshift 到搜索路径开头，返回 true
```

### 版本检查配置

```javascript
// CacheManager.js 模块级配置
var VERSION_CHECK_PREFIXES = [
    'activity/',
    'card_system_lagload/'
];

function needsVersionCheck(resourcePath) {
    if (!resourcePath) {
        return false;
    }
    for (var i = 0; i < VERSION_CHECK_PREFIXES.length; i++) {
        if (resourcePath.indexOf(VERSION_CHECK_PREFIXES[i]) === 0) {
            return true;
        }
    }
    return false;
}
```

## 实现细节

### 修改文件

| 文件 | 修改内容 |
|-----|---------|
| `src/resource_v2/core/CacheManager.js` | 增加 manifest 校验、版本检查、搜索路径管理 |
| `src/resource_v2/ResourceManV2.js` | 注入 ConfigManager 到 CacheManager |

### 核心代码

#### isDownloaded 方法

```javascript
isDownloaded: function (resourcePath) {
    // 1. 内存缓存（快速路径）
    if (this._downloadedMap[resourcePath]) {
        return true;
    }

    // 2. 非 Native 平台不做持久化校验
    if (!cc.sys.isNative) {
        return false;
    }

    // 3. 检查 manifest 文件是否存在
    var storagePath = this._getStoragePath(resourcePath);
    if (!storagePath) {
        return false;
    }
    var manifestPath = storagePath + 'project.manifest';

    if (!jsb.fileUtils.isFileExist(manifestPath)) {
        return false;
    }

    // 4. 版本检查（根据资源路径前缀自动判断）
    if (needsVersionCheck(resourcePath)) {
        var currentVersion = this._getCommonVersion();
        var localManifestVersion = this._getLocalManifestVersion(manifestPath);
        if (!localManifestVersion || localManifestVersion !== currentVersion) {
            return false;
        }
    }

    // 5. 检查资源完整性
    var hasResourceFiles = this._checkResourceFilesExist(storagePath);
    if (!hasResourceFiles) {
        this._removeManifestFile(manifestPath);
        return false;
    }

    // 6. 确保搜索路径已添加（高优先级）
    this._ensureSearchPath(storagePath);

    // 校验通过，更新内存缓存
    this._downloadedMap[resourcePath] = true;
    return true;
}
```

#### 搜索路径管理

```javascript
_ensureSearchPath: function (searchPath) {
    if (!cc.sys.isNative) {
        return;
    }

    var searchPathArr = jsb.fileUtils.getSearchPaths();
    if (!searchPathArr) {
        searchPathArr = [];
    }

    // 检查是否已在搜索路径中
    for (var i = 0; i < searchPathArr.length; i++) {
        if (searchPathArr[i] === searchPath) {
            return; // 已存在，无需添加
        }
    }

    // 添加到搜索路径开头（高优先级）
    // 与 jsb.AssetsManager.prependSearchPaths() 行为一致
    searchPathArr.unshift(searchPath);
    jsb.fileUtils.setSearchPaths(searchPathArr);
}
```

## 路径结构说明

### jsb.AssetsManager 下载位置

```
storagePath = writablePath + resourcePath/
    例如: /data/.../files/activity/grow_up_bounty/

manifest asset key = 完整相对路径
    例如: activity/grow_up_bounty/xxx.png

实际下载位置 = storagePath + asset_key
    例如: /data/.../files/activity/grow_up_bounty/activity/grow_up_bounty/xxx.png
```

### 搜索路径配置

```
searchPath = storagePath
    例如: /data/.../files/activity/grow_up_bounty/

游戏加载资源时：
    加载路径: activity/grow_up_bounty/xxx.png
    完整路径 = searchPath + 加载路径
            = /data/.../files/activity/grow_up_bounty/activity/grow_up_bounty/xxx.png ✓
```

**关键**：搜索路径必须使用 `storagePath`（不是 `writablePath`），才能正确解析资源路径。

## 关键点说明

### 为什么需要添加搜索路径？

`jsb.AssetsManager` 下载资源到 `storagePath`（如 `/var/mobile/.../activity/xxx/`），但 Cocos2d 加载资源时使用**相对路径**（如 `activity/xxx/res.png`）。

| API | 路径类型 | 是否依赖搜索路径 |
|-----|---------|----------------|
| `jsb.fileUtils.isFileExist()` | 绝对路径 | 否 |
| `cc.spriteFrameCache.addSpriteFrames()` | 相对路径 | 是 |
| `cc.loader.load()` | 相对路径 | 是 |

如果跳过下载但不添加搜索路径，后续资源加载会失败。

### 为什么使用 unshift 而不是 push？

搜索路径优先级规则：**数组开头优先级最高**。

使用 `unshift` 将下载资源路径添加到开头，确保：
1. 下载的新版本资源优先于旧版本
2. 与 `jsb.AssetsManager.prependSearchPaths()` 行为一致

### 为什么需要版本检查？

**核心原因**：这些是后置加载的游戏核心资源，需要保证与主版本（基础资源）同步、版本一致。

需要版本检查的资源类型：
- `activity/*` - 活动资源，是游戏核心功能的延迟加载部分
- `card_system_lagload/*` - 卡牌系统延迟加载资源，与主卡牌系统强耦合

这些资源虽然是后置加载，但它们与基础资源（随版本发布）紧密关联。如果版本不一致，可能导致：
- UI 布局错位（资源与代码不匹配）
- 功能异常（依赖的接口或数据结构变更）
- 崩溃（资源格式不兼容）

其他动态资源（如 `card_banner_xxx`、`poster/*`）不需要版本检查，它们：
- 是独立的运营资源，不依赖代码版本
- 有独立的更新机制（服务器下发配置）
- 内容变化不影响游戏核心功能

### 为什么检查资源文件完整性？

仅检查 `project.manifest` 存在不够，可能出现：
- manifest 存在但资源文件被删除
- 下载中断导致资源不完整

通过读取 manifest 的 `assets` 字段，检查所有资源文件是否存在，可有效防止这种情况。

## 验证方法

### 1. 首次下载

```
操作：清除本地资源，进入活动
预期：
  - 控制台显示 jsb.AssetsManager 下载日志
  - 下载完成后 manifest 文件写入 storagePath
```

### 2. 再次进入（版本相同）

```
操作：重启应用，进入活动
预期：
  - 控制台显示 [SKIP DOWNLOAD] Local cache valid
  - 无 EventListenerAssetsManager 日志
  - 资源正常加载
```

### 3. 版本更新场景

```
操作：修改 Config.commonVersion，重启应用
预期：
  - 控制台显示 Version mismatch, need re-download
  - 触发重新下载
```

### 4. 文件损坏场景

```
操作：手动删除 storagePath 下的资源文件，重启应用
预期：
  - 控制台显示 Resource file missing
  - 删除 manifest 文件
  - 触发重新下载
```

## 日志示例

### 缓存命中

```
[ResourceManV2][CacheManager] [SKIP DOWNLOAD] Local cache valid: activity/system_daily_mission
```

### 版本检查

```
[ResourceManV2][CacheManager] Version check: activity/grow_up_bounty - local: 93.6.905520 current: 93.6.905521
[ResourceManV2][CacheManager] Version mismatch, need re-download: activity/grow_up_bounty
```

### 搜索路径添加

```
[ResourceManV2][CacheManager] Added search path (high priority): /var/mobile/.../activity/system_daily_mission/
```

## 相关文件

- `src/resource_v2/core/CacheManager.js` - 缓存管理器
- `src/resource_v2/core/ConfigManager.js` - 配置管理器（提供 storagePath）
- `src/resource_v2/ResourceManV2.js` - 资源管理器入口
- `src/resource_v2/adapters/NativeDownloader.js` - Native 下载适配器
- `src/common/asset/AssetsManager.js` - jsb.AssetsManager 封装

## 更新记录

| 日期 | 内容 |
|-----|-----|
| 2026-01-13 | 初始实现，localStorage 持久化 + 8 层校验流程 |
| 2026-01-18 | 重构：移除 localStorage，改用 manifest 文件作为已下载标记；版本检查基于路径前缀自动判断；搜索路径改用 unshift 确保高优先级 |
