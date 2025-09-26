# fix-environment.sh 脚本多扩展多编辑器支持更新

## 更新时间
2025-09-27

## 背景
原始的 fix-environment.sh 脚本只支持单个扩展（wtc-toolbar）和两个编辑器（VSCode、Trae）。随着项目发展，需要支持更多扩展和编辑器。

## 更新内容

### 1. 支持的扩展
- wtc-toolbar (0.0.1) - VSCode 工具栏扩展
- google-drive-uploader (0.0.1) - Google Drive 上传扩展

### 2. 支持的编辑器
- VSCode (`.vscode/extensions`)
- Trae (`.trae/extensions`)
- Trae-CN (`.trae-cn/extensions`)
- Windsurf (`.windsurf/extensions`)
- Cursor (`.cursor/extensions`)

### 3. 技术改进

#### 问题修复
1. **配置兼容性问题**
   - 原始脚本依赖 `extensionName` 和 `symlinkName` 配置字段
   - 新的 settings.json 使用了 `plugins` 结构
   - 解决方案：硬编码扩展信息，避免配置依赖

2. **Bash 兼容性问题**
   - `declare -A` (关联数组) 在某些 bash 版本不支持
   - 解决方案：使用普通变量和循环替代关联数组

#### 代码实现
```bash
# 定义所有扩展（硬编码，因为配置结构变化）
declare -a EXTENSIONS=(
    "wtc-toolbar:0.0.1:vscode-toolbar-extension"
    "google-drive-uploader:0.0.1:google-drive-uploader"
)

# 定义所有编辑器的扩展目录
VSCODE_EXT_DIR="$HOME/.vscode/extensions"
TRAE_EXT_DIR="$HOME/.trae/extensions"
TRAE_CN_EXT_DIR="$HOME/.trae-cn/extensions"
WINDSURF_EXT_DIR="$HOME/.windsurf/extensions"
CURSOR_EXT_DIR="$HOME/.cursor/extensions"

# 为每个编辑器创建扩展目录
for EXT_DIR in "$VSCODE_EXT_DIR" "$TRAE_EXT_DIR" "$TRAE_CN_EXT_DIR" "$WINDSURF_EXT_DIR" "$CURSOR_EXT_DIR"; do
    if [ ! -d "$EXT_DIR" ]; then
        mkdir -p "$EXT_DIR"
    fi
done

# 为每个扩展在所有编辑器中创建符号链接
for EXT_INFO in "${EXTENSIONS[@]}"; do
    IFS=':' read -r EXT_NAME EXT_VERSION EXT_DIRNAME <<< "$EXT_INFO"
    EXT_SOURCE="$EXTENSIONS_DIR/$EXT_DIRNAME"

    for EXT_DIR in "$VSCODE_EXT_DIR" "$TRAE_EXT_DIR" "$TRAE_CN_EXT_DIR" "$WINDSURF_EXT_DIR" "$CURSOR_EXT_DIR"; do
        EXT_LINK="$EXT_DIR/${EXT_NAME}-${EXT_VERSION}"
        ln -sf "$EXT_SOURCE" "$EXT_LINK" 2>/dev/null
    done
done
```

## 使用方法
```bash
# 运行环境修复脚本
bash .vscode/scripts/fix-environment.sh
```

## 执行效果
脚本会自动：
1. 清理并重新克隆 vscode-extensions 仓库
2. 为五个编辑器创建扩展目录（如果不存在）
3. 为每个扩展在所有编辑器中创建符号链接
4. 输出每个步骤的执行状态

示例输出：
```
[7/8] 检查和恢复 VS Code 扩展...
✓ VS Code 扩展仓库克隆成功
  处理扩展: wtc-toolbar-0.0.1
    ✓ .vscode 扩展链接已创建
    ✓ .trae 扩展链接已创建
    ✓ .trae-cn 扩展链接已创建
    ✓ .windsurf 扩展链接已创建
    ✓ .cursor 扩展链接已创建
  处理扩展: google-drive-uploader-0.0.1
    ✓ .vscode 扩展链接已创建
    ✓ .trae 扩展链接已创建
    ✓ .trae-cn 扩展链接已创建
    ✓ .windsurf 扩展链接已创建
    ✓ .cursor 扩展链接已创建
✓ VS Code 扩展恢复完成
```

## 相关文件
- 脚本位置：[.vscode/scripts/fix-environment.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/scripts/fix-environment.sh)
- 扩展仓库：https://github.com/zhaoheng666/WTC-extensions.git
- 配置文件：[.vscode/settings.json](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/settings.json)

## 注意事项
1. 扩展信息目前硬编码在脚本中，添加新扩展需要手动更新 `EXTENSIONS` 数组
2. 编辑器目录路径遵循各编辑器的标准扩展目录规范
3. 脚本使用符号链接，需要文件系统支持
4. 首次运行会克隆整个 vscode-extensions 仓库，需要 git 访问权限