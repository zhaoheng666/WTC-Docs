#!/bin/bash

# 简化版文档统计生成脚本
# 只生成相对稳定的统计信息，减少频繁变更

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$DOCS_DIR/统计仪表板.md"
JSON_FILE="$DOCS_DIR/public/stats.json"

cd "$DOCS_DIR" || exit 1

# 颜色定义
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}生成简化版统计数据...${NC}"

# 获取最近更新的文档（从 git 日志）
RECENT_UPDATES=""
JSON_RECENT="["
first=true

# 获取最近修改的 md 文件（按时间顺序）
if git rev-parse --git-dir > /dev/null 2>&1; then
    # 保存已处理的文件，避免重复
    processed_files=""
    
    # 获取最近50个提交中的 md 文件修改
    while IFS= read -r line; do
        if [[ "$line" =~ ^[0-9]{2}-[0-9]{2} ]]; then
            # 这是日期和提交信息行
            commit_date=$(echo "$line" | cut -d' ' -f1)
            commit_msg=$(echo "$line" | cut -d' ' -f2- | cut -c1-30)
        elif [[ "$line" =~ \.md$ ]] && [[ "$line" != "统计仪表板.md" ]]; then
            # 这是文件名
            file="$line"
            
            # 检查是否已处理过这个文件
            if ! echo "$processed_files" | grep -q "^$file$"; then
                processed_files="${processed_files}${file}\n"
                
                if [ -f "$file" ]; then
                    filename=$(basename "$file" .md)
                    
                    # 根据目录添加图标
                    icon=""
                    if [[ "$file" == "活动/"* ]]; then icon="📋 "
                    elif [[ "$file" == "关卡/"* ]]; then icon="🎮 "
                    elif [[ "$file" == "工具/"* ]]; then icon="🛠️ "
                    elif [[ "$file" == "协议/"* ]]; then icon="🔌 "
                    elif [[ "$file" == "native/"* ]]; then icon="🏙️ "
                    elif [[ "$file" == "故障排查/"* ]]; then icon="🔧 "
                    fi
                    
                    RECENT_UPDATES="${RECENT_UPDATES}| $commit_date | ${icon}[$filename](/$file) | $commit_msg |\n"
                    
                    if [ "$first" = true ]; then
                        first=false
                    else
                        JSON_RECENT="$JSON_RECENT,"
                    fi
                    
                    JSON_RECENT="$JSON_RECENT
    { \"date\": \"$commit_date\", \"file\": \"$filename\", \"path\": \"/$file\", \"message\": \"$commit_msg\" }"
                    
                    # 只显示前10个不同的文件
                    file_count=$(echo -e "$processed_files" | grep -v "^$" | wc -l)
                    if [ $file_count -ge 10 ]; then
                        break
                    fi
                fi
            fi
        fi
    done < <(git log --name-only --format="%cd %s" --date=format:"%m-%d" -50)
fi

JSON_RECENT="$JSON_RECENT
  ]"

# 生成 Markdown 文件
cat > "$OUTPUT_FILE" << EOF
# 📊 文档统计仪表板

## 🕐 最近更新

| 更新日期 | 文档 | 最后提交 |
|----------|------|----------|
$(echo -e "$RECENT_UPDATES")

## 📚 文档导航

### 核心文档
- 🎮 [关卡配置](/关卡/) - 老虎机游戏关卡配置、数值设计
- 📋 [活动系统](/活动/) - 游戏活动配置、节日活动
- 🏙️ [Native](/native/) - 城市解锁、地标收集
- 🔌 [协议文档](/协议/) - 前后端通信协议

### 开发支持
- 🛠️ [工具集](/工具/) - 开发工具、调试工具
- 🔧 [故障排查](/故障排查/) - 常见问题解决方案
- 📝 [其他文档](/其他/) - 工作记录、迁移文档

## 🔗 快速链接

- [在线文档](https://zhaoheng666.github.io/WTC-Docs/)
- [GitHub 仓库](https://github.com/zhaoheng666/WTC-Docs)
- [技术实现说明](/README)

<Dashboard />
EOF

# 生成简化的 JSON 文件
cat > "$JSON_FILE" << EOF
{
  "recentUpdates": $JSON_RECENT
}
EOF

echo -e "${GREEN}✓ 统计数据已生成（简化版）${NC}"