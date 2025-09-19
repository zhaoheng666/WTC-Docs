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
                
                # 清理已处理的原始图片文件
                echo -e "${CYAN}🧹 清理已处理的原始图片...${NC}"
                
                # 查找所有包含已处理图片的 MD 文件
                PROCESSED_MDS=$(find . -name "*.md" -type f -exec grep -l "http://localhost:5173/WTC-Docs/assets/" {} \; 2>/dev/null)
                
                if [ -n "$PROCESSED_MDS" ]; then
                    TOTAL_DELETED=0
                    
                    # 对每个包含处理后图片的 MD 文件，找到并删除其原始图片
                    echo "$PROCESSED_MDS" | while read -r md_file; do
                        MD_DIR=$(dirname "$md_file")
                        
                        # 从 MD 文件中提取所有本地图片引用
                        LOCAL_IMAGES=$(grep -oE '!\[([^\]]*)\]\(([^)]+)\)' "$md_file" 2>/dev/null | \
                            grep -oE '\]\([^)]+\)' | \
                            sed 's/](\(.*\))/\1/' | \
                            grep -v "^http" | \
                            grep -E '\.(png|jpg|jpeg|gif|webp|svg)' 2>/dev/null)
                        
                        # 从 MD 文件中提取所有已处理的图片
                        PROCESSED_COUNT=$(grep -c "http://localhost:5173/WTC-Docs/assets/" "$md_file" 2>/dev/null || echo "0")
                        
                        # 如果有已处理的图片，且没有本地图片引用了
                        if [ "$PROCESSED_COUNT" -gt 0 ] && [ -z "$LOCAL_IMAGES" ]; then
                            # 删除常见的图片目录
                            for img_dir in assets images image img pics pictures; do
                                if [ -d "$MD_DIR/$img_dir" ]; then
                                    IMAGE_COUNT=$(find "$MD_DIR/$img_dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) 2>/dev/null | wc -l)
                                    if [ "$IMAGE_COUNT" -gt 0 ]; then
                                        echo -e "${CYAN}    删除 $MD_DIR/$img_dir 目录（含 $IMAGE_COUNT 个图片）${NC}"
                                        rm -rf "$MD_DIR/$img_dir"
                                        TOTAL_DELETED=$((TOTAL_DELETED + IMAGE_COUNT))
                                    fi
                                fi
                            done
                            
                            # 删除与 MD 文件同级目录的图片文件
                            SAME_DIR_IMAGES=$(find "$MD_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) 2>/dev/null)
                            if [ -n "$SAME_DIR_IMAGES" ]; then
                                SAME_DIR_COUNT=$(echo "$SAME_DIR_IMAGES" | wc -l)
                                echo -e "${CYAN}    删除 $MD_DIR 中的 $SAME_DIR_COUNT 个图片文件${NC}"
                                echo "$SAME_DIR_IMAGES" | xargs rm -f
                                TOTAL_DELETED=$((TOTAL_DELETED + SAME_DIR_COUNT))
                            fi
                        fi
                    done
                    
                    if [ $TOTAL_DELETED -gt 0 ]; then
                        echo -e "${GREEN}  ✓ 共删除 $TOTAL_DELETED 个原始图片${NC}"
                    else
                        echo -e "${GREEN}  ✓ 没有需要清理的图片${NC}"
                    fi
                else
                    echo -e "${GREEN}  ✓ 没有需要清理的图片${NC}"
                fi
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

# 2. 跳过统计生成（本地不生成，仅 CI 生成）
echo -e "${GREEN}  ✓ 跳过统计生成（仅在 CI 环境生成）${NC}"

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
    
    # 先尝试提取特定的错误行
    ERROR_LINES=$(grep -E "(Error:|ERROR|Failed|found dead link|missing|not found|✖|×)" "$BUILD_LOG" 2>/dev/null)
    
    if [ -n "$ERROR_LINES" ]; then
        echo "$ERROR_LINES" | while read -r line; do
            echo -e "${RED}  • $line${NC}"
        done
    else
        # 如果没有特定错误关键词，显示最后20行日志
        echo -e "${YELLOW}构建日志（最后20行）：${NC}"
        tail -20 "$BUILD_LOG" | while read -r line; do
            echo -e "${RED}  $line${NC}"
        done
    fi
    
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}💡 提示：完整日志已保存到 $BUILD_LOG${NC}"
    echo -e "${YELLOW}💡 提示：使用 'npm run dev' 在开发模式下调试${NC}"
    
    # 保留日志文件用于调试，不删除
    exit 1
fi