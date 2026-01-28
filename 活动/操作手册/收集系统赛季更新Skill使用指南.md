# 收集系统赛季更新 Skill 使用指南

> 全自动完成 CardSystem 赛季更新，零参数启动，智能推断配置

## 一、Skill 简介

### 1.1 功能说明

`card-system-season-update` Skill 用于**全自动**完成收集系统（CardSystem）的赛季更新操作。

**核心特性**：
- **零参数启动** - 无需任何参数，从分支名自动识别风格
- **智能推断** - 自动从代码读取当前赛季，推断新旧赛季 ID
- **自动获取配置** - 从 Google Sheets 配置表格自动提取数据
- **静默执行** - 音效/视频缺失时自动跳过，旧资源自动清理
- **一键完成** - 代码修改、资源生成、发布、构建全流程自动化

### 1.2 适用场景

适用于以下情况：
- ✅ 收集系统赛季更新（S21 → S22）
- ✅ 多风格支持（CV/DH/VS/DHX）
- ✅ 配置文件自动生成
- ✅ 旧资源自动清理
- ✅ 完整的发布和构建流程

### 1.3 Skill 位置

```
WorldTourCasino/.claude/skills/card-system-season-update/
```

---

## 二、快速开始

### 2.1 启动命令

在正确的分支上执行：

```bash
/card-system-season-update
```

**无需任何参数！** 系统会自动完成所有操作。

### 2.2 前置条件

执行前确保：

1. **分支名称正确** - 必须符合命名规范：
   - CV: `classic_vegas_cvs_v*`
   - DH: `classic_vegas_dbh_v*`
   - VS: `classic_vegas_vs_v*`
   - DHX: `classic_vegas_dhx_v*`

2. **配置表格已准备** - 新赛季的卡牌计划文档已添加到配置表格：
   - 表格 ID: `1Xy1cYB92XAhIsDXUIUId38HRA2gHcfOrQC9W2NISjZM`
   - 工作表: `收集赛季安排`

3. **Google Sheets 权限** - 表格已共享给 Service Account：
   ```
   ghoststudio-sheets-api@sheets-api-437103.iam.gserviceaccount.com
   ```

### 2.3 执行示例

**场景**：在 CV 风格分支上更新到 S22 赛季

```bash
# 1. 切换到正确的分支
git checkout classic_vegas_cvs_v877

# 2. 执行 Skill
/card-system-season-update

# 3. 等待自动完成（约 2-3 分钟）
```

**输出示例**：
```
🎯 收集系统赛季更新 - 全自动模式

当前分支: classic_vegas_cvs_v877
风格: CV (Classic Vegas)
当前赛季: S21
新赛季: S22
旧赛季: S21

配置文档: Q3'25-Slots-收集S22赛季需求-策划
Spreadsheet ID: 1LkOg3XJCzpillkdQSQ-THPTfgz-iRi1EAnfAz0Sl1z0

开始执行...

✅ 代码调整完成（CardSystemMan.js）
✅ 配置获取完成（20 个卡册，200 张卡片）
⚠️  赛季视频缺失，已跳过
✅ 资源生成完成
✅ 旧资源清理完成（9 项）
✅ 资源发布完成（4 组）
✅ 构建验证完成
```

---

## 三、自动化流程

### 3.1 流程概览

```
1. 分支名识别风格
    ↓
2. 智能推断赛季参数
    ↓
3. 代码调整（修改 CardSystemMan.js）
    ↓
4. 配置获取（从 Google Sheets）
    ↓
5. 资源检查（音效 & 视频）
    ↓
6. 资源生成（配置文件）
    ↓
7. 资源清理（删除旧赛季）
    ↓
8. 资源发布（4 组资源）
    ↓
9. 构建和验证
```

### 3.2 分支名映射

| 分支名模式 | 风格 | 资源目录 | 说明 |
|-----------|------|---------|------|
| `classic_vegas_cvs_v*` | CV | oldvegas | Classic Vegas |
| `classic_vegas_dbh_v*` | DH | doublehit | Double Hit |
| `classic_vegas_vs_v*` | VS | vegasstar | Vegas Star |
| `classic_vegas_dhx_v*` | DHX | doublex | Double X |

### 3.3 智能推断逻辑

**从代码读取当前赛季**：
```javascript
// src/social/model/CardSystemMan.js
if (game.switchMan.isHitTheme(game.themeName.THEME_OLD_VEGAS)) {
    this.maxSeasonId = 21;  // 当前赛季
}
```

**自动推断新旧赛季**：
- 当前赛季：21
- 新赛季：22（当前 + 1）
- 旧赛季：21（用于清理）

**从配置表格获取 Spreadsheet ID**：
- 查找：`收集赛季安排` 工作表
- 提取：S22 行的卡牌计划文档链接
- 解析：Spreadsheet ID

### 3.4 资源发布组

Skill 自动发布以下 4 组资源：

1. **casino/card_system** - 配置文件、卡册图标、卡片图片
2. **card_system_lagload** - BGM、背景图、视频等延迟加载资源
3. **dynamic_feature/card_system** - 动态加载的卡片资源
4. **激励卡包图标** - S11 版本的图标资源（统一使用）

---

## 四、生成的配置文件

### 4.1 card_names.json

**位置**：
```
WorldTourCasinoResource/{资源目录}/Resources/casino/card_system/cards/s_{赛季ID}/card_names.json
```

**结构**：
```json
{
  "220101": {
    "name": "卡片名称",
    "banner": "card_blue_banner",
    "border": "card_orange_border",
    "playerWordTitle": "卡片名称",
    "playerWordDesc": "玩家寄语内容（智能换行）"
  },
  "220201": {
    "name": "卡片名称",
    "banner": "card_pink_banner",
    "border": "card_green_border"
  }
}
```

**字段说明**：
- `cardId` - 卡片 ID（从程序使用工作表）
- `name` - 卡片名称
- `banner` - 横幅样式（去掉 .png 后缀）
- `border` - 边框样式（去掉 .png 后缀）
- `playerWordTitle` - 卡片名称（**仅第一个卡册包含**）
- `playerWordDesc` - 玩家寄语（**仅第一个卡册包含**，智能换行）

**智能换行规则**：
- 每约 53 字符添加一个 `\n`
- 如果在单词中间，在单词之前添加换行符
- 示例：
  ```
  "It didn't snow much where we lived in Mississippi,\nthis is a picture of my dad when it did snow"
  ```

### 4.2 album_name_config.json

**位置**：
```
WorldTourCasinoResource/{资源目录}/Resources/casino/card_system/album/s_{赛季ID}/album_name_config.json
```

**结构**：
```json
{
  "2201": {"name": "Yester's Hometown"},
  "2202": {"name": "Vanished Glory"},
  "2203": {"name": "Emerald Road"},
  ...
  "2220": {"name": "卡册名称20"}
}
```

**数据来源**：
- 从主题工作表提取：`{风格} S{赛季ID}卡牌详情`
- 示例：`CV S22卡牌详情`
- 提取 20 个卡册名称

---

## 五、资源清理

### 5.1 自动清理范围

Skill 自动搜索并删除所有包含旧赛季 ID 的文件和目录：

| 类型 | 路径模式 | 说明 |
|-----|---------|------|
| 卡册配置 | `casino/card_system/album/s_{旧赛季ID}/` | 配置和图标 |
| 卡片配置 | `casino/card_system/cards/s_{旧赛季ID}/` | 配置和图片 |
| 动态资源 | `dynamic_feature/card_system/cards/s_{旧赛季ID}/` | 动态卡片 |
| 加载图 | `casino/card_system/entrance/card_loading_s{旧赛季ID}.png` | 入口图片 |
| 弹窗图 | `casino/card_system/guide/effects/poster_popup_card_new_album_s{旧赛季ID}.png` | 新卡册弹窗 |
| 背景音乐 | `card_system_lagload/mp3/cardsystem_bgm_s{旧赛季ID}.mp3` | BGM |
| 赛季视频 | `card_system_lagload/season_main/card_season_video_s{旧赛季ID}.mp4` | 赛季视频 |
| 赛季背景 | `card_system_lagload/card_season_bg_s{旧赛季ID}.jpg` | 背景图 |
| 教程资源 | `card_system_lagload/howtoplay/card_how_to_play_s{旧赛季ID}/` | 教程目录 |
| 教程CCB | `card_system_lagload/howtoplay/card_how_to_play_s{旧赛季ID}.ccb` | 教程文件 |

### 5.2 清理策略

- **自动决策** - 不询问用户，直接删除
- **智能搜索** - 使用 `find` 命令搜索所有匹配项
- **完整删除** - 目录使用 `shutil.rmtree()`，文件使用 `os.remove()`
- **记录日志** - 删除的文件列表会在摘要中显示

### 5.3 清理示例

```
✅ 已删除 9 项资源

  • dynamic_feature/card_system/cards/s_21/ (目录)
  • casino/card_system/cards/s_21/ (目录)
  • casino/card_system/album/s_21/ (目录)
  • card_system_lagload/card_season_bg_s21.jpg
  • card_system_lagload/howtoplay/card_how_to_play_s21/ (目录)
  • card_system_lagload/howtoplay/card_how_to_play_s21.ccb
  • card_system_lagload/mp3/cardsystem_bgm_s21.mp3
  • casino/card_system/guide/effects/poster_popup_card_new_album_s21.png
  • casino/card_system/entrance/card_loading_s21.png
```

---

## 六、完成摘要

### 6.1 摘要示例

```
✅ 收集系统赛季更新完成

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
执行摘要
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

分支: classic_vegas_cvs_v877
风格: CV (Classic Vegas)
赛季: S21 → S22

✅ 已完成：
  ✓ 代码调整（CardSystemMan.js：maxSeasonId = 22）
  ✓ 配置获取（从 Google Sheets）
  ✓ 资源生成（card_names.json, album_name_config.json）
  ✓ 资源清理（删除 S21 旧资源）
  ✓ 资源发布（4 组资源发布完成）
  ✓ 构建验证（build_local_oldvegas.sh）

⚠️  需要手动处理：
  • 赛季视频：card_season_video_s22.mp4（缺失）

  请联系美术提供这些资源，然后手动添加到：
  WorldTourCasinoResource/oldvegas/Resources/card_system_lagload/season_main/

📋 已删除旧资源：
  • casino/card_system/album/s_21/
  • casino/card_system/cards/s_21/
  • card_system_lagload/mp3/cardsystem_bgm_s21.mp3
  • card_system_lagload/season_main/card_season_video_s21.mp4

📦 配置文件位置：
  • WorldTourCasino/res_oldvegas/casino/card_system/album/s_22/album_name_config.json
  • WorldTourCasino/res_oldvegas/casino/card_system/cards/s_22/card_names.json

📊 配置数据：
  • 卡册数量：20
  • 卡片数量：200
  • 背景音乐：✅ cardsystem_bgm_s22.mp3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎮 下一步：
  1. 启动游戏测试 S22 赛季
  2. 检查卡册名称和卡片显示
  3. 验证玩家寄语功能
  4. 如需补充音频/视频资源，联系美术团队

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 6.2 摘要字段说明

| 区块 | 说明 |
|-----|------|
| **执行摘要** | 分支、风格、赛季变更信息 |
| **✅ 已完成** | 成功完成的步骤清单 |
| **⚠️ 需要手动处理** | 缺失资源提示（不影响流程） |
| **📋 已删除旧资源** | 清理的文件列表 |
| **📦 配置文件位置** | 生成的配置文件路径 |
| **📊 配置数据** | 统计信息 |
| **🎮 下一步** | 后续验证步骤 |

---

## 七、故障排查

### 7.1 无法识别风格

**现象**：
```
❌ 无法从分支名识别风格
当前分支: feature/card-system-update
```

**原因**：当前分支名不符合命名规范

**解决**：
```bash
# 切换到正确的分支
git checkout classic_vegas_cvs_v877  # CV
git checkout classic_vegas_dbh_v875  # DH
git checkout classic_vegas_vs_v800   # VS
git checkout classic_vegas_dhx_v850  # DHX
```

### 7.2 Google Sheets 权限错误

**现象**：
```
❌ Google Sheets 权限错误（403）
```

**原因**：表格未共享给 Service Account

**解决**：
1. 打开表格
2. 点击右上角「共享」按钮
3. 添加邮箱：`ghoststudio-sheets-api@sheets-api-437103.iam.gserviceaccount.com`
4. 权限设为「查看者」
5. 点击「发送」

### 7.3 未找到赛季配置

**现象**：
```
❌ 未找到 S22 的配置记录
```

**原因**：配置表格中没有新赛季的记录

**解决**：
1. 打开配置表格：`1Xy1cYB92XAhIsDXUIUId38HRA2gHcfOrQC9W2NISjZM`
2. 在「收集赛季安排」工作表中添加新赛季行
3. 添加卡牌计划文档链接（使用 Smart Chips）
4. 重新运行 Skill

### 7.4 资源发布失败

**现象**：
```
Error: No plugin exists using the extension ccbi.
```

**原因**：新赛季目录通常不包含 .ccb 文件

**处理**：
- ✅ 正常现象，继续执行即可
- ✅ 资源的 rsync 部分已成功完成

### 7.5 构建失败

**现象**：
```
❌ 构建失败
```

**排查步骤**：
1. 检查代码修改是否正确：
   ```bash
   grep "maxSeasonId" src/social/model/CardSystemMan.js
   ```

2. 检查配置文件是否存在：
   ```bash
   ls -lh res_oldvegas/casino/card_system/album/s_22/album_name_config.json
   ls -lh res_oldvegas/casino/card_system/cards/s_22/card_names.json
   ```

3. 手动运行构建脚本查看详细错误：
   ```bash
   cd scripts
   ./build_local_oldvegas.sh
   ```

---

## 八、重要注意事项

### 8.1 plist 文件处理

**自动跳过**，由美术（@李强）处理：
```
WorldTourCasinoResource/{资源目录}/Resources/casino/card_system/entrance/card_system_entrance.plist
```

**原因**：从 S19 赛季开始，此资源由美术团队维护

### 8.2 激励卡包图标

**统一使用 S11 版本**：
- `activity_card_wonder_pack_s11.plist`
- `activity_card_wonder_pack_s11.png`

**注意**：
- 不创建新赛季的图标文件
- 每次发布时需要包含（美术可能会修改）

### 8.3 音效和视频

**处理策略**：
- ✅ 存在 → 自动发布
- ⚠️ 缺失 → 跳过并在摘要中提示

**后续补充**：
1. 联系美术团队提供资源
2. 手动添加到资源目录
3. 重新发布 `card_system_lagload`

### 8.4 玩家寄语功能

**仅第一个卡册（前 10 张卡）包含玩家寄语**：
- `playerWordTitle` - 卡片名称
- `playerWordDesc` - 玩家寄语内容（智能换行）

**代码依赖**：
- `src/social/controller/card_system/card_item/CardInfoController.js:85`
- `src/social/entity/card_system/CardState.js:42`

### 8.5 多风格支持

Skill 支持所有 4 种风格，每种风格独立更新：

| 风格 | 资源目录 | 构建脚本 |
|------|---------|---------|
| CV | oldvegas | build_local_oldvegas.sh |
| DH | doublehit | build_local_doublehit.sh |
| VS | vegasstar | build_local_vegasstar.sh |
| DHX | doublex | build_local_doublex.sh |

**注意**：同一时间只更新一个风格

---

## 九、技术细节

### 9.1 项目结构

```
Projects/
├── WorldTourCasino/              # 主项目（代码）
│   ├── src/social/model/CardSystemMan.js
│   ├── res_oldvegas/             # CV 风格资源（发布目标）
│   ├── res_doublehit/            # DH 风格资源（发布目标）
│   ├── res_vegasstar/            # VS 风格资源（发布目标）
│   └── res_doublex/              # DHX 风格资源（发布目标）
│
└── WorldTourCasinoResource/      # 资源项目
    ├── PlugIns/publishCCB.py     # CocosBuilder 发布工具
    ├── oldvegas/Resources/       # CV 风格资源（源文件）
    ├── doublehit/Resources/      # DH 风格资源（源文件）
    ├── vegasstar/Resources/      # VS 风格资源（源文件）
    └── doublex/Resources/        # DHX 风格资源（源文件）
```

### 9.2 Google Sheets API

**Service Account**：
```
ghoststudio-sheets-api@sheets-api-437103.iam.gserviceaccount.com
```

**认证文件**：
```
WorldTourCasino/scripts/ggs/server_secret.json
```

**配置表格**：
- ID: `1Xy1cYB92XAhIsDXUIUId38HRA2gHcfOrQC9W2NISjZM`
- 工作表: `收集赛季安排`

**卡牌计划表格结构**：
- 主题工作表: `{风格} S{赛季ID}卡牌详情`（卡册名称）
- 程序使用工作表: `程序使用`（卡片配置）

### 9.3 发布工具

**发布脚本**：
```
WorldTourCasinoResource/PlugIns/publishCCB.py
```

**功能**：
1. 资源同步（rsync）
2. CCB 编译（.ccb → .ccbi）
3. 资源检查（尺寸、内存、引用等）
4. 热更新列表生成

**环境变量**：
```bash
COCOS_X_ROOT=/Users/mac/Documents/Projects/WorldTourCasino/frameworks
```

---

## 十、相关文档

- [收集系统资源发布指南](http://localhost:5173/WTC-Docs/活动/操作手册/收集系统资源发布指南) - 资源发布技术细节
- [新版收集系统SOP操作手册](http://localhost:5173/WTC-Docs/活动/操作手册/新版收集系统SOP操作手册) - 完整的赛季更新流程

---

**创建日期**：2026-01-28
**维护者**：WTC Dev Team
**版本**：v1.0
