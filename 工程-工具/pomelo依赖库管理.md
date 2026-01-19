# Pomelo 依赖库管理

**适用范围**: WorldTourCasino 主项目

本文档说明 pomelo 相关依赖库的管理方式和开发流程。

---

## 仓库结构

### 依赖关系

```
WorldTourCasino
└── @me2zen/pomelo-cocos2d-js
    ├── @me2zen/pomelo-jsclient-websocket
    └── @me2zen/pomelo-protocol
```

### 本地开发路径

| 库 | 本地路径 |
|---|---------|
| pomelo-cocos2d-js | `/Users/ghost/work/pomelo/pomelo-cocos2d-js` |
| pomelo-jsclient-websocket | `/Users/ghost/work/pomelo/pomelo-jsclient-websocket` |
| pomelo-protocol | `/Users/ghost/work/pomelo/pomelo-protocol` |

### 远程仓库

| 库 | GitHub |
|---|--------|
| pomelo-cocos2d-js | https://github.com/LuckyZen/pomelo-cocos2d-js |
| pomelo-jsclient-websocket | https://github.com/LuckyZen/pomelo-jsclient-websocket |
| pomelo-protocol | https://github.com/LuckyZen/pomelo-protocol |

---

## 版本管理

### 使用 commit hash（强制）

为确保多机器环境下依赖一致性，**必须使用具体 commit hash** 而非分支名：

```json
// ✅ 正确
"@me2zen/pomelo-cocos2d-js": "git+https://github.com/LuckyZen/pomelo-cocos2d-js.git#646c508"

// ❌ 错误（会导致同步问题）
"@me2zen/pomelo-cocos2d-js": "git+https://github.com/LuckyZen/pomelo-cocos2d-js.git#gzip-support"
```

### 原因

npm 对 git 依赖有缓存机制：
- 使用分支名时，npm 认为本地版本是最新的，不会检查远程是否有新提交
- 使用 commit hash 时，npm 会对比 hash 值，发现不同则重新拉取

---

## 修改流程

### 1. 修改 pomelo-jsclient-websocket

```bash
# 进入仓库
cd /Users/ghost/work/pomelo/pomelo-jsclient-websocket
git checkout gzip-support  # 或其他分支

# 修改代码
vim lib/pomelo-client.js

# 提交并推送
git add .
git commit -m "描述改动"
git push

# 获取新 commit hash
git rev-parse --short HEAD  # 例如：71d8f8b
```

### 2. 更新 pomelo-cocos2d-js 依赖

```bash
cd /Users/ghost/work/pomelo/pomelo-cocos2d-js
git checkout gzip-support

# 修改 package.json 中的依赖版本
# "@me2zen/pomelo-jsclient-websocket": "...#旧hash" → "...#71d8f8b"

git add .
git commit -m "更新 pomelo-jsclient-websocket 依赖到 #71d8f8b"
git push

# 获取新 commit hash
git rev-parse --short HEAD  # 例如：646c508
```

### 3. 更新主项目

```bash
cd /Users/ghost/work/WorldTourCasino

# 修改 package.json
# "@me2zen/pomelo-cocos2d-js": "...#旧hash" → "...#646c508"

# 重新生成 package-lock.json
rm package-lock.json
rm -rf node_modules/@me2zen
npm install

# 提交（必须包含 package-lock.json）
git add package.json package-lock.json
git commit -m "cv: 更新 pomelo 依赖"
git push
```

### ⚠️ package-lock.json 同步规则（强制）

**历史原因**：`package-lock.json` 已纳入 Git 版本控制。

**必须遵守**：
1. 每次更新 pomelo 或其他 npm 依赖时，**必须删除并重新生成** `package-lock.json`
2. **必须提交** 新的 `package-lock.json` 到 Git
3. 如果只提交 `package.json` 而不提交 `package-lock.json`，其他机器 `git pull` 后会被重置为旧版本的依赖

**错误示例**：
```bash
# ❌ 只提交 package.json，忘记提交 package-lock.json
git add package.json
git commit -m "更新依赖"
# 结果：其他机器 pull 后 package-lock.json 仍是旧版本，npm install 会安装旧依赖
```

**正确流程**：
```bash
# ✅ 完整流程
rm package-lock.json
rm -rf node_modules/@me2zen
npm install
git add package.json package-lock.json  # 两个文件都要提交
git commit -m "更新依赖"
git push
```

---

## 本地调试

### 方式一：直接修改 node_modules

适用于快速调试，修改后需同步回仓库：

```bash
# 修改
vim node_modules/@me2zen/pomelo-jsclient-websocket/lib/pomelo-client.js

# 测试通过后，复制回仓库
cp node_modules/@me2zen/pomelo-jsclient-websocket/lib/pomelo-client.js \
   /Users/ghost/work/pomelo/pomelo-jsclient-websocket/lib/
```

### 方式二：使用 npm link（推荐）

```bash
# 在 pomelo 库中
cd /Users/ghost/work/pomelo/pomelo-jsclient-websocket
npm link

# 在主项目中
cd /Users/ghost/work/WorldTourCasino
npm link @me2zen/pomelo-jsclient-websocket

# 调试完成后取消 link
npm unlink @me2zen/pomelo-jsclient-websocket
npm install
```

---

## 常见问题

### 切换分支后依赖版本不对

```bash
rm -rf node_modules/@me2zen
npm install
```

### 多机器依赖不一致

确保 `package.json` 和 `package-lock.json` 都使用 commit hash，然后：

```bash
rm package-lock.json
rm -rf node_modules/@me2zen
npm install
```

### npm install 无法更新 git 依赖

npm 会使用 `package-lock.json` 中锁定的版本。需要删除 lock 文件重新生成：

```bash
rm package-lock.json
npm install
```

---

## 当前版本

| 库 | commit | 说明 |
|---|--------|-----|
| pomelo-cocos2d-js | `#b4e3c87` | main 分支 |
| pomelo-jsclient-websocket | `#7ee1965` | 使用 compressGzip 字段判断解压 |
| pomelo-protocol | 默认分支 | 无特殊修改 |

---

**最后更新**: 2026-01-18
**维护者**: WTC Team
