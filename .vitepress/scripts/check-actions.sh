#!/bin/bash

# GitHub Actions 状态检查脚本
# 检查最近的 Actions 运行状态并在失败时发送通知

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

# 检查依赖
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ 未安装 GitHub CLI${NC}"
    echo -e "${YELLOW}请运行以下命令修复环境：${NC}"
    echo -e "${CYAN}  npm run init${NC}"
    exit 1
fi

if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${RED}❌ GitHub CLI 未登录${NC}"
    echo -e "${YELLOW}请运行以下命令修复环境：${NC}"
    echo -e "${CYAN}  npm run init${NC}"
    exit 1
fi

# 获取仓库信息
REPO_INFO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
if [ -z "$REPO_INFO" ]; then
    echo -e "${RED}❌ 无法获取仓库信息${NC}"
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔍 检查 GitHub Actions 状态...${NC}"
echo -e "${CYAN}仓库: $REPO_INFO${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 清理 PATH，移除 node_modules/.bin
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "node_modules" | tr '\n' ':' | sed 's/:$//')

# 获取最近的 workflow 运行状态
RECENT_RUNS=$(gh run list --limit 5 --json databaseId,status,conclusion,name,createdAt,event,headBranch 2>/dev/null)

if [ -z "$RECENT_RUNS" ] || [ "$RECENT_RUNS" = "[]" ]; then
    echo -e "${YELLOW}没有找到最近的 Actions 运行${NC}"
    exit 0
fi

# 使用 Python 解析 JSON（避免 jq 依赖）
echo "$RECENT_RUNS" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for run in data:
    print(f\"{run['status']}|{run['conclusion']}|{run['name']}|{run['createdAt']}|{run['event']}|{run['headBranch']}|{run['databaseId']}\")
" | while IFS='|' read -r status conclusion name created_at event branch run_id; do
    # 如果没有数据，跳过
    if [ -z "$status" ]; then
        continue
    fi
    # 格式化时间
    formatted_time=$(echo "$created_at" | cut -d'T' -f1,2 | sed 's/T/ /')
    
    # 确定状态图标和颜色
    if [ "$status" = "completed" ]; then
        if [ "$conclusion" = "success" ]; then
            STATUS_ICON="✅"
            STATUS_COLOR=$GREEN
            STATUS_TEXT="成功"
        elif [ "$conclusion" = "failure" ]; then
            STATUS_ICON="❌"
            STATUS_COLOR=$RED
            STATUS_TEXT="失败"
        elif [ "$conclusion" = "cancelled" ]; then
            STATUS_ICON="⏹"
            STATUS_COLOR=$YELLOW
            STATUS_TEXT="取消"
        else
            STATUS_ICON="⚠️"
            STATUS_COLOR=$YELLOW
            STATUS_TEXT="$conclusion"
        fi
    elif [ "$status" = "in_progress" ]; then
        STATUS_ICON="🔄"
        STATUS_COLOR=$CYAN
        STATUS_TEXT="运行中"
    else
        STATUS_ICON="⏸"
        STATUS_COLOR=$YELLOW
        STATUS_TEXT="$status"
    fi
    
    # 显示状态
    echo -e "${STATUS_COLOR}$STATUS_ICON $STATUS_TEXT${NC} - $name"
    echo -e "  分支: $branch | 触发: $event"
    echo -e "  时间: $formatted_time"
    echo -e "  查看: https://github.com/$REPO_INFO/actions/runs/$run_id"
    echo ""
done

# 检查最近一次运行是否失败
LATEST_CONCLUSION=$(echo "$RECENT_RUNS" | jq -r '.[0].conclusion')
LATEST_STATUS=$(echo "$RECENT_RUNS" | jq -r '.[0].status')
LATEST_NAME=$(echo "$RECENT_RUNS" | jq -r '.[0].name')
LATEST_RUN_ID=$(echo "$RECENT_RUNS" | jq -r '.[0].databaseId')

# 如果最近的运行失败了，发送通知
if [ "$LATEST_STATUS" = "completed" ] && [ "$LATEST_CONCLUSION" = "failure" ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}⚠️  最近的 Actions 运行失败了！${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 获取失败的详细信息
    echo -e "${CYAN}获取失败详情...${NC}"
    FAILED_JOBS=$(gh run view "$LATEST_RUN_ID" --json jobs -q '.jobs[] | select(.conclusion == "failure") | .name' 2>/dev/null)
    
    if [ -n "$FAILED_JOBS" ]; then
        echo -e "${YELLOW}失败的任务：${NC}"
        echo "$FAILED_JOBS" | while read -r job; do
            echo -e "  • $job"
        done
    fi
    
    # 如果在 macOS 上，发送系统通知
    if [ "$(uname)" = "Darwin" ]; then
        osascript -e "display notification \"$LATEST_NAME 运行失败\" with title \"GitHub Actions\" subtitle \"文档构建失败\" sound name \"Basso\""
        
        # 如果安装了 terminal-notifier，使用更好的通知
        if command -v terminal-notifier &> /dev/null; then
            terminal-notifier -title "GitHub Actions 失败" \
                -subtitle "$LATEST_NAME" \
                -message "点击查看详情" \
                -open "https://github.com/$REPO_INFO/actions/runs/$LATEST_RUN_ID" \
                -sound Basso \
                -group "github-actions"
        fi
    fi
    
    exit 1
elif [ "$LATEST_STATUS" = "in_progress" ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔄 Actions 正在运行中...${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ 所有 Actions 运行正常${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
fi