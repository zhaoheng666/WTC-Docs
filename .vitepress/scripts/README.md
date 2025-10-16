# Scripts 目录说明

## 目录结构

```
.vitepress/scripts/
├── 顶层脚本（7个）          # NPM 入口 + CI 构建
├── lib/（6个）              # 核心处理器（自动调用）
├── utils/（1个）            # 辅助工具（被调用）
├── tools/（6个）            # 手动工具（独立使用）
└── archive/（6个）          # 废弃脚本
```

## 顶层脚本（用户/CI 直接调用）

| 脚本 | 用途 | 调用方式 |
|------|------|---------|
| `init.sh` | 环境初始化 | `npm run init` |
| `dev.sh` | 开发服务器 | `npm run dev` |
| `build.sh` | 构建文档 | `npm run build` |
| `build-ci.sh` | CI 构建 | GitHub Actions |
| `sync.sh` | 同步部署 | `npm run sync` |
| `status.sh` | Git 状态 | `npm run status` |
| `convert-docx.sh` | DOCX 转换 | `npm run convert-docx` |

## lib/ - 核心处理器（自动调用，用户不直接使用）

| 脚本 | 用途 | 调用者 |
|------|------|--------|
| `fix-problematic-filenames.js` | 修复文件名特殊字符 | build.sh |
| `image-processor.js` | 图片下载、重命名、清理 | build.sh |
| `pdf-processor.js` | PDF 文件收集和处理 | build.sh |
| `link-processor.js` | 链接格式转换 | build.sh |
| `generate-directory-index.js` | 生成目录索引页 | build.sh |
| `generate-stats.js` | 统计数据生成 | build-ci.sh |

## utils/ - 辅助工具（被其他脚本调用）

| 脚本 | 用途 | 调用者 |
|------|------|--------|
| `notify.sh` | 系统通知 | sync.sh, convert-docx.sh |

## tools/ - 手动工具（独立使用）

| 脚本 | 用途 | 调用方式 |
|------|------|---------|
| `image-duplicate-checker.js` | 检查重复图片 | `node .vitepress/scripts/tools/image-duplicate-checker.js` |
| `rename-existing-images.js` | 批量重命名图片 | `node .vitepress/scripts/tools/rename-existing-images.js` |
| `force-process-images.js` | 强制处理图片 | `node .vitepress/scripts/tools/force-process-images.js` |
| `convert-to-absolute-paths.js` | 转换链接格式 | `node .vitepress/scripts/tools/convert-to-absolute-paths.js` |
| `comment-missing-images.sh` | 注释缺失图片 | `zsh .vitepress/scripts/tools/comment-missing-images.sh` |
| `comment-missing-images.py` | 注释缺失图片（Python版） | `python3 .vitepress/scripts/tools/comment-missing-images.py` |

## archive/ - 废弃脚本（仅供参考）

- `image-processor-old.js` - 旧版图片处理器
- `migrate-links-to-vitepress-standard.js` - 一次性迁移工具
- `update-content-titles.js` - 未使用
- `rename-files.js` - 未使用
- `sync 优化方案` - 文本文件
- `fix-rollup.sh` - Rollup ARM64 修复（已不需要）

---

**最后更新**: 2025-10-16
**维护者**: WTC-Docs Team
