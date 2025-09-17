#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 判断是否在 CI 环境
const isCI = process.env.GITHUB_ACTIONS === 'true';
const isForce = process.argv[2] === '--force';

const docsDir = path.join(__dirname, '../..');
const outputFile = path.join(docsDir, '其他/隐藏/最近更新.md');

// 确保目录存在
const outputDir = path.dirname(outputFile);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// 获取最近的提交记录
function getRecentCommits(limit = 30) {
  try {
    const format = '%H|%ai|%an|%s';
    const gitLog = execSync(
      `git log --pretty=format:"${format}" --name-only --diff-filter=AM -- "*.md" | head -300`,
      { cwd: docsDir, encoding: 'utf8' }
    );
    
    const commits = [];
    const lines = gitLog.split('\n');
    let currentCommit = null;
    
    for (const line of lines) {
      if (line.includes('|')) {
        // 这是提交信息行
        const [hash, date, author, message] = line.split('|');
        currentCommit = {
          hash: hash.substring(0, 7),
          date: new Date(date).toLocaleDateString('zh-CN'),
          author,
          message,
          files: []
        };
      } else if (line.endsWith('.md') && currentCommit) {
        // 这是文件名
        currentCommit.files.push(line);
        if (!commits.find(c => c.hash === currentCommit.hash)) {
          commits.push({ ...currentCommit });
        }
      }
    }
    
    return commits.slice(0, limit);
  } catch (error) {
    console.error('获取提交记录失败:', error.message);
    return [];
  }
}

// 获取文档统计
function getDocStats() {
  let totalDocs = 0;
  let totalDirs = 0;
  const categoryStats = {};
  
  function scanDir(dir, category = null) {
    const items = fs.readdirSync(dir);
    
    for (const item of items) {
      const itemPath = path.join(dir, item);
      
      // 跳过特殊目录
      if (item.startsWith('.') || item === 'node_modules' || item === 'public') {
        continue;
      }
      
      const stat = fs.statSync(itemPath);
      
      if (stat.isDirectory()) {
        totalDirs++;
        const cat = category || item;
        scanDir(itemPath, cat);
      } else if (item.endsWith('.md') && item !== '最近更新.md') { // 排除统计页面本身
        totalDocs++;
        if (category) {
          categoryStats[category] = (categoryStats[category] || 0) + 1;
        }
      }
    }
  }
  
  scanDir(docsDir);
  
  return {
    totalDocs,
    totalDirs,
    categoryStats,
    updateTime: new Date().toLocaleString('zh-CN')
  };
}

// 生成 Markdown 内容
function generateMarkdown() {
  const stats = getDocStats();
  
  let content = `# 📊 文档统计与最近更新

> 最后更新：${stats.updateTime}

## 📈 文档概况

- **文档总数**：${stats.totalDocs} 篇
- **目录总数**：${stats.totalDirs} 个
`;

  // CI 环境下添加提交统计
  if (isCI) {
    const commits = getRecentCommits(30);
    content += `- **最近提交**：${commits.length} 次\n`;
  }

  content += `
### 📁 分类统计

| 分类 | 文档数 |
|------|--------|
`;

  for (const [category, count] of Object.entries(stats.categoryStats).sort((a, b) => b[1] - a[1])) {
    content += `| ${category} | ${count} |\n`;
  }

  // 只在 CI 环境下生成提交历史
  if (isCI) {
    const commits = getRecentCommits(30);
    content += `
## 🕐 最近更新

| 日期 | 文件 | 提交者 | 说明 |
|------|------|--------|------|
`;

    for (const commit of commits) {
      if (commit.files.length > 0) {
        const fileName = path.basename(commit.files[0], '.md');
        const filePath = commit.files[0];
        content += `| ${commit.date} | [${fileName}](/${filePath}) | ${commit.author} | ${commit.message} |\n`;
      }
    }
  } else {
    // 本地环境显示提示
    content += `
## 🕐 最近更新

:::tip 本地预览提示
最近更新记录仅在部署版本中显示。本地开发时不显示提交历史以避免循环提交问题。

查看完整更新历史：[GitHub Commits](https://github.com/zhaoheng666/WTC-Docs/commits/main)
:::
`;
  }

  content += `
## 🔗 相关链接

- [在线文档](https://zhaoheng666.github.io/WTC-Docs/)
- [GitHub 仓库](https://github.com/zhaoheng666/WTC-Docs)
- [查看所有提交](https://github.com/zhaoheng666/WTC-Docs/commits/main)

---

*此页面${isCI ? '由 GitHub Actions 自动生成' : '在本地生成（不含提交历史）'}，最后更新：${stats.updateTime}*
`;

  return content;
}

// 主函数
function main() {
  if (isCI) {
    console.log('📊 生成完整统计页面（CI 环境）...');
  } else {
    console.log('📊 生成本地统计页面（不含提交历史）...');
  }
  
  try {
    const content = generateMarkdown();
    fs.writeFileSync(outputFile, content, 'utf8');
    console.log(`✅ 统计页面已生成: ${outputFile}`);
    
    if (!isCI) {
      console.log('💡 提示：本地版本不含提交历史，避免循环提交');
    }
  } catch (error) {
    console.error('❌ 生成失败:', error.message);
    process.exit(1);
  }
}

main();