# Native 资源下载缓存优化 - 设计图

## 1. 整体架构

![整体架构](/assets/resource-v2/native-cache-architecture.png)

**说明**：
- **缓存命中**（绿色路径）：8 层校验通过后直接加载资源，无网络请求
- **缓存未命中**（橙色路径）：触发 jsb.AssetsManager 下载，完成后写入缓存
- **三级存储**：localStorage 持久化、内存缓存加速、搜索路径支持资源加载

---

## 2. isDownloaded() 8 层校验流程

![8层校验流程](/assets/resource-v2/native-cache-flow.png)

**校验层级**：

| 层级 | 检查内容 | 失败处理 |
|-----|---------|---------|
| ① | 内存缓存 `_downloadedMap` | 继续下一层 |
| ② | Native 平台判断 | Web 端直接返回 false |
| ③ | localStorage 记录 | 返回 false |
| ④ | commonVersion 版本匹配 | 清除缓存 + 返回 false |
| ⑤ | manifest 文件存在 | 清除缓存 + 返回 false |
| ⑥ | manifest 版本匹配 | 清除缓存 + 返回 false |
| ⑦ | 资源文件抽样检查 | 清除缓存 + 返回 false |
| ⑧ | 添加搜索路径 | - |

---

## 3. 优化前后对比

![优化前后对比](/assets/resource-v2/native-cache-comparison.png)

**关键差异**：

| 指标 | 优化前 | 优化后 |
|-----|-------|-------|
| 网络请求 | 每次启动都请求 manifest | 缓存命中时无请求 |
| 加载速度 | 受网络延迟影响 | 本地校验，毫秒级 |
| 离线支持 | 需要网络确认版本 | 完全离线可用 |

---

## 4. 数据存储结构

![数据存储结构](/assets/resource-v2/native-cache-data.png)

**存储格式**：

```javascript
// localStorage Key: "ResourceManV2_DownloadCache"
{
    "activity/club_event_box": "93.6.905520",
    "slot/wild_fever": "93.6.905520",
    "poster/card_system_xxx": "93.6.905520"
    // resourcePath: commonVersion
}
```

---

## 相关文档

- 技术文档：`docs/优化重构/resource-v2/Native资源下载缓存优化.md`
- OpenSpec 归档：`openspec/changes/archive/2026-01-13-optimize-native-download-cache/`
