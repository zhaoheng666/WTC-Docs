# Code Review 规则定义

本文件是 code-review skill 的规则权威来源。

## 规则分类说明

| 风险等级 | 标记 | 触发行为 |
|---------|------|---------|
| 高风险 | 🔴 | 必触发 review + 深度分析 + 二次确认 |
| 中风险 | 🟡 | 触发 review + 关注 |
| 低风险 | 🟢 | 提示/警告 |

---

## 1. 高风险 API

检测到以下 API 时，**必须深度分析 + 二次确认**。

| API | 检测模式 | 风险说明 | 分析要点 |
|-----|---------|---------|---------|
| removeFromParent | `removeFromParent` | cleanup 默认 true，立即清理节点 | 检查参数、同帧引用、延迟回调 |
| removeChild | `removeChild(` | 同上 | 检查参数、同帧引用 |
| removeChildByTag | `removeChildByTag` | 同上 | 检查参数、同帧引用 |
| removeAllChildren | `removeAllChildren` | 批量移除，影响范围大 | 检查子节点引用 |
| removeAllChildrenWithCleanup | `removeAllChildrenWithCleanup` | 显式清理 | 确认是否预期 |
| release | `.release(` | 手动释放引用计数，可能野指针 | 确认 retain/release 配对 |
| cleanup | `.cleanup(` | 手动清理 | 确认时机正确 |
| setSearchPaths | `setSearchPaths` | 设置资源搜索路径，影响资源加载优先级 | 必须用 unshift 添加到头部，确保热更资源优先 |

### 深度分析模板

检测到高风险 API 时，按以下步骤分析：

1. **参数检查**：是否显式传递了 cleanup 参数？
2. **同帧引用**：移除后是否还有代码访问该节点？
3. **循环安全**：是否在循环中移除正在遍历的元素？
4. **延迟回调**：是否有 scheduleOnce/runAction 回调持有引用？
5. **无法判断**：加入二次确认清单

---

## 2. 高风险路径

修改以下路径时，**必须触发 review + 二次确认**。

| 路径模式 | 风险说明 | 确认事项 |
|---------|---------|---------|
| `frameworks/cocos2d-html5/` | 引擎底层（渲染） | 是否必要？影响范围？ |
| `frameworks/cocos2d-x/` | 引擎底层（原生） | 是否必要？影响范围？ |
| `src/common/` | 公共模块 | 所有模块是否兼容？ |
| `src/gameCommon.js` | 游戏初始化核心 | 初始化顺序是否正确？ |
| `src/main.js` | 入口文件 | 启动流程是否正确？ |
| `src/*/protocol/` | 前后端协议 | 服务端是否已同步？ |
| `**/C2S*.js` | 客户端请求协议 | 服务端是否已同步？ |
| `**/S2C*.js` | 服务端响应协议 | 服务端是否已同步？ |
| `src/social/controller/card_system/` | CardSystem 核心 | 收集系统逻辑是否正确？ |
| `src/slot/controller/` | 关卡控制器 | 影响所有关卡？ |
| `src/vip/` | VIP 特权 | VIP 逻辑是否正确？ |
| `src/store/` | 支付相关 | 支付流程是否正确？ |
| `src/task/model/ActivityMan.js` | 活动管理器 | 影响所有活动？ |

---

## 3. 中风险 API

检测到以下 API 时，**触发 review + 关注**。

| API | 检测模式 | 风险说明 | 分析要点 |
|-----|---------|---------|---------|
| retain | `.retain(` | 手动增加引用计数 | 是否有对应 release |
| unschedule | `unschedule` | 取消定时器 | 确认取消正确 |
| unscheduleAllCallbacks | `unscheduleAllCallbacks` | 取消所有定时器 | 确认范围正确 |
| stopAllActions | `stopAllActions` | 停止所有动作 | 确认范围正确 |
| isActivityVisible | `isActivityVisible(` | 仅 BaseActivity 有此方法，直接继承 Activity 的子类（如 JackpotFeverActivity、HighRollerActivity）没有此方法 | 确认调用方是否来自 forEachActivites 等全量遍历；若是，需加 typeof 保护：`typeof activity.isActivityVisible === 'function'` |

---

## 4. 中风险路径

修改以下路径时，**触发 review**。

| 路径模式 | 风险说明 | 确认事项 |
|---------|---------|---------|
| `src/slot/model/` | 关卡数据模型 | 数据结构是否兼容？ |
| `src/social/model/` | 社交数据模型 | 数据结构是否兼容？ |
| `src/task/model/` | 任务数据模型 | 数据结构是否兼容？ |
| `src/newdesign_slot/` | 新版关卡系统 | 新关卡是否正常？ |
| `**/ActivityConfig.json` | 活动配置 | 是否需要热更？ |
| `**/ActivityConfig.js` | 活动配置解析 | 配置解析是否正确？ |
| `resource_dirs.json` | 资源版本控制 | 资源版本是否正确？ |

---

## 5. 代码质量规则

| 规则 | 检测模式 | 风险等级 | 说明 | 处理方式 |
|-----|---------|---------|------|---------|
| ES6 const | `const ` | 🔴 高 | 主项目禁止 ES6 | 阻断提交 |
| ES6 let | `let ` | 🔴 高 | 主项目禁止 ES6 | 阻断提交 |
| 箭头函数 | `=>` | 🔴 高 | 主项目禁止 ES6 | 阻断提交 |
| debugger | `debugger` | 🔴 高 | 调试断点 | 阻断提交 |
| console.log | `console.log` | 🟡 中 | 调试代码 | 警告，建议移除 |
| TODO/FIXME | `TODO`, `FIXME` | 🟢 低 | 待处理标记 | 提示 |

---

## 6. 业务敏感关键词

涉及以下关键词时，**触发 review + 业务确认**。

| 关键词 | 风险等级 | 说明 | 确认事项 |
|-------|---------|------|---------|
| `reward`, `Reward` | 🔴 高 | 奖励逻辑 | 策划是否确认？ |
| `coin`, `Coin` | 🔴 高 | 金币相关 | 数值是否正确？ |
| `gem`, `Gem` | 🔴 高 | 宝石相关 | 数值是否正确？ |
| `bet`, `Bet` | 🔴 高 | 下注相关 | 数值是否正确？ |
| `vip`, `VIP` | 🔴 高 | VIP 特权 | VIP 逻辑是否正确？ |
| `pay`, `Pay`, `purchase`, `Purchase` | 🔴 高 | 支付相关 | 支付流程是否正确？ |
| `rate`, `probability`, `random` | 🔴 高 | 概率相关 | 随机逻辑是否正确？ |
| `LeaderBoard`, `rank` | 🟡 中 | 排行榜 | 排名逻辑是否正确？ |
| `startTime`, `endTime`, `duration` | 🟡 中 | 活动时间 | 时间是否正确？ |

---

## 7. 变更规模阈值

| 指标 | 阈值 | 风险等级 | 说明 |
|-----|------|---------|------|
| 修改文件数 | ≥ 5 | 🔴 高 | 影响范围广 |
| 新增/删除行数 | ≥ 200 | 🔴 高 | 大量代码变更 |
| 跨模块数 | ≥ 3 | 🟡 中 | 影响多个模块 |
| 删除占比 | > 50% | 🟡 中 | 可能破坏依赖 |
| 新增文件数 | ≥ 3 | 🟡 中 | 新增功能 |

---

## 8. 语法校验（强制 · eslint ES5 解析）

grep 规则（第 5 节）只能匹配**固定文本模式**，无法发现**语法级错误**。典型漏网案例：**函数调用的尾逗号** `f(a,)` —— ES2017 合法、ES5 非法；browserify（acorn 高版本）构建时容忍不报错，现代运行时（JSC/V8）也容忍，但违反项目 ES5 强制规范，老引擎会 `SyntaxError`。

**唯一能拦下此类问题的是 ES5 解析器**（项目 `.eslintrc` 已配 `ecmaVersion:5`）。因此 code-review **必须对本次改动的 JS 文件跑一次 eslint**：

```bash
# 仅校验本次改动（含未跟踪）的 src JS，命中语法错误即阻断提交
{ git diff --name-only HEAD -- 'src/**/*.js'; git ls-files --others --exclude-standard -- 'src/**/*.js'; } | sort -u | xargs -r npx eslint
```

| 检测方式 | 能否发现尾逗号等语法错误 | 用途 |
|---------|:---:|------|
| grep 规则匹配（第 5 节） | ❌ | 只匹配固定模式（const/let/=>/debugger 等） |
| browserify 构建 | ❌ | 语法宽容，可解析即通过，"无 error/warning" |
| **eslint（ecmaVersion:5）** | ✅ | **ES5 语法级校验，本节强制执行** |

**处理方式**：

- eslint 报 `Parsing error` → 🔴 **阻断提交**（ES5 语法违规）
- eslint 报 error（规则级，如 `no-undef`）→ 🟡 关注并在报告中列出
- eslint 报 warning → 🟢 提示

---

## 跳过 Review 条件

满足以下任一条件可跳过深度 review：

- 仅构建产物变更（`res_*/flavor/`、`resource_list/`）
- 单文件小改动（< 50 行）
- 纯文档/注释修改
- 仅资源文件变更（图片、音频等）
- 用户明确说"跳过 review"

---

## 更新记录

| 日期 | 变更 | 操作人 |
|-----|------|-------|
| 2026-07-20 | 新增第 8 节「语法校验（强制 · eslint ES5）」：grep 与 browserify 均无法发现函数调用尾逗号等 ES5 语法错误，强制对改动 JS 跑 eslint | AI |
| 2026-04-28 | 新增 isActivityVisible 中风险 API（BaseActivity 专属方法，全量遍历时需 typeof 保护） | AI |
| 2025-01-19 | 新增 setSearchPaths 高风险 API | AI |
| 2025-01-19 | 初始版本，从 SKILL.md 提取规则 | AI |

---

## 如何更新规则

1. 在对应表格中添加新行
2. 同步更新 `.claude/skills/code-review/SKILL.md` 的快速引用
3. 在更新记录中添加条目
