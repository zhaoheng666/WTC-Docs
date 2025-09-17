#!/bin/bash

# 下载 Gitee 图片并更新 MD 文档引用
# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

echo -e "${CYAN}开始处理 Gitee 图片...${NC}"

# 创建临时文件存储找到的图片链接
TEMP_FILE="/tmp/gitee_images_$$.txt"

# 查找所有包含 Gitee 图片的 MD 文件
grep -r "https://gitee\.com.*\.\(png\|jpg\|jpeg\|gif\|webp\|svg\)" --include="*.md" . | while IFS=: read -r file rest; do
    # 提取图片URL
    echo "$rest" | grep -oE "https://gitee\.com[^)\"'\s]+" | grep -E "\.(png|jpg|jpeg|gif|webp|svg)" | while read -r url; do
        # 去掉可能的结尾字符
        url=$(echo "$url" | sed 's/[)​]*$//')
        echo "$file|$url" >> "$TEMP_FILE"
    done
done

# 检查是否找到图片
if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
    echo -e "${GREEN}没有找到 Gitee 图片链接${NC}"
    exit 0
fi

# 统计并显示找到的图片
total_images=$(wc -l < "$TEMP_FILE")
echo -e "${YELLOW}找到 $total_images 个 Gitee 图片链接${NC}"

# 处理每个图片
while IFS='|' read -r file url; do
    # 规范化文件路径
    file="${file#./}"
    
    echo -e "\n${CYAN}处理: $file${NC}"
    echo -e "  URL: $url"
    
    # 获取文件名
    filename=$(basename "$url" | sed 's/?.*$//')
    
    # 如果文件名太长或包含特殊字符，使用时间戳
    if [ ${#filename} -gt 50 ] || [[ "$filename" =~ [^a-zA-Z0-9._-] ]]; then
        ext="${filename##*.}"
        timestamp=$(date +%s%N)
        filename="gitee_${timestamp}.${ext}"
    fi
    
    # 确定保存目录（在文档同级目录下的 assets 文件夹）
    doc_dir=$(dirname "$file")
    assets_dir="$doc_dir/assets"
    
    # 创建 assets 目录
    mkdir -p "$assets_dir"
    
    # 下载图片
    target_file="$assets_dir/$filename"
    
    echo -e "  ${CYAN}下载到: $target_file${NC}"
    
    # 使用 curl 下载，添加 User-Agent 避免防盗链
    if curl -L -s -o "$target_file" \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        -H "Referer: https://gitee.com/" \
        "$url"; then
        
        # 检查文件是否下载成功
        if [ -f "$target_file" ] && [ -s "$target_file" ]; then
            echo -e "  ${GREEN}✓ 下载成功${NC}"
            
            # 计算相对路径
            relative_path="./assets/$filename"
            
            # 更新 MD 文件中的引用
            # 需要转义 URL 中的特殊字符
            escaped_url=$(printf '%s\n' "$url" | sed 's/[[\.*^$()+?{|]/\\&/g')
            escaped_path=$(printf '%s\n' "$relative_path" | sed 's/[[\.*^$()+?{|]/\\&/g')
            
            # 使用 sed 替换
            sed -i '' "s|${escaped_url}|${relative_path}|g" "$file"
            
            echo -e "  ${GREEN}✓ 更新引用${NC}"
        else
            echo -e "  ${RED}✗ 下载失败：文件为空${NC}"
            rm -f "$target_file"
        fi
    else
        echo -e "  ${RED}✗ 下载失败${NC}"
    fi
    
done < "$TEMP_FILE"

# 清理临时文件
rm -f "$TEMP_FILE"

echo -e "\n${GREEN}✅ Gitee 图片处理完成${NC}"

# 显示统计信息
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}统计信息：${NC}"
echo -e "  • 处理文档: $(grep -r "https://gitee\.com" --include="*.md" . | cut -d: -f1 | sort -u | wc -l) 个"
echo -e "  • 处理图片: $total_images 个"
echo -e "  • 新建 assets 目录: $(find . -type d -name "assets" -mmin -5 2>/dev/null | wc -l) 个"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"