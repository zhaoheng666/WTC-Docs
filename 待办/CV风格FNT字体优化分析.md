# CV 风格 FNT 字体优化分析报告

## 整体统计

| 指标 | 数值 |
|------|------|
| **.fnt 文件总数** | **4,060 个** |
| **唯一字体名称** | 2,261 个 |
| **.fnt 元数据大小** | 33 MB |
| **字体纹理总大小** | **186 MB** |

---

## 目录分布

| 目录 | 文件数 | 占比 |
|------|--------|------|
| **activity/** | 1,923 | 47.4% |
| **casino/** | 256 | 6.3% |
| **dynamic/** | 238 | 5.9% |
| **common/** | 146 | 3.6% |
| **slot/** | 135 | 3.3% |
| **card_system_lagload/** | 55 | 1.4% |
| **其他（关卡等）** | ~1,307 | 32.2% |

---

## 重复最多的字体文件 TOP15

| 字体文件名 | 重复次数 | 用途 |
|-----------|---------|------|
| `140_3.fnt` | 81 | 编号字体 |
| `jackpot_fever_48_green.fnt` | 55 | 彩票活动 |
| `jackpot_fever_48_blue.fnt` | 46 | 彩票活动 |
| `jackpot_fever_48.fnt` | 43 | 彩票活动 |
| `jackpot_fever_discount_60.fnt` | 33 | 折扣展示 |
| `hr_wheel_white_34.fnt` | 31 | 高额游戏 |
| `bingo_fever_tip_white_48.fnt` | 22 | Bingo 提示 |
| `journey_info3_w_24.fnt` | 19 | Journey 活动 |
| `store_coin_yellow_60.fnt` | 18 | 商店金币 |
| `new_spinui_win_44.fnt` | 18 | 旋转 UI |
| `new_spinui_win_32.fnt` | 18 | 旋转 UI |
| `store_coin_yellow_120.fnt` | 17 | 商店金币 |
| `road_mission_info_28.fnt` | 17 | Road 活动 |
| `title_107_2.fnt` | 15 | 标题字体 |
| `activity_center_white_24.fnt` | 15 | 活动中心 |

---

## 活动目录字体分布 TOP15

| 活动名 | 字体数 |
|--------|--------|
| `bingo_island` | 42 |
| `vegas_pass_treasure` | 33 |
| `magical_journey_lb` | 33 |
| `snake_ladders_2025` | 30 |
| `magical_journey_id4` | 29 |
| `magical_journey_hw` | 29 |
| `system_casino_challenge` | 28 |
| `vegas_quest_first_quest` | 27 |
| `santa_s_retreat` | 25 |
| `paddy_s_wonderland_2025` | 25 |
| `club_bingo` | 25 |
| `casino_challenge` | 25 |
| `9th_brithday_fiesta` | 25 |
| `10th_birthday_fiesta` | 25 |
| `club_pinata_game` | 24 |

---

## 文件大小分布

| 大小范围 | 数量 | 占比 |
|---------|------|------|
| 2-5 KB | 2,522 | 62.1% |
| 5-10 KB | 239 | 5.9% |
| > 10 KB | 1,299 | 32.0% |

---

## 最大纹理文件 TOP10

| 文件 | 大小 | 位置 |
|------|------|------|
| `mysterious_gift_wild_font_anim.png` | 1.2 MB | 关卡特效 |
| `reward_video_150.png` | 916 KB | common/fonts |
| `168_tanban_num1.png` | 908 KB | 关卡字体 |
| `brilliant_diamonds_symbol_bonus_spins_font_3d.png` | 740 KB | 关卡特效 |
| `haunted_treats_symbol_wild_10x_trigger_3d_font.png` | 652 KB | 关卡特效 |
| `glitzy_hits_symbols_jackpot_font_3d_sweep.png` | 612 KB | 关卡特效 |
| `1_8.png` | 580 KB | jackpot_clover |
| `brilliant_diamonds_symbol_500x_font_jackpot_win_3d.png` | 548 KB | 关卡特效 |
| `haunted_treats_symbol_batch_bonus_font_3d.png` | 536 KB | 关卡特效 |
| `brilliant_diamonds_symbol_bonus_free_font_3d.png` | 516 KB | 关卡特效 |

---

## common/fonts 公共字体（75 个）

常用字体示例：

| 字体文件 | 大小 | 用途 |
|---------|------|------|
| `button_white_30.fnt` | 15.6 KB | 按钮文字 |
| `dialog_title_40.fnt` | 12 KB | 对话框标题 |
| `gold_font_30pt.fnt` | 12 KB | 金色数字 |
| `gold_neuron_90.fnt` | 19.7 KB | 金色标题 |
| `white_one.fnt` | - | 白色通用 |
| `bigwin_160.fnt` | 2.8 KB | 大赢展示 |

---

## 关键发现

1. **活动目录占比近半** - 1,923 个字体在 activity/ 目录，占 47.4%
2. **重复严重** - 同一字体文件（如 `140_3.fnt`）在 81 个不同位置存在副本
3. **大纹理集中在关卡** - 超过 500KB 的纹理主要用于关卡 3D 特效字体
4. **大文件占比高** - 32% 的 fnt 文件超过 10KB

---

## 运行时性能影响分析

### BMFont 引擎实现原理

`cc.LabelBMFont` 继承自 `cc.SpriteBatchNode`，每个字符作为独立的 `cc.Sprite` 子节点。

```text
cc.LabelBMFont
  └─ extends cc.SpriteBatchNode
      └─ 每个字符 = 1 个 cc.Sprite 子节点
```

### 性能影响因素

#### 1. Draw Call 问题

| 场景 | Draw Call 数量 | 说明 |
|------|---------------|------|
| 同一字体的多个 Label | **1 次** | SpriteBatchNode 自动合批 |
| 不同字体的多个 Label | **N 次** | 每个字体纹理 = 1 次 Draw Call |
| 同屏 10 种字体 | **10+ 次** | 纹理切换导致批次打断 |

**关键结论**：字体文件数量多 → 纹理种类多 → Draw Call 增加

#### 2. 内存占用

| 类型 | 占用方式 | 影响 |
|------|---------|------|
| **纹理内存 (GPU)** | 每个 .fnt 对应的 .png 加载到显存 | 186 MB 纹理 = 186 MB 显存上限 |
| **配置内存 (CPU)** | .fnt 文件解析后的字符映射表 | 每个字体 ~10-50 KB |
| **Sprite 对象** | 每个字符创建 1 个 Sprite | 100 字文本 = 100 个对象 |

#### 3. 字符串更新开销

```javascript
// setString() 会触发 createFontChars()
// 每次更新文本 = 销毁旧 Sprite + 创建新 Sprite
label.setString("新文本");  // 触发完整重建
```

**高频更新场景**（如计时器、积分）会产生大量 GC 压力。

#### 4. 纹理切换代价

```text
渲染顺序：Label A (字体1) → Label B (字体2) → Label C (字体1)
Draw Call：    1              2              3 (无法合并回字体1)
```

即使使用相同字体，如果渲染顺序被其他字体打断，也无法合批。

### 性能问题严重度评估

| 问题 | 严重度 | 影响范围 |
|------|--------|---------|
| 纹理种类过多导致 Draw Call 高 | 🔴 高 | 全局渲染性能 |
| 大纹理加载延迟 | 🟡 中 | 首次显示卡顿 |
| 频繁 setString 的 GC 压力 | 🟡 中 | 动态文本场景 |
| 配置内存常驻 | 🟢 低 | 内存占用 |

---

## 优化建议

### 优先级 1：资源去重（高收益）

#### 1.1 重建全局共享字体库

- **目标**：消除跨活动重复
- **预期收益**：减少 30-40% 活动字体文件

#### 1.2 字体尺寸精简

**当前问题**：存在过多尺寸变体（24, 28, 30, 32, 34, 40, 44, 48, 50, 60, 80, 100, 120, 150, 160pt）

**建议保留**：
- 小号：30pt（按钮、提示）
- 中号：48pt（正文、标签）
- 大号：80pt（标题、奖励）
- 特大：120pt（大赢展示）

**预期收益**：减少 30-40% 字体变体

### 优先级 2：清理未使用资源（中等收益）

#### 2.1 清理未使用字体

- 生成完整的字体使用报告
- 识别零引用的字体文件
- 清理未使用字体

#### 2.2 大纹理优化

- 评估 1MB+ 的特效字体是否必要
- 考虑使用更小的尺寸或压缩

### 优先级 3：合批优化（运行时性能）

#### 3.1 字体纹理合并（Atlas 合并）

**目标**：将多个小字体纹理合并为单一 Atlas，减少纹理切换

```text
合并前：
  white_30.png (64KB) → 1 Draw Call
  white_48.png (80KB) → 1 Draw Call
  gold_30.png  (70KB) → 1 Draw Call
  共 3 次 Draw Call

合并后：
  common_fonts_atlas.png (200KB) → 1 Draw Call
  共 1 次 Draw Call
```

**实施步骤**：
1. 使用 TexturePacker 合并常用字体纹理
2. 更新 .fnt 文件中的纹理坐标映射
3. 修改字体加载路径

**预期收益**：减少 50-70% 字体相关 Draw Call

#### 3.2 渲染顺序优化

**原则**：将使用相同字体的 Label 在渲染树中相邻排列

```text
优化前：
  Layer
    ├─ Label A (font_white)
    ├─ Sprite X
    ├─ Label B (font_gold)
    ├─ Sprite Y
    └─ Label C (font_white)  // 无法与 A 合批

优化后：
  Layer
    ├─ Label A (font_white)
    ├─ Label C (font_white)  // 可与 A 合批
    ├─ Sprite X
    ├─ Sprite Y
    └─ Label B (font_gold)
```

#### 3.3 字体复用策略

**统一常用字体**：

| 用途 | 推荐字体 | 替代 |
|------|---------|------|
| 白色文本 | `white_48.fnt` | 替代 white_30/32/34/40/44 |
| 金色数字 | `gold_font_48pt.fnt` | 替代 gold_30/40/54/60/64 |
| 按钮文字 | `button_white_30.fnt` | 统一使用 |

**收益**：减少同屏字体种类 → 减少 Draw Call

#### 3.4 动态文本优化

**问题**：频繁 `setString()` 导致 Sprite 重建

**方案**：
- 使用对象池复用 Sprite 对象
- 避免每帧更新文本，使用节流

---

## 预期收益汇总

| 维度 | 当前 | 优化后 | 节省 |
|------|------|--------|------|
| 文件数量 | 4,060 | ~2,500 | 38% |
| 存储空间 | 219 MB | 140 MB | 36% |
| 下载体积 | - | - | 20-30% |
| Draw Call | - | - | 50-70% |

---

**生成日期**: 2024-11-27
**数据来源**: res_oldvegas 目录分析
