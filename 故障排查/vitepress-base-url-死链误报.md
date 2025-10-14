# VitePress Base URL 死链误报问题

## 问题描述

在 VitePress 构建时，出现死链错误：

```
Found dead link http://localhost:5173/WTC-Docs/index in file 工程-工具/ai-rules/WTC/documentation-guide.md
```

但实际上：
1. 文件中的链接是 `http://localhost:5173/WTC-Docs/`（带尾部斜杠）
2. 该页面是可以正常访问的（对应 `index.md`）

## 根本原因

这是 VitePress 路由机制导致的误报：

1. **VitePress 路由解析**：当链接到 base URL（如 `http://localhost:5173/WTC-Docs/`）时，VitePress 的路由器会自动将其解析为 `http://localhost:5173/WTC-Docs/index`

2. **死链检测器误判**：死链检测器检查 `/WTC-Docs/index` 路径时，发现它不是一个实际的 Markdown 文件（实际文件是 `index.md`），因此报告为死链

3. **页面实际可访问**：尽管被报告为死链，但页面实际上是可以访问的，因为 VitePress 会正确地将 `/WTC-Docs/` 路由到 `index.md`

## 解决方案

### 方案1：使用 `ignoreDeadLinks` 函数（推荐）

在 `.vitepress/config.mjs` 中配置 `ignoreDeadLinks`，使用函数来动态忽略这个特定的误报：

```javascript
export default defineConfig({
  base: '/WTC-Docs/',

  ignoreDeadLinks: [
    // 忽略 base URL 后的 /index 路径（VitePress 路由机制导致的误报）
    (url) => {
      const baseIndex = `${process.env.GITHUB_ACTIONS ? 'https://zhaoheng666.github.io' : 'http://localhost:5173'}/WTC-Docs/index`;
      return url === baseIndex || url === `${baseIndex}.html`;
    }
  ]
})
```

**优点**：
- 不影响实际链接格式
- 同时支持本地和生产环境
- 针对性地解决这个特定问题

### 方案2：在链接后添加查询参数（临时方案）

在链接后添加查询参数（如 `?sn=1`），阻止 VitePress 路由器将其解析为 `/index`：

```markdown
- **本地**: http://localhost:5173/WTC-Docs/?sn=1
```

**缺点**：
- 链接不够简洁
- 只是绕过问题，不是真正的解决方案

### 方案3：使用正则表达式忽略

```javascript
ignoreDeadLinks: [
  // 忽略所有以 /index 或 /index.html 结尾的链接
  /\/index(\.html)?$/
]
```

**缺点**：
- 可能忽略其他真正的死链

## 相关配置

### 当前配置文件

`.vitepress/config.mjs`:
```javascript
export default defineConfig({
  base: '/WTC-Docs/',
  ignoreDeadLinks: [
    (url) => {
      const baseIndex = `${process.env.GITHUB_ACTIONS ? 'https://zhaoheng666.github.io' : 'http://localhost:5173'}/WTC-Docs/index`;
      return url === baseIndex || url === `${baseIndex}.html`;
    }
  ]
})
```

## 参考资料

- [VitePress Site Config - ignoreDeadLinks](https://vitepress.dev/reference/site-config#ignoredeadlinks)
- [VitePress Routing Guide](https://vitepress.dev/guide/routing)
- [GitHub Issue: dead link errors should show transformed URL #3774](https://github.com/vuejs/vitepress/issues/3774)

## 相关问题

如果遇到类似的路由相关问题，可以考虑：
1. 检查 `base` 配置是否正确（应该以 `/` 开头和结尾）
2. 检查 `cleanUrls` 配置（如果启用）
3. 查看 VitePress 的路由解析日志

---

**问题发现日期**: 2025-10-14
**解决方案**: 使用 ignoreDeadLinks 函数动态忽略 base URL 的 /index 误报
**影响范围**: 仅影响构建过程，不影响实际页面访问
