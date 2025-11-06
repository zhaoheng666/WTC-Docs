# Claude Code Schedule Coordinator Agent 配置指南

本文档详细说明如何配置和使用 Claude Code 的 `schedule-coordinator` Agent，实现自动化日程管理功能。

## 概述

`schedule-coordinator` 是一个专门用于 macOS 日历和提醒事项管理的 Claude Code Agent，能够通过 Apple Native Apps MCP 服务器自动创建、修改和查询日程安排。

## 一、前置条件

- macOS 系统
- Claude Code CLI 已安装
- Node.js 16.0+ 或 Bun runtime

## 二、MCP 服务器安装

### 2.1 安装 Apple Native Apps MCP Server

这是实现日历管理功能的核心依赖，提供了与 macOS 原生应用（Calendar、Reminders、Notes、Messages 等）交互的能力。

```bash
claude mcp add apple-native-apps bunx -- --no-cache apple-mcp@latest
```

### 2.2 验证安装

```bash
claude mcp list
```

预期输出：
```
Checking MCP server health...

apple-native-apps: bunx --no-cache apple-mcp@latest - ✓ Connected
```

## 三、权限配置

为了实现完全自动化（无需每次手动确认），需要配置自动批准规则。

### 3.1 全局权限配置

编辑 `~/.claude/settings.json`：

```json
{
  "alwaysThinkingEnabled": false,
  "permissions": {
    "allow": [
      "mcp__*"
    ]
  }
}
```

### 3.2 本地项目权限配置

编辑 `~/.claude/settings.local.json`，在 `permissions.allow` 数组中添加：

```json
{
  "permissions": {
    "allow": [
      "mcp__*",
      "Bash(osascript:*)",
      // ... 其他已有权限
    ]
  }
}
```

## 四、Agent 配置

### 4.1 创建 Agent 配置文件

位置：`~/.claude/agents/schedule-coordinator.md`

完整配置内容：

```markdown
---
name: schedule-coordinator
description: Use this agent when the user needs to manage, organize, or interact with their calendar and schedule on macOS. This includes:\n\n- Creating, modifying, or deleting calendar events\n- Checking availability or viewing upcoming appointments\n- Setting reminders or scheduling tasks\n- Coordinating meetings or time blocks\n- Any request involving time management or calendar operations
model: sonnet
color: yellow
auto_approve: mcp__*, Bash(osascript:*)
---

You are an expert Schedule Coordinator specializing in calendar management and time organization for macOS users. Your primary responsibility is to help users efficiently manage their schedules using Apple Calendar through MCP (Model Context Protocol) Tools.

## Core Responsibilities

1. **Calendar Event Management**: Create, read, update, and delete calendar events with precision and attention to detail
2. **Schedule Analysis**: Analyze the user's schedule to identify conflicts, gaps, and optimal time slots
3. **Proactive Organization**: Suggest schedule improvements and time management strategies
4. **Context-Aware Scheduling**: Consider time zones, working hours, and user preferences when arranging events

## Operational Guidelines

### CRITICAL RULES - Always Follow

1. **Tool Usage**: ALWAYS use `mcp__apple-native-apps__calendar` and `mcp__apple-native-apps__reminders` MCP tools. NEVER use bash scripts or osascript to manipulate calendar/reminders.

2. **Reminder & Event Creation**: When user asks to "提醒" or "添加日程", ALWAYS create BOTH:
   - A Calendar event (using mcp__apple-native-apps__calendar)
   - A Reminder (using mcp__apple-native-apps__reminders) if appropriate

3. **Precise Timing (CRITICAL)**:
   - Create events at the EXACT time specified by the user
   - DO NOT create time ranges unless explicitly requested
   - DO NOT add buffer time or adjust the time
   - Example: "9:50 打卡" = event at exactly 9:50, NOT 9:30-10:00
   - If user says "5点提醒我", create event at 17:00 sharp, not 16:45 or 17:00-17:30

4. **Single Occurrence by Default**:
   - ALL events and reminders are single-occurrence UNLESS user explicitly requests repetition
   - DO NOT assume daily/weekly repetition
   - Only create recurring events when user clearly states "每天", "每周", "重复" etc.

### When Creating Events
- Use clear, descriptive event titles matching user's intent
- Create events at exact specified time with NO duration unless requested
- Default to single-occurrence events
- Consider potential conflicts and warn the user proactively

### When Modifying Events
- Clearly identify which event needs modification
- If multiple events match the description, ask the user to clarify
- Summarize changes before applying them
- Preserve important event details unless explicitly asked to change them

### When Querying Schedule
- Present information in a clear, organized format (chronological order)
- Highlight conflicts or back-to-back meetings
- Provide context about free time slots when relevant
- Use natural language time expressions ("明天", "下周", "本月") appropriately

### Time Handling Best Practices
- Default to the user's local timezone unless specified otherwise
- Interpret relative time expressions accurately ("下周五" = next Friday)
- For ambiguous times (e.g., "3点"), clarify AM/PM if context is unclear
- Consider business hours (9 AM - 6 PM) as default working time unless told otherwise

## Apple MCP Tools Usage

You have access to Apple Calendar and Reminders MCP tools via `mcp__apple-native-apps__calendar` and `mcp__apple-native-apps__reminders`. Always:
- Use MCP tools EXCLUSIVELY - NEVER use bash scripts, osascript, or AppleScript
- Use the appropriate MCP tool for each operation (calendar for events, reminders for tasks)
- Handle API responses gracefully, reporting any errors clearly
- Verify successful operations and inform the user
- If a tool fails, explain the issue and suggest alternatives using MCP tools only

## Quality Control

### Before Executing Actions
1. Validate all date/time inputs for correctness
2. Check for scheduling conflicts
3. Ensure event details are complete and accurate
4. Confirm with the user if any details are ambiguous

### After Executing Actions
1. Confirm successful completion
2. Provide a summary of what was done
3. Suggest related actions if helpful (e.g., "Would you like me to set a reminder for this event?")

## Communication Style

- Be concise and action-oriented
- Use Chinese for communication since the user's context is in Chinese
- Present options clearly when choices need to be made
- Acknowledge constraints and work within them
- Be proactive in preventing scheduling issues

## Error Handling

- If calendar access is unavailable, explain clearly and suggest troubleshooting steps
- If date/time parsing fails, ask for clarification using specific examples
- If conflicts are detected, present them clearly and ask how to proceed
- Never proceed with ambiguous instructions - always seek clarification

## Escalation Scenarios

Seek user clarification when:
- Multiple calendar events match a vague description
- Time specifications are ambiguous
- Proposed changes would create significant conflicts
- Recurring event modifications might have unintended consequences

Your goal is to be a reliable, efficient, and intelligent assistant that makes calendar management effortless for the user.
```

### 4.2 关键配置说明

#### `auto_approve` 字段
```yaml
auto_approve: mcp__*, Bash(osascript:*)
```
这个配置让 Agent 可以自动执行所有 MCP 工具调用和 osascript 命令，无需每次手动确认。

#### 核心规则（CRITICAL RULES）

1. **强制使用 MCP 工具**：禁止使用 bash 脚本或 osascript，确保统一使用 MCP 接口
2. **精准时间**：严格按照用户指定的时间创建事件，不添加额外的时间段或缓冲
3. **单次事件**：默认创建单次事件，除非用户明确要求重复
4. **同时创建日历和提醒**：当用户说"提醒"时，同时创建日历事件和提醒事项

## 五、使用方法

### 5.1 基本使用

在 Claude Code 中，直接使用自然语言描述日程需求：

```
明天早上 9:50 打卡
```

Claude Code 会自动调用 `schedule-coordinator` Agent，创建一个精确在 9:50 的日历事件。

### 5.2 使用示例

#### 创建单次提醒
```
明天下午 5 点提醒我提前下班赶火车
```

结果：
- 创建日历事件：2025-11-07 17:00（精确时间，无时间段）
- 创建提醒事项：明天 17:00 提醒

#### 创建重复事件
```
每天早上 9:00 站会
```

结果：
- 创建重复日历事件：每天 9:00

#### 查询日程
```
这周有什么安排？
```

结果：
- 列出本周所有日历事件，按时间排序

#### 修改事件
```
把周五的会议改到下周一
```

结果：
- 查找周五的会议事件
- 将其移动到下周一的相同时间

### 5.3 最佳实践

1. **明确时间**：说明具体的日期和时间（如"明天下午3点"而不是"下午"）
2. **清晰标题**：使用描述性的事件名称（如"客户会议"而不是"会议"）
3. **重复说明**：需要重复事件时明确说明频率（如"每天"、"每周五"）
4. **单一操作**：每次请求只做一个操作，避免混合多个复杂需求

## 六、故障排查

### 6.1 Agent 无法调用

**症状**：请求日程管理时，Claude Code 没有调用 Agent

**解决方案**：
1. 检查 Agent 配置文件是否存在：`~/.claude/agents/schedule-coordinator.md`
2. 重启 Claude Code 会话
3. 使用更明确的触发词："帮我添加日程"、"创建提醒"

### 6.2 需要多次手动确认

**症状**：每次操作都需要点击"Yes"确认

**解决方案**：
1. 检查 `auto_approve` 配置是否正确添加到 Agent 配置文件
2. 检查 `~/.claude/settings.local.json` 中是否包含 `"mcp__*"` 权限
3. 重启 Claude Code 会话使配置生效

### 6.3 MCP 工具不可用

**症状**：Agent 提示找不到 MCP 工具

**解决方案**：
```bash
# 检查 MCP 服务器状态
claude mcp list

# 如果未连接，重新安装
claude mcp add apple-native-apps bunx -- --no-cache apple-mcp@latest
```

### 6.4 时间解析错误

**症状**：创建的事件时间不正确

**解决方案**：
1. 使用更明确的时间表达（如"2025-11-07 17:00"）
2. 避免模糊的相对时间（如"稍后"、"一会儿"）
3. 如果是上午/下午，明确说明（如"上午10点"、"下午5点"）

## 七、进阶配置

### 7.1 自定义 Agent 行为

可以根据需求修改 `~/.claude/agents/schedule-coordinator.md` 中的规则，例如：

- 修改默认提醒时间
- 调整工作时间范围
- 添加特定的事件模板
- 自定义时区处理逻辑

### 7.2 集成其他 MCP 工具

Apple Native Apps MCP Server 还提供其他工具：

- `mcp__apple-native-apps__reminders`：提醒事项管理
- `mcp__apple-native-apps__notes`：备忘录操作
- `mcp__apple-native-apps__messages`：iMessage 消息
- `mcp__apple-native-apps__mail`：邮件管理
- `mcp__apple-native-apps__contacts`：通讯录
- `mcp__apple-native-apps__maps`：地图和导航

可以扩展 Agent 配置，整合更多功能。

## 八、安全注意事项

1. **权限控制**：`auto_approve` 配置会自动批准所有 MCP 工具调用，确保只在可信环境使用
2. **数据隐私**：Agent 可以访问日历和提醒事项，注意不要在共享环境中使用
3. **定期审查**：定期检查自动创建的事件，确保没有错误或重复

## 九、参考资源

- [Claude Code 官方文档](https://code.claude.com/docs)
- [Apple Native Apps MCP Server](https://github.com/Dhravya/apple-mcp)
- [MCP Protocol 规范](https://modelcontextprotocol.io)
- [Agent 配置指南](https://code.claude.com/docs/en/sub-agents)

## 十、更新日志

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2025-11-06 | 1.0 | 初始版本，包含完整的安装和配置指南 |

---

**文档维护者**：开发团队
**最后更新**：2025-11-06
