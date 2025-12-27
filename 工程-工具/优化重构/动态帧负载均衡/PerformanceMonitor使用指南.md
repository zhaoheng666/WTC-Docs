# PerformanceMonitor 使用指南

## 概述

PerformanceMonitor 是统一的性能监控与帧预算计算组件，负责提供实时帧耗时、剩余预算、设备性能等级等信息，并为 FrameScheduler 与资源加载模块提供决策依据。

**核心能力**:

- 设备性能等级评估（CPU 核心数、移动端识别）
- 帧时间/预算/剩余预算计算
- 实时帧负载检测（空闲/繁忙）
- 性能采样与统计（批次加载、任务耗时）

## 帧预算模型原理

**目标帧时间**: 60fps 对应约 16.67ms（实际取值由引擎帧率决定）

**任务预算比例**: 70%（保留 30% 给引擎渲染）

| 项目 | 公式 | 说明 |
|------|------|------|
| 目标帧时间 | `getAnimationInterval() * 1000` | 引擎目标帧时间（ms） |
| 任务预算 | `targetFrameTime * 0.7` | 默认预算比例 70% |
| 剩余预算 | `frameBudget - frameElapsed` | 本帧可用时间 |

```javascript
var PerformanceMonitor = require("../common/util/PerformanceMonitor");

var monitor = PerformanceMonitor.getInstance();
var target = monitor.getTargetFrameTime();
var budget = monitor.getFrameBudget();
var remaining = monitor.getRemainingBudget();
```

## 核心 API

| API | 返回值 | 说明 |
|-----|--------|------|
| `getRemainingBudget()` | Number | 当前帧剩余预算（ms） |
| `isFrameIdle()` | Boolean | 帧空闲（预算充足） |
| `isFrameBusy()` | Boolean | 帧繁忙（预算不足） |

**辅助接口**:

- `getFrameElapsed()`：本帧已消耗时间
- `getFrameBudget()`：本帧任务预算
- `getAverageFrameTime()`：最近 N 帧平均耗时

## 与其他组件协作

| 组件 | 协作方式 | 作用 |
|------|----------|------|
| FrameScheduler | 委托目标帧时间与预算计算 | 统一帧预算模型、动态帧调度 |
| CanvasDownloader | 动态计算 batchSize + 帧空闲检测 | 降低单帧加载阻塞 |
| ConfigManager | 读取性能等级、记录批次样本 | 自适应批次策略 |

## 实时负载检测方法

**建议流程**:

1. 使用 `isFrameBusy()` 快速判断是否跳过任务
2. 用 `getRemainingBudget()` 计算本帧可执行量
3. 结合 `getAverageFrameTime()` 观察趋势

```javascript
var PerformanceMonitor = require("../common/util/PerformanceMonitor");

var monitor = PerformanceMonitor.getInstance();
if (monitor.isFrameBusy()) {
    requestAnimationFrame(doWorkNextFrame);
    return;
}

var remaining = monitor.getRemainingBudget();
var batchSize = Math.max(3, Math.min(10, Math.floor(remaining / avgTimePerResource)));
loadBatch(batchSize);
```

**实时检测要点**:

- `isFrameBusy()` 适合快速阻断重任务
- `getRemainingBudget()` 适合动态计算批次大小
- `isFrameIdle(requiredBudget)` 可传入预估耗时（ms）
