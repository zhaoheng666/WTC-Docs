# 文档链接处理规则

## 规则概述

**所有文档中的相对链接必须在构建时转换为完整的 HTTP 链接**

这是 **强制性规则**，适用于所有文档编写和构建流程。

## 为什么需要链接处理

详细设计原理参见：[WTC-docs链接设计规范](http://localhost:5173/WTC-Docs/工程-工具/WTC-docs链接设计规范)

### 核心原因

1. **编辑器兼容性**：相对路径在不同编辑器（VS Code、Typora、Mark Text）中表现不一致
2. **避免死链**：VitePress 构建时死链检测可能因相对路径误报
3. **多环境支持**：统一格式便于在本地开发和线上部署间切换

### 推荐格式对比

```markdown
# ✅ 推荐：完整 HTTP 链接
[PDF文档](http://localhost:5173/WTC-Docs/pdf/文档名.pdf)
[图片资源](http://localhost:5173/WTC-Docs/assets/1758727509512_c2bd9e6b.png)
[内部文档](http://localhost:5173/WTC-Docs/工程-工具/vscode/配置说明)

# ❌ 不推荐：相对路径
[PDF文档](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/public/pdf/文档名.pdf)
[图片资源](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/assets/image.png)
[内部文档](http://localhost:5173/WTC-Docs/工程-工具/other/doc)
```

## 构建流程集成

### 处理时机

链接处理在构建流程中的位置：

```bash
图片处理 → 链接处理 → VitePress Build
```

- **在图片处理之后**：确保图片引用已经转换完成
- **在 VitePress 构建之前**：避免构建时出现死链检测问题

### 处理范围

链接处理器会检查：

1. **变更文件**：通过 `git diff` 检测修改的 markdown 文件
2. **相对链接**：检测 `[text](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/相对路径)` 和 `![alt](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/相对路径)` 格式
3. **自动转换**：将相对路径转换为 `http://localhost:5173/WTC-Docs/` 开头的绝对链接

### 排除规则

以下类型的链接**不会**被转换：

- 已经是完整 HTTP/HTTPS 链接（`http://`、`https://`）
- GitHub 链接（`github.com`）
- 外部网站链接
- 锚点链接（`#heading`）

## 实现细节

### 脚本位置

```bash
docs/.vitepress/scripts/link-processor.js
```

### 调用方式

在 `build.sh` 和 `build-ci.sh` 中：

```bash
# 1. 处理图片
node .vitepress/scripts/image-processor.js

# 2. 处理链接（新增）
node .vitepress/scripts/link-processor.js

# 3. 构建文档
npm run docs:build
```

## AI 工作规范

### 编写文档时

**在编写任何文档时，必须直接使用完整 HTTP 链接格式**：

```markdown
[链接文本](http://localhost:5173/WTC-Docs/路径)
```

### 引用文件时

- **文档引用**：使用 `http://localhost:5173/WTC-Docs/` 格式
- **代码文件引用**：使用 GitHub 链接（参见 [文件路径链接规范](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/shared/file-path-links)）

### 构建检查

构建流程会自动处理遗漏的相对链接，但建议：

1. **主动使用正确格式**：减少构建时的转换工作
2. **检查构建日志**：确认链接转换是否成功
3. **本地预览验证**：构建后检查链接是否正常工作

## 故障排查

### 链接无法访问

1. 检查链接格式是否正确：`http://localhost:5173/WTC-Docs/...`
2. 确认文件路径是否存在
3. 检查构建日志中的链接转换记录

### 构建时报死链

1. 检查是否有外部相对链接未被正确转换
2. 查看 link-processor 日志
3. 手动修正问题链接

## 相关规则

- [WTC-docs链接设计规范](http://localhost:5173/WTC-Docs/工程-工具/WTC-docs链接设计规范)：完整设计原理
- [文件路径链接规范](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/shared/file-path-links)：代码文件链接格式
- [VitePress 开发规范](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/vitepress-standards)：文档开发标准
