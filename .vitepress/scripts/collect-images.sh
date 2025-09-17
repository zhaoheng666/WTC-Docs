#!/bin/bash

# 图片自动收集脚本
# 在构建前自动将分散的图片收集到 public 目录
# 并更新 MD 文件中的引用路径

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PUBLIC_DIR="$DOCS_DIR/public"
IMAGES_DIR="$PUBLIC_DIR/images"

cd "$DOCS_DIR" || exit 1

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🖼️  正在收集和整理图片资源...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 创建 public/images 目录
mkdir -p "$IMAGES_DIR"

# 统计变量
TOTAL_IMAGES=0
MOVED_IMAGES=0
UPDATED_FILES=0

# 支持的图片格式
IMAGE_EXTENSIONS="png|jpg|jpeg|gif|svg|webp|ico|bmp"

# 创建临时文件记录更改
TEMP_CHANGES="/tmp/image_changes_$$.txt"
TEMP_MOVED="/tmp/image_moved_$$.txt"
> "$TEMP_CHANGES"
> "$TEMP_MOVED"

# 使用进程替换避免子 shell 导致的变量作用域问题
# 创建临时文件存储统计信息
TEMP_STATS="/tmp/image_stats_$$.txt"
echo "0 0 0" > "$TEMP_STATS"

# 扫描所有 MD 文件
echo -e "${CYAN}扫描 Markdown 文件...${NC}"

while IFS= read -r md_file; do
    # 获取 MD 文件的相对路径（去掉 ./）
    md_path="${md_file#./}"
    md_dir=$(dirname "$md_path")
    
    # 查找文件中的所有图片引用 - 使用更精确的正则来处理一行多个图片
    # 匹配 ![...](...) 格式，使用非贪婪匹配
    grep -o '!\[[^]]*\]([^)]*)' "$md_file" | while read -r match; do
        # 提取括号中的路径
        img_path=$(echo "$match" | sed 's/.*](\([^)]*\)).*/\1/')
        
        # 跳过空路径
        if [ -z "$img_path" ]; then
            continue
        fi
        
        # 跳过外部链接和已经在 public 中的图片
        if echo "$img_path" | grep -q '^https\?://\|^/images/'; then
            continue
        fi
        
        # 移除开头的 ./
        img_path="${img_path#./}"
        
        # 构建完整的源路径
        if [ "${img_path:0:1}" = "/" ]; then
            # 绝对路径（从 docs 根目录开始）
            source_path="${DOCS_DIR}${img_path}"
        else
            # 相对路径（相对于 MD 文件）
            source_path="${DOCS_DIR}/${md_dir}/${img_path}"
        fi
        
        # 规范化路径
        source_path=$(realpath "$source_path" 2>/dev/null)
        
        # 检查图片是否存在
        if [ -f "$source_path" ]; then
            # 更新统计信息
            read -r t m u < "$TEMP_STATS"
            t=$((t + 1))
            echo "$t $m $u" > "$TEMP_STATS"
            
            # 生成目标路径（保持目录结构避免冲突）
            # 使用 MD 文件路径作为子目录
            target_subdir="${md_dir//\//_}"
            if [ "$target_subdir" = "." ]; then
                target_subdir="root"
            fi
            target_dir="$IMAGES_DIR/$target_subdir"
            mkdir -p "$target_dir"
            
            img_name=$(basename "$img_path")
            target_path="$target_dir/$img_name"
            
            # 复制图片到 public/images
            if cp "$source_path" "$target_path" 2>/dev/null; then
                # 更新统计信息
                read -r t m u < "$TEMP_STATS"
                m=$((m + 1))
                echo "$t $m $u" > "$TEMP_STATS"
                
                # 计算新的引用路径
                new_path="/images/$target_subdir/$img_name"
                
                # 记录需要替换的内容
                echo "$md_file|$img_path|$new_path" >> "$TEMP_CHANGES"
                
                # 记录已移动的原始文件（用于后续删除）
                echo "$source_path" >> "$TEMP_MOVED"
                
                echo -e "${GREEN}  ✓ 收集: $img_path → $new_path${NC}"
            else
                echo -e "${YELLOW}  ⚠️  无法复制: $source_path${NC}"
            fi
        fi
    done
    
    # 同样处理 HTML img 标签
    grep -o '<img[^>]*src="[^"]*"' "$md_file" | while read -r match; do
        # 提取 src 属性值
        img_path=$(echo "$match" | sed 's/.*src="\([^"]*\)".*/\1/')
        
        # 跳过空路径、外部链接和已处理的路径
        if [ -z "$img_path" ] || echo "$img_path" | grep -q '^https\?://\|^/images/'; then
            continue
        fi
        
        # 移除开头的 ./
        img_path="${img_path#./}"
        
        # 构建完整的源路径
        if [ "${img_path:0:1}" = "/" ]; then
            source_path="${DOCS_DIR}${img_path}"
        else
            source_path="${DOCS_DIR}/${md_dir}/${img_path}"
        fi
        
        # 规范化路径
        source_path=$(realpath "$source_path" 2>/dev/null)
        
        # 检查图片是否存在
        if [ -f "$source_path" ]; then
            # 更新统计信息
            read -r t m u < "$TEMP_STATS"
            t=$((t + 1))
            echo "$t $m $u" > "$TEMP_STATS"
            
            # 生成目标路径
            target_subdir="${md_dir//\//_}"
            if [ "$target_subdir" = "." ]; then
                target_subdir="root"
            fi
            target_dir="$IMAGES_DIR/$target_subdir"
            mkdir -p "$target_dir"
            
            img_name=$(basename "$img_path")
            target_path="$target_dir/$img_name"
            
            # 复制图片
            if cp "$source_path" "$target_path" 2>/dev/null; then
                # 更新统计信息
                read -r t m u < "$TEMP_STATS"
                m=$((m + 1))
                echo "$t $m $u" > "$TEMP_STATS"
                
                # 计算新的引用路径
                new_path="/images/$target_subdir/$img_name"
                
                # 记录需要替换的内容
                echo "$md_file|$img_path|$new_path" >> "$TEMP_CHANGES"
                
                # 记录已移动的原始文件（用于后续删除）
                echo "$source_path" >> "$TEMP_MOVED"
                
                echo -e "${GREEN}  ✓ 收集: $img_path → $new_path${NC}"
            fi
        fi
    done
done < <(find . -name "*.md" -type f | grep -v node_modules | grep -v ".vitepress")

# 从临时文件读取统计信息
read -r TOTAL_IMAGES MOVED_IMAGES UPDATED_FILES < "$TEMP_STATS"

# 应用所有更改到 MD 文件
if [ -s "$TEMP_CHANGES" ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}更新 Markdown 文件中的图片引用...${NC}"
    
    # 获取所有需要更新的文件列表
    while IFS= read -r md_file; do
        # 创建临时文件
        temp_file="${md_file}.tmp"
        cp "$md_file" "$temp_file"
        
        # 应用所有替换
        grep "^${md_file}|" "$TEMP_CHANGES" | while IFS='|' read -r file old_path new_path; do
            # 转义特殊字符
            escaped_old=$(printf '%s\n' "$old_path" | sed 's/[[\.*^$()+?{|]/\\&/g')
            escaped_new=$(printf '%s\n' "$new_path" | sed 's/[[\.*^$()+?{|]/\\&/g')
            
            # 替换路径
            sed -i.bak "s|$escaped_old|$escaped_new|g" "$temp_file"
        done
        
        # 如果有实际更改，覆盖原文件
        if ! cmp -s "$md_file" "$temp_file"; then
            mv "$temp_file" "$md_file"
            echo -e "${GREEN}  ✓ 更新: $md_file${NC}"
            UPDATED_FILES=$((UPDATED_FILES + 1))
        else
            rm -f "$temp_file"
        fi
        
        # 清理备份文件
        rm -f "${temp_file}.bak"
    done < <(cut -d'|' -f1 "$TEMP_CHANGES" | sort -u)
fi

# 删除原始图片文件（如果成功收集）
DELETED_FILES=0
CLEANED_DIRS=0
TEMP_DELETE_COUNT="/tmp/delete_count_$$.txt"
echo "0 0" > "$TEMP_DELETE_COUNT"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}检查是否需要删除原始文件...${NC}"
echo -e "  • TEMP_MOVED 文件大小: $(wc -l < "$TEMP_MOVED" 2>/dev/null || echo 0) 行"
echo -e "  • 更新的文件数: $UPDATED_FILES"

if [ -s "$TEMP_MOVED" ] && [ $UPDATED_FILES -gt 0 ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}删除原始图片文件...${NC}"
    
    # 读取所有已移动的文件并删除
    while IFS= read -r original_file; do
        if [ -f "$original_file" ]; then
            # 获取相对路径用于显示
            rel_path="${original_file#$DOCS_DIR/}"
            
            # 再次检查文件是否已被成功复制到 public
            img_name=$(basename "$original_file")
            if find "$IMAGES_DIR" -name "$img_name" -type f | grep -q .; then
                if rm -f "$original_file" 2>/dev/null; then
                    echo -e "${GREEN}  ✓ 删除: $rel_path${NC}"
                    read -r d c < "$TEMP_DELETE_COUNT"
                    d=$((d + 1))
                    echo "$d $c" > "$TEMP_DELETE_COUNT"
                    
                    # 检查并删除空目录
                    parent_dir=$(dirname "$original_file")
                    while [ "$parent_dir" != "$DOCS_DIR" ] && [ "$parent_dir" != "/" ]; do
                        # 只删除 image、images、assets、asset 目录
                        dir_name=$(basename "$parent_dir")
                        if [[ "$dir_name" =~ ^(image|images|asset|assets)$ ]]; then
                            if [ -d "$parent_dir" ] && [ -z "$(ls -A "$parent_dir" 2>/dev/null)" ]; then
                                if rmdir "$parent_dir" 2>/dev/null; then
                                    echo -e "${GREEN}  ✓ 清理空目录: ${parent_dir#$DOCS_DIR/}${NC}"
                                    read -r d c < "$TEMP_DELETE_COUNT"
                                    c=$((c + 1))
                                    echo "$d $c" > "$TEMP_DELETE_COUNT"
                                fi
                            else
                                break
                            fi
                        else
                            break
                        fi
                        parent_dir=$(dirname "$parent_dir")
                    done
                else
                    echo -e "${YELLOW}  ⚠️  无法删除: $rel_path${NC}"
                fi
            else
                echo -e "${YELLOW}  ⚠️  跳过删除（未找到副本）: $rel_path${NC}"
            fi
        fi
    done < <(sort -u "$TEMP_MOVED")
fi

# 读取删除计数
read -r DELETED_FILES CLEANED_DIRS < "$TEMP_DELETE_COUNT"

# 额外清理：查找已经迁移到 public/images 但源文件仍存在的情况
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}检查遗留的源文件...${NC}"

find . -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" -o -name "*.webp" -o -name "*.ico" -o -name "*.bmp" \) \
    ! -path "./node_modules/*" ! -path "./.vitepress/*" ! -path "./public/*" | while read -r source_file; do
    
    # 只处理 image/images/asset/assets 目录下的文件
    if echo "$source_file" | grep -qE "/(image|images|asset|assets)/"; then
        img_name=$(basename "$source_file")
        
        # 检查是否已经在 public/images 中存在
        if find "$IMAGES_DIR" -name "$img_name" -type f | grep -q .; then
            # 检查是否有 MD 文件引用了 /images/ 路径的这个图片
            if grep -r "/images/.*$img_name" . --include="*.md" --quiet 2>/dev/null; then
                rel_path="${source_file#./}"
                echo -e "${YELLOW}  ⚠️  发现遗留文件: $rel_path${NC}"
                
                if rm -f "$source_file" 2>/dev/null; then
                    echo -e "${GREEN}  ✓ 删除遗留文件: $rel_path${NC}"
                    DELETED_FILES=$((DELETED_FILES + 1))
                    
                    # 尝试清理空目录
                    parent_dir=$(dirname "$source_file")
                    while [ "$parent_dir" != "." ] && [ "$parent_dir" != "/" ]; do
                        dir_name=$(basename "$parent_dir")
                        if [[ "$dir_name" =~ ^(image|images|asset|assets)$ ]]; then
                            if [ -d "$parent_dir" ] && [ -z "$(ls -A "$parent_dir" 2>/dev/null)" ]; then
                                if rmdir "$parent_dir" 2>/dev/null; then
                                    echo -e "${GREEN}  ✓ 清理空目录: ${parent_dir#./}${NC}"
                                    CLEANED_DIRS=$((CLEANED_DIRS + 1))
                                fi
                            else
                                break
                            fi
                        else
                            break
                        fi
                        parent_dir=$(dirname "$parent_dir")
                    done
                fi
            fi
        fi
    fi
done

# 清理临时文件
rm -f "$TEMP_CHANGES" "$TEMP_MOVED" "$TEMP_STATS" "$TEMP_DELETE_COUNT"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 图片收集完成${NC}"
echo -e "  • 扫描到 ${TOTAL_IMAGES} 个图片引用"
echo -e "  • 收集了 ${MOVED_IMAGES} 个图片"
echo -e "  • 更新了 ${UPDATED_FILES} 个文件"
if [ $DELETED_FILES -gt 0 ]; then
    echo -e "  • 删除了 ${DELETED_FILES} 个原始文件"
fi
if [ $CLEANED_DIRS -gt 0 ]; then
    echo -e "  • 清理了 ${CLEANED_DIRS} 个空目录"
fi
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 如果有图片被收集，提醒需要提交
if [ $MOVED_IMAGES -gt 0 ]; then
    echo -e "${YELLOW}💡 提示：图片已收集到 public/images，原始文件已删除${NC}"
fi

exit 0