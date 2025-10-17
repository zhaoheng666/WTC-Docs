#!/bin/bash

# GitHub Actions 构建脚本（精简版）
# 只处理必要的构建任务
# Last updated: 2025-10-17

set -e

echo "🚀 Starting CI Build..."

# 确保 stats.json 存在（从模板复制）
if [ ! -f "public/stats.json" ] && [ -f "public/stats.template.json" ]; then
    echo "📋 Copying stats template..."
    cp public/stats.template.json public/stats.json
fi

# 获取当前提交信息（用于修正统计）
CURRENT_COMMIT_HASH=$(git rev-parse --short HEAD)
CURRENT_COMMIT_MSG=$(git log -1 --pretty=format:"%s")
CURRENT_COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an")
echo "📝 Current commit: $CURRENT_COMMIT_HASH - $CURRENT_COMMIT_MSG by $CURRENT_COMMIT_AUTHOR"

# 生成统计页面（CI 环境，包含完整提交历史）
if [ -f ".vitepress/scripts/lib/generate-stats.js" ]; then
    echo "📊 Generating stats page..."
    # 设置环境变量，让 generate-stats.js 知道当前提交信息
    export CURRENT_COMMIT_HASH="$CURRENT_COMMIT_HASH"
    export CURRENT_COMMIT_MSG="$CURRENT_COMMIT_MSG"
    export CURRENT_COMMIT_AUTHOR="$CURRENT_COMMIT_AUTHOR"
    node .vitepress/scripts/lib/generate-stats.js
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