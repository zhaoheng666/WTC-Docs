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

# 统计文档数量
MD_COUNT=$(find . -name "*.md" -type f | grep -v node_modules | grep -v ".vitepress" | wc -l | tr -d ' ')
DIR_COUNT=$(find . -type d | grep -v node_modules | grep -v ".vitepress" | grep -v ".git" | wc -l | tr -d ' ')

# 统计各目录文档数量
CATEGORY_STATS=""
JSON_CATEGORIES="["
first=true
for dir in 关卡 活动 native 协议 工具 其他 故障排查; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name "*.md" -type f | wc -l | tr -d ' ')
        CATEGORY_STATS="$CATEGORY_STATS| $dir | $count |\n"
        
        # 为目录分配颜色
        case $dir in
            关卡) color="#7c3aed" ;;
            活动) color="#ec4899" ;;
            native|Native) color="#f59e0b" ;;
            协议) color="#10b981" ;;
            工具) color="#3b82f6" ;;
            故障排查) color="#ef4444" ;;
            *) color="#6b7280" ;;
        esac
        
        if [ "$first" = true ]; then
            first=false
        else
            JSON_CATEGORIES="$JSON_CATEGORIES,"
        fi
        
        JSON_CATEGORIES="$JSON_CATEGORIES
    { \"name\": \"$dir\", \"count\": $count, \"color\": \"$color\" }"
    fi
done
JSON_CATEGORIES="$JSON_CATEGORIES
  ]"

# 获取最近更新的文档（从 git 日志）
RECENT_UPDATES=""
JSON_RECENT="["
first=true

# 获取最近修改的 md 文件
if git rev-parse --git-dir > /dev/null 2>&1; then
    # 获取最近10个不同的文档更新
    count=0
    processed_files=""
    
    # 获取每个md文件的最后提交信息
    for file in $(git ls-files "*.md" | grep -v "统计仪表板.md" | head -20); do
        if [ -f "$file" ]; then
            # 获取该文件的最后提交
            last_info=$(git log -1 --format="%cd|%s" --date=format:"%m-%d" -- "$file" 2>/dev/null)
            if [ -n "$last_info" ]; then
                commit_date=$(echo "$last_info" | cut -d'|' -f1)
                commit_msg=$(echo "$last_info" | cut -d'|' -f2 | cut -c1-30)
                filename=$(basename "$file" .md)
                
                # 根据目录添加图标
                icon=""
                if [[ "$file" == "活动/"* ]]; then icon="📋 "
                elif [[ "$file" == "关卡/"* ]]; then icon="🎮 "
                elif [[ "$file" == "工具/"* ]]; then icon="🛠️ "
                elif [[ "$file" == "协议/"* ]]; then icon="🔌 "
                elif [[ "$file" == "native/"* ]]; then icon="🏙️ "
                fi
                
                RECENT_UPDATES="${RECENT_UPDATES}| $commit_date | ${icon}[$filename](/$file) | $commit_msg |\n"
                
                if [ "$first" = true ]; then
                    first=false
                else
                    JSON_RECENT="$JSON_RECENT,"
                fi
                
                JSON_RECENT="$JSON_RECENT
    { \"date\": \"$commit_date\", \"file\": \"$filename\", \"path\": \"/$file\", \"message\": \"$commit_msg\" }"
                
                count=$((count + 1))
                if [ $count -ge 10 ]; then
                    break
                fi
            fi
        fi
    done
fi

JSON_RECENT="$JSON_RECENT
  ]"

# 生成 Markdown 文件
cat > "$OUTPUT_FILE" << EOF
# 📊 文档统计仪表板

## 📈 总体统计

| 指标 | 数值 |
|------|------|
| 📄 文档总数 | **${MD_COUNT}** 个 |
| 📁 目录总数 | **${DIR_COUNT}** 个 |

## 📂 分类统计

| 分类 | 文档数量 |
|------|----------|
$(echo -e "$CATEGORY_STATS")

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
  "totalDocs": $MD_COUNT,
  "totalDirs": $DIR_COUNT,
  "categoryStats": $JSON_CATEGORIES,
  "recentUpdates": $JSON_RECENT
}
EOF

echo -e "${GREEN}✓ 统计数据已生成（简化版）${NC}"