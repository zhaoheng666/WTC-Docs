#!/bin/bash

# 文档统计数据生成脚本

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$DOCS_DIR/统计仪表板.md"

cd "$DOCS_DIR" || exit 1

# 颜色定义
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}正在生成文档统计数据...${NC}"

# 获取当前时间
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# 统计文档数量
MD_COUNT=$(find . -name "*.md" -type f | grep -v node_modules | grep -v ".vitepress" | wc -l | tr -d ' ')
DIR_COUNT=$(find . -type d | grep -v node_modules | grep -v ".vitepress" | grep -v ".git" | wc -l | tr -d ' ')

# 统计各目录文档数量
CATEGORY_STATS=""
for dir in 关卡 活动 native 协议 工具 其他; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name "*.md" -type f | wc -l | tr -d ' ')
        CATEGORY_STATS="$CATEGORY_STATS| $dir | $count |\n"
    fi
done

# 获取最近更新的文档（最近10个）
RECENT_LIST=""
for file in $(find . -name "*.md" -type f | grep -v node_modules | grep -v ".vitepress" | xargs ls -t | head -10); do
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
done

# 获取 Git 贡献者统计
if [ -d .git ]; then
    # 获取贡献者和提交数
    CONTRIBUTORS=$(git shortlog -sn --all --no-merges | head -10)
    CONTRIB_LIST=""
    TOTAL_COMMITS=0
    while IFS= read -r line; do
        commits=$(echo "$line" | awk '{print $1}')
        author=$(echo "$line" | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
        TOTAL_COMMITS=$((TOTAL_COMMITS + commits))
        CONTRIB_LIST="$CONTRIB_LIST| $author | $commits |\n"
    done <<< "$CONTRIBUTORS"
    
    # 计算百分比
    CONTRIB_LIST_WITH_PERCENT=""
    while IFS= read -r line; do
        commits=$(echo "$line" | awk '{print $1}')
        author=$(echo "$line" | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
        if [ "$TOTAL_COMMITS" -gt 0 ]; then
            percent=$(echo "scale=1; $commits * 100 / $TOTAL_COMMITS" | bc)
            bar_length=$(echo "scale=0; $percent / 5" | bc)
            bar=$(printf '█%.0s' $(seq 1 $bar_length))
            CONTRIB_LIST_WITH_PERCENT="$CONTRIB_LIST_WITH_PERCENT| $author | $commits | ${bar} ${percent}% |\n"
        fi
    done <<< "$CONTRIBUTORS"
fi

# 获取最近7天的提交活跃度
ACTIVITY_LAST_7_DAYS=""
for i in {6..0}; do
    date=$(date -v-${i}d '+%Y-%m-%d' 2>/dev/null || date -d "$i days ago" '+%Y-%m-%d' 2>/dev/null)
    commits=$(git log --since="$date 00:00:00" --until="$date 23:59:59" --format=oneline 2>/dev/null | wc -l | tr -d ' ')
    day_name=$(date -v-${i}d '+%a' 2>/dev/null || date -d "$i days ago" '+%a' 2>/dev/null)
    ACTIVITY_LAST_7_DAYS="$ACTIVITY_LAST_7_DAYS| $day_name | $date | $commits |\n"
done

# 生成 JSON 数据文件供 Vue 组件使用
JSON_FILE="$DOCS_DIR/public/stats.json"
mkdir -p "$DOCS_DIR/public"

cat > "$JSON_FILE" << EOF
{
  "updateTime": "$CURRENT_TIME",
  "totalDocs": $MD_COUNT,
  "totalDirs": $DIR_COUNT,
  "totalContributors": $(git shortlog -sn --all --no-merges | wc -l | tr -d ' '),
  "totalCommits": $(git rev-list --all --count),
  "categoryStats": [
    { "name": "关卡", "count": $(find 关卡 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '), "color": "#7c3aed" },
    { "name": "活动", "count": $(find 活动 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '), "color": "#ec4899" },
    { "name": "Native", "count": $(find native -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '), "color": "#f59e0b" },
    { "name": "协议", "count": $(find 协议 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '), "color": "#10b981" },
    { "name": "工具", "count": $(find 工具 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '), "color": "#3b82f6" },
    { "name": "其他", "count": $(find 其他 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' '), "color": "#6b7280" }
  ],
  "growth": {
    "today": $(find . -name "*.md" -type f -mtime -1 | wc -l | tr -d ' '),
    "week": $(find . -name "*.md" -type f -mtime -7 | wc -l | tr -d ' '),
    "month": $(find . -name "*.md" -type f -mtime -30 | wc -l | tr -d ' ')
  }
}
EOF

echo -e "${GREEN}✅ JSON 数据已生成到: $JSON_FILE${NC}"

# 生成统计页面
cat > "$OUTPUT_FILE" << EOF
# 📊 文档统计仪表板

> 最后更新时间：$CURRENT_TIME

## 📈 总体统计

| 指标 | 数值 |
|------|------|
| 📄 文档总数 | **$MD_COUNT** 个 |
| 📁 目录总数 | **$DIR_COUNT** 个 |
| 👥 贡献者数 | **$(git shortlog -sn --all --no-merges | wc -l | tr -d ' ')** 人 |
| 🔄 总提交数 | **$(git rev-list --all --count)** 次 |

## 📂 分类统计

| 分类 | 文档数量 |
|------|----------|
$(echo -e "$CATEGORY_STATS")

## 🕒 最近更新

| 更新时间 | 文档路径 |
|----------|----------|
$(echo -e "$RECENT_LIST")

## 👥 贡献者排行

| 贡献者 | 提交数 | 贡献比例 |
|--------|--------|----------|
$(echo -e "$CONTRIB_LIST_WITH_PERCENT")

## 📅 最近7天活跃度

| 星期 | 日期 | 提交数 |
|------|------|--------|
$(echo -e "$ACTIVITY_LAST_7_DAYS")

## 📊 文档增长趋势

\`\`\`
最近30天新增文档：$(find . -name "*.md" -type f -mtime -30 | wc -l | tr -d ' ') 个
最近7天新增文档：$(find . -name "*.md" -type f -mtime -7 | wc -l | tr -d ' ') 个
今日新增文档：$(find . -name "*.md" -type f -mtime -1 | wc -l | tr -d ' ') 个
\`\`\`

---

*此页面由自动脚本生成，每次构建时更新*
EOF

echo -e "${GREEN}✅ 统计数据已生成到: $OUTPUT_FILE${NC}"