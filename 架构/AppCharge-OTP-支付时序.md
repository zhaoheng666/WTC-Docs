# AppCharge OTP 登录与购买返回时序

> 完整流程（OTP 登录入口）：三阶段（进入商城并 OTP 登录 / 游戏内 OTP 验证 / 购买并返回游戏），可按 `P` 播放故事、`T` 切主题、`E` 导出。
> [全屏打开 ↗](/WTC-Docs/diagrams/WorldTourCasino-AppCharge-flow.archify.html){target="_blank"}
>
> 简化入口变体见：[AppCharge Coupon 支付时序](/架构/AppCharge-Coupon-支付时序)

<iframe src="/WTC-Docs/diagrams/WorldTourCasino-AppCharge-flow.archify.html" style="width:100%;height:82vh;border:1px solid var(--vp-c-divider);border-radius:8px;" title="AppCharge OTP 登录与购买返回时序"></iframe>

## 图注

- 阶段 1：从 AppCharge Domain 进入 → OTP 登录页 `/login` → AppCharge 经 `/appcharge/otp-deeplink` 回调游戏服务器换取 deeplink + accessToken → 按设备类型重定向回游戏（web CDN / APP 启动链接）
- 阶段 2：游戏内 `C2SGetOTPCode` 取 proofKey → 浏览器打开 `/login/otp?proofKey=xxx` → AppCharge 经 `/appCharge/report` 回调校验 playerCode + token → 验证页跳转商城主页
- 阶段 3：付款完成 → back to game → deeplink 服务重定向回游戏
- 关键地址：deeplink `slots-cdn-resource.me2zengame.com/deeplink/open.html?path=appsource&opentype=otp`；商城 `ghoststudio-classic-vegas-slots-store.me2zengame.com`

## 图源

- 规格：[`WorldTourCasino-AppCharge-flow.archify.json`](https://github.com/zhaoheng666/WTC-Docs/blob/main/WorldTourCasino-AppCharge-flow.archify.json)（Archify sequence schema）
- 历史版本：`WorldTourCasino-AppCharge-flow.drawio` / `.png` / `.svg`（仓库根目录）
