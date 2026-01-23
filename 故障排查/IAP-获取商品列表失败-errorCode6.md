# IAP 获取商品列表失败 - errorCode:6

## 摘要

| | |
|-|-|
| **状态** | ✅ 已分析 |
| **日期** | 2026年1月23日 |
| **平台** | Android |
| **原文档** | [飞书文档](https://ghoststudio.feishu.cn/wiki/Cys4wzzuNijWaPknReKcNAN5nCb) |

---

## 问题现象

BI 日志中出现大量 `iap_error_code: 999` 的上报，错误信息格式如下：

```
get product list failed: { "errCode": 1, "errMsg": "{\"errorCode\":6}" } tryCnt: X
```

- **iap_error_code**: 999（JS 层自定义错误码，表示获取商品列表失败）
- **errorCode**: 6（来自 Google Play Billing Library）
- **tryCnt**: 重试次数（1-4）

---

## 错误码含义

### errorCode: 6 = `BillingResponseCode.ERROR`

| 字段 | 值 |
|-----|---|
| **错误码** | 6 |
| **常量名** | `BillingResponseCode.ERROR` |
| **含义** | **通用致命错误** - API 操作期间发生致命错误 |

这是 Google Play Billing Library 定义的错误码，表示与 Google Play 服务通信时发生了无法恢复的错误。

---

## Google Play Billing 错误码对照表

| 错误码 | 常量名 | 含义 |
|-------|-------|------|
| 0 | `OK` | 成功 |
| 1 | `USER_CANCELED` | 用户取消 |
| 2 | `SERVICE_UNAVAILABLE` | 网络连接断开 |
| 3 | `BILLING_UNAVAILABLE` | 设备不支持 Billing API |
| 4 | `ITEM_UNAVAILABLE` | 商品不可用 |
| 5 | `DEVELOPER_ERROR` | 开发者配置错误 |
| **6** | **`ERROR`** | **通用致命错误** |
| 7 | `ITEM_ALREADY_OWNED` | 商品已购买 |
| 8 | `ITEM_NOT_OWNED` | 商品未拥有 |

---

## 可能原因

1. **Google Play 应用问题**
   - Google Play 应用需要更新
   - Google Play 服务缓存异常

2. **设备网络问题**
   - 与 Google 服务器通信失败
   - 网络不稳定或被墙

3. **无效参数**
   - 传递给 billing flow 的参数无效
   - 有时会返回 `ERROR` 而非 `DEVELOPER_ERROR`

4. **Google 拒绝请求**
   - Google 后台服务异常
   - 账号或设备被限制

---

## 代码追踪

### JS 层 - 错误上报位置

`src/store/model/StoreMan.js:1644-1645`

```javascript
var msg = "get product list failed: " + jsonStr + " tryCnt: " + this._retryReqProductCnt;
LogMan.getInstance().logIAPErrorInfo(999, msg, "get product list failed");
```

### Java 层 - 错误产生位置

`libZenSDK/thirdparty/android/libPayGooglePlaySmall/src/com/zentertain/payment/ZenPaymentChannelGooglePlay.java:273-284`

```java
mBillingClient.queryProductDetailsAsync(params, new ProductDetailsResponseListener() {
    @Override
    public void onProductDetailsResponse(BillingResult billingResult, List<ProductDetails> skuDetailsList) {
        int responseCode = billingResult.getResponseCode();
        if(responseCode != BillingClient.BillingResponseCode.OK || skuDetailsList == null || skuDetailsList.size() == 0) {
            JSONObject object = new JSONObject();
            try {
                object.put("errorCode", responseCode);  // 这里返回了 errorCode: 6
            } catch (Exception exce) {
                exce.printStackTrace();
            }
            m_listener.onReceiveProducts(ZenPaymentResult.E_PAYMENT_FAILED, null, object.toString(), extraInfo);
        }
    }
});
```

---

## 建议处理

### 用户侧

1. **重启设备**后重试购买
2. **更新 Google Play**：Google Play > 设置 > 关于 > 点击"Play 商店版本"检查更新
3. **清除 Google Play 缓存**：设置 > 应用 > Google Play 商店 > 清除缓存
4. **检查网络连接**：确保网络稳定，尝试切换 WiFi/移动数据

### 开发侧

1. **增加重试机制**：当前已有重试（tryCnt），可考虑增加重试间隔
2. **添加详细日志**：记录更多设备信息（Google Play 版本、网络状态等）
3. **监控频率**：如果某些用户频繁出现此错误，可能是设备或账号问题

---

## 参考资料

- [BillingClient.BillingResponseCode - Android Developers](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.BillingResponseCode)
- [Handle BillingResult response codes - Android Developers](https://developer.android.com/google/play/billing/errors)
- [Google Play Billing SDK Error Codes](https://adapty.io/blog/google-play-billing-library-in-app-purchase-error-codes/)

---

*📅 最后更新: 2026/01/23*
