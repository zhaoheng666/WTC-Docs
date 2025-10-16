# .vitepress/scripts 目录重构方案

## 当前问题

`.vitepress/scripts` 目录组织混乱：
- JS 脚本和 Shell 脚本混在一起
- 自动调用脚本和手动工具脚本没有区分
- 缺少清晰的层次结构
- 已废弃的脚本（如 `*-old.js`）未清理

## 脚本分类（基于调用关系分析）

### 一、NPM Scripts 入口（6个）

这些是用户直接调用的入口脚本：

| NPM 命令 | Shell 脚本 | 用途 |
|---------|-----------|------|
| `npm run init` | `init.sh` | 环境初始化和检查 |
| `npm run dev` | `dev.sh` | 启动开发服务器 |
| `npm run build` | `build.sh` | 构建文档 |
| `npm run sync` | `sync.sh` | 同步到 GitHub Pages |
| `npm run status` | `status.sh` | 显示 Git 状态 |
| `npm run convert-docx` | `convert-docx.sh` | DOCX 转 Markdown |

### 二、自动化处理器（被 build.sh 调用）

这些 JS 脚本在构建流程中自动执行：

| 脚本 | 调用位置 | 用途 |
|------|---------|------|
| `fix-problematic-filenames.js` | build.sh:28 | 修复文件名特殊字符 |
| `image-processor.js` | build.sh:93 | 图片下载、重命名、清理 |
| `pdf-processor.js` | build.sh:158 | PDF 文件收集和处理 |
| `link-processor.js` | build.sh:190 | 链接格式转换 |
| `generate-directory-index.js` | build.sh:223 | 生成目录索引页 |

### 三、辅助脚本（被其他脚本调用）

| 脚本 | 被调用者 | 用途 |
|------|---------|------|
| `notify.sh` | sync.sh, convert-docx.sh | 系统通知 |
| `build-ci.sh` | GitHub Actions | CI 环境专用构建 |

### 四、手动工具（独立使用）

这些脚本不在自动化流程中，需要手动调用：

| 脚本 | 用途 | 调用方式 |
|------|------|---------|
| `image-duplicate-checker.js` | 检查重复图片 | `node .vitepress/scripts/tools/image-duplicate-checker.js` |
| `rename-existing-images.js` | 批量重命名图片 | `node .vitepress/scripts/tools/rename-existing-images.js` |
| `force-process-images.js` | 强制处理图片 | `node .vitepress/scripts/tools/force-process-images.js` |
| `convert-to-absolute-paths.js` | 转换链接格式 | `node .vitepress/scripts/tools/convert-to-absolute-paths.js` |
| `comment-missing-images.sh` | 注释缺失图片 | `zsh .vitepress/scripts/tools/comment-missing-images.sh` |
| `comment-missing-images.py` | 注释缺失图片（Python版） | `python3 .vitepress/scripts/tools/comment-missing-images.py` |

### 五、已废弃（待删除）

| 脚本 | 原因 | 替代方案 |
|------|------|---------|
| `image-processor-old.js` | 已被新版本替代 | 使用 `image-processor.js` |
| `migrate-links-to-vitepress-standard.js` | 一次性迁移工具，已完成 | 使用 `convert-to-absolute-paths.js` |
| `fix-rollup.sh` | 已不需要 | - |
| `update-content-titles.js` | 未被调用，功能不明 | 待确认 |
| `rename-files.js` | 未被调用，功能不明 | 待确认 |
| `sync 优化方案` | 文本文件，非脚本 | 移到文档 |

---

## 推荐的新目录结构

```
.vitepress/scripts/
├── README.md                          # 脚本使用说明
│
├── init.sh                            # npm run init
├── dev.sh                             # npm run dev
├── build.sh                           # npm run build
├── build-ci.sh                        # CI 环境构建（GitHub Actions）
├── sync.sh                            # npm run sync
├── status.sh                          # npm run status
├── convert-docx.sh                    # npm run convert-docx
│
├── lib/                               # 核心库（被 build.sh 等调用）
│   ├── fix-problematic-filenames.js   # 文件名修复
│   ├── image-processor.js             # 图片处理
│   ├── pdf-processor.js               # PDF 处理
│   ├── link-processor.js              # 链接处理
│   ├── generate-directory-index.js    # 目录索引
│   └── generate-stats.js              # 统计生成（CI专用）
│
├── utils/                             # 辅助工具（被其他脚本调用）
│   └── notify.sh                      # 系统通知
│
├── tools/                             # 手动工具（独立使用，一次性任务）
│   ├── image-duplicate-checker.js     # 图片去重检查
│   ├── rename-existing-images.js      # 批量重命名图片
│   ├── force-process-images.js        # 强制处理图片
│   ├── convert-to-absolute-paths.js   # 链接格式转换
│   ├── comment-missing-images.sh      # 注释缺失图片
│   └── comment-missing-images.py      # 注释缺失图片（Python）
│
└── archive/                           # 已废弃（待删除或参考）
    ├── image-processor-old.js
    ├── migrate-links-to-vitepress-standard.js
    ├── update-content-titles.js
    ├── rename-files.js
    ├── fix-rollup.sh
    └── sync\ 优化方案
```

**设计原则**：
- **顶层 Shell 脚本** - NPM 入口（6个）+ CI 构建（1个），用户/CI 直接调用
- `lib/` - 核心处理库（自动调用，用户不直接使用）
- `utils/` - 辅助工具（被其他脚本调用）
- `tools/` - 手动工具（一次性任务，手动调用）
- `archive/` - 归档目录

---

## 调用关系图

```
[用户]
  ├── npm run init      → init.sh
  │                       └── (环境检查和安装)
  │
  ├── npm run dev       → dev.sh
  │                       └── vitepress dev
  │
  ├── npm run build     → build.sh
  │                       ├── lib/fix-problematic-filenames.js
  │                       ├── lib/image-processor.js
  │                       ├── lib/pdf-processor.js
  │                       ├── lib/link-processor.js
  │                       ├── lib/generate-directory-index.js
  │                       └── vitepress build
  │
  ├── npm run sync      → sync.sh
  │                       ├── npm run build
  │                       ├── utils/notify.sh
  │                       └── git push
  │
  ├── npm run status    → status.sh
  │                       └── git status
  │
  └── npm run convert-docx → convert-docx.sh
                              ├── pandoc
                              ├── npm run build
                              └── utils/notify.sh

[GitHub Actions]
  └── deploy workflow   → build-ci.sh
                          └── npm run build

[手动工具]（独立使用，不在自动化流程中）
  ├── tools/image-duplicate-checker.js
  ├── tools/rename-existing-images.js
  ├── tools/force-process-images.js
  ├── tools/convert-to-absolute-paths.js
  ├── tools/comment-missing-images.sh
  └── tools/comment-missing-images.py
```

---

## 迁移步骤

### 阶段一：创建目录并移动文件

```bash
cd /Users/ghost/work/WorldTourCasino/docs/.vitepress/scripts

# 创建新目录
mkdir -p lib utils tools archive

# 移动核心处理库到 lib/
mv fix-problematic-filenames.js lib/
mv image-processor.js lib/
mv pdf-processor.js lib/
mv link-processor.js lib/
mv generate-directory-index.js lib/

# 移动辅助工具到 utils/
mv notify.sh utils/

# 移动手动工具到 tools/
mv image-duplicate-checker.js tools/
mv rename-existing-images.js tools/
mv force-process-images.js tools/
mv convert-to-absolute-paths.js tools/
mv comment-missing-images.sh tools/
mv comment-missing-images.py tools/

# 归档废弃脚本
mv image-processor-old.js archive/
mv migrate-links-to-vitepress-standard.js archive/
mv update-content-titles.js archive/
mv rename-files.js archive/
mv fix-rollup.sh archive/
mv "sync 优化方案" archive/

# 顶层保留（无需移动）：
# - init.sh, dev.sh, build.sh, build-ci.sh, sync.sh, status.sh, convert-docx.sh
```

### 阶段二：更新引用路径

**1. build.sh** - 更新处理器路径（5处修改）
```bash
# 修改所有处理器调用路径
node .vitepress/scripts/lib/fix-problematic-filenames.js
node .vitepress/scripts/lib/image-processor.js
node .vitepress/scripts/lib/pdf-processor.js
node .vitepress/scripts/lib/link-processor.js
node .vitepress/scripts/lib/generate-directory-index.js
```

**2. sync.sh 和 convert-docx.sh** - 更新 notify.sh 路径
```bash
# 修改 notify.sh 路径
bash "$SCRIPT_DIR/utils/notify.sh" --title "..." --message "..."
```

**3. init.sh** - 更新脚本权限设置
```bash
# 脚本权限设置更新
chmod +x .vitepress/scripts/*.sh
chmod +x .vitepress/scripts/utils/*.sh
chmod +x .vitepress/scripts/tools/*.sh
```

**4. package.json** - 无需修改（顶层脚本路径不变）
```json
{
  "scripts": {
    "init": "zsh .vitepress/scripts/init.sh",
    "dev": "zsh .vitepress/scripts/dev.sh",
    "build": "zsh .vitepress/scripts/build.sh",
    "sync": "zsh .vitepress/scripts/sync.sh",
    "status": "zsh .vitepress/scripts/status.sh",
    "convert-docx": "zsh .vitepress/scripts/convert-docx.sh"
  }
}
```

### 阶段三：验证和测试

```bash
# 1. 验证构建
npm run build

# 2. 验证开发服务器
npm run dev

# 3. 验证 DOCX 转换
npm run convert-docx "测试文件.docx"

# 4. 验证手动工具
node .vitepress/scripts/tools/image-duplicate-checker.js
```

---

## 优势

1. **顶层极简**
   - 仅保留 6 个 NPM 入口脚本
   - 用户直接调用，无需进目录

2. **职责明确**
   - `lib/` - 核心库（自动调用）
   - `utils/` - 辅助工具（被调用）
   - `tools/` - 手动工具（独立使用）
   - `archive/` - 废弃脚本（隔离）

3. **易于维护**
   - 清晰的三层结构：顶层入口 → lib/utils → archive
   - 新增处理器放 `lib/`
   - 新增工具放 `tools/`
   - 废弃脚本移 `archive/`

4. **改动最小**
   - package.json 无需修改
   - GitHub Actions 无需修改
   - 需修改路径：build.sh (5处)、sync.sh (2处)、convert-docx.sh (2处)、init.sh (1处)

---

**文档创建时间**: 2025-10-16
**分析依据**: package.json scripts 和脚本源码调用关系
**作者**: Claude Code
