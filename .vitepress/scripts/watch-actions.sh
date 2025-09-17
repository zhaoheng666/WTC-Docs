#!/bin/bash

# GitHub Actions 监控脚本
# 持续监控 Actions 状态，失败时发送通知

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

# 设置 jq 命令 - 优先使用系统 jq，回退到 npx jq
if command -v jq &> /dev/null; then
    JQ_CMD="jq"
else
    JQ_CMD="npx jq"
fi

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
REPO_INFO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}👁  开始监控 GitHub Actions${NC}"
echo -e "${CYAN}仓库: $REPO_INFO${NC}"
echo -e "${CYAN}按 Ctrl+C 停止监控${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 记录已通知的运行ID，避免重复通知
NOTIFIED_RUNS="/tmp/notified_runs_$$.txt"
> "$NOTIFIED_RUNS"

# 清理函数
cleanup() {
    rm -f "$NOTIFIED_RUNS"
    echo -e "\n${CYAN}监控已停止${NC}"
    exit 0
}

trap cleanup INT TERM

# 发送通知函数
send_notification() {
    local title="$1"
    local message="$2"
    local url="$3"
    local sound="${4:-Basso}"
    
    if [ "$(uname)" = "Darwin" ]; then
        # macOS 系统通知
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
        
        # 如果有 terminal-notifier，使用更好的通知
        if command -v terminal-notifier &> /dev/null; then
            terminal-notifier -title "$title" \
                -message "$message" \
                -open "$url" \
                -sound "$sound" \
                -group "github-actions" \
                -ignoreDnD
        fi
    fi
    
    # 也在终端显示
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}🔔 $title${NC}"
    echo -e "${RED}$message${NC}"
    echo -e "${RED}$url${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 监控循环
LAST_CHECK=""
CHECK_COUNT=0
while true; do
    # 显示检查状态（每次检查都显示）
    CHECK_COUNT=$((CHECK_COUNT + 1))
    CURRENT_TIME=$(date "+%H:%M:%S")
    echo -ne "\r${CYAN}[${CURRENT_TIME}] 检查 #${CHECK_COUNT} - 监控中...${NC}"
    
    # 获取最新的运行
    # 清理 PATH，移除 node_modules/.bin
    export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "node_modules" | tr '\n' ':' | sed 's/:$//')
    
    LATEST_RUN=$(gh run list --limit 1 --json databaseId,status,conclusion,name,headBranch 2>/dev/null)
    
    if [ -n "$LATEST_RUN" ] && [ "$LATEST_RUN" != "[]" ]; then
        # 使用 jq 解析 JSON
        RUN_ID=$(echo "$LATEST_RUN" | $JQ_CMD -r '.[0].databaseId // ""')
        STATUS=$(echo "$LATEST_RUN" | $JQ_CMD -r '.[0].status // ""')
        CONCLUSION=$(echo "$LATEST_RUN" | $JQ_CMD -r '.[0].conclusion // ""')
        NAME=$(echo "$LATEST_RUN" | $JQ_CMD -r '.[0].name // ""')
        BRANCH=$(echo "$LATEST_RUN" | $JQ_CMD -r '.[0].headBranch // ""')
        
        if [ -z "$RUN_ID" ]; then
            continue
        fi
        
        # 检查是否已通知过
        if ! grep -q "$RUN_ID" "$NOTIFIED_RUNS" 2>/dev/null; then
            # 根据状态发送通知
            if [ "$STATUS" = "completed" ]; then
                echo "$RUN_ID" >> "$NOTIFIED_RUNS"
                
                if [ "$CONCLUSION" = "success" ]; then
                    # 成功通知
                    echo -e "\n${GREEN}✅ [$BRANCH] $NAME - 构建成功${NC}"
                    send_notification "✅ GitHub Actions 成功" \
                        "$NAME 在 $BRANCH 分支构建成功" \
                        "https://github.com/$REPO_INFO/actions/runs/$RUN_ID" \
                        "Glass"
                        
                elif [ "$CONCLUSION" = "failure" ]; then
                    # 失败通知（重要）
                    echo -e "\n${RED}❌ [$BRANCH] $NAME - 构建失败${NC}"
                    
                    # 获取失败详情
                    FAILED_JOBS=$(gh run view "$RUN_ID" --json jobs -q '.jobs[] | select(.conclusion == "failure") | .name' 2>/dev/null | head -3)
                    
                    send_notification "❌ GitHub Actions 失败" \
                        "$NAME 在 $BRANCH 分支构建失败\n失败任务: $FAILED_JOBS" \
                        "https://github.com/$REPO_INFO/actions/runs/$RUN_ID" \
                        "Sosumi"
                        
                elif [ "$CONCLUSION" = "cancelled" ]; then
                    # 取消通知
                    echo -e "\n${YELLOW}⏹ [$BRANCH] $NAME - 已取消${NC}"
                    send_notification "⏹ GitHub Actions 取消" \
                        "$NAME 在 $BRANCH 分支被取消" \
                        "https://github.com/$REPO_INFO/actions/runs/$RUN_ID" \
                        "Pop"
                fi
            elif [ "$STATUS" = "in_progress" ]; then
                # 显示运行中状态（不通知）
                CURRENT_CHECK="$RUN_ID-$STATUS"
                if [ "$CURRENT_CHECK" != "$LAST_CHECK" ]; then
                    echo -e "\n${CYAN}🔄 [$BRANCH] $NAME - 运行中...${NC}"
                    LAST_CHECK="$CURRENT_CHECK"
                fi
            elif [ "$STATUS" = "queued" ]; then
                # 显示排队状态
                CURRENT_CHECK="$RUN_ID-$STATUS"
                if [ "$CURRENT_CHECK" != "$LAST_CHECK" ]; then
                    echo -e "\n${YELLOW}⏳ [$BRANCH] $NAME - 排队中...${NC}"
                    LAST_CHECK="$CURRENT_CHECK"
                fi
            fi
        fi
    fi
    
    # 等待10秒后再次检查
    sleep 10
done