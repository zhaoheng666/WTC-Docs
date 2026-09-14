---
title: CFG
---

# CFG

> 源自飞书文档 · 最后同步：2026-09-10

**一个函数内部所有“可能执行路线”的路网图。**

AST 更像代码的语法目录，描述“谁包着谁”：

```
if (win > 0) {
  return win;
} else {
  return 0;
}
```

而 CFG 关心的是运行时会往哪里走：

> [全屏打开 ↗](/WTC-Docs/diagrams/03-settle-branch.archify.html){target="_blank"}

<iframe src="/WTC-Docs/diagrams/03-settle-branch.archify.html" style="width:100%;height:82vh;border:1px solid var(--vp-c-divider);border-radius:8px;" title="03-settle-branch"></iframe>

它把一个函数拆成若干控制节点，再用边表示下一步可能去哪里。比如：

- 普通顺序语句：`A → B → C`
- `if`：条件节点分成真、假两条边
- 循环：循环条件 → 循环体 → 回到循环条件；退出条件 → 后续代码
- `switch`：每个 `case`、`default` 和穿透关系
- `return`：直接连到函数出口
- `throw`：连到 `catch` 或异常出口
例如循环：

```
while (hasFreeSpin) {
  playFreeSpin();
}
showSettlement();
```

静态 CFG 大致是：

```
进入 → hasFreeSpin?
          ├─ 是 → playFreeSpin → 回到 hasFreeSpin?
          └─ 否 → showSettlement → 结束
```

这里的“简化”有两个意思。

第一，它描述的是**静态可能性**，不是某次真实运行的精确轨迹。它会画出真、假两条路，即使本次测试只跑了真分支；实际跑到哪一条由运行录制和 Istanbul 覆盖率标亮。

第二，它不会试图穷尽 JavaScript 的全部复杂语义。当前工具能处理顺序、条件、循环、`switch`、`try/catch`、`return`、`throw`、普通 `break/continue`；但动态调用、带标签跳转、`finally` 中复杂的提前退出、运行时拼出的回调目标等，不能可靠静态确定时会显示为“解析缺口”。

所以你可以这样区分：

- **AST**：代码长什么样、嵌套关系是什么。
- **CFG**：函数内可能怎么走。
- **调用图**：函数之间可能怎么互相调用。
- **运行轨迹**：这一次测试实际上怎么走。
- **覆盖率**：哪些路线或代码点至少走到过一次。
当前图谱把 CFG 作为“函数内部路线”，再和调用图、组件装配、状态读写、实际轨迹拼到一起，才形成关卡规格图。
