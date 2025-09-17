#!/bin/bash

# 创建图片符号链接脚本
# 让编辑器能预览图片，同时保持目录纯净

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔗 创建图片符号链接${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 获取脚本所在目录的上上级目录（docs目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$DOCS_DIR" || exit 1

# 1. 在根目录创建 images 符号链接
if [ -L "images" ]; then
    echo -e "${YELLOW}⚠️  images 符号链接已存在${NC}"
elif [ -e "images" ]; then
    echo -e "${RED}❌ images 已存在但不是符号链接${NC}"
    exit 1
else
    ln -s public/images images
    echo -e "${GREEN}✅ 创建 images -> public/images 符号链接${NC}"
fi

# 2. 更新 .gitignore
if ! grep -q "^images$" .gitignore 2>/dev/null; then
    echo -e "\n# 图片符号链接（编辑器预览用）" >> .gitignore
    echo "images" >> .gitignore
    echo -e "${GREEN}✅ 更新 .gitignore 忽略符号链接${NC}"
else
    echo -e "${CYAN}ℹ️  .gitignore 已配置${NC}"
fi

# 3. 检查效果
echo -e "\n${CYAN}检查配置...${NC}"

# 检查是否有图片
IMAGE_COUNT=$(find public/images -type f -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" 2>/dev/null | wc -l)
echo -e "  图片数量: ${CYAN}$IMAGE_COUNT${NC}"

# 检查符号链接
if [ -L "images" ]; then
    echo -e "  符号链接: ${GREEN}✓ 正常${NC}"
    
    # 测试路径
    TEST_IMAGE=$(find public/images -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | head -1)
    if [ -n "$TEST_IMAGE" ]; then
        # 获取相对路径
        REL_PATH=${TEST_IMAGE#public/}
        if [ -f "$REL_PATH" ]; then
            echo -e "  路径测试: ${GREEN}✓ 可访问${NC}"
        else
            echo -e "  路径测试: ${RED}✗ 不可访问${NC}"
        fi
    fi
fi

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ 配置完成！${NC}"
echo -e "\n使用说明："
echo -e "1. 图片实际存储在 ${CYAN}public/images/${NC}"
echo -e "2. MD 文件使用 ${CYAN}/images/...${NC} 引用图片"
echo -e "3. 编辑器通过符号链接可以预览图片"
echo -e "4. 符号链接已加入 .gitignore，不会提交到仓库"
echo -e "\n${YELLOW}注意：${NC}"
echo -e "- Windows 系统可能需要管理员权限创建符号链接"
echo -e "- 某些编辑器可能需要重启才能识别符号链接"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0