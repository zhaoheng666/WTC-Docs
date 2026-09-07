# 架构图

交互式技术图表（Archify 生成，自包含 HTML：支持深浅主题切换、引导视图、路径追踪、PNG/SVG 导出）。

| 图表 | 说明 |
| --- | --- |
| [客户端架构总览](/架构/客户端架构总览) | 运行链路 / 构建发布 / 服务端与第三方 |
| [AppCharge OTP 支付时序](/架构/AppCharge-OTP-支付时序) | 完整流程：商城 OTP 登录 → 游戏内验证 → 购买返回 |
| [AppCharge Coupon 支付时序](/架构/AppCharge-Coupon-支付时序) | 简化入口：游戏内 Inbox 领券 → OTP 验证 → 购买返回 |

## 维护方式

- 图源规格：仓库根目录 `WorldTourCasino-*.archify.json`（与 `.drawio` 图源同级）
- 展示产物：`public/diagrams/*.archify.html`
- 修改流程：编辑 JSON → 用 Archify skill `deliver` 重新生成 HTML 覆盖产物（校验器会把关布局与可读性）
