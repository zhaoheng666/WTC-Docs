# Casino Royale 路线图绘制工具使用说明

## 工具信息

**文件位置**: `/Users/gaoyachuang/Desktop/路线图_线段绘制工具.html`
**版本**: v3.1
**创建日期**: 2026-01-23

## 功能概述

这是一个用于 Casino Royale 活动地图路线编辑的可视化工具，支持绘制NPC行走路径、设置标注点、导出配置文件等功能。

## 核心功能

### 1. 线段绘制

**操作方式**:
1. 点击画布设置起点
2. 再次点击设置终点
3. 自动生成线段并分配ID

**特性**:
- 智能吸附：点击时距离已有点位 ≤5 像素自动吸附
- 吸附预览：线段显示黄色，目标点位有黄色光圈
- 线段编号：自动在线段中点显示ID

### 2. 标注点模式

**操作方式**:
1. 点击"📍 标注点模式"按钮进入模式
2. 在地图上点击添加独立标注点
3. 右键点击标注点设置类型

**标注类型**:
- 👤 路线停留点 (`stand`)
- 🍷 服务员站立点 (`waiter`)
- 🧹 垃圾清扫点 (`trash`)
- 🎲 小游戏触发点 (`game`)

### 3. 起点设置

**操作方式**:
1. 右键点击节点或标注点
2. 选择"🚩 设置为起点"
3. 起点显示为红色旗帜标记

**清除起点**: 右键菜单 → "🗑️ 清除起点"

### 4. 拖拽调整

**操作方式**:
1. 鼠标悬停在标注点上（检测范围30像素）
2. 按住鼠标左键拖拽
3. 释放鼠标完成移动

### 5. 导入/导出

#### 导出配置
点击"📋 导出配置JSON"生成 `path_config_map.json`

**JSON格式**:
```json
{
  "segments": [
    {
      "id": 1,
      "pos0": {"x": -386, "y": 574},
      "pos1": {"x": -299, "y": 574}
    }
  ],
  "markers": [
    {
      "configCoords": {"x": -676, "y": 3},
      "type": "stand"
    }
  ],
  "startPoint": {"x": -386, "y": 574}
}
```

#### 导入配置
点击"📥 导入配置JSON"加载已有配置，支持继续编辑

## 坐标系统

### 图片坐标 → 配置坐标转换

```javascript
// 图片坐标转配置坐标
configX = imgX - CENTER_X
configY = CENTER_Y - imgY

// 配置坐标转图片坐标
imgX = configX + CENTER_X
imgY = CENTER_Y - configY
```

**中心点**:
- `CENTER_X = 图片宽度 / 2`
- `CENTER_Y = 图片高度 / 2`

### 示例
假设图片尺寸为 2772×1536：
- 中心点：(1386, 768)
- 图片坐标 (1000, 194) → 配置坐标 (-386, 574)
- 配置坐标 (0, 0) → 图片坐标 (1386, 768)

## 使用流程

### 完整工作流程

```
1. 📁 加载路线图
   ↓
2. ✏️ 绘制NPC行走路径（线段）
   ↓
3. 🚩 设置起点（右键点击节点）
   ↓
4. 📍 切换到标注点模式
   ↓
5. 🏷️ 添加独立标注点并设置类型
   ↓
6. 🖱️ 拖拽调整位置（可选）
   ↓
7. 📋 导出配置JSON
   ↓
8. 📂 将JSON放到项目路径：
   res_oldvegas/activity/casino_royale_map_X/path_config_map.json
```

## 快捷操作

| 操作 | 方式 |
|-----|------|
| 绘制线段 | 左键点击两次 |
| 添加标注点 | 标注点模式 + 左键点击 |
| 设置类型 | 右键点击 → 选择类型 |
| 移动标注点 | 按住拖拽 |
| 删除线段 | 点击列表中的线段两次 |
| 撤销 | 点击"↶ 撤销上一条" |
| 清空 | 点击"🗑️ 清空所有线段" |

## 统计信息

工具实时显示：
- ✅ 已绘制线段数
- ✅ 已标注节点数（线段节点）
- ✅ 独立标注点数
- ✅ 起点位置
- ✅ 特殊点位统计（按类型分类）

## 技术细节

### 智能吸附算法

```javascript
function findNearbyPoint(x, y, threshold = 5) {
    // 1. 检查起点
    if (distance(startPoint, {x, y}) <= threshold) {
        return startPoint;
    }

    // 2. 检查所有线段端点
    for (segment of segments) {
        if (distance(segment.start, {x, y}) <= threshold) {
            return segment.start;
        }
        if (distance(segment.end, {x, y}) <= threshold) {
            return segment.end;
        }
    }

    return {x, y, snapped: false};
}
```

### 标注点拖拽实现

```javascript
// 鼠标按下：检测标注点（30像素范围）
onMouseDown → findNearbyMarker(x, y, 30)

// 鼠标移动：更新标注点位置
onMouseMove → marker.x = mouseX - dragOffset.x

// 鼠标释放：完成拖拽
onMouseUp → 重置拖拽状态
```

### 右键菜单定位

右键菜单显示在点击点的**左上方**：
```javascript
menu.style.left = (screenX - 160) + 'px';
menu.style.top = (screenY - 20) + 'px';
```

## 注意事项

### 1. 图片加载
- 默认尝试加载 `/Users/gaoyachuang/Desktop/路线图.jpeg`
- 如果默认图片不存在，点击"📁 选择路线图"手动加载
- 加载后自动计算中心点和坐标系

### 2. 导出前检查
- ✅ 确认起点已设置
- ✅ 确认所有线段已连接
- ✅ 确认标注点类型已设置
- ✅ 检查统计信息是否正确

### 3. JSON兼容性
- 工具支持导入旧版和新版JSON格式
- 旧版：包含 `imageCoords`
- 新版：只包含配置坐标，自动转换

### 4. 浏览器兼容性
- 推荐使用 Chrome / Edge / Safari
- 需要支持 HTML5 Canvas API
- 需要支持 ES5 JavaScript

## 常见问题

### Q1: 点击没有反应？
**A**: 检查是否加载了图片，查看控制台是否有错误信息。

### Q2: 吸附不生效？
**A**: 确保距离已有点位 ≤5 像素，或调整 `findNearbyPoint` 的阈值参数。

### Q3: 导出的JSON坐标不对？
**A**: 检查图片尺寸是否正确，中心点计算是否准确（CENTER_X、CENTER_Y）。

### Q4: 拖拽标注点后自动触发点击？
**A**: 已通过 `justDragged` 标记避免，如果仍有问题检查延迟时间（当前50ms）。

### Q5: 右键菜单位置不对？
**A**: 检查画布缩放比例，调整菜单偏移量（当前 -160px, -20px）。

## 更新日志

### v3.1 (2026-01-23)
- ✅ 添加独立标注点功能
- ✅ 支持标注点拖拽
- ✅ 添加特殊点位统计
- ✅ 优化右键菜单定位
- ✅ 改进吸附视觉反馈

### v3.0
- ✅ 添加起点设置功能
- ✅ 支持导入/导出JSON
- ✅ 添加节点类型标注

### v2.0
- ✅ 基础线段绘制
- ✅ 智能吸附
- ✅ 坐标转换

## 相关文档

- [Casino Royale 小游戏移植流程](/../活动/Casino Royale 小游戏移植流程)
- [Casino Royale 业务开发记录](/../活动/Casino Royale 业务开发记录)

---

**维护者**: WorldTourCasino Team
**最后更新**: 2026-01-23
