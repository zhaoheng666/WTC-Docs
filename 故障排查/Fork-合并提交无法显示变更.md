# Fork 合并提交无法显示变更

## 问题现象

在 Fork（macOS Git 客户端）中查看合并提交 `78daf81a7f7e4b72006154ec6688e3db65e772d6`（`Merge branch 'classic_vegas_dbh_v762' into classic_vegas`）时，下方变更面板显示报错：

![Fork 合并提交报错截图](/assets/fork-merge-commit-error.png)

```txt
Error
generic("Unexpected error:\ndetect renames\nDecompressed required size, but buffer has more\n\nPlease contact Fork support")
```

同一合并提交在 GitHub 网页端、其他同事的 Fork 中均可正常显示。

## 根因分析

报错并非来自 Git 仓库本身，而是 Fork 客户端 UI 渲染层的问题：

| 关键词 | 含义 |
|--------|------|
| `detect renames` | Git 在生成 diff 时执行重命名检测，会把候选 blob 解压到内存做相似度比较 |
| `Decompressed required size, but buffer has more` | Fork 内部使用固定大小的 zlib 解压缓冲区，单个对象解压后超出上限时直接抛错 |

触发条件：本次合并涉及面非常大。

- 合并提交相对父 `^1`（CVS 主线父）：2666 个文件，+7405/−7896 行
- 合并提交相对父 `^2`（DH 版本分支父 `015455c`）：1181 个文件，+2858/−2823 行
- 包含若干大体积二进制资源（如 `star_777_symbol_anim_batch.png` 2.5MB → 560KB）

`git show` 走的是流式解压，不受影响；Fork 为了在 UI 中做 rename 检测做了预加载，因而在某个对象上越界。

## 仓库完整性验证

为排除仓库本体损坏，需做以下交叉验证：

```bash
# 1) 哈希一致性：本地与远端 SHA 必须完全相同
git rev-parse origin/classic_vegas 78daf81a7f7

# 2) 深度对象自检：返回 exit 0 且无输出
git fsck --no-dangling 78daf81a7f7e4b72006154ec6688e3db65e772d6

# 3) 合并父链可达
git log --oneline 78daf81a7f7^1..78daf81a7f7
git log --oneline 78daf81a7f7^2..78daf81a7f7

# 4) 与远端 classic_vegas 顶端 diff 必须为空
git diff --stat 78daf81a7f7 origin/classic_vegas

# 5) 验证版本分支与主线的 merge-base 锚点正常
git merge-base origin/classic_vegas_dbh_v765 origin/classic_vegas
git merge-base origin/classic_vegas_cvs_v940 origin/classic_vegas
```

只要 SHA 与远端一致、`fsck` 无输出，即可判定仓库本体健康——Git 的 SHA 是对 `tree + 父 + 作者 + message` 的内容寻址哈希，任何 byte 丢失都会导致哈希改变。

## 解决方案

### 立即生效（推荐）

**重启 Fork 即可**。重启会释放 Fork 持有的旧缓冲区句柄并重建对象缓存，绝大多数情况下问题随即消失。

### 仍未恢复时

```bash
# 1) 清理 Fork 缓存目录后重新打开仓库
rm -rf ~/Library/Caches/com.DanPristupov.Fork

# 2) 或暂时关闭重命名检测
#    Fork → Settings → Diff → 取消勾选 "Detect renames"

# 3) 应急查看变更
git show 78daf81a7f7 --stat -- src/
git log -m -p 78daf81a7f7 -- 具体路径
# 或直接到 GitHub Web 查看该 commit
```

## 触发条件总结

满足以下条件时，Fork 较容易出现该报错：

- 合并提交跨越两个长期分支，diff 文件数 > 千级
- 变更中包含若干 MB 级的二进制资源（图集 png、CCBI、plist 等）
- 启用了 rename 检测

WTC 的 `classic_vegas_dh_v*` / `classic_vegas_cvs_v*` 版本分支回流主线时容易满足上述条件，遇到此现象可参照本文处置，无需担心数据丢失。

## 相关链接

- 合并提交：`78daf81a7f7e4b72006154ec6688e3db65e772d6`
- 涉及版本分支：`classic_vegas_dbh_v762` → 主线 `classic_vegas`
- 后续版本分支：`classic_vegas_dbh_v765`、`classic_vegas_cvs_v940`（均正常）

---

**最后更新**: 2026-05-11
