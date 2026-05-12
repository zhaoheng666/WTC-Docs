# Knit & Luck 毛线织图玩法可行性调研

> **背景**：竞品 Bingo Frenzy 的「Knit & Luck」玩法将传统 Bingo 包装成"毛线织图"体验，截图中可见线轴改动、毛线甩动、连线、织图等复杂表现，基于 **Cocos Creator** 实现。本文评估 WTC 当前引擎（cocos2d-html5 v3.13-lite-wtc）能否支撑同等表现，并与 Cocos Creator 路径做成本对比。

---

## 一、竞品核心表现拆解

| 表现 | 描述 |
| --- | --- |
| **线轴形象** | 5×5 Bingo 格，每格一个毛线团；命中后顶部弹出"线头" |
| **毛线甩动** | 线团之间、线团到画板之间的毛线有自然下垂、摆动、回弹 |
| **连线** | 从线团延伸到右侧画板对应位，多色曲线带粗细与毛线纹理 |
| **织图** | 右侧画板由像素方块组成，命中一格即点亮对应区域，最终拼出完整图案 |

---

## 二、当前引擎能力盘点

| 表现需求 | 引擎能力 | 项目内现成参考 |
| --- | --- | --- |
| 矢量曲线 / 线段 | `cc.DrawNode`（drawSegment / drawPoly，Canvas + WebGL 双后端） | `src/common/view/LineDrawNode.js`、`src/common/effect/WinLineNode.js` |
| 甩动 / 拖尾 | `cc.MotionStreak`（`cocos2d/motion-streak/`） | 引擎内置，项目未显式使用 |
| 离屏合成 / 渐进显形 | `cc.RenderTexture` | `magic_scratch`、`lucky_scratch`、`bundle_system`、`sure_win_lotto`、`bingo_scratch` 均用于刮刮乐效果 |
| 骨骼动画（线轴表现） | Spine（`extensions/spine/Spine.js`） | slot symbol 大量使用 |
| 物理（摆动 / 弹簧） | Chipmunk（`external/chipmunk/chipmunk.js`）、Box2D | 引擎内置，主项目未启用 |
| 粒子（毛线碎屑等） | `cc.ParticleSystem` | 活动通用 |
| 裁剪 | `cc.ClippingNode` | 通用 |

**结论：渲染能力层面，v3.13-lite-wtc 与 Cocos Creator 2.x 基本对等，不存在"做不到"的瓶颈。**

---

## 三、四个核心表现的实现路径

### 3.1 线轴 / 毛线团形象

- 静态帧 + 命中动画：**贴图 + Spine**，与现有 slot symbol 完全同构。
- 技术风险：无。

### 3.2 毛线甩动（物理摆动）

| 方案 | 思路 | 工时估算 | 推荐度 |
| --- | --- | --- | --- |
| **A. Verlet 绳索（推荐）** | N 个质点 + 距离约束，每帧迭代 3~5 次，重力 + 阻尼，输出折线给 DrawNode | 约 200~300 行 ES5，1~2 天 | ★★★★★ |
| B. Chipmunk 关节链 | PinJoint 串质点，启用物理 World | 接入成本高、踩坑风险大 | ★★☆☆☆ |

Verlet 是 H5 绳索 / 毛线类表现的业界标准解，与引擎完全解耦，推荐选 A。

### 3.3 连线（毛线曲线）

- 每条连线 = 一组 Verlet 质点（N=12~20），`DrawNode.drawSegment` 逐段连接。
- 粗细 + 阴影：`drawSegment` 的 `width` 参数 + 同路径偏移一次绘制暗色（阴影层）。
- 毛线绒毛质感（可选）：沿路径采样 UV 的自定义 Sprite 条带；建议先做纯色 + 阴影版 Demo 验证体感，再决定是否升级。

### 3.4 织图（像素渐显）

完全可复用现有 RenderTexture 刮刮乐套路：

1. 一张目标图（完整织好的图案）作底。
2. 一个全覆盖的"未织"灰色层。
3. 命中号码 → 在 RenderTexture 上以"擦除"方式露出对应像素块（或反向逐块"织"色块）。
4. 像素块按 N×M 网格切分，命中事件触发：连线动画延伸到目标区 → 该区域逐格点亮 + 粒子。

---

## 四、与 Cocos Creator 路径的成本对比

| 维度 | WTC 当前引擎 | Cocos Creator | 差异 |
| --- | --- | --- | --- |
| 渲染能力 | 全部具备 | 全部具备 | 持平 |
| 编辑器 / 可视化布局 | 无，纯代码 + JSON | 有，拖拽 + Prefab | Creator 优 |
| 绳索 / 曲线 | DrawNode + 手写 Verlet | Graphics + 手写 Verlet（同样需要写） | 持平 |
| 毛线贴图条带 | 自定义 Sprite 渲染 | 自定义 Component | 持平 |
| 像素织图 | **RenderTexture 已多处复用，有现成参考** | RenderTexture / Mask | WTC 略优 |
| Spine | 已用 | 已用 | 持平 |
| 语言 | ES5（效率略低） | TypeScript / ES6+ | Creator 优 |
| 资源 / 构建管线 | 已成熟（res_xxx/flavor） | 需新建管线 | WTC 优（无迁移成本） |
| 团队熟悉度 | 高 | 低（引入新引擎） | WTC 优 |

### 工时估算

| 路径 | 玩法本身工时 | 一次性额外成本 | 合计 |
| --- | --- | --- | --- |
| **WTC 当前引擎** | 3.5 ~ 4.5 人周 | 0 | **3.5 ~ 4.5 人周** |
| 切换 Cocos Creator | 3 ~ 4 人周 | 引擎迁移 / 双工程并存 3~5 人周 | **6 ~ 9 人周** |

---

## 五、风险与建议

| 风险点 | 说明 | 应对 |
| --- | --- | --- |
| 毛线绒毛质感 | 沿路径贴图条带需自定义渲染 | 先做纯色 + 阴影版 PoC，视觉不够再升级 |
| 同屏连线数量 | ~10 条 Verlet 绳索 × 20 质点，DrawNode 每帧重建 buffer 在低端 Android 上有帧率压力 | 静止线条不跑 Verlet，仅在触发 / 拖拽时激活 |
| 像素织图网格密度 | 建议画板 ≤ 32×32，单格用可复用小色块 Sprite，避免 RT 内逐像素操作 | 设计阶段对齐分辨率上限 |

---

## 六、推荐下一步：PoC 验证

**投入**：1 ~ 1.5 人周

**范围**：

1. 一根 Verlet 毛线：从固定锚点到鼠标，每帧打印 FPS。
2. 一块 16×16 像素织图：点击触发 → 逐格点亮。
3. 命中流程串联：点击线团 → 毛线延伸到目标像素区 → 该区织色。
4. CV 风格下执行 `cd scripts && ./build_local_oldvegas.sh` 验证构建无报错 / 警告。

**通过标准**：中端 Android Chrome 真机 ≥ 50 FPS。达标即可立项，否则回到"同屏连线数量"风险点优化后复测。

---

## 七、关键参考文件

| 文件 | 用途 |
| --- | --- |
| `frameworks/cocos2d-html5/cocos2d/shape-nodes/CCDrawNode.js` | 矢量绘制 API |
| `frameworks/cocos2d-html5/cocos2d/motion-streak/CCMotionStreak.js` | 拖尾 API |
| `frameworks/cocos2d-html5/cocos2d/render-texture/` | 离屏合成 API |
| `frameworks/cocos2d-html5/extensions/spine/Spine.js` | 骨骼动画 |
| `src/common/view/LineDrawNode.js` | DrawNode 连线封装，可直接复用 |
| `src/common/effect/WinLineNode.js` | 多段连线实例 |
| `src/social/controller/bundle_system/BundleScratchMainController.js` | RenderTexture 渐显参考 |
| `src/task/controller/magic_scratch/ui/MagicScratchItemController.js` | RenderTexture 擦除参考 |

---

**核心结论**：当前 WTC 引擎完全可以实现该玩法的全部视觉表现，工时仅比 Cocos Creator 多 10~15%，远低于换引擎的一次性迁移成本，建议在现有引擎上做 PoC 后立项。

---

## 八、毛线连线 Demo 实现记录

> **状态**：PoC 完成（毛线连线部分），已在 `OdysseyMythicMainUIController.js` 验证可行性。

### 8.1 最终技术方案

放弃 `cc.DrawNode` 纯色线 + `CMeshRenderNode` 贴图线两条路，最终采用 **Sprite 条带沿路径摆放**：

- 以弧长为步进（`STEP = 8px`），沿贝塞尔曲线等间距放置 `cc.Sprite`
- 每个 Sprite 取 plist 帧，旋转到切线方向（`setRotation(-ang + 90)`）
- 通过 `setScaleX(0.12)` 压窄贴图宽度（旋转 90° 后 X 轴对应视觉宽度）
- Sprite 池复用，多余隐藏不销毁，避免频繁 GC

> **踩坑**：`CMeshRenderNode`（`cc.GLNode`）在当前引擎升级版本中 `_stackMatrix` 为 `undefined`，`cc.kmGLLoadMatrix` 会 crash，已确认弃用，`LineDrawNode.js` 中也有同样注释。

### 8.2 S 形曲线结构

用**两段三次贝塞尔首尾拼接**生成 S 形：

```
起点 s → 中间衔接点 mid → 终点 e
第一段控制点偏法线 +sign 侧
第二段控制点偏法线 -sign 侧（反向）
```

- `sign`：S 弯强度，范围 `-1 ~ +1`，正负决定 S 方向
- `amp = len * AMP`：幅度随线长等比缩放
- `midShift`：中间衔接点沿切线方向的轻微偏移，增加不对称感

### 8.3 摆动系统

**步进往复驱动**（每 `INTERVAL` 秒执行一次）：

| 参数 | 当前值 | 说明 |
| --- | --- | --- |
| `INTERVAL` | 0.06s | 步进间隔 |
| `STEP_SIZE` | 0.70 | 每次 sign 步进量 |
| `SIGN_MAX` | ±0.8 | sign 边界（控制弧度上限） |
| `AMP` | 0.12 | 幅度系数（乘以线长） |
| `R`（终点漂移） | 50px | baseEnd ±50px 随机范围 |

每条线维护独立步进状态（初始相位错开），`sign` 碰到边界自动反向，产生有节奏的 S 弯往复翻转。每次步进时终点在 `baseEnd ±50px` 范围内随机漂移，形态不单调。

### 8.4 关键文件

| 文件 | 说明 |
| --- | --- |
| `src/activity/odyssey_mythic/controller/OdysseyMythicMainUIController.js` | Demo 所在文件，搜索 `_initYarnDemo` |
| `res_oldvegas/activity/odyssey_mythic/effects/odyssey_mythic_main_bg_wenli_sg1.plist` | 当前使用的贴图 plist，帧 `_008.png` 尺寸 182×52 |

### 8.5 待展开方向

- [ ] **织图（像素渐显）**：复用 `magic_scratch` / `bingo_scratch` 的 `RenderTexture` 擦除套路，将画板按 N×M 网格分块，命中后逐格点亮
- [ ] **线轴形象**：替换为 Spine 骨骼动画，命中时播放"冒线头"动画
- [ ] **连线延伸动画**：入场时用 `drawT` 参数从 0→1 渐进绘制（已有 DrawNode 直线生长阶段的框架，可复用到贴图阶段）
- [ ] **多色绳子**：每条线用不同 plist 帧（需设计提供多色毛线素材）
- [ ] **性能测试**：在中端 Android Chrome 真机验证同屏 10 条绳 × 50 Sprite 的帧率（目标 ≥ 50 FPS）

---

**最后更新**：2026-05-09  
**负责人**：zhaoheng666
