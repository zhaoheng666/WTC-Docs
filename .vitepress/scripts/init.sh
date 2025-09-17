#!/bin/bash

# 文档项目环境初始化和修复脚本
# 用于设置、检查和修复开发环境
# 可多次运行，自动跳过已配置项

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 参数解析
SILENT=false
FIX_ONLY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --silent|-s)
            SILENT=true
            shift
            ;;
        --fix|-f)
            FIX_ONLY=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ "$SILENT" = false ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🚀 文档项目环境检查和修复${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

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

# 4. 安装 GitHub CLI（必需）
echo -e "\n${CYAN}检查 GitHub CLI...${NC}"
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  未安装 GitHub CLI${NC}"
    
    if [ "$FIX_ONLY" = true ] || [ "$SILENT" = true ]; then
        # 自动修复模式
        INSTALL_GH=true
    else
        # 询问是否安装
        read -p "是否安装 GitHub CLI？(Actions监控必需) [Y/n] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Nn]$ ]] && INSTALL_GH=true || INSTALL_GH=false
    fi
    
    if [ "$INSTALL_GH" = true ]; then
        if [ "$(uname)" = "Darwin" ]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install gh
                echo -e "${GREEN}✅ GitHub CLI 已安装${NC}"
            else
                echo -e "${RED}❌ 需要先安装 Homebrew: https://brew.sh${NC}"
                echo -e "${YELLOW}   请安装后重新运行 npm run init${NC}"
                exit 1
            fi
        elif [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update && sudo apt install gh -y
            echo -e "${GREEN}✅ GitHub CLI 已安装${NC}"
        else
            echo -e "${YELLOW}请手动安装: https://cli.github.com/${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  跳过 GitHub CLI 安装（Actions监控将不可用）${NC}"
    fi
else
    echo -e "${GREEN}✅ GitHub CLI 已安装${NC}"
fi

# 检查 GitHub CLI 登录状态
if command -v gh &> /dev/null; then
    if ! gh auth status &> /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  GitHub CLI 未登录${NC}"
        
        if [ "$FIX_ONLY" = true ] || [ "$SILENT" = true ]; then
            echo -e "${YELLOW}   请手动运行: gh auth login${NC}"
        else
            read -p "是否现在登录 GitHub？[Y/n] " -n 1 -r
            echo
            
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                gh auth login --hostname github.com --protocol https --web
                if gh auth status &> /dev/null 2>&1; then
                    echo -e "${GREEN}✅ GitHub 登录成功${NC}"
                else
                    echo -e "${YELLOW}⚠️  登录失败，Actions监控功能将受限${NC}"
                fi
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

# 9. 环境检查汇总
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}环境状态汇总：${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检查所有关键依赖
ENV_READY=true

# Node.js
if command -v node &> /dev/null; then
    echo -e "${GREEN}✅ Node.js${NC}"
else
    echo -e "${RED}❌ Node.js - 需要安装${NC}"
    ENV_READY=false
fi

# npm 依赖
if [ -d "node_modules" ]; then
    echo -e "${GREEN}✅ npm 依赖${NC}"
else
    echo -e "${RED}❌ npm 依赖 - 需要安装${NC}"
    ENV_READY=false
fi

# GitHub CLI
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null 2>&1; then
        echo -e "${GREEN}✅ GitHub CLI (已登录)${NC}"
    else
        echo -e "${YELLOW}⚠️  GitHub CLI (未登录)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  GitHub CLI (未安装)${NC}"
fi

# terminal-notifier (macOS)
if [ "$(uname)" = "Darwin" ]; then
    if command -v terminal-notifier &> /dev/null; then
        echo -e "${GREEN}✅ terminal-notifier${NC}"
    else
        echo -e "${YELLOW}⚠️  terminal-notifier (可选)${NC}"
    fi
fi

# Git 配置
if [ "$(git config core.quotepath)" = "false" ]; then
    echo -e "${GREEN}✅ Git 中文路径配置${NC}"
else
    echo -e "${YELLOW}⚠️  Git 中文路径未配置${NC}"
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$ENV_READY" = true ]; then
    echo -e "${GREEN}✨ 环境配置完成！${NC}"
else
    echo -e "${YELLOW}⚠️  环境配置未完成，部分功能可能受限${NC}"
fi

if [ "$SILENT" = false ]; then
    echo -e "\n可用命令："
    echo -e "  ${CYAN}npm run dev${NC}         - 启动开发服务器"
    echo -e "  ${CYAN}npm run build${NC}       - 构建文档"
    echo -e "  ${CYAN}npm run commit${NC}      - 同步文档到远程"
    echo -e "  ${CYAN}npm run actions${NC}     - 检查 Actions 状态"
    echo -e "  ${CYAN}npm run actions:watch${NC} - 监控 Actions 状态"
    echo -e "  ${CYAN}npm run clean${NC}       - 清理缓存"
    echo -e "  ${CYAN}npm run init${NC}        - 环境检查和修复"
    echo -e "\n详细说明请查看 ${CYAN}SCRIPTS.md${NC}"
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$ENV_READY" = false ]; then
    exit 1
else
    exit 0
fi