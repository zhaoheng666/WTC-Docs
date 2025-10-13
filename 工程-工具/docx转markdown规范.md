# DOCX 转 Markdown 规范

本文档定义了如何将 Word 文档 (.docx) 转换为 Markdown 格式，以便集成到 WTC-Docs 文档系统。

## 核心原则

1. **使用 Pandoc 转换**：利用 Pandoc 工具进行自动转换
2. **图片自动处理**：借助现有的 `image-processor.js` 自动处理图片命名和引用
3. **相对路径引用**：Markdown 中使用**相对路径**引用图片，让构建脚本自动转换
4. **保留语义化 alt 文本**：图片描述应该有意义，避免使用 `image1`、`image2` 等无意义的名称

## 转换流程

### 第 1 步：使用 Pandoc 转换

```bash
# 进入文档所在目录
cd /path/to/docs/目录

# 使用 Pandoc 转换并提取图片
pandoc "文档名.docx" -o "文档名.md" --extract-media=.
```

**说明**：

- `--extract-media=.`：将文档中的图片提取到当前目录的 `media/` 子目录
- Pandoc 会自动为图片命名为 `image1.png`、`image2.png` 等

### 第 2 步：优化 Markdown 格式

Pandoc 生成的 Markdown 通常包含一些需要清理的内容：

```markdown
# 需要清理的内容示例

# 1. 移除图片尺寸属性
![](./media/image1.png){width="6.208333333333333in" height="3.6458333333333335in"}
# 改为：
![配置界面](media/image1.png)

# 2. 清理下划线标记
[[git@github.com]{.underline}](mailto:git@github.com):repo/name.git
# 改为：
`git@github.com:repo/name.git`

# 3. 规范化标题
## 要求固定tmpl.json配置文件路径
# 改为：
## tmpl.json 配置文件路径要求

# 4. 添加有意义的 alt 文本
![](media/image1.png)
# 改为：
![配置路径输入界面](media/image1.png)
```

### 第 3 步：图片引用规范

**关键**：在 Markdown 中使用**相对路径**引用图片，构建脚本会自动处理。

```markdown
# ✅ 正确：使用相对路径
![配置界面](media/image1.png)
![操作步骤](media/image2.png)

# ❌ 错误：不要使用绝对路径或 HTTP 链接
![配置界面](/Users/ghost/docs/media/image1.png)
![配置界面](http://localhost:5173/WTC-Docs/assets/xxx.png)
```

**原因**：

- 构建脚本 `image-processor.js` 会自动检测相对路径图片
- 自动复制到 `public/assets/` 目录
- 自动重命名为 `{timestamp}_{hash}.{ext}` 格式
- 自动更新 Markdown 中的引用为完整 HTTP 链接

### 第 4 步：运行构建脚本

```bash
# 进入 docs 目录
cd docs

# 运行构建脚本（会自动处理图片）
npm run build

# 或者启动开发服务器（也会处理图片）
npm run dev
```

**构建脚本的自动处理**：

1. **检测图片**：扫描 Markdown 中的相对路径图片引用
2. **复制图片**：将图片复制到 `public/assets/`
3. **重命名图片**：使用 `{timestamp}_{hash}.{ext}` 格式
   - `timestamp`：13 位时间戳（毫秒）
   - `hash`：图片内容的 MD5 哈希前 8 位
   - 示例：`1758727509979_00725c36.png`
4. **更新引用**：将 Markdown 中的相对路径替换为完整链接
   - 开发环境：`http://localhost:5173/WTC-Docs/assets/{filename}`
   - 生产环境：`https://zhaoheng666.github.io/WTC-Docs/assets/{filename}`
5. **清理原始目录**：删除 `media/` 等原始图片目录

## 图片命名规范

### 自动生成的图片名称格式

```
{timestamp}_{hash}.{ext}
```

**组成部分**：

- `timestamp`：13 位毫秒级时间戳，确保时间唯一性
- `hash`：基于图片 URL 的 MD5 哈希前 8 位，确保内容唯一性
- `ext`：原始图片扩展名（.png、.jpg、.gif 等）

**示例**：

```
1758727509979_00725c36.png
1760337193440_8c256044.png
1760338758605_6b381915.png
```

### 为什么使用这种命名

1. **唯一性保证**：时间戳 + 哈希确保不会重复
2. **内容追踪**：相同图片产生相同哈希
3. **时间排序**：时间戳在前，便于按时间查找
4. **避免冲突**：不依赖原始文件名，避免中文或特殊字符问题

## 完整示例

### 原始 DOCX 结构

```
创建新关卡工具使用指南.docx
├── [文本内容]
├── [图片1: VSCode扩展截图]
├── [图片2: 配置路径界面]
├── [图片3: 生成结果]
└── [图片4: 文件结构]
```

### 转换后的目录结构

```
docs/
├── 关卡/
│   └── 创建新关卡工具使用指南.md    ← Markdown 文件
│       └── (引用: media/image1.png, media/image2.png...)
└── public/assets/                      ← 构建后自动生成
    ├── 1760338758605_6b381915.png      ← image4.png
    ├── 1760338758605_7163febf.png      ← image1.png
    ├── 1760338758606_05b05e2d.png      ← image2.png
    └── 1760338758606_060c9619.png      ← image3.png
```

### Markdown 文件内容变化

**转换后（构建前）**：

```markdown
# 生成新关卡工具使用指南

## VSCode 增加开发工具

![VSCode 工具扩展](media/image4.png)

## 运行工具

### 步骤 1：配置路径

![配置路径](media/image1.png)
```

**构建后（自动更新）**：

```markdown
# 生成新关卡工具使用指南

## VSCode 增加开发工具

![VSCode 工具扩展](http://localhost:5173/WTC-Docs/assets/1760338758605_6b381915.png)

## 运行工具

### 步骤 1：配置路径

![配置路径](http://localhost:5173/WTC-Docs/assets/1760338758605_7163febf.png)
```

## 常见问题

### Q1: 为什么不直接在 Markdown 中使用 HTTP 链接？

**A**: 因为在编写文档时，图片还没有被处理和重命名。使用相对路径可以：

1. 在编辑器中预览图片
2. 让构建脚本自动处理命名和引用更新
3. 保持文档的可移植性

### Q2: media/ 目录什么时候会被删除？

**A**: 构建脚本在处理完图片后会自动删除以下常见的原始图片目录：

- `assets/`
- `images/`
- `image/`
- `img/`
- `pics/`
- `pictures/`
- `media/` ✅ 已支持

**注意**：如果使用其他自定义目录名，可能需要手动删除。

### Q3: 如何确保图片被正确处理？

**A**: 运行构建时检查输出：

```bash
npm run build

# 应该看到：
# 🔍 检查 MD 文件中的图片...
#   • 发现 X 个变更的 MD 文件
# 🖼️  开始处理图片引用...
#   ✓ 处理了 Y 个文件
#   ✓ 处理了 Z 个本地图片
# 🧹 清理原始图片目录...
#   ✓ 原始图片目录清理完成
```

### Q4: 构建后 Markdown 文件会被修改吗？

**A**: 是的！构建脚本会**直接修改** Markdown 文件，将相对路径替换为完整的 HTTP 链接。因此：

1. 建议先提交原始文档
2. 运行构建后再次提交更新的引用
3. Git 会显示 Markdown 文件被修改

### Q5: 可以使用其他图片目录名吗？

**A**: 可以，但需要注意：

- Pandoc 默认使用 `media/`
- 构建脚本会识别常见的目录名
- 如果使用自定义目录名，可能需要手动清理

## 操作检查清单

转换 DOCX 时，请确保完成以下步骤：

- [ ] 使用 Pandoc 转换并提取图片到 `media/` 目录
- [ ] 清理 Pandoc 生成的冗余格式（尺寸属性、下划线标记等）
- [ ] 为所有图片添加有意义的 alt 文本
- [ ] 确认使用相对路径引用图片（如 `media/image1.png`）
- [ ] 规范化标题格式和段落结构
- [ ] 运行 `npm run build` 验证图片处理
- [ ] 检查 `public/assets/` 目录确认图片已复制
- [ ] 验证 Markdown 中的图片链接已更新为 HTTP 格式
- [ ] 在浏览器中预览文档确认图片正常显示
- [ ] 手动删除原始的 `media/` 目录（如果未自动清理）
- [ ] 提交更新后的 Markdown 文件和新增的图片

## 相关文档

- [WTC-docs 链接设计规范](./WTC-docs链接设计规范.md) - 了解为什么使用完整 HTTP 链接
- [GitHub: image-processor.js](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/docs/.vitepress/scripts/image-processor.js) - 图片处理脚本源码
- [GitHub: build.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/docs/.vitepress/scripts/build.sh) - 构建脚本源码

## 技术实现细节

### image-processor.js 关键逻辑

```javascript
// 生成唯一图片名称
generateUniqueImageName(mdFilePath, originalUrl, imageId = null) {
  // 1. 提取扩展名
  let ext = '.png';
  const originalExt = path.extname(originalUrl).toLowerCase();
  if (['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'].includes(originalExt)) {
    ext = originalExt;
  }

  // 2. 生成内容哈希
  const contentKey = originalUrl + (imageId ? '|' + imageId : '');
  const fullHash = crypto.createHash('md5').update(contentKey).digest('hex');

  // 3. 生成文件名：时间戳(13位) + 哈希(8位)
  const timestamp = Date.now().toString();
  const shortHash = fullHash.substring(0, 8);
  const filename = `${timestamp}_${shortHash}${ext}`;

  return filename;
}
```

### 构建流程

```mermaid
graph LR
    A[编写 Markdown<br/>相对路径引用] --> B[运行 npm run build]
    B --> C[检测变更的 MD 文件]
    C --> D[扫描图片引用]
    D --> E[复制图片到 public/assets/]
    E --> F[重命名为时间戳_哈希格式]
    F --> G[更新 Markdown 引用为 HTTP 链接]
    G --> H[清理原始图片目录]
    H --> I[VitePress 构建]
```
