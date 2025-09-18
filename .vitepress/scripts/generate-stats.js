#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 判断是否在 CI 环境
const isCI = process.env.GITHUB_ACTIONS === 'true';
const isForce = process.argv[2] === '--force';

const docsDir = path.join(__dirname, '../..');
// 不再生成 markdown 文件，只生成 JSON 数据
const jsonOutputFile = path.join(docsDir, 'public/stats.json');

// 确保目录存在
const outputDir = path.dirname(jsonOutputFile);
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
          date: new Date(date).toISOString(),
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
    categoryStats,
    updateTime: new Date().toLocaleString('zh-CN')
  };
}


// 生成 JSON 数据
function generateJSON() {
  const stats = getDocStats();
  const commits = isCI ? getRecentCommits(100) : []; // CI 环境获取更多提交
  
  // 计算贡献者数量
  const contributors = new Set(commits.map(c => c.author)).size;
  
  return {
    updateTime: new Date().toISOString(),
    totalDocs: stats.totalDocs,
    categoryStats: stats.categoryStats,
    contributors: contributors,
    commits: commits.map(commit => ({
      hash: commit.hash,
      date: commit.date,
      author: commit.author,
      message: commit.message,
      files: commit.files
    }))
  };
}

// 主函数
function main() {
  if (isCI) {
    console.log('📊 生成完整统计数据（CI 环境）...');
  } else {
    console.log('📊 生成本地统计数据（不含提交历史）...');
  }
  
  try {
    // 只生成 JSON 数据，不生成 Markdown 文件
    const jsonData = generateJSON();
    fs.writeFileSync(jsonOutputFile, JSON.stringify(jsonData, null, 2), 'utf8');
    console.log(`✅ JSON 数据已生成: ${jsonOutputFile}`);
    
    if (!isCI) {
      console.log('💡 提示：本地版本不含提交历史，避免循环提交');
    }
  } catch (error) {
    console.error('❌ 生成失败:', error.message);
    process.exit(1);
  }
}

main();