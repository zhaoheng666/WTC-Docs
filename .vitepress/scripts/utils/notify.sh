#!/bin/bash
# 通用通知工具脚本
# 使用方法: bash notify.sh --title "标题" --message "消息" [--type system|dialog] [--sound Glass]

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认值
TITLE="通知"
MESSAGE=""
TYPE="system"  # system(系统通知) 或 dialog(弹窗)
SOUND="Glass"
SUBTITLE=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --title|-t)
            TITLE="$2"
            shift 2
            ;;
        --message|-m)
            MESSAGE="$2"
            shift 2
            ;;
        --subtitle|-s)
            SUBTITLE="$2"
            shift 2
            ;;
        --type)
            TYPE="$2"
            shift 2
            ;;
        --sound)
            SOUND="$2"
            shift 2
            ;;
        --help|-h)
            echo "使用方法: $0 [选项]"
            echo "选项:"
            echo "  --title, -t <标题>     通知标题"
            echo "  --message, -m <消息>   通知消息"
            echo "  --subtitle, -s <副标题> 通知副标题（仅系统通知）"
            echo "  --type <类型>          通知类型: system(系统通知) 或 dialog(弹窗)"
            echo "  --sound <声音>         提示音名称 (默认: Glass)"
            echo "  --help, -h             显示此帮助信息"
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            exit 1
            ;;
    esac
done

# 检查消息是否为空
if [ -z "$MESSAGE" ]; then
    echo -e "${RED}错误：消息内容不能为空${NC}"
    exit 1
fi

# macOS 检查
if [ "$(uname)" != "Darwin" ]; then
    echo -e "${YELLOW}警告：通知功能仅支持 macOS${NC}"
    exit 0
fi

# 对文本进行转义，移除可能导致问题的特殊字符
safe_text() {
    echo "$1" | sed 's/[`"\\$]/\\&/g' | tr -d '\n\r'
}

# 系统通知函数
send_system_notification() {
    local safe_title=$(safe_text "$TITLE")
    local safe_message=$(safe_text "$MESSAGE")
    local safe_subtitle=$(safe_text "$SUBTITLE")

    # 优先使用 terminal-notifier（更稳定可靠）
    if command -v terminal-notifier &> /dev/null; then
        # 构建命令
        local cmd="terminal-notifier"
        cmd="$cmd -title \"$safe_title\""
        cmd="$cmd -message \"$safe_message\""
        
        if [ -n "$safe_subtitle" ]; then
            cmd="$cmd -subtitle \"$safe_subtitle\""
        fi
        
        if [ -n "$SOUND" ] && [ "$SOUND" != "none" ]; then
            cmd="$cmd -sound \"$SOUND\""
        fi
        
        # 添加一个唯一的 group ID，避免重复通知
        cmd="$cmd -group \"wtc-notify-$(date +%s)\""
        
        # 执行命令（忽略勿扰模式）
        eval "$cmd -ignoreDnD"
        
        echo -e "${GREEN}✓ 系统通知已发送${NC}"
        
        # 给通知时间显示
        sleep 0.5
        return 0
    fi

    # 备用方案：使用 osascript
    local applescript="display notification \"$safe_message\" with title \"$safe_title\""
    
    if [ -n "$safe_subtitle" ]; then
        applescript="$applescript subtitle \"$safe_subtitle\""
    fi
    
    if [ -n "$SOUND" ] && [ "$SOUND" != "none" ]; then
        applescript="$applescript sound name \"$SOUND\""
    fi
    
    if osascript -e "$applescript" 2>/dev/null; then
        echo -e "${GREEN}✓ 系统通知已发送 (osascript)${NC}"
        sleep 0.5
        return 0
    fi

    echo -e "${YELLOW}⚠️ 系统通知发送失败${NC}"
    echo -e "${YELLOW}提示：安装 terminal-notifier 以获得更好的通知体验${NC}"
    echo -e "${YELLOW}安装命令：brew install terminal-notifier${NC}"
    return 1
}

# 弹窗通知函数
send_dialog_notification() {
    local safe_title=$(safe_text "$TITLE")
    local safe_message=$(safe_text "$MESSAGE")

    osascript <<EOF 2>/dev/null
tell application "System Events"
    display dialog "$safe_message" with title "$safe_title" buttons {"确定"} default button 1 giving up after 5
end tell
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 弹窗通知已显示${NC}"
        # 播放提示音
        afplay "/System/Library/Sounds/${SOUND}.aiff" 2>/dev/null &
        return 0
    else
        echo -e "${YELLOW}⚠️ 弹窗通知显示失败${NC}"
        return 1
    fi
}

# 主逻辑
case "$TYPE" in
    system)
        send_system_notification
        ;;
    dialog)
        send_dialog_notification
        ;;
    both)
        # 先尝试系统通知，失败则使用弹窗
        send_system_notification || send_dialog_notification
        ;;
    *)
        echo -e "${RED}错误：未知的通知类型: $TYPE${NC}"
        echo "支持的类型: system, dialog, both"
        exit 1
        ;;
esac