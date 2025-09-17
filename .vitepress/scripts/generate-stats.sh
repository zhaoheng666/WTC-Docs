#!/bin/bash

# 文档统计数据生成脚本
# 只在内容实际变化时才更新，避免不必要的 git 变更

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$DOCS_DIR/统计仪表板.md"
JSON_FILE="$DOCS_DIR/public/stats.json"
TEMP_FILE="/tmp/stats_temp_$$.md"
TEMP_JSON="/tmp/stats_temp_$$.json"

cd "$DOCS_DIR" || exit 1

# 颜色定义
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}正在生成文档统计数据...${NC}"

# 获取当前日期（不包含时间，减少更新频率）
CURRENT_DATE=$(date '+%Y-%m-%d')

# 统计文档数量
MD_COUNT=$(find . -name "*.md" -type f | grep -v node_modules | grep -v ".vitepress" | wc -l | tr -d ' ')
DIR_COUNT=$(find . -type d | grep -v node_modules | grep -v ".vitepress" | grep -v ".git" | wc -l | tr -d ' ')

# 获取 git 统计（如果可用）
CONTRIBUTORS=0
COMMITS=0
if git rev-parse --git-dir > /dev/null 2>&1; then
    CONTRIBUTORS=$(git log --format='%aN' | sort -u | wc -l | tr -d ' ')
    COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
fi

# 统计各目录文档数量
CATEGORY_STATS=""
JSON_CATEGORIES="["
first=true
for dir in 关卡 活动 native 协议 工具 其他; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name "*.md" -type f | wc -l | tr -d ' ')
        CATEGORY_STATS="$CATEGORY_STATS| $dir | $count |\n"
        
        # 为目录分配颜色
        case $dir in
            关卡) color="#7c3aed" ;;
            活动) color="#ec4899" ;;
            native) color="#f59e0b" ;;
            协议) color="#10b981" ;;
            工具) color="#3b82f6" ;;
            其他) color="#6b7280" ;;
            *) color="#9ca3af" ;;
        esac
        
        # 首字母大写处理
        display_name=$dir
        if [ "$dir" = "native" ]; then
            display_name="Native"
        fi
        
        if [ "$first" = true ]; then
            first=false
        else
            JSON_CATEGORIES="$JSON_CATEGORIES,"
        fi
        JSON_CATEGORIES="$JSON_CATEGORIES
    { \"name\": \"$display_name\", \"count\": $count, \"color\": \"$color\" }"
    fi
done
JSON_CATEGORIES="$JSON_CATEGORIES
  ]"

# 获取最近更新的文档（最近10个）
RECENT_LIST=""
JSON_RECENT="["
first=true
for file in $(find . -name "*.md" -type f | grep -v node_modules | grep -v ".vitepress" | grep -v "统计仪表板.md" | xargs ls -t 2>/dev/null | head -10); do
    # 获取相对路径
    file_path=$(echo "$file" | sed 's|^\./||')
    # 获取修改时间 - macOS 兼容
    mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null)
    if [ -z "$mod_time" ]; then
        # Linux fallback
        mod_time=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1 | sed 's/-/\//g')
    fi
    # 创建链接
    link_path="/$file_path"
    title=$(basename "$file_path" .md)
    RECENT_LIST="$RECENT_LIST| $mod_time | [$title]($link_path) |\n"
    
    if [ "$first" = true ]; then
        first=false
    else
        JSON_RECENT="$JSON_RECENT,"
    fi
    JSON_RECENT="$JSON_RECENT
    { \"time\": \"$mod_time\", \"path\": \"$link_path\", \"title\": \"$title\" }"
done
JSON_RECENT="$JSON_RECENT
  ]"

# 获取贡献者统计
CONTRIBUTOR_LIST=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    # 获取每个贡献者的提交数
    while IFS= read -r line; do
        count=$(echo "$line" | awk '{print $1}')
        author=$(echo "$line" | cut -d' ' -f2-)
        # 计算百分比
        if [ "$COMMITS" -gt 0 ]; then
            percentage=$(awk "BEGIN {printf \"%.1f\", $count * 100 / $COMMITS}")
        else
            percentage="0.0"
        fi
        # 生成进度条（每5%一个块，最多20个块）
        bar_count=$(awk "BEGIN {printf \"%.0f\", $percentage / 5}")
        bar=$(printf '█%.0s' $(seq 1 $bar_count 2>/dev/null))
        
        CONTRIBUTOR_LIST="$CONTRIBUTOR_LIST| $author | $count | $bar $percentage% |\n"
    done < <(git shortlog -sn --all | head -10)
fi

# 获取最近7天活跃度
ACTIVITY_LIST=""
for i in {6..0}; do
    # macOS 兼容的日期计算
    if [ "$(uname)" = "Darwin" ]; then
        date_str=$(date -v-${i}d '+%Y-%m-%d')
        weekday=$(date -v-${i}d '+%a' | sed 's/Mon/一/;s/Tue/二/;s/Wed/三/;s/Thu/四/;s/Fri/五/;s/Sat/六/;s/Sun/日/')
    else
        date_str=$(date -d "$i days ago" '+%Y-%m-%d')
        weekday=$(date -d "$i days ago" '+%a')
    fi
    
    # 统计该日的提交数
    if git rev-parse --git-dir > /dev/null 2>&1; then
        day_commits=$(git log --since="$date_str 00:00:00" --until="$date_str 23:59:59" --format="%H" | wc -l | tr -d ' ')
    else
        day_commits=0
    fi
    
    ACTIVITY_LIST="$ACTIVITY_LIST| $weekday | $date_str | $day_commits |\n"
done

# 计算文档增长趋势（基于 git 历史）
NEW_DOCS_30D=0
NEW_DOCS_7D=0
NEW_DOCS_TODAY=0

if git rev-parse --git-dir > /dev/null 2>&1; then
    # 计算各时间段的新增文档
    for file in $(find . -name "*.md" -type f | grep -v node_modules | grep -v ".vitepress"); do
        # 获取文件的创建时间（第一次提交时间）
        first_commit=$(git log --diff-filter=A --format="%ai" -- "$file" | tail -1)
        if [ -n "$first_commit" ]; then
            # 转换为时间戳进行比较
            file_timestamp=$(date -d "$first_commit" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S %z" "$first_commit" +%s 2>/dev/null)
            now_timestamp=$(date +%s)
            
            # 计算天数差
            days_diff=$(( (now_timestamp - file_timestamp) / 86400 ))
            
            if [ $days_diff -le 30 ]; then
                NEW_DOCS_30D=$((NEW_DOCS_30D + 1))
            fi
            if [ $days_diff -le 7 ]; then
                NEW_DOCS_7D=$((NEW_DOCS_7D + 1))
            fi
            if [ $days_diff -eq 0 ]; then
                NEW_DOCS_TODAY=$((NEW_DOCS_TODAY + 1))
            fi
        fi
    done
fi

# 生成 JSON 文件（不包含更新时间）
cat > "$TEMP_JSON" << EOF
{
  "totalDocs": $MD_COUNT,
  "totalDirs": $DIR_COUNT,
  "totalContributors": $CONTRIBUTORS,
  "totalCommits": $COMMITS,
  "categoryStats": $JSON_CATEGORIES,
  "recentDocs": $JSON_RECENT,
  "newDocs30d": $NEW_DOCS_30D,
  "newDocs7d": $NEW_DOCS_7D,
  "newDocsToday": $NEW_DOCS_TODAY
}
EOF

# 生成 Markdown 文件（不包含更新时间）
cat > "$TEMP_FILE" << EOF
# 📊 文档统计仪表板

## 📈 总体统计

| 指标 | 数值 |
|------|------|
| 📄 文档总数 | **${MD_COUNT}** 个 |
| 📁 目录总数 | **${DIR_COUNT}** 个 |
| 👥 贡献者数 | **${CONTRIBUTORS}** 人 |
| 🔄 总提交数 | **${COMMITS}** 次 |

## 📂 分类统计

| 分类 | 文档数量 |
|------|----------|
$(echo -e "$CATEGORY_STATS" | grep -v '^$')

## 🕒 最近更新

| 更新时间 | 文档路径 |
|----------|----------|
$(echo -e "$RECENT_LIST" | grep -v '^$')

## 👥 贡献者排行

| 贡献者 | 提交数 | 贡献比例 |
|--------|--------|----------|
$(echo -e "$CONTRIBUTOR_LIST" | grep -v '^$')

## 📅 最近7天活跃度

| 星期 | 日期 | 提交数 |
|------|------|--------|
$(echo -e "$ACTIVITY_LIST" | grep -v '^$')

## 📊 文档增长趋势

\`\`\`
最近30天新增文档：${NEW_DOCS_30D} 个
最近7天新增文档：${NEW_DOCS_7D} 个
今日新增文档：${NEW_DOCS_TODAY} 个
\`\`\`

---

<div style="text-align: center; color: #6b7280; font-size: 12px; margin-top: 20px;">
生成时间：$CURRENT_TIME | 
<a href="https://github.com/yourusername/worldtourcasino-docs" style="color: #3b82f6;">查看仓库</a>
</div>

<Dashboard />
EOF

# 比较新旧文件内容（忽略时间戳）
CONTENT_CHANGED=false

# 比较 JSON（忽略 updateTime 字段）
if [ -f "$JSON_FILE" ]; then
    OLD_JSON=$(cat "$JSON_FILE" | grep -v "updateTime" | grep -v '^$')
    NEW_JSON=$(cat "$TEMP_JSON" | grep -v "updateTime" | grep -v '^$')
    if [ "$OLD_JSON" != "$NEW_JSON" ]; then
        CONTENT_CHANGED=true
    fi
else
    CONTENT_CHANGED=true
fi

# 比较 Markdown（忽略时间戳行）
if [ -f "$OUTPUT_FILE" ]; then
    OLD_MD=$(cat "$OUTPUT_FILE" | grep -v "最后更新时间" | grep -v "生成时间" | grep -v '^$')
    NEW_MD=$(cat "$TEMP_FILE" | grep -v "最后更新时间" | grep -v "生成时间" | grep -v '^$')
    if [ "$OLD_MD" != "$NEW_MD" ]; then
        CONTENT_CHANGED=true
    fi
else
    CONTENT_CHANGED=true
fi

# 只有内容变化时才更新文件
if [ "$CONTENT_CHANGED" = true ]; then
    # 添加时间戳到 JSON
    echo "{" > "$JSON_FILE"
    echo "  \"updateTime\": \"$CURRENT_TIME\"," >> "$JSON_FILE"
    cat "$TEMP_JSON" | tail -n +2 >> "$JSON_FILE"
    
    # 添加时间戳到 Markdown
    echo "# 📊 文档统计仪表板" > "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "> 最后更新时间：$CURRENT_TIME" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cat "$TEMP_FILE" | tail -n +3 >> "$OUTPUT_FILE"
    
    echo -e "${GREEN}✅ 统计数据已更新${NC}"
    echo -e "  • 文档总数：$MD_COUNT"
    echo -e "  • 统计文件已生成：统计仪表板.md"
    echo -e "  • JSON数据已生成：public/stats.json"
else
    echo -e "${YELLOW}⚠️  统计数据无变化，跳过更新${NC}"
fi

# 清理临时文件
rm -f "$TEMP_FILE" "$TEMP_JSON"

exit 0