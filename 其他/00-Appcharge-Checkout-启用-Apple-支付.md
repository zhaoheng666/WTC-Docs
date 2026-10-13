---
title: Appcharge Checkout 启用 Apple 支付
---

# Appcharge Checkout 启用 Apple 支付

> 源自飞书文档 · 最后同步：2026-10-13

配套 [AppCharge 接入 SOP](https://ghoststudio.feishu.cn/wiki/O3WLwe8LAikXMLkNu4JcizmanPd)，记录 Appcharge Web Checkout 启用 Apple Pay 的完整流程与历史踩坑。

## 时间摘要

- 2026-06-01：南芳在「第三方支付」群提出，Appcharge 结算方式目前没有 Apple Pay 选项，大 R 反馈希望增加且竞品 Apple Pay 占比高，建议评估上线。
- 2026-06-01：王建在 CV/DH 共 6 个域名下完成 Apple 域名验证文件的部署，并把清单发到群里。
- 2026-06-02：南芳反馈有 2 个问题——CV 网页版测试环境 `Connection refused`、5 个域名 `Content-Type` 配错（应为 `text/plain` 实际为 `application/octet-stream`）。王建当天修复，并确认外链方式验证通过。
- 2026-10-13：VS / DX 项目对接 Appcharge Checkout，新增 Android 外链中间站 `appcharge_bridge_*` 配置；网页端、跳转、支付测试正常，王建补充：「apple 这个也要单独加」（即 iOS Apple Pay 与 Android 是独立的两件事）。
---

## 1. 背景

Appcharge 的 Web Checkout 默认走 Stripe / 卡支付，不直接支持 Apple Pay。要让 Apple Pay 在 Checkout 页面上出现，须按 Appcharge 要求**在所有加载 Checkout 页面的顶层域名上部署 Apple 域名验证文件**，让 Apple 注册这些域名。完成后：

- 加载速度、成功率、稳定性提升。
- 结算选项里会**单独出现** Apple Pay（iOS / macOS Safari 上自动出现按钮），与 Card / Link 并列。
- 项目维度独立：每个新项目（如 CV、DH、VS、DX）接入 AppCharge 时，需要单独走一遍该流程、上传它对应的全部域名。
适用范围：所有走 Appcharge Checkout 的产品，即目前 Vegas 系列、Classic Vegas、Double Hit 等。

## 2. 启用流程（Appcharge 官方 5 步）

来自 Appcharge 官方文档 [Add Apple Pay](https://docs.appcharge.com/guides/checkout/add-apple-pay)：

1. **提供域名列表**：提交一份用于加载 Checkout 页面的完整域名 / 子域名列表，**包含测试环境域名**，明确标注**生产环境**域名。
1. **获取认证文件**：Appcharge 向 Apple 注册上述域名后，提供对应的认证文件。
1. **上传认证文件**：将该认证文件上传到所有相关域名的指定路径 `/.well-known/apple-developer-merchantid-domain-association`，确保文件**公开可访问**（HTTPS、HTTP 200、无重定向）。
1. **通知验证**：文件上传完成后通知 Appcharge，由对方验证文件配置正确性。
1. **测试验证**：验证通过后，使用专门测试卡在测试环境完成一笔 Apple Pay 测试交易，确认集成配置正常。
⚠️ 第 3 步不仅是"文件在"，还有一个易踩的坑——`Content-Type` 必须是 `text/plain`。CV 当时被配成 `application/octet-stream`，导致 6 月 2 日被打回重做。

## 3. 验证文件规格

| 字段 | 值 |
| --- | --- |
| 文件名 | `apple-developer-merchantid-domain-association` |
| 大小 | 9094 bytes |
| MD5 | `230e4592b3844d35aaac33e4344a2805` |
| 部署路径 | 域名根目录 `/.well-known/apple-developer-merchantid-domain-association` |
| 访问要求 | HTTPS、HTTP 200、无重定向、公网可访问 |
| Content-Type | `text/plain` |

## 4. 部署清单

### 4.1 CV（Classic Vegas）生产环境

| 角色 | 域名 |
| --- | --- |
| Web 入口 | `https://slotssaga-v401-cdn.me2zengame.com/.well-known/apple-developer-merchantid-domain-association` |
| App 网关 | `https://slots-wtc-gate.me2zengame.com/.well-known/apple-developer-merchantid-domain-association` |

### 4.2 DH（DoubleHit）生产环境

| 角色 | 域名 |
| --- | --- |
| Web 入口 | `https://slots-lucky-casino-res-cdn.me2zengame.com/.well-known/apple-developer-merchantid-domain-association`（当时未启用） |
| App 网关 | `https://slots-doublehit-gate.me2zengame.com/.well-known/apple-developer-merchantid-domain-association` |

### 4.3 测试环境（CV 和 DH 共用）

| 来源 | 域名 |
| --- | --- |
| AWS | `https://slots-team-test-server-v0.me2zengame.com/.well-known/apple-developer-merchantid-domain-association` |
| 阿里云 | `https://ali-slots-res.me2zengame.com/.well-known/apple-developer-merchantid-domain-association` |

### 4.4 部署架构

- `slotssaga-v401-cdn`：AWS CloudFront → Nginx 源站（`slotssaga-v401.me2zengame.com`），部署位置 `/export/nginx/https/.well-known/`
- `slots-wtc-gate`：AWS Nginx，部署位置 `/usr/share/nginx/html/.well-known/`
- `slots-lucky-casino-res-cdn`：AWS CloudFront → Nginx 源站（`slots-res-server-new.me2zengame.com`），部署位置 `/usr/share/nginx/https/.well-known/`
- `slots-doublehit-gate`：AWS Nginx，部署位置 `/usr/share/nginx/html/.well-known/`
- `slots-team-test-server-v0`：AWS Nginx（443 default server），部署位置 `/usr/share/nginx/html/.well-known/`
- `ali-slots-res`：阿里云 CDN → 内网源站（ali-beta），部署位置 `/usr/share/nginx/html/.well-known/`
## 5. 当前状态（截至 2026-06）

- 6 个域名验证文件已全部部署完成。
- 所有 URL 外网访问返回 HTTP 200，文件 MD5 一致。
- 已通知 Appcharge 触发 Apple 端域名验证。
- CV / DH 生产入口走充值流程，确认 Apple Pay 按钮出现并完成支付测试。
- CV 网页版（`slotssaga-v401-cdn` 测试环境）证书不好用，6 月 2 日仅以"外链方式"验证，其它 5 个域名的 `Content-Type` 已改为 `text/plain` 后通过。
## 6. VS / DX 新项目接入（2026-10）

VS（Vegas Star）、DX 是 2026-10 新接入 Appcharge Checkout 的项目。Android 端需要走公司自建中间站 `appcharge_bridge_*`，与 Apple Pay 是**独立**的两件事：

王建 2026-10-13 11:23: 「嗯嗯，apple 这个也要单独加」——即 iOS Apple Pay 与 Android 外链是两条线。

### 6.1 Android 中间站 URL 配置

```
var uri_map = {};
var uri_map_debug = {};
uri_map[ThemeName.THEME_DOUBLE_HIT]  = "https://slots-doublehit-gate.me2zengame.com/appcharge_bridge/";
uri_map[ThemeName.THEME_OLD_VEGAS]    = "https://slots-wtc-gate.me2zengame.com/appcharge_bridge_cv/";
uri_map[ThemeName.THEME_VEGAS_STAR]   = "https://slots-vegasstar-gate.me2zengame.com/appcharge_bridge_vs/";
uri_map_debug[ThemeName.THEME_DOUBLE_HIT] = "https://slots-team-test-server-v0.me2zengame.com/appcharge_bridge/";
uri_map_debug[ThemeName.THEME_OLD_VEGAS]   = "https://slots-team-test-server-v0.me2zengame.com/appcharge_bridge_cv/";
uri_map_debug[ThemeName.THEME_VEGAS_STAR]  = "https://slots-team-test-server-v0.me2zengame.com/appcharge_bridge_vs/";
var uri = Config.isDebug() ? uri_map_debug[Config.themeName] : uri_map[Config.themeName];
```

### 6.2 APP 回跳 Scheme

| 项目 | Scheme |
| --- | --- |
| VS APP | `fb1010681085629414` |
| DX APP | `fb897497747010840` |

### 6.3 VS Apple Pay 待办

类比 CV/DH 的清单，VS / DX 也需要：

1. 在 `slots-vegasstar-gate.me2zengame.com`（生产）、`slots-team-test-server-v0.me2zengame.com`（测试）部署 `apple-developer-merchantid-domain-association` 文件到 `/.well-known/`，`Content-Type = text/plain`。
1. 收集 VS 项目所有用于加载 Checkout 的域名（含测试），提供给 Appcharge；通知他们向 Apple 注册，拿到官方认证文件并替换。
1. 等待 Appcharge / Apple 验证通过。
1. 在测试环境用专用测试卡完成一笔 Apple Pay 测试交易，确认按钮出现并能完成支付。
DX 项目域名待定，未在 2026-10-13 的讨论中给出。

## 7. 易踩坑 / FAQ

- **`Content-Type`**** 必须为 ****`text/plain`**，否则 Apple 端校验失败。容易默认成 `application/octet-stream`（Nginx 默认行为），需显式设置。
- **HTTPS + HTTP 200 + 无重定向**三个条件都要满足：CDN 重定向、HTTP 而不是 HTTPS、5xx 状态码都会验证失败。
- **APP 网关域名（****`* -gate`****）≠ Web CDN 域名（****`* -cdn`****）**：APP 网关是 native 跳转外链使用的入口，Web CDN 是网页版入口，两个都需单独部署文件。
- **测试环境（AWS / 阿里云）域名也要加**——不是可选项，否则测试环境无法测试 Apple Pay。
- **每个项目独立**：CV/DH 部署过不代表 VS 自动生效，需要单独走 Appcharge / Apple 注册流程并部署。
## 8. 相关参考

- Appcharge 官方文档：[Add Apple Pay](https://docs.appcharge.com/guides/checkout/add-apple-pay)
- 配套 SOP：[AppCharge 接入 SOP](https://ghoststudio.feishu.cn/wiki/O3WLwe8LAikXMLkNu4JcizmanPd)
- 讨论消息：王建 p2p（2026-06-01 16:39 部署清单 post）、南芳「第三方支付」群（2026-06-01 14:18 申请、Apple Pay 5 步流程）、王建「第三方支付」群（2026-06-01 17:40 修复版本）。
- 测试上线讨论：赵恒 / 王建 p2p（2026-10-13 上午 — Android 中间站 + Apple Pay 提醒）、南芳 / 苏振宇「第三方支付」群（2026-09-23 09:59~10:20 第三方支付验证）。
