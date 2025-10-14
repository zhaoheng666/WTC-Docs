# CLAUDE.md

**WorldTourCasino 主项目 AI 上下文文件**

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 📚 AI 规则索引

**所有规则文档位于**: `docs/工程-工具/ai-rules/`

### 通用规则 (shared/)

适用于主项目和所有子项目

- [Git 提交类型参考](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/shared/git-commit-types-reference) - chore/feat/fix/docs...
- [文件路径链接规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/shared/file-path-links-rules) - 转 GitHub 链接规则
- [文档编写标准](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/shared/doc-writing-standards) - Markdown/VitePress 规范

### 主项目规则 (WTC/)

仅适用于 WorldTourCasino 主项目

- [专业术语表](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/terminology-glossary) - 项目专有概念和术语
- [Git 提交规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/git-commit-rules) - 主项目提交确认流程
- [Shell 脚本标准](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/shell-script-standards) - zsh 规范
- [配置文件同步规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/config-sync-rules) - settings.json ↔ workspace 同步
- [文档记录指南](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/documentation-guide) - 如何使用 docs 记录

### docs 子项目规则 (docs/)

仅适用于 docs 子项目

- [VitePress 开发标准](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/vitepress-dev-standards) - VitePress 特定规范
- [图片处理参考](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/image-processing-reference) - 自动图片处理
- [链接处理规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/link-processing-rules) - 相对链接转绝对 HTTP 链接 ⚠️ **强制**
- [自动化提交规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/docs/auto-commit-rules) - docs 自动化提交

### extensions 子项目规则 (extensions/)

仅适用于 extensions 子项目

- [扩展开发标准](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/extensions/extension-dev-standards) - TypeScript/package.json 规范
- [扩展激活规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/extensions/activation-rules) - 只在 WTC 项目激活
- [符号链接安装指南](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/extensions/symlink-installation-guide) - 扩展安装机制

### 新增规则指南

**判断规则分类**:

1. **通用规则 (shared/)**: 主项目和所有子项目都适用
   - 例如：Git 提交类型、文件路径链接、文档编写规范

2. **子项目规则 (WTC/docs/extensions/)**: 特定项目/子项目适用
   - 每个子项目在 `ai-rules/` 下有独立目录
   - 包括：开发规范、工作流程、专业术语等

**新增规则流程**:
1. 确定规则分类（shared 还是特定子项目）
2. 在 `docs/工程-工具/ai-rules/` 对应目录创建 .md 文件
3. 更新本文件（CLAUDE.md）的规则索引

**注意**: 专业术语、概念解释也属于规则的一部分，应放在对应子项目的规则目录中

---

## 🎯 子项目索引

| 子项目 | 路径 | 规则目录 | 说明 |
|--------|------|---------|------|
| 主项目 | `.` | `docs/工程-工具/ai-rules/WTC/` | WorldTourCasino 游戏主项目 |
| docs | `docs/` | `docs/工程-工具/ai-rules/docs/` | 文档系统（VitePress） |
| extensions | `vscode-extensions/` | `docs/工程-工具/ai-rules/extensions/` | VS Code 扩展生态 |

---

## 🚀 快速参考

### 核心构建命令

#### 本地开发

```bash
# 构建特定风格版本
scripts/build_local_oldvegas.sh    # CV - Classic Vegas 版本
scripts/build_local_doublehit.sh   # DH - Double Hit 版本
scripts/build_local_doublex.sh     # DHX - Double X 版本
scripts/build_local_vegasstar.sh   # VS - Vegas Star 版本
scripts/build_local_all.sh         # 所有版本

# 构建后运行
open index.html  # 在浏览器中打开测试
```

#### 测试与部署

```bash
# 部署测试版本
scripts/deploy_fb_alpha_normal.sh     # Facebook 测试版
scripts/deploy_fb_alpha_dynamic.sh    # Facebook 折扣测试版

# 生产环境部署（需先在 resource_dirs.json 中升级版本号）
scripts/sync_flavor.sh              # 同步风格文件（首先运行）
scripts/gen_res_list.sh             # 生成资源列表
scripts/build_fb.sh                 # 构建 Facebook 版本
scripts/build_native.sh             # 构建原生版本
```

#### 代码质量检查

```bash
npm run lint                        # 运行 ESLint（ES5 严格模式）
```

### 文档子项目快速命令

```bash
cd docs
npm run dev                         # 启动文档服务器（固定端口 5173）
npm run build                       # 构建文档
npm run sync                        # 同步文档到 GitHub Pages
```

**文档访问地址**:
- 本地: http://localhost:5173/WTC-Docs/
- 线上: https://zhaoheng666.github.io/WTC-Docs/

---

## 📦 项目架构

### 多风格赌场游戏系统

- **核心引擎**: Cocos2d-html5 JavaScript 游戏引擎
- **开发语言**: ES5 JavaScript（强制严格模式）
- **模块系统**: Browserify 进行打包
- **构建系统**: 自定义 bash 脚本配合 Python 工具

### 关键目录结构

```
WorldTourCasino/
├── src/                        # 项目核心代码（5,762+ JS 文件）- 所有风格共享
├── res_*/                      # 风格特定的资源和配置
│   ├── res_oldvegas/           # CV - Classic Vegas（主要工作分支）
│   ├── res_doublehit/          # DH - Double Hit
│   ├── res_vegasstar/          # VS - Vegas Star
│   └── res_doublex/            # DHX - Double X
├── scripts/                    # 构建和部署自动化脚本
├── libZenSDK/                  # SDK 中间件（子仓库）
├── frameworks/                 # Cocos2d 引擎框架（子仓库）
│   ├── cocos2d-html5/          # Cocos2d-html5 引擎
│   └── cocos2d-x/              # Cocos2d-x 引擎
├── docs/                       # 文档子项目（独立仓库）
├── vscode-extensions/          # VS Code 扩展子项目（独立仓库）
├── publish/                    # 发布中间目录（构建输出）
├── assets_config/              # Native 资源 manifest 文件
├── native_bundle_res/          # Native 打包替换文件
├── jenkins_tools/              # Jenkins CI/CD 脚本
├── .webpcache/                 # 图片压缩缓存（WebP）
└── res/                        # 未使用（历史遗留）
```

### 风格系统架构

详见: [专业术语表 - Flavor System](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/terminology-glossary.md#多风格系统flavor-system)

### 资源管理

- **版本控制**: 通过 `resource_dirs.json` 管理（debug/release 版本）
- **动态加载**: 活动可以延迟加载
- **CDN 部署**: 自动化部署和缓存失效处理

---

## 🛠️ 开发指南

### 构建前置条件

```bash
npm install browserify@11.2.0 -g
npm install uglifyjs -g
ulimit -n 65535  # 处理大量文件时需要
```

### 风格切换工作流

1. 当前分支通常针对一个风格（查看 git status）
2. 切换风格时运行 `scripts/sync_flavor.sh`
3. 资源变更后必须重新生成资源列表

### VS Code 集成

- **任务**: `.vscode/tasks.json` 中有 100+ 个自动化任务
- **扩展生态**: 详见 [extensions 子项目规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/extensions)
  - `wtc-docs-server` - 文档服务器管理
  - `wtc-local-server` - 本地开发服务器
  - `wtc-toolbars` - 工具栏快捷操作
  - `wtc-google-drive` - Google Drive 上传
- **自动化**:
  - 打开项目时通过 `onEnter.sh` 自动安装扩展
  - 重载前通过 `cleanup-services.sh` 清理服务
  - 服务状态通过扩展状态栏实时监控

### 重要文件

详见: [专业术语表 - 重要文件](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/terminology-glossary.md#重要文件)

### Git 工作流

- **主分支**: `classic_vegas`
- **功能分支**: `classic_vegas_cvs_v*_subject_*`
- **提交格式**: `cv：关卡X [描述]`

---

## 🔧 常用工作流程

### 添加新功能

1. 检查当前分支和风格上下文
2. 修改 `src/`（共享）或 `res_*/flavor/`（风格特定）中的源码
3. 运行本地构建: `scripts/build_local_[flavor].sh`
4. 在浏览器中测试
5. 运行代码检查: `npm run lint`

### 更新资源

1. 在相应的 `res_*/` 目录中添加/修改资源
2. 运行 `scripts/gen_res_list.py` 更新清单
3. 如需要，在 `resource_dirs.json` 中升级版本号
4. 本地构建并测试

### 调试

- Browserify 生成 source maps 用于调试
- 检查控制台的 Cocos2d 初始化错误
- 资源加载问题通常与清单不匹配有关

---

## 🔍 故障排查

**重要**：遇到问题时，请先查阅 `docs/故障排查/` 目录下的文档，很多问题已有解决方案。

### 快速入口

- [故障排查索引](https://zhaoheng666.github.io/WTC-Docs/故障排查/) - 在线文档
- [VSCode 扩展问题](https://zhaoheng666.github.io/WTC-Docs/故障排查/vscode-扩展工作区兼容性问题.html)
- 本地文档: [docs/故障排查/](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/docs/故障排查)

---

**最后更新**: 2025-10-14
**维护者**: WorldTourCasino Team
