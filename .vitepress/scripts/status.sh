#!/bin/bash

# 文档状态检查脚本
# 包含：stash本地更改、拉取远程、恢复本地更改、显示状态

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 获取当前分支
CURRENT_BRANCH=$(git branch --show-current)

# 检查本地是否有更改
HAS_LOCAL_CHANGES=false
LOCAL_CHANGES=""

if [ -n "$(git status --porcelain)" ]; then
    HAS_LOCAL_CHANGES=true
    LOCAL_CHANGES=$(git status --porcelain)
    
    # 暂存本地更改
    echo -e "${CYAN}暂存本地更改...${NC}" >&2
    git add -A > /dev/null 2>&1
    git stash push -m "Auto stash for status check" > /dev/null 2>&1
fi

# 拉取远程更新
echo -e "${CYAN}检查远程更新...${NC}" >&2
git fetch origin "$CURRENT_BRANCH" --quiet 2>/dev/null

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse origin/"$CURRENT_BRANCH" 2>/dev/null)

if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    echo -e "${YELLOW}发现远程更新，正在拉取...${NC}" >&2
    # 使用 rebase 保持线性历史
    if git pull --rebase origin "$CURRENT_BRANCH" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 已同步远程更新（rebase）${NC}" >&2
    else
        # 如果 rebase 失败，中止并尝试普通 pull
        git rebase --abort > /dev/null 2>&1
        git pull origin "$CURRENT_BRANCH" --no-edit > /dev/null 2>&1
        echo -e "${YELLOW}⚠ 已同步远程更新（merge）${NC}" >&2
    fi
fi

# 恢复本地更改
if [ "$HAS_LOCAL_CHANGES" = true ]; then
    git stash pop > /dev/null 2>&1
    echo -e "${GREEN}✓ 已恢复本地更改${NC}" >&2
fi

# 输出当前状态（用于主项目读取）
git status --short

# 如果有本地更改，输出到 stderr（用于显示信息）
if [ "$HAS_LOCAL_CHANGES" = true ]; then
    CHANGE_COUNT=$(echo "$LOCAL_CHANGES" | wc -l | tr -d ' ')
    echo -e "${CYAN}本地有 $CHANGE_COUNT 个文件变更${NC}" >&2
fi

exit 0