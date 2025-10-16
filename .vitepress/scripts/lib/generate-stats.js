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

// 获取所有贡献者
function getAllContributors() {
  try {
    const gitAuthors = execSync(
      `git shortlog -sn --all`,
      { cwd: docsDir, encoding: 'utf8' }
    );

    return gitAuthors.split('\n')
      .filter(line => line.trim())
      .map(line => {
        const match = line.trim().match(/(\d+)\s+(.+)/);
        if (match) {
          return {
            name: match[2],
            totalCommits: parseInt(match[1])
          };
        }
      })
      .filter(Boolean);
  } catch (error) {
    console.error('获取贡献者失败:', error.message);
    return [];
  }
}

// 获取最近的提交记录
function getRecentCommits(limit = 30) {
  try {
    const format = '%H|%ai|%an|%s';
    // 移除 -- "*.md" 限制，获取所有提交
    const gitLog = execSync(
      `git -c core.quotepath=false log --pretty=format:"${format}" --name-only --diff-filter=AM | head -500`,
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
        // 立即添加到commits数组
        commits.push(currentCommit);
      } else if (line.trim() && currentCommit) {
        // 这是文件名（不限制.md）
        currentCommit.files.push(line);
      }
    }

    // 在 CI 环境中，确保包含当前正在部署的提交
    // GitHub Actions 的问题是：stats.json 在构建时生成，但此时最新提交还未完全部署
    // 所以需要特殊处理以确保显示的是实时信息
    if (process.env.GITHUB_ACTIONS === 'true' && process.env.CURRENT_COMMIT_HASH) {
      // 检查第一个提交是否就是当前提交
      if (commits.length === 0 || !commits[0].hash.startsWith(process.env.CURRENT_COMMIT_HASH)) {
        // 获取当前提交的文件变更
        let changedFiles = [];
        try {
          const filesOutput = execSync(
            `git -c core.quotepath=false diff-tree --no-commit-id --name-only -r HEAD -- "*.md"`,
            { cwd: docsDir, encoding: 'utf8' }
          ).trim();
          if (filesOutput) {
            changedFiles = filesOutput.split('\n').filter(f => f.endsWith('.md'));
          }
        } catch (e) {
          // 如果获取失败，至少记录这是一次提交
          changedFiles = ['文档更新'];
        }

        // 添加当前提交到列表开头
        const currentCommitInfo = {
          hash: process.env.CURRENT_COMMIT_HASH || 'unknown',
          date: new Date().toISOString(),
          author: process.env.CURRENT_COMMIT_AUTHOR || 'unknown',
          message: process.env.CURRENT_COMMIT_MSG || '文档更新',
          files: changedFiles
        };

        // 确保不重复添加
        if (!commits[0] || commits[0].hash !== currentCommitInfo.hash) {
          commits.unshift(currentCommitInfo);
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
  const allContributors = isCI ? getAllContributors() : [];

  // 计算今日更新次数
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const todayCommits = commits.filter(commit => {
    const commitDate = commit.date.split('T')[0];
    return commitDate === today;
  });

  // 计算贡献者统计 - 使用完整的Git历史
  let contributorsList = [];
  if (allContributors.length > 0) {
    contributorsList = allContributors.map(contributor => {
      // 找到该贡献者最近的提交
      const recentCommit = commits.find(c => c.author === contributor.name);
      return {
        name: contributor.name,
        commits: contributor.totalCommits,
        lastCommit: recentCommit?.date || new Date().toISOString()
      };
    }).sort((a, b) => b.commits - a.commits);
  } else {
    // 降级到从recent commits计算
    const contributorsSet = new Set(commits.map(c => c.author));
    contributorsList = Array.from(contributorsSet).map(author => {
      const authorCommits = commits.filter(c => c.author === author);
      return {
        name: author,
        commits: authorCommits.length,
        lastCommit: authorCommits[0]?.date || new Date().toISOString()
      };
    }).sort((a, b) => b.commits - a.commits);
  }

  return {
    updateTime: new Date().toISOString(),
    totalDocs: stats.totalDocs,
    categoryStats: stats.categoryStats,
    contributors: contributorsList.length,
    contributorsList: contributorsList,
    todayUpdates: todayCommits.length,
    commits: commits.slice(0, 30).map(commit => ({ // 限制前30个最新提交
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
  // 仅在 CI 环境生成统计
  if (!isCI) {
    console.log('⏭️  跳过统计生成（仅在 CI 环境生成）');
    return;
  }
  
  console.log('📊 生成完整统计数据（CI 环境）...');
  
  try {
    // 检查是否存在 stats.json，如果不存在，从模板复制
    if (!fs.existsSync(jsonOutputFile)) {
      const templateFile = path.join(docsDir, 'public/stats.template.json');
      if (fs.existsSync(templateFile)) {
        console.log('📋 使用模板文件初始化 stats.json');
        fs.copyFileSync(templateFile, jsonOutputFile);
      }
    }
    
    // 生成完整的统计数据
    const jsonData = generateJSON();
    fs.writeFileSync(jsonOutputFile, JSON.stringify(jsonData, null, 2), 'utf8');
    console.log(`✅ JSON 数据已生成: ${jsonOutputFile}`);
  } catch (error) {
    console.error('❌ 生成失败:', error.message);
    process.exit(1);
  }
}

main();