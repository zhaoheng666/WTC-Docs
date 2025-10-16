#!/bin/zsh

# 文档构建脚本
# 包含：增量图片收集、统计生成、构建测试

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🏗️  开始构建文档...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 0. 修复有问题的文件名
if [ -f ".vitepress/scripts/fix-problematic-filenames.js" ]; then
    echo -e "${CYAN}🔧 修复有问题的文件名...${NC}"

    # 预览模式检查是否需要修复
    FIX_OUTPUT=$(node .vitepress/scripts/fix-problematic-filenames.js --dry-run 2>&1)

    if echo "$FIX_OUTPUT" | grep -E "📄.*->" >/dev/null; then
        echo -e "${CYAN}  • 发现需要修复的文件名${NC}"

        # 实际执行修复
        if node .vitepress/scripts/fix-problematic-filenames.js > /tmp/fix-filenames.log 2>&1; then
            FIXED_COUNT=$(grep -E "📄.*->" /tmp/fix-filenames.log | wc -l)
            echo -e "${GREEN}  ✓ 修复了 $FIXED_COUNT 个文件/目录${NC}"
        else
            echo -e "${YELLOW}  ⚠️  文件名修复失败（继续构建）${NC}"
            # 显示错误信息
            if [ -f "/tmp/fix-filenames.log" ]; then
                ERROR_MSG=$(tail -3 /tmp/fix-filenames.log)
                [ -n "$ERROR_MSG" ] && echo -e "${YELLOW}    错误: $ERROR_MSG${NC}"
            fi
        fi
    else
        echo -e "${GREEN}  ✓ 文件名没有问题${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠️  fix-problematic-filenames.js 不存在，跳过文件名修复${NC}"
fi

# 0. 处理图片引用和下载
if [ -f ".vitepress/scripts/image-processor.js" ]; then
    echo -e "${CYAN}🔍 检查 MD 文件中的图片...${NC}"

    # 检查是否有包含图片的 MD 文件更改（包括暂存、未暂存和未跟踪的文件）
    # 禁用 Git 的路径引号，以便正确处理中文文件名
    CHANGED_MDS=$(
        (git -c core.quotePath=false diff --cached --name-only; \
         git -c core.quotePath=false diff --name-only; \
         git -c core.quotePath=false ls-files --others --exclude-standard) |
        grep "\.md$" | sort -u
    )

    # 调试输出
    if [ -n "$DEBUG" ]; then
        echo -e "${YELLOW}DEBUG: 检测到的 MD 文件:${NC}" >&2
        echo "$CHANGED_MDS" >&2
        echo -e "${YELLOW}DEBUG: 文件数量: $(echo "$CHANGED_MDS" | grep -c '^')${NC}" >&2
    fi

    if [ -n "$CHANGED_MDS" ]; then
        MD_COUNT=$(echo "$CHANGED_MDS" | wc -l | tr -d ' ')
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
                            for img_dir in assets images image img pics pictures media; do
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

# 0.5. 处理 PDF 文件
if [ -f ".vitepress/scripts/pdf-processor.js" ]; then
    echo -e "${CYAN}📄 处理 PDF 文件...${NC}"

    # 覆盖式写入日志（不追加）
    if node .vitepress/scripts/pdf-processor.js > /tmp/pdf-processor.log 2>&1; then
        # 提取处理信息
        PDF_FOUND=$(grep "发现 PDF 文件:" /tmp/pdf-processor.log | grep -o "[0-9]* 个" | grep -o "[0-9]*")
        PDF_COPIED=$(grep "新复制文件:" /tmp/pdf-processor.log | grep -o "[0-9]* 个" | grep -o "[0-9]*")

        if [ -n "$PDF_FOUND" ] && [ "$PDF_FOUND" -gt 0 ]; then
            echo -e "${GREEN}  ✓ 发现 $PDF_FOUND 个 PDF 文件${NC}"
            if [ -n "$PDF_COPIED" ] && [ "$PDF_COPIED" -gt 0 ]; then
                echo -e "${GREEN}  ✓ 复制了 $PDF_COPIED 个新 PDF 文件${NC}"
            fi
            echo -e "${GREEN}  ✓ 更新了其他/index.md 链接${NC}"
        else
            echo -e "${GREEN}  ✓ 没有找到 PDF 文件${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠️  PDF 处理失败（继续构建）${NC}"
        # 显示错误信息
        if [ -f "/tmp/pdf-processor.log" ]; then
            ERROR_MSG=$(tail -3 /tmp/pdf-processor.log)
            [ -n "$ERROR_MSG" ] && echo -e "${YELLOW}    错误: $ERROR_MSG${NC}"
        fi
    fi
    # 保留日志文件用于调试，不删除
else
    echo -e "${YELLOW}  ⚠️  pdf-processor.js 不存在，跳过 PDF 处理${NC}"
fi

# 0.7. 处理文档链接（转换相对路径为根路径）
if [ -f ".vitepress/scripts/link-processor.js" ]; then
    echo -e "${CYAN}🔗 处理文档链接...${NC}"

    # 覆盖式写入日志（不追加）
    if node .vitepress/scripts/link-processor.js > /tmp/link-processor.log 2>&1; then
        # 提取处理信息
        MODIFIED=$(grep "Files modified:" /tmp/link-processor.log | grep -o "[0-9]*" | tail -1)
        CONVERTED=$(grep "Links converted:" /tmp/link-processor.log | grep -o "[0-9]*" | tail -1)
        SKIPPED=$(grep "Links skipped:" /tmp/link-processor.log | grep -o "[0-9]*" | tail -1)

        if [ -n "$MODIFIED" ] && [ "$MODIFIED" -gt 0 ]; then
            echo -e "${GREEN}  ✓ 处理了 $MODIFIED 个文件${NC}"
        fi
        [ -n "$CONVERTED" ] && [ "$CONVERTED" -gt 0 ] && echo -e "${GREEN}  ✓ 转换了 $CONVERTED 个相对路径链接为根路径格式${NC}"
        [ -n "$SKIPPED" ] && [ "$SKIPPED" -gt 0 ] && echo -e "${CYAN}  • 跳过了 $SKIPPED 个链接（已是根路径格式）${NC}"

        if [ -z "$MODIFIED" ] || [ "$MODIFIED" -eq 0 ]; then
            echo -e "${GREEN}  ✓ 链接已是根路径格式${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠️  链接处理失败（继续构建）${NC}"
        # 显示错误信息
        if [ -f "/tmp/link-processor.log" ]; then
            ERROR_MSG=$(tail -5 /tmp/link-processor.log)
            [ -n "$ERROR_MSG" ] && echo -e "${YELLOW}    错误: $ERROR_MSG${NC}"
        fi
    fi
    # 保留日志文件用于调试，不删除
else
    echo -e "${YELLOW}  ⚠️  link-processor.js 不存在，跳过链接处理${NC}"
fi

# 0.8. 生成目录索引文件树
if [ -f ".vitepress/scripts/generate-directory-index.js" ]; then
    echo -e "${CYAN}📁 生成目录索引文件树...${NC}"

    # 覆盖式写入日志（不追加）
    if node .vitepress/scripts/generate-directory-index.js > /tmp/directory-index.log 2>&1; then
        # 提取处理信息
        PROCESSED=$(grep "处理目录:" /tmp/directory-index.log | grep -o "[0-9]*" | tail -1)
        SUCCESS=$(grep "成功生成:" /tmp/directory-index.log | grep -o "[0-9]*" | tail -1)

        if [ -n "$PROCESSED" ] && [ "$PROCESSED" -gt 0 ]; then
            echo -e "${GREEN}  ✓ 处理了 $PROCESSED 个目录${NC}"
            if [ -n "$SUCCESS" ] && [ "$SUCCESS" -gt 0 ]; then
                echo -e "${GREEN}  ✓ 成功生成 $SUCCESS 个索引文件${NC}"
            fi
        else
            echo -e "${GREEN}  ✓ 目录索引已是最新状态${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠️  目录索引生成失败（继续构建）${NC}"
        # 显示错误信息
        if [ -f "/tmp/directory-index.log" ]; then
            ERROR_MSG=$(tail -3 /tmp/directory-index.log)
            [ -n "$ERROR_MSG" ] && echo -e "${YELLOW}    错误: $ERROR_MSG${NC}"
        fi
    fi
    # 保留日志文件用于调试，不删除
else
    echo -e "${YELLOW}  ⚠️  generate-directory-index.js 不存在，跳过目录索引生成${NC}"
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