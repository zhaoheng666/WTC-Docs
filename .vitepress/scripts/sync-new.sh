#!/bin/bash

# 文档同步脚本 - 优化版
# 流程：检查状态 → 构建测试 → 合并远程 → 确认提交 → 推送监控

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

# 弹窗通知函数（macOS）
show_dialog() {
    local title="$1"
    local message="$2"
    local buttons="${3:-OK}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display dialog \"$message\" with title \"$title\" buttons {$buttons} default button 1" 2>/dev/null
        return $?
    else
        echo -e "${CYAN}$title: $message${NC}"
        if [[ "$buttons" == *","* ]]; then
            read -p "请选择 (y/n): " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]]
            return $?
        fi
        return 0
    fi
}

# 显示成功通知
show_success() {
    local title="$1"
    local message="$2"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\""
    fi
    echo -e "${GREEN}✅ $title: $message${NC}"
}

# 显示错误通知
show_error() {
    local title="$1"
    local message="$2"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Basso\""
    fi
    echo -e "${RED}❌ $title: $message${NC}"
}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔄 开始文档同步（优化版）...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. 检查 Git 仓库状态
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    show_error "同步失败" "当前目录不是 Git 仓库"
    exit 1
fi

# 获取当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${CYAN}📍 当前分支: ${YELLOW}$CURRENT_BRANCH${NC}"

# 2. 检查本地是否有更改（包括未跟踪文件）
echo -e "${CYAN}🔍 检查本地更改...${NC}"

# 暂存所有更改以便检查
git add -A

# 检查是否有需要提交的内容
if git diff --cached --quiet; then
    # ========== 场景1：本地无变更 ==========
    echo -e "${GREEN}  ✓ 本地没有更改${NC}"
    
    # 直接拉取远程最新版本
    echo -e "${CYAN}📥 拉取远程最新版本...${NC}"
    git fetch origin "$CURRENT_BRANCH" --quiet 2>/dev/null
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/"$CURRENT_BRANCH" 2>/dev/null)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo -e "${CYAN}发现远程更新，正在同步...${NC}"
        if git pull --rebase origin "$CURRENT_BRANCH" > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ 已同步最新代码${NC}"
            show_success "同步完成" "已拉取远程最新版本"
        else
            git rebase --abort > /dev/null 2>&1
            if git pull origin "$CURRENT_BRANCH" --no-edit; then
                echo -e "${GREEN}  ✓ 已同步最新代码（merge）${NC}"
                show_success "同步完成" "已拉取远程最新版本"
            else
                show_error "同步失败" "合并远程代码失败"
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}  ✓ 已是最新版本${NC}"
        show_success "同步完成" "本地已是最新版本"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ 文档同步完成（仅拉取）${NC}"
    exit 0
fi

# ========== 场景2：本地有变更 ==========
echo -e "${GREEN}  ✓ 检测到本地更改${NC}"

# 3. 执行构建测试
echo -e "${CYAN}🔨 执行构建测试...${NC}"
if bash .vitepress/scripts/build.sh > /tmp/sync-build.log 2>&1; then
    echo -e "${GREEN}  ✓ 构建成功${NC}"
else
    echo -e "${RED}  ✗ 构建失败${NC}"
    ERROR_MSG=$(tail -20 /tmp/sync-build.log | head -10)
    show_error "构建失败" "请查看日志: /tmp/sync-build.log"
    
    # 显示错误详情
    echo -e "${RED}错误详情：${NC}"
    echo "$ERROR_MSG"
    
    # 重置暂存区
    git reset HEAD > /dev/null 2>&1
    exit 1
fi

# 4. 拉取远程最新版本并合并
echo -e "${CYAN}📥 同步远程仓库...${NC}"
git fetch origin "$CURRENT_BRANCH" --quiet 2>/dev/null

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/"$CURRENT_BRANCH" 2>/dev/null)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo -e "${CYAN}发现远程更改，正在合并...${NC}"
    
    # 先创建临时提交
    git commit -m "temp: local changes" > /dev/null 2>&1
    
    # 尝试 rebase
    if git pull --rebase origin "$CURRENT_BRANCH" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ 合并成功（rebase）${NC}"
        # 撤销临时提交，恢复暂存状态
        git reset --soft HEAD~1 > /dev/null 2>&1
    else
        # rebase 失败，尝试 merge
        git rebase --abort > /dev/null 2>&1
        
        if git pull origin "$CURRENT_BRANCH" --no-edit > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ 合并成功（merge）${NC}"
            # 撤销临时提交
            git reset --soft HEAD~1 > /dev/null 2>&1
        else
            echo -e "${RED}  ✗ 合并失败，存在冲突${NC}"
            show_error "同步失败" "无法自动合并，请手动处理冲突"
            
            # 显示冲突文件
            echo -e "${RED}冲突文件：${NC}"
            git diff --name-only --diff-filter=U
            exit 1
        fi
    fi
else
    echo -e "${GREEN}  ✓ 本地已包含远程最新内容${NC}"
fi

# 5. 生成提交信息并显示变更内容
echo -e "${CYAN}📝 准备提交...${NC}"

# 获取变更统计
CHANGED_FILES=$(git diff --cached --name-only | wc -l)
CHANGED_MD=$(git diff --cached --name-only | grep "\.md$" | wc -l)
CHANGED_OTHER=$((CHANGED_FILES - CHANGED_MD))

# 获取具体变更文件列表
CHANGED_LIST=$(git diff --cached --name-status | head -10)

# 生成提交信息
if [ "$CHANGED_MD" -gt 0 ]; then
    MD_FILES=$(git diff --cached --name-only | grep "\.md$" | head -3 | xargs -I {} basename {} .md | paste -sd ", " -)
    if [ "$CHANGED_MD" -gt 3 ]; then
        COMMIT_MSG="docs: 更新 ${MD_FILES} 等 ${CHANGED_MD} 个文档"
    else
        COMMIT_MSG="docs: 更新 ${MD_FILES}"
    fi
else
    COMMIT_MSG="chore: 更新配置文件"
fi

# 弹窗确认提交
CHANGE_SUMMARY="变更文件: ${CHANGED_FILES} 个\n"
CHANGE_SUMMARY="${CHANGE_SUMMARY}├─ 文档: ${CHANGED_MD} 个\n"
CHANGE_SUMMARY="${CHANGE_SUMMARY}└─ 其他: ${CHANGED_OTHER} 个\n\n"
CHANGE_SUMMARY="${CHANGE_SUMMARY}提交信息: ${COMMIT_MSG}\n\n"
CHANGE_SUMMARY="${CHANGE_SUMMARY}是否确认提交？"

if ! show_dialog "确认提交" "$CHANGE_SUMMARY" "\"取消\", \"确认\""; then
    echo -e "${YELLOW}⚠️  用户取消提交${NC}"
    # 重置暂存区
    git reset HEAD > /dev/null 2>&1
    show_success "操作取消" "已取消提交，本地更改保留"
    exit 0
fi

# 6. 创建提交
if git commit -m "$COMMIT_MSG" > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ 提交成功: $COMMIT_MSG${NC}"
else
    show_error "提交失败" "创建提交失败"
    exit 1
fi

# 7. 推送到远程
echo -e "${CYAN}📤 推送到远程仓库...${NC}"
if git push origin "$CURRENT_BRANCH"; then
    echo -e "${GREEN}  ✓ 推送成功${NC}"
else
    show_error "推送失败" "请检查网络连接或仓库权限"
    exit 1
fi

# 8. 监控 GitHub Actions 部署状态
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}⏳ 等待 GitHub Actions 部署...${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 等待 Actions 启动
    sleep 5
    
    # 获取当前提交的 SHA
    COMMIT_SHA=$(git rev-parse HEAD)
    
    # 监控部署（最多等待 5 分钟）
    MAX_CHECKS=30
    CHECK_COUNT=0
    
    while [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
        CHECK_COUNT=$((CHECK_COUNT + 1))
        
        # 获取最新的 Actions 运行状态
        RUN_STATUS=$(gh run list --limit 1 --json status,conclusion,headSha | \
            jq -r --arg sha "$COMMIT_SHA" '.[] | select(.headSha == $sha) | .status' 2>/dev/null)
        
        if [ -n "$RUN_STATUS" ]; then
            case "$RUN_STATUS" in
                "completed")
                    CONCLUSION=$(gh run list --limit 1 --json conclusion,headSha | \
                        jq -r --arg sha "$COMMIT_SHA" '.[] | select(.headSha == $sha) | .conclusion' 2>/dev/null)
                    
                    if [ "$CONCLUSION" = "success" ]; then
                        echo -e "\n${GREEN}✅ GitHub Actions 部署成功！${NC}"
                        show_success "部署成功" "文档已成功部署到 GitHub Pages"
                    else
                        echo -e "\n${RED}❌ GitHub Actions 部署失败！${NC}"
                        show_error "部署失败" "请检查 GitHub Actions 日志"
                    fi
                    break
                    ;;
                "in_progress"|"queued")
                    echo -ne "\r${CYAN}⏳ Actions 运行中... (${CHECK_COUNT}/${MAX_CHECKS})${NC}"
                    sleep 10
                    ;;
                *)
                    sleep 10
                    ;;
            esac
        else
            echo -ne "\r${YELLOW}⏳ 等待 Actions 启动... (${CHECK_COUNT}/${MAX_CHECKS})${NC}"
            sleep 10
        fi
    done
    
    if [ $CHECK_COUNT -ge $MAX_CHECKS ]; then
        echo -e "\n${YELLOW}⚠️ 超时：请手动检查 GitHub Actions 状态${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ 未安装 gh 命令行工具，跳过部署监控${NC}"
fi

# 9. 清理临时文件
rm -f /tmp/sync-build.log

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 文档同步完成！${NC}"
show_success "同步完成" "文档已成功同步并推送"