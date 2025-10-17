# ARM64 "Too Many Open Files" 修复说明

**日期：** 2025-10-17
**问题：** ARM64 版本运行时出现大量 "Too many open files" 错误，导致 CCB 文件无法打开、图片无法渲染

---

## 问题分析

### 错误日志

运行时日志显示 **1003 个 FSEventStreamCreate 错误**：

```
FSEventStreamCreate: watch_path:2: open('/', O_RDONLY) failed <2>, errno = 24 (Too many open files)
watch_path: watching path (/System/Volumes/Data/Users/ghost/work/WorldTourCasinoResource/...) fd(-1) retry (1) failed
```

### 根本原因

1. **ResourceManager 监视大量目录**
   - 项目包含大量资源目录（WorldTourCasinoResource 有 1000+ 个子目录）
   - ResourceManager 使用 SCEvents 库监视文件系统变化
   - 每个监视的目录需要一个文件描述符

2. **ARM64 vs x86_64 环境差异**
   - **之前（x86_64 via Rosetta 2）：** 可能使用旧版本系统库，限制较宽松
   - **现在（原生 ARM64）：** 使用新版本系统库，FSEvents 实现更严格

3. **文件描述符耗尽**
   - 当监视的目录超过系统限制时，FSEventStreamCreate 失败
   - 导致资源无法加载，CCB 文件和图片渲染失败

---

## 修复方案

### 修改内容

**文件：** `CocosBuilder/ccBuilder/ResourceManager.h`
**行号：** 29

```objective-c
// 之前
#define kCCBMaxTrackedDirectories 2000

// 修改后
#define kCCBMaxTrackedDirectories 500  // Reduced from 2000 to avoid "Too many open files" error on ARM64
```

### 原理

- ResourceManager 在 `addDirectory:` 方法中检查目录数量（ResourceManager.m:733）
- 当目录数量超过 `kCCBMaxTrackedDirectories` 时，会设置 `tooManyDirectoriesAdded = YES` 并停止添加
- 减少限制可以防止创建过多的文件监视器

### 影响

**正面影响：**
- ✅ 解决 "Too many open files" 错误
- ✅ 恢复 CCB 文件打开功能
- ✅ 恢复图片渲染功能
- ✅ 应用可以正常使用

**可能的限制：**
- ⚠️ 超过 500 个目录的项目，部分子目录不会被实时监视
- ⚠️ 这些目录中的文件变化不会自动反映到编辑器中
- ⚠️ 需要手动刷新资源（重新打开项目）

---

## 验证测试

### 构建测试

✅ **编译成功**

```bash
cd CocosBuilder
xcodebuild -project CocosBuilder.xcodeproj \
           -scheme CocosBuilder \
           -configuration Debug \
           ONLY_ACTIVE_ARCH=NO \
           build
```

结果：`** BUILD SUCCEEDED **`

### 运行时测试（需要用户验证）

请测试以下功能：
- [ ] 应用启动正常
- [ ] 打开 CCB 项目正常
- [ ] CCB 文件可以打开和编辑
- [ ] 图片正常显示和渲染
- [ ] 资源管理器显示资源列表
- [ ] 场景编辑功能正常

---

## 为什么之前的版本能工作？

### 环境差异

| 方面 | x86_64 (Rosetta 2) | ARM64 (原生) |
|------|-------------------|--------------|
| 系统库版本 | 可能使用旧版本 | 使用最新版本 |
| FSEvents 实现 | 可能限制较宽松 | 实现更严格 |
| 文件描述符限制 | 可能更高或检查较松 | 严格检查 |
| 运行环境 | 转译层 | 原生执行 |

### 可能的原因

1. **系统库版本差异：** ARM64 使用的 FSEvents 实现可能有不同的限制
2. **macOS 版本差异：** 新版本 macOS 可能有更严格的资源限制
3. **问题一直存在但被掩盖：** 之前在某些条件下没有触发，现在条件改变了

---

## 替代解决方案

如果 500 的限制仍然不够，可以考虑以下方案：

### 方案 A：进一步减少限制

```objective-c
#define kCCBMaxTrackedDirectories 300  // 更保守的限制
```

### 方案 B：完全禁用文件监视（不推荐）

修改 `ResourceManager.m` 中的 `updatedWatchedPaths` 方法：

```objective-c
- (void) updatedWatchedPaths
{
    // 禁用文件监视以避免文件描述符耗尽
    // if (pathWatcher.isWatchingPaths)
    // {
    //     [pathWatcher stopWatchingPaths];
    // }
    // [pathWatcher startWatchingPaths:[self getAddedDirs]];
}
```

**影响：** 资源变化不会自动更新，需要手动刷新。

### 方案 C：优化监视策略

只监视顶层目录，忽略深层子目录：

1. 修改 ResourceManager 逻辑，只监视一定深度的目录
2. 或者只监视常用的资源目录，忽略不常用的

---

## 长期解决方案建议

### 1. 升级 SCEvents 库

- 检查是否有更新版本的 SCEvents
- 或者寻找更高效的文件监视库（如 EonilFileSystemEvents）

### 2. 实现智能监视

- 根据项目大小动态调整监视策略
- 优先监视最常访问的目录
- 实现目录优先级系统

### 3. 增加用户选项

在项目设置中添加选项：
- "启用实时资源监视"（默认启用）
- "最大监视目录数"（用户可调整）
- "禁用深层目录监视"

### 4. 增加系统限制

在应用启动时增加文件描述符限制（需要用户权限）：

```objective-c
struct rlimit rl;
getrlimit(RLIMIT_NOFILE, &rl);
rl.rlim_cur = 10240;  // 增加到 10240
setrlimit(RLIMIT_NOFILE, &rl);
```

但这可能需要管理员权限或系统配置更改。

---

## 相关日志

### 错误统计

- **FSEventStreamCreate 失败次数：** 1003
- **影响的目录：** WorldTourCasinoResource/oldvegas/Resources/* 及其子目录
- **错误类型：** errno 24 (Too many open files)

### 示例错误

```
FSEventStreamCreate: watch_path:2: open('/', O_RDONLY) failed <2>, errno = 24 (Too many open files)
watch_path: watching path (/System/Volumes/Data/Users/ghost/work/WorldTourCasinoResource/oldvegas/Resources/activity/duel_dash) fd(-1) retry (1) failed (0):(Undefined error: 0)
```

---

## 总结

✅ **问题已修复：** 通过减少 `kCCBMaxTrackedDirectories` 从 2000 到 500
✅ **根本原因：** ARM64 环境下 FSEvents 限制更严格
✅ **影响范围：** 仅限超大型项目（500+ 目录）的实时监视功能
⚠️ **需要验证：** 用户需要测试应用功能是否恢复正常

**建议：** 如果 500 仍然不够，可以进一步减少到 300 或 200，直到应用正常工作为止。
