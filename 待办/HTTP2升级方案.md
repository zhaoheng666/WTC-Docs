# HTTP/2 升级方案

> 创建时间：2025-12-03
> 状态：待办
> 优先级：低
> 负责人：赵恒
> 预计时间：2026.3

## 现状分析

| 平台 | 网络层 | 当前协议 | HTTP/2 现状 |
|-----|-------|---------|-------------|
| **Web (Canvas)** | XMLHttpRequest | HTTP/1.1 | 浏览器原生支持，无需修改 |
| **Native iOS/Mac** | libcurl 7.52.1 | HTTP/1.1 | 需重编译 curl + nghttp2 |
| **Native Android** | HttpURLConnection | HTTP/1.1 | 可用 OkHttp 替代 |
| **游戏服务** | WebSocket | N/A | 不涉及 |

## 推荐方案

### 阶段一：服务器升级（零代码改动）

**收益**：Web 端立即获得 HTTP/2 支持

**步骤**：
1. 服务器配置 TLS 1.2+
2. 启用 ALPN 协议协商
3. 启用 HTTP/2 模块

**验证**：浏览器开发者工具查看 Protocol 列显示 `h2`

---

### 阶段二：Native 端升级

#### 方案 A：重编译 libcurl（推荐）

**优点**：跨平台一致，改动小
**缺点**：需要重新编译外部库

**修改文件**：

| 文件 | 修改内容 |
|-----|---------|
| `frameworks/cocos2d-x/external/curl/CMakeLists.txt` | 添加 nghttp2 依赖 |
| `frameworks/cocos2d-x/cocos/network/HttpClient.cpp` | 添加 `CURLOPT_HTTP_VERSION` 设置 |
| `frameworks/cocos2d-x/cocos/network/HttpClient.h` | 新增 HTTP 版本配置接口 |

**HttpClient.cpp 核心改动**：

```cpp
// 在 configureCURL() 函数中添加：
curl_easy_setopt(handle, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0);
```

**编译依赖**：
- nghttp2 库（iOS/Android/Mac/Windows 预编译版）
- curl 编译选项：`--with-nghttp2`

#### 方案 B：Android 使用 OkHttp（可选增强）

**优点**：Android 平台最优性能
**缺点**：增加维护复杂度

**修改文件**：
- `build.gradle`：添加 `okhttp3` 依赖
- 新建 `OkHttpClient.java`：替代 `Cocos2dxHttpURLConnection`

---

## 升级后优化建议

| 配置项 | 当前值 | 建议值 | 原因 |
|-------|-------|-------|------|
| `DownloadQueue._maxConcurrent` | 3 | 6-10 | HTTP/2 单连接多路复用 |

---

## 实施清单

```
☐ 服务器：配置 TLS + ALPN + HTTP/2
☐ 验证：Web 端 Protocol = h2
☐ 编译：nghttp2 库（各平台）
☐ 编译：libcurl with HTTP/2
☐ 修改：HttpClient.cpp 添加版本设置
☐ 测试：各平台 HTTP/2 连接
☐ 优化：调整 DownloadQueue 并发数
```

---

## 性能提升预估

### 当前瓶颈（HTTP/1.1）

| 瓶颈 | 当前值 | 影响 |
|-----|-------|------|
| 最大并发连接 | 3 个 | 浏览器限制每域名 6 个连接 |
| 每请求连接开销 | ~100-300ms | TCP + TLS 握手 |
| 请求头大小 | ~800 字节/请求 | Cookie、UA 等重复传输 |
| 队头阻塞 | 有 | 一个慢请求阻塞整条连接 |

### HTTP/2 提升预估

| 指标 | HTTP/1.1 | HTTP/2 | 提升幅度 |
|-----|----------|--------|---------|
| **单域名并发** | 6 连接 | 1 连接 100+ 流 | 无限制 |
| **连接复用** | 无 | 完全复用 | 省 100-300ms/请求 |
| **头部大小** | ~800B | ~50B (HPACK) | **减少 90%** |
| **队头阻塞** | 有 | 无（多路复用） | 消除 |

### 场景预估

#### 场景 1：游戏启动加载 50 个资源

| 指标 | HTTP/1.1 (3并发) | HTTP/2 (10并发) | 提升 |
|-----|-----------------|-----------------|------|
| 连接建立 | 3 次握手 | 1 次握手 | 省 200-600ms |
| 头部总量 | 40KB | 4KB | 省 36KB |
| 总耗时 | ~5s | ~2s | **提升 60%** |

#### 场景 2：活动资源批量下载 20 个包

| 指标 | HTTP/1.1 | HTTP/2 | 提升 |
|-----|----------|--------|------|
| 排队等待 | 17 个任务排队 | 0 排队 | 消除 |
| 下载耗时 | ~3s | ~1.2s | **提升 60%** |

#### 场景 3：海报/广告牌小资源

| 指标 | HTTP/1.1 | HTTP/2 | 提升 |
|-----|----------|--------|------|
| 连接开销占比 | 80% | 5% | **提升 75%** |
| 感知延迟 | 明显 | 几乎无感 | 用户体验改善 |

### 并发数调整建议

```javascript
// DownloadQueue 当前配置
_maxConcurrent: 3  // HTTP/1.1 安全值

// HTTP/2 升级后建议
_maxConcurrent: 8-10  // 单连接多路复用，无连接开销
```

### 综合预估

| 场景 | 预估提升 |
|-----|---------|
| 首次加载 | 40-60% |
| 活动资源下载 | 50-70% |
| 小文件批量请求 | 60-80% |
| 网络差环境 | 30-50% |

**注意**：实际提升取决于：
- 服务器响应速度
- 资源文件大小分布
- 用户网络环境
- CDN 是否支持 HTTP/2

---

## 风险评估

| 风险 | 影响 | 缓解措施 |
|-----|-----|---------|
| curl 编译失败 | Native 无法升级 | 保留 HTTP/1.1 回退 |
| 服务器不支持 | 全平台无效 | 协议自动降级 |
| 老设备兼容 | 部分用户受影响 | HTTP/2 自动降级到 1.1 |
