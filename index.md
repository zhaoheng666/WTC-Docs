# WorldTourCasino 文档中心

## 🚀 快速开始

```bash
npm run init    # 初始化环境（首次使用）
npm run dev     # 启动开发服务器
npm run sync    # 一键同步文档
```

访问 http://localhost:5173 查看文档

## 📚 在线访问

- **在线文档**：https://zhaoheng666.github.io/WTC-Docs/
- **GitHub 仓库**：https://github.com/zhaoheng666/WTC-Docs
- **查看进度**：[GitHub Actions](https://github.com/zhaoheng666/WTC-Docs/actions)

## ✨ 核心功能

### 🔍 智能搜索
- **快捷键**：`Cmd/Ctrl + K`
- **中文优化**：专业分词算法
- **模糊匹配**：支持拼写容错
- **实时预览**：输入即显示结果

### 📸 图片自动处理
- **直接插入**：无需特殊操作
- **自动下载**：外部图片本地化
- **统一管理**：集中存储到 assets
- **防盗链解决**：Gitee 图片自动处理

### 🔄 一键同步
```bash
npm run sync    # 自动完成所有操作
```
- ✅ 处理所有图片
- ✅ 构建测试
- ✅ 智能提交
- ✅ 推送部署
- ✅ 监控状态
- ✅ 完成通知

## 📝 编写文档

### 创建文档
1. 在相应目录创建 `.md` 文件
2. 使用标准 Markdown 语法
3. 直接插入图片，无需管理路径

### 目录结构
```
docs/
├── 成员/           # 成员相关
├── 工具/           # 工具使用
├── 故障排查/       # 问题解决
├── 关卡/           # 游戏关卡
├── 活动/           # 活动相关
├── 其他/           # 其他文档
└── 协议/           # 协议文档
```

### 插入图片示例
```markdown
![本地图片](./images/screenshot.png)
![Gitee图片](https://gitee.com/xxx/xxx.png)
![外部图片](https://example.com/image.jpg)
```

## 🛠 高级功能

### 侧边栏配置
通过 `.vitepress/sidebar.mjs` 控制：
- **目录排序**：`directoryOrder` 配置
- **忽略文件**：`ignoreList` 设置
- **名称映射**：`specialCases` 定义

### Google Drive 集成
一键上传文档，Markdown 自动转 PDF
[查看详情](/工具/vscode/google-drive-upload)

### 文档规范
- **命名**：中文或英文，避免特殊字符
- **格式**：标准 Markdown 语法
- **提交**：使用 `docs:` 前缀

## 💡 使用技巧

### 开发模式
- 文档修改自动热更新
- 新增/删除文档需重启服务
- VS Code 中按 `h` 然后 `r` 重启

### 常用命令
| 命令 | 说明 | 场景 |
|------|------|------|
| `npm run init` | 初始化环境 | 首次使用/修复问题 |
| `npm run dev` | 开发模式 | 编写文档 |
| `npm run build` | 构建测试 | 验证文档 |
| `npm run sync` | 一键同步 | 提交部署 |

## 🆘 常见问题

### 环境问题？
```bash
npm run init    # 一键修复
```

### 图片不显示？
- 开发模式会自动处理
- 运行 `npm run sync` 确保处理

### 构建失败？
```bash
npm run build   # 查看具体错误
```

## 📊 项目状态

- **文档数量**：查看 public/stats.json
- **部署状态**：[GitHub Actions](https://github.com/zhaoheng666/WTC-Docs/actions)
- **在线地址**：https://zhaoheng666.github.io/WTC-Docs/

## 📄 更多文档

- [脚本使用说明](./SCRIPTS.md)
- [图片处理系统](./IMAGE_HANDLING.md)
- [技术实现文档](./README.md)
- [开发环境配置](/其他/VSCode 编辑器前端开发环境.md)

---

> 💡 **提示**：使用 `npm run sync` 一键完成所有操作，无需记住复杂命令！