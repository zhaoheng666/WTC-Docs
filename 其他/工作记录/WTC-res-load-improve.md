# WTC 资源加载优化任务跟踪

**创建日期**: 2025-10-16
**状态**: 进行中
**优先级**: 高

---
## 任务概述
优化 WorldTourCasino 主项目（老项目）的资源加载方式，提升游戏性能和用户体验。

## 强制规则
- 所有代码修改必须保持 ES5 兼容
- 不要随便在这个文件中添加内容，必须保证精简、准确

## 关注点
- 关注内存泄漏风险

### 目标

- 改善游戏启动速度：减少进入大厅前加载资源量，缩短 loading 时间
- 优化内存占用
- 提升资源管理效率

---

## 相关文档

- [Cocos2d-html5 官方文档](https://docs.cocos2d-x.org/cocos2d-x/v3/zh/)
- [项目技术栈说明](/../技术文档)

---

## 关键步骤记录

### 2025-10-16：系统架构分析

#### 核心模块

| 模块 | 文件 | 职责 |
|-----|------|------|
| AssetsManager | `src/common/asset/AssetsManager.js:130` | JSB 资源下载、版本比对、失败重试 |
| LoadingController | `src/loader/LoadingController.js:136` | 第1阶段加载入口、manifest 刷新 |
| ResourceMan | `src/common/model/ResourceMan.js:218` | 关卡资源管理、manifest 生成 |
| FeatureResMan | `src/common/model/FeatureResMan.js:106` | 分阶段加载调度（LobbyRes/FeatureRes） |
| SlotPreDownloadMan | `src/slot/model/SlotPreDownloadMan.js:120` | 关卡预下载队列（最多3线程） |

#### 三阶段加载流程

```
阶段1（启动）: LoadingController → 基础资源（占10%或97%进度）
阶段2（Game.js加载后）: FeatureResMan → LobbyRes（分iOS/Android）
阶段3（登录后）: FeatureResMan → FeatureRes（高级功能）
游戏内: SlotPreDownloadMan → 关卡预下载（3线程并发）
```

#### Manifest 机制

- **优先级**: `documents/project.manifest` > `documents/assets_config/project.manifest` > 包内 manifest
- **资源质量**: HD(`_hd`) / SD(无后缀) / LD(`_ld`)
- **版本控制**: `@version` 快速比对 + `@manifest` 完整清单

#### 已识别的优化点

1. ⚠️ Manifest 重复读写（每次启动都重新生成备份）
2. ⚠️ 资源释放时机（切关卡时批量释放）
3. ⚠️ CCB 文件加载无缓存
4. ⚠️ 图片资源批量加载（无懒加载）
5. ⚠️ 预下载队列无优先级调度

**最后更新**: 2025-10-16
**维护者**: WTC Team
