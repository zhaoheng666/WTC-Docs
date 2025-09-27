# VSCode 扩展开发注意事项

## 技术迭代记录

### 2025-01-27：扩展配置管理优化

#### 1. 使用 jq 替代 Node.js 读取 JSON 配置

**问题**：原先使用 Node.js 读取 `settings.json` 配置过于冗长复杂

**原方案**：
```bash
plugin_name=$(node -e "
    const fs = require('fs');
    const settingsPath = '$PROJECT_ROOT/.vscode/settings.json';
    try {
        let content = fs.readFileSync(settingsPath, 'utf8');
        content = content.replace(/\/\/.*$/gm, '');
        content = content.replace(/\/\*[\s\S]*?\*\/g, '');
        const settings = JSON.parse(content);
        const plugins = settings['WTC.subProjects'].extensions.plugins;
        if (plugins && plugins['$plugin_key'] && plugins['$plugin_key']['name']) {
            console.log(plugins['$plugin_key']['name']);
        }
    } catch (error) {
        process.exit(1);
    }
" 2>/dev/null)
```

**优化方案**：使用项目级 jq 工具
```bash
local JQ="$PROJECT_ROOT/node_modules/.bin/jq"
plugin_name=$($JQ -r ".["WTC.subProjects"].extensions.plugins.$plugin_key.name // empty" "$settings_file" 2>/dev/null)
```

**关键点**：
- 使用 `node_modules/.bin/jq` 而非 `node_modules/jq/bin/jq`（符合 Node.js 惯例）
- 使用项目级 jq 而非系统级，确保可移植性
- 代码更简洁，性能更好

#### 2. 动态读取扩展配置

**改进**：从 `settings.json` 动态读取扩展列表，避免硬编码

相关文件：
- [.vscode/scripts/onEnter.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/scripts/onEnter.sh) - 项目启动时的扩展设置
- [.vscode/scripts/fix-environment.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/scripts/fix-environment.sh) - 环境修复脚本

## 开发环境配置

### 软链接装载插件的关键要求

**重要**：开发环境下使用软链接方式装载插件时，必须保证：

1. **插件目录名与软链接名一致**
   - 插件实际目录：`vscode-extensions/vscode-toolbar-extension/`
   - 软链接名称：`~/.vscode/extensions/vscode-toolbar-extension`
   - ⚠️ **两者名称必须完全一致，否则 VSCode 无法识别处于开发期间的插件**

2. **示例配置**（settings.json）：
```json
{
    "WTC.subProjects": {
        "extensions": {
            "plugins": {
                "toolbar": {
                    "name": "vscode-toolbar-extension",  // 实际目录名
                    "symlinkName": "vscode-toolbar-extension"  // 软链接名（必须一致）
                },
                "googleDrive": {
                    "name": "google-drive-uploader",
                    "symlinkName": "google-drive-uploader"
                }
            }
        }
    }
}
```

3. **创建软链接的正确方式**：
```bash
# 正确：目录名和链接名一致
ln -sf "$EXTENSIONS_DIR/vscode-toolbar-extension" "$HOME/.vscode/extensions/vscode-toolbar-extension"

# 错误：名称不一致会导致插件无法识别
# ln -sf "$EXTENSIONS_DIR/vscode-toolbar-extension" "$HOME/.vscode/extensions/toolbar-0.0.1"
```

## 多编辑器支持

脚本同时为以下编辑器创建扩展软链接：
- VS Code：`~/.vscode/extensions/`
- Trae：`~/.trae/extensions/`
- TraeCN：`~/.trae-cn/extensions/`
- Windsurf：`~/.windsurf/extensions/`
- Cursor：`~/.cursor/extensions/`

## 故障排查

### 插件无法识别

1. **检查软链接名称**：
```bash
ls -la ~/.vscode/extensions/ | grep your-extension
```

2. **验证 package.json**：
```bash
cat vscode-extensions/your-extension/package.json | jq '.name, .publisher'
```

3. **确保目录名一致性**：
- 实际目录名
- 软链接名
- package.json 中的 name 字段

### 调试建议

1. 使用 VSCode 开发者工具查看扩展加载日志
2. 检查 `~/.vscode/extensions/` 目录下的软链接是否正确
3. 重启 VSCode 并查看扩展是否被识别

## 参考资料

- [VSCode 扩展开发文档](https://code.visualstudio.com/api)
- [项目扩展配置](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/.vscode/settings.json)