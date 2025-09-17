#!/bin/bash

# 增量图片收集脚本
# 只处理 git 中新增或修改的 MD 文件

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

# 创建 public/images 目录
mkdir -p "$IMAGES_DIR"

# 统计变量
TOTAL_IMAGES=0
MOVED_IMAGES=0
UPDATED_FILES=0
DELETED_FILES=0

# 支持的图片格式
IMAGE_EXTENSIONS="png|jpg|jpeg|gif|svg|webp|ico|bmp"

# 创建临时文件
TEMP_CHANGES="/tmp/image_changes_$$.txt"
TEMP_MOVED="/tmp/image_moved_$$.txt"
> "$TEMP_CHANGES"
> "$TEMP_MOVED"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🖼️  增量收集图片资源...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 获取已修改和新增的 MD 文件
CHANGED_FILES=$(git diff --name-only --diff-filter=AM HEAD -- "*.md" 2>/dev/null)
STAGED_FILES=$(git diff --name-only --cached --diff-filter=AM -- "*.md" 2>/dev/null)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard -- "*.md" 2>/dev/null)

# 合并所有需要处理的文件
ALL_FILES=$(echo -e "$CHANGED_FILES\n$STAGED_FILES\n$UNTRACKED_FILES" | sort -u | grep -v '^$')

if [ -z "$ALL_FILES" ]; then
    echo -e "${GREEN}没有需要处理的 MD 文件${NC}"
    exit 0
fi

echo -e "${CYAN}找到以下待处理文件：${NC}"
echo "$ALL_FILES" | while read -r file; do
    echo -e "  • $file"
done
echo ""

# 处理每个文件
echo "$ALL_FILES" | while read -r md_file; do
    [ -z "$md_file" ] && continue
    [ ! -f "$md_file" ] && continue
    
    echo -e "${CYAN}处理: $md_file${NC}"
    md_dir=$(dirname "$md_file")
    
    # 查找文件中的所有图片引用
    # 匹配 ![...](...) 格式
    grep -o '!\[[^]]*\]([^)]*)' "$md_file" 2>/dev/null | while read -r match; do
        # 提取括号中的路径
        img_path=$(echo "$match" | sed 's/.*](\([^)]*\)).*/\1/')
        
        # 跳过空路径、外部链接和已在 public 中的图片
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
            TOTAL_IMAGES=$((TOTAL_IMAGES + 1))
            
            # 生成目标路径（保持目录结构）
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
                MOVED_IMAGES=$((MOVED_IMAGES + 1))
                
                # 计算新的引用路径
                new_path="/images/$target_subdir/$img_name"
                
                # 记录需要替换的内容
                echo "$md_file|$img_path|$new_path" >> "$TEMP_CHANGES"
                
                # 记录已移动的原始文件
                echo "$source_path" >> "$TEMP_MOVED"
                
                echo -e "${GREEN}  ✓ 收集: $img_path → $new_path${NC}"
            fi
        fi
    done
    
    # 同样处理 HTML img 标签
    grep -o '<img[^>]*src="[^"]*"' "$md_file" 2>/dev/null | while read -r match; do
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
            TOTAL_IMAGES=$((TOTAL_IMAGES + 1))
            
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
                MOVED_IMAGES=$((MOVED_IMAGES + 1))
                
                # 计算新的引用路径
                new_path="/images/$target_subdir/$img_name"
                
                # 记录需要替换的内容
                echo "$md_file|$img_path|$new_path" >> "$TEMP_CHANGES"
                
                # 记录已移动的原始文件
                echo "$source_path" >> "$TEMP_MOVED"
                
                echo -e "${GREEN}  ✓ 收集: $img_path → $new_path${NC}"
            fi
        fi
    done
done

# 应用更改到 MD 文件
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
if [ -s "$TEMP_MOVED" ] && [ $UPDATED_FILES -gt 0 ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}删除原始图片文件...${NC}"
    
    # 读取所有已移动的文件并删除
    sort -u "$TEMP_MOVED" | while read -r original_file; do
        if [ -f "$original_file" ]; then
            # 获取相对路径用于显示
            rel_path="${original_file#$DOCS_DIR/}"
            
            # 再次检查文件是否已被成功复制到 public
            img_name=$(basename "$original_file")
            if find "$IMAGES_DIR" -name "$img_name" -type f | grep -q .; then
                if rm -f "$original_file" 2>/dev/null; then
                    echo -e "${GREEN}  ✓ 删除: $rel_path${NC}"
                    DELETED_FILES=$((DELETED_FILES + 1))
                    
                    # 检查并删除空目录
                    parent_dir=$(dirname "$original_file")
                    while [ "$parent_dir" != "$DOCS_DIR" ] && [ "$parent_dir" != "/" ]; do
                        # 只删除 image、images、assets、asset 目录
                        dir_name=$(basename "$parent_dir")
                        if [[ "$dir_name" =~ ^(image|images|asset|assets)$ ]]; then
                            if [ -d "$parent_dir" ] && [ -z "$(ls -A "$parent_dir" 2>/dev/null)" ]; then
                                if rmdir "$parent_dir" 2>/dev/null; then
                                    echo -e "${GREEN}  ✓ 清理空目录: ${parent_dir#$DOCS_DIR/}${NC}"
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
    done
fi

# 清理临时文件
rm -f "$TEMP_CHANGES" "$TEMP_MOVED"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 增量图片收集完成${NC}"
if [ $TOTAL_IMAGES -gt 0 ]; then
    echo -e "  • 扫描到 ${TOTAL_IMAGES} 个图片引用"
    echo -e "  • 收集了 ${MOVED_IMAGES} 个图片"
    echo -e "  • 更新了 ${UPDATED_FILES} 个文件"
    [ $DELETED_FILES -gt 0 ] && echo -e "  • 删除了 ${DELETED_FILES} 个原始文件"
fi
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0