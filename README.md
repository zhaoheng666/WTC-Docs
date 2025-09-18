# WorldTourCasino 文档系统

> 使用 VitePress 构建的技术文档系统，通过 GitHub Actions 自动部署到 GitHub Pages

## ✨ 系统特性

- 📝 **Markdown 驱动** - 专注内容创作
- 🔍 **智能中文搜索** - 基于 Intl.Segmenter 的专业分词
- 📸 **图片自动处理** - 解决防盗链，统一管理
- 🔄 **一键同步** - 自动构建、提交、部署
- 📱 **响应式设计** - 系统选择框交互，系统通知状态、结果

## 🛠 技术栈

- **框架**: VitePress 1.6.4
- **构建**: Vite + Vue 3
- **部署**: GitHub Pages + Actions
- **脚本**: Node.js + Bash

## 📝 命令参考

### 核心命令

| 命令             | 说明           | 使用场景                   |
| ---------------- | -------------- | -------------------------- |
| `npm run init`   | 初始化环境     | 首次使用或修复环境问题     |
| `npm run dev`    | 启动开发服务器 | 日常文档编写和预览         |
| `npm run sync`   | 一键同步       | 自动构建、提交、推送、部署 |
| `npm run build`  | 本地构建       | 测试构建是否成功           |

### 环境初始化

```bash
npm run init          # 自动检查和修复环境问题
```

自动处理：Node.js 依赖、GitHub CLI 配置、Git 中文路径、脚本权限、Mac ARM64 兼容性

## 📸 图片处理系统

**零操作，全自动** - 直接在 Markdown 中插入图片，系统自动处理

- 支持本地图片、Gitee 图片、外部链接
- 自动下载外部图片到 `public/assets/`
- 生成唯一文件名（时间戳_哈希值）
- 构建时自动更新所有引用

## 🔄 一键同步

`npm run sync` 执行完整工作流：

1. 处理所有图片（下载、重命名、更新引用）
2. 构建测试确保无错误
3. 自动生成提交信息
4. 推送并监控 GitHub Actions 部署
5. 完成后发送系统通知

## 🏗️ 项目结构

```
docs/
├── .vitepress/
│   ├── config.mjs          # VitePress 配置
│   ├── sidebar.mjs         # 侧边栏自动生成
│   ├── components/         # Vue 组件
│   └── scripts/            # 自动化脚本
│       ├── init.sh         # 环境初始化
│       ├── build.sh        # 本地构建
│       ├── sync.sh         # 同步脚本
│       └── image-processor.js # 图片处理
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions 配置
├── public/
│   ├── assets/            # 统一图片存储
│   └── stats.json         # 文档统计数据
└── 各文档目录/
```

## 🎯 最佳实践

- **文档编写**：按功能模块分类，使用清晰的中文命名
- **图片管理**：直接粘贴或拖拽，系统自动处理
- **提交规范**：`docs:` 文档更新、`feat:` 新功能、`fix:` 修复、`chore:` 配置

## 🔧 故障排除

- **环境问题**：运行 `npm run init` 自动修复
- **构建失败**：查看 `/tmp/vitepress-build.log`
- **图片问题**：确保运行了 `npm run build`
- **GitHub Actions**：检查 `gh auth status`
- **Mac ARM64**：`npm run init` 会自动处理

## 📊 性能指标

- **本地启动**: < 2秒
- **热更新**: < 100ms
- **构建时间**: ~18秒
- **部署时间**: ~10秒
- **搜索响应**: < 50ms

## 🔗 相关资源

- [快速开始](./快速开始) - 3分钟上手指南
- [在线文档](https://zhaoheng666.github.io/WTC-Docs/)
- [GitHub 仓库](https://github.com/zhaoheng666/WTC-Docs)
- [GitHub Actions](https://github.com/zhaoheng666/WTC-Docs/actions)
