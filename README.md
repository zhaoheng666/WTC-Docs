# WorldTourCasino 文档系统

> 使用 VitePress 构建的技术文档系统，通过 GitHub Actions 自动部署到 GitHub Pages

> 解决的问题：
>
> 1、公司网盘、项目网盘两级要求，导致文档同步工作繁琐，协作困难；
>
> 2、现行文档分类、索引表格，维护繁琐，文档查找困难；
>
> 3、Google Drive 缺少文档内容搜索，信息查找困难；

## ✨ 特性

- 📝 **Markdown 驱动** - 专注内容创作
- 🔍 **智能中文搜索** - 基于 Intl.Segmenter 的专业分词
- 📸 **图片自动处理** - 解决防盗链，统一管理，无需图床
- 📄 **PDF 文件管理** - 自动收集、重命名、归档PDF文件
- 🏷️ **文件名标准化** - 批量清理文件名前缀后缀
- 🔄 **一键同步** - 自动构建、提交、部署
- 📱 **响应式设计** - 系统选择框交互，系统通知状态、结果

## 🛠 技术栈

- **框架**: VitePress 1.6.4
- **构建**: Vite + Vue 3
- **部署**: GitHub Pages + Actions
- **脚本**: Node.js + Bash

## 🏗️ 项目结构

```
docs/
├── .vitepress/
│   ├── config.mjs          # VitePress 配置
│   ├── sidebar.mjs         # 侧边栏自动生成
│   ├── components/         # Vue 组件
│   └── scripts/            # 自动化脚本
│       ├── init.sh                    # 环境初始化
│       ├── build.sh                   # 本地构建
│       ├── sync.sh                    # 同步脚本
│       ├── image-processor.js         # 图片处理
│       ├── pdf-processor.js           # PDF文件处理 (新)
│       ├── rename-files.js            # 批量重命名 (新)
│       ├── update-content-titles.js   # 标题同步 (新)
│       └── fix-problematic-filenames.js # 文件名修复
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions 配置
├── public/
│   ├── assets/            # 统一图片存储
│   ├── pdf/              # PDF文件存储 (新)
│   └── stats.json         # 文档统计数据
└── 各文档目录/
```

## 🔍 文档搜索

### 快捷键

- **Mac**：`Cmd + K`
- **Windows/Linux**：`Ctrl + K`

### 搜索功能

- **全文索引**：搜索文档标题、各级标题和正文内容
- **权重优化**：标题匹配优先级高于正文
- **模糊搜索**：支持拼写容错（fuzzy: 0.2）
- **前缀匹配**：输入部分文字即可匹配
- **实时预览**：输入即显示搜索结果
- **中英混合**：支持中英文混合搜索

## 📸 图片处理

**零操作，全自动** - 直接在 Markdown 中插入图片，系统自动处理

### 图片处理特性
- 支持本地图片、Gitee 图片、外部链接
- 自动下载外部图片到 `public/assets/`
- 生成唯一文件名（时间戳_哈希值）
- 构建时自动更新所有引用
- 智能去重，相同内容只存储一份
- 无持久化依赖，支持文件重命名

### PDF文件管理 (**新功能**)
- 自动扫描并收集所有PDF文件
- 清理文件名中的特殊字符
- 统一存储到 `public/pdf/` 目录
- 在文档中自动创建分类链接
- 完整HTTP链接兼容各种编辑器
- 处理后删除源文件避免重复

### 文件名标准化 (**新功能**)
- 批量去除Q季度前缀（Q3`24-Slots-, Q1 2025等）
- 自动清理程序后缀（-程序, 程序）
- 同步更新文档标题保持一致
- 支持所有Q前缀模式识别

## 🔄 一键同步

`npm run sync` 执行完整工作流：

1. **文件名修复** - 处理特殊字符确保URI安全
2. **PDF文件处理** - 收集、重命名、归档PDF文件
3. **图片处理** - 下载、重命名、更新引用
4. **构建测试** - 确保无错误
5. **自动提交** - 生成提交信息
6. **推送部署** - 监控 GitHub Actions 部署
7. **系统通知** - 完成后发送通知

## 📝 命令参考

### 核心命令

| 命令              | 说明           | 使用场景                   |
| ----------------- | -------------- | -------------------------- |
| `npm run init`  | 初始化环境     | 首次使用或修复环境问题     |
| `npm run dev`   | 启动开发服务器 | 日常文档编写和预览         |
| `npm run sync`  | 一键同步       | 自动构建、提交、推送、部署 |
| `npm run build` | 本地构建       | 测试构建是否成功           |

### 环境初始化

```bash
npm run init          # 自动检查和修复环境问题
```

自动处理：Node.js 依赖、GitHub CLI 配置、Git 中文路径、脚本权限、Mac ARM64 兼容性

## 📊 性能指标

- **本地启动**: < 2秒
- **热更新**: < 100ms
- **构建时间**: ~18秒
- **部署时间**: ~10秒
- **搜索响应**: < 50ms

---

## 🎯 最佳实践

---

### 一、VScode 编辑器

- 使用  vscode:launch、vscode:task、vscode 插件，实现与WorldTourCasino 项目融合
- .vscode 同步,

---

### 二、markdown 编辑器

- 推荐使用 vscode 插件：

  ![1758077225108](/assets/1758120878197_7fc81ffc.png)

---

### 三、一键同步

- #### 本地自动更新：

  WorldTourCasino 更新、分支检出时，触发 Git-Hooks ，自动更新 docs：
- #### 一键操作:

  1. 点击 vscode:launch:【文档-同步】一键同步（智能、双向）
  2. GitHub Pages 自动部署
     **触发方式**：推送到 main 分支自动部署
     **部署耗时**：约 40 秒（Build 18s + Deploy 10s）
     **访问地址**：https://zhaoheng666.github.io/WTC-Docs/
     **查看进度**：[Actions](https://github.com/zhaoheng666/WTC-Docs/actions)
- #### 一键上传 Google Drive

  1. 点击 vscode:launch:【工具】上传到 Google Drive
  2. [查看手册](/工具/vscode/google-drive-upload)
     Markdown 文件自动转 PDF;
     Google Drive 一次认证；
     可指定 Google Drive 目录；

---

### 四、📝 文档管理

#### 新增、删除

- docs 目录即为文档分类目录；
- 自动映射到侧边栏；
- 支持目录多级嵌套；
- 建议子目录标配 index.md;  空目录侧边栏不显示、无法提交 git
- 及时提交、推送，以避免冲突；
  WorldTourCasino 项目 push 前触发钩子，检查、提醒 docs 项目是否有未提交、未推送的变更

#### 文档规范

- **命名**：中文或英文小写，避免特殊字符，推荐使用-连接符（区分于主项目命名风格 [查看详情](/工具/vscode/vscode环境工具开发规范)）
- **格式**：标准 Markdown 语法过于复杂的进阶 md 语法需要额外增加插件支持；
- **软换行**：使用反斜杠
- **提交**：文档提交日志使用 `docs:` 前缀

---

### 五、侧边栏配置

通过 `.vitepress/sidebar.mjs` 控制：

- **目录排序**：`directoryOrder` 配置显示顺序
- **忽略文件**：`ignoreList` 屏蔽特定文件
- **名称映射**：`specialCases` 定义友好名称

---

### 六、🔧 故障排除

- **环境问题**：运行 `npm run init` 自动修复
- **构建失败**：查看 `/tmp/vitepress-build.log`
- **图片问题**：确保运行了 `npm run build`
- **GitHub Actions**：检查 `gh auth status`
- **Mac ARM64**：`npm run init` 会自动处理

---

### 七、⚠️ 注意事项

- 新增/删除文档，预览服务可能延迟，可手动重启服务
- VS Code 中找到运行中任务：start-local-server，按 `r` 可重启服务
