# Q3`25-Slots-Symbol-CCB创建工具-程序

## 初始需求：

- ### 需求描述：

  读取本地 Plist 文件（图集文件），按固定结构读取其中的信息，将读取到的条目用 UI 组件排列、显示出来，为每个条目提供额外的操作选项，并将操作结果存储到指定的本地文件中；
- ### 需求拆分：

  1、桌面工具，可作为独立应用打开、也可通过 shell 脚本调用打开；  
  2、可在打开后，在界面中操作选取需要读取的配置文件，也可在 shell 命令启动时传入文件路径，并通过配置文件的路径推断当前 res_name；  
  例如，配置文件示例：/Users/ghost/work/WorldTourCasinoResource/theme273-275/Resources/luxurious_vaults/reels/symbol/luxurious_vaults_symbol_batch.plist  
  推断的 res_name = luxurious_vaults  
  3、从配置文件中读取 frames，将 frames 以列表形式显示到本工具界面中；显示内容包括：frameSize，frame 文件名，frame 图片；  
  4、为每个 frame 条目提供这些操作：  
  1）、是否需要生成 CCB 文件，默认勾选；  
  2）、选择要生成的 CCB 文件类型：normal、link、jackpot等，默认为 normal；  
  3）、需要生成的 CCB 文件名，可输入，未输入时默认填充为 frame 文件名的 basename + '.ccb'；  
  5、提供操作按钮：生成 CCB；  
  6、生成 CCB 功能：  
  1）、按照 frames 的信息和配置生成 .cbb 文件；  
  2）、拷贝对应的ccb 文件模板：  
  {  
  "nomal":"/Users/ghost/work/WorldTourCasinoResource/PlugIns/tools/themeA-B/Resources/template_res_name/reels/symbol/template_res_name_symbol_batch_normal.ccb",  
  "nomal":"/Users/ghost/work/WorldTourCasinoResource/PlugIns/tools/themeA-B/Resources/template_res_name/reels/symbol/template_res_name_symbol_batch_link.ccb",  
  "nomal":"/Users/ghost/work/WorldTourCasinoResource/PlugIns/tools/themeA-B/Resources/template_res_name/reels/symbol/template_res_name_symbol_batch_jackpot.ccb"  
  ......  
  }  
  3）、CCB 文件名、文件内容做字符串替换，template_res_name 替换为第 2 条需求中推断出的 res_name；  
  4）、查找CCB文件内容，将包含 "....._T.png" 修改为 frame 的文件名；
- ### 技术选型：

  1、使用 electron + vue + ts/js；

  2、可以自行选择合适的 GUI 库；
- ### 技术指标：

  1、代码结构清晰、设计明了；

  2、易于扩展；

  3、做好语法检查；
- ### 工程需求：

## 需求迭代记录

### 1. Frame 提取功能实现

**问题描述**：最初实现的 frame 提取显示的是整个图集，而非单个 frame  
**解决方案**：

- 参考 plistUnpack.py 实现正确的 frame 提取逻辑
- 处理 TexturePacker 的 rotated（90度逆时针旋转）属性
- 正确处理 sourceColorRect 用于还原被裁剪的透明区域
- 使用 Canvas API 替代 Sharp 库进行图片处理

### 2. CCB 文件生成逻辑

**问题描述**：CCB 文件中的 frame 名称替换逻辑错误，破坏了文件结构  
**解决方案**：

- 分析实际 CCB 文件结构，发现需要精确替换 displayFrame 数组中的内容
- 实现智能替换逻辑，支持 blur 变体（如 _symbol_batch_blur_T.png）
- 使用正则表达式精确匹配和替换 displayFrame 数组中的 frame 名称
- 扫描模板目录中的 template_res_name_symbol_batch_*.ccb 文件，动态生成 CCB 类型选项

### 3. 路径处理和参数传递

**改进内容**：

- 移除所有硬编码路径，实现动态模板目录检测
- 从依赖 config.json 改为支持命令行参数 `--template` 或 `-t`​
- 支持绝对路径和相对路径
- 区分开发环境和生产环境的参数处理
- 实现 open-file 事件处理器支持 macOS 文件关联
- 修复 `open -a` 命令参数传递问题

### 4. 应用生命周期管理

**优化内容**：

- 移除单实例锁定，允许多个实例并行运行
- 窗口关闭时完全退出应用进程
- 统一所有平台的关闭行为
- 设置应用名称为 "CreateSlotSymbols"（无空格）

### 5. TypeScript 类型系统完善

**实现内容**：

- 在 `src/shared/types.ts` 中定义完整的 `ElectronAPI` 接口
- 声明全局 `window.electronAPI` 类型
- 修正所有类型错误和警告
- 解决动态导入在 CommonJS 中的兼容性问题

### 6. 应用打包和分发

**实现方案**：

- 使用 electron-builder 生成独立的 macOS 应用
- 配置正确的 bin 目录路径: `PlugIns/tools/bin/`​
- 合并 shell 脚本，简化部署
- 优化应用体积：移除未使用的依赖，只保留中英文语言包
- 最终体积：约 740MB（主要是 Electron 框架本身）

### 7. 模板目录选择功能

**新增功能**：

- 添加手动选择模板目录的 UI 功能
- 在主进程添加 `select-template-directory` IPC 处理器
- 在生成 CCB 时检测模板目录，未设置时提示用户选择
- 支持运行时动态切换模板目录

### 8. UI 界面优化

**改进内容**：

- **样式统一**：模板选择器与 plist 选择器采用相同的 input + Browse 按钮布局
- **布局优化**：统一标签对齐（右对齐，80px），调整行间距为 12px
- **信息展示**：将 Resource 标签移到 Frames 卡片标题栏中
- **中文化**：部分 UI 文本改为中文（模板目录、Batch图集、选择）
- **交互优化**：模板选择器在上，Plist 文件选择器在下

### 9. 技术栈最终确定

- **框架**：Electron + Vue 3 + TypeScript
- **UI 库**：Element Plus
- **图像处理**：Canvas API（浏览器原生）
- **构建工具**：Vite + electron-builder
- **IPC 通信**：Electron 的 contextBridge 和 ipcRenderer/ipcMain

### 10. 项目结构

```
createSlotSymbols/
├── src/
│   ├── main/           # Electron 主进程
│   │   ├── index.ts    # 主进程入口（含模板目录选择功能）
│   │   └── preload.ts  # 预加载脚本
│   ├── renderer/       # 渲染进程（Vue 应用）
│   │   ├── App.vue     # 主界面组件（优化后的 UI）
│   │   └── main.ts     # Vue 应用入口
│   └── shared/
│       └── types.ts    # TypeScript 类型定义
├── dist/               # 构建输出目录
├── dist-app/           # 应用打包输出目录
├── package.json        # 项目配置（productName: CreateSlotSymbols）
├── tsconfig.main.json  # 主进程 TypeScript 配置
└── LLMRequirementDoc.md # 需求文档

PlugIns/tools/bin/
└── CreateSlotSymbols.app  # 打包后的 macOS 应用
```

### 11. 使用方式

1. **直接打开应用**：双击 CreateSlotSymbols.app，手动选择模板目录和 plist 文件
2. **命令行启动（带参数）** ：

    ```bash
    open -a CreateSlotSymbols.app --args --template [模板路径] [plist文件路径]
    ```
3. **Shell 脚本调用**：

    ```bash
    createSlotSymbols.sh [plist文件路径]
    ```

### 12. 关键特性总结

1. **Frame 提取**：正确处理 TexturePacker 格式，支持旋转和裁剪
2. **CCB 生成**：智能替换模板内容，支持 blur 变体
3. **模板路径**：支持命令行参数指定，支持手动选择，支持绝对/相对路径
4. **类型安全**：完整的 TypeScript 类型定义
5. **用户体验**：清晰的错误提示，进度显示，中文化界面
6. **灵活部署**：独立 .app 应用，无需 npm 环境
