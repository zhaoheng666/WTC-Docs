# 核心规则（详细）

WorldTourCasino 项目的详细规则。此文件通过主项目 CLAUDE.md 的 @ 导入。

## 强制规则

### 文件路径链接

编写文档时，将所有源码文件链接转换为 GitHub 格式。

格式：
```
https://github.com/zhaoheng666/WorldTourCasino/blob/classic_vegas/path/to/file.ext
https://github.com/zhaoheng666/WorldTourCasino/blob/classic_vegas/path/to/file.ext#L10
https://github.com/zhaoheng666/WorldTourCasino/blob/classic_vegas/path/to/file.ext#L10-L20
```

### Docs 子项目链接

仅在 `docs/` 子项目中：
- 将所有相对 markdown 链接转换为绝对 HTTP 链接
- 本地使用：`http://localhost:5173/WTC-Docs/`
- 生产使用：`https://zhaoheng666.github.io/WTC-Docs/`
- 链接处理器在构建时自动运行

### 扩展激活规则

VS Code 扩展必须只在 WTC 项目中激活：
- 检查 `workspace.getWorkspaceFolder()` 名称
- 使用激活事件：`onStartupFinished`
- 禁止全局激活

### 配置文件同步

同步 `.vscode/settings.json` ↔ `WorldTourCasino.code-workspace`：
- 修改配置时更新两个文件
- 使用 `.vscode/scripts/` 中的自动化脚本
- 修改后测试

## Shell 脚本

编写 Shell 脚本遵循以下规则：

Shebang：
```bash
#!/usr/bin/env zsh
```

错误处理：
```bash
set -euo pipefail
```

最佳实践：
- 使用绝对路径
- 尽可能避免 `cd` 命令
- 引用所有变量：`"$var"`
- 操作前检查文件是否存在

## Git 提交信息

### 主项目

格式：`cv：关卡X [描述]`

示例：
- `cv：关卡1 fix bug in slot machine`
- `cv：关卡2 add new bonus feature`

或使用标准格式：
- `type(scope): subject`
- 类型：feat, fix, chore, docs, style, refactor

### Docs 子项目

始终使用标准格式：
- `type(scope): subject`
- 添加页脚：`🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## 术语

### 风格系统

- **Flavor**：游戏变体/品牌
  - CV = Classic Vegas (res_oldvegas/)
  - DH = Double Hit (res_doublehit/)
  - DHX = Double X (res_doublex/)
  - VS = Vegas Star (res_vegasstar/)

- **res_*/** 目录：风格特定资源
- **src/** 目录：所有风格共享代码
- **flavor/** 子目录：风格特定 JavaScript 代码

### 重要文件

- `resource_dirs.json`：资源版本控制（debug/release）
- `project.json`：Cocos2d 项目配置
- `main.js`：游戏入口
- `.vscode/settings.json`：VS Code 工作区设置
- `WorldTourCasino.code-workspace`：多根工作区配置

## 工作流程模式

### 添加新功能

1. 检查当前分支和风格上下文
2. 修改 `src/`（共享）或 `res_*/flavor/`（风格特定）
3. 运行本地构建：`scripts/build_local_[flavor].sh`
4. 在浏览器中测试
5. 运行 `npm run lint`
6. 使用正确格式提交

### 更新资源

1. 在相应的 `res_*/` 目录中添加/修改资源
2. 运行 `scripts/gen_res_list.py` 更新清单
3. 如需要，更新 `resource_dirs.json` 中的版本
4. 本地构建并测试

### 处理文档

1. 进入 docs 子项目：`cd docs`
2. 启动开发服务器：`npm run dev`
3. 进行修改
4. 测试构建：`npm run build`
5. 在 docs 仓库提交（独立于主项目）
6. 同步到 GitHub Pages：`npm run sync`

## 参考

完整的项目架构和详细信息，请参阅：
- `docs/工程-工具/ai-rules/WTC/CLAUDE-REFERENCE.md`（综合参考）
- 在线文档：https://zhaoheng666.github.io/WTC-Docs/
