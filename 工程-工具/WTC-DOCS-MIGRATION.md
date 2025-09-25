# 将文档迁移到独立仓库

本指南说明如何将 docs 目录分离为独立的 Git 仓库。

## 方法一：创建全新的仓库（推荐）

### 1. 复制 docs 目录到新位置

```bash
# 复制整个 docs 目录到新位置
cp -r docs ~/worldtourcasino-docs

# 进入新目录
cd ~/worldtourcasino-docs
```

### 2. 初始化新的 Git 仓库

```bash
# 初始化 Git
git init

# 添加所有文件
git add .

# 创建首次提交
git commit -m "Initial commit: Extract docs from main project"
```

### 3. 创建 GitHub 仓库并推送

```bash
# 添加远程仓库
git remote add origin https://github.com/yourusername/worldtourcasino-docs.git

# 推送到 GitHub
git push -u origin main
```

### 4. 安装依赖并启动

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

## 方法二：保留 Git 历史（使用 git filter-branch）

如果需要保留文档的 Git 历史记录：

### 1. 克隆主仓库

```bash
# 克隆仓库
git clone https://github.com/yourusername/WorldTourCasino.git worldtourcasino-docs
cd worldtourcasino-docs
```

### 2. 使用 filter-branch 只保留 docs 目录

```bash
# 过滤出只包含 docs 目录的历史
git filter-branch --prune-empty --subdirectory-filter docs main

# 清理
git reset --hard
git gc --aggressive --prune=now
```

### 3. 更新远程仓库

```bash
# 移除原来的远程仓库
git remote remove origin

# 添加新的远程仓库
git remote add origin https://github.com/yourusername/worldtourcasino-docs.git

# 强制推送
git push -u origin main --force
```

## 主项目的调整

在主项目中，您可以：

### 选项 1：完全移除 docs 目录

```bash
# 在主项目中
rm -rf docs
git add -A
git commit -m "Remove docs (moved to separate repository)"
```

### 选项 2：添加 submodule 引用（可选）

```bash
# 添加文档仓库作为 submodule
git submodule add https://github.com/yourusername/worldtourcasino-docs.git docs
git commit -m "Add docs as submodule"
```

### 选项 3：在 README 中添加链接

在主项目的 README.md 中添加：

```markdown
## 文档

项目文档已迁移到独立仓库：[worldtourcasino-docs](https://github.com/yourusername/worldtourcasino-docs)
```

## 部署配置

### GitHub Pages

1. 在新仓库的 Settings > Pages 中启用 GitHub Pages
2. 选择 GitHub Actions 作为源
3. 推送代码后会自动部署

### Vercel/Netlify

1. 连接 GitHub 仓库
2. 设置构建命令：`npm run build`
3. 设置输出目录：`.vitepress/dist`

## 注意事项

- 记得更新主项目的 CI/CD 配置
- 更新相关文档中的链接
- 通知团队成员新的文档位置
- 考虑设置自动部署
