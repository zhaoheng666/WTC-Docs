---
title: Istanbul
---

# Istanbul

> 源自飞书文档 · 最后同步：2026-09-10

Istanbul 是 JavaScript 生态里最常用的一套代码覆盖率插桩与统计标准。它不负责理解老虎机玩法，而是回答很机械、但很可靠的问题：某段代码、某个函数、某个分支臂，在本次运行中到底有没有执行过、执行了多少次。

它的工作方式可以理解为把测试版代码改写一遍。原代码：

```javascript
function settle(win) {
  if (win > 0) return win;
  return 0;
}
```

Istanbul 插桩后的概念效果大致是：

```javascript
function settle(win) {
  coverage.f[0]++; // 函数命中

  if (win > 0) {
    coverage.b[0][0]++; // if 为真
    coverage.s[0]++;    // return win 语句
    return win;
  }

  coverage.b[0][1]++; // if 为假
  coverage.s[1]++;    // return 0 语句
  return 0;
}
```

运行时这些计数保存在浏览器端的覆盖对象中，随后上传给本地服务。Istanbul 同时保存“计数编号对应原始源码哪一行、哪个分支”的映射，因此看板能显示原始源码，而不是插桩后的代码。

它定义了四个标准指标：

- 语句覆盖（statement）：每条语句是否执行。
- 函数覆盖（function）：每个函数是否被调用。
- 分支覆盖（branch）：每条分支臂是否命中。
- 行覆盖（line）：由语句位置与计数按 Istanbul 规则汇总。
尤其要注意：分支覆盖率按“分支臂”算，不是按“分支点”算。例如：

```javascript
if (isFreeSpin) {
  startFreeSpin();
} else {
  startNormalSpin();
}
```

只跑过 FreeSpin 时：

- if 分支点已到达；
- 真分支命中；
- 假分支未命中；
- 分支覆盖率是 1 / 2 = 50%，不是 100%。
在我们当前工具中，Istanbul 有两个角色：

1. 静态提取阶段先用它为所有选定源码生成固定的 statementMap、fnMap、branchMap 和零计数。这决定覆盖率分母，未加载的文件仍然是零覆盖，而不会被分母忽略（实现位于分析器的 coverage.js）。
1. 构建录制版游戏时，对实际运行的 Browserify 源码插入同一套标准计数。计数再按关卡、会话、用例、Spin 上下文归属，避免公共模块在错误的关卡统计中“蹭覆盖”。
它和我们的轨迹探针分工不同：Istanbul 给出稳定、可比较的“代码命中事实”，轨迹探针补充“这些命中在关卡流程中意味着什么”。

最后一个边界很重要：Istanbul 的高覆盖率不代表玩法全测完。它不能证明所有路径组合都覆盖了，也不能证明 MC/DC、服务端判奖、异步时序或视觉表现正确。

CFG、Istanbul 与轨迹如何协作、各自边界见 [《CFG、Istanbul 与运行轨迹：证据模型》](https://ghoststudio.feishu.cn/wiki/UHnAwYdL3irXiCkKQrWc4680nwc)。
