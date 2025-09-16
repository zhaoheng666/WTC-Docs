# Google Drive 文档上传工具

## 概述

这是一个集成在 VS Code 中的 Google Drive 文件上传工具，支持一键上传文件到指定的 Google Drive 文件夹，特别优化了 Markdown 文件的处理。

## 主要特性

### 核心功能
- **一键上传** - VS Code 任务集成，右键即可上传当前文件
- **Markdown 转 PDF** - 自动将 Markdown 转换为 PDF，完美支持中文
- **图片嵌入** - 自动将 Markdown 中引用的本地图片嵌入 PDF
- **智能命名** - 按照配置的模板自动重命名文件
- **文件覆盖** - 同名文件自动覆盖，避免重复
- **多文件夹支持** - 可配置多个上传目标，动态选择

### 文件命名模板
默认模板：`Q{quarter}'`{year}-Slots-{fileName}-程序`

变量说明：
- `{quarter}` - 当前季度（1-4）
- `{year}` - 年份后两位（如 25 代表 2025）
- `{fileName}` - 原始文件名（不含扩展名）

示例：
- 输入：`组内程序会.md`
- 输出：`Q3'25-Slots-组内程序会-程序.pdf`

## 快速使用

### 方法一：VS Code 任务
1. 打开要上传的文件
2. 按 `Cmd+Shift+P` (Mac) 或 `Ctrl+Shift+P` (Windows)
3. 选择 `Tasks: Run Task`
4. 选择 `upload_to_google_drive`
5. 如有多个文件夹，选择目标文件夹
6. 等待上传完成

### 方法二：命令行
```bash
# 上传 Markdown 文件（会转换为 PDF）
node .vscode/google_drive/upload-task.js your-file.md

# 直接上传其他文件
node .vscode/google_drive/upload-task.js your-file.zip
```

## 初始设置

### 1. 获取 Google API 凭据

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建新项目或选择现有项目
3. 启用 Google Drive API：
   - 在左侧菜单选择"API 和服务" > "库"
   - 搜索 "Google Drive API"
   - 点击启用
4. 创建凭据：
   - 选择"API 和服务" > "凭据"
   - 点击"创建凭据" > "OAuth 客户端 ID"
   - 应用类型选择"桌面应用"
   - 输入名称（如 "VS Code Upload"）
5. 下载凭据 JSON 文件
6. 重命名为 `credentials.json` 并保存到 `.vscode/google_drive/` 目录

### 2. 配置文件说明

首次运行任务时会自动创建 `uploadConfig.json`，格式如下：

```json
{
  "folders": {
    "文件夹名称1": "Google Drive 文件夹 ID",
    "文件夹名称2": "Google Drive 文件夹 ID"
  },
  "fileNameTemplate": {
    "enabled": true,
    "template": "Q{quarter}'`{year}-Slots-{fileName}-程序",
    "useOriginalExtension": true,
    "quarterMap": {
      "1": "Q1", "2": "Q1", "3": "Q1",
      "4": "Q2", "5": "Q2", "6": "Q2",
      "7": "Q3", "8": "Q3", "9": "Q3",
      "10": "Q4", "11": "Q4", "12": "Q4"
    }
  }
}
```

### 3. 获取 Google Drive 文件夹 ID

1. 在浏览器打开目标 Google Drive 文件夹
2. 查看地址栏 URL：`https://drive.google.com/drive/folders/[文件夹ID]`
3. 复制最后一部分作为文件夹 ID

## 文件处理规则

### Markdown 文件 (.md, .markdown)
1. 自动转换为 PDF
2. 嵌入所有引用的本地图片
3. 优化中文显示和换行
4. 应用专业的排版样式

### 其他文件
- 直接上传原始文件
- 支持所有常见文件格式

## 高级配置

### 添加新的文件夹
编辑 `uploadConfig.json`：
```json
"folders": {
  "现有文件夹": "xxx",
  "新文件夹": "新的文件夹ID"
}
```

### 自定义命名模板
修改 `uploadConfig.json` 中的 `template`：
```json
"template": "自定义-{year}-{fileName}"
```

### 禁用文件重命名
设置 `enabled` 为 `false`：
```json
"fileNameTemplate": {
  "enabled": false
}
```

## 故障排除

### 常见问题

**Q: 首次运行提示缺少凭据文件**
A: 按照上述步骤获取 Google API 凭据

**Q: 上传时提示未配置文件夹 ID**
A: 编辑 `uploadConfig.json`，将占位符替换为实际的文件夹 ID

**Q: PDF 转换失败**
A: 确保系统安装了 Chrome、Edge 或 Brave 浏览器

**Q: 认证失败或 token 过期**
A: 删除 `token.json` 文件后重新运行，会自动重新认证

**Q: 中文显示乱码**
A: 已优化中文支持，如仍有问题请检查原始 Markdown 文件编码（应为 UTF-8）

### 重置配置
如需重新配置，删除以下文件：
- `uploadConfig.json` - 重置文件夹配置
- `token.json` - 重置认证
- `credentials.json` - 需要重新下载凭据

## 技术实现

### 文件结构
```
.vscode/google_drive/
├── README.md                      # 详细文档
├── upload-task.js                 # VS Code 任务入口
├── upload-markdown-with-images.js # Markdown 处理核心
├── upload-to-drive-auto.js       # 通用文件上传
├── upload-with-selection.js      # 带文件夹选择的上传
├── common.js                      # 公共模块
├── uploadConfig.json             # 用户配置（gitignore）
├── credentials.json              # Google API 凭据（gitignore）
└── token.json                    # OAuth token（gitignore）
```

### 主要依赖
- `googleapis` - Google API 客户端
- `marked` - Markdown 解析
- `puppeteer-core` - PDF 生成（使用系统 Chrome）

### 安全性
- 使用 OAuth 2.0 认证
- Token 自动刷新
- 敏感文件已添加到 .gitignore