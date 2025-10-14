# WorldTourCasino 专业术语表

**适用范围**: 仅 WorldTourCasino 主项目

本文件帮助 AI 理解项目中的专有概念和术语。

---

## 核心系统

### CardSystem（收集系统/卡册系统）

- **中文名称**: 收集系统 / 卡册系统
- **相关路径**: `src/social/controller/card_system/`
- **管理器**: `CardSystemMan` (位于 `src/social/model/CardSystemMan.js`)
- **功能**:
  - 卡片收集
  - 进度追踪
  - 赛季奖励
  - 卡片合成

---

## 多风格系统（Flavor System）

### Flavor（风格/裂变产品）

- **说明**: 基于同一代码库的不同品牌版本
- **共享代码**: `src/` 目录（所有风格共享）
- **独立资源**: `res_*/` 目录（每个风格独立）

### 风格列表

| 风格名称 | 目录 | 简称 | 说明 |
|---------|------|------|------|
| Classic Vegas | `res_oldvegas/` | **CV/cv** | 主要工作分支 |
| Double Hit | `res_doublehit/` | **DH/dh** | |
| Vegas Star | `res_vegasstar/` | **VSS/VS/vs** | |
| Double X | `res_doublex/` | **DHX/dhx** | |

### 风格目录结构

每个风格（`res_*`）包含：
- `flavor/index.html` - 入口文件
- `flavor/project.json` - Cocos2d 配置
- `flavor/js_src/common/util/Config.js` - 风格特定设置
- `resource_list/` - 带版本控制的资源清单
- `activity/`, `casino/`, `slot/` - 游戏资源

---

## 构建系统

### resource_dirs.json

- **功能**: 资源版本控制
- **版本类型**:
  - `debug` - 调试版本
  - `release` - 发布版本
- **位置**: 每个 `res_*/` 目录下

### 构建产物

以下文件由构建脚本自动生成，**不应提交到版本控制**：
- `res_*/flavor/index.html`
- `res_*/flavor/main*.css`
- `res_*/flavor/project.json`
- `res_*/flavor/js_src/common/util/Config.js`
- `res_*/resource_list/**/*.json`
- `res_*/resource_dirs.json`

---

## 技术栈

### 核心引擎

- **Cocos2d-html5**: JavaScript 游戏引擎
- **版本**: v3.13-lite-wtc (定制版)
- **位置**: `frameworks/cocos2d-html5-v3.13-lite-wtc.js`

### 开发语言

- **JavaScript**: ES5（强制严格模式）
- **模块系统**: Browserify 进行打包
- **构建系统**: 自定义 bash 脚本 + Python 工具

---

## 资源管理

### 动态加载

- 活动资源可以延迟加载
- 减少初始加载时间

### CDN 部署

- 自动化部署
- 缓存失效处理
- 版本控制通过 `resource_dirs.json`

---

## Git 工作流

### 分支命名

- **主分支**: `classic_vegas`
- **功能分支**: `classic_vegas_cvs_v*_subject_*`
  - 例如: `classic_vegas_cvs_v865_card_system`

### 提交格式

- **格式**: `cv：关卡X [描述]`
- **示例**: `cv：关卡100 添加新的奖励机制`

---

## 重要文件

| 文件路径 | 说明 |
|---------|------|
| `resource_dirs.json` | 资源版本控制（每个 res_*/ 下） |
| `src/log/enum/UIClickId.js` | UI 点击事件跟踪定义 |
| `src/social/controller/card_system/` | 收集系统实现 |
| `src/social/model/CardSystemMan.js` | 收集系统管理器 |
| `.vscode/tasks.json` | VS Code 自动化配置（100+ 任务） |

---

**最后更新**: 2025-10-13
**维护者**: WorldTourCasino Team
