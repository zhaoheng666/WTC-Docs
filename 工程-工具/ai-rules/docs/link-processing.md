# 文档链接处理规则

## 规则概述

**使用根路径绝对引用，实现文档与位置解耦**

这是 **强制性规则**，适用于所有文档编写。

## 核心原则

详细设计原理参见：[WTC-docs链接设计规范](/工程-工具/WTC-docs链接设计规范)

### 为什么使用根路径

1. **位置无关性**：文档可以随意移动目录，链接不受影响
2. **与图片一致**：图片使用 `/assets/`，文档也使用根路径
3. **VitePress 原生支持**：框架自动处理根路径
4. **重构友好**：目录结构调整时无需修改链接

---

## 链接格式规范

### 1. 文档链接

**✅ 使用根路径绝对引用**

```markdown
# 推荐格式
[配置管理](/工程-工具/ai-rules/WTC/config-sync)
[Shell 规范](/工程-工具/vscode/shell-脚本规范)
[首页](/README)

# ❌ 不推荐：相对路径
[配置管理](../WTC/config-sync)
[Shell 规范](../../vscode/shell-脚本规范)
```

**VitePress 自动处理**：
- 开发：`/工程-工具/config` → `/WTC-Docs/工程-工具/config.html`
- 生产：`/工程-工具/config` → `https://zhaoheng666.github.io/WTC-Docs/工程-工具/config.html`

### 2. 图片资源链接

**✅ 使用 `/assets/` 绝对路径**

```markdown
![截图](/assets/screenshot.png)
```

**VitePress 自动处理**：
- 开发：`http://localhost:5173/WTC-Docs/assets/screenshot.png`
- 生产：`https://zhaoheng666.github.io/WTC-Docs/assets/screenshot.png`

### 3. PDF 文件链接

**✅ 使用 `/pdf/` 绝对路径**

```markdown
[开发指南](/pdf/dev-guide.pdf)
```

### 4. 外部链接

外部链接保持完整 URL：

```markdown
[VitePress 官方](https://vitepress.dev/)
[GitHub 仓库](https://github.com/zhaoheng666/WTC-Docs)
```

---

## AI 工作规范

### 编写文档时的链接格式

**文档链接**：

```markdown
# ✅ 正确：根路径
[配置管理](/工程-工具/ai-rules/WTC/config-sync)
[工具列表](/工程-工具/vscode/README)

# ❌ 错误：相对路径
[配置管理](../WTC/config-sync)
[工具列表](../../vscode/README)
```

**图片引用**：

```markdown
# ✅ 正确：/assets/ 路径
![截图](/assets/screenshot.png)

# ❌ 错误：相对路径
![截图](../public/assets/screenshot.png)
```

**代码文件引用**（在 Markdown 文本中说明位置）：

```markdown
# ✅ 推荐：文件路径格式
修改 `docs/.vitepress/config.mjs:10` 中的 base 配置

# ✅ 可选：GitHub 链接（用于代码审查等场景）
参见：https://github.com/zhaoheng666/WTC-Docs/blob/main/docs/.vitepress/config.mjs#L10
```

---

## 迁移工具

### 自动转换脚本

从相对路径迁移到根路径：

```bash
node .vitepress/scripts/convert-to-absolute-paths.js
```

**转换规则**：

| 相对路径 | 根路径 | 说明 |
|---------|--------|------|
| `./config` | `/工程-工具/ai-rules/WTC/config` | 同级目录 |
| `../shared/doc` | `/工程-工具/ai-rules/shared/doc` | 上级目录 |
| `../../vscode/tool` | `/工程-工具/vscode/tool` | 跨目录 |

---

## 故障排查

### 链接显示 404

**检查项**：
1. 确认文件路径正确（注意大小写）
2. 检查文件是否存在
3. 启动开发服务器测试：`npm run dev`

### 图片无法显示

**检查项**：
1. 图片是否在正确的资源目录
2. 使用 `/assets/` 开头（不是 `./assets/`）
3. 检查图片文件名和扩展名

### 死链检测误报

**处理方式**（`config.mjs`）：

```javascript
export default {
  ignoreDeadLinks: [
    /\/%E/,  // URL 编码的中文路径
    (url) => url.includes('/external-api/')
  ]
}
```

---

## 设计优势

| 维度 | 相对路径 | 根路径（当前方案） |
|------|---------|-----------------|
| **位置依赖** | ❌ 强依赖 | ✅ 无依赖 |
| **维护成本** | ❌ 需手动修复 | ✅ 零维护 |
| **框架兼容** | ✅ 标准 | ✅ 标准 |
| **与图片一致** | ❌ 不一致 | ✅ 一致 |
| **重构友好** | ❌ 困难 | ✅ 容易 |

---

## 相关文档

- [WTC-docs 链接设计规范](/工程-工具/WTC-docs链接设计规范)：详细设计理念
- [文件路径链接规范](/工程-工具/ai-rules/shared/file-path-links)：代码文件引用格式
- [VitePress 官方文档](https://vitepress.dev/guide/routing)：路由和链接规范

---

## 更新记录

**2025-10-16 - 实现自动链接转换**
- 重构 `.vitepress/scripts/link-processor.js` 实现主动检测功能
- Build 脚本在 VitePress 构建前自动转换相对路径
- 开发者无需手动维护链接格式，系统自动保证正确性
- 测试验证：相对路径、根路径、外部链接、锚点、图片均处理正确

**2025-10-16 - 链接格式统一**
- 统一链接格式为根路径，实现文档与位置解耦
- 批量转换现有文档链接（23 文件，83 链接）
- 更新 AI 规则强制要求使用根路径格式
