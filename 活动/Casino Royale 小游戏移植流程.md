# Casino Royale 小游戏移植流程

## 概述

本文档描述将小游戏从 `src/task/controller/` 迁移到 Casino Royale 活动（`src/activity/casino_royale/controller/games/`）的标准化流程。

## 前置信息

移植前需要准备以下 6 项信息：

| 序号 | 信息项 | 说明 | 示例 |
|------|--------|------|------|
| 1 | 源码路径 | 原游戏代码所在目录 | `src/task/controller/crazy_lotto` |
| 2 | 目标路径 | 迁移后的代码目录 | `src/activity/casino_royale/controller/games/crazy_lotto` |
| 3 | 资源路径 | CCB 等资源文件所在目录 | `Resources/activity/casino_royale_games/crazy_lotto` |
| 4 | 类名前缀 | 添加到所有类名前的前缀 | `CasinoRoyale` |
| 5 | 删除的 CCB | 需要删除的 CCB 文件名（逗号分隔，不含 .ccb 后缀） | `crazy_lotto_deal,crazy_lotto_entrance` |
| 6 | 子目录 | 如果有 ui 等子目录需要特殊处理（可选） | `ui` |

## 移植步骤

### 步骤 1：拷贝源码到目标目录

```bash
mkdir -p <目标路径>
cp -r <源码路径>/* <目标路径>/
```

**示例**：
```bash
mkdir -p src/activity/casino_royale/controller/games/crazy_lotto
cp -r src/task/controller/crazy_lotto/* src/activity/casino_royale/controller/games/crazy_lotto/
```

### 步骤 2：重命名 JS 文件

将所有 JS 文件添加 `CasinoRoyale` 前缀：

```bash
cd <目标路径>
for file in <原前缀>*.js; do
    mv "$file" "CasinoRoyale$file"
done
```

**示例**：
```bash
cd src/activity/casino_royale/controller/games/crazy_lotto
for file in CrazyLotto*.js; do
    mv "$file" "CasinoRoyale$file"
done
```

**结果**：
- `CrazyLottoMainController.js` → `CasinoRoyaleCrazyLottoMainController.js`
- `CrazyLottoEventType.js` → `CasinoRoyaleCrazyLottoEventType.js`

### 步骤 3：修改类名

使用 Python 脚本批量修改所有 JS 文件中的类名：

```python
import os
import re

target_dir = '<目标路径>'
os.chdir(target_dir)

js_files = [f for f in os.listdir('.') if f.endswith('.js')]

for filename in js_files:
    # 提取原类名：CasinoRoyaleCrazyLotto -> CrazyLotto
    original_name = filename.replace('CasinoRoyale', '').replace('.js', '')
    new_name = 'CasinoRoyale' + original_name

    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    # 替换类定义
    content = re.sub(r'\bvar ' + original_name + r' = function',
                     'var ' + new_name + ' = function', content)

    # 替换继承
    content = re.sub(r'\bgame\.util\.inherits\(' + original_name + r',',
                     'game.util.inherits(' + new_name + ',', content)

    # 替换原型方法
    content = re.sub(r'\b' + original_name + r'\.prototype\.',
                     new_name + '.prototype.', content)

    # 替换静态方法
    content = re.sub(r'\b' + original_name + r'\.createFromCCB',
                     new_name + '.createFromCCB', content)

    # 替换字符串引用
    content = re.sub(r'"' + original_name + r'"',
                     '"' + new_name + '"', content)

    # 替换 new 语句
    content = re.sub(r'new ' + original_name + r'\(',
                     'new ' + new_name + '(', content)

    # 替换模块导出
    content = re.sub(r'\bmodule\.exports = ' + original_name + r';',
                     'module.exports = ' + new_name + ';', content)

    # 替换 require 语句（变量名和类名）
    content = re.sub(r'\bvar ' + original_name + r' = require\("\./' + original_name + r'"\);',
                     'var ' + new_name + ' = require("./' + new_name + '");', content)

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f'✅ {filename}: {original_name} -> {new_name}')
```

**修改内容**：
- `var CrazyLottoMainController = function()` → `var CasinoRoyaleCrazyLottoMainController = function()`
- `game.util.inherits(CrazyLottoMainController, ...)` → `game.util.inherits(CasinoRoyaleCrazyLottoMainController, ...)`
- `CrazyLottoMainController.prototype.xxx` → `CasinoRoyaleCrazyLottoMainController.prototype.xxx`
- `module.exports = CrazyLottoMainController;` → `module.exports = CasinoRoyaleCrazyLottoMainController;`
- `var CrazyLottoEventType = require("./CrazyLottoEventType");` → `var CasinoRoyaleCrazyLottoEventType = require("./CasinoRoyaleCrazyLottoEventType");`

### 步骤 4：修正 require 路径

由于目标目录层级更深，需要修正所有外部引用的路径：

```python
import os
import re

target_dir = '<目标路径>'
os.chdir(target_dir)

js_files = [f for f in os.listdir('.') if f.endswith('.js')]

for filename in js_files:
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    # 目标深度: src/activity/casino_royale/controller/games/游戏名
    # 需要: ../../../../../ 来访问 src/ 下的模块

    # ActivityMainUIController
    content = re.sub(r'require\("\.\.\/ActivityMainUIController"\)',
                     'require("../../../../../task/controller/ActivityMainUIController")', content)

    # ActivityBaseController
    content = re.sub(r'require\("\.\.\/ActivityBaseController"\)',
                     'require("../../../../../task/controller/ActivityBaseController")', content)

    # 其他可能的 require 路径
    content = re.sub(r'require\("\.\.\/\.\.\/([^"]+)"\)',
                     r'require("../../../../../\1")', content)

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f'✅ {filename}')
```

**路径对比**：
- 原路径：`require("../ActivityMainUIController")`
- 新路径：`require("../../../../../task/controller/ActivityMainUIController")`

**特殊情况：ui 子目录**

如果源码中有 `ui/` 子目录，需要额外处理：

```python
# ui 子目录的文件需要多一层 ../
if is_in_ui_dir:
    content = re.sub(r'require\("\.\.\/\.\.\/ActivityBaseController"\)',
                     'require("../../../../../../task/controller/ActivityBaseController")', content)
```

### 步骤 5：更新 CCB 文件的 jsController

修改资源目录中所有 CCB 文件的 `jsController` 字段：

```python
import os
import re

ccb_dir = '<资源路径>'

# 控制器映射表
controller_mapping = {
    'CrazyLottoMainController': 'CasinoRoyaleCrazyLottoMainController',
    'CrazyLottoEventType': 'CasinoRoyaleCrazyLottoEventType',
    # ... 添加所有控制器
}

ccb_files = [f for f in os.listdir(ccb_dir) if f.endswith('.ccb')]
modified_count = 0

for ccb_file in ccb_files:
    filepath = os.path.join(ccb_dir, ccb_file)

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    modified = False
    for old_controller, new_controller in controller_mapping.items():
        pattern = r'<key>jsController</key>\s*<string>' + old_controller + r'</string>'
        replacement = '<key>jsController</key>\n\t\t\t<string>' + new_controller + '</string>'

        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            modified = True
            print(f'  {ccb_file}: {old_controller} -> {new_controller}')

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        modified_count += 1

print(f'\n✅ 共更新了 {modified_count} 个 CCB 文件')
```

**CCB 文件结构**：
```xml
<dict>
    <key>jsController</key>
    <string>CrazyLottoMainController</string>  <!-- 需要修改 -->
</dict>
```

### 步骤 6：删除指定的 CCB 文件

删除不需要的 CCB 文件：

```bash
cd <资源路径>
rm -f <文件1>.ccb <文件2>.ccb <文件3>.ccb
```

**示例**：
```bash
cd Resources/activity/casino_royale_games/crazy_lotto
rm -f crazy_lotto_deal.ccb crazy_lotto_entrance.ccb crazy_lotto_end.ccb
```

## 完整示例

### CrazyLotto 移植示例

**移植信息**：
```
源码: src/task/controller/crazy_lotto
目标: src/activity/casino_royale/controller/games/crazy_lotto
资源: Resources/activity/casino_royale_games/crazy_lotto
前缀: CasinoRoyale
删除CCB: crazy_lotto_deal,crazy_lotto_double_pay,crazy_lotto_double_pay_again,crazy_lotto_end,crazy_lotto_entrance
```

**执行结果**：
- ✅ 拷贝 12 个 JS 文件
- ✅ 重命名添加 CasinoRoyale 前缀
- ✅ 修改所有类名和引用
- ✅ 修正 require 路径
- ✅ 更新 10 个 CCB 文件的 jsController
- ✅ 删除 5 个指定 CCB 文件
- ✅ 剩余 22 个 CCB 文件

### SuperBlackJack 移植示例

**移植信息**：
```
源码: src/task/controller/super_black_jack
目标: src/activity/casino_royale/controller/games/super_black_jack
资源: Resources/activity/casino_royale_games/super_black_jack
前缀: CasinoRoyale
删除CCB: super_black_jack_timeleft,super_black_jack_guide,super_black_jack_end,super_black_jack_buy
```

**执行结果**：
- ✅ 拷贝 8 个 JS 文件
- ✅ 重命名添加 CasinoRoyale 前缀
- ✅ 修改所有类名和引用
- ✅ 修正 require 路径
- ✅ 更新 8 个 CCB 文件的 jsController
- ✅ 删除 4 个指定 CCB 文件
- ✅ 剩余 19 个 CCB 文件

## 注意事项

1. **备份原始文件**：移植前建议先备份或确保代码已提交到 Git
2. **检查子目录**：如果源码中有 `ui/` 等子目录，需要特殊处理路径深度
3. **验证控制器映射**：步骤 5 中的 `controller_mapping` 需要包含所有使用的控制器
4. **测试运行**：移植完成后需要测试游戏是否正常运行
5. **资源路径**：确保资源路径中的游戏名与目标路径一致

## 常见问题

### Q1: 如何确定需要删除哪些 CCB 文件？

A: 根据游戏的入口和主要界面确定，通常需要删除以下类型的 CCB：
- 旧的入口界面（entrance）
- 旧的结算界面（end）
- 旧的购买界面（buy）
- 旧的引导界面（guide）

### Q2: 如果有 ui 子目录怎么处理？

A: 在步骤 4 修正 require 路径时，ui 子目录下的文件需要额外增加一层 `../`：
```python
if is_in_ui_dir:
    content = re.sub(r'require\("\.\.\/\.\.\/ActivityBaseController"\)',
                     'require("../../../../../../task/controller/ActivityBaseController")', content)
```

### Q3: 如何验证移植是否成功？

A: 检查以下几点：
1. 所有文件已重命名，包含 CasinoRoyale 前缀
2. 代码中无语法错误
3. require 路径正确，无模块找不到的错误
4. CCB 文件的 jsController 已更新
5. 游戏可以正常启动和运行

## 相关文档

- [Casino Royale 活动开发流程](/../活动/流程/新人活动开发流程)
- [活动资源归档](/../活动/活动资源归档)
- [活动注意事项](/../活动/注意事项)
