# WTC-docs 链接设计规范

## 核心原则

**使用 VitePress 根路径格式，实现文档与位置解耦**

本规范基于 [VitePress 官方文档](https://vitepress.dev/guide/routing) 和实际项目需求制定。

---

## 设计理念

### 问题：文档链接与位置强耦合

使用相对路径（`./` `../`）的问题：
- 文档移动位置后，所有链接失效
- 维护困难，重构成本高
- 与图片链接设计不一致

### 解决方案：统一使用根路径

| 链接类型 | 格式示例 | 特点 |
|---------|---------|------|
| **图片** | `/assets/screenshot.png` | ✅ 位置无关 |
| **文档** | `/工程-工具/vscode/shell-脚本规范` | ✅ 位置无关 |
| **PDF** | `/pdf/guide.pdf` | ✅ 位置无关 |

**核心优势**：文档可以随意移动目录，链接保持有效。

---

## 链接格式规范

### 1. 文档链接（推荐格式）

**✅ 使用根路径绝对引用**

```markdown
# 根路径格式（推荐）
[配置管理](/工程-工具/ai-rules/WTC/config-sync)
[Shell 规范](/工程-工具/vscode/shell-脚本规范)
[首页](/README)

# 相对路径格式（不推荐）
[配置管理](/WTC/config-sync)  # ❌ 文档移动后失效
[Shell 规范](/../vscode/shell-脚本规范)  # ❌ 维护困难
```

**为什么使用根路径？**

VitePress 会自动处理根路径：
- 开发环境：`/工程-工具/config` → `/WTC-Docs/工程-工具/config.html`
- 生产环境：自动适配 `base` 配置
- **文档移动位置不影响链接**

### 2. 图片资源链接（已实现）

**✅ 使用 `/assets/` 绝对路径**

```markdown
![截图](/assets/screenshot.png)
```

**设计理念**（与文档链接一致）：
- 图片统一存储在 `public/assets/`
- 文档移动位置不影响图片引用
- 通过软链接 `docs/assets/` → `docs/public/assets/` 支持编辑器预览

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

## VitePress 原生机制

### 1. `base` 配置自动处理

VitePress 的 `base` 配置处理所有路径：

```javascript
// docs/.vitepress/config.mjs
export default {
  base: '/WTC-Docs/',  // GitHub Pages 路径前缀
}
```

**效果**：

| 链接写法 | 开发环境 | 生产环境 |
|---------|---------|---------|
| `/assets/image.png` | `http://localhost:5173/WTC-Docs/assets/image.png` | `https://zhaoheng666.github.io/WTC-Docs/assets/image.png` |
| `/工程-工具/config` | `http://localhost:5173/WTC-Docs/工程-工具/config.html` | `https://zhaoheng666.github.io/WTC-Docs/工程-工具/config.html` |

### 2. 文件路由系统

VitePress 自动将文件结构映射为 URL：

```
docs/
├── 工程-工具/
│   ├── vscode/
│   │   └── shell-脚本规范.md  → /工程-工具/vscode/shell-脚本规范
│   └── ai-rules/
│       └── WTC/
│           └── config-sync.md  → /工程-工具/ai-rules/WTC/config-sync
└── README.md                   → /README
```

### 3. `public/` 目录静态资源

`docs/public/` 下的文件直接复制到输出根目录：

```
docs/public/
├── assets/
│   └── screenshot.png  → /assets/screenshot.png
└── pdf/
    └── guide.pdf       → /pdf/guide.pdf
```

---

## 设计优势

### 与图片链接设计统一

| 资源类型 | 格式 | 位置依赖 |
|---------|------|---------|
| **图片** | `/assets/xxx.png` | ✅ 无依赖 |
| **文档** | `/工程-工具/xxx` | ✅ 无依赖 |
| **PDF** | `/pdf/xxx.pdf` | ✅ 无依赖 |

**设计一致性**：所有资源都使用根路径，文档可以随意重组目录结构。

### 优势对比

| 维度 | 相对路径 | 根路径（当前方案） |
|------|---------|-----------------|
| **文档可移动性** | ❌ 移动后失效 | ✅ 任意移动 |
| **维护成本** | ❌ 需要手动修复 | ✅ 零维护 |
| **框架兼容** | ✅ 标准格式 | ✅ 标准格式 |
| **重构友好** | ❌ 重构困难 | ✅ 重构容易 |
| **与图片一致** | ❌ 设计不一致 | ✅ 设计统一 |

---

## 迁移指南

### 从相对路径迁移

**转换规则**：

| 相对路径 | 根路径 | 说明 |
|---------|--------|------|
| `./config` | `/工程-工具/ai-rules/WTC/config` | 同级目录 |
| `../shared/doc` | `/工程-工具/ai-rules/shared/doc` | 上级目录 |
| `../../vscode/tool` | `/工程-工具/vscode/tool` | 跨目录 |

**自动化工具**：

```bash
# 批量转换脚本
node .vitepress/scripts/convert-to-absolute-paths.js
```

---

## 编辑器兼容性

### VS Code 预览支持

根路径格式在 VS Code 中的表现：

| 链接类型 | 预览效果 | 说明 |
|---------|---------|------|
| `/工程-工具/config` | ⚠️ 需运行服务器 | 启动 `npm run dev` 后可预览 |
| `/assets/image.png` | ⚠️ 需软链接 | 通过 `docs/assets/` 软链接预览 |

**最佳实践**：
1. 启动 VitePress 开发服务器：`npm run dev`
2. 在浏览器中预览文档（http://localhost:5173/WTC-Docs/）
3. 最终效果以 VitePress 渲染结果为准

---

## 常见问题

### Q: 根路径和相对路径哪个更符合 VitePress 规范？

**A**: 两者都是 VitePress 原生支持的格式。但根路径更适合需要频繁重组目录的项目：
- **相对路径**：适合结构固定的文档
- **根路径**：适合需要灵活重组的文档（我们的选择）

### Q: 为什么不用完整 HTTP 链接？

**A**: HTTP 链接有以下问题：
1. 绕过 VitePress 的死链检测
2. 需要构建时转换
3. 不符合框架设计理念

根路径格式同时具备：
- ✅ VitePress 原生支持
- ✅ 位置无关性
- ✅ 死链检测有效

### Q: 如何处理死链？

**A**: 根路径会触发 VitePress 死链检测，这是**好事**：
- 构建时发现问题
- 及时修复错误链接
- 保证文档质量

如需忽略特定链接：

```javascript
// .vitepress/config.mjs
export default {
  ignoreDeadLinks: [
    /\/%E/,  // URL 编码的中文路径
  ]
}
```

---

## 总结

### 核心要点

1. **文档链接**：使用根路径 `/工程-工具/xxx`
   ```markdown
   [配置](/工程-工具/ai-rules/WTC/config-sync)
   ```

2. **图片资源**：使用 `/assets/`（已实现）
   ```markdown
   ![截图](/assets/screenshot.png)
   ```

3. **外部链接**：保持完整 URL
   ```markdown
   [VitePress](https://vitepress.dev/)
   ```

### 设计理念

**"资源与位置解耦，文档结构灵活重组"**

- ✅ 所有资源使用根路径
- ✅ 文档可以随意移动
- ✅ 利用 VitePress 原生能力
- ✅ 设计统一（图片、文档、PDF）

---

## 更新记录

**2025-10-16 - 实现自动链接转换**
- 重构 `link-processor.js` 实现主动检测和转换功能
- 在 VitePress build 前自动将相对路径转换为根路径
- 与 `image-processor.js` 实现一致的位置无关性设计
- 工作流程：检测变更 MD 文件 → 扫描相对路径链接 → 自动转换 → 构建

**2025-10-16 - 链接格式统一**
- 统一链接设计为根路径格式，实现文档与位置解耦
- 迁移所有文档链接从相对路径到根路径格式
- 更新设计文档和 AI 规则
