# Vscode 环境、工具开发规范

## 命名约定

### 设计理念

WorldTourCasino 项目采用**差异化命名策略**，通过文件名风格区分不同类型的代码：

- **下划线（_）**：主项目业务代码
- **连字符（-）**：开发辅助工具

这种设计让开发者能够一眼识别文件的用途和重要性。

### 具体规范

#### 主项目文件（使用下划线）

**适用范围**：业务逻辑相关的所有文件

**目录位置**：

- `scripts/` - 构建和部署脚本
- `src/` - 源代码
- `res/` - 资源文件
- `config/` - 配置文件

**命名示例**：

```bash
# Shell 脚本
build_local_app.sh
adb_sync_native.sh
build_fb_alpha.sh

# 配置文件
popup_pools.json
subject_tmpl_1002.json
special_paytable_1003.json

# Python 脚本
build_local_hotfix.py
check_json_format.py
```

#### 开发工具（使用连字符）

**适用范围**：研发辅助工具、VSCode 扩展功能

**目录位置**：`.vscode/` 目录下的所有文件和目录

**命名示例**：

```bash
# 目录
.vscode/google-drive/
.vscode/local-server/
.vscode/wtc-docs/

# Shell 脚本
fix-environment.sh
check-docs-setup.sh
sync-docs.sh
start-local-server.sh

# 任务标签
build-local-cv
run-local-check
upload-to-google-drive
```

### 命名决策依据

#### 为什么主项目使用下划线？

1. **Unix/Linux 传统**：Shell 脚本历史惯例
2. **Shell 友好**：避免被误解为命令选项
3. **双击选择**：可以双击选中完整文件名
4. **团队习惯**：项目已建立的规范

#### 为什么开发工具使用连字符？

1. **视觉区分**：立即识别非业务代码
2. **现代工具链**：符合 VSCode、npm、Docker 等生态
3. **命名空间隔离**：防止与主项目混淆
4. **降低风险**：避免工具被误认为核心逻辑

### 优势说明

这种差异化命名带来以下好处：

1. **清晰的边界**

   - 一眼区分产品代码与辅助工具
   - 新成员快速理解项目结构
2. **便于管理**

   - 可通过命名模式批量处理
   - `.gitignore` 规则更简单
3. **降低误操作风险**

   - 不会混淆关键业务脚本
   - 工具脚本修改不影响产品
4. **搜索效率**

   - 自动补全时快速定位
   - grep/find 时精确过滤

### 例外情况

以下情况可以不遵循上述规范：

1. **第三方要求的固定名称**

   - VSCode 插件图标：`userButton01_light.svg`
   - npm 包配置：`package.json`
   - Git 配置：`.gitignore`
2. **框架约定**

   - Vue 组件：遵循 Vue 规范
   - React 组件：遵循 React 规范
3. **已有规范的配置文件**

   - `tsconfig.json`
   - `webpack.config.js`
   - `.eslintrc.js`

### 实践示例

#### ❌ 错误示例

```bash
# 开发工具使用了下划线
.vscode/fix_environment.sh

# 主项目使用了连字符
scripts/build-local-app.sh
```

#### ✅ 正确示例

```bash
# 主项目 - 下划线
scripts/build_local_app.sh
config/popup_pools.json

# 开发工具 - 连字符
.vscode/scripts/fix-environment.sh
.vscode/tasks.json 中的 "label": "build-local-cv"
```
