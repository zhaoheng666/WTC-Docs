# Code Review 规则定义

本文件是 code-review skill 的规则权威来源。

## 执行时机与职责

- code-review 是任务收口活动，必须在最后一次实质性修改之后、宣布任务完成或进入等待提交之前执行，并审查当前任务准备交付的累计变更。
- 审查范围必须以本次改动的实际影响为边界；局部检查足以证明正确性时不得无依据扩张为全量审查或回归。
- 审查发现阻断问题并产生实质性修复后，必须在改动面重新稳定时复查 finding 相关内容与累计变更；只有影响扩散证据成立时才扩大范围。
- 收口结论只在待提交范围没有发生实质变化时保持有效。Git 提交只复用该结论，不自动启动 code-review，也不执行提交后例行复审。
- 无法确认必要收口已经完成时，必须在改变 Git 状态前报告缺失条件；不得把实施、广泛审查或测试静默推迟到提交流程中补做。

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

## 7. 变更规模与影响信号

文件数、行数和删除占比只用于帮助定位变更，不得单独决定风险等级、深度审查或测试范围。审查者必须结合行为、权威契约、共享边界、失败模式和回退能力判断实际影响。

| 信号 | 审查关注 |
|-----|---------|
| 修改共享 Runtime、公共接口或跨模块契约 | 下游兼容、状态 owner、失败传播和受影响回归 |
| 修改权威规范、生成契约或验收语义 | 消费入口是否一致、历史契约是否保持、是否需要独立 verdict |
| 删除、迁移或批量重写 | 引用完整性、回退边界和数据/资源可恢复性 |
| 同时触及多个具有共同交付面的文件 | 作为一个累计 diff 审查，不按文件数量拆分 |
| 纯文档或配置修改 | 判断是否改变权威规则、运行配置或外部契约；“非代码”本身不是低风险证明 |

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

## 9. OpenSpec 校验与归档提醒

code-review 在任务收口时**每次必须**执行：

```bash
npm run --silent list:openspec
```

- active change 集合和任务进度以该命令返回的官方 `openspec list --json` 结构化结果为权威来源。
- active change 任务达到 100% 后，在 review 回复中使用独立标题和 change ID 显著提醒归档。
- 没有匹配项时保持静默，不输出 OpenSpec 提醒标题、空列表或“检查通过”信息。
- 归档提醒不阻断当前 review 或提交，不要求当前协作者处理无关 change。
- 跳过深度 review 不会跳过归档提醒。
- 涉及 `openspec/` 时另外运行 `npm run check:openspec`；语言检查或 strict validation 失败时阻断提交。

---

## 跳过 Review 条件

只有实际影响已经证明为局部且不存在行为、权威契约、共享边界或安全风险时，才可缩小或跳过可选的深度 review，例如纯排版修正或来源明确的派生构建产物。文件/行数、文件类型或“纯文档”不得单独作为跳过依据。

用户明确要求跳过 review 时停止可选深度分析；项目、Change、安全或权限规定的不可绕过门禁仍保留并说明原因。

---

## 更新记录

| 日期 | 变更 | 操作人 |
|-----|------|-------|
| 2026-09-02 | 将 code-review 定位为最后一次实质修改后的任务收口，以定性影响信号替代机械规模阈值，提交只复用有效结论且不再自动审查或提交后复审 | WorldTourCasino Team |
| 2026-08-31 | 统一使用存在的 `npm run list:openspec`，删除失效命令与 fallback | WorldTourCasino Team |
| 2026-08-13 | 将完成态 active change 从全局阻断调整为 review/commit 回复中的非阻断归档提醒 | WorldTourCasino Team |
| 2026-08-12 | 新增第 9 节「OpenSpec 交付与语言门禁」：强制检查中文人读内容、机器 ID、完成态和严格校验 | WorldTourCasino Team |
| 2026-07-20 | 新增第 8 节「语法校验（强制 · eslint ES5）」：grep 与 browserify 均无法发现函数调用尾逗号等 ES5 语法错误，强制对改动 JS 跑 eslint | AI |
| 2026-04-28 | 新增 isActivityVisible 中风险 API（BaseActivity 专属方法，全量遍历时需 typeof 保护） | AI |
| 2025-01-19 | 新增 setSearchPaths 高风险 API | AI |
| 2025-01-19 | 初始版本，从 SKILL.md 提取规则 | AI |

---

## 如何更新规则

1. 在对应表格中添加新行
2. 同步更新 `.claude/skills/code-review/SKILL.md` 的快速引用
3. 在更新记录中添加条目
