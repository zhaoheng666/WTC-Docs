# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

WorldTourCasino 技术文档系统，基于 VitePress 构建，自动部署到 GitHub Pages。

- **访问地址**：https://zhaoheng666.github.io/WTC-Docs/
- **基础路径**：`/WTC-Docs/`
- **开发端口**：5173（固定）

## 快速参考

### 常用命令

```bash
npm run init   # 初始化环境（首次使用或修复问题）
npm run dev    # 启动开发服务器
npm run build  # 本地构建测试
npm run sync   # 一键同步（构建→测试→提交→推送→部署）
npm run status # 检查状态
```

### 核心配置文件

- `.vitepress/config.mjs` - VitePress 主配置
- `.vitepress/sidebar.mjs` - 自动生成侧边栏
- `.github/workflows/deploy.yml` - GitHub Actions 部署
- `.vitepress/scripts/` - 自动化脚本目录

## 文档索引

### 项目文档
- **项目总览**：[README.md](./README.md) - 特性、结构、使用方法
- **技术架构**：[技术文档.md](./技术文档.md) - 构建流程、图片处理、同步机制
- **工作规范**：[工作规范.md](./工作规范.md) - 编写规范、命名规范

### 分类文档
- **原生平台**：`native/` 目录
- **工程工具**：`工程-工具/` 目录
- **故障排查**：`故障排查/` 目录
- **团队成员**：`成员/` 目录
- **关卡系统**：`关卡/` 目录
- **活动系统**：`活动/` 目录
- **协议相关**：`协议/` 目录
- **其他文档**：`其他/` 目录

## 关键特性说明

### 自动化脚本
所有脚本位于 `.vitepress/scripts/`：
- `init.sh` - 环境初始化
- `dev.sh` - 开发服务器（自动处理端口冲突）
- `build.sh` - 构建脚本（包含图片处理）
- `sync.sh` - 一键同步工作流
- `image-processor.js` - 图片自动处理
- `generate-stats.js` - 统计生成

### 图片处理
- 自动下载外部图片到 `public/assets/`
- 命名格式：`文件路径_哈希值.扩展名`
- 自动更新 Markdown 中的引用
- 构建时清理未使用的图片

### 搜索优化
- 使用 Intl.Segmenter 实现中文分词
- 标题权重高于正文
- 支持模糊匹配

### 日志位置
- `/tmp/vitepress-build.log` - 构建日志
- `/tmp/image-processor.log` - 图片处理日志
- `/tmp/sync-build.log` - 同步日志

## 开发注意事项

### Git 工作流
- Markdown 文件变更提交使用 `docs:` 前缀
- 推送到 main 分支自动触发部署
- 构建时间 ~18秒，部署时间 ~10秒

### 常见问题快速解决
- **端口占用**：`dev.sh` 会自动终止占用进程
- **图片未清理**：运行 `npm run build` 重新处理
- **构建失败**：查看 `/tmp/vitepress-build.log`
- **同步冲突**：`sync.sh` 自动尝试 rebase/merge

## 相关链接

- [VitePress 文档](https://vitepress.qzxdp.cn/)
- [GitHub 仓库](https://github.com/zhaoheng666/WTC-Docs)
- [GitHub Actions](https://github.com/zhaoheng666/WTC-Docs/actions)