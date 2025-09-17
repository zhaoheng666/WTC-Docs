#!/bin/bash

# 文档同步脚本
# 包含：拉取最新、构建测试、自动提交推送

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

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔄 开始文档同步...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. 检查 Git 仓库状态
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 获取当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${CYAN}📍 当前分支: ${YELLOW}$CURRENT_BRANCH${NC}"

# 2. 暂存所有更改
echo -e "${CYAN}📦 暂存本地更改...${NC}"
git add -A
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ 文件已暂存${NC}"
fi

# 3. 检查是否有需要提交的内容
if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  没有需要提交的更改${NC}"
    
    # 仍然尝试拉取远程更新
    echo -e "${CYAN}📥 检查远程更新...${NC}"
    git fetch origin "$CURRENT_BRANCH" --quiet 2>/dev/null
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/"$CURRENT_BRANCH" 2>/dev/null)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo -e "${CYAN}正在合并远程更改...${NC}"
        # 使用 rebase 保持线性历史
        if git pull --rebase origin "$CURRENT_BRANCH" > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ 已同步最新代码（rebase）${NC}"
        else
            # 如果失败，回退到普通 pull
            git rebase --abort > /dev/null 2>&1
            if git pull origin "$CURRENT_BRANCH" --no-edit; then
                echo -e "${GREEN}  ✓ 已同步最新代码（merge）${NC}"
            else
                echo -e "${RED}  ✗ 合并失败，请手动处理冲突${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}  ✓ 已是最新版本${NC}"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ 文档已是最新状态${NC}"
    exit 0
fi

# 4. 执行构建测试
echo -e "${CYAN}🔨 执行构建测试...${NC}"
if bash .vitepress/scripts/build.sh > /tmp/sync-build.log 2>&1; then
    echo -e "${GREEN}  ✓ 构建成功${NC}"
else
    echo -e "${RED}  ✗ 构建失败${NC}"
    echo -e "${YELLOW}查看详细日志：cat /tmp/sync-build.log${NC}"
    
    # 询问是否继续
    read -p "构建失败，是否仍要继续提交？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}已取消同步${NC}"
        exit 1
    fi
fi

# 5. 生成提交信息
echo -e "${CYAN}📝 准备提交...${NC}"

# 获取更改的文件列表（只显示 .md 文件，不包含路径）
CHANGED_MD_FILES=$(git diff --cached --name-only | grep "\.md$" | xargs -I {} basename {} .md | head -5)
CHANGED_MD_COUNT=$(git diff --cached --name-only | grep "\.md$" | wc -l)

# 获取其他类型更改
OTHER_CHANGES=$(git diff --cached --name-only | grep -v "\.md$" | wc -l)

# 生成提交信息
if [ "$CHANGED_MD_COUNT" -gt 0 ]; then
    # 将文件名转换为逗号分隔的列表
    FILE_LIST=$(echo "$CHANGED_MD_FILES" | paste -sd ", " -)
    
    if [ "$CHANGED_MD_COUNT" -gt 5 ]; then
        # 如果文件太多，显示前5个和总数
        COMMIT_MSG="docs: 更新 ${FILE_LIST} 等 ${CHANGED_MD_COUNT} 个文档"
    elif [ "$CHANGED_MD_COUNT" -eq 1 ]; then
        COMMIT_MSG="docs: 更新 ${FILE_LIST}"
    else
        COMMIT_MSG="docs: 更新 ${FILE_LIST}"
    fi
    
    # 如果有其他文件更改，添加说明
    if [ "$OTHER_CHANGES" -gt 0 ]; then
        COMMIT_MSG="${COMMIT_MSG} (含配置文件)"
    fi
else
    # 没有 md 文件更改，可能只是配置文件
    if [ "$OTHER_CHANGES" -gt 0 ]; then
        COMMIT_MSG="chore: 更新配置文件"
    else
        COMMIT_MSG="docs: 更新文档"
    fi
fi

# 6. 创建提交
if git commit -m "$COMMIT_MSG" > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ 提交成功: $COMMIT_MSG${NC}"
else
    echo -e "${RED}  ✗ 提交失败${NC}"
    exit 1
fi

# 7. 拉取并合并远程更改
echo -e "${CYAN}📥 同步远程仓库...${NC}"
git fetch origin "$CURRENT_BRANCH" --quiet 2>/dev/null

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/"$CURRENT_BRANCH" 2>/dev/null)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo -e "${CYAN}发现远程更改，正在合并...${NC}"
    # 优先使用 rebase 保持线性历史
    if git pull --rebase origin "$CURRENT_BRANCH" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ 合并成功（rebase）${NC}"
    else
        # 如果 rebase 有冲突，中止并使用普通 merge
        git rebase --abort > /dev/null 2>&1
        if git pull origin "$CURRENT_BRANCH" --no-edit; then
            echo -e "${GREEN}  ✓ 合并成功（merge）${NC}"
        else
            echo -e "${RED}  ✗ 合并失败，请手动处理冲突${NC}"
            exit 1
        fi
    fi
fi

# 8. 推送到远程
echo -e "${CYAN}📤 推送到远程仓库...${NC}"
if git push origin "$CURRENT_BRANCH"; then
    echo -e "${GREEN}  ✓ 推送成功${NC}"
else
    echo -e "${RED}  ✗ 推送失败${NC}"
    echo -e "${YELLOW}请检查网络连接或仓库权限${NC}"
    exit 1
fi

# 9. 清理临时文件
rm -f /tmp/sync-build.log

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 文档同步完成！${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 10. 等待并检查 GitHub Actions 状态（如果有 gh CLI）
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    echo -e "${CYAN}等待 GitHub Actions 启动...${NC}"
    sleep 5
    
    # 检查 Actions 状态
    if [ -f ".vitepress/scripts/check-actions.sh" ]; then
        bash .vitepress/scripts/check-actions.sh || true
    fi
else
    echo -e "${YELLOW}提示：运行 'npm run init' 配置 GitHub Actions 监控${NC}"
fi

exit 0