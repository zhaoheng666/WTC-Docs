#!/bin/zsh

# 检查端口 5173 是否被占用
PORT=5173
PID=$(lsof -ti:$PORT)

if [ ! -z "$PID" ]; then
    echo "Port $PORT is in use by PID $PID. Killing the process..."
    kill -9 $PID
    sleep 1
fi

# 启动 vitepress 并指定端口
vitepress dev --port $PORT