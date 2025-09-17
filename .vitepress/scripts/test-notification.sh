#!/bin/bash

# 测试通知脚本

echo "测试 macOS 通知系统..."

# 1. 测试 osascript
echo "1. 测试 osascript..."
osascript -e 'display notification "osascript 测试成功" with title "测试通知" subtitle "基础通知" sound name "Glass"'
echo "osascript 执行完成，退出码: $?"

sleep 2

# 2. 测试 terminal-notifier
echo "2. 测试 terminal-notifier..."
if command -v terminal-notifier &> /dev/null; then
    terminal-notifier -title "测试通知" \
        -subtitle "terminal-notifier" \
        -message "增强通知测试成功" \
        -sound Glass \
        -group "test-notification"
    echo "terminal-notifier 执行完成，退出码: $?"
else
    echo "terminal-notifier 未安装"
fi

sleep 2

# 3. 测试变量插值
LATEST_NAME="Deploy to GitHub Pages"
LATEST_RUN_ID="17790008933"
REPO_INFO="zhaoheng666/WTC-Docs"

echo "3. 测试变量插值..."
osascript -e "display notification \"$LATEST_NAME 运行成功\" with title \"GitHub Actions\" subtitle \"文档构建成功\" sound name \"Glass\""
echo "变量插值 osascript 执行完成，退出码: $?"

sleep 2

if command -v terminal-notifier &> /dev/null; then
    terminal-notifier -title "GitHub Actions 成功" \
        -subtitle "$LATEST_NAME" \
        -message "文档已成功部署" \
        -open "https://github.com/$REPO_INFO/actions/runs/$LATEST_RUN_ID" \
        -sound Glass \
        -group "github-actions"
    echo "变量插值 terminal-notifier 执行完成，退出码: $?"
fi

echo "所有测试完成"