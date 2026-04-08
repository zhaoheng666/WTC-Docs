---
title: ghoststudio 代理支持模型
date: '2026-04-08 15:50:00'
head: []
outline: deep
sidebar: true
prev: true
next: true
---

## 支持的模型

接入 `chatgpt-corp.ghoststudio.net` 的任何客户端配置，都需要使用代理服务器支持的模型 ID。

支持的模型取决于代理服务器当前采购和部署的模型，后续可能变化。

### GhostStudio 通用查询命令

```bash
curl -s https://chatgpt-corp.ghoststudio.net/v1/models \
  -H "Authorization: Bearer <YOUR_API_KEY>"
```

![代理服务器支持模型示例](/assets/image-20260302135652-rpsu18c.png)
