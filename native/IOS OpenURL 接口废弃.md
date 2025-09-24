# IOS OpenURL 接口废弃

### 部分用户游戏内跳转链接全部失效：

在 **iOS 18.0**（2024年发布）中，Apple 对 `openURL` API 进行了 **硬移除（Hard Removal）** 。

### 📌 具体变化：

1. **iOS 10.0 (2016)**

    - 引入 `openURL:options:completionHandler:` 替代
    - 标记旧方法 `openURL:` 为 `API_DEPRECATED`（软弃用）
2. **iOS 14.0 (2020)**

    - **静默行为变更**：调用 `openURL:` 会触发用户授权弹窗（不再支持无感跳转）
    - 但仍能使用（苹果通过 **运行时兼容层** 维持旧 API 运行）
3. **iOS 18.0 (2024)**

    - **直接移除** **​`openURL:`​**  **方法本身**（二进制级别删除）
    - 导致 App 在 iOS 18+ 设备上 **运行时崩溃**（调用时会报 `unrecognized selector` 错误）

### 🔧 验证方式：

- 在 **Xcode 16+**  使用 `@available` 检查，会看到警告：

  ```objc
  if (@available(iOS 18.0, *)) {
     return [[UIApplication sharedApplication] openURL:nsUrl];
  }
  ```

### ✅ 适配方案：

```objc
- (void)openURL:(NSURL *)url {
    if (!url) return;

    if (@available(iOS 10.0, *)) {
        // 强制使用 Universal Links（更安全，iOS 10+）
        [[UIApplication sharedApplication] openURL:url 
                                          options:@{ UIApplicationOpenURLOptionUniversalLinksOnly: @YES }
                                completionHandler:^(BOOL success) {
            if (!success) {
                // 降级方案：直接跳转（关闭 Universal Links 限制）
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            }
        }];
    } else {
        // iOS 9 及以下（保留旧方式）
        [[UIApplication sharedApplication] openURL:url];
    }
}
```

### ⚠️ **iOS 18+ 特别注意事项**

1. **必须检查 URL Scheme 白名单**  
    在 `Info.plist` 中声明需跳转的 Scheme，否则 iOS 18+ 会静默失败：

    ```xml
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>http</string>
        <string>https</string>
        <string>your-app-scheme</string>
    </array>
    ```
2. **Universal Links 优先**  
    如果目标 URL 支持 Universal Links（如跳转其他 App 的特定页面），应强制使用：

    ```swift
    options:@{ UIApplicationOpenURLOptionUniversalLinksOnly: @YES }  // 仅允许通过 Universal Links 跳转
    ```
3. **错误处理**  
    iOS 18+ 对 URL 跳转的安全性检查更严格，需处理失败情况：

    ```objc
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url 
                                          options:@{} 
                                completionHandler:^(BOOL success) {
            if (!success) {
                NSURL *safariURL = [NSURL URLWithString:@"https://example.com/fallback"];
                if (safariURL) {
                    [[UIApplication sharedApplication] openURL:safariURL 
                                                      options:@{} 
                                            completionHandler:nil];
                }
            }
        }];
    } else {
        // iOS 9及以下版本兼容
        BOOL success = [[UIApplication sharedApplication] openURL:url];
        if (!success) {
            NSURL *safariURL = [NSURL URLWithString:@"https://example.com/fallback"];
            if (safariURL) {
                [[UIApplication sharedApplication] openURL:safariURL];
            }
        }
    }
    ```

---

###  **📝苹果的 API 废弃策略**

- **阶段一：标记废弃 (Deprecated)**  - 只是警告开发者需要迁移
- **阶段二：软移除 (Soft Removal)**  - 保留功能但可能限制特性
- **阶段三：硬移除 (Hard Removal)**  - 彻底移除功能代码

### 📝 兼容性保障机制

苹果通常采用  **「双轨制兼容性」** ：

```objc
iOS 14-17:
└─ 保留旧版 openURL 的实现
   └─ 通过兼容性垫片(Compatibility Shim)转发到新API

iOS 18+:
└─ 移除兼容性垫片
   └─ 直接报错: "Symbol not found"
```
