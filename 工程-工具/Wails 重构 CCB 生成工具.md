# Wails 重构 CCB 生成工具

## 概述

这是使用 **Wails + Vue 3 + TypeScript** 重新实现的 CreateSlotSymbols 工具，完全复刻了原 Electron 版本的所有功能。

## 技术架构

### 后端 (Go)

- **框架**: Wails v2.10.2
- **依赖**:

  - `howett.net/plist` - Plist 文件解析
  - Wails runtime - 文件对话框、系统集成

### 前端 (Vue 3 + TypeScript)

- **框架**: Vue 3 Composition API + TypeScript
- **UI 库**: Element Plus 2.4.2
- **构建工具**: Vite + vue-tsc
- **图像处理**: Canvas API（浏览器原生）

## 实现的功能

### 核心功能

✅ **Plist 文件解析**: 支持 TexturePacker 格式的 plist 文件
✅ **Frame 提取**: 从图集中正确提取 frame（支持旋转和裁剪）
✅ **CCB 文件生成**: 智能模板替换，支持多种 CCB 类型
✅ **模板目录选择**: 动态扫描和选择 CCB 模板

### 用户界面

✅ **中文界面**: 保持与原版一致的中文用户体验
✅ **文件选择**: 图形化文件和目录选择对话框
✅ **实时预览**: Frame 预览图显示
✅ **进度显示**: 批量生成时的进度条和状态提示
✅ **错误处理**: 完善的错误提示和用户反馈

### 高级功能

✅ **命令行支持**: 支持 `--template` 参数指定模板目录
✅ **智能推断**: 自动从文件路径推断资源名称
✅ **模板扫描**: 动态扫描可用的 CCB 模板类型
✅ **批量处理**: 支持同时生成多个 CCB 文件

## 项目结构

```
createSymbols/
├── app.go              # Go 后端 API 实现
├── main.go             # Wails 应用入口
├── go.mod              # Go 依赖管理
├── wails.json          # Wails 项目配置
├── frontend/           # Vue 3 前端
│   ├── src/
│   │   ├── App.vue     # 主界面组件
│   │   └── main.ts     # Vue 应用入口
│   ├── wailsjs/        # Wails 自动生成的绑定
│   └── package.json    # 前端依赖
└── build/             # 构建输出
    └── bin/
        └── createSymbols.app  # 最终应用
```

## 构建和使用

### 开发模式

```bash
cd createSymbols
wails dev
```

### 生产构建

```bash
wails build
```

### 使用方式

1. **GUI 模式**: 双击 `createSymbols.app` 启动
2. **命令行模式**:

   ```bash
   ./createSymbols.app --template /path/to/templates
   ```

## 优势对比

与原 Electron 版本相比，Wails 版本具有以下优势：

### 性能优势

- **更小体积**: 约 10-15MB (vs Electron 的 ~140MB)，生成的 app content 更干净
- **更快启动**: Go 编译的二进制启动速度更快
- **更低内存**: 无需 Chromium 引擎，内存占用更低

### 技术优势

- **单一可执行文件**: 无需安装 Node.js 运行时
- **原生集成**: 更好的系统集成和文件对话框体验
- **跨平台**: 可以轻松构建 Windows、Linux 版本
- **结构清晰：** 项目文件结构清晰、分层合理

### 开发优势

- **类型安全**: 完整的 TypeScript 支持和 Go-JS 绑定
- **热重载**: 开发模式下支持前后端热重载
- **现代工具链**: Vite 构建 + Vue 3 Composition API

## 部署说明

- build_install.sh 脚本：编译后拷贝到 Plugins/tools/bin

## 应用启动方式

### 1. 使用启动脚本（推荐）

使用提供的启动脚本最简单：

```bash
cd /Users/ghost/work/WorldTourCasinoResource/PlugIns/tools/createSymbols

# 基本启动
./launch-createSymbols.sh

# 指定模板目录
./launch-createSymbols.sh --template "/path/to/your/template/directory"

# 指定模板目录和 plist 文件
./launch-createSymbols.sh --template "/path/to/templates" "/path/to/file.plist"

# 查看帮助
./launch-createSymbols.sh --help
```

### 2. 使用 `open` 命令

```bash
# 基本启动
open -a createSymbols.app

# 指定模板目录
open -a createSymbols.app --args --template "/Users/ghost/work/WorldTourCasinoResource/PlugIns/tools/themeA-B/Resources/template_res_name/reels/symbol"

# 指定模板目录和 plist 文件
open -a createSymbols.app --args --template "/path/to/templates" "/path/to/file.plist"
```

### 3. 直接调用可执行文件

```bash
# 基本启动
./createSymbols.app/Contents/MacOS/createSymbols

# 带参数启动
./createSymbols.app/Contents/MacOS/createSymbols --template "/path/to/templates"

# 带参数和文件启动
./createSymbols.app/Contents/MacOS/createSymbols --template "/path/to/templates" "/path/to/file.plist"
```

## 参数说明

### `--template` 或 `-t`

指定 CCB 模板目录路径，该目录应包含以下格式的文件：

- `template_res_name_symbol_batch_normal.ccb`
- `template_res_name_symbol_batch_link.ccb`
- `template_res_name_symbol_batch_jackpot.ccb`
- 等等

默认模板目录：

```
/Users/ghost/work/WorldTourCasinoResource/PlugIns/tools/themeA-B/Resources/template_res_name/reels/symbol
```

## 问题排查

[Wails 重构 CCB 生成工具-问题排查记录](/故障排查/Wails%20重构%20CCB%20生成工具-问题排查记录)
