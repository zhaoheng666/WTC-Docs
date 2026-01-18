# 协议 gzip 压缩分析

**分析日期**: 2026-01-13
**数据来源**: 客户端实际运行日志
**分析目的**: 找出最适合启用 gzip 压缩的协议

---

## 概述

本文档基于实际运行数据，分析各协议的大小、耗时、调用频率，为 gzip 压缩策略提供数据支撑。

### 当前压缩机制

- **全局开关**: `Protocol.gzipSwitch`
- **协议开关**: `Protocol.openGzip`
- **压缩路由**: `connector.entryHandler.protocolEntry_compress`
- **普通路由**: `connector.entryHandler.protocolEntry`

---

## 完整协议数据

### 原始日志数据

以下是单次完整登录流程中采集的所有协议数据：

| 序号 | 协议名 | 数据大小 | 总耗时 | 解析耗时 |
|-----|-------|---------|-------|---------|
| 1 | c2s_use_game_features | 744B | 342ms | 0ms |
| 2 | c2s_use_game_features | 747B | 311ms | 0ms |
| 3 | c2s_use_game_features | 767B | 353ms | 0ms |
| 4 | c2s_use_game_features | 625B | 299ms | 0ms |
| 5 | c2s_use_game_features | 543B | 342ms | 0ms |
| 6 | c2s_use_game_features | 615B | 376ms | 0ms |
| 7 | c2s_use_game_features | 471B | 318ms | 0ms |
| 8 | c2s_get_open_activities | 56B | 315ms | 0ms |
| 9 | c2s_get_game_features | 25,307B | 338ms | 0ms |
| 10 | c2s_use_game_features | 95B | 318ms | 0ms |
| 11 | c2s_use_game_features | 2,257B | 310ms | 0ms |
| 12 | c2s_use_game_features | 297B | 326ms | 0ms |
| 13 | c2s_use_game_features | 176B | 375ms | 0ms |
| 14 | c2s_use_game_features | 342B | 339ms | 0ms |
| 15 | c2s_use_game_features | 174B | 294ms | 0ms |
| 16 | c2s_get_open_activities | 57B | 349ms | 0ms |
| 17 | c2s_use_game_features | 1,292B | 317ms | 0ms |
| 18 | c2s_use_game_features | 107B | 372ms | 0ms |
| 19 | c2s_login | 3,875B | 321ms | 0ms |
| 20 | c2s_get_subjects | 128,339B | 409ms | 0ms |
| 21 | c2s_get_shops | 40,037B | 710ms | 0ms |
| 22 | c2s_get_timed_challenge | 315B | 4ms | 0ms |
| 23 | c2s_get_operation_info | 87B | 4ms | 0ms |
| 24 | c2s_get_spin_mode_activity | 1,118B | 118ms | 0ms |
| 25 | c2s_get_group_link | 32B | 246ms | 0ms |
| 26 | c2s_ad_control | 747B | 388ms | 0ms |
| 27 | c2s_get_game_features | 42,492B | 528ms | 0ms |
| 28 | c2s_daily_shop_pop_up | 35B | 96ms | 0ms |
| 29 | c2s_get_activities | 62,318B | 328ms | 0ms |
| 30 | c2s_get_hourly_bonus | 194B | 189ms | 0ms |
| 31 | c2s_get_daily_bonus | 614B | 273ms | 0ms |
| 32 | c2s_get_login_bonus | 3,292B | 393ms | 0ms |
| 33 | c2s_get_reward | 5,180B | 511ms | 0ms |
| 34 | c2s_get_clover_clash | 4,017B | 147ms | 0ms |
| 35 | c2s_get_clover_clash | 4,950B | 192ms | 0ms |
| 36 | c2s_get_operation_info | 86B | 129ms | 0ms |
| 37 | c2s_get_smoke | 27B | 68ms | 0ms |
| 38 | c2s_get_processing_purchase | 242B | 263ms | 0ms |
| 39 | c2s_get_system_message | 51B | 323ms | 0ms |
| 40 | c2s_get_mails | 38B | 391ms | 0ms |
| 41 | c2s_enter_room | 2,339B | 733ms | 0ms |
| 42 | c2s_update_prize_pool_players | 365B | 273ms | 0ms |
| 43 | c2s_claim_special_activity_reward | 5,418B | 423ms | 0ms |
| 44 | c2s_spin | 2,440B | 330ms | 0ms |
| 45 | c2s_update_prize_pool_players | 369B | 403ms | 0ms |
| 46 | c2s_update_prize_pool_players | 369B | 319ms | 0ms |
| 47 | c2s_update_prize_pool_players | 369B | 306ms | 0ms |
| 48 | c2s_update_prize_pool_players | 369B | 301ms | 0ms |
| 49 | c2s_update_prize_pool_players | 368B | 338ms | 0ms |
| 50 | c2s_update_prize_pool_players | 381B | 305ms | 0ms |
| 51 | c2s_update_prize_pool_players | 381B | 300ms | 0ms |
| 52 | c2s_update_prize_pool_players | 381B | 378ms | 0ms |
| 53 | c2s_update_prize_pool_players | 381B | 366ms | 0ms |
| 54 | c2s_update_prize_pool_players | 387B | 346ms | 0ms |
| 55 | c2s_claim_special_activity_reward | 1,014B | 331ms | 0ms |

---

## 统计分析

### 按数据大小排序（降序）

| 排名 | 协议名 | 数据大小 | 耗时 | 压缩建议 |
|-----|-------|---------|------|---------|
| 1 | c2s_get_subjects | 128,339B (125.3KB) | 409ms | 🔴 强烈推荐 |
| 2 | c2s_get_activities | 62,318B (60.9KB) | 328ms | 🔴 强烈推荐 |
| 3 | c2s_get_game_features | 42,492B (41.5KB) | 528ms | 🔴 强烈推荐 |
| 4 | c2s_get_shops | 40,037B (39.1KB) | 710ms | 🔴 强烈推荐 |
| 5 | c2s_get_game_features | 25,307B (24.7KB) | 338ms | 🔴 强烈推荐 |
| 6 | c2s_claim_special_activity_reward | 5,418B (5.3KB) | 423ms | 🟡 建议 |
| 7 | c2s_get_reward | 5,180B (5.1KB) | 511ms | 🟡 建议 |
| 8 | c2s_get_clover_clash | 4,950B (4.8KB) | 192ms | 🟡 建议 |
| 9 | c2s_get_clover_clash | 4,017B (3.9KB) | 147ms | 🟡 建议 |
| 10 | c2s_login | 3,875B (3.8KB) | 321ms | 🟡 建议 |
| 11 | c2s_get_login_bonus | 3,292B (3.2KB) | 393ms | 🟡 建议 |
| 12 | c2s_spin | 2,440B (2.4KB) | 330ms | 🟡 建议 |
| 13 | c2s_enter_room | 2,339B (2.3KB) | 733ms | 🟡 建议 |
| 14 | c2s_use_game_features | 2,257B (2.2KB) | 310ms | 🟡 建议 |
| 15 | c2s_use_game_features | 1,292B (1.3KB) | 317ms | 🟢 可选 |
| 16 | c2s_get_spin_mode_activity | 1,118B (1.1KB) | 118ms | 🟢 可选 |
| 17 | c2s_claim_special_activity_reward | 1,014B (1.0KB) | 331ms | 🟢 可选 |
| 18 | c2s_use_game_features | 767B | 353ms | ⚪ 不推荐 |
| 19 | c2s_ad_control | 747B | 388ms | ⚪ 不推荐 |
| 20 | c2s_use_game_features | 747B | 311ms | ⚪ 不推荐 |
| 21 | c2s_use_game_features | 744B | 342ms | ⚪ 不推荐 |
| 22 | c2s_use_game_features | 625B | 299ms | ⚪ 不推荐 |
| 23 | c2s_use_game_features | 615B | 376ms | ⚪ 不推荐 |
| 24 | c2s_get_daily_bonus | 614B | 273ms | ⚪ 不推荐 |
| 25 | c2s_use_game_features | 543B | 342ms | ⚪ 不推荐 |
| 26 | c2s_use_game_features | 471B | 318ms | ⚪ 不推荐 |
| 27 | c2s_update_prize_pool_players | 387B | 346ms | ⚪ 不推荐 |
| 28 | c2s_update_prize_pool_players | 381B | 305ms | ⚪ 不推荐 |
| 29 | c2s_update_prize_pool_players | 381B | 300ms | ⚪ 不推荐 |
| 30 | c2s_update_prize_pool_players | 381B | 378ms | ⚪ 不推荐 |
| 31 | c2s_update_prize_pool_players | 381B | 366ms | ⚪ 不推荐 |
| 32 | c2s_update_prize_pool_players | 369B | 403ms | ⚪ 不推荐 |
| 33 | c2s_update_prize_pool_players | 369B | 319ms | ⚪ 不推荐 |
| 34 | c2s_update_prize_pool_players | 369B | 306ms | ⚪ 不推荐 |
| 35 | c2s_update_prize_pool_players | 369B | 301ms | ⚪ 不推荐 |
| 36 | c2s_update_prize_pool_players | 368B | 338ms | ⚪ 不推荐 |
| 37 | c2s_update_prize_pool_players | 365B | 273ms | ⚪ 不推荐 |
| 38 | c2s_use_game_features | 342B | 339ms | ⚪ 不推荐 |
| 39 | c2s_get_timed_challenge | 315B | 4ms | ⚪ 不推荐 |
| 40 | c2s_use_game_features | 297B | 326ms | ⚪ 不推荐 |
| 41 | c2s_get_processing_purchase | 242B | 263ms | ⚪ 不推荐 |
| 42 | c2s_get_hourly_bonus | 194B | 189ms | ⚪ 不推荐 |
| 43 | c2s_use_game_features | 176B | 375ms | ⚪ 不推荐 |
| 44 | c2s_use_game_features | 174B | 294ms | ⚪ 不推荐 |
| 45 | c2s_use_game_features | 107B | 372ms | ⚪ 不推荐 |
| 46 | c2s_use_game_features | 95B | 318ms | ⚪ 不推荐 |
| 47 | c2s_get_operation_info | 87B | 4ms | ⚪ 不推荐 |
| 48 | c2s_get_operation_info | 86B | 129ms | ⚪ 不推荐 |
| 49 | c2s_get_open_activities | 57B | 349ms | ⚪ 不推荐 |
| 50 | c2s_get_open_activities | 56B | 315ms | ⚪ 不推荐 |
| 51 | c2s_get_system_message | 51B | 323ms | ⚪ 不推荐 |
| 52 | c2s_get_mails | 38B | 391ms | ⚪ 不推荐 |
| 53 | c2s_daily_shop_pop_up | 35B | 96ms | ⚪ 不推荐 |
| 54 | c2s_get_group_link | 32B | 246ms | ⚪ 不推荐 |
| 55 | c2s_get_smoke | 27B | 68ms | ⚪ 不推荐 |

### 按调用频率统计

| 协议名 | 调用次数 | 总数据量 | 平均大小 | 平均耗时 |
|-------|---------|---------|---------|---------|
| c2s_use_game_features | 14 | 9,251B | 661B | 328ms |
| c2s_update_prize_pool_players | 12 | 4,479B | 373B | 330ms |
| c2s_get_clover_clash | 2 | 8,967B | 4,484B | 170ms |
| c2s_get_game_features | 2 | 67,799B | 33,900B | 433ms |
| c2s_get_open_activities | 2 | 113B | 57B | 332ms |
| c2s_get_operation_info | 2 | 173B | 87B | 67ms |
| c2s_claim_special_activity_reward | 2 | 6,432B | 3,216B | 377ms |
| c2s_login | 1 | 3,875B | 3,875B | 321ms |
| c2s_get_subjects | 1 | 128,339B | 128,339B | 409ms |
| c2s_get_shops | 1 | 40,037B | 40,037B | 710ms |
| c2s_get_activities | 1 | 62,318B | 62,318B | 328ms |
| c2s_enter_room | 1 | 2,339B | 2,339B | 733ms |
| c2s_spin | 1 | 2,440B | 2,440B | 330ms |
| c2s_get_reward | 1 | 5,180B | 5,180B | 511ms |
| c2s_get_login_bonus | 1 | 3,292B | 3,292B | 393ms |
| c2s_get_daily_bonus | 1 | 614B | 614B | 273ms |
| c2s_get_hourly_bonus | 1 | 194B | 194B | 189ms |
| c2s_ad_control | 1 | 747B | 747B | 388ms |
| c2s_get_spin_mode_activity | 1 | 1,118B | 1,118B | 118ms |
| c2s_get_timed_challenge | 1 | 315B | 315B | 4ms |
| c2s_get_group_link | 1 | 32B | 32B | 246ms |
| c2s_daily_shop_pop_up | 1 | 35B | 35B | 96ms |
| c2s_get_processing_purchase | 1 | 242B | 242B | 263ms |
| c2s_get_system_message | 1 | 51B | 51B | 323ms |
| c2s_get_mails | 1 | 38B | 38B | 391ms |
| c2s_get_smoke | 1 | 27B | 27B | 68ms |

### 按耗时排序（降序）

| 排名 | 协议名 | 耗时 | 数据大小 | 备注 |
|-----|-------|------|---------|-----|
| 1 | c2s_enter_room | 733ms | 2,339B | 进房协议，涉及业务逻辑 |
| 2 | c2s_get_shops | 710ms | 40,037B | 数据量大 |
| 3 | c2s_get_game_features | 528ms | 42,492B | 数据量大 |
| 4 | c2s_get_reward | 511ms | 5,180B | 业务逻辑复杂 |
| 5 | c2s_claim_special_activity_reward | 423ms | 5,418B | 活动奖励 |
| 6 | c2s_get_subjects | 409ms | 128,339B | 数据量最大 |
| 7 | c2s_update_prize_pool_players | 403ms | 369B | 频繁调用 |
| 8 | c2s_get_login_bonus | 393ms | 3,292B | 登录奖励 |
| 9 | c2s_get_mails | 391ms | 38B | 网络延迟 |
| 10 | c2s_ad_control | 388ms | 747B | 广告控制 |

---

## 压缩收益预估

### 假设条件

- JSON 数据 gzip 压缩率约 85-95%（取 90% 计算）
- 解压耗时约 5-15ms（根据数据大小）
- JSON 解析耗时约 0-5ms

### 收益计算

| 协议名 | 原始大小 | 压缩后预估 | 节省流量 | 解压开销 | 净收益 |
|-------|---------|-----------|---------|---------|-------|
| c2s_get_subjects | 125.3KB | ~12.5KB | **112.8KB** | ~15ms | ✅ 高 |
| c2s_get_activities | 60.9KB | ~6.1KB | **54.8KB** | ~10ms | ✅ 高 |
| c2s_get_game_features | 41.5KB | ~4.2KB | **37.3KB** | ~8ms | ✅ 高 |
| c2s_get_shops | 39.1KB | ~3.9KB | **35.2KB** | ~8ms | ✅ 高 |
| c2s_get_game_features | 24.7KB | ~2.5KB | **22.2KB** | ~5ms | ✅ 高 |
| c2s_claim_special_activity_reward | 5.3KB | ~0.5KB | 4.8KB | ~3ms | ✅ 中 |
| c2s_get_reward | 5.1KB | ~0.5KB | 4.6KB | ~3ms | ✅ 中 |
| c2s_get_clover_clash | 4.8KB | ~0.5KB | 4.3KB | ~3ms | ✅ 中 |
| c2s_login | 3.8KB | ~0.4KB | 3.4KB | ~2ms | ✅ 中 |
| c2s_get_login_bonus | 3.2KB | ~0.3KB | 2.9KB | ~2ms | ✅ 中 |
| c2s_spin | 2.4KB | ~0.2KB | 2.2KB | ~2ms | ✅ 低 |
| c2s_enter_room | 2.3KB | ~0.2KB | 2.1KB | ~2ms | ✅ 低 |

### 单次登录总收益

| 指标 | 数值 |
|-----|-----|
| 原始数据总量 | 347,523B (339.4KB) |
| 可压缩数据量（≥2KB） | 329,556B (321.8KB) |
| 压缩后预估 | ~32KB |
| **节省流量** | **~290KB** |

---

## 压缩策略建议

### 建议阈值

```
响应数据 ≥ 2KB → 启用 gzip 压缩
响应数据 < 2KB → 不压缩
```

### 分级压缩策略

#### 🔴 第一优先级（强烈推荐）

立即启用压缩，收益最大：

| 协议 | 原因 |
|-----|-----|
| `c2s_get_subjects` | 128KB，单次节省超 100KB |
| `c2s_get_activities` | 62KB，活动数据重复性高 |
| `c2s_get_game_features` | 42KB，高频调用 |
| `c2s_get_shops` | 40KB，商店数据结构化 |

#### 🟡 第二优先级（建议）

收益中等，建议启用：

| 协议 | 原因 |
|-----|-----|
| `c2s_get_reward` | 5KB，登录必经 |
| `c2s_claim_special_activity_reward` | 5KB，活动奖励 |
| `c2s_get_clover_clash` | 5KB，活动数据 |
| `c2s_login` | 4KB，首次登录 |
| `c2s_get_login_bonus` | 3KB，登录奖励 |
| `c2s_spin` | 2.4KB，高频 |
| `c2s_enter_room` | 2.3KB，进房必经 |

#### 🟢 第三优先级（可选）

收益较小，视情况启用：

| 协议 | 原因 |
|-----|-----|
| `c2s_use_game_features` (>1KB) | 部分调用超过 1KB |
| `c2s_get_spin_mode_activity` | 1.1KB，边界值 |

#### ⚪ 不推荐压缩

数据量太小，压缩开销大于收益：

- 所有 < 1KB 的协议
- `c2s_update_prize_pool_players`（高频但数据小）
- `c2s_get_open_activities`、`c2s_get_operation_info` 等

---

## 实施建议

### 服务端配置

需要为以下协议启用 gzip 压缩响应：

```javascript
// 强烈推荐
"c2s_get_subjects"
"c2s_get_activities"
"c2s_get_game_features"
"c2s_get_shops"

// 建议
"c2s_get_reward"
"c2s_claim_special_activity_reward"
"c2s_get_clover_clash"
"c2s_login"
"c2s_get_login_bonus"
"c2s_spin"
"c2s_enter_room"
```

### 客户端配置

在对应协议类中设置 `openGzip = true`：

```javascript
// 示例：GetSubjectsProtocol.js
var GetSubjectsProtocol = function () {
    Protocol.call(this, "c2s_get_subjects");
    this.openGzip = true;  // 启用压缩
};
```

### 监控指标

启用压缩后，关注以下指标：

1. **压缩率**: 预期 85-95%
2. **解压耗时**: 预期 < 20ms
3. **总耗时变化**: 预期减少（节省传输时间 > 解压开销）
4. **内存占用**: 解压过程会临时占用内存

---

## 附录

### 数据采集环境

- 客户端版本: CV (Classic Vegas)
- 网络环境: 正常网络
- 采集时间: 2026-01-13
- 采集范围: 单次完整登录流程 + 进房 + Spin

### 相关文件

- `src/common/protocol/Protocol.js` - 协议基类
- `src/common/net/PomeloClient.js` - 网络层
- `node_modules/@me2zen/pomelo-jsclient-websocket/lib/pomelo-client.js` - Pomelo 客户端

---

**最后更新**: 2026-01-13
**维护者**: WTC Team
