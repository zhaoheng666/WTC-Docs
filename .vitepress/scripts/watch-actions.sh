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

# 检查依赖
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  未安装 GitHub CLI (gh)${NC}"
    echo -e "${CYAN}正在安装...${NC}"
    
    # 根据系统自动安装
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install gh
        else
            echo -e "${RED}请先安装 Homebrew: https://brew.sh${NC}"
            exit 1
        fi
    elif [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install gh -y
    else
        echo -e "${RED}请手动安装 GitHub CLI: https://cli.github.com/${NC}"
        exit 1
    fi
fi

if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  需要登录 GitHub${NC}"
    echo -e "${CYAN}正在启动登录流程...${NC}"
    
    # 自动运行登录流程
    gh auth login --hostname github.com --protocol https --web
    
    # 再次检查登录状态
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ 登录失败，请重试${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub 登录成功${NC}"
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
while true; do
    # 获取最新的运行
    LATEST_RUN=$(gh run list --limit 1 --json databaseId,status,conclusion,name,headBranch 2>/dev/null | jq -r '.[0]')
    
    if [ -n "$LATEST_RUN" ] && [ "$LATEST_RUN" != "null" ]; then
        RUN_ID=$(echo "$LATEST_RUN" | jq -r '.databaseId')
        STATUS=$(echo "$LATEST_RUN" | jq -r '.status')
        CONCLUSION=$(echo "$LATEST_RUN" | jq -r '.conclusion')
        NAME=$(echo "$LATEST_RUN" | jq -r '.name')
        BRANCH=$(echo "$LATEST_RUN" | jq -r '.headBranch')
        
        # 检查是否已通知过
        if ! grep -q "$RUN_ID" "$NOTIFIED_RUNS" 2>/dev/null; then
            # 根据状态发送通知
            if [ "$STATUS" = "completed" ]; then
                echo "$RUN_ID" >> "$NOTIFIED_RUNS"
                
                if [ "$CONCLUSION" = "success" ]; then
                    # 成功通知
                    echo -e "${GREEN}✅ [$BRANCH] $NAME - 构建成功${NC}"
                    send_notification "✅ GitHub Actions 成功" \
                        "$NAME 在 $BRANCH 分支构建成功" \
                        "https://github.com/$REPO_INFO/actions/runs/$RUN_ID" \
                        "Glass"
                        
                elif [ "$CONCLUSION" = "failure" ]; then
                    # 失败通知（重要）
                    echo -e "${RED}❌ [$BRANCH] $NAME - 构建失败${NC}"
                    
                    # 获取失败详情
                    FAILED_JOBS=$(gh run view "$RUN_ID" --json jobs -q '.jobs[] | select(.conclusion == "failure") | .name' 2>/dev/null | head -3)
                    
                    send_notification "❌ GitHub Actions 失败" \
                        "$NAME 在 $BRANCH 分支构建失败\n失败任务: $FAILED_JOBS" \
                        "https://github.com/$REPO_INFO/actions/runs/$RUN_ID" \
                        "Sosumi"
                        
                elif [ "$CONCLUSION" = "cancelled" ]; then
                    # 取消通知
                    echo -e "${YELLOW}⏹ [$BRANCH] $NAME - 已取消${NC}"
                    send_notification "⏹ GitHub Actions 取消" \
                        "$NAME 在 $BRANCH 分支被取消" \
                        "https://github.com/$REPO_INFO/actions/runs/$RUN_ID" \
                        "Pop"
                fi
            elif [ "$STATUS" = "in_progress" ]; then
                # 显示运行中状态（不通知）
                CURRENT_CHECK="$RUN_ID-$STATUS"
                if [ "$CURRENT_CHECK" != "$LAST_CHECK" ]; then
                    echo -e "${CYAN}🔄 [$BRANCH] $NAME - 运行中...${NC}"
                    LAST_CHECK="$CURRENT_CHECK"
                fi
            fi
        fi
    fi
    
    # 等待30秒后再次检查
    sleep 30
done