# DH资源异常-manifest和文件访问预警

## 摘要

| | |
|-|-|
| **状态** | ✅ 已解决 |
| **日期** | 2025年11月10日 |
| **游戏** | DoubleHit (DH) |
| **问题资源** | `coupon_board_cv_2024_turkey_likeclg_20240927193848` |
| **根本原因** | 运营后台用 `current_version` CDN链接，游戏用版本号链接，发版只过期后者 |
| **解决方案** | 每次发版同时过期 `current_version` 链接 |
| **原文档** | [飞书文档](https://ghoststudio.feishu.cn/wiki/GgllwsRQ4iz1sWkswp8cOtJYnfb) |

## 监控截图

![问题资源详情](/assets/db67dddf2342b2c49e6f0f768089d0aa.png)

## 问题

2025年11月10日 02:00-03:00 (UTC+0)，DH 游戏资源访问异常激增：

| 预警项 | 监控值 | 增长率 |
|-------|--------|--------|
| manifest文件访问异常 | 578 | 3300% |
| 文件访问异常 | 539 | 4391.67% |

## 根本原因

### CDN链接不一致

**现状**：
- 运营后台：`current_version` CDN链接
- 游戏客户端：版本号CDN链接（如 `v1.2.3/...`）

**问题流程**：
1. 发版只过期版本号链接，未过期 `current_version`
2. 运营后台仍能访问已删除资源
3. 运营发布包含已删除资源的 coupon
4. 玩家收到 coupon，游戏客户端访问失败
5. 触发大量 manifest 和文件访问异常

### 时间戳一致性

资源名、ccbi 文件、coupon 数据中的时间戳必须一致，否则即使资源存在也会加载失败。

## 解决方案

每次发版同时过期 `current_version` CDN链接，保证运营和游戏看到相同资源列表

