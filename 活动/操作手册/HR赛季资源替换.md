# HR赛季资源替换

## DH：统一 Bundle 发布

DH 的赛季更新通过 `WorldTourCasinoResource/PlugIns/featureBundlePublish.py` 完成冻结、隔离转换、完整闭包验证与本地事务。不要先修改正式 `WorldTourCasino/src/social/controller/high_rollers_lounge/v2/HR2Constants.js`，也不要先把新资源单独发布到正式树。CV/Native 的既有操作见后面的原流程，本次接入不改变它们的发布入口。

### 准备全部输入

1. 明确当前赛季 N、目标赛季和提前准备或切换模式。`supportedHrSeasons` 必须来自明确配置或已验证 descriptor 的有限样本，不能扫描美术目录取最大赛季。
2. 在 `WorldTourCasinoResource/doublehit/Resources/casino/high_rollers_lounge/hr_2` 准备目标赛季。八幅画册分别需要普通和 `_small` CCB；FAQ 使用 `hr_2_how_to_play_sN.ccb`，S1 使用 `hr_2_how_to_play.ccb`。FAQ 图片和引用必须属于目标赛季。
3. 更新 `hr_2_final_prize_view.ccb`，控制器必须为 `HR2FinalPrizeController`，保留窗口内每季必须有唯一的根控制器绑定 `_bg_sN`。提前准备 N+1 时，N、N-1、N+1 的绑定都必须保留。
4. 从策划取得八个画册名称及最后一项排名占位，`artNames` 必须恰好九项，最后一项为单个空格 `" "`。由准备器生成 `HR2Constants.ArtName` 候选，`ArtCount` 保持 8；工具不修改服务端的活动赛季。
5. 汇总本次全部新增或修改源文件为 `explicitSourcePaths`，包括本次修改的 CCB 及其图片。路径相对 `doublehit/Resources`，CCB 使用 `.ccb`，HD 图片保留源 `_hd` 名字；`manifest.requiredAssets` 则使用普通发布产物路径，例如 `.ccbi`。

首次接入以代码工程现有普通/HD 字节为准。选中目录只扩大完整闭包的准备范围，不等于授权覆盖全部历史源差异；明确文件清单及相对上一成功源快照的新增变化才进入转换。失败不得回退旧插件覆盖资源。

### 请求文件与命令

`--request` 接收 JSON 文件，顶层字段为 `bundleIds`、`explicitSourcePaths`、`supportedHrSeasons`、`seasonPreparations`。不要在外部 JSON 中增加 `request` 包装层；插件内部会转换到 `options.request.seasonPreparations`。

以下仅展示 S18 提前准备 S19 的结构。实际名称、支持季和文件清单必须按本次输入填写，示例中的一个 FAQ 路径不是完整赛季更新清单：

```json
{
  "bundleIds": ["feature.high-roller"],
  "explicitSourcePaths": [
    "casino/high_rollers_lounge/hr_2/hr_2_how_to_play_s19.ccb"
  ],
  "supportedHrSeasons": [17, 18, 19],
  "seasonPreparations": [
    {
      "domain": "high-roller",
      "currentSeason": 18,
      "targetSeason": 19,
      "mode": "prepare",
      "manifest": {
        "requiredAssets": [],
        "artNames": ["画册一", "画册二", "画册三", "画册四", "画册五", "画册六", "画册七", "画册八", " "]
      }
    }
  ]
}
```

`requiredAssets` 数组必须存在，即使为空，准备器仍会自动检查十六份画册产物、FAQ、最终大奖及其图片引用。`currentSeason`、`targetSeason` 必须为明确的正整数，目标不能早于当前季，HR 配置不能跳过中间索引。

先配置 `WTC_RESOURCE_ROOT`、`WTC_CODE_ROOT` 指向各自仓库，`WTC_FEATURE_REQUEST` 指向临时请求 JSON，`WTC_FEATURE_STAGE` 指向仓库外不存在或为空的隔离目录。需要可用的 Python 2.7、Node、既有 CCB 编译器和 Pillow；命令不会安装依赖。

```bash
python2.7 "$WTC_RESOURCE_ROOT/PlugIns/featureBundlePublish.py" \
  --fullpath "$WTC_RESOURCE_ROOT/doublehit/Resources/casino/high_rollers_lounge" \
  --rootpath "$WTC_RESOURCE_ROOT/doublehit/Resources" \
  --appdir res_doublehit \
  --code-root "$WTC_CODE_ROOT" \
  --request "$WTC_FEATURE_REQUEST" \
  --working-root "$WTC_FEATURE_STAGE" \
  --mode prepare
```

命令行 `--mode prepare` 只生成隔离候选和报告，必须得到 accepted 且 `replayVerified: true`。需要正式落地时，按已授权范围使用**另一个空隔离目录**执行同一命令的 `--mode promote`；入口会重新冻结并验证输入，将普通/HD、HR 配置、manifest、Catalog 与成功状态同批写入。它不部署资源服，也不切换服务端赛季。

赛季项的 `mode` 与命令行模式独立：`prepare` 提前准备并保留当前 N、N-1 和目标季；`switch` 按目标季与其上一季计算保留窗口。HR 在两种赛季模式下均可生成目标季 `ArtName` 配置候选，只有外层 promote 才落到正式代码。

### 关联资源与清理

- 卡册与 HR 可放入一个请求，`seasonPreparations` 分别使用 `domain: "card-system"` 和 `domain: "high-roller"`，每个领域最多一项。先准备全部输入，再一次同批处理，不能先改正式卡册常量或分多次目录发布。
- 卡册 S11 图标 `common/activity/activity_card_wonder_pack_s11.{plist,png}` 有本次修改时，把对应源文件加入明确更新清单，并把 HR 加入同一 `bundleIds`；图标沿用原名，不创建新季名称。
- 两条公共转盘音效自动关联 `shared.feature-effects`。HR 自动关联大厅商店维护的 `shared.store-info`，供大厅和 HR 共用；七个具名资源保持代码工程字节，四条原 HR 资源迁出且不复制，公共包依赖 `startup.login`，不反向依赖 HR。
- 提前准备不清理；切换后的保留窗口为目标 N 与 N-1。成功生成后会从冻结资源枚举精确旧季文件，并结合实际引用和 Catalog 输出 `cleanup-assessment.json`；完整报告随成功 state 同事务保存，临时目录删除后仍可追溯。未取得完整全域反向引用证明的旧文件逐项保留，**不会自动删除**。禁止按赛季通配符删除，也不能因源工程缺文件就删除代码工程文件。
- `card_system_archive/**`、`coupon/**`、废弃 CCB 和独立宣发资源不处理，不作为延期任务。

验收记录实际请求、明确文件集合、保留原因、双重准备结果和事务结果。发布后验证 HR 冷启动、热重入、FAQ、最终大奖、当前/上一季，以及大厅和 HR 的商店详情入口；仅 prepare 成功不能报告已发布或已切季。

## CV/Native：既有操作流程

以下保留原有资源服、CCB 和配置操作顺序，不用于上面的 DH Bundle 发布。

## 1、发布资源到资源服

在资源工程中找到 `casino/high_rollers_lounge/hr2/s(n)`，发布到资源服。

## 2、处理FAQ资源

### 操作步骤
1. **复制FAQ文件**：复制一个faq文件（`how_to_play.ccb`）
2. **文本编辑器打开**：使用文本编辑器打开该文件
3. **搜索替换**：搜索替换赛季资源名

### 资源命名示例
- `hr_2_1_s4.png`
- `hr_2faq_5_s4.png`

## 3、处理最终大奖资源

### 操作步骤
1. **打开CCB文件**：使用cocosbuilder打开 `final_prize_view.ccb`
2. **添加新赛季节点**：添加新赛季节点
3. **注意事项**：注意绑定

> ⚠️ **重要**：确保新添加的节点正确绑定到相应的控制器

## 4、修改画册配置

### 代码位置
在代码工程中找到 HR 配置：`WorldTourCasino/src/social/controller/high_rollers_lounge/v2/HR2Constants.js`。

### 操作内容
添加赛季画册名称（找策划要）

> **注意**：最后的一个空格是hr rank的名称，不能删除！

## 5、清理旧资源

### 资源管理策略
- **删除旧赛季资源**
- **保险起见保留上赛季资源**

### 推荐做法
为了避免意外情况，建议：
1. 先备份当前运行的上一赛季资源
2. 再删除更早期的旧赛季资源
3. 部署新赛季资源

## HR赛季更新流程总结

### 核心步骤
1. **资源发布**：将新赛季资源发布到资源服
2. **FAQ更新**：替换FAQ中的赛季资源引用
3. **最终大奖**：在CCB中添加新赛季最终大奖节点
4. **画册配置**：更新HR2Constants中的画册名称
5. **资源清理**：删除旧资源，保留上赛季作为备份

### 注意事项
- 确保资源路径正确
- FAQ资源替换要完整
- CCB节点绑定要正确
- 画册名称格式要准确（注意空格）
- 资源清理要谨慎，保留必要备份

### 相关文件
- FAQ文件：`how_to_play.ccb`
- 最终大奖文件：`final_prize_view.ccb`
- HR配置：`WorldTourCasino/src/social/controller/high_rollers_lounge/v2/HR2Constants.js`
- 资源路径：`casino/high_rollers_lounge/hr2/s(n)`

通过按照此流程操作，可以顺利完成HR赛季的资源替换工作。
