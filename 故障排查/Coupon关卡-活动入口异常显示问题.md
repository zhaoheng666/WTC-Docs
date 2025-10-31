# Coupon 关卡 - 活动入口异常显示问题

## 摘要

| | |
|-|-|
| **状态** | ✅ 已解决 |
| **提交** | `a14673a008a` |
| **文件** | `src/task/entity/BaseActivity.js:226-252` |
| **原因** | `mountSlotSceneExtraUI()` 未验证活动中心存在性 |

---

## 问题

Coupon 关卡无活动中心，但活动入口异常显示

**触发场景**：
- 后置资源未加载完成就进入 coupon 关卡
- 关卡中断线重连

---

## 解决方案

在 `BaseActivity.mountSlotSceneExtraUI()` 添加两层验证：

```javascript
// 验证 slotScene 有效性
if (!cc.sys.isObjectValid(slotScene)) return;

// 验证 centerWidget 存在性
var centerWidget = slotScene.getChildByTag(ActivityTagEnum.ACTIVITY_CENTER);
if (this.doNotUseCenterWidget || !cc.sys.isObjectValid(centerWidget)) {
    return;
}
```

---

## 测试

- ✅ Coupon 关卡正常进入和断线重连
- ✅ 普通关卡断线重连
- ✅ 新老框架关卡活动入口正常

---

## 现场记录

👉 **[CV发版通知群 2025年10月30日](https://ghoststudio.feishu.cn/wiki/FjqOwGH72izxYHkbgKgcUSEbnZb?from=from_copylink)**