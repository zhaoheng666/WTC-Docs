#!/bin/bash

# GitHub Actions 构建脚本（精简版）
# 只处理必要的构建任务

set -e

echo "🚀 Starting CI Build..."

# 生成统计页面（CI 环境，包含完整提交历史）
if [ -f ".vitepress/scripts/generate-stats.js" ]; then
    echo "📊 Generating stats page..."
    node .vitepress/scripts/generate-stats.js
fi

# 设置 GitHub Pages URL
export VITE_BASE_URL="https://zhaoheng666.github.io/WTC-Docs"

# 执行 VitePress 构建
echo "📦 Building with VitePress..."
npx vitepress build

# 构建后替换 URL（确保所有链接都使用正确的域名）
echo "🔄 Replacing URLs for GitHub Pages..."
find .vitepress/dist -type f \( -name "*.html" -o -name "*.js" \) -exec sed -i \
    -e "s|http://localhost:5173/WTC-Docs|https://zhaoheng666.github.io/WTC-Docs|g" {} \;

echo "✅ CI Build complete!"