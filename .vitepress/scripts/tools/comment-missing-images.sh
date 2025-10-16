#!/bin/zsh
set -euo pipefail

# 批量注释掉 Markdown 文件中引用的不存在的图片

count=0

find . -name "*.md" -type f ! -path "./node_modules/*" ! -path "./.vitepress/dist/*" | while IFS= read -r md_file; do
  # 提取所有图片引用
  grep -o '!\[[^]]*\](/assets/[^)]*\.png)' "$md_file" 2>/dev/null | while IFS= read -r img_ref; do
    # 提取图片路径
    img_path=$(echo "$img_ref" | sed 's/.*(\(\/assets\/[^)]*\)).*/\1/')
    img_file="public${img_path}"

    # 检查图片文件是否存在
    if [ ! -f "$img_file" ]; then
      echo "❌ 缺失: $md_file -> $img_path"

      # 使用 sed 进行原地替换
      # 需要转义特殊字符
      escaped_path=$(echo "$img_path" | sed 's/[\/&]/\\&/g')
      # 先匹配整个图片引用，然后注释掉
      sed -i '' "s|!\[[^]]*\](${escaped_path})|<!-- & --><!-- ⚠️ 图片文件缺失，已注释 -->|g" "$md_file"

      ((count++))
    fi
  done
done

echo ""
echo "✅ 处理完成！共注释了 $count 个缺失的图片引用"
