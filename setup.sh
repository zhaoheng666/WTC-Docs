#!/bin/bash

# WorldTourCasino Docs Setup Script

echo "🚀 设置 WorldTourCasino 文档项目..."

# 检查是否在 docs 目录
if [ ! -f "package.json" ]; then
    echo "❌ 请在 docs 目录下运行此脚本"
    exit 1
fi

# 安装依赖
echo "📦 安装依赖..."
npm install

# 创建必要的目录
echo "📁 创建目录结构..."
mkdir -p .vitepress/theme
mkdir -p public

# 检查配置文件是否存在
if [ ! -f ".vitepress/config.mjs" ]; then
    echo "⚠️  未找到 VitePress 配置文件"
    echo "请确保 .vitepress/config.mjs 文件存在"
fi

echo ""
echo "✅ 设置完成！"
echo ""
echo "可用的命令："
echo "  npm run dev     - 启动开发服务器"
echo "  npm run build   - 构建文档"
echo "  npm run preview - 预览构建结果"
echo ""
echo "文档将在 http://localhost:5173 启动"