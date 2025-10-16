# Claude Code 模块化拆分+标注机制实验报告

## 📋 实验目的

  验证在 CLAUDE.md 中使用 [XX任务时-必读] 标注是否能让 Claude Code  
  在执行特定任务时自动读取对应规则文件。

---

## 🧪 实验设计

### 测试场景

- 任务: 提交项目（Git commit）
- 标注: [触发主项目提交任务时-必读] 指向两个规则文件

  - docs/工程-工具/ai-rules/shared/git-commit-types.md
  - docs/工程-工具/ai-rules/WTC/git-commits.md

### 预期行为

  Claude Code 应该：

1. 识别到"提交项目"任务
2. 读取 CLAUDE.md 发现标注
3. 自动调用 Read 工具读取两个规则文件
4. 按照规则执行提交

---

### 📊 实验结果

#### Claude Code 实际行为

  ✅ 执行了标准操作:  
  git status    # 查看工作区状态  
  git diff      # 查看未暂存更改  
  git diff --cached  # 查看已暂存更改  
  git log --oneline -10  # 学习提交风格

  ❌ 未读取规则文件:

- 没有调用 Read docs/工程-工具/ai-rules/shared/git-commit-types.md
- 没有调用 Read docs/工程-工具/ai-rules/WTC/git-commits.md

#### Claude Code 的决策逻辑

1. 依赖内置知识: 使用通用 Git 提交规范
2. 从历史学习: 分析 git log 输出推断风格  
    - 看到 fix:、refactor:、chore: → 推测用 Conventional Commits  
    - 看到中文描述 → 推测提交信息用中文  
    - 看到 cv:、^oldvegas: → 推测有项目特定前缀
3. 跳过规则文件: 认为从 git log 学习已"足够"

---

## 🎯 核心结论

### ❌ 标注机制无效

  [XX任务时-必读] 标注不起作用，原因：

1. 只是文本描述，非可执行指令  
    - Claude Code 不会解析标注并转换为工具调用  
    - 需要 AI 自己"意识到"并"决定"执行
2. AI 的优先级判断  
    - 内置知识 > 历史记录 > 规则文件  
    - 如果觉得"已有足够信息"就不会主动读取
3. 缺乏强制机制  
    - 没有系统级钩子拦截任务执行  
    - 完全依赖 AI 的"自觉性"

‍
