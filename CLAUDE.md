# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

WorldTourCasino 技术文档系统，基于 VitePress 构建，自动部署到 GitHub Pages。

- **访问地址**：https://zhaoheng666.github.io/WTC-Docs/
- **基础路径**：`/WTC-Docs/`
- **开发端口**：5173（固定）

## 快速参考

### 常用命令

```bash
npm run init   # 初始化环境（首次使用或修复问题）
npm run dev    # 启动开发服务器
npm run build  # 本地构建测试
npm run sync   # 一键同步（构建→测试→提交→推送→部署）
npm run status # 检查状态
```

### 核心配置文件

- `.vitepress/config.mjs` - VitePress 主配置
- `.vitepress/sidebar.mjs` - 自动生成侧边栏
- `.github/workflows/deploy.yml` - GitHub Actions 部署
- `.vitepress/scripts/` - 自动化脚本目录

## 文档索引

### 项目文档

- **项目总览**：[README.md](./README.md) - 特性、结构、使用方法
- **技术架构**：[技术文档.md](./技术文档.md) - 构建流程、图片处理、同步机制
- **工作规范**：[工作规范.md](./工作规范.md) - 编写规范、命名规范

### 分类文档

- **原生平台**：`native/` 目录
- **工程工具**：`工程-工具/` 目录
- **故障排查**：`故障排查/` 目录
- **团队成员**：`成员/` 目录
- **关卡系统**：`关卡/` 目录
- **活动系统**：`活动/` 目录
- **协议相关**：`协议/` 目录
- **其他文档**：`其他/` 目录

## 关键特性说明

### 自动化脚本

所有脚本位于 `.vitepress/scripts/`：

- `init.sh` - 环境初始化
- `dev.sh` - 开发服务器（自动处理端口冲突）
- `build.sh` - 构建脚本（包含图片处理）
- `sync.sh` - 一键同步工作流
- `image-processor.js` - 图片自动处理
- `generate-stats.js` - 统计生成

### 图片处理

- 自动下载外部图片到 `public/assets/`
- 命名格式：`文件路径_哈希值.扩展名`
- 自动更新 Markdown 中的引用
- 构建时清理未使用的图片

### 搜索优化

- 使用 Intl.Segmenter 实现中文分词
- 标题权重高于正文
- 支持模糊匹配

### 日志位置

- `/tmp/vitepress-build.log` - 构建日志
- `/tmp/image-processor.log` - 图片处理日志
- `/tmp/sync-build.log` - 同步日志

## 开发注意事项

### 文档编写规范

#### 代码块语言标识符规则

在编写 Markdown 文档时，代码块必须使用 VitePress 支持的语言标识符：

- **不支持的语言**：使用 `text` 作为默认标识符
  - 例如：`gitignore`、`justfile`、`just`、`env`、`dotenv` 等
- **常用支持的语言**：`bash`、`javascript`、`typescript`、`json`、`python`、`html`、`css`、`sql` 等
- **规则**：如果 VitePress 显示"The language 'xxx' is not loaded, falling back to 'bash'"警告，应改为 `text`

示例：
```text
# 错误写法
```gitignore
.vscode/.env-verified
```

# 正确写法
```text
.vscode/.env-verified
```
```

#### 文件路径链接规则

在文档中提及具体的代码文件路径时，应自动转换为 GitHub 链接：

1. **主项目文件**：链接到主仓库 `https://github.com/LuckyZen/WorldTourCasino`

   - 格式：`[文件路径](https://github.com/LuckyZen/WorldTourCasino/blob/分支名/文件路径)`
   - 示例：[`scripts/build_local_app.sh`](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas_cvs_v855/scripts/build_local_app.sh)
2. **子仓库文件**：链接到对应的子仓库

   - cocos2d-html5：`https://github.com/LuckyZen/cocos2d-html5`
   - cocos2d-x：`https://github.com/LuckyZen/cocos2d-x`
   - libZenSDK：`https://github.com/LuckyZen/libZenSDK`
3. **子仓库处理步骤**：

   ```bash
   # 获取子仓库当前提交
   cd 主项目/frameworks/cocos2d-html5
   git log --oneline -1  # 获取提交哈希

   # 使用提交哈希构建链接
   https://github.com/LuckyZen/cocos2d-html5/blob/提交哈希/文件路径
   ```
4. **子仓库映射表**：

   - `frameworks/cocos2d-html5/` → `https://github.com/LuckyZen/cocos2d-html5`
   - `frameworks/cocos2d-x/` → `https://github.com/LuckyZen/cocos2d-x`
   - `libZenSDK/` → `https://github.com/LuckyZen/libZenSDK`

### Git 工作流

#### 提交类型规范

| 类型     | 描述                               | 示例                           |
| -------- | ---------------------------------- | ------------------------------ |
| docs     | 文档更新                           | docs: 更新 API 接口说明        |
| chore    | 构建过程、辅助工具或杂项任务的变动 | chore: 更新 webpack 配置       |
| feat     | 新增功能或特性                     | feat: 添加搜索功能             |
| fix      | 修复 bug                           | fix: 解决图片显示错误          |
| style    | 代码格式调整（不影响代码逻辑）     | style: 调整代码缩进            |
| refactor | 代码重构                           | refactor: 优化构建流程         |
| perf     | 性能优化                           | perf: 优化图片加载速度         |
| ci       | 持续集成配置更改                   | ci: 更新 GitHub Actions 工作流 |

#### 提交规则

- **不添加 AI 标识**: 提交信息中不包含 "Generated with Claude" 等 AI 相关标识
- **简洁明了**: 提交信息应直接描述变更内容，无需额外后缀
- **自动化提交**: docs 子项目可以自动完成提交和推送
- **自动恢复 stash**: 提交推送完成后，如有 stash 会自动恢复
- 推送到 main 分支自动触发部署
- 构建时间 ~18秒，部署时间 ~10秒

### 常见问题快速解决

- **端口占用**：`dev.sh` 会自动终止占用进程
- **图片未清理**：运行 `npm run build` 重新处理
- **构建失败**：查看 `/tmp/vitepress-build.log`
- **同步冲突**：`sync.sh` 自动尝试 rebase/merge

### 链接设计规范

[WTC-docs-链接设计规范](./工程-工具/WTC-docs链接设计规范.md)

## 架构决策记录 (ADR)

### ADR-001: 统计数据生成策略

**决策日期**: 2024-09-18
**状态**: 已实施

**背景**: 需要为文档系统提供实时统计信息（贡献者数量、今日更新次数、文档总数等），但本地开发环境和生产环境有不同需求。

**决策**:
- **仅在CI环境生成统计数据**: `generate-stats.js` 脚本只在 `GITHUB_ACTIONS=true` 时执行
- **本地通过HTTP获取**: 本地开发时，前端组件通过 `https://zhaoheng666.github.io/WTC-Docs/stats.json` 获取线上数据
- **基于Git记录**: 所有统计数据基于实际的 Git 提交记录动态生成，不使用硬编码数据

**原因**:
1. **避免本地Git环境差异**: 不同开发者的本地Git配置可能影响统计准确性
2. **减少本地构建时间**: 统计生成需要遍历Git历史，在本地跳过可提升开发体验
3. **确保数据一致性**: 所有用户看到的都是来自生产环境的一致统计数据
4. **简化部署流程**: 只需在CI环境处理统计逻辑，降低复杂度

**影响**:
- 本地开发时统计数据来自线上，可能略有延迟
- 需要确保 `public/stats.json` 在生产环境正常生成
- 前端组件需要处理网络请求失败的情况

### ADR-002: 目录索引内容保护机制

**决策日期**: 2024-09-25
**状态**: 已实施

**背景**: 自动生成目录索引时，需要在保持自动化的同时保护用户的自定义内容。

**决策**:
- **只更新目录结构部分**: 智能识别 `## 📋 目录结构` 部分进行替换
- **完全保护用户内容**: 保留标题、介绍、开发指南等所有自定义章节
- **智能创建模式**: 新文件使用标准模板，已存在文件进行部分更新

**原因**:
1. **内容安全**: 避免覆盖用户花时间编写的文档内容
2. **灵活性**: 允许每个目录有自己的特色介绍和说明
3. **可维护性**: 用户可以安全地添加架构说明、最佳实践等内容

### ADR-003: URL编码与特殊字符处理

**决策日期**: 2024-09-25
**状态**: 已实施

**背景**: 文档中存在中文文件名、空格、特殊字符，需要在生成链接时正确处理。

**决策**:
- **选择性编码**: 只编码必要字符，保留常见安全字符（!', ()*, 等）
- **分段处理**: 按 `/` 分割路径，分别编码每段后重新组合
- **保持可读性**: 在安全的前提下尽量保持链接的可读性

**原因**:
1. **VitePress兼容性**: 确保生成的链接能被VitePress正确解析
2. **中文支持**: 正确处理中文文件名的编码问题
3. **用户体验**: 保持链接相对简洁和可读

## 相关链接

- [VitePress 文档](https://vitepress.qzxdp.cn/)
- [GitHub 仓库](https://github.com/zhaoheng666/WTC-Docs)
- [GitHub Actions](https://github.com/zhaoheng666/WTC-Docs/actions)
