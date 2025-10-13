#!/bin/zsh

# DOCX 转 Markdown 自动化脚本
# 功能：转换 DOCX -> Markdown -> 验证构建 -> 删除原文件
#
# 安全机制：任何步骤失败都会保留原始 DOCX 文件
# 只有在所有验证通过后才会删除原文件
# 支持批量处理多个文件

# 注意：不使用 set -e，因为需要精细控制错误处理

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# 打印函数
print_error() { echo "${RED}❌ $1${NC}" }
print_success() { echo "${GREEN}✅ $1${NC}" }
print_info() { echo "${BLUE}ℹ️  $1${NC}" }
print_warning() { echo "${YELLOW}⚠️  $1${NC}" }

# 通知脚本路径
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/notify.sh"

# 通知函数
notify_success() {
  if [ -f "$NOTIFY_SCRIPT" ]; then
    bash "$NOTIFY_SCRIPT" --title "DOCX 转换成功" --message "$1" --sound "Glass" 2>/dev/null
  fi
}

notify_error() {
  if [ -f "$NOTIFY_SCRIPT" ]; then
    bash "$NOTIFY_SCRIPT" --title "DOCX 转换失败" --message "$1" --sound "Basso" --type "notification" 2>/dev/null
  fi
}

# 检查参数
if [ $# -lt 1 ]; then
  print_error "缺少参数"
  echo "用法: npm run convert-docx <docx文件路径> [更多文件...]"
  echo "示例: npm run convert-docx \"成员/赵恒/工具使用指南.docx\""
  echo "批量: npm run convert-docx \"文件1.docx\" \"文件2.docx\""
  notify_error "缺少文件路径参数"
  exit 1
fi

# 处理单个文件的函数
process_single_file() {
  local DOCX_PATH="$1"

  # 检查文件是否存在
  if [ ! -f "$DOCX_PATH" ]; then
    print_error "文件不存在: $DOCX_PATH"
    notify_error "文件不存在: $DOCX_PATH"
    return 1
  fi

  # 检查是否为 DOCX 文件
  if [[ ! "$DOCX_PATH" =~ \.(docx|doc)$ ]]; then
    print_error "文件必须是 .docx 或 .doc 格式: $DOCX_PATH"
    notify_error "文件格式错误：必须是 .docx 或 .doc"
    return 1
  fi

  # 保存当前目录（docs 根目录）
  DOCS_ROOT=$(pwd)

  # 获取文件信息（绝对路径）
  DOCX_FULL_PATH="$DOCS_ROOT/$DOCX_PATH"
  DOCX_DIR="$DOCS_ROOT/$(dirname "$DOCX_PATH")"
  DOCX_FULL_NAME=$(basename "$DOCX_PATH")
  DOCX_NAME="${DOCX_FULL_NAME%.*}"
  MD_PATH="$DOCX_DIR/$DOCX_NAME.md"

  echo ""
  echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "${BLUE}📄 DOCX 转 Markdown${NC}"
  echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print_info "源文件: $DOCX_PATH"
  print_info "目标文件: $MD_PATH"
  echo ""

  # 步骤 1：转换文档
  print_info "步骤 1/4: 使用 Pandoc 转换文档..."

  cd "$DOCX_DIR" || return 1
  # 使用默认 markdown 格式以保留 Markdown 图片语法
  pandoc "$DOCX_FULL_NAME" -f docx -t markdown --extract-media=. -o "$DOCX_NAME.md" 2>&1

  if [ $? -ne 0 ]; then
    print_error "Pandoc 转换失败"
    notify_error "Pandoc 转换失败，请检查 docx 文件格式"
    return 1
  fi

  print_success "转换成功"
  echo ""

  # 步骤 2：检查生成的文件
  if [ ! -f "$DOCX_NAME.md" ]; then
    print_error "Markdown 文件未生成"
    notify_error "Markdown 文件生成失败"
    return 1
  fi

  print_success "Markdown 文件已生成"
  echo ""

  # 步骤 2.5：清理 Pandoc 生成的冗余格式
  print_info "步骤 1.5/4: 清理 Pandoc 格式..."

  # 使用 perl 进行多行匹配和替换
  perl -i -0pe '
    # 1. 移除图片尺寸属性（支持多行）
    s/\{[^}]*width="[^"]*"[^}]*\}//gs;
    s/\{[^}]*height="[^"]*"[^}]*\}//gs;

    # 2. 清理图片路径前缀
    s/\]\(\.\/(media\/)/]($1/g;           # ./media/ -> media/
    s/\]\(\.\/(?!media)/](media\//g;      # ./ -> media/ (如果不是 media，添加 media/)

    # 3. 处理 Word 自动链接（通用规则）
    # 如果链接文本和链接地址相同，移除链接保留文本

    # 3.1 处理带 {.underline} 的链接（必须在移除 {.underline} 之前）
    # [[text]{.underline}](link):extra -> `text:extra`
    s/\[\[([^\]]+)\]\{\.underline\}\]\([^\)]+\)([:\/][\w\/\-\.]+)/`$1$2`/g;

    # 3.2 处理 mailto 链接：[text](mailto:text) -> `text`
    s/\[([^\]]+)\]\(mailto:\1\)/`$1`/g;

    # 3.3 处理 HTTP 自动链接：[http://example.com](http://example.com) -> <http://example.com>
    s/\[(https?:\/\/[^\]]+)\]\(\1\)/<$1>/g;

    # 4. 移除 Pandoc 类名标记和括号扩展
    s/\{\.underline\}//g;
    s/\{\.[-\w]+\}//g;
    s/\[\[([^\]]+)\]\]/`$1`/g;
  ' "$DOCX_NAME.md"

  if [ $? -ne 0 ]; then
    print_error "格式清理失败"
    print_warning "保留原始 DOCX 文件和生成的 MD 文件供检查"
    notify_error "格式清理失败，原始文件已保留"
    return 1
  fi

  print_success "格式清理完成"

  # 统计清理的内容
  CLEANED_COUNT=$(grep -c "media/" "$DOCX_NAME.md" 2>/dev/null || echo "0")
  if [ "$CLEANED_COUNT" -gt 0 ]; then
    print_info "已清理 $CLEANED_COUNT 处图片引用格式"
  fi

  echo ""

  # 步骤 3：运行构建验证
  print_info "步骤 2/4: 验证构建..."

  # 回到 docs 根目录
  cd "$DOCS_ROOT" || return 1

  BUILD_LOG="/tmp/docx-convert-build-$(date +%s).log"
  npm run build > "$BUILD_LOG" 2>&1

  if [ $? -ne 0 ]; then
    print_error "构建验证失败"
    print_warning "查看日志: $BUILD_LOG"
    print_warning "保留原始 DOCX 文件"
    notify_error "构建验证失败，日志: $BUILD_LOG"
    return 1
  fi

  print_success "构建验证通过"
  echo ""

  # 步骤 4：删除原始 DOCX 文件
  print_info "步骤 3/4: 删除原始 DOCX 文件..."

  # 最终安全检查：确保 Markdown 文件存在且非空
  if [ ! -f "$MD_PATH" ] || [ ! -s "$MD_PATH" ]; then
    print_error "Markdown 文件不存在或为空"
    print_warning "保留原始 DOCX 文件"
    notify_error "Markdown 文件无效，原始文件已保留"
    return 1
  fi

  # 检查 media 目录是否有图片（如果原文档有图片）
  if [ -d "$DOCX_DIR/media" ]; then
    IMAGE_COUNT=$(find "$DOCX_DIR/media" -type f 2>/dev/null | wc -l | xargs)
    if [ "$IMAGE_COUNT" -eq 0 ]; then
      print_warning "media/ 目录存在但为空，可能图片提取失败"
      print_warning "保留原始 DOCX 文件供检查"
      notify_error "图片提取失败，原始文件已保留"
      return 1
    fi
  fi

  rm "$DOCX_FULL_PATH"

  if [ $? -eq 0 ]; then
    print_success "原始文件已删除: $DOCX_PATH"
  else
    print_warning "删除失败，请手动删除"
    notify_error "原始文件删除失败，请手动删除"
    return 1
  fi

  echo ""

  # 步骤 5：显示结果
  print_info "步骤 4/4: 检查转换结果..."
  echo ""

  # 统计信息
  MD_SIZE=$(wc -c < "$MD_PATH" | xargs)
  if [ -d "$DOCX_DIR/media" ]; then
    IMAGE_COUNT=$(find "$DOCX_DIR/media" -type f 2>/dev/null | wc -l | xargs)
  else
    IMAGE_COUNT=0
  fi

  echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "${GREEN}✅ 转换完成${NC}"
  echo ""
  echo "  📝 Markdown 文件: $MD_PATH"
  echo "  📏 文件大小: ${MD_SIZE} bytes"
  if [ $IMAGE_COUNT -gt 0 ]; then
    echo "  🖼️  提取图片: ${IMAGE_COUNT} 张 (位于 media/ 目录)"
  fi
  echo "  🗑️  原始 DOCX: 已删除"
  echo "  📋 构建日志: $BUILD_LOG"
  echo ""
  echo "${YELLOW}📌 下一步操作：${NC}"
  echo "  1. 优化 Markdown 排版（图片 alt 文本、标题格式等）"
  echo "  2. 运行 npm run dev 预览文档"
  echo "  3. 确认无误后提交变更"
  echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # 发送成功通知
  DOCX_FILENAME=$(basename "$DOCX_PATH")
  if [ $IMAGE_COUNT -gt 0 ]; then
    notify_success "$DOCX_FILENAME 已转换完成（含 ${IMAGE_COUNT} 张图片）"
  else
    notify_success "$DOCX_FILENAME 已转换完成"
  fi

  return 0
}

# 主逻辑：批量处理文件
TOTAL_FILES=$#
SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_FILES=()

echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}📦 批量转换 DOCX 文件${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}  总文件数: $TOTAL_FILES${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 循环处理所有文件
for DOCX_FILE in "$@"; do
  if process_single_file "$DOCX_FILE"; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_FILES+=("$DOCX_FILE")
  fi
done

# 显示最终统计
echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}📊 批量转换统计${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  总文件数: $TOTAL_FILES"
echo "  ${GREEN}成功: $SUCCESS_COUNT${NC}"
if [ $FAIL_COUNT -gt 0 ]; then
  echo "  ${RED}失败: $FAIL_COUNT${NC}"
  echo ""
  echo "${YELLOW}失败的文件：${NC}"
  for failed_file in "${FAILED_FILES[@]}"; do
    echo "    - $failed_file"
  done
fi
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 发送批量处理完成通知
if [ $FAIL_COUNT -eq 0 ]; then
  notify_success "批量转换完成：$SUCCESS_COUNT 个文件全部成功"
  exit 0
else
  notify_error "批量转换完成：$SUCCESS_COUNT 成功，$FAIL_COUNT 失败"
  exit 1
fi
