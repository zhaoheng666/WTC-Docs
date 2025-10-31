# Coupon 关卡 - 活动入口异常显示问题

## 基本信息

| 项目 | 内容 |
|------|------|
| **状态** | ✅ 已解决 |
| **类型** | 活动系统 / UI 挂载问题 |
| **修改文件** | `src/task/entity/BaseActivity.js` |
| **提交记录** | `a14673a008a` |
| **日期** | 2025-10-30 |
| **负责人** | 赵恒 |

---

## 问题描述

### 现象

在 Coupon 关卡中，活动入口显示异常，具体表现为：

- Coupon 关卡默认不创建活动中心（Activity Center）
- 但在某些情况下，活动入口仍会被创建并显示
- 导致 UI 层级混乱，活动入口无法正常交互

### 触发条件

**情况 1：后置资源未加载完成**
- 进游戏直接弹出免费旋转 Coupon
- 后置加载资源（活动资源）在进入关卡后才完成
- 资源加载完成触发活动刷新
- 活动刷新时尝试添加活动入口，但活动中心不存在

**情况 2：关卡中断线重连**
- Coupon 关卡运行中发生断线
- 重新连接时触发活动刷新
- 同样尝试添加活动入口，但活动中心不存在

### 复现步骤

1. 使用 fg coupon
2. 进入关卡前后置加载还未完成
3. 进入 coupon 关卡
4. 观察活动入口显示异常（或断线重连）

---

## 根本原因

### 问题点

在 `BaseActivity.mountSlotSceneExtraUI()` 方法中：

```javascript
// 修改前的代码存在以下问题：
// 1. 未验证 slotScene 是否有效
// 2. 未检查 centerWidget 是否存在
// 3. 直接尝试挂载 UI，导致异常
```

### 原因分析

1. **设计缺陷**：Coupon 关卡被标记为 `doNotUseCenterWidget = true`，明确不需要活动中心
2. **逻辑漏洞**：活动刷新时，代码未判定活动中心是否存在，仍然执行"添加活动入口"操作
3. **时序问题**：后置加载导致活动资源与关卡状态的加载时序不一致

### 相关代码

**文件**: `src/task/entity/BaseActivity.js`
**方法**: `mountSlotSceneExtraUI()` (第 226-252 行)

**问题代码位置**：
```javascript
// 第 226 行开始的 mountSlotSceneExtraUI 方法
// 未检查 slotScene 有效性
// 未检查 centerWidget 存在性
// 直接执行 UI 挂载逻辑
```

---

## 解决方案

### 修改内容

在 `BaseActivity.mountSlotSceneExtraUI()` 方法中添加两层验证：

#### 验证 1：slotScene 有效性检查（第 236 行）
```javascript
if (!cc.sys.isObjectValid(slotScene)) return;
```

**作用**：确保关卡场景对象有效，避免在无效场景上操作

#### 验证 2：centerWidget 存在性检查（第 238-241 行）
```javascript
var centerWidget = slotScene.getChildByTag(ActivityTagEnum.ACTIVITY_CENTER);
if (this.doNotUseCenterWidget || !cc.sys.isObjectValid(centerWidget)) {
    return;
}
```

**作用**：
- 获取关卡中的活动中心 Widget
- 如果标记不使用中心 Widget，或中心 Widget 不存在，则提前返回
- 避免在无活动中心的情况下执行"添加活动入口"操作

### 修改原理

**从逻辑上推断，倾向于该问题一直存在**，原因是：
- Coupon 关卡明确设置 `doNotUseCenterWidget = true`
- 但活动刷新逻辑未考虑此标记
- 任何涉及后置加载或断线重连的活动刷新都可能触发

**解决方案的改动**：
- 仅针对活动刷新触发的"添加活动入口"逻辑做额外判定
- 没有活动中心的情况下，不执行"添加活动入口"操作

---

## 代码变更

```javascript
// BaseActivity.js mountSlotSceneExtraUI 方法
// 修改前：没有有效性验证，直接挂载 UI

// 修改后：添加两层验证
mountSlotSceneExtraUI: function(slotScene) {
    // 新增验证 1：slotScene 有效性
    if (!cc.sys.isObjectValid(slotScene)) return;

    // 新增验证 2：centerWidget 存在性
    var centerWidget = slotScene.getChildByTag(ActivityTagEnum.ACTIVITY_CENTER);
    if (this.doNotUseCenterWidget || !cc.sys.isObjectValid(centerWidget)) {
        return;
    }

    // 后续的 UI 挂载逻辑，现在安全执行
    // ...
}
```

### 变更统计

| 指标 | 数值 |
|------|------|
| **修改行数** | +7 行 |
| **新增验证** | 2 个 |
| **修改文件** | 1 个 |

---

## 风险评估

### 风险等级

🟢 **较低**

### 影响范围

- **直接影响**：所有使用 `mountSlotSceneExtraUI` 的活动（尤其是 Coupon 关卡）
- **间接影响**：任何涉及后置加载、断线重连的活动都可能受益

### 兼容性

- ✅ 向后兼容：只添加安全检查，不改变现有行为
- ✅ 不影响其他功能：仅保护特定逻辑路径

---

## 测试验证

### 测试场景

| 场景 | 测试项目 | 验证方法 |
|------|---------|--------|
| **Coupon 关卡** | 正常进入 | 活动入口显示正常 |
| **Coupon 关卡** | 断线重连 | 重连后活动入口显示正常 |
| **普通关卡** | 正常进入 | 活动入口显示正常 |
| **普通关卡** | 断线重连 | 重连后活动入口显示正常 |
| **新框架关卡** | 所有场景 | 活动入口显示正常 |
| **老框架关卡** | 所有场景 | 活动入口显示正常 |

### 测试建议

```
新老关卡各挑几个，测试以下场景：
1. 正常进入关卡，活动入口显示
2. 在关卡中断网，重连后活动入口显示
3. 特别关注有后置加载的活动

如果没有问题，立即发版
```

---

## 相关信息

### 文件关联

| 文件 | 作用 | 相关性 |
|------|------|--------|
| `src/task/entity/BaseActivity.js` | 活动基类 | ⭐⭐⭐⭐⭐ |
| `src/task/entity/SlotSceneObject.js` | 关卡场景对象 | ⭐⭐⭐⭐ |
| `src/task/entity/WidgetController.js` | 关卡入口控制器 | ⭐⭐⭐ |

### 相关概念

- **Activity Center**: 活动中心 Widget，显示活动进度等信息
- **Activity Entrance**: 活动入口，用户进入活动的点击区域
- **doNotUseCenterWidget**: 标记，表示该活动不使用中心 Widget（如 Coupon 关卡）
- **PKCE**: 后置加载资源，在关卡启动后异步加载

### 讨论记录

**飞书群讨论时间**：2025-10-30 14:16 - 16:33

**参与人员**：
- 曹霞（问题报告）
- 赵恒（问题分析与修复）
- 陈天琦（协助调查）
- 马新蓝（Coupon 逻辑协助）
- 王建（资源确认）

**关键讨论点**：
1. 问题场景：free spin coupon 进入后活动入口异常
2. 原因定位：后置加载导致的时序问题
3. 方案确认：改动活动基础代码添加验证
4. 发版计划：验证无误后 5 点发版

---

## 参考链接

- **Git 提交**: [a14673a008a](http://localhost:5173/WTC-Docs/故障排查/Coupon关卡-活动入口异常显示问题)
- **飞书讨论**: CV发版通知群 2025年10月30日
- **修改文件**: `src/task/entity/BaseActivity.js:226-252`

---

## 标签

`#活动系统` `#UI挂载` `#Coupon` `#已解决` `#2025-10-30`