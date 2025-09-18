#!/bin/bash

# 文档状态检查脚本 - 精简版
# 仅显示当前状态，不做任何修改

# 颜色定义
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 显示当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${CYAN}📍 当前分支: ${YELLOW}$CURRENT_BRANCH${NC}"

# 显示本地状态
LOCAL_CHANGES=$(git status --porcelain)
if [ -n "$LOCAL_CHANGES" ]; then
    CHANGE_COUNT=$(echo "$LOCAL_CHANGES" | wc -l | tr -d ' ')
    echo -e "${YELLOW}📝 本地有 $CHANGE_COUNT 个文件变更${NC}"
    echo "$LOCAL_CHANGES"
else
    echo -e "${GREEN}✅ 本地没有未提交的更改${NC}"
fi

# 检查远程状态
git fetch origin "$CURRENT_BRANCH" --quiet 2>/dev/null
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse origin/"$CURRENT_BRANCH" 2>/dev/null)

if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    # 判断是本地领先还是远程领先
    BEHIND=$(git rev-list --count HEAD..origin/"$CURRENT_BRANCH" 2>/dev/null || echo 0)
    AHEAD=$(git rev-list --count origin/"$CURRENT_BRANCH"..HEAD 2>/dev/null || echo 0)
    
    if [ "$BEHIND" -gt 0 ] && [ "$AHEAD" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  本地和远程有分歧（需要合并）${NC}"
    elif [ "$BEHIND" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  远程有 $BEHIND 个新提交（需要拉取）${NC}"
    elif [ "$AHEAD" -gt 0 ]; then
        echo -e "${CYAN}📤 本地领先 $AHEAD 个提交（需要推送）${NC}"
    fi
else
    if [ -n "$LOCAL_CHANGES" ]; then
        echo -e "${CYAN}📊 与远程同步（但有本地未提交更改）${NC}"
    else
        echo -e "${GREEN}✅ 与远程完全同步${NC}"
    fi
fi

exit 0