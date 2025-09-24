# 新版收集系统SOP操作手册(s19)

> 旧版操作文档：Q2'24-Slots-收集系统赛季更新操作-程序.pdf

## 1、代码调整

**PATH**: `src/social/model/CardSystemMan.js`

```javascript
this.maxSeasonId = 19; //修改赛季ID
```

## 2、资源调整

### 2.1 音效&视频

#### 背景音乐
- 路径：`card_system_lagload/mp3/`
- 文件命名规则：`cardsystem_bgm_sXX.mp3`
- 示例：19赛季 → `card_system_lagload/mp3/cardsystem_bgm_s19.mp3`

#### 赛季视频
- 路径：`card_system_lagload/season_main/`
- 文件命名规则：`card_season_video_sXX.mp4`
- 示例：21赛季 → `card_system_lagload/season_main/card_season_video_s21.mp4`

### 2.2 配置文件

#### 配置文件路径
- **卡册名称配置**：`casino/card_system/album/s_XX/album_name_config.json`
- **卡片配置**：`casino/card_system/cards/s_XX/card_names.json`

> **注意**：如果没有相应的配置文件，可从之前的老赛季相应的位置复制。

#### 示例：S19赛季
- 卡册名称配置：`casino/card_system/album/s_19/album_name_config.json`
- 卡片配置：`casino/card_system/cards/s_19/card_names.json`

> **重要**：新赛季的卡册和卡片的配置文件找策划去要，目前为 @马新蓝

### 2.2.1 修改card_names.json

需要替换的字段：
- **ID**：卡片唯一标识
- **name**：卡片名称
- **playerWordTitle**：玩家寄语标题（第一卡册独有）
- **playerWordDesc**：玩家寄语描述（第一卡册独有）

#### 字段说明
- `name`：卡片名称
- `playerWordTitle`：一般也为卡片名称
- `playerWordDesc`：新赛季文档中的玩家寄语
- `banner`：卡册卡片上的飘带
- `border`：卡册卡片后面的底框

### 2.2.2 修改album_name_config.json

> **Tips**：可以使用正则表达式快速清理之前的配置。按住鼠标滚轮拖动，可以同时修改多行。⚠️ **注意**：一定要找对路径，修改资源文件中的json而不是发布后的，否则再次发布时修改会被覆盖掉。

#### 玩家寄语处理
寄语 `playerWordDesc` 在实际使用时，存在过长需要手动换行的情况，这时可以通过修改 `CardInfoController.js` 文件中的 `initCard` 方法，根据情况进行调试，每次只会生效一条，修改后，再复制回 `card_names.json` 的 `playerWordDesc` 中。

### 2.3 赛季资源处理

#### 2.3.1 清理老资源，发布新资源

在以下路径中查找上个赛季 `s_XX` 的资源，并且删除掉，并检查新赛季资源：
- `dynamic_feature/card_system`
- `casino/card_system`
- `card_system_lagload`

#### 2.3.2 处理plist文件

`casino/card_system/entrance/card_system_entrance.plist` 解包，删除旧资源，再重新打包plist（这里也可以找美术处理）

### 2.4 闪卡和限时卡册

> s19赛季，跟美术@李强咨询过，这部分资源后面由美术那边进行替换和添加处理，程序可以不用操心这个地方了。

## 3、资源部署

### 3.1 赛季主体资源
- `card_system_lagload`
- `casino/card_system`
- `dynamic_feature/card_system`

### 3.2 coupon资源
- `slot/lobby/coupon/card_pack_newseason_cardpack`（coupon）

### 3.3 激励卡包图标资源
- `common/activity/activity_card_wonder_pack_s11.plist`
- `common/activity/activity_card_wonder_pack_s11.png`

## 4、其他问题

### 4.1 引用资源报错
一般是因为ccb引用的是之前赛季的资源，查找对应位置修改为当前赛季即可。

### 4.2 board、item报错
运行之后打开卡册，发现会出现board，item之类的报错，可能是由于配置文件导致的，检查 `album_name_config.json` 和 `card_names.json` 两个配置是否为最新赛季。

### 4.3 数据接口
- **数据接口**：`s2c_get_game_feature`

### 4.4 限时卡册图标
- **路径**：`card_system_lagload/card_limited_set_2024_new_year/card_limited_set_2024_new_year_cards_bg.png`

## 总结

新版收集系统SOP操作主要包含以下几个关键步骤：

1. **代码调整**：修改 `CardSystemMan.js` 中的赛季ID
2. **资源处理**：更新音效、视频、配置文件
3. **资源部署**：部署主体资源、coupon资源、激励卡包图标
4. **问题排查**：处理引用报错、配置错误等常见问题

按照本手册的步骤操作，可以顺利完成新赛季收集系统的更新工作。