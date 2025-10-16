# DOCX 转 Markdown 规范

本文档定义了如何将 Word 文档 (.docx) 转换为 Markdown 格式，以便集成到 WTC-Docs 文档系统。

## 核心原则

1. **使用 Pandoc 转换**：利用 Pandoc 工具进行自动转换
2. **图片自动处理**：借助 `image-processor.js` 自动处理图片命名和引用
3. **相对路径引用**：Markdown 中使用相对路径引用图片，构建脚本自动转换为 HTTP 链接
4. **保留语义化 alt 文本**：图片描述应该有意义

## 转换流程

### 第 0 步：确定文档存放目录

根据文档标题和内容关键词，推测合适的存放目录。

#### 目录推测规则

| 关键词示例 | 推荐目录 | 说明 |
|-----------|---------|------|
| 活动、event、activity | `活动/` | 游戏活动相关 |
| 关卡、slot、机台、spin | `关卡/` | 关卡相关 |
| 工具、构建、脚本、Jenkins、VSCode | `工程-工具/` | 开发工具和自动化 |
| 错误、bug、问题、crash、修复 | `故障排查/` | 问题排查和解决 |
| 服务器、接口、协议、API | `服务器/` | 服务器端相关 |
| 个人总结、工作记录 | `成员/{姓名}/` | 个人文档 |
| iOS、Android、native、打包 | `native/` | 原生平台相关 |
| 其他 | `其他/` | 默认分类 |

**示例**：
```
文档：创建新关卡工具使用指南
关键词：关卡、工具
推测：关卡/ （关卡优先级高于工具）
```

### 第 1 步：使用 npm script 转换

**推荐方式**：使用自动化脚本

```bash
# 在 docs 目录下运行
npm run convert-docx "成员/赵恒/文档名.docx"
```

脚本会自动完成：
1. **Pandoc 转换**并提取图片到 `media/` 目录
2. **自动清理格式**：
   - 移除图片尺寸属性 `{width="..." height="..."}`
   - 清理路径前缀 `./media/` → `media/`
   - **处理 Word 自动链接**（通用规则）：
     - Git 链接：`[git@github.com](mailto:...)` → `` `git@github.com:repo` ``
     - 邮箱：`[user@example.com](mailto:user@example.com)` → `` `user@example.com` ``
     - HTTP：`[http://example.com](http://example.com)` → `<http://example.com>`
     - 保留有意义的超链接：`[点击这里](http://...)` 不变
   - 移除 Pandoc 标记：`{.underline}`、`{.class}`
3. **构建验证**
4. **安全检查**后删除原始 DOCX 文件
5. **系统通知**：成功或失败都会发送 macOS 通知

### 安全机制

**只有所有步骤成功才会删除 DOCX 文件**：

- ✅ Pandoc 转换成功
- ✅ Markdown 文件已生成且非空
- ✅ 格式清理成功
- ✅ 构建验证通过
- ✅ 图片提取正常（如果有图片）

**任何步骤失败都会保留原始 DOCX 文件供检查，并发送系统通知告知失败原因。**

**手动方式**（仅在脚本不可用时使用）：

```bash
cd "目标目录"
pandoc "文档名.docx" -f docx -t markdown --extract-media=. -o "文档名.md"
```

### 第 2 步：优化 Markdown 格式

**注意**：使用 `npm run convert-docx` 后，路径和 Git 链接已自动清理，只需关注：

#### 排版优化要点

**图片处理**：
- 添加语义化 alt 文本（避免 `image1`、`图片` 等无意义描述）

**文本规范**：
- 中英文之间添加空格（`tmpl.json 配置`）
- 标题末尾移除标点（除问号）
- 列表使用 `1.` 而非 `1、`
- 补全被截断的句子

**代码块**：
- 添加语言标识符（`bash`、`javascript` 等）

**示例**：
```markdown
# 优化前
## 运行工具：
1、首次运行需配置tmpl.json文件路径
![](./media/image1.png){width="11.5in"}

# 优化后
## 运行工具
1. **配置 tmpl.json 文件路径**
   ![配置路径输入界面](media/image1.png)
```

### 第 3 步：运行构建脚本

```bash
cd docs
npm run build
```

构建脚本会自动：
1. 检测变更的 Markdown 文件
2. 处理相对路径图片引用
3. 复制图片到 `assets/` （源码目录）
4. 重命名为 `{timestamp}_{hash}.{ext}` 格式
5. 更新 Markdown 中的引用为 HTTP 链接
6. 删除 `media/` 原始图片目录

### 第 4 步：验证和清理

**自动清理**（使用 npm script）：
- 原始 DOCX 文件会在构建验证通过后自动删除

**手动清理**（如果使用手动转换）：
```bash
# 1. 确认构建成功
npm run build

# 2. 在浏览器中预览
npm run dev  # 访问 http://localhost:5173/WTC-Docs

# 3. 确认无误后删除 DOCX
rm "文档名.docx"
```

## 图片命名规范

构建脚本会自动将图片重命名为：

```
{timestamp}_{hash}.{ext}
```

- `timestamp`：13 位毫秒级时间戳
- `hash`：基于图片内容的 MD5 哈希前 8 位
- `ext`：原始扩展名（.png、.jpg 等）

**示例**：`1758727509979_00725c36.png`

**优势**：
- 唯一性保证（时间戳 + 内容哈希）
- 相同图片产生相同哈希（自动去重）
- 避免中文或特殊字符问题

## 快速检查清单

转换 DOCX 时的核心步骤：

- [ ] 根据内容确定存放目录
- [ ] 运行 `npm run convert-docx "路径/文档.docx"`
- [ ] 优化 Markdown 排版（图片 alt、标题、列表、代码块）
- [ ] 确认图片引用使用相对路径
- [ ] 运行 `npm run build` 验证
- [ ] 浏览器预览确认图片正常显示
- [ ] 原始 DOCX 文件已自动删除（或手动删除）

## 相关文档

- [WTC-docs 链接设计规范](/工程-工具/WTC-docs链接设计规范) - HTTP 链接设计原理
- [image-processor.js](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/docs/.vitepress/scripts/image-processor.js) - 图片处理脚本源码

## 注意事项

1. **构建验证必须通过**才删除 DOCX 文件
2. **DOCX 文件已在 .gitignore 中**，不会被提交
3. **图片使用相对路径**，不要手动修改为 HTTP 链接
4. **media/ 目录会自动删除**，图片移到 assets/（源码目录）
