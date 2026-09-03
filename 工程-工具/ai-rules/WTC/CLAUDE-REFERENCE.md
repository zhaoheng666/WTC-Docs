# CLAUDE-REFERENCE

**WorldTourCasino 项目综合参考文档**

本文档提供项目架构概览和快速参考。**仅供查阅，不会自动加载**。

现行共享规则与条件路由请查看主项目 `AGENTS.md`；`CLAUDE.md` 是指向它的
符号链接。本文档仅是按需项目参考，不是当前仓库状态的权威来源。

---

## 📚 规则目录结构

AI 规则文件按项目分类存储：

1. **shared/** - 通用规则（所有项目适用）
2. **WTC/** - 主项目规则
3. **docs/** - docs 子项目规则
4. **extensions/** - extensions 子项目规则

**完整索引**: `docs/工程-工具/ai-rules/`

**注意**: 这是文件目录结构，不是加载机制。当前分层见
[项目规则与基础上下文维护](/工程-工具/ai-rules/shared/rule-maintenance)。

| 子项目 | 路径 | 规则目录 |
|--------|------|---------|
| 主项目 | `.` | `docs/工程-工具/ai-rules/WTC/` |
| docs | `docs/` | `docs/工程-工具/ai-rules/docs/` |
| extensions | `vscode-extensions/` | `docs/工程-工具/ai-rules/extensions/` |

---

## 🚀 快速参考

### 核心构建命令

**本地开发**（从 `scripts/` 目录执行）:
```bash
cd scripts
./build_local_oldvegas.sh    # CV - Classic Vegas
./build_local_doublehit.sh   # DH - Double Hit
./build_local_doublex.sh     # DHX - Double X
./build_local_vegasstar.sh   # VS - Vegas Star
```

主项目根目录下使用 `npm run lint` 执行 ES5 代码检查。验证本地构建时，只检查命令退出状态
以及有界的 error/warning 输出；不读取或解析生成的 `game.js`。

**测试部署**（从 `scripts/` 目录执行，并传入目标资源目录）:
```bash
cd scripts
./deploy_fb_alpha_normal.sh <resPath>  # Facebook 测试版
./deploy_fb_alpha_dynamic.sh <resPath> # Facebook 折扣测试版
```

**生产部署**（从 `scripts/` 目录执行；发布前按对应流程更新资源版本）:
```bash
cd scripts
./sync_flavor.sh <resPath>   # 同步风格文件
./gen_res_list.py <resPath>  # 生成资源列表
./build_fb.sh <resPath>      # Facebook 版本
./build_native.sh <resPath>  # 原生版本
```

### 文档子项目

```bash
cd docs
npm run dev    # 启动服务器 (http://localhost:5173/WTC-Docs/)
npm run build  # 构建文档
npm run sync   # 同步到 GitHub Pages (https://zhaoheng666.github.io/WTC-Docs/)
```

---

## 📦 项目架构

### 技术栈

- **核心引擎**: Cocos2d-html5 JavaScript 游戏引擎
- **开发语言**: ES5 JavaScript（强制严格模式）
- **模块系统**: Browserify
- **构建系统**: Bash + Python 脚本

### 目录结构

```
WorldTourCasino/
├── src/                   # 共享 JS 文件
├── res_*/                 # 风格特定资源
│   ├── res_oldvegas/      # CV - Classic Vegas
│   ├── res_doublehit/     # DH - Double Hit
│   ├── res_vegasstar/     # VS - Vegas Star
│   └── res_doublex/       # DHX - Double X
├── scripts/               # 构建和部署脚本
├── libZenSDK/             # SDK 中间件（子仓库）
├── frameworks/            # Cocos2d 引擎（子仓库）
├── docs/                  # 文档子项目（独立仓库）
├── vscode-extensions/     # 扩展子项目（独立仓库）
└── publish/               # 构建输出
```

### 风格系统

- **Flavor**: 基于同一代码库的不同品牌版本
  - CV/cv - Classic Vegas (res_oldvegas/)
  - DH/dh - Double Hit (res_doublehit/)
  - DHX/dhx - Double X (res_doublex/)
  - VS/vs - Vegas Star (res_vegasstar/)
- **共享代码**: `src/` 目录
- **独立资源**: `res_*/` 目录
- **版本控制**: `resource_dirs.json` (debug/release)

详见: [专业术语表](/工程-工具/ai-rules/WTC/terminology)

### VS Code 集成

- `.vscode/tasks.json` - 100+ 自动化任务
- VS Code 扩展生态：
  - `wtc-docs-server` - 文档服务器管理
  - `wtc-local-server` - 本地开发服务器
  - `wtc-toolbars` - 工具栏快捷操作
  - `wtc-google-drive` - Google Drive 上传

详见: [extensions 子项目规则](/工程-工具/ai-rules/extensions/extension-dev)

---

## 🔧 开发工作流

### 添加功能

1. 检查当前分支和风格
2. 修改代码（`src/` 或 `res_*/flavor/`）
3. 进入 `scripts/` 并运行 `./build_local_[flavor].sh`
4. 浏览器测试
5. 代码检查：`npm run lint`

### 更新资源

1. 修改 `res_*/` 目录资源
2. 更新清单：`scripts/gen_res_list.py`
3. 升级版本号（如需要）：`resource_dirs.json`
4. 本地构建并测试

---

## 🔍 故障排查

**重要**: 先查阅 [故障排查文档](https://zhaoheng666.github.io/WTC-Docs/故障排查/)

---

**最后更新**: 2025-10-14
**维护者**: WorldTourCasino Team
