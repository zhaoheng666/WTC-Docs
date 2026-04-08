---
title: Codex CLI 配置
date: '2026-04-08 15:50:00'
head: []
outline: deep
sidebar: true
prev: true
next: true
---

### 一、安装 Codex CLI
```bash
npm install -g codex-cli
```

### 二、配置代理、模型
打开配置文件 `~/.codex/config.toml` 没有就创建一个
```bash
model_provider = "crs"
model = "gpt-5.3-codex"
model_reasoning_effort = "medium"
disable_response_storage = true
preferred_auth_method = "apikey"
personality = "pragmatic"

[model_providers.crs]
name = "crs"
base_url = "https://chatgpt-corp.ghoststudio.net/codex"
wire_api = "responses"
parameters = { reasoning_effort = "xhigh", max_thinking_tokens = 16384 }

[notice]
hide_full_access_warning = true

[notice.model_migrations]
"gpt-5.1-codex-mini" = "gpt-5.1-codex-mini"
"gpt-5.1-codex-max" = "gpt-5.1-codex-max"
"gpt-5.4" = "gpt-5.4"
"gpt-5.2-codex" = "gpt-5.2-codex"

```
 [ghoststudio 代理支持模型](./ghoststudio支持模型.md)  

### 三、配置 Auth Key
打开配置文件 `~/.codex/config.toml` 没有就创建一个
```bash
codex-cli config set auth-key cr_89cafa291bfbba447ae63c21c65db9be4344514c2d911acff77128adf70c54aa
```