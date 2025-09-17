#!/bin/bash

# 提交前检查脚本 - 确保构建成功才能提交

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🚦 正在执行提交前检查...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 1. 检查是否有未暂存的更改
UNSTAGED=$(git diff --name-only)
if [ -n "$UNSTAGED" ]; then
    echo -e "${YELLOW}⚠️  检测到未暂存的更改：${NC}"
    echo "$UNSTAGED" | sed 's/^/  • /'
    echo -e "${YELLOW}请先使用 'git add' 暂存更改${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

# 2. 生成最新的统计数据
echo -e "${CYAN}📊 更新统计数据...${NC}"
if [ -f ".vitepress/scripts/generate-stats.sh" ]; then
    bash .vitepress/scripts/generate-stats.sh > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ 统计数据已更新${NC}"
        # 添加更新后的文件
        git add public/stats.json 2>/dev/null
        git add 其他/隐藏/统计仪表板.md 2>/dev/null
    else
        echo -e "${YELLOW}  ⚠️  统计数据更新失败（非关键）${NC}"
    fi
fi

# 3. 运行构建测试
echo -e "${CYAN}🔨 执行构建测试...${NC}"
BUILD_LOG="/tmp/pre-commit-build.log"
if npm run build > "$BUILD_LOG" 2>&1; then
    echo -e "${GREEN}  ✓ 构建成功${NC}"
else
    echo -e "${RED}  ✗ 构建失败！${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 显示错误信息
    echo -e "${YELLOW}错误详情：${NC}"
    grep -E "(Error:|Failed|Found dead link|missing|not found)" "$BUILD_LOG" | while read -r line; do
        echo -e "${RED}  • $line${NC}"
    done
    
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}请修复构建错误后再提交！${NC}"
    
    # 询问是否继续提交
    read -p "是否强制继续提交？(不推荐) (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 4. 显示即将提交的文件
echo -e "${CYAN}📝 即将提交的文件：${NC}"
git diff --cached --name-status | while read -r line; do
    status=$(echo "$line" | cut -f1)
    file=$(echo "$line" | cut -f2)
    case $status in
        A) echo -e "${GREEN}  + $file${NC}" ;;
        M) echo -e "${YELLOW}  ± $file${NC}" ;;
        D) echo -e "${RED}  - $file${NC}" ;;
        *) echo -e "    $line" ;;
    esac
done

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 所有检查通过，可以提交！${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 清理临时文件
rm -f "$BUILD_LOG"

exit 0