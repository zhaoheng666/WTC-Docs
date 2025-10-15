#!/usr/bin/env python3
"""批量注释掉 Markdown 文件中引用的不存在的图片"""

import os
import re
from pathlib import Path

def process_markdown_files():
    docs_root = Path(__file__).parent.parent.parent
    count = 0

    # 遍历所有 MD 文件
    for md_file in docs_root.rglob("*.md"):
        # 跳过 node_modules 和构建目录
        if "node_modules" in str(md_file) or ".vitepress/dist" in str(md_file):
            continue

        content = md_file.read_text(encoding='utf-8')
        modified = False

        # 查找所有图片引用：![xxx](/assets/yyy.png)
        pattern = r'!\[([^\]]*)\]\((/assets/[^\)]+\.(?:png|jpg|jpeg|gif|webp|svg))\)'

        def replace_missing_image(match):
            nonlocal modified, count
            alt_text = match.group(1)
            img_path = match.group(2)

            # 检查图片文件是否存在
            img_file = docs_root / "public" / img_path.lstrip('/')

            if not img_file.exists():
                print(f"❌ 缺失: {md_file.relative_to(docs_root)} -> {img_path}")
                modified = True
                count += 1
                # 返回注释后的内容
                return f'<!-- ![{alt_text}]({img_path}) -->\n<!-- ⚠️ 图片文件缺失，已注释 -->'

            # 图片存在，保持原样
            return match.group(0)

        new_content = re.sub(pattern, replace_missing_image, content)

        if modified:
            md_file.write_text(new_content, encoding='utf-8')

    print()
    print(f"✅ 处理完成！共注释了 {count} 个缺失的图片引用")

if __name__ == "__main__":
    process_markdown_files()
