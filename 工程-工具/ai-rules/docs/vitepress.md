# VitePress 开发规范

**适用范围**: 仅 docs 子项目

本文件定义 VitePress 文档系统的开发规范和注意事项。

---

## 代码块语言标识符（已在通用规则中定义）

参考: [文档编写规范](/工程-工具/ai-rules/shared/doc-writing)

VitePress 使用 Shiki 语法高亮，详细规范请查看通用规则文档。

---

## 图片处理机制

### 自动下载外部图片

- 外部图片自动下载到 `assets/` （源码目录，非 public/）
- 命名格式：`文件路径_哈希值.扩展名`
- 自动更新 Markdown 中的引用
- 构建时清理未使用的图片

### 图片引用

在 Markdown 中使用相对路径：

```txt
![描述](/assets/image_abc123.png)
```

---

## 搜索优化

### 中文分词

- 使用 Intl.Segmenter 实现中文分词
- 提升中文搜索准确性

### 权重设置

- 标题权重高于正文
- 确保重要内容优先显示

### 模糊匹配

- 支持模糊搜索
- 提升用户体验

---

## 日志位置

开发和调试时，可以查看以下日志文件：

- `/tmp/vitepress-build.log` - 构建日志
- `/tmp/image-processor.log` - 图片处理日志
- `/tmp/sync-build.log` - 同步日志

---

## 架构决策记录 (ADR)

docs 子项目的重要架构决策：

### ADR-001: 统计数据生成策略

- 仅在 CI 环境生成统计数据
- 本地通过 HTTP 获取线上数据
- 基于 Git 记录动态生成

### ADR-002: 目录索引内容保护机制

- 只更新目录结构部分
- 完全保护用户内容
- 智能创建模式

### ADR-003: URL编码与特殊字符处理

- 选择性编码
- 分段处理
- 保持可读性

---

## 相关配置文件

- `.vitepress/config.mjs` - VitePress 主配置
- `.vitepress/sidebar.mjs` - 自动生成侧边栏
- `.github/workflows/deploy.yml` - GitHub Actions 部署
- `.vitepress/scripts/` - 自动化脚本目录

---

##链接设计规范

参考: [WTC-docs-链接设计规范](/工程-工具/WTC-docs链接设计规范)

---

**最后更新**: 2025-10-13
**维护者**: WTC-Docs Team
