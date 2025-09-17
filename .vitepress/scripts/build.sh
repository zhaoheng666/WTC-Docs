#!/bin/bash

# 文档构建脚本
# 包含：增量图片收集、统计生成、构建测试

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
echo -e "${CYAN}🏗️  开始构建文档...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. 增量收集图片资源
if [ -f ".vitepress/scripts/collect-images-incremental.sh" ]; then
    echo -e "${CYAN}🖼️  收集图片资源...${NC}"
    if bash .vitepress/scripts/collect-images-incremental.sh > /tmp/collect-images.log 2>&1; then
        COLLECTED=$(grep "收集了" /tmp/collect-images.log | grep -o "[0-9]*" | head -1)
        if [ -n "$COLLECTED" ] && [ "$COLLECTED" -gt 0 ]; then
            echo -e "${GREEN}  ✓ 收集了 $COLLECTED 个新图片${NC}"
        else
            echo -e "${GREEN}  ✓ 图片资源已是最新${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠️  图片收集失败（继续构建）${NC}"
    fi
    rm -f /tmp/collect-images.log
fi

# 1.5 确保符号链接存在（用于编辑器预览）
if [ ! -L "images" ] && [ -d "public/images" ]; then
    ln -s public/images images 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ 创建图片符号链接${NC}"
    fi
fi

# 2. 生成统计数据（优先使用简化版）
if [ -f ".vitepress/scripts/generate-stats-simple.sh" ]; then
    echo -e "${CYAN}📊 更新统计数据（简化版）...${NC}"
    bash .vitepress/scripts/generate-stats-simple.sh > /dev/null 2>&1
    echo -e "${GREEN}  ✓ 统计数据已生成${NC}"
elif [ -f ".vitepress/scripts/generate-stats.sh" ]; then
    echo -e "${CYAN}📊 更新统计数据...${NC}"
    if bash .vitepress/scripts/generate-stats.sh > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ 统计数据已更新${NC}"
    else
        echo -e "${YELLOW}  ⚠️  统计更新失败（非关键）${NC}"
    fi
fi

# 3. 执行构建
echo -e "${CYAN}🔨 执行 VitePress 构建...${NC}"
BUILD_LOG="/tmp/vitepress-build.log"

if npx vitepress build > "$BUILD_LOG" 2>&1; then
    echo -e "${GREEN}  ✓ 构建成功${NC}"
    
    # 显示构建产物信息
    if [ -d ".vitepress/dist" ]; then
        FILE_COUNT=$(find .vitepress/dist -type f | wc -l)
        DIR_SIZE=$(du -sh .vitepress/dist | cut -f1)
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ 文档构建完成${NC}"
        echo -e "  • 文件数量：${FILE_COUNT} 个"
        echo -e "  • 总大小：${DIR_SIZE}"
        echo -e "  • 输出目录：.vitepress/dist"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    
    rm -f "$BUILD_LOG"
    exit 0
else
    echo -e "${RED}  ✗ 构建失败${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 显示错误信息
    echo -e "${YELLOW}错误详情：${NC}"
    grep -E "(Error:|ERROR|Failed|found dead link|missing|not found)" "$BUILD_LOG" | while read -r line; do
        echo -e "${RED}  • $line${NC}"
    done
    
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}💡 提示：使用 'npm run dev' 在开发模式下调试${NC}"
    
    rm -f "$BUILD_LOG"
    exit 1
fi