#!/bin/bash

# 简单修复 Rollup ARM64 问题
# 仅在本地 M1/M2/M3 Mac 上需要

echo "🔧 修复 Rollup ARM64 依赖..."

# 直接安装 ARM64 版本
npm install @rollup/rollup-darwin-arm64@4 --save-optional 2>/dev/null

echo "✅ 完成"