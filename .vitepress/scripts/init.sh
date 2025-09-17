#!/bin/bash

# 文档项目初始化脚本
# 用于首次设置环境和依赖

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🚀 文档项目初始化${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 1. 检查 Node.js
echo -e "\n${CYAN}检查 Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}✅ Node.js 已安装: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ 未安装 Node.js${NC}"
    echo -e "${YELLOW}请访问 https://nodejs.org 安装${NC}"
    exit 1
fi

# 2. 安装 npm 依赖
echo -e "\n${CYAN}安装项目依赖...${NC}"
if [ -f "package.json" ]; then
    npm install
    echo -e "${GREEN}✅ 依赖安装完成${NC}"
else
    echo -e "${RED}❌ 找不到 package.json${NC}"
    exit 1
fi

# 3. 修复 Rollup ARM64 问题（如果是 Mac ARM）
if [ "$(uname)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
    echo -e "\n${CYAN}检测到 Mac ARM64，安装兼容包...${NC}"
    npm install --save-optional @rollup/rollup-darwin-arm64
    echo -e "${GREEN}✅ ARM64 兼容包已安装${NC}"
fi

# 4. 安装 GitHub CLI（如果需要）
echo -e "\n${CYAN}检查 GitHub CLI...${NC}"
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  未安装 GitHub CLI${NC}"
    
    # 询问是否安装
    read -p "是否安装 GitHub CLI？(用于 Actions 监控) [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$(uname)" = "Darwin" ]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install gh
                echo -e "${GREEN}✅ GitHub CLI 已安装${NC}"
            else
                echo -e "${YELLOW}请先安装 Homebrew: https://brew.sh${NC}"
            fi
        elif [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update && sudo apt install gh -y
            echo -e "${GREEN}✅ GitHub CLI 已安装${NC}"
        else
            echo -e "${YELLOW}请手动安装: https://cli.github.com/${NC}"
        fi
    else
        echo -e "${YELLOW}跳过 GitHub CLI 安装${NC}"
    fi
else
    echo -e "${GREEN}✅ GitHub CLI 已安装${NC}"
    
    # 检查登录状态
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}GitHub CLI 未登录${NC}"
        read -p "是否现在登录 GitHub？[y/N] " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login --hostname github.com --protocol https --web
            if gh auth status &> /dev/null; then
                echo -e "${GREEN}✅ GitHub 登录成功${NC}"
            fi
        fi
    else
        echo -e "${GREEN}✅ 已登录 GitHub${NC}"
    fi
fi

# 5. 安装 terminal-notifier（macOS 增强通知）
if [ "$(uname)" = "Darwin" ]; then
    echo -e "\n${CYAN}检查 terminal-notifier...${NC}"
    if ! command -v terminal-notifier &> /dev/null; then
        read -p "是否安装 terminal-notifier？(增强通知) [y/N] " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command -v brew &> /dev/null; then
                brew install terminal-notifier
                echo -e "${GREEN}✅ terminal-notifier 已安装${NC}"
            fi
        else
            echo -e "${YELLOW}跳过 terminal-notifier 安装${NC}"
        fi
    else
        echo -e "${GREEN}✅ terminal-notifier 已安装${NC}"
    fi
fi

# 6. 配置 Git
echo -e "\n${CYAN}配置 Git...${NC}"
git config core.quotepath false
echo -e "${GREEN}✅ Git 中文路径显示已配置${NC}"

# 7. 创建必要的目录
echo -e "\n${CYAN}创建目录结构...${NC}"
mkdir -p public/images
mkdir -p .vitepress/cache
mkdir -p .vitepress/dist
echo -e "${GREEN}✅ 目录结构已创建${NC}"

# 8. 验证脚本权限
echo -e "\n${CYAN}设置脚本权限...${NC}"
chmod +x .vitepress/scripts/*.sh
echo -e "${GREEN}✅ 脚本权限已设置${NC}"

# 9. 显示可用命令
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ 初始化完成！${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n可用命令："
echo -e "  ${CYAN}npm run dev${NC}         - 启动开发服务器"
echo -e "  ${CYAN}npm run build${NC}       - 构建文档"
echo -e "  ${CYAN}npm run commit${NC}      - 同步文档到远程"
echo -e "  ${CYAN}npm run actions${NC}     - 检查 Actions 状态"
echo -e "  ${CYAN}npm run clean${NC}       - 清理缓存"
echo -e "\n详细说明请查看 ${CYAN}SCRIPTS.md${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0