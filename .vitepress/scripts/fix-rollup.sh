#!/bin/bash

# 修复 Rollup 架构兼容性问题的脚本
# 解决 Node.js 和系统架构不匹配导致的构建失败

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔧 正在修复 Rollup 架构兼容性问题...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 检测系统架构
SYSTEM_ARCH=$(uname -m)
NODE_ARCH=$(node -p "process.arch")
OS=$(uname -s)

echo -e "${CYAN}系统架构检测：${NC}"
echo -e "  • 系统架构 (uname): $SYSTEM_ARCH"
echo -e "  • Node.js 架构: $NODE_ARCH"
echo -e "  • 操作系统: $OS"

# 判断需要安装的 Rollup 包
ROLLUP_PACKAGES=""

if [ "$OS" = "Darwin" ]; then
    # macOS 系统
    echo -e "${CYAN}检测到 macOS 系统${NC}"
    
    # 安装两个架构的包以确保兼容性
    ROLLUP_PACKAGES="@rollup/rollup-darwin-arm64@4 @rollup/rollup-darwin-x64@4"
    
    echo -e "${YELLOW}⚠️  注意：由于架构混合环境，将安装两个版本以确保兼容性${NC}"
elif [ "$OS" = "Linux" ]; then
    # Linux 系统（GitHub Actions 等）
    echo -e "${CYAN}检测到 Linux 系统${NC}"
    
    if [ "$NODE_ARCH" = "x64" ]; then
        ROLLUP_PACKAGES="@rollup/rollup-linux-x64-gnu@4"
    elif [ "$NODE_ARCH" = "arm64" ]; then
        ROLLUP_PACKAGES="@rollup/rollup-linux-arm64-gnu@4"
    fi
fi

# 如果检测到需要安装的包
if [ -n "$ROLLUP_PACKAGES" ]; then
    echo -e "${CYAN}正在安装 Rollup 架构包...${NC}"
    echo -e "${CYAN}安装包: $ROLLUP_PACKAGES${NC}"
    
    # 安装必要的 Rollup 包
    if npm install $ROLLUP_PACKAGES --save-optional --force; then
        echo -e "${GREEN}✅ Rollup 架构包安装成功！${NC}"
    else
        echo -e "${RED}❌ 安装失败，尝试其他方法...${NC}"
        
        # 备用方案：清理并重新安装
        echo -e "${YELLOW}正在尝试清理缓存...${NC}"
        npm cache clean --force
        
        if npm install $ROLLUP_PACKAGES --save-optional; then
            echo -e "${GREEN}✅ 通过清理缓存后安装成功！${NC}"
        else
            echo -e "${RED}❌ 安装仍然失败${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠️  未检测到需要特殊处理的架构${NC}"
fi

# 验证修复
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}正在验证修复...${NC}"

# 尝试运行构建测试
if npm run build > /tmp/rollup-test.log 2>&1; then
    echo -e "${GREEN}✅ Rollup 问题已解决，构建成功！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    rm -f /tmp/rollup-test.log
    exit 0
else
    echo -e "${RED}❌ 构建仍然失败${NC}"
    echo -e "${YELLOW}错误信息：${NC}"
    grep -E "(Error:|Cannot find module)" /tmp/rollup-test.log | head -5
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}建议尝试以下操作：${NC}"
    echo -e "  1. 运行: rm -rf node_modules package-lock.json"
    echo -e "  2. 运行: npm install"
    echo -e "  3. 再次运行此修复脚本"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    rm -f /tmp/rollup-test.log
    exit 1
fi