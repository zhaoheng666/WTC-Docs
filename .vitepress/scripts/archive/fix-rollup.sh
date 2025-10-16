#!/bin/bash

# 修复 rollup 可选依赖问题的脚本
# 这个问题是 npm 的一个已知 bug：https://github.com/npm/cli/issues/4828

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔧 修复 Rollup 依赖问题..."

cd "$PROJECT_ROOT"

# 检查是否需要修复
if npm ls @rollup/rollup-darwin-x64 2>/dev/null | grep -q "UNMET OPTIONAL DEPENDENCY"; then
    echo "  检测到 Rollup 依赖问题，开始修复..."

    # 删除 node_modules 和 package-lock.json
    echo "  清理旧的依赖..."
    rm -rf node_modules package-lock.json

    # 重新安装
    echo "  重新安装依赖..."
    npm install

    echo "✅ 修复完成！"
else
    echo "✅ 依赖正常，无需修复"
fi