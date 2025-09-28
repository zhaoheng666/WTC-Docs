# Git Hooks 重构方案

## 概述
为了提升项目组织结构的清晰度和可维护性，将 Git hooks 相关文件从 `.vscode/git-hooks/` 迁移到 `.vscode/scripts/git-hooks/` 目录下，使其与其他脚本保持一致的组织结构。

## 重构时间
2025-09-28

## 变更内容

### 1. 目录结构调整

**原目录结构**：
```
.vscode/
├── git-hooks/
│   ├── README.md
│   ├── install-hooks.sh
│   ├── pre-push
│   ├── post-checkout
│   └── post-merge
└── scripts/
    └── common/
        └── ui-interact.sh
```

**新目录结构**：
```
.vscode/
└── scripts/
    ├── common/
    │   └── notify-sys.sh (重命名自 ui-interact.sh)
    └── git-hooks/
        ├── README.md
        ├── install-hooks.sh
        ├── pre-push
        ├── post-checkout
        └── post-merge
```

### 2. 文件重命名
- `ui-interact.sh` → `notify-sys.sh`：更准确地反映其系统通知功能

### 3. 路径更新

#### install-hooks.sh
更新 hooks 源目录路径：
- 旧：`HOOKS_DIR="${PROJECT_ROOT}/.vscode/git-hooks"`
- 新：`HOOKS_DIR="${PROJECT_ROOT}/.vscode/scripts/git-hooks"`

#### post-checkout 和 post-merge
更新通知脚本路径：
- 旧：`source "${PROJECT_ROOT}/.vscode/scripts/common/ui-interact.sh"`
- 新：`source "${PROJECT_ROOT}/.vscode/scripts/common/notify-sys.sh"`

### 4. sync-docs.sh 更新
添加 Git hooks 安装检查，确保同步文档时 hooks 已正确安装：
```bash
# 检查并安装 git hooks
if [ ! -f "${PROJECT_ROOT}/.git/hooks/post-checkout" ] || [ ! -f "${PROJECT_ROOT}/.git/hooks/post-merge" ]; then
    echo "Git hooks 未安装，正在安装..."
    if [ -f "${PROJECT_ROOT}/.vscode/scripts/git-hooks/install-hooks.sh" ]; then
        bash "${PROJECT_ROOT}/.vscode/scripts/git-hooks/install-hooks.sh"
    fi
fi
```

## 重构优势

1. **统一的组织结构**：所有脚本集中在 `.vscode/scripts/` 目录下
2. **更清晰的命名**：`notify-sys.sh` 更准确地描述了其功能
3. **维护性提升**：相关脚本聚集在一起，便于查找和维护
4. **自动化增强**：sync-docs 脚本自动处理 hooks 安装，减少手动配置

## 安装方法

### 手动安装
```bash
cd /Users/ghost/work/WorldTourCasino
bash .vscode/scripts/git-hooks/install-hooks.sh
```

### 自动安装
运行 sync-docs.sh 时会自动检查并安装：
```bash
bash .vscode/scripts/wtc-docs/sync-docs.sh
```

## 相关文件
- [install-hooks.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v858_chore/.vscode/scripts/git-hooks/install-hooks.sh)
- [sync-docs.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v858_chore/.vscode/scripts/wtc-docs/sync-docs.sh)
- [notify-sys.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v858_chore/.vscode/scripts/common/notify-sys.sh)