# CocosBuilder Bug Fix: NSInvalidArgumentException 崩溃修复

**日期：** 2025-10-17
**提交：** bcaded65

---

## 问题描述

### 崩溃日志

应用在启动时崩溃，错误信息：

```
*** -[NSRegularExpression enumerateMatchesInString:options:range:usingBlock:]: nil argument
FAULT: NSInvalidArgumentException: *** -[NSRegularExpression enumerateMatchesInString:options:range:usingBlock:]: nil argument
```

### 调用栈

```
0   CoreFoundation           __exceptionPreprocess + 176
1   libobjc.A.dylib          objc_exception_throw + 88
2   Foundation               -[NSRegularExpression enumerateMatchesInString:options:range:usingBlock:] + 1700
3   Foundation               -[NSRegularExpression firstMatchInString:options:range:] + 180
4   CocosBuilder             -[CocosBuilderAppDelegate checkUpdate] + 624    ← 崩溃点
5   CocosBuilder             -[CocosBuilderAppDelegate openProject:] + 1444
6   CocosBuilder             __40-[CocosBuilderAppDelegate openDocument:]_block_invoke_2 + 128
```

崩溃发生在：`CocosBuilderAppDelegate.m:4897`

---

## 根本原因分析

### 代码问题

**位置：** `CocosBuilder/ccBuilder/CocosBuilderAppDelegate.m`
**方法：** `- (void) checkUpdate`
**行号：** 4894-4897

**问题代码：**

```objective-c
// Line 4892: 检查文件是否存在
if (![[NSFileManager defaultManager] fileExistsAtPath:shellPath]) return;

// Line 4894: 读取文件内容
NSString* file = [NSString stringWithContentsOfFile:shellPath
                                          encoding:NSUTF8StringEncoding
                                             error:nil];

// Line 4897: 直接使用 file，未检查 nil
NSTextCheckingResult* match = [reg firstMatchInString:file
                                              options:0
                                                range:NSMakeRange(0, [file length])];
```

### 为什么会出现 nil？

虽然代码在第 4892 行检查了文件是否存在，但 `stringWithContentsOfFile:` 仍然可能返回 nil：

1. **权限问题：** 文件存在但没有读取权限
2. **编码问题：** 文件内容无法用 UTF-8 解码
3. **I/O 错误：** 磁盘错误或文件被锁定
4. **文件被删除：** 在检查存在性后、读取前被删除（竞态条件）

### 触发场景

在 ARM64 Mac 上运行时，当用户打开项目后触发：

1. `openProject:` 被调用
2. 调用 `checkUpdate` 检查插件更新
3. 尝试读取 `PlugIns/updateCocosBuilder.sh`
4. 文件读取失败返回 nil
5. 传递 nil 给 `firstMatchInString:` 导致崩溃

---

## 修复方案

### 代码修改

**文件：** `CocosBuilder/ccBuilder/CocosBuilderAppDelegate.m`
**行号：** 4895（新增）

**修复后的代码：**

```objective-c
// Line 4892: 检查文件是否存在
if (![[NSFileManager defaultManager] fileExistsAtPath:shellPath]) return;

// Line 4894: 读取文件内容
NSString* file = [NSString stringWithContentsOfFile:shellPath
                                          encoding:NSUTF8StringEncoding
                                             error:nil];

// Line 4895: ✅ 新增：检查文件内容是否为 nil
if (!file) return;  // Guard against nil file content

// Line 4897-4899: 现在安全使用 file
NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:
                            @"#[^\\n\\r\\S]*version[^\\n\\r\\S]*:[^\\n\\r\\S]*(\\d+)"
                            options:NSRegularExpressionCaseInsensitive
                            error:nil];
NSTextCheckingResult* match = [reg firstMatchInString:file
                                              options:0
                                                range:NSMakeRange(0, [file length])];
```

### 修复原理

添加了防御性编程的 nil 检查：
- 如果文件内容为 nil，提前返回
- 避免将 nil 传递给 NSRegularExpression
- 优雅地处理文件读取失败的情况

---

## 测试验证

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

### 验证架构

✅ **Universal Binary 仍然正常**

```bash
lipo -info ~/Library/Developer/Xcode/DerivedData/CocosBuilder-*/Build/Products/Debug/CocosBuilder.app/Contents/MacOS/CocosBuilder
```

输出：`Architectures in the fat file: x86_64 arm64`

### 运行时测试建议

建议测试以下场景：

- [ ] **正常启动：** 应用能正常启动不崩溃
- [ ] **打开项目：** 打开包含 PlugIns 目录的项目
- [ ] **打开项目（无 PlugIns）：** 打开不含 updateCocosBuilder.sh 的项目
- [ ] **权限测试：** 修改 updateCocosBuilder.sh 权限为不可读

---

## 影响范围

### 受影响功能

- **自动更新检查：** 插件自动更新功能
- **影响范围：** 仅在打开项目时触发

### 用户影响

- **之前：** 应用在某些情况下启动崩溃
- **现在：** 优雅处理文件读取失败，不再崩溃

### 功能行为

- ✅ 如果文件读取成功，正常检查更新
- ✅ 如果文件读取失败，静默跳过更新检查
- ✅ 不影响应用的其他功能

---

## 相关提交

### Bug 修复提交

**Commit:** `bcaded65`
**标题:** Fix NSInvalidArgumentException crash in checkUpdate method
**文件:** `CocosBuilder/ccBuilder/CocosBuilderAppDelegate.m`
**更改:** +2 行（添加 nil 检查和注释）

### 相关提交

**Commit:** `3162420a`
**标题:** Enable Universal Binary support (x86_64 + ARM64)
**说明:** ARM64 迁移时可能触发了这个潜在的 bug

---

## 代码质量改进

### 防御性编程

这次修复体现了良好的防御性编程实践：

1. **不信任外部数据：** 文件读取可能失败
2. **及早检查返回值：** 在使用前验证 nil
3. **优雅降级：** 失败时提前返回，不影响其他功能

### 建议的后续改进

如果需要进一步改进，可以考虑：

```objective-c
NSError *error = nil;
NSString* file = [NSString stringWithContentsOfFile:shellPath
                                          encoding:NSUTF8StringEncoding
                                             error:&error];
if (!file) {
    if (error) {
        NSLog(@"Failed to read update script: %@", error);
    }
    return;
}
```

这样可以记录具体的失败原因，便于调试。

---

## 经验教训

### 1. Objective-C API 的返回值

许多 Objective-C API 可能返回 nil，即使参数合法：
- `stringWithContentsOfFile:` 可能返回 nil
- 即使文件存在，读取也可能失败
- **总是检查返回值**

### 2. 竞态条件

文件系统操作存在竞态条件：
```objective-c
if (fileExists) {      // Time of Check
    readFile();        // Time of Use  ← 文件可能已被删除
}
```

**解决方案：** 检查操作结果而不是前置条件

### 3. ARM64 迁移的副作用

虽然这个 bug 与 ARM64 无关，但在测试 ARM64 版本时被触发。这提醒我们：
- 架构迁移可能暴露潜在的 bug
- 需要全面的回归测试
- 防御性编程很重要

---

## 总结

✅ **Bug 已修复：** 添加 nil 检查防止崩溃
✅ **构建验证：** 编译成功，Universal Binary 正常
✅ **代码改进：** 提高了代码的健壮性
✅ **影响最小：** 仅 2 行代码更改，风险极低

**建议：** 在实际环境中进行运行时测试，验证修复效果。
