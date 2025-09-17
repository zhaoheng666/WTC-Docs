#!/bin/bash

# 修复图片路径脚本
# 将 /images/目录/文件名 改为相对路径

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔧 修复图片路径${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 统计变量
FIXED_FILES=0
TOTAL_REFS=0

echo -e "\n${CYAN}扫描并修复图片路径...${NC}"

# 查找所有包含 /images/ 路径的 MD 文件
find . -name "*.md" -type f | while read -r file; do
    # 跳过 node_modules 和 .vitepress/dist
    if [[ "$file" == *"node_modules"* ]] || [[ "$file" == *".vitepress/dist"* ]]; then
        continue
    fi
    
    # 检查是否包含 /images/ 路径的图片引用
    if grep -q "!\[.*\](/images/" "$file" 2>/dev/null; then
        # 获取文件所在目录的深度
        dir_path=$(dirname "$file")
        
        # 计算需要多少个 ../ 返回到根目录
        # 移除开头的 ./
        clean_path=${dir_path#./}
        
        # 如果在根目录
        if [ "$clean_path" = "." ]; then
            relative_prefix="."
        else
            # 计算目录深度
            depth=$(echo "$clean_path" | awk -F'/' '{print NF}')
            relative_prefix=""
            for ((i=0; i<depth; i++)); do
                if [ -z "$relative_prefix" ]; then
                    relative_prefix=".."
                else
                    relative_prefix="${relative_prefix}/.."
                fi
            done
        fi
        
        # 创建临时文件
        temp_file="${file}.tmp"
        
        # 替换图片路径：从 /images/... 改为相对路径
        # 例如：/images/其他/xxx.png -> ../images/其他/xxx.png
        sed -E "s|!\[([^\]]*)\]\(/images/|![\1](${relative_prefix}/images/|g" "$file" > "$temp_file"
        
        # 检查是否有变化
        if ! diff -q "$file" "$temp_file" > /dev/null 2>&1; then
            # 计算修改的引用数量
            refs_before=$(grep -c "!\[.*\](/images/" "$file" 2>/dev/null || echo 0)
            
            mv "$temp_file" "$file"
            ((FIXED_FILES++))
            ((TOTAL_REFS+=refs_before))
            
            echo -e "  ${GREEN}✓${NC} $(basename "$dir_path")/$(basename "$file") - 修复 ${CYAN}${refs_before}${NC} 个引用"
        else
            rm "$temp_file"
        fi
    fi
done

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ 路径修复完成！${NC}"
echo -e "  修复文件: ${CYAN}${FIXED_FILES}${NC} 个"
echo -e "  修复引用: ${CYAN}${TOTAL_REFS}${NC} 个"
echo -e "\n${CYAN}说明：${NC}"
echo -e "  • 图片路径已改为相对路径"
echo -e "  • 编辑器现在应该能正常预览图片"
echo -e "  • VitePress 构建警告应该消失"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0