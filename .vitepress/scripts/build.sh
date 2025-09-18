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

# 0. 处理图片引用和下载（仅当有 md 文件更改或包含图片时）
if [ -f ".vitepress/scripts/image-processor.js" ]; then
    # 检查是否有包含图片的 MD 文件更改（包括暂存、未暂存和未跟踪的文件）
    HAS_IMAGE_CHANGES=$(
        (git diff --cached --name-only; git diff --name-only; git ls-files --others --exclude-standard) | 
        grep "\.md$" | 
        xargs grep -l "!\[.*\](" 2>/dev/null | 
        head -1
    )
    
    if [ -n "$HAS_IMAGE_CHANGES" ]; then
        echo -e "${CYAN}🖼️  处理图片引用...${NC}"
        if node .vitepress/scripts/image-processor.js > /tmp/image-processor.log 2>&1; then
            MODIFIED=$(grep "Files modified:" /tmp/image-processor.log | grep -o "[0-9]*" | tail -1)
            if [ -n "$MODIFIED" ] && [ "$MODIFIED" -gt 0 ]; then
                echo -e "${GREEN}  ✓ 处理了 $MODIFIED 个文件的图片引用${NC}"
            else
                echo -e "${GREEN}  ✓ 图片引用已是最新${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠️  图片处理失败（继续构建）${NC}"
        fi
        rm -f /tmp/image-processor.log
    else
        echo -e "${GREEN}  ✓ 跳过图片处理（无图片更改）${NC}"
    fi
fi

# 1. 确保符号链接存在（用于编辑器预览）
if [ ! -L "images" ] && [ -d "public/images" ]; then
    ln -s public/images images 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ 创建图片符号链接${NC}"
    fi
fi

# 2. 生成统计页面（本地版本，不含提交历史）
if [ -f ".vitepress/scripts/generate-stats.js" ]; then
    echo -e "${CYAN}📊 生成统计页面...${NC}"
    if node .vitepress/scripts/generate-stats.js > /tmp/stats-gen.log 2>&1; then
        echo -e "${GREEN}  ✓ 统计页面已生成${NC}"
    else
        echo -e "${YELLOW}  ⚠️  统计生成失败（继续构建）${NC}"
    fi
    rm -f /tmp/stats-gen.log
fi

# 3. 执行构建
echo -e "${CYAN}🔨 执行 VitePress 构建...${NC}"
BUILD_LOG="/tmp/vitepress-build.log"

# 本地构建使用本地 URL
export VITE_BASE_URL="http://localhost:5173/WTC-Docs"

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