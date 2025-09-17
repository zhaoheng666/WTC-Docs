#!/bin/bash

# 本地构建测试脚本 - 在提交前运行确保构建成功

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔨 正在执行本地构建测试...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 检查 node_modules 是否存在
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  未找到 node_modules，正在安装依赖...${NC}"
    npm install
fi

# 运行构建
echo -e "${CYAN}正在构建文档...${NC}"
if npm run build > /tmp/build.log 2>&1; then
    echo -e "${GREEN}✅ 构建成功！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}❌ 构建失败！${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}错误详情：${NC}"
    
    # 提取并显示关键错误信息
    grep -E "(Error:|Failed|Found dead link|missing|not found)" /tmp/build.log | while read -r line; do
        echo -e "${RED}  • $line${NC}"
    done
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}💡 提示：${NC}"
    echo -e "  1. 检查是否有死链接（dead links）"
    echo -e "  2. 确保所有引用的文件都存在"
    echo -e "  3. 运行 'npm run docs:dev' 在本地预览"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 询问是否查看完整日志
    read -p "是否查看完整构建日志？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cat /tmp/build.log
    fi
    
    exit 1
fi