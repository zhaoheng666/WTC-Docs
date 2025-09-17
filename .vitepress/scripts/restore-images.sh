#!/bin/bash

# 恢复图片到原始位置脚本
# 将 public/images 中的图片恢复到文档同目录，并修复引用路径

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔄 恢复图片到原始位置${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 统计变量
RESTORED_COUNT=0
UPDATED_REFS=0

# 1. 恢复所有图片文件
echo -e "\n${CYAN}恢复图片文件...${NC}"

# 处理每个子目录
for dir in public/images/*/; do
    if [ -d "$dir" ]; then
        # 获取目录名（如 "关卡"、"活动" 等）
        dirname=$(basename "$dir")
        target_dir="./$dirname"
        
        # 确保目标目录存在
        if [ -d "$target_dir" ]; then
            echo -e "${CYAN}处理目录: $dirname${NC}"
            
            # 复制所有图片文件
            for img in "$dir"*; do
                if [ -f "$img" ]; then
                    filename=$(basename "$img")
                    cp "$img" "$target_dir/$filename"
                    ((RESTORED_COUNT++))
                    echo -e "  ${GREEN}✓${NC} $filename"
                fi
            done
        fi
    fi
done

# 2. 修复 MD 文件中的图片引用
echo -e "\n${CYAN}修复图片引用...${NC}"

# 查找所有包含图片引用的 MD 文件
find . -name "*.md" -type f | while read -r file; do
    # 跳过 node_modules 和 .vitepress/dist
    if [[ "$file" == *"node_modules"* ]] || [[ "$file" == *".vitepress/dist"* ]]; then
        continue
    fi
    
    # 检查是否包含 /images/ 路径的图片引用
    if grep -q "!\[.*\](/images/" "$file" 2>/dev/null; then
        # 获取文件所在目录
        file_dir=$(dirname "$file")
        
        # 创建临时文件
        temp_file="${file}.tmp"
        
        # 替换图片路径：从 /images/目录名/文件名 改为 ./文件名
        sed -E 's|!\[([^\]]*)\]\(/images/[^/]+/([^)]+)\)|![\1](./\2)|g' "$file" > "$temp_file"
        
        # 检查是否有变化
        if ! diff -q "$file" "$temp_file" > /dev/null; then
            mv "$temp_file" "$file"
            ((UPDATED_REFS++))
            echo -e "  ${GREEN}✓${NC} $(basename "$file")"
        else
            rm "$temp_file"
        fi
    fi
done

# 3. 清理 public/images（可选）
echo -e "\n${CYAN}是否删除 public/images 中的图片？${NC}"
echo -e "${YELLOW}注意：删除后需要重新构建才能生成${NC}"
read -p "删除 public/images? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf public/images
    echo -e "${GREEN}✓ 已清理 public/images${NC}"
else
    echo -e "${YELLOW}保留 public/images${NC}"
fi

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ 恢复完成！${NC}"
echo -e "  恢复图片: ${CYAN}$RESTORED_COUNT${NC} 个"
echo -e "  修复引用: ${CYAN}$UPDATED_REFS${NC} 个文件"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0