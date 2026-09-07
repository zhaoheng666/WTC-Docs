# AppCharge Coupon 支付时序

> 交互式时序图：三阶段（Inbox 领券进入 / OTP 验证 / 购买并返回游戏），可按 `P` 播放故事、`T` 切主题、`E` 导出。
> [全屏打开 ↗](/WTC-Docs/diagrams/WorldTourCasino-AppCharge-Coupon-flow.archify.html){target="_blank"}
>
> 完整流程（OTP 登录入口）见：[AppCharge OTP 支付时序](/架构/AppCharge-OTP-支付时序)

<iframe src="/WTC-Docs/diagrams/WorldTourCasino-AppCharge-Coupon-flow.archify.html" style="width:100%;height:82vh;border:1px solid var(--vp-c-divider);border-radius:8px;" title="AppCharge Coupon 支付时序"></iframe>

## 图注

- 入口差异（对比完整流程）：省去 OTP 登录页 `/login` 与 deeplink 首跳，Inbox 的 Coupon 直接触发 `C2SGetOTPCode`；OTP 阶段经 `/appcharge/otp-deeplink` 换取 deeplink + accessToken
- 鉴权：proofKey（playerCode）由游戏服务器随 `S2CGetOTPCode` 签发；AppCharge 经 `/appCharge/report` 回调校验 playerCode + token
- 关键地址：deeplink `slots-cdn-resource.me2zengame.com/deeplink/open.html?path=appsource&opentype=otp`；商城 `ghoststudio-classic-vegas-slots-store.me2zengame.com`

## 图源

- 规格：[`WorldTourCasino-AppCharge-Coupon-flow.archify.json`](https://github.com/zhaoheng666/WTC-Docs/blob/main/WorldTourCasino-AppCharge-Coupon-flow.archify.json)（Archify sequence schema）
- 历史版本：`WorldTourCasino-AppCharge-Coupon-flow.drawio` / `.png` / `.svg`（仓库根目录）
