# 08 - 实施路线图与验证计划

[返回目录](00-index.md) | [上一章](07-execution-standards.md)

---

## 8.1 总体路线

```
Phase 1          Phase 2           Phase 3              Phase 4
L1 兼容层     →   L2 框架层      →   试点验证           →   批量转换
                                    (287 + 第二关卡)       (剩余 93 关卡)
```

### 依赖约束

- Phase 2 依赖 Phase 1 的 P0+P1 优先级方法完成
- Phase 3 依赖 Phase 2 的核心框架完成
- Phase 4 依赖 Phase 3 验证通过

---

## 8.2 Phase 1: L1 Cocos 兼容层

### 实施顺序

| 步骤 | 文件 | 预估方法数 | 依赖 | 状态 |
|------|------|-----------|------|------|
| 1.1 | `CCCompat.cs` | ~45 | 无 | 待开始 |
| 1.2 | `CCAction.cs` | ~44 | DOTween 引入 | 待开始 |
| 1.3 | `NameBinder.cs` | ~5 | 无 | 待开始 |
| 1.4 | `NodeHelper.cs` | ~23 | CCCompat | 待开始 |
| 1.5 | `GameUtil.cs` | ~50 (实际需实现) | CCCompat, CCAction, NameBinder | 待开始 |
| 1.6 | `SlotUtil.cs` | ~50 (实际需实现) | CCCompat, CCAction, GameUtil | 待开始 |
| 1.7 | `EventDispatcher.cs` | ~3 | 无 | 待开始 |
| 1.8 | `AudioBridge.cs` | ~10 | 无 | 待开始 |
| 1.9 | `ActivityUtil.cs` | ~40 (Slot 相关) | CCCompat, GameUtil | 待开始 |
| 1.10 | `UIHelper.cs` | ~20 | CCCompat, CCAction | 待开始 |
| 1.11 | `DialogBridge.cs` | ~5 | 无 | 待开始 |
| 1.12 | `SlotPopupUtil.cs` | ~4 | GameUtil | 待开始 |
| 1.13 | `WinEffectHelper.cs` | ~10 | GameUtil, SlotUtil | 待开始 |
| 1.14 | `HighRollerSlotUtil.cs` | ~12 | SlotUtil | 待开始 |

### Phase 1 验证

- [ ] 所有 L1 文件编译通过
- [ ] 映射表中所有 P0+P1 方法标记为 `已实现`
- [ ] NameBinder 能自动绑定测试 Prefab 的子节点
- [ ] CCAction.RunAction 能正确执行 Sequence/Spawn/Repeat
- [ ] 基础单元测试通过

---

## 8.3 Phase 2: L2 Slot 框架层

### 实施顺序

| 步骤 | 内容 | 预估文件数 | 依赖 | 状态 |
|------|------|-----------|------|------|
| 2.1 | 数据模型：SpinResult, MachineConfig, 枚举 | 5 | L1 | 待开始 |
| 2.2 | 核心基类：SlotComponentBase, SlotProcessBase, SlotActionBase | 5 | L1 | 待开始 |
| 2.3 | FlowDispatcher 流程引擎 | 4 (FlowNode/Sequence/Loop/Dispatcher) | 2.2 | 待开始 |
| 2.4 | SlotActionRegistry (SA/SAT) | 1 | 2.2 | 待开始 |
| 2.5 | SlotMachineBase 主场景基类 | 1 | 2.1-2.4 | 待开始 |
| 2.6 | Reel 卷轴系统 | 4 (ReelSystem/Strip/Controller/Pool) | 2.5 | 待开始 |
| 2.7 | 20 个基础组件 | 20 | 2.5, 2.6 | 待开始 |
| 2.8 | 35 个基础流程 | 35 | 2.5, 2.6 | 待开始 |
| 2.9 | 27 个基础动作 | 27 | 2.5 | 待开始 |

### Phase 2 验证

- [ ] 所有 L2 文件编译通过
- [ ] FlowDispatcher 单元测试：正确执行 Sequence、Loop、Break
- [ ] 创建一个最小 SlotMachineBase 子类，能走通完整流程树
- [ ] Reel 卷轴：能展示 3×3 网格的旋转→停止→弹跳
- [ ] 组件三阶段初始化：InitConfig → InitComponent → AfterInit 顺序正确
- [ ] 零 TODO

---

## 8.4 Phase 3: 试点验证

### 试点关卡选择

| 顺序 | 关卡 | 选择理由 |
|------|------|----------|
| 第一个 | **287 Wilds Starburst** | 已深入分析，16 个文件，复杂度中等，有代表性（Wild/FreeSpin/Jackpot） |
| 第二个 | **292 Rose Romance** | 最小关卡（9 个文件），验证流水线在简单关卡上的效率 |

### Phase 3 验证

- [ ] 287 完整走通：进房→旋转→赢分显示→FreeSpin 进入/退出→Jackpot
- [ ] 292 完整走通：进房→旋转→基本功能
- [ ] 两个关卡共享同一套 L1+L2，无冲突
- [ ] 转换 292 时未发现需要新增的 L1 API（或已补充）
- [ ] 两个关卡的自定义组件正确继承 L2 基类

### 试点结论判定

| 结论 | 条件 | 后续动作 |
|------|------|----------|
| **通过** | 两个关卡验证全部通过 | 进入 Phase 4 批量转换 |
| **需调整** | 发现 L1/L2 设计问题但可修复 | 修复后重新验证 |
| **需重审** | 发现架构级问题 | 回退到设计阶段 |

---

## 8.5 Phase 4: 批量转换

### 批量转换策略

优先级排序依据：
1. **模块化关卡优先**（11 个子目录关卡）— 结构清晰，AI 可独立转换
2. **然后单文件关卡**（84 个）— 按复杂度从低到高
3. **复杂度评估**：以 JS 代码行数为参考

### 模块化关卡转换计划

| 顺序 | 关卡 | 文件数 | 优先级 |
|------|------|--------|--------|
| 1 | 287 Wilds Starburst | 16 | Phase 3 已完成 |
| 2 | 292 Rose Romance | 9 | Phase 3 已完成 |
| 3 | 285 Carnival Blast | 13 | 高 |
| 4 | 286 Halo and Horns | 13 | 高 |
| 5 | 284 Santa Giftstorm | 21 | 高 |
| 6 | 293 Trio Wheels Deluxe | 16 | 中 |
| 7 | 291 Ducky Dollars | 19 | 中 |
| 8 | 288 Three Little Piggies | 17 | 中 |
| 9 | 297 Goldpot Party | 18 | 中 |
| 10 | 289 Yay Yeti Glitzy | 19 | 低 |
| 11 | 290 Dazzling Diamonds | 23 | 低（最复杂） |

### 批量验证策略

每转换 5 个关卡后执行一次集成验证：
1. 编译通过检查
2. 映射表完整性检查
3. 至少 1 个关卡的手动运行验证

---

## 8.6 风险与缓解

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| **CCB → Prefab 转换困难** | L1 的 LoadPrefab 无法完全替代 CCB 加载 | 中 | 建立 CCB → Prefab 转换工具链（可能需要额外工具） |
| **动画系统差异** | Cocos CCB Timeline 与 Unity Animator 行为不完全一致 | 中 | PlayAnim 方法内做兼容处理，必要时用 DOTween 模拟 |
| **DOTween 性能** | 大量 Sequence 同时运行可能有性能问题 | 低 | 对象池化 Sequence，限制并发数 |
| **L2 基类设计遗漏** | Phase 3 发现基类缺少扩展点 | 中 | Phase 3 就是为此设计，试点后迭代 |
| **Spine 动画兼容** | Spine 版本差异 | 低 | 使用 Spine-Unity 官方 Runtime |
| **服务端协议变更** | 迁移期间协议可能更新 | 低 | 客户端仅做展示层，协议层独立处理 |
| **84 个单文件关卡复杂度高于预期** | 单文件内可能有大量内联逻辑 | 中 | 转换前做代码行数/复杂度扫描，按复杂度分批 |

---

## 8.7 里程碑

| 里程碑 | 交付物 | 验证标准 |
|--------|--------|----------|
| **M1: L1 完成** | 14 个 C# 兼容层文件 + 完整映射表 | 编译通过 + 单元测试 |
| **M2: L2 完成** | ~97 个 C# 框架文件 | 编译通过 + FlowDispatcher 测试 + Reel 视觉测试 |
| **M3: 试点通过** | 287 + 292 两个完整关卡 | 手动运行验证 + 零 TODO |
| **M4: 模块化关卡全部完成** | 11 个关卡（184 JS → ~200 C# 文件） | 编译通过 + 抽样验证 |
| **M5: 单文件关卡全部完成** | 84 个关卡 | 编译通过 + 抽样验证 |

---

[下一章：09 - 附录 API 映射速查表](09-appendix-api-reference.md)
