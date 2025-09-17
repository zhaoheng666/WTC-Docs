# WorldTourCasino 文档中心

## 🕐最近更新

| 更新日期 | 文档                            | 最后提交                                  |
| -------- | ------------------------------- | ----------------------------------------- |
| 09-17    | 📋[index](/活动/index.md)          | docs: 更新 index                          |
| 09-17    | [README](/README.md)               | docs: 更新 README,统计仪表板 (含配置文件) |
| 09-17    | [index](/index.md)                 | docs: 更新 index,统计仪表板 (含配置文件)  |
| 09-17    | [index](/index.md)                 | docs: 更新 index                          |
| 09-17    | [index](/index.md)                 | docs: 更新文档 (新增        4, 修改       |
| 09-17    | [index](/index.md)                 | docs: 更新文档 (新增        1, 修改       |
| 09-17    | [index](/index.md)                 | docs: 更新文档 (新增        1, 修改       |
| 09-17    | [index](/index.md)                 | fix: 修复图片路径并改进同步脚本显示       |
| 09-17    | [index](/index.md)                 | docs: 更新文档 (新增        3, 修改       |
| 09-17    | [快速开始](/其他/隐藏/快速开始.md) | docs: 更新文档 (新增        3, 修改       |

## 🚀 快速访问

- **在线文档**：https://zhaoheng666.github.io/WTC-Docs/
- **技术实现**：[查看技术实现文档](/README)

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

## 🔄 同步机制

### 本地同步

通过 Git Hooks 自动同步：

- **文档仓库**：https://github.com/zhaoheng666/WTC-Docs
- **自动同步**：主项目 pull/checkout 时触发
- **手动更新**：`cd docs && git pull`

运行文档更新任务：

* **launch**：【文档】同步
* **task**：sync-docs

### GitHub Pages 自动部署

- **触发方式**：推送到 main 分支自动部署
- **部署耗时**：约 40 秒（Build 18s + Deploy 10s）
- **访问地址**：https://zhaoheng666.github.io/WTC-Docs/
- **查看进度**：[Actions](https://github.com/zhaoheng666/WTC-Docs/actions)

### Google Drive 上传工具

- 一键上传文档到 Google Drive，Markdown 文件自动转 PDF 后上传。[查看手册](/工具/vscode/google-drive-upload)

## 📝 文档管理

### 新增、删除分类目录

1. 在 docs 目录下增、删目录；
2. 自动映射到侧边栏；
3. 支持目录多级嵌套；
4. 建议子目录创建自己的 index.md;空目录侧边栏不显示、无法提交 git,另外
5. 及时提交、推送；

### 新增、删除文档

1. 在相应目录创建 `.md` 文件；
2. 仅支持 md 文件，其他文件类型自动忽略显示；
3. 自动映射到侧边栏；
4. 及时提交、推送；

### 文档规范

- **命名**：中文或英文小写，避免特殊字符，推荐使用-连接符（区分于主项目命名风格 [查看详情](/工具/vscode/vscode环境工具开发规范)）
- **格式**：标准 Markdown 语法过于复杂的进阶 md 语法需要额外增加插件支持；
- **软换行**：使用反斜杠
- **提交**：文档提交日志使用 `docs:` 前缀

### 侧边栏配置

通过 `.vitepress/sidebar.mjs` 控制：[查看手册](README)；

- **目录排序**：`directoryOrder` 配置显示顺序
- **忽略文件**：`ignoreList` 屏蔽特定文件
- **名称映射**：`specialCases` 定义友好名称

### 图床

- 无需额外图床，截图、图片直接按引用路径存放即可
- 不同 MD 编辑器、插件生成的图片目录有差异，assets、images等
- 提交同步时，会自动收集图片到 images/ 并修正文档引用
- 不支持远程图片

### markdown 编辑器

- 推荐使用 vscode 插件：
  ![1758077097119](./images/root/1758077097119.png)
- 其他 vscode 插件：按个人习惯自行选择；
- 第三方专用 markdown 编辑器：
  不推荐，需手动拷贝文档、引用资源到 docs 目录

## ⚠️ 注意事项

- 文档内容修改会自动热更新
- 新增/删除文档需重启服务
- VS Code 中找到 docs-server 任务，按 `h` 然后 `r` 可重启服务

  ![1758091570595](./images/root/1758091570595.png)
