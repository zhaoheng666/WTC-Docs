# Spine 更新与 AppVersion 关联

> 本文梳理 `getAppVersion()` 中与 Spine 骨骼动画相关的版本标记，并把它们关联到
> cocos2d-x、cocos2d-html5、libZenSDK、主仓库四个仓库的真实提交记录，
> 作为后续排查「Spine 是哪个版本 / 什么时候改的」的可追溯依据。

**整理时间**: 2026-06-04

---

## 背景

Native 版本号定义在主仓库的 `getAppVersion()` 方法中（每次出包递增），方法体里保留了
全部历史记录，每条 `//return XXXXXX;` 注释代表一次 native 更新。

- 文件（当前路径）：`libZenSDK/js-bindings/bindings/manual/LogicHelper.cpp`
- 文件（迁移前旧路径）：`frameworks/runtime-src/Classes/jsb/manual/LogicHelper.cpp`

⚠️ **追溯陷阱**：libZenSDK 中这份文件的 `git blame` 全部指向 2019-11-19 的一次
「native 代码从 app 层移到 libzensdk」提交（`6c435a73f2`），这是一次性历史导入，
**不代表真实变更时间**。版本号的真实设定时间需回溯主仓库旧路径的提交历史。

---

## getAppVersion 中的 Spine 标记

历史记录里**直接点名 Spine** 的只有两条：

| AppVersion | 代码注释 |
| ---------- | ----------------------- |
| `100014`   | `// dbh ios 接入spine 3.6` |
| `100024`   | `// DBH 修复spine析构时崩溃` |

---

## 关联关系

### 100014「接入 Spine 3.6」

| 仓库 | Commit | 时间 | 提交信息 |
| --- | --- | --- | --- |
| 主仓库（版本锚点） | `14ae89d693` | 2018-11-14 | `* client version 设置为100014` |
| cocos2d-x（C++ 运行时） | `86b8911377` | 2018-10-16 | update spine runtime to 2.5 && works with data exported from **Spine 3.6.xx** |
| cocos2d-x（编译修复） | `1d746d7245` | 2018-10-16 | spine 升级-安卓编译通过 |
| cocos2d-html5（JS 运行时） | `529766b4ea` | 2018-10-17 | update Spine runtime version **3.6.39** |
| libZenSDK | — | — | 无 Spine 内容 |

> 底层运行时在 2018-10-16/17 落地（cocos2d-x 的 C++ runtime 支持解析 Spine 3.6 导出数据 +
> cocos2d-html5 的 JS runtime 升到 3.6.39），主仓库在 2018-11-14 总装出包并设定版本号 `100014`。

### 100024「修复 Spine 析构崩溃」

| 仓库 | Commit | 时间 | 提交信息 |
| --- | --- | --- | --- |
| 主仓库（版本锚点） | `0df4961091` | 2019-04-25 14:59 | `!!! DBH ios 1.4.8/1.4.8 100024`（Info.plist 1.4.7→1.4.8） |
| 主仓库（前置修复） | `e73617f0c0` | 2019-04-25 14:07 | ^修复spine导致的崩溃 |
| cocos2d-x（实际修复点） | `df5c8665ca` | 2019-04-25 13:50 | 修复 spine 的 **spTrack 缓存机制**，在杀掉游戏的时候导致的崩溃 |
| libZenSDK | — | — | 无 Spine 内容 |

> 同一天链路清晰：cocos2d-x 在 `jsb_cocos2dx_spine_manual.cpp` 修复 spTrack 缓存（13:50）
> → 主仓库前置修复（14:07）→ 主仓库设定版本号 `100024` 并把 iOS 版本升到 1.4.8（14:59）。

---

## 未挂版本号的其他 Spine 更新

这些 Spine 改动**未在 `getAppVersion()` 中单独贴标签**（可能并入其他版本号或属纯前端热更），
但属于 Spine 演进的一部分：

| 仓库 | Commit | 时间 | 内容 |
| --- | --- | --- | --- |
| cocos2d-x | `f1f2b9eebc` | 2019-02-02 | 修复 Spine Runtime Clipping bug |
| cocos2d-x | `2ba6802633` | 2019-02-18 | 修复 SPINE RUNTIME 第一帧播放错误 |
| cocos2d-x | `c85dc94876` | 2020-03-13 | 更新 spine runtime 到 **3.8**（C→C++ 重构） |
| cocos2d-x | `27f43add79` | 2020-04-15 | 修复游戏内重启 spine 内存泄露/掉帧 |
| cocos2d-html5 | `00b44a1ded` | 2020-03-13 | spine runtime 3.8 |
| cocos2d-html5 | `1065134c9e` | 2020-09-08 | **Revert** "spine runtime 3.8"（回退到 3.6） |
| cocos2d-html5 | `dabfbf5e79` | 2019-10-14 | 修复 spine 复杂 clip 顶点过多导致合批/OpenGL 报错 |
| cocos2d-html5 | `071c3ce401` | 2019-02-28 | Spine WebGL support Clipping Node |
| cocos2d-html5 | `c185fabd6f` | 2018-11-07 | spine canvas mesh support |
| 主仓库 | `0fdb1f2284` | 2019-10-14 | 更新 cocos2d-html5 修复 spine 渲染报错 |

> **3.8 升级未成功落地**：cocos2d-x 和 cocos2d-html5 都在 2020-03-13 升到 3.8，
> 但 cocos2d-html5 在 2020-09-08 又 Revert 回 3.6。因此项目目前 Spine 仍稳定在
> **3.6.39**（cocos2d-html5）/ runtime 2.5 + 3.6 数据格式（cocos2d-x），与 `100014` 标记一致。

---

## 四仓库职责

| 仓库 | 是否含 Spine | 角色 |
| --- | --- | --- |
| `frameworks/cocos2d-x` | 有，`cocos/editor-support/spine/` | C++ spine runtime + JSB 绑定（接入/崩溃修复/版本升级的**实际代码**） |
| `frameworks/cocos2d-html5` | 有，`extensions/spine/`（`Spine.js` = 3.6.39） | 纯 JS spine runtime（Web/H5 渲染） |
| 主仓库 WorldTourCasino | 版本锚点 | `LogicHelper.cpp` 设定 AppVersion + 大量关卡 `useSpine` 配置 |
| `libZenSDK` | 无 | 广告/支付/数据 SDK，与 Spine 无关 |

---

## 结论

1. 两个 Spine 版本锚点都成立且可追溯：`100014`（接入 3.6，2018-11-14）、
   `100024`（修复析构崩溃，2019-04-25），底层提交均可在 cocos2d-x / cocos2d-html5 找到对应实现。
2. Spine 真正的代码在 **cocos2d-x 和 cocos2d-html5**，libZenSDK 完全不涉及 Spine。
3. 当前 Spine 版本停留在 **3.6**（3.8 升级被回退），与 `getAppVersion()` 中无新增 Spine 标记相互印证。
