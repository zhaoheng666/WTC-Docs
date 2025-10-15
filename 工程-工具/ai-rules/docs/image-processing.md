# 图片处理机制

**适用范围**: 仅 docs 子项目

本文件详细说明 docs 子项目的图片处理机制。

---

## 自动化脚本

**脚本位置**: `.vitepress/scripts/image-processor.js`

**执行时机**: 构建时自动执行

---

## 工作流程

### 1. 下载外部图片

- 扫描 Markdown 文件中的图片引用
- 识别外部 URL（如 https://example.com/image.png）
- 自动下载到 `public/assets/` 目录

### 2. 命名格式

```
文件路径_哈希值.扩展名
```

**示例**:
```
工程-工具_vscode_abc123def.png
故障排查_构建问题_456789abc.jpg
```

**优势**:
- 避免文件名冲突
- 基于内容哈希，相同图片不重复下载
- 便于追踪图片来源

### 3. 更新 Markdown 引用

自动将外部 URL 替换为本地路径：

**原始 Markdown**:
```markdown
![示例](https://example.com/image.png)
```

**自动更新为**:
```markdown
<!-- <!-- ![示例](/assets/工程-工具_vscode_abc123def.png) -->
<!-- ⚠️ 图片文件缺失，已注释 --> -->
<!-- ⚠️ 图片文件缺失，已注释 -->
```

### 4. 清理未使用的图片

- 构建时扫描所有 Markdown 文件
- 识别 `public/assets/` 中未被引用的图片
- 自动删除，保持目录清洁

---

## 配置选项

在 `.vitepress/scripts/image-processor.js` 中可配置：

```javascript
{
  assetsDir: 'public/assets',  // 图片存放目录
  hashLength: 8,               // 哈希值长度
  enableCleanup: true,         // 是否清理未使用图片
  supportedFormats: [          // 支持的图片格式
    'png', 'jpg', 'jpeg',
    'gif', 'svg', 'webp'
  ]
}
```

---

## 日志查看

图片处理日志位于：`/tmp/image-processor.log`

**查看日志**:
```bash
cat /tmp/image-processor.log
```

**日志内容**:
- 下载的图片列表
- 更新的 Markdown 文件
- 清理的未使用图片
- 错误信息（如下载失败）

---

## 常见问题

### 图片未清理

运行 `npm run build` 重新处理图片。

### 图片下载失败

检查：
1. 网络连接
2. 图片 URL 是否有效
3. `/tmp/image-processor.log` 日志

### 图片路径错误

确保：
1. 图片引用使用绝对路径（`/assets/...`）
2. 图片文件在 `public/assets/` 目录中
3. 文件名没有特殊字符

---

**最后更新**: 2025-10-13
**维护者**: WTC-Docs Team
