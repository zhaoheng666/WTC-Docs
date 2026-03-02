---
title: OpenCode 模型配置
date: '2026-03-02 11:52:37'
head: []
outline: deep
sidebar: false
prev: false
next: false
---





### 一、Claude Code + Codex 配置：

```config
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "anthropic": {
      "npm": "@ai-sdk/anthropic",
      "options": {
        "baseURL": "https://chatgpt-corp.ghoststudio.net/v1",
        "apiKey": "sk-au3fWPoVtB54KSwm0356F35915464dD1Bd56120d02A842D2"
      },
      "models": {
        "claude-opus-4-5-20251101": {
          "name": "[GS] Claude Opus 4.5"
        },
        "claude-sonnet-4-5-20250929": {
          "name": "[GS] Claude Sonnet 4.5"
        },
        "claude-haiku-4-5-20251001": {
          "name": "[GS] Claude Haiku 4.5"
        },
        "claude-opus-4-6": {
          "name": "[GS] Claude Opus 4.6"
        }
      }
    },
    "ghoststudio-codex": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Codex (GhostStudio)",
      "options": {
        "baseURL": "https://chatgpt-corp.ghoststudio.net/v1",
        "apiKey": "sk-au3fWPoVtB54KSwm0356F35915464dD1Bd56120d02A842D2"
      },
      "models": {
        "gpt-5.2-codex": {
          "name": "GPT-5.2 Codex"
        },
        "gpt-5.1-codex-max": {
          "name": "GPT-5.1 Codex Max"
        },
        "gpt-5.1-codex-mini": {
          "name": "GPT-5.1 Codex Mini"
        },
        "gpt-5.3-codex": {
          "name": "GPT-5.3 Codex"
        }
      }
    }
  }
}
```

### 二、使用方法：

- #### 安装 opencode：

  推荐使用官方 [opencode 桌面应用程序](https://github.com/anomalyco/opencode/blob/dev/README.zh.md)；
- #### 添加配置：

  找到配置文件/Users/ghost/.config/opencode/opencode.json，没有的话手动创建一个；

  将上边的配置粘贴进去；
- #### 重启 opencode 客户端
- #### 勾选模型：

  ![image](/assets/image-20260302155332-jdkq2xy.png)

  ![image](/assets/image-20260302152943-0ja28sf.png)![image](/assets/image-20260302155254-m56ph3f.png)

  找到 anthropic 、ghoststudio-codex 分组，勾选[GS]开头、自己需要的模型；

### 三、配置说明：

- #### provider 分组：（anthropic + ghoststudio-codex）

  避免模型列表与 provider 官方模型列表混合，模型名重复难以区分；

  anthropic 必须
- #### SDK：

  - anthropic 需要使用官方`"npm": "@ai-sdk/anthropic"`，否则无法选择推理强度
  - codex 没有推理选择功能，使用`"npm": "@ai-sdk/openai-compatible"`，使用兼容 sdk

- #### 支持的模型：

  opencode 配置中，必须使用我们代理服务器支持的模型 id；

  支持的模型取决于，我们的代理服务器采购部署了哪些模型（未来可能会有变化）；

  查看代理服务器支持模型：

  ​`curl -s https://chatgpt-corp.ghoststudio.net/v1/models \ -H "Authorization: Bearer sk-au3fWPoVtB54KSwm0356F35915464dD1Bd56120d02A842D2"`

  ![image](/assets/image-20260302135652-rpsu18c.png)

‍
