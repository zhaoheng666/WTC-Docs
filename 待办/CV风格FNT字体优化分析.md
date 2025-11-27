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

## 优化建议

### 优先级 1：高收益

#### 1.1 建立全局共享字体库

**目标**：消除跨活动重复

```text
res_oldvegas/common/fonts/shared/     ← 新建共享目录
  ├─ jackpot_fever_48_green.fnt + .png
  ├─ jackpot_fever_48_blue.fnt + .png
  ├─ 140_3.fnt + .png
  └─ hr_wheel_white_34.fnt + .png

所有活动通过路径映射引用，而非各自存储副本
```

**预期收益**：减少 30-40% 活动字体文件

#### 1.2 字体尺寸精简

**当前问题**：存在过多尺寸变体（24, 28, 30, 32, 34, 40, 44, 48, 50, 60, 80, 100, 120, 150, 160pt）

**建议保留**：
- 小号：30pt（按钮、提示）
- 中号：48pt（正文、标签）
- 大号：80pt（标题、奖励）
- 特大：120pt（大赢展示）

**预期收益**：减少 30-40% 字体变体

### 优先级 2：中等收益

#### 2.1 清理未使用字体

- 生成完整的字体使用报告
- 识别零引用的字体文件
- 清理未使用字体

#### 2.2 大纹理优化

- 评估 1MB+ 的特效字体是否必要
- 考虑使用更小的尺寸或压缩

---

## 预期收益汇总

| 维度 | 当前 | 优化后 | 节省 |
|------|------|--------|------|
| 文件数量 | 4,060 | ~2,500 | 38% |
| 存储空间 | 219 MB | 140 MB | 36% |
| 下载体积 | - | - | 20-30% |

---

**生成日期**: 2024-11-27
**数据来源**: res_oldvegas 目录分析
