# JS 构建压缩方案

## 背景

项目使用 browserify 将 `src/` 下的 JS 源码打包为 `main.js` 和 `game.js`，之前未启用 uglifyjs 压缩，生产环境 `game.js` 体积约 28.7MB，传输和加载效率低，可能引发 game.js 下载超时、失败等情况。

本次修改在三套构建脚本中合理配置 browserify + uglifyjs 组合，在保证运行安全的前提下减小产物体积。

## 工具链版本

| 工具 | 版本 | 用途 |
|------|------|------|
| browserify | 11.2.0 | CommonJS 模块打包 |
| uglify-js | 2.8.29 | JS 压缩混淆 |
| Node.js | v24.x | 运行环境 |

## browserify 基础知识

### 是什么

browserify 是一个 JS 模块打包工具，让浏览器端可以使用 Node.js 的 `require()` 语法。它从入口文件出发，递归解析所有 `require()` 依赖，将数百个源文件和 npm 包合并为单个 JS 文件。

### 工作原理

```
src/main.js                    ┐
  require("./slot/model/SlotMan")     │
  require("./common/net/PomeloClient")│  → browserify →  game.js (单文件)
  require("numeral")                  │
  require("dateformat")               │
  ...（6000+ 模块）                    ┘
```

每个模块被包裹在一个函数中，通过模块 ID 互相引用：

```js
// browserify 输出结构（简化）
(function(){
  function r(e,n,t){ /* 模块加载器 */ }
  return r
})()({
  1: [function(require,module,exports){
    // src/main.js 的内容
  }, {"./slot/model/SlotMan": 2, "numeral": 3}],
  2: [function(require,module,exports){
    // SlotMan.js 的内容
  }, {}],
  // ... 所有模块
})
```

### 常用参数

| 参数 | 说明 | 本项目用途 |
|------|------|-----------|
| `browserify entry.js` | 从入口文件打包，输出到 stdout | debug/生产构建 |
| `browserify -d entry.js` | 打包并在末尾注入 inline source map（base64 编码） | 本地开发调试 |
| `browserify --debug` | 等同 `-d` | - |

### Source Map 说明

`-d` 标志会在输出文件末尾附加一段 base64 编码的 source map：

```js
// ... 打包后的代码 ...
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjoz...
```

source map 包含：
- **sources**：所有原始源文件路径（如 `src/slot/model/SlotMan.js`）
- **sourcesContent**：每个源文件的完整原始代码（体积大的主因）
- **mappings**：打包后代码位置 ↔ 原始文件行列号的映射

浏览器 DevTools 检测到此注释后会解析 source map，调试时展示原始文件而非打包文件。**source map 仅在打开 DevTools 时加载，不影响运行时行为。**

本项目中 source map 约占 `-d` 输出体积的 60%（`game.js` 95MB 中有 57MB 是 source map）。

## uglifyjs 基础知识

### 是什么

uglifyjs 是一个 JS 代码压缩/混淆工具，通过解析代码的 AST（抽象语法树）进行等价变换来减小文件体积。

### 三个核心功能

uglifyjs 提供三类独立的代码变换，可以单独或组合使用：

#### 1. `-b` (beautify) — 美化输出

格式化代码的缩进和换行，不改变逻辑。`-b "indent-level=0"` 去除所有缩进但保留换行和变量名。

```js
// 输入
function foo(a,b){var c=a+b;return c}
// -b 输出
function foo(a, b) {
    var c = a + b;
    return c;
}
// -b "indent-level=0" 输出
function foo(a, b) {
var c = a + b;
return c;
}
```

注意：`-b` 是"反压缩"，**不应与 `-c`/`-m` 同时使用**。

#### 2. `-c` (compress) — 代码压缩

对 AST 进行等价变换以减小代码体积。包含多个子选项，可通过 `-c "opt1=val1,opt2=val2"` 逐项控制。

**默认开启的压缩子选项：**

| 子选项 | 默认 | 作用 | 示例 |
|--------|------|------|------|
| `dead_code` | true | 删除不可达代码 | `return x; foo();` → `return x;` |
| `conditionals` | true | 简化条件表达式 | `if(true) A; else B;` → `A;` |
| `evaluate` | true | 计算常量表达式 | `1+2` → `3`，`"ab"+"cd"` → `"abcd"` |
| `booleans` | true | 简化布尔表达式 | `!!x` → `x`，`!0` → `true` |
| `loops` | true | 优化循环 | `while(true)` → `for(;;)` |
| `if_return` | true | 优化 if/return | `if(a) return b; return c;` → `return a?b:c;` |
| `join_vars` | true | 合并声明 | `var a=1; var b=2;` → `var a=1,b=2;` |
| `sequences` | true | 合并为逗号表达式 | `a=1; b=2;` → `a=1,b=2;` |
| `cascade` | true | 合并连续赋值 | `a=1; return a;` → `return a=1;` |
| `properties` | true | 点号与括号互换 | `a["b"]` → `a.b` |
| `drop_debugger` | true | 删除 `debugger` 语句 | `debugger;` → (删除) |
| `comparisons` | true | 优化比较 | `!(a>b)` → `a<=b` |

**需要特别注意的子选项：**

| 子选项 | 默认 | 风险 | 说明 |
|--------|------|------|------|
| `unused` | true | **高** | 删除未使用的变量/函数。可能误删有副作用的 `require()` 调用 |
| `collapse_vars` | true | **中** | 将单次使用的变量内联。可能改变有副作用代码的求值顺序 |
| `unsafe` | false | **高** | 启用可能改变语义的优化（如假设 `Math.floor` 未被重写）|
| `pure_getters` | false | **中** | 假设属性访问无副作用（如 getter）|
| `drop_console` | false | **低** | 删除所有 `console.*` 调用 |
| `global_defs` | {} | **低** | 全局常量替换，如 `{"DEBUG": false}` 可消除 debug 代码 |

#### 3. `-m` (mangle) — 变量名混淆

将局部变量和函数参数缩短为 `a`、`b`、`c` 等短名称。不改变逻辑，仅影响可读性。

```js
// 输入
function calculateWinnings(betAmount, multiplier) {
    var totalWin = betAmount * multiplier;
    return totalWin;
}
// -m 输出
function calculateWinnings(n, t) {
    var r = n * t;
    return r;
}
```

注意：`-m` 只缩短局部作用域内的名称。全局变量、对象属性名、字符串不会被改变。

### 参数组合速查

| 命令 | 效果 | 适用场景 |
|------|------|---------|
| `uglifyjs -b "indent-level=0"` | 仅去缩进，不压缩 | 历史遗留用法（本项目旧方案） |
| `uglifyjs -c` | 仅压缩，保留变量名 | 需要可读性时 |
| `uglifyjs -m` | 仅混淆变量名，不压缩逻辑 | 轻度混淆 |
| `uglifyjs -c -m` | 压缩 + 混淆（最大压缩比） | 生产环境 |
| `uglifyjs -c "unused=false"` | 安全压缩（不删未使用变量） | 有副作用 require 的项目 |
| `uglifyjs -c "unused=false,collapse_vars=false" -m` | 安全压缩 + 混淆 | **本项目生产方案** |

## 三套构建脚本对比

| 脚本 | 用途 | browserify | uglifyjs | 产物特征 |
|------|------|-----------|----------|---------|
| `build_local_alpha.sh` | 本地开发调试 | `browserify -d`（含 inline source map） | 不使用 | 未压缩，DevTools 可直接调试原始源码 |
| `build_fb_alpha.sh` | 内部 debug 发布 | `browserify`（无 source map） | `-c "unused=false,collapse_vars=false"` | 压缩但不混淆变量名，便于线上问题定位 |
| `build_fb.sh` | 生产环境发布 | `browserify`（无 source map） | `-c "unused=false,collapse_vars=false" -m` | 压缩 + 变量名混淆，体积最小 |

### 设计原则

1. **fb_alpha 与 fb 的 JS 构建流程保持一致**（相同的 browserify 参数、相同的 uglifyjs 压缩参数），仅 fb 额外启用 `-m`（mangle 变量混淆），确保 debug 环境能真实复现生产问题
2. **本地开发不压缩**，优先构建速度和调试体验
3. `build_local_alpha.sh` 中通过注释保留了模拟 debug 环境和模拟生产环境的构建命令，方便开发者本地切换验证

## uglifyjs 压缩安全性说明

### 启用的安全选项

```sh
uglifyjs -c "unused=false,collapse_vars=false"
```

| 选项 | 值 | 含义 |
|------|-----|------|
| `unused` | `false` | **禁止**删除未使用的变量和函数 |
| `collapse_vars` | `false` | **禁止**将变量内联到使用处 |

### 为什么关闭 `unused`

项目大量使用 `var XXX = require("./XXX")` 加载模块。部分模块的加载仅为了触发副作用（注册协议、注册工厂类等），返回值存入的变量从未被直接使用。如果 `unused=true`，uglifyjs 可能误删这些 `require` 调用，导致运行时功能缺失。

### 为什么关闭 `collapse_vars`

`collapse_vars` 会将单次使用的变量直接替换为其赋值表达式。在存在副作用的代码中（如函数调用返回值），这可能改变求值顺序，引入难以排查的 bug。

### 仍然生效的默认压缩项

以下优化仍然启用，对代码逻辑无影响：

| 优化项 | 作用 | 安全性 |
|-------|------|--------|
| `dead_code` | 删除 `return`/`throw` 后的不可达代码 | 安全，代码永远不会执行 |
| `conditionals` | 简化条件表达式，如 `if(true) A else B` → `A` | 安全 |
| `evaluate` | 常量折叠，如 `1+2` → `3` | 安全 |
| `join_vars` | 合并连续 `var` 声明 | 安全 |
| `if_return` | 简化 `if/return` 模式 | 安全 |
| `sequences` | 合并连续简单语句为逗号表达式 | 安全 |

### 构建警告说明

uglifyjs 压缩时会输出大量 `WARN` 信息，均为安全操作：

| 警告类型 | 含义 | 是否影响运行 |
|---------|------|-------------|
| `Dropping unreachable code` | 删除 return/throw 后的代码 | 不影响 |
| `Declarations in unreachable code` | 死代码中有 var 声明 | 不影响（var 提升仅声明不赋值） |
| `Condition always true/false` | 静态分析确定条件恒真/恒假 | 不影响（保留必然执行的分支） |
| `Non-strict equality against boolean` | 使用 `== true` / `== false` | 不影响（仅风格提示，不改行为） |
| `Dropping side-effect-free statement` | 删除无副作用的表达式语句 | 不影响 |

## 体积对比（以 res_oldvegas/game.js 为例）

| 阶段 | 体积 | 说明 |
|------|------|------|
| browserify 原始输出 | ~28.7 MB | 未压缩代码 |
| browserify -d 输出 | ~95 MB | 含 ~57MB inline source map |
| uglifyjs -c（仅压缩） | ~25.9 MB | 压缩，不混淆 |
| uglifyjs -c -m（压缩+混淆） | ~20 MB | 压缩 + 变量名缩短 |

## 已知限制

1. **uglifyjs 2.x 与 Node.js v24 的 source map 兼容性问题**：uglifyjs 2.x 的 `--source-map` 和 `--in-source-map` 选项在 Node.js v24 下会报 `ERR_INVALID_ARG_TYPE` 错误（`writeFileSync` 收到 Object 而非 String）。因此当前构建不使用 uglifyjs 的 source map 功能。如需压缩后的 source map，需升级至 uglifyjs v3 或 terser。

2. **browserify `-d` 标志会注入 inline source map**：约占输出文件 60% 的体积。仅用于本地开发，不可用于 debug/生产构建。

## 测试注意事项

本次变更启用了 JS 代码压缩，game.js 的代码内容经过等价变换（缩短变量名、简化表达式、删除死代码），逻辑与压缩前完全一致，但需要针对性验证以确保无遗漏。

### 测试范围（覆盖日常测试 + Smoke 测试，无具体测试要点）
比如：
1. **基础功能验证**
   - 游戏正常加载，无白屏或 JS 报错
   - 大厅场景正常渲染，关卡列表可滑动点击
   - 进入任意关卡房间，spin 功能正常
   - ......

2. **关卡玩法流程**
   - 普通 spin、auto spin、fast spin
   - Free Spin 触发、进行、结算
   - Bonus Game 触发和交互（Pick Game、Link Game 等）
   - 断线重连后状态恢复等
   - ......

3. **登录、支付**
   - FB、Apple 等登录流程
   - 支付流程
   - ......

4. **跨模块功能**
   - 活动入口和活动内交互
   - 社交功能（好友列表、排行榜）
   - ......

5. **其他功能**
   - ......

### 如何判断压缩导致的问题

如果测试中遇到功能异常，可通过以下方式排查是否由压缩引起：

1. 使用 `build_local_alpha.sh`（不压缩）构建同一版本
2. 对比压缩版和未压缩版是否都存在该问题
3. 如果仅压缩版出现问题，报告时注明"疑似压缩引起"，并附上浏览器控制台的错误信息

## 修改记录

- 2026-02-27：启用 uglifyjs 安全压缩，配置三套构建脚本差异化策略
