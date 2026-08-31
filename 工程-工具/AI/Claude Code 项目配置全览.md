# Claude Code 项目配置全览

本文档说明 WorldTourCasino 项目中所有 Claude Code 相关文件的用途、层级关系和使用方式，帮助新人快速理解和上手。

---

## 目录结构总览

```
WorldTourCasino/
├── CLAUDE.md                          # 项目级 AI 上下文（核心）
└── .claude/                           # Claude Code 配置根目录
    ├── settings.json                  # 项目级设置（插件开关等）
    ├── settings.local.json            # 本地设置（不提交，个人权限）
    ├── plugins.json                   # 插件注册表（自动生成）
    ├── .vscode/
    │   └── settings.json             # Claude 内嵌 VSCode 配色
    ├── commands/                      # 斜杠命令（用户手动调用）
    │   ├── openspec-archive-checklist.md
    │   └── openspec/
    │       ├── proposal.md           # /openspec:proposal
    │       ├── apply.md              # /openspec:apply
    │       └── archive.md            # /openspec:archive
    └── skills/                        # 技能（自动/手动触发）
        ├── git-commit/               # 项目自建 - Git 提交流程
        ├── code-review/              # 项目自建 - 代码审查
        ├── card-system-season-update/ # 项目自建 - 收集系统赛季更新
        ├── docs-to-google-drive/     # 项目自建 - 文档上传 Google Drive
        ├── feishu-to-docs/           # 项目自建 - 飞书文档转换
        ├── git-branch-archive/       # 项目自建 - 分支归档
        ├── baoyu-post-to-wechat/     # 外部安装 - 微信公众号发布
        ├── docx/                     # 外部安装 - Word 文档处理
        ├── pdf/                      # 外部安装 - PDF 处理
        ├── pptx/                     # 外部安装 - PPT 处理
        ├── xlsx/                     # 外部安装 - Excel 处理
        ├── frontend-design/          # 外部安装 - 前端界面设计
        ├── mcp-builder/              # 外部安装 - MCP 服务器构建
        └── skill-writer/             # 外部安装 - 技能编写指南
```

---

## 一、CLAUDE.md — 项目 AI 上下文

| 属性 | 说明 |
|------|------|
| **路径** | `WorldTourCasino/CLAUDE.md` |
| **作用** | Claude Code 启动时自动加载的项目级指令文件 |
| **谁维护** | 团队共同维护，提交到 Git |

### 包含内容

| 章节 | 内容 |
|------|------|
| **Context** | 项目概述、技术栈、目录结构、四种风格系统、专业术语、构建命令 |
| **Rules** | 禁止行为（ES6+、AI 标识等）、强制要求（中文、ES5、代码规范）、Git 工作流 |
| **Decision** | 任务触发规则表 — 根据用户输入自动匹配对应的规则文件和执行流程 |

### 核心禁令（新人必读）

| 禁止项 | 原因 |
|--------|------|
| 提交信息中添加 AI 标识 | 公司规范要求 |
| 跳过提交确认流程 | 防止误提交 |
| 使用 ES6+ 语法 | 主项目必须兼容 ES5 |
| 随意创建新文档 | 优先更新现有文档 |

---

## 二、.claude/ 目录 — 配置根目录

### 2.1 settings.json — 项目级设置

```
路径: .claude/settings.json
提交: 是（团队共享）
```

当前配置：
```json
{
  "enabledPlugins": {
    "github@claude-plugins-official": true
  }
}
```

**作用**：控制启用哪些 Claude 插件。当前启用了 GitHub 官方插件，支持 PR、Issue 等操作。

### 2.2 settings.local.json — 本地设置

```
路径: .claude/settings.local.json
提交: 否（.gitignore 排除）
```

**作用**：个人权限配置（allow/deny/ask 规则），控制 Claude 哪些操作需要确认、哪些自动放行。每个开发者可以根据自己的习惯配置。

### 2.3 plugins.json — 插件注册表

```
路径: .claude/plugins.json
提交: 是
```

**作用**：自动生成的插件元数据文件，记录所有已安装 skill 和 command 的文件名、大小、hash、安装时间等。**不需要手动编辑**。

---

## 三、commands/ 目录 — 斜杠命令

斜杠命令是**用户主动调用**的工作流，通过在 Claude Code 中输入 `/命令名` 触发。

### 3.1 目录结构

```
commands/
├── openspec-archive-checklist.md    →  /openspec-archive-checklist
└── openspec/
    ├── proposal.md                  →  /openspec:proposal
    ├── apply.md                     →  /openspec:apply
    └── archive.md                   →  /openspec:archive
```

### 3.2 命令说明

| 命令 | 用途 | 使用场景 |
|------|------|----------|
| `/openspec:proposal` | 创建新的 OpenSpec 变更提案 | 需要规划新功能、架构变更时 |
| `/openspec:apply` | 实施已批准的 OpenSpec 变更 | 提案通过后，开始编码实现 |
| `/openspec:archive` | 归档已部署的 OpenSpec 变更 | 变更上线后，归档并更新规范 |
| `/openspec-archive-checklist` | 归档后同步检查清单 | 归档完成后，确认所有关联配置已更新 |

### 3.3 如何新增命令

在 `commands/` 目录下创建 `.md` 文件即可，文件名即命令名。支持子目录分组（用 `:` 分隔）。

---

## 四、skills/ 目录 — 技能系统

技能是**可自动触发或手动调用**的复杂工作流。每个技能包含一个 `SKILL.md` 定义文件，部分还包含脚本和参考文档。

### 4.1 项目自建技能（核心）

#### git-commit — Git 提交流程

```
路径: skills/git-commit/SKILL.md
触发: "提交吧" / "commit" / "git push" / /git-commit
```

| 特性 | 说明 |
|------|------|
| **自动调用 code-review** | 提交前强制执行代码审查 |
| **确认流程** | 生成提交大纲 → 用户确认 → 执行提交 |
| **提交顺序** | docs → extensions → 主项目 |
| **提交格式** | `[类型] 产品代号：描述`（中文冒号） |
| **禁止 AI 标识** | 不添加 "Co-Authored-By" 等 |

#### code-review — 代码审查

```
路径: skills/code-review/SKILL.md
触发: /code-review / "审查代码" / 由 git-commit 自动调用
```

| 特性 | 说明 |
|------|------|
| **自动跳过** | <50 行、纯文档、纯构建产物时跳过 |
| **高风险 API 检测** | `removeFromParent`、`removeChild` 等需要深度分析 |
| **输出格式** | 变更概览 → 高风险项 → 中风险项 → 二次确认清单 |

#### card-system-season-update — 收集系统赛季更新

```
路径: skills/card-system-season-update/SKILL.md
触发: /card-system-season-update
```

全自动流程，无需参数：
1. 从分支名推断风格（`cvs` → CV, `dbh` → DH 等）
2. 从代码读取赛季 ID
3. 从 Google Sheets 获取配置
4. 自动生成资源、发布、构建

#### docs-to-google-drive — 文档上传

```
路径: skills/docs-to-google-drive/SKILL.md
触发: "上传文档到 Google Drive" / "备份文档"
```

批量上传 `docs/` 下的文档到 Google Drive，支持按时间段、目录、作者筛选。

#### feishu-to-docs — 飞书文档转换

```
路径: skills/feishu-to-docs/SKILL.md
触发: "从飞书转 docs" / 提供飞书链接
```

读取飞书文档 → 自动识别类型（故障排查/活动/关卡/其他） → 生成结构化 Markdown → 自动提交。

#### git-branch-archive — 分支归档

```
路径: skills/git-branch-archive/SKILL.md
触发: "归档老分支" / "清理分支"
```

将长期无变更的远程分支归档为 `archive/<branch-name>` Tag，支持 dry-run 和恢复。归档记录保存在 `skills/git-branch-archive/archives/`。

### 4.2 外部安装技能

这些技能从 Anthropic 官方或社区安装，提供通用文件处理和开发能力：

| 技能 | 触发词 | 用途 |
|------|--------|------|
| **baoyu-post-to-wechat** | "发公众号"、"微信公众号" | 发布微信公众号文章/图文 |
| **docx** | 涉及 `.docx` 文件 | 创建/读取/编辑 Word 文档 |
| **pdf** | 涉及 `.pdf` 文件 | 读取/合并/拆分 PDF |
| **pptx** | 涉及 `.pptx` 文件 | 创建/编辑 PPT 演示文稿 |
| **xlsx** | 涉及 `.xlsx`/`.csv` 文件 | 读取/编辑电子表格 |
| **frontend-design** | "构建前端"、"做个页面" | 生成高质量前端界面代码 |
| **mcp-builder** | "创建 MCP 服务器" | 构建 MCP 协议服务器 |
| **skill-writer** | "创建 Skill" | 编写新的 Claude Code 技能 |

---

## 五、关联文件 — 规则扩展

CLAUDE.md 中的任务触发规则表引用了以下外部规则文件，Claude 在执行特定任务前会自动读取：

```
docs/工程-工具/ai-rules/
├── WTC/
│   ├── shell-scripts.md              # Shell 脚本编写规范
│   └── config-sync.md                # settings.json 同步规范
├── docs/
│   ├── vitepress.md                  # VitePress 文档规范
│   └── feishu-integration.md         # 飞书集成规范
├── extensions/
│   └── extension-dev.md              # VS Code 扩展开发规范
├── shared/
│   ├── rule-maintenance.md           # 规则维护指南
│   └── git-commit-types.md           # 提交类型定义
└── code-review/
    └── RULES.md                      # 代码审查规则
```

---

## 六、工作流全景图

```
用户输入
  │
  ▼
CLAUDE.md 加载（自动）
  │
  ├─ 匹配禁止行为？ → 拒绝执行
  │
  ├─ 匹配任务触发规则？
  │   ├─ "提交" → /git-commit skill
  │   │            └─ 自动调用 /code-review
  │   ├─ "规划" → 读取 openspec/AGENTS.md
  │   ├─ "飞书" → /feishu-to-docs skill
  │   ├─ "脚本" → 读取 shell-scripts.md 规范
  │   └─ 其他   → 读取对应规则文件
  │
  └─ 无匹配 → 使用 CLAUDE.md 内联规则执行
```

---

## 七、新人快速上手

### 日常使用

| 场景 | 操作 |
|------|------|
| 写完代码要提交 | 告诉 Claude "提交吧"，会自动审查+确认+提交 |
| 需要做功能规划 | 输入 `/openspec:proposal` 创建提案 |
| 飞书文档要归档 | 粘贴飞书链接，说"转到 docs" |
| 上传文档备份 | 说"上传文档到 Google Drive" |
| 清理老分支 | 说"归档一年未变更的分支" |
| 更新收集系统赛季 | 输入 `/card-system-season-update` |

### 迭代更新指南

| 要修改的内容 | 修改位置 | 注意事项 |
|-------------|---------|---------|
| 项目级规则/禁令 | `CLAUDE.md` | 仅放严重后果的规则 |
| 详细编码规范 | `docs/工程-工具/ai-rules/` | 可修复的错误放这里 |
| 新增斜杠命令 | `.claude/commands/` | 创建 `.md` 文件即可 |
| 新增/修改技能 | `.claude/skills/技能名/SKILL.md` | 参考现有技能格式 |
| 启用/禁用插件 | `.claude/settings.json` | 团队共享，谨慎修改 |
| 个人权限偏好 | `.claude/settings.local.json` | 不提交，仅本地生效 |

### 规则层级（重要）

```
第一层：CLAUDE.md 内联         → 违反后果严重、难以恢复
第二层：docs/ai-rules/ 外部文件 → 需要详细规范、可修复
第三层：.claude/commands/       → 有清晰工作边界的用户流程
```

---

**最后更新**: 2026-05-11
