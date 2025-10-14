# 文件路径链接规则

**适用范围**: 所有项目和子项目（主项目、docs、extensions 等）

## 规则说明

在文档中提及具体的代码文件路径时，应自动转换为 GitHub 链接，方便用户直接访问源码。

## 主项目文件

**格式**:
```markdown
[文件路径](https://github.com/LuckyZen/WorldTourCasino/blob/分支名/文件路径)
```

**示例**:
```markdown
[scripts/build_local_app.sh](https://github.com/LuckyZen/WorldTourCasino/blob/classic_vegas/scripts/build_local_app.sh)
```

## 子仓库文件

主项目中包含多个子仓库（git submodule），引用子仓库文件时需要使用具体的提交哈希。

### 子仓库映射表

| 主项目路径 | 子仓库 URL |
|-----------|-----------|
| `frameworks/cocos2d-html5/` | https://github.com/LuckyZen/cocos2d-html5 |
| `frameworks/cocos2d-x/` | https://github.com/LuckyZen/cocos2d-x |
| `libZenSDK/` | https://github.com/LuckyZen/libZenSDK |

### 获取子仓库提交哈希

```bash
# 进入子仓库目录
cd 主项目/frameworks/cocos2d-html5

# 获取当前提交哈希
git log --oneline -1
```

### 链接格式

```markdown
https://github.com/LuckyZen/cocos2d-html5/blob/提交哈希/文件路径
```

**示例**:
```markdown
[CCDirector.js](https://github.com/LuckyZen/cocos2d-html5/blob/a1b2c3d4/cocos2d/core/CCDirector.js)
```

---

**最后更新**: 2025-10-13
**维护者**: WorldTourCasino Team
