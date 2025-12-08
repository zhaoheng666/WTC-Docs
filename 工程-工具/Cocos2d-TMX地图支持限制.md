# Cocos2d-html5 TMX 地图支持限制

## 背景

在 Words of Fortune 活动中测试使用 Tiled Map Editor 创建的 TMX 地图时，发现 Cocos2d-html5 引擎对 TMX 格式的支持存在多项限制。

## 测试环境

- **引擎**: Cocos2d-html5 v3.13-lite-wtc
- **地图编辑器**: Tiled Map Editor
- **测试文件**: `res_oldvegas/activity/words_of_fortune/chapter1/map.tmx`

## 引擎限制汇总

| TMX 特性 | 支持状态 | 说明 |
|---------|---------|------|
| `<tileset>` + sprite sheet | ✅ 支持 | 标准用法，基于 SpriteBatchNode 渲染 |
| `<tileset>` Collection of Images | ❌ 不支持 | 每个 tile 独立图片的格式 |
| `<layer>` (tile 层) | ✅ 支持 | 正常解析渲染 |
| `<objectgroup>` | ✅ 支持 | 解析为 TMXObjectGroup |
| `<imagelayer>` | ❌ 不支持 | 引擎完全不解析此元素 |
| TMX version 1.0 | ✅ 支持 | 推荐使用 |
| TMX version 1.0.0+ | ⚠️ 警告 | 会输出版本不支持警告 |

## 问题详解

### 1. Collection of Images Tileset 不支持

**问题描述**：Tiled 支持两种 tileset 类型：
- **基于图像的 tileset**：所有 tile 在一张 sprite sheet 上
- **Collection of Images**：每个 tile 是独立的图片文件

Cocos2d 只支持第一种。

**TMX 格式差异**：

```xml
<!-- ✅ 基于图像的 tileset（引擎支持） -->
<tileset firstgid="1" name="tiles" tilewidth="256" tileheight="128" tilecount="3" columns="3">
  <image source="tileset.png" width="768" height="128"/>
</tileset>

<!-- ❌ Collection of Images（引擎不支持） -->
<tileset firstgid="1" name="tile1" tilewidth="256" tileheight="128" tilecount="1" columns="0">
  <tile id="0">
    <image width="256" height="128" source="tile1.png"/>
  </tile>
</tileset>
```

**原因分析**（`CCTMXXMLParser.js` 第 645-646 行）：

```javascript
var image = selTileset.getElementsByTagName('image')[0];
var imagename = image.getAttribute('source');
```

引擎假设 `<image>` 直接在 `<tileset>` 下，而 Collection of Images 的图片在 `<tile><image/></tile>` 内部。

**解决方案**：
1. 在 Tiled 中将独立图片合并为一张 sprite sheet
2. 或手动实现 tile 层渲染（见下方代码）

### 2. ImageLayer 完全不支持

**问题描述**：TMX 的 `<imagelayer>` 元素用于添加背景图片，但 Cocos2d 的 XML 解析器完全没有处理这个元素。

**验证方法**：

```bash
grep -r "imagelayer" frameworks/cocos2d-html5/cocos2d/tilemap/
# 输出为空，证明没有任何相关代码
```

**原因分析**：`CCTMXXMLParser.js` 只解析以下元素：
- `<tileset>` (第 611-676 行)
- `<layer>` (第 678-764 行)
- `<objectgroup>` (第 766-840 行)

**解决方案**：手动解析 XML 并创建 Sprite 加载 imagelayer。

### 3. TMX 版本警告

**问题描述**：使用 Tiled 新版本导出的 TMX 文件版本号为 `1.0.0`，会触发警告：

```
cocos2d: TMXFormat: Unsupported TMX version: 1.0.0
```

**原因分析**（`CCTMXXMLParser.js` 第 562-563 行）：

```javascript
if (version !== "1.0" && version !== null)
    cc.log("cocos2d: TMXFormat: Unsupported TMX version:" + version);
```

**解决方案**：将 TMX 文件的 `version` 属性改为 `1.0`：

```xml
<map version="1.0" orientation="staggered" ...>
```

## 解决方案代码

### 方案 A：使用引擎原生 TMXTiledMap + 手动加载 imagelayer

适用于：tileset 已合并为 sprite sheet 的情况

```javascript
WordsOfFortuneMainUIController.prototype.testLoadChapter1Map = function () {
    var tmxPath = "activity/words_of_fortune/chapter1/map.tmx";

    // 使用引擎原生 TMXTiledMap 加载
    var tmxMap = new cc.TMXTiledMap(tmxPath);
    this.rootNode.addChild(tmxMap, 1);

    // 手动加载 imagelayer（引擎不支持）
    var basePath = tmxPath.substring(0, tmxPath.lastIndexOf("/") + 1);
    var bgSprite = new cc.Sprite(basePath + "background.png");
    bgSprite.setAnchorPoint(0, 0);
    // 计算位置...
    tmxMap.addChild(bgSprite, -1);
};
```

### 方案 B：完全手动解析和渲染

适用于：使用 Collection of Images tileset 或需要完全控制渲染的情况

```javascript
// 解析 TMX XML
WordsOfFortuneMainUIController.prototype._parseTMXFile = function (tmxPath) {
    var tmxContent = cc.loader.getRes(tmxPath);
    var parser = new DOMParser();
    var xmlDoc = parser.parseFromString(tmxContent, "text/xml");

    // 解析 imagelayer
    var imageLayerElements = xmlDoc.getElementsByTagName("imagelayer");
    // ...

    // 解析 Collection of Images tileset
    var tileElements = ts.getElementsByTagName("tile");
    for (var j = 0; j < tileElements.length; j++) {
        var imgElements = tileElements[j].getElementsByTagName("image");
        // ...
    }
};

// 手动渲染 tile 层
WordsOfFortuneMainUIController.prototype._loadTileLayers = function (mapInfo, basePath, container) {
    // 遍历 tile 数据，为每个非零 gid 创建 Sprite
    // 根据 staggered/orthogonal 计算坐标
};
```

## 合并 Tileset 图片

如果需要将多张独立图片合并为 sprite sheet：

```python
# Python 脚本示例
from PIL import Image

img1 = Image.open("tile1.png")  # 256x128
img2 = Image.open("tile2.png")  # 256x128
img3 = Image.open("tile3.png")  # 256x128

# 水平拼接
result = Image.new('RGBA', (768, 128))
result.paste(img1, (0, 0))
result.paste(img2, (256, 0))
result.paste(img3, (512, 0))
result.save("tileset.png")
```

合并后更新 TMX 文件：

```xml
<tileset firstgid="1" name="tileset" tilewidth="256" tileheight="128" tilecount="3" columns="3">
  <image source="tileset.png" width="768" height="128"/>
</tileset>
```

## Staggered 地图坐标转换

Staggered（交错）地图的坐标计算与正交地图不同：

```javascript
// TMX 坐标系：原点左上角，Y 轴向下
// Cocos2d 坐标系：原点左下角，Y 轴向上

if (isStaggered) {
    var isOddRow = (row % 2 === 1);
    var shouldOffset = (staggerIndex === "odd") ? isOddRow : !isOddRow;

    // X 坐标：奇数行向右偏移半个 tile
    posX = col * tileWidth + (shouldOffset ? tileWidth / 2 : 0);

    // Y 坐标：每行只占 tileHeight/2 高度
    var tmxY = row * (tileHeight / 2);
    posY = mapPixelHeight - tmxY - tileHeight / 2;
}
```

## 相关文件

| 文件 | 说明 |
|-----|------|
| `frameworks/cocos2d-html5/cocos2d/tilemap/CCTMXTiledMap.js` | TMXTiledMap 主类 |
| `frameworks/cocos2d-html5/cocos2d/tilemap/CCTMXXMLParser.js` | TMX XML 解析器 |
| `frameworks/cocos2d-html5/cocos2d/tilemap/CCTMXLayer.js` | TMXLayer 渲染（基于 SpriteBatchNode） |
| `src/task/controller/words_of_fortune/WordsOfFortuneMainUIController.js` | 测试代码位置 |

## 参考资料

- [Tiled Map Editor 官方文档](https://doc.mapeditor.org/)
- [TMX 文件格式规范](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/)
- Cocos2d-html5 TMXTiledMap 注释（CCTMXTiledMap.js 第 64-113 行）

---

**记录日期**: 2025-12-04
**测试人员**: Words of Fortune 开发组
