# stats.json 同步问题解决方案

## 问题描述
- 本地和 CI 环境生成的 stats.json 内容不一致
- 本地：没有提交历史（避免循环提交）
- CI：有完整提交历史
- 导致每次同步都会改变文件

## 解决方案

### 方案1：分离静态和动态数据（推荐）
将统计数据分为两部分：
1. `stats-static.json` - 只包含文档数量等静态信息（本地生成）
2. `stats-dynamic.json` - 包含提交历史和贡献者信息（CI 生成）

优点：
- 避免循环提交
- 本地可以更新静态统计
- CI 负责更新动态数据

实现：
- 修改 generate-stats.js 生成两个文件
- 修改 StatsPage.vue 合并两个数据源
- .gitignore 忽略 stats-dynamic.json

### 方案2：完全由 CI 生成
- 本地不生成 stats.json
- 仅在 CI 环境生成
- .gitignore 忽略本地的 stats.json

优点：
- 简单直接
- 避免冲突

缺点：
- 本地开发时看不到统计信息

### 方案3：使用 GitHub API 动态获取
- 不生成静态文件
- 前端直接调用 GitHub API 获取提交历史
- 使用 GitHub GraphQL API 获取贡献者信息

优点：
- 数据实时
- 无需生成文件

缺点：
- 需要处理 API 限流
- 可能需要认证

## 推荐实施方案1

分离数据，让本地和 CI 各司其职。