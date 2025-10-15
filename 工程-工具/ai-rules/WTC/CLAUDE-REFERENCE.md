# CLAUDE-REFERENCE

**WorldTourCasino 项目综合参考文档**

本文档提供项目架构概览和快速参考。**仅供查阅，不会自动加载**。

详细规则请查看主项目 [CLAUDE.md](https://github.com/zhaoheng666/WorldTourCasino/blob/classic_vegas/CLAUDE.md) 和规则索引。

---

## 📚 规则目录结构

AI 规则文件按项目分类存储：

1. **shared/** - 通用规则（所有项目适用）
2. **WTC/** - 主项目规则
3. **docs/** - docs 子项目规则
4. **extensions/** - extensions 子项目规则

**完整索引**: `docs/工程-工具/ai-rules/`

**注意**: 这是文件目录结构，不是加载机制。关于三层规则架构（第一层内联/第二层外部/第三层 Slash Commands），请查看主项目 `CLAUDE.md` 的"规则维护"章节

| 子项目 | 路径 | 规则目录 |
|--------|------|---------|
| 主项目 | `.` | `docs/工程-工具/ai-rules/WTC/` |
| docs | `docs/` | `docs/工程-工具/ai-rules/docs/` |
| extensions | `vscode-extensions/` | `docs/工程-工具/ai-rules/extensions/` |

---

## 🚀 快速参考

### 核心构建命令

**本地开发**:
```bash
scripts/build_local_oldvegas.sh    # CV - Classic Vegas
scripts/build_local_doublehit.sh   # DH - Double Hit
scripts/build_local_doublex.sh     # DHX - Double X
scripts/build_local_vegasstar.sh   # VS - Vegas Star
npm run lint                        # ES5 代码检查
```

**测试部署**:
```bash
scripts/deploy_fb_alpha_normal.sh  # Facebook 测试版
scripts/deploy_fb_alpha_dynamic.sh # Facebook 折扣测试版
```

**生产部署**（需先升级 resource_dirs.json 版本号）:
```bash
scripts/sync_flavor.sh             # 同步风格文件
scripts/gen_res_list.sh            # 生成资源列表
scripts/build_fb.sh                # Facebook 版本
scripts/build_native.sh            # 原生版本
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
├── src/                   # 5,762+ 共享 JS 文件
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

详见: [专业术语表](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/WTC/terminology)

### VS Code 集成

- `.vscode/tasks.json` - 100+ 自动化任务
- VS Code 扩展生态：
  - `wtc-docs-server` - 文档服务器管理
  - `wtc-local-server` - 本地开发服务器
  - `wtc-toolbars` - 工具栏快捷操作
  - `wtc-google-drive` - Google Drive 上传

详见: [extensions 子项目规则](http://localhost:5173/WTC-Docs/工程-工具/ai-rules/extensions)

---

## 🔧 开发工作流

### 添加功能

1. 检查当前分支和风格
2. 修改代码（`src/` 或 `res_*/flavor/`）
3. 运行构建：`scripts/build_local_[flavor].sh`
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
