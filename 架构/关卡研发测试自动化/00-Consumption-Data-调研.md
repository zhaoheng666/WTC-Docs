---
title: Consumption Data 调研
---

# Consumption Data 调研

> 源自飞书文档 · 最后同步：2026-09-11

## 一、摘要

- 主要用途：
- 在用户申请 App Store 退款时，向 Apple 提供商品交付与消费情况，辅助退款判断
- 接入位置
- 服务端、App Store Server Notifications、App Store Server API
- 是否建议现在接入
- 仅在已有 IAP 且希望参与退款判断时接入
## 二、详细介绍

### 2.1 它是什么

Apple 的 Consumption Data 不是普通的用户行为分析接口，也不是用来向 App 内展示“消费数据”的服务。

当用户针对 App 内购买发起退款请求时，Apple 向开发者服务端发送 `CONSUMPTION_REQUEST` 通知。开发者在取得用户有效同意后，可以把商品交付情况、消费比例等信息返回给 Apple，辅助 Apple 判断是否批准退款。[cite:47f4ab46-1]

支持的商品类型包括：

- 消耗型 IAP
- 非消耗型 IAP
- 非续期订阅
- 自动续期订阅
### 2.2 服务端流程

```
用户购买 IAP
      ↓
App Store Server Notifications V2
      ↓
服务端收到 CONSUMPTION_REQUEST
      ↓
判断用户是否已同意提供消费数据
      ↓
如果同意，准备 ConsumptionRequest
      ↓
调用 App Store Server API
      ↓
Apple 将消费信息作为退款判断因素之一
```

- **接口：**
```
PUT https://api.storekit.apple.com/inApps/v2/transactions/consumption/{transactionId}
```

- **沙盒接口：**
```
PUT https://api.storekit-sandbox.apple.com/inApps/v2/transactions/consumption/{transactionId}
```

该接口要求使用 App Store Server API 1.19 或更高版本。[cite:47f4ab46-1]

### 2.3 时间要求

收到 `CONSUMPTION_REQUEST` 通知后，需要在 12** **小时内响应。

如果用户没有同意提供消费数据，则不要调用该接口，也不要发送消费信息。[cite:47f4ab46-1][cite:47f4ab46-3]

因此，服务端需要具备：

- App Store Server Notifications V2 接收端点
- JWS 通知验签与解析
- `CONSUMPTION_REQUEST` 处理逻辑
- 12 小时内的任务调度或可靠重试机制
- App Store Server API JWT 鉴权
- 消费信息持久化和审计记录
### 2.4 `ConsumptionRequest` 字段

- **核心字段如下：**
`consumptionPercentage` 的取值范围是 `0` 到 `100000`，单位是千分之一百分点：

该字段可以精确到三位小数。[cite:47f4ab46-2][cite:47f4ab46-4]

示例：

```json
{
  "customerConsented": true,
  "deliveryStatus": "DELIVERED",
  "sampleContentProvided": true,
  "consumptionPercentage": 40000,
  "refundPreference": "GRANT_PRORATED"
}
```

- **注意：**
1. 如果商品没有成功交付，`consumptionPercentage` 必须为 `0`。
1. 自动续期订阅不能主动传 `consumptionPercentage`，Apple 会根据订阅经过的时间自动计算。
1. `GRANT_PRORATED` 通常需要消费比例大于 `0` 且小于 `100000`。
1. `customerConsented` 不为 `true` 时，Apple 会拒绝请求。[cite:47f4ab46-2][cite:47f4ab46-4]
### 2.5 用户同意与隐私合规

这是 Consumption Data 接入中最需要注意的部分。

Apple 明确要求：

- 开发者必须自行取得用户有效同意；
- 同意应当是自由、明确、具体、知情且无歧义的；
- 最好采用明确的 opt-in，而不是默认同意或仅提供 opt-out；
- 用户撤回同意后，不应继续发送该用户的数据；
- 不能使用 ATT 弹窗代替 Consumption Data 的独立授权；
- 如果采用该 API，需要更新 App Privacy 隐私标签，披露相关数据收集及用途。[cite:47f4ab46-1][cite:47f4ab46-3]
建议的授权文案方向：

为了协助 Apple 处理你的 App 内购买退款请求，我们可能会将本次购买的交付状态和使用情况提供给 Apple。你可以随时撤回授权。

具体文案、保存周期和撤回机制仍需根据实际业务地区及隐私政策评估，Apple 不替开发者提供法律意见。

### 2.6 对当前项目的建议

它的收益主要是：

- 在退款场景下给 Apple 提供更多判断信息；
- 降低“商品已完整消费但仍全额退款”的部分风险；
- 让 IAP 服务端链路更加完整。
但它同时增加：

- 用户授权流程；
- 隐私标签和隐私政策维护；
- App Store Server Notifications V2；
- JWT 鉴权；
- JWS 验签；
- 12 小时 SLA；
- 退款数据审计和重试逻辑。
