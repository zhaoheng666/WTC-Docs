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

# 0. 处理图片引用和下载
if [ -f ".vitepress/scripts/image-processor.js" ]; then
    echo -e "${CYAN}🔍 检查 MD 文件中的图片...${NC}"

    # 检查是否有包含图片的 MD 文件更改（包括暂存、未暂存和未跟踪的文件）
    CHANGED_MDS=$(
        (git diff --cached --name-only; git diff --name-only; git ls-files --others --exclude-standard) |
        grep "\.md$" | sort -u
    )

    if [ -n "$CHANGED_MDS" ]; then
        MD_COUNT=$(echo "$CHANGED_MDS" | wc -l)
        echo -e "${CYAN}  • 发现 $MD_COUNT 个变更的 MD 文件${NC}"

        # 只要有 MD 文件变更就处理（image-processor 会自己判断是否需要清理）
        HAS_IMAGE_CHANGES=true
    fi

    if [ "$HAS_IMAGE_CHANGES" = true ]; then
        echo -e "${CYAN}🖼️  开始处理图片引用...${NC}"

        # 显示处理前的环境
        if [ -n "$GITHUB_ACTIONS" ]; then
            echo -e "${CYAN}  • 环境: GitHub Actions (生产环境)${NC}"
            echo -e "${CYAN}  • 目标 URL: https://zhaoheng666.github.io/WTC-Docs${NC}"
        else
            echo -e "${CYAN}  • 环境: 本地开发${NC}"
            echo -e "${CYAN}  • 目标 URL: http://localhost:5173/WTC-Docs${NC}"
        fi

        # 覆盖式写入日志（不追加）
        if node .vitepress/scripts/image-processor.js > /tmp/image-processor.log 2>&1; then
            # 提取处理信息
            MODIFIED=$(grep "Files modified:" /tmp/image-processor.log | grep -o "[0-9]*" | tail -1)
            DOWNLOADED=$(grep "Images downloaded:" /tmp/image-processor.log | grep -o "[0-9]*" | tail -1)
            PROCESSED=$(grep "Images processed:" /tmp/image-processor.log | grep -o "[0-9]*" | tail -1)
            EMBEDDED=$(grep "Embedded images extracted:" /tmp/image-processor.log | grep -o "[0-9]*" | tail -1)
            CLEANED=$(grep "Images cleaned:" /tmp/image-processor.log | grep -o "[0-9]*" | tail -1)

            if [ -n "$MODIFIED" ] && [ "$MODIFIED" -gt 0 ]; then
                echo -e "${GREEN}  ✓ 处理了 $MODIFIED 个文件${NC}"
            fi
            [ -n "$DOWNLOADED" ] && [ "$DOWNLOADED" -gt 0 ] && echo -e "${GREEN}  ✓ 下载了 $DOWNLOADED 个远程图片${NC}"
            [ -n "$PROCESSED" ] && [ "$PROCESSED" -gt 0 ] && echo -e "${GREEN}  ✓ 处理了 $PROCESSED 个本地图片${NC}"
            [ -n "$EMBEDDED" ] && [ "$EMBEDDED" -gt 0 ] && echo -e "${GREEN}  ✓ 提取了 $EMBEDDED 个内置图片${NC}"
            [ -n "$CLEANED" ] && [ "$CLEANED" -gt 0 ] && echo -e "${GREEN}  ✓ 自动清理了 $CLEANED 个未使用的图片${NC}"

            # 清理已处理文件的原始图片目录
            if [ -n "$MODIFIED" ] && [ "$MODIFIED" -gt 0 ]; then
                echo -e "${CYAN}🧹 清理原始图片目录...${NC}"

                # 从日志中提取处理过的文件
                PROCESSED_FILES=$(grep "✓ Processed:" /tmp/image-processor.log | sed 's/.*Processed: //')

                if [ -n "$PROCESSED_FILES" ]; then
                    echo "$PROCESSED_FILES" | while read -r md_file; do
                        if [ -f "$md_file" ]; then
                            MD_DIR=$(dirname "$md_file")

                            # 删除常见的图片目录
                            for img_dir in assets images image img pics pictures; do
                                if [ -d "$MD_DIR/$img_dir" ]; then
                                    echo -e "${CYAN}    • 删除 $MD_DIR/$img_dir/${NC}"
                                    rm -rf "$MD_DIR/$img_dir"
                                fi
                            done
                        fi
                    done
                    echo -e "${GREEN}  ✓ 原始图片目录清理完成${NC}"
                fi
            fi

            if [ -z "$MODIFIED" ] || [ "$MODIFIED" -eq 0 ]; then
                echo -e "${GREEN}  ✓ 图片已是最新状态${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠️  图片处理失败（继续构建）${NC}"
            # 显示错误信息
            if [ -f "/tmp/image-processor.log" ]; then
                ERROR_MSG=$(tail -5 /tmp/image-processor.log)
                [ -n "$ERROR_MSG" ] && echo -e "${YELLOW}    错误: $ERROR_MSG${NC}"
            fi
        fi
        # 保留日志文件用于调试，不删除
    else
        echo -e "${GREEN}  ✓ 跳过图片处理（无包含图片的 MD 文件变更）${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠️  image-processor.js 不存在，跳过图片处理${NC}"
fi

# 1. 跳过统计生成（本地不生成，仅 CI 生成）
echo -e "${GREEN}  ✓ 跳过统计生成（仅在 CI 环境生成）${NC}"

# 2. 执行构建
echo -e "${CYAN}🔨 执行 VitePress 构建...${NC}"
BUILD_LOG="/tmp/vitepress-build.log"

# 本地构建使用本地 URL
export VITE_BASE_URL="http://localhost:5173/WTC-Docs"

# 覆盖式写入构建日志
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
        echo -e "  • 构建日志：$BUILD_LOG"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi

    # 保留日志文件用于调试
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