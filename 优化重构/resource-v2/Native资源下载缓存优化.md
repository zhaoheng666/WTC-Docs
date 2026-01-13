# Native 资源下载缓存优化

## 概述

优化 Native 端资源下载流程，通过 localStorage 持久化缓存避免重复触发 `jsb.AssetsManager` 下载任务。

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
检查 localStorage 缓存 + 多层校验
  ↓
校验通过 → 返回 true（跳过下载）
  ↓
添加搜索路径 → 资源可用
```

## 技术方案

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
    ├─ 3. localStorage 记录检查
    │      └─ 无记录 → 返回 false
    │
    ├─ 4. Config.commonVersion 版本对比
    │      └─ 不一致 → 清除记录，返回 false
    │
    ├─ 5. 本地 manifest 文件存在性检查
    │      └─ 不存在 → 清除记录，返回 false
    │
    ├─ 6. 本地 manifest 版本号对比
    │      └─ 不一致 → 清除记录，返回 false
    │
    ├─ 7. 实际资源文件抽样检查
    │      └─ 不存在 → 清除记录，返回 false
    │
    └─ 8. 确保搜索路径已添加
           └─ 校验通过 → 添加搜索路径，返回 true
```

### 数据结构

```javascript
// LocalStorage Key: "ResourceManV2_DownloadCache"
// Value: JSON string
{
    "activity/club_event_box": "93.6.905520",
    "activity/christmas": "93.6.905520",
    "slot/wild_fever": "93.6.905520"
    // resourcePath: commonVersion
}
```

## 实现细节

### 修改文件

| 文件 | 修改内容 |
|-----|---------|
| `src/resource_v2/core/CacheManager.js` | 增加持久化逻辑和搜索路径管理 |
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

    // 3. localStorage 记录检查
    var cache = this._loadFromStorage();
    var cachedVersion = cache[resourcePath];
    if (!cachedVersion) {
        return false;
    }

    // 4. Config.commonVersion 版本对比
    var currentVersion = this._getCommonVersion();
    if (cachedVersion !== currentVersion) {
        this._clearCacheRecord(resourcePath);
        return false;
    }

    // 5. 本地文件存在性检查
    var storagePath = this._getStoragePath(resourcePath);
    var manifestPath = storagePath + 'project.manifest';
    if (!jsb.fileUtils.isFileExist(manifestPath)) {
        this._clearCacheRecord(resourcePath);
        return false;
    }

    // 6. 本地 manifest 版本号对比
    var localManifestVersion = this._getLocalManifestVersion(manifestPath);
    if (!localManifestVersion || localManifestVersion !== cachedVersion) {
        this._clearCacheRecord(resourcePath);
        return false;
    }

    // 7. 检查实际资源文件是否存在（抽样检查）
    var hasResourceFiles = this._checkResourceFilesExist(storagePath);
    if (!hasResourceFiles) {
        this._clearCacheRecord(resourcePath);
        return false;
    }

    // 8. 确保搜索路径已添加（关键！否则资源无法被找到）
    this._ensureSearchPath(storagePath);

    // 校验通过，更新内存缓存
    this._downloadedMap[resourcePath] = true;
    return true;
}
```

#### markAsDownloaded 方法

```javascript
markAsDownloaded: function (resourcePath) {
    this._downloadedMap[resourcePath] = true;
    delete this._downloadingMap[resourcePath];

    // Native 端持久化到 localStorage
    if (cc.sys.isNative) {
        this._saveToStorage(resourcePath);
    }
}
```

#### 搜索路径管理

```javascript
_ensureSearchPath: function (storagePath) {
    if (!cc.sys.isNative) {
        return;
    }

    var searchPathArr = jsb.fileUtils.getSearchPaths();

    // 检查是否已在搜索路径中
    for (var i = 0; i < searchPathArr.length; i++) {
        if (searchPathArr[i] === storagePath) {
            return;
        }
    }

    // 添加到搜索路径
    searchPathArr.push(storagePath);
    jsb.fileUtils.setSearchPaths(searchPathArr);
}
```

## 关键点说明

### 为什么需要添加搜索路径？

`jsb.AssetsManager` 下载资源到 `storagePath`（如 `/var/mobile/.../activity/xxx/`），但 Cocos2d 加载资源时使用**相对路径**（如 `activity/xxx/res.png`）。

| API | 路径类型 | 是否依赖搜索路径 |
|-----|---------|----------------|
| `jsb.fileUtils.isFileExist()` | 绝对路径 | 否 |
| `cc.spriteFrameCache.addSpriteFrames()` | 相对路径 | 是 |
| `cc.loader.load()` | 相对路径 | 是 |

如果跳过下载但不添加搜索路径，后续资源加载会失败。

### 为什么需要抽样检查资源文件？

仅检查 `project.manifest` 存在不够，可能出现：
- manifest 存在但资源文件被删除
- 下载中断导致资源不完整

通过读取 manifest 的 `assets` 字段，检查第一个资源文件是否存在，可有效防止这种情况。

## 验证方法

### 1. 首次下载

```
操作：清除 localStorage 和本地资源，进入工会活动
预期：
  - 控制台显示 jsb.AssetsManager 下载日志
  - localStorage 写入缓存记录
```

### 2. 再次进入（版本相同）

```
操作：重启应用，进入工会活动
预期：
  - 控制台显示 [SKIP DOWNLOAD] Local cache valid
  - 无 EventListenerAssetsManager 日志
  - 资源正常加载
```

### 3. 版本更新场景

```
操作：修改 Config.commonVersion，重启应用
预期：
  - 控制台显示 Version mismatch
  - 触发重新下载
```

### 4. 文件损坏场景

```
操作：手动删除 storagePath 下的文件，重启应用
预期：
  - 控制台显示相应错误
  - 清除缓存记录
  - 触发重新下载
```

## 日志示例

### 缓存命中

```
[ResourceManV2][CacheManager] Checking manifest path: /var/mobile/.../activity/system_daily_mission/project.manifest
[ResourceManV2][CacheManager] Sample resource check: system_daily_mission.plist - exists: true
[ResourceManV2][CacheManager] Added search path: /var/mobile/.../activity/system_daily_mission/
[ResourceManV2][CacheManager] [SKIP DOWNLOAD] Local cache valid: activity/system_daily_mission - version: 93.6.905520
```

### 版本不匹配

```
[ResourceManV2][CacheManager] Version mismatch for poster/card_system_album_bonus_poster_s21_album - cached: 1.0.1 current: 93.6.905520
[ResourceManV2][CacheManager] Saved to storage: poster/card_system_album_bonus_poster_s21_album - version: 93.6.905520
```

## 相关文件

- `src/resource_v2/core/CacheManager.js` - 缓存管理器
- `src/resource_v2/ResourceManV2.js` - 资源管理器入口
- `src/resource_v2/adapters/NativeDownloader.js` - Native 下载适配器
- `src/common/asset/AssetsManager.js` - jsb.AssetsManager 封装

## 更新记录

| 日期 | 内容 |
|-----|-----|
| 2026-01-13 | 初始实现，8 层校验流程 |
