---
title: Google OAuth 品牌验证记录（Classic Vegas）
---

# Google OAuth 品牌验证记录（Classic Vegas）

> 源自飞书文档 · 最后同步：2026-09-16

## Google OAuth 品牌验证记录

> 本文为该事项的主记录（2026-09-16）。首页修复对应 WTC-Web 提交 8315f9a；文中截图已直接上传至本文档。

本文记录 Classic Vegas（CV）的 Google Auth Platform 品牌验证最终状态和复核要点。 品牌验证管理 Google OAuth 授权页所展示的品牌信息；它不改变 Firebase Authentication 的登录流程或 Firebase App 实例名称。

### 触发背景

2026-09 Google Developers 发送自动邮件 `[Action required] Complete OAuth Brand Verification for your Google Cloud projects`， 点名 `classicvegas-41d2f` 缺少 OAuth 品牌配置且未验证，要求在 **2026-12-14** 前完成。 逾期且项目保持 production 状态的后果：该项目在 Cloud Console 上被限制修改其他 OAuth 配置（数据访问、客户端等）；用户登录时可能看到「此应用未经 Google 验证」提示。 不影响已配置的 Google 登录继续工作。

![](/feishu/Google-OAuth-品牌验证记录Classic-Vegas/00-Google-OAuth-品牌验证记录Classic-Vegas/img-1.png)

### CV 当前状态

- Firebase / Google Cloud 项目：`classicvegas-41d2f`
- 品牌验证：已通过，2026-09-16
- 目标对象：正式版 + 外部
- 当前基础 scope：`openid`、`email`、`profile`
![](/feishu/Google-OAuth-品牌验证记录Classic-Vegas/00-Google-OAuth-品牌验证记录Classic-Vegas/img-2.png)

### 已验证的品牌配置

Google Auth Platform → 品牌塑造中的配置如下，修改时须一并复核：

| 字段 | 当前值 |
| --- | --- |
| 应用名称 | `Classic Vegas Casino` |
| 用户支持电子邮件 | `heng.zhao@ghoststudio.net` |
| 应用徽标 | 与 `Classic Vegas Casino` 名称一致的正式 Classic Vegas Casino logo；`120×120` 像素 PNG 或 JPG |
| 应用首页 | `https://classicvegas.ghoststudio.net/` |
| 隐私权政策 | `https://www.ghoststudio.net/en/legal/PrivacyPolicy` |
| 服务条款 | `https://www.ghoststudio.net/en/legal/TermsofService` |
| 已获授权的网域 | `ghoststudio.net` |

应用名称与产品配置中的 `PRODUCTS.cv.displayName` 保持一致。首页、隐私政策与服务 条款均可在未登录状态下公开访问，且 `ghoststudio.net` 已完成域名所有权验证。

徽标必须是能唯一识别 `Classic Vegas Casino` 的正式品牌标识，而不是通用的老虎机图案 或带有临时年份的图案。上传前确认图片为正方形 `120×120` 像素、格式为 PNG 或 JPG， 并让图片中可见的品牌名称与「应用名称」字段逐字一致。

### 处理过程与重试记录

品牌验证分自动扫描与人工复核两层。整个过程共被驳回三次，最终通过；每次驳回的 问题、原因和处置如下。

#### 驳回 1：应用名称与首页不一致

配置：应用名称 `Classic Vegas Casino`，正式 Classic Vegas Casino logo。

审核反馈只有一条：「OAuth 授权页配置的应用名称 "Classic Vegas Casino" 与首页上的 应用名称不一致」。

原因：修复前的首页是纯 SPA，应用名称只存在于 `<title>` 和 logo 图片里，页面正文没有 任何文本形式的应用名，自动扫描无法匹配。

![](/feishu/Google-OAuth-品牌验证记录Classic-Vegas/00-Google-OAuth-品牌验证记录Classic-Vegas/img-3.png)

修复前的首页（仅 logo 图、登录按钮和页脚法务链接，无应用名文本）：

![](/feishu/Google-OAuth-品牌验证记录Classic-Vegas/00-Google-OAuth-品牌验证记录Classic-Vegas/img-4.png)

#### 驳回 2：三条问题同时出现

配置不变，在正式站尚未更新的情况下选择「我已解决相关问题」重新提交。

审核反馈变为三条：「首页在登录页面之后显示」「首页未说明应用的用途」「应用名称与 首页不一致」。

原因：三条均为自动扫描对 SPA 的典型判定——页面可读文本只有几个 "Sign in with ..." 按钮，就会同时命中「只是登录页」「无功能描述」「无名称」。 此时提交 `8315f9a` 尚未部署到正式站（或 CloudFront 仍在返回旧构建），扫描到的仍是 修复前的页面，所以问题不减反增。

![](/feishu/Google-OAuth-品牌验证记录Classic-Vegas/00-Google-OAuth-品牌验证记录Classic-Vegas/img-5.png)

#### 驳回 3：更换名称与徽标的尝试

中途尝试把应用名称改为 `Slots™ - Classic Vegas Casino`，并换用通用的 "SLOTS 777 Vegas" 图案作为徽标。

审核反馈：「应用名称 "Slots™ - Classic Vegas Casino" 与首页上的应用名称不一致」 「您的徽标无法唯一标识您的品牌和身份」。

原因：名称加了前缀后与首页/产品配置的 `Classic Vegas Casino` 不再逐字一致；通用 老虎机图案不含品牌名，无法唯一识别品牌。这次尝试证实了两条硬性规则：应用名称 必须与首页文本逐字一致，徽标必须是能唯一识别品牌的正式标识。

处置：名称改回 `Classic Vegas Casino`，徽标改回正式 Classic Vegas Casino logo （`120×120` PNG）。

![](/feishu/Google-OAuth-品牌验证记录Classic-Vegas/00-Google-OAuth-品牌验证记录Classic-Vegas/img-6.png)

#### 最终通过：多次重试的说明

配置恢复为「已验证的品牌配置」一节中的值，`8315f9a` 部署到正式站并确认页脚显示 `Classic Vegas Casino © 2026 GHOST STUDIO. All rights reserved.` 后，在「品牌验证 问题」对话框中反复选择「我已解决相关问题」重新提交。前几次提交后控制台仍显示 上一轮的历史问题，再提交数次后状态变为「您的品牌已经过验证，正在向用户显示」。

需要多次重试的原因：

- 对话框展示的是**上一次**审核发现的问题，不是对当前配置的实时判定；配置已改对但历史问题文本仍会显示，容易误判为「没解决」。
- 每次提交触发一次新的扫描，扫描抓取的是当时正式站返回的内容；CloudFront 缓存或部署延迟会导致早期几次扫描仍拿到旧构建。
- 部分提交可能进入人工复核队列，结果不会即时反馈。
因此重试的正确姿势是：先用「首页发布核验」一节的命令确认正式站已是新构建，再 提交；提交后若历史问题仍在，等待一段时间再看验证状态，不要立刻改配置。 「我认为发现的问题不正确」申诉入口在本次过程中未使用。

### Firebase handler 参数边界

Firebase Auth 发起 Google 登录时会访问同源 helper，例如：

```
https://classicvegas.ghoststudio.net/__/auth/handler?...&appName=%5BDEFAULT%5D&...
```

其中 `appName=[DEFAULT]` 是 Firebase JavaScript SDK 为未显式命名的 Firebase App 使用的内部实例标识。它由 `initializeApp(CONFIG.firebase)` 产生，用于让 helper 定位 当前 Firebase App；不是 Google OAuth 授权页显示给用户的应用名称，也不是 Google Auth Platform「品牌塑造」中的应用名称字段。因此不要修改它，也不要将它与 `Classic Vegas Casino` 对齐。

### 首页发布核验

提交 `8315f9a` 已让静态首页产物包含 `Classic Vegas Casino` 的浏览器/PWA/分享元数据， 并在登录前页脚显示该名称。该版本已部署并完成品牌验证。

发布或复核时可直接检查：

```bash
curl -fsSL https://classicvegas.ghoststudio.net/ | \
  rg 'application-name|og:site_name|og:title|<title>'
curl -fsSL https://classicvegas.ghoststudio.net/assets/cv/manifest.webmanifest | jq -r '.name, .short_name'
```

上述结果都应为 `Classic Vegas Casino`。这些检查用于确认已发布的静态产物与产品配置 一致；不应据此推断 Google 审核的单一内部判定机制。

### 重新提交与后续变更

品牌配置变更后，在 Google Auth Platform 的「品牌验证问题」中选择 「我已解决相关问题」并重新提交。若控制台仍显示上一次审核的历史问题，先确认品牌 验证状态与当前已发布首页，再等待审核结果或按控制台入口发起申诉；历史问题文本本身 不等于当前配置仍然错误。

以下变更应重新核对本页的字段并按控制台要求重新验证：应用名称、徽标（名称一致性、 `120×120`、PNG/JPG）、首页、隐私政策、服务条款、授权域名，以及新增敏感或受限 scope。

### 参考

- [App Homepage](https://support.google.com/cloud/answer/13807376)
- [Verification requirements](https://support.google.com/cloud/answer/13464321)
- [OAuth 2.0 Policies](https://developers.google.com/identity/protocols/oauth2/policies)
