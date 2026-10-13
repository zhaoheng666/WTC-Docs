---
title: Xcode 27 接入 AI 配置指南（Codex 代理 / DeepSeek Harness / MCP）
---

# Xcode 27 接入 AI 配置指南（Codex 代理 / DeepSeek Harness / MCP）

> 源自飞书文档 · 最后同步：2026-10-13

本文说明 Xcode 27 接入 AI 的三种方式，并附逐步配置截图。所有步骤均在 GhostStudio 代理下实测可用。

| 接入方式 | 用途 | 入口 |
| --- | --- | --- |
| Chat Provider（GhostStudio Codex 代理） | 对话问答，使用公司代理的 GPT 系列模型 | Settings → Intelligence → Chat → Add a Chat Provider… |
| Agent（Claude / Codex / DeepSeek Harness） | 推荐。自主调用 Xcode 工具，完成改代码、构建、排错等多步任务 | Settings → Intelligence → Agents → Add an Agent… |
| MCP | 让 Xcode 之外的 Agent（终端里的 Claude Code、Codex CLI）使用 Xcode 工具 | Settings → Intelligence → Model Context Protocol |

> **结论：日常开发优先用 Agent。**同样是“升级广告 SDK”，Chat 只给建议并反复要求用户提供文件；Agent 自主完成了升级、pod install、构建验证，并列出需要人决定的事项。详见第二章。

**验证环境：**Xcode 27.0（27A266a），macOS 26.6.2，2026-10-13。

---

---

## 一、配置

Xcode 27 的 AI 能力分两类：**Chat**（对话问答）和 **Agent**（自主执行任务）。两者都在 Settings → Intelligence 中配置，可同时启用，使用时在 New Conversation 菜单中切换。

### 1.1 Chat：GhostStudio Codex 代理

#### 1. 打开 Xcode 设置

菜单栏 Xcode → **Settings…**（快捷键 ⌘,）。

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-1.png)

#### 2. 进入 Intelligence，添加 Chat Provider

左侧选 **Intelligence**，滚动到 Chat 区，点右下角 **Add a Chat Provider…**。

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-2.png)

#### 3. 填写代理信息

在 Add a Model Provider 弹窗中按下表填写，然后点 Add。

| 字段 | 值 | 说明 |
| --- | --- | --- |
| 类型 | `Internet Hosted` | 代理在公网，不选 Locally Hosted |
| URL | `https://chatgpt-corp.ghoststudio.net/codex` | GhostStudio Codex 代理地址 |
| API Key | 你的 GhostStudio Codex 代理 Key | 向管理员申请，不要写进文档或代码仓库 |
| API Key Header | `x-api-key` | Key 放在这个请求头中发送 |
| Description | `Ghoststudio-Codex` | 显示名，可自定义 |

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-3.png)

添加成功后，Chat 列表中会出现 **Ghoststudio-Codex**（见 1.1 第 2 步截图底部）。

### 1.2 Agent：Claude / Codex / DeepSeek Harness

New Conversation 菜单中的 Antigravity、Claude Agent、Codex 旁边显示 **GET**，但它只是文字提示，点击后直接跳到设置页；设置页的 Agents 区也没有这几项，无法下载。推测是 Xcode 按地区或账号资格隐藏了内置 Agent。

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-4.png)

解决办法：通过 **Add an Agent…**，把 Claude、Codex、DeepSeek Harness 作为自定义 ACP Agent 加入。走 GhostStudio 代理，不需要 Anthropic / OpenAI 账号，效果与内置 Agent 相同。

#### 1. 添加自定义 Agent 的通用步骤

Settings → Intelligence → Agents 区，点 **Add an Agent…**。

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-5.png)

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-6.png)

| 字段 | 说明 |
| --- | --- |
| Name | 在 New Conversation 菜单中显示的名字 |
| Executable | Agent 程序的绝对路径。必须写成 /Users/<用户名>/…，不能用 ~ |
| Interpreter | node 的绝对路径。下面三个 Agent 都是 Node 脚本，必填 |
| Arguments | 启动参数，每个参数单独添加一条 |
| Environment Variables | 额外环境变量，在表单下方，需要向下滚动才能看到 |

> **为什么必须填 Interpreter：**这些程序靠 #!/usr/bin/env node 启动，而从 Dock 打开的 Xcode 只有系统最小 PATH，找不到 nvm 安装的 node。下文以 nvm 安装的 Node v22.20.0 为例，请按本机实际路径替换（可用 which node 查询）。

#### 2. 安装 Claude / Codex 的 ACP 适配器

Claude Code 和 Codex CLI 本身不支持 ACP，需要用官方 ACP 适配器包一层。在终端执行一次：

```bash
mkdir -p ~/.local/share/xcode-acp-agents && cd ~/.local/share/xcode-acp-agents
echo '{"private":true}' > package.json
npm install @agentclientprotocol/claude-agent-acp @agentclientprotocol/codex-acp

# 以后升级
cd ~/.local/share/xcode-acp-agents && npm update
```

- 旧包名 `@zed-industries/claude-agent-acp`、`@zed-industries/codex-acp` 已弃用，不要安装。
- Codex 适配器自带兼容版本的 Codex，不依赖本机已安装的 codex 命令。
#### 3. 添加 Claude Agent

| 字段 | 值 |
| --- | --- |
| Name | `Claude (GhostStudio)` |
| Executable | `/Users/<用户名>/.local/share/xcode-acp-agents/node_modules/@agentclientprotocol/claude-agent-acp/dist/index.js` |
| Interpreter | `/Users/<用户名>/.nvm/versions/node/v22.20.0/bin/node` |
| Arguments | 不填 |
| Environment Variables | 不填 |

代理和 Key 读取 `~/.claude/settings.json`，与终端里的 Claude Code 共用。尚未配置的同学参考：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://chatgpt-corp.ghoststudio.net/claudecode",
    "ANTHROPIC_AUTH_TOKEN": "<你的 GhostStudio ClaudeCode Key>"
  }
}
```

模型映射（ANTHROPIC_DEFAULT_OPUS_MODEL 等）按团队约定补充。

#### 4. 添加 Codex Agent

| 字段 | 值 |
| --- | --- |
| Name | `Codex (GhostStudio)` |
| Executable | `/Users/<用户名>/.local/share/xcode-acp-agents/node_modules/@agentclientprotocol/codex-acp/dist/index.js` |
| Interpreter | `/Users/<用户名>/.nvm/versions/node/v22.20.0/bin/node` |
| Arguments | 不填 |
| Environment Variables | `NO_BROWSER` = `1`（隐藏 ChatGPT 网页登录选项） |

Environment Variables 在表单下方，向下滚动后点 + 添加：

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-7.png)

代理读取 `~/.codex/config.toml`，Key 读取 `~/.codex/auth.json`，与终端里的 Codex CLI 共用。config.toml 参考：

```
openai_base_url = "https://chatgpt-corp.ghoststudio.net/codex"
model = "gpt-6-astra"
model_reasoning_effort = "xhigh"
wire_api = "responses"
```

Key 可用 `codex login --with-api-key`（从标准输入读取）写入。

#### 5. 添加 DeepSeek Harness Agent

DeepSeek Harness 自带 ACP 服务端，启动命令为 `dsh --profile acp`，不需要额外安装适配器。

| 字段 | 值 |
| --- | --- |
| Name | `DeepSeek Harness` |
| Executable | `/Users/<用户名>/.nvm/versions/node/v22.20.0/lib/node_modules/@deepseek-ai/dsh/lib/bin.js` |
| Interpreter | `/Users/<用户名>/.nvm/versions/node/v22.20.0/bin/node` |
| Arguments | `--profile`、`acp`（分两条添加） |

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-8.png)

ACP profile 默认只提供 DeepSeek 官方模型。要使用 GhostStudio 的 Claude 线路，编辑 `~/.dsh/profiles/acp/cordis.patch.yml`（节选）：

```yaml
- id: llm-pi-ai
  name: "@deepseek-ai/dsh-llm-pi-ai"
  config:
    providers:
      ghoststudio-claudecode:
        displayName: GhostStudio-ClaudeCode
        apiKeyEnv: GHOSTSTUDIO_CLAUDECODE_API_KEY   # 凭据引用名，不是密钥本身
        api: openai-completions
        baseURL: https://chatgpt-corp.ghoststudio.net/claudecode/v1
        streamIdleTimeoutMs: 900000
        compat:
          supportsReasoningEffort: true
        models:
          - id: claude-opus-5-5
            name: claude-opus-5-5
            input: [ text, image ]
            # …其余模型同 desktop profile
- id: agent-default-model
  name: "@deepseek-ai/dsh-agent-default-model"
  config:
    provider: ghoststudio-claudecode
    model: claude-opus-5-5
- id: acp                      # ACP 新会话的初始模型
  name: "@deepseek-ai/dsh-acp"
  config:
    provider: ghoststudio-claudecode
    model: claude-opus-5-5
```

- Key 不依赖环境变量：`apiKeyEnv` 只是引用名，DSH 会到 `~/.dsh/.credentials.yaml` 的 refs 中按这个名字取值。所有 profile 共用这个文件，所以 Xcode 以最小环境启动也能拿到 Key。
- 改动只对新启动的 DSH 进程生效：在 Xcode 中新建一个 DeepSeek Harness 对话；仍显示旧模型时重启 Xcode。
- 思考强度不能写在配置里，默认按线路设置；如 Xcode 界面提供选项，可在会话中调整。
#### 6. 配置注意事项

- Claude、Codex Agent 与终端里的 Claude Code、Codex CLI 共用配置，修改命令行配置会同时影响 Xcode。
- 升级 Node 后，所有 Agent 的 Interpreter 路径都要同步修改（DeepSeek Harness 的 Executable 也含 Node 版本号）。
- 自定义 Agent 的配置保存在 `~/Library/Developer/Xcode/CodingAssistant/ACP/` 下的 plist 文件中，可用于备份或排查。
---

## 二、使用

### 2.1 Chat 还是 Agent

使用 Chat 时，Coding Assistant 面板顶部会出现 “Switch to agents for a better experience” 提示：Xcode 27 把 Agent 作为与编码助手交互的主要方式。点 **Get Started with Agents** 只会打开 Intelligence 设置页，不会自动切换。

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-9.png)

Agent 与 Chat 的区别：

|  | Chat | Agent |
| --- | --- | --- |
| 工作方式 | 一问一答，基于检索结果给建议 | 自主多步执行：读写文件、执行命令、构建、看日志、修复问题 |
| Xcode 工具 | 只能搜索工程内容 | 自动获得 Xcode 的 xcode-tools 工具集（BuildProject、GetBuildLog、XcodeRead / XcodeWrite 等） |
| 实测：升级广告 SDK | 定位到 AppLovin MAX 13.0.1 后给出方案，未修改文件，要求用户提供 Podfile 等文件 | 升级 AppLovin 及 5 个广告适配器、执行 pod install、修改工程配置、调用 BuildProject 验证，并列出需人工决定的事项 |
| 适合 | 问答、查方案、解释代码 | 改代码、升级依赖、修编译错误等多步任务 |
| 接入方式 | Add a Chat Provider（需兼容 Chat Completions 接口） | Add an Agent（需支持 Agent Client Protocol，即 ACP） |

Chat 适合问答、查方案、解释代码；改代码、升级依赖、修编译错误等需要动手并验证的任务，用 Agent。

### 2.2 使用 Chat

#### 1. 新建对话并选择模型

按 **⌘0** 打开 Coding Assistant 面板，点 **New Conversation ▾**，在 Chat 分组下选 **Ghoststudio-Codex**，再选择模型。

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-10.png)

- 编码任务建议选 **GPT-6 Sol**、**GPT-6.1 Sol**、**GPT-6 Astra** 或 GPT-5.6 系列。
- 下拉列表是代理返回的全部模型，其中包含 GPT Image、gpt-4o-audio-preview、gpt-4o-realtime-preview 等非对话模型，不要选这些做编码对话。
#### 2. 示例：升级广告 SDK

下图在 OldVegasCasino 工程中用 GPT-6 Sol 下达 “升级广告 sdk，但不要提交”。模型先检索工程中的 Podfile、Podfile.lock、ALSdk 等文件（图中 “5 Results”），确认使用 CocoaPods 集成 AppLovin MAX 后给出升级方案，但没有动手修改，并反复要求用户提供 Podfile 等文件。

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-11.png)

### 2.3 使用 Agent

#### 1. 新建对话

按 **⌘0** 打开 Coding Assistant → **New Conversation ▾** → Agents 分组，选择 Claude (GhostStudio)、Codex (GhostStudio) 或 DeepSeek Harness。输入框的占位文字会显示当前使用的 Agent。

- Xcode 会把自己的 xcode-tools 工具集自动交给自定义 Agent，无需额外配置。实测 DeepSeek Harness 会话中调用了 `BuildProject` 构建工程，Claude 会话中也能看到 xcode-tools 工具。
- 下达任务时写清约束和验收标准，例如 “升级广告 SDK，构建通过为止，不要提交”。Agent 会自己找文件、改配置、构建、读日志，遇到需要决策的地方会停下来询问。
- Agent 会直接修改工程文件。完成后用 git diff 审查改动；也可以在对话历史中回滚。
- Claude Agent 默认模式为 acceptEdits，改文件不会弹窗确认；想先审再改，可在会话中切换模式。
#### 2. 各 Agent 的默认设置

- **Claude (GhostStudio)：**实测默认模型为 opus（实际调用 claude-opus-5），思考强度 high，可在会话中切换。
- **Codex (GhostStudio)：**实测默认模型为 gpt-6-astra、思考强度 xhigh，会话中可切换 gpt-6.1-sol 及 low 到 ultra 各档思考强度。
- **DeepSeek Harness：**默认模型 claude-opus-5-5（由 acp profile 配置决定）。只实现标准 ACP v1 自动化接口：没有斜杠命令、plan 模式和终端，也不读写客户端文件系统；权限请求以弹窗形式交给 Xcode 处理。
下图中 Claude Agent 自动识别了工程目录、分支和未提交的改动：

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-12.png)

#### 3. 示例：升级广告 SDK

下图是 DeepSeek Harness Agent 执行同一个 “升级广告 sdk，但不要提交” 任务的结果：AppLovinSDK 13.0.1 → 13.6.4，5 个适配器同步升级，改动全部未提交。构建被与本次无关的旧代码问题阻断（libZenSDK 引用了 Xcode 27 不再允许的私有头文件），Agent 如实说明，并把 “最低 iOS 版本需从 12.0 提到 15.0” 列为需要人决定的事项。

![](/feishu/Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/00-Xcode-27-接入-AI-配置指南Codex-代理-DeepSeek-Harness-MCP/img-13.png)

---

## 三、让 Xcode 外的 Agent 使用 Xcode 工具（MCP）

在 Xcode 内添加的 Agent 会自动获得 Xcode 工具，无需本节配置。本节用于让终端里的 Claude Code、Codex CLI 等外部 Agent 通过 Xcode 内置的 MCP 服务（`xcrun mcpbridge`，实测提供 53 个工具）构建、跑测试、渲染 Preview、改 Build Settings。

### 3.1 打开开关

Settings → Intelligence → Model Context Protocol，把 **Allow External Agents to Use Xcode Tools** 设为 Always（见 1.2 第 1 步的第一张截图）。

### 3.2 注册 MCP

```bash
# Claude Code（-s user 表示所有目录可用）
claude mcp add -s user --transport stdio xcode -- xcrun mcpbridge

# Codex CLI
codex mcp add xcode -- xcrun mcpbridge

# 检查
claude mcp list
codex mcp list
```

- 给 Agent 下指令前，先在 Xcode 中打开对应工程；Agent 连接时 Xcode 会弹出提示。
- 同时开了多个 Xcode 时，用 `MCP_XCODE_PID=<pid> xcrun mcpbridge` 指定连接哪一个。
- 注册后，1.2 节的 Claude、Codex Agent 也会加载这份配置（与命令行共用）；Xcode 内本来已有 xcode-tools，如出现重复工具，可只在终端使用时再注册。
### 3.3 常用工具

| 工具 | 用途 |
| --- | --- |
| `BuildProject` | 构建工程并等待完成 |
| `GetBuildLog` | 读取最近一次构建日志，定位编译错误 |
| `RunAllTests` / `RunSomeTests` | 运行全部或指定测试 |
| `RenderPreview` | 构建并渲染 SwiftUI Preview 截图 |
| `UpdateTargetBuildSetting` | 修改 Target 的 Build Settings |
| `GetCrashIssueLogs` | 获取线上崩溃日志与分析建议 |
| `InvokeDebuggerCommand` | 在当前调试会话中执行 lldb 命令 |
| `XcodeRead` / `XcodeUpdate` / `XcodeWrite` | 按工程结构读写文件 |

游戏项目场景：Unity / Cocos 导出 iOS 工程后，可让 Agent 用 BuildProject + GetBuildLog 修编译错误，用 UpdateTargetBuildSetting 调签名和编译选项。

---

## 四、常见问题

| 现象 | 处理 |
| --- | --- |
| Claude Agent / Codex 旁的 GET 点了只跳到设置页，设置页里也没有 | 内置 Agent 被隐藏，按 1.2 节以自定义 ACP Agent 接入 |
| 自定义 Agent 启动失败，提示找不到 node | Interpreter 填 node 的绝对路径 |
| 升级 Node 后 Agent 无法启动 | 更新 Interpreter（以及 DeepSeek Harness 的 Executable）中的版本号路径 |
| Codex Agent 要求登录 ChatGPT | 确认已设置环境变量 NO_BROWSER=1，且 ~/.codex/auth.json 中已有 Key |
| Claude Agent 没有确认就改了文件 | 默认模式为 acceptEdits，可在会话中切换为需要确认的模式 |
| DeepSeek Harness 仍显示旧模型 | 新建对话；仍不行则重启 Xcode |
| `xcrun mcpbridge run-agent claude` 报 Could not find 'claude' binary | 该命令依赖内置 Agent，改用 1.2 节的自定义 Agent 或第三章的 MCP 注册方式 |
| Chat 下拉里模型很多，不知道选哪个 | 编码选 GPT-6 Sol / GPT-6.1 Sol / GPT-5.6 系列，避开 Image、audio、realtime 模型 |

---

## 参考资料

- [Setting up coding intelligence](https://developer.apple.com/documentation/xcode/setting-up-coding-intelligence)
- [Writing code with intelligence in Xcode](https://developer.apple.com/documentation/xcode/writing-code-with-intelligence-in-xcode)
- [Giving external agents access to Xcode](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode)
- [Extending and customizing agents](https://developer.apple.com/documentation/xcode/extending-and-customizing-agents)
- [Agent Client Protocol](https://agentclientprotocol.com)
- [claude-agent-acp（npm）](https://www.npmjs.com/package/@agentclientprotocol/claude-agent-acp)
- [codex-acp（npm）](https://www.npmjs.com/package/@agentclientprotocol/codex-acp)
