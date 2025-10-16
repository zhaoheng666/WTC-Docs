# VitePress Public 目录设计规范

## 问题背景

在 VitePress 项目中遇到警告：

```
Assets in public directory cannot be imported from JavaScript.
If you intend to import that asset, put the file in the src directory...
```

## VitePress 对 Public 目录的定义

### 1. Public 目录的用途

`public/` 目录用于存放**纯静态资源**，这些资源：
- ✅ 直接通过 URL 访问（如 `/favicon.ico`）
- ✅ 不需要经过构建处理
- ✅ 不会被 hash 命名
- ❌ **不应该在 JavaScript/Markdown 中 import**

### 2. 源码资源目录

需要在代码中引用的资源应该放在**源码目录**：
- ✅ `docs/assets/` - 图片、媒体文件
- ✅ `.vitepress/assets/` - 主题相关资源
- ✅ 会被 Vite 处理（优化、hash、tree-shaking）
- ✅ 可以在 Markdown 中使用 `![](/assets/xxx.png)`

### 3. 目录对比

| 目录 | 用途 | 是否可 import | 构建处理 | URL 路径 |
|------|------|--------------|----------|----------|
| `public/` | 纯静态资源 | ❌ | 直接复制 | `/xxx` |
| `docs/assets/` | 源码资源 | ✅ | Vite 优化 | `/assets/xxx` |
| `.vitepress/assets/` | 主题资源 | ✅ | Vite 优化 | 自动处理 |

## 我们的解决方案

### 之前的错误设计

```
docs/
├── public/
│   └── assets/          ❌ 错误：图片在 public 里
│       └── *.png
```

**问题**：
- Markdown 中 `![](/assets/xxx.png)` 被 VitePress 转为 JS import
- Vite 发现 `public/` 资源被 import，触发警告
- 违反了 public 目录的设计原则

### 正确的设计

```
docs/
├── public/              ✅ 只放纯静态资源
│   ├── favicon.svg
│   ├── logo.png
│   ├── stats.json
│   └── pdf/
├── assets/              ✅ 源码资源，可被 import
│   └── *.png
```

**优势**：
- ✅ 符合 VitePress/Vite 设计原则
- ✅ 图片可以被优化（压缩、格式转换）
- ✅ 支持 tree-shaking（未使用的资源不会打包）
- ✅ 没有警告

## 迁移步骤

如果你的项目有类似问题：

```bash
# 1. 移动 assets 目录
mv public/assets docs/assets

# 2. 验证引用仍然有效
# Markdown 中的 ![](/assets/xxx.png) 引用不需要修改

# 3. 重新构建测试
npm run dev
npm run build
```

## Public 目录应该放什么

### ✅ 适合放在 public/ 的资源

- `favicon.ico` / `favicon.svg` - 网站图标
- `robots.txt` - SEO 配置
- `manifest.json` - PWA 配置
- `*.pdf` - 直接下载的文档（不需要处理）
- `stats.json` - 动态数据文件（运行时生成）

### ❌ 不应该放在 public/ 的资源

- 文档中引用的图片 → 应该放 `docs/assets/`
- 组件使用的图标 → 应该放 `.vitepress/assets/`
- 需要优化的媒体文件 → 应该放源码目录

## 相关文档

- [VitePress 官方文档 - 静态资源处理](https://vitepress.dev/guide/asset-handling)
- [Vite 官方文档 - public 目录](https://vitejs.dev/guide/assets.html#the-public-directory)
- [WTC-docs 链接设计规范](/工程-工具/WTC-docs链接设计规范)

## 关键原则

**一句话总结**：
> `public/` 用于纯静态资源（URL 访问），`docs/assets/` 用于源码资源（import 引用）

**判断方法**：
- 需要在 Markdown/JS 中 import？→ `docs/assets/`
- 只需要直接 URL 访问？→ `public/`

---

**文档创建时间**：2025-10-16
**问题来源**：VitePress dev 模式警告 "Assets in public directory cannot be imported"
**解决方法**：将 `public/assets/` 移动到 `docs/assets/`
