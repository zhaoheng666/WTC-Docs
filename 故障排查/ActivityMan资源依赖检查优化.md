# ActivityMan 资源依赖检查优化

## 问题描述

在活动"补单"场景下（`onGetOpenActivitiesCmd`），系统发现本地未缓存某些活动时，直接请求服务器数据，**没有检查和下载后置加载活动的资源**，导致：

1. 活动资源未下载，显示异常
2. 用户体验受影响（活动入口无法正常显示）
3. 需要等待下一次资源检查才能下载

## 问题分析

### 原始代码流程

```javascript
// src/task/model/ActivityMan.js (第 298-309 行)
onGetOpenActivitiesCmd: function (openActivities, args) {
    var activityIdList = openActivities.activityIdList;
    if (!activityIdList.length) return;

    var needRequestActivities = [];
    for (var i = 0; i < activityIdList.length; i++) {
        var activityId = activityIdList[i];
        if (!this.activities[activityId]) {
            needRequestActivities.push(activityId);
        }
    }

    if (needRequestActivities.length) {
        // ❌ 直接请求，没有检查资源
        this.sendRequestActivityCmd(needRequestActivities, args);
    }
}
```

### 问题根源

1. **缺少资源依赖检查**：没有检查后置加载活动是否需要下载资源
2. **时序问题**：先请求数据，后下载资源，导致活动无法正常初始化
3. **未利用现有 API**：没有使用已设计好的 `ensureActivityResources` 方法

## 解决方案

### 集成 ensureActivityResources

利用 `ActivityLoader.ensureActivityResources` 方法，在请求活动数据前确保资源已下载：

```javascript
onGetOpenActivitiesCmd: function (openActivities, args) {
    var activityIdList = openActivities.activityIdList;
    if (!activityIdList.length) return;

    var self = this;
    var needRequestActivities = [];
    var activitiesToEnsure = [];  // 需要确保资源的活动

    // 检查哪些活动需要请求
    for (var i = 0; i < activityIdList.length; i++) {
        var activityId = activityIdList[i];
        if (!this.activities[activityId]) {
            needRequestActivities.push(activityId);

            // 检查是否是后置加载活动
            var lagLoadActivity = this.getLagLogActivityByActivityName(activityId);
            if (lagLoadActivity && lagLoadActivity.themeName) {
                activitiesToEnsure.push(activityId);
            }
        }
    }

    // 如果有需要确保资源的活动
    if (activitiesToEnsure.length > 0) {
        cc.log('[ActivityMan] Ensuring resources for activities:', activitiesToEnsure);

        var pendingCount = activitiesToEnsure.length;
        var completedCount = 0;

        var onResourceEnsured = function(success) {
            completedCount++;

            if (!success) {
                cc.warn('[ActivityMan] Failed to ensure resources for some activities');
            }

            // 所有资源检查完成后，继续请求活动数据
            if (completedCount === pendingCount) {
                if (needRequestActivities.length) {
                    self.sendRequestActivityCmd(needRequestActivities, args);
                }
            }
        };

        // 使用 ensureActivityResources 确保每个活动的资源
        var activityLoader = game.ResourceMan.getInstance().getLoader('activity');
        for (var j = 0; j < activitiesToEnsure.length; j++) {
            activityLoader.ensureActivityResources(activitiesToEnsure[j], onResourceEnsured);
        }
    } else if (needRequestActivities.length) {
        // 不需要下载资源，直接请求活动数据
        this.sendRequestActivityCmd(needRequestActivities, args);
    }
}
```

## 关键改进

### 1. 资源依赖检查
- 在请求活动数据前，先检查是否需要下载资源
- 使用 `getLagLogActivityByActivityName` 识别后置加载活动

### 2. 使用正确的 API
- 调用 `ActivityLoader.ensureActivityResources` 方法
- 该方法内部使用 `critical: true` 确保立即下载

### 3. 并行处理
- 多个活动资源可以并行检查和下载
- 提高资源下载效率

### 4. 容错机制
- 即使部分资源下载失败，仍继续请求活动数据
- 避免因个别资源问题阻塞整个流程

## 验证方法

### 1. 功能验证

```javascript
// 模拟活动补单场景
// 1. 清理本地活动缓存
delete game.ActivityMan.getInstance().activities[activityId];

// 2. 触发补单
game.ActivityMan.getInstance().onGetOpenActivitiesCmd({
    activityIdList: [activityId]
}, {});

// 3. 检查日志
// 应该看到：
// [ActivityMan] Ensuring resources for activities: [...]
// [ResourceManV2] [CRITICAL] Resource download started: activity/xxx
```

### 2. 构建验证

```bash
cd scripts
./build_local_oldvegas.sh
# 确保无编译错误
```

## 影响范围

- **修改文件**：`src/task/model/ActivityMan.js`
- **影响功能**：活动补单场景的资源下载
- **向后兼容**：完全兼容，不影响现有功能

## 相关文档

- ResourceManV2内存优化.md
- openspec/changes/optimize-resourcemanv2-memory/

## 更新历史

- 2024-11-23：初始文档，记录活动资源依赖检查优化