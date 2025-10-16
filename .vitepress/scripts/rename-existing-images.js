#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// 图片存放在 docs/assets/ (源码目录，非 public/)
const PUBLIC_ASSETS_DIR = path.join(__dirname, '../../assets');

class ImageRenamer {
  constructor() {
    this.stats = {
      filesRenamed: 0,
      documentsUpdated: 0,
      errors: 0
    };
    this.renameMap = new Map(); // 记录旧名称到新名称的映射
  }

  // 生成新的两段式命名
  generateNewImageName(originalName, content) {
    // 从原始文件名中提取扩展名
    const ext = path.extname(originalName).toLowerCase();

    // 生成基于原始文件名和内容的唯一标识符
    const contentKey = originalName + '|' + content;
    const fullHash = crypto.createHash('md5').update(contentKey).digest('hex');

    // 生成两段式命名：时间戳(13位) + hash(8位)
    const timestamp = Date.now().toString();
    const shortHash = fullHash.substring(0, 8);

    return `${timestamp}_${shortHash}${ext}`;
  }

  // 检查是否为旧命名规则的文件
  isOldNamingPattern(filename) {
    // 如果已经是新的两段式命名，跳过
    if (/^\d{13}_[a-f0-9]{8}\.\w+$/.test(filename)) {
      return false;
    }

    // 如果是图片文件，则认为是旧命名需要处理
    return /\.(png|jpg|jpeg|gif|webp|svg)$/i.test(filename);
  }

  async renameImages() {
    console.log('🔄 开始重命名现有图片文件...');

    if (!fs.existsSync(PUBLIC_ASSETS_DIR)) {
      console.log('❌ 资源目录不存在');
      return;
    }

    const files = fs.readdirSync(PUBLIC_ASSETS_DIR);
    const imagesToRename = files.filter(file => this.isOldNamingPattern(file));

    console.log(`📊 发现 ${imagesToRename.length} 个需要重命名的图片文件`);

    for (const oldName of imagesToRename) {
      try {
        const oldPath = path.join(PUBLIC_ASSETS_DIR, oldName);

        // 读取文件内容用于生成唯一哈希
        const fileContent = fs.readFileSync(oldPath);
        const contentHash = crypto.createHash('md5').update(fileContent).digest('hex');

        const newName = this.generateNewImageName(oldName, contentHash);
        const newPath = path.join(PUBLIC_ASSETS_DIR, newName);

        // 检查新文件名是否已存在
        if (fs.existsSync(newPath)) {
          console.log(`⚠️  跳过 ${oldName}，新名称已存在: ${newName}`);
          continue;
        }

        // 重命名文件
        fs.renameSync(oldPath, newPath);

        // 记录映射关系
        this.renameMap.set(oldName, newName);

        console.log(`✅ ${oldName} -> ${newName}`);
        this.stats.filesRenamed++;

        // 稍微延迟一下，确保时间戳不重复
        await new Promise(resolve => setTimeout(resolve, 1));

      } catch (error) {
        console.error(`❌ 重命名失败 ${oldName}: ${error.message}`);
        this.stats.errors++;
      }
    }

    console.log(`\n📊 重命名统计:`);
    console.log(`  成功重命名: ${this.stats.filesRenamed} 个文件`);
    console.log(`  错误: ${this.stats.errors} 个`);

    return this.renameMap;
  }

  async updateMarkdownReferences(renameMap) {
    console.log('\n🔄 更新 Markdown 文档中的图片引用...');

    const docsDir = path.join(__dirname, '../..');

    // 递归查找所有 Markdown 文件
    const markdownFiles = this.findMarkdownFiles(docsDir);

    console.log(`📄 发现 ${markdownFiles.length} 个 Markdown 文件`);

    for (const filePath of markdownFiles) {
      try {
        let content = fs.readFileSync(filePath, 'utf8');
        let modified = false;

        // 更新图片引用
        for (const [oldName, newName] of renameMap) {
          const oldUrl = `/WTC-Docs/assets/${oldName}`;
          const newUrl = `/WTC-Docs/assets/${newName}`;

          // 替换本地开发和生产环境的引用
          const patterns = [
            new RegExp(`http://localhost:5173/WTC-Docs/assets/${this.escapeRegex(oldName)}`, 'g'),
            new RegExp(`https://zhaoheng666\\.github\\.io/WTC-Docs/assets/${this.escapeRegex(oldName)}`, 'g'),
            new RegExp(`/WTC-Docs/assets/${this.escapeRegex(oldName)}`, 'g')
          ];

          const replacements = [
            `http://localhost:5173/WTC-Docs/assets/${newName}`,
            `https://zhaoheng666.github.io/WTC-Docs/assets/${newName}`,
            `/WTC-Docs/assets/${newName}`
          ];

          for (let i = 0; i < patterns.length; i++) {
            if (patterns[i].test(content)) {
              content = content.replace(patterns[i], replacements[i]);
              modified = true;
            }
          }
        }

        if (modified) {
          fs.writeFileSync(filePath, content);
          console.log(`✅ 更新文档: ${path.relative(docsDir, filePath)}`);
          this.stats.documentsUpdated++;
        }

      } catch (error) {
        console.error(`❌ 更新文档失败 ${filePath}: ${error.message}`);
        this.stats.errors++;
      }
    }

    console.log(`\n📊 文档更新统计:`);
    console.log(`  更新的文档: ${this.stats.documentsUpdated} 个`);
  }

  // 递归查找所有 Markdown 文件
  findMarkdownFiles(dir, files = []) {
    const items = fs.readdirSync(dir);

    for (const item of items) {
      if (item.startsWith('.') || item === 'node_modules' || item === 'public') {
        continue;
      }

      const fullPath = path.join(dir, item);
      const stat = fs.statSync(fullPath);

      if (stat.isDirectory()) {
        this.findMarkdownFiles(fullPath, files);
      } else if (item.endsWith('.md')) {
        files.push(fullPath);
      }
    }

    return files;
  }

  // 转义正则表达式特殊字符
  escapeRegex(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
}

async function main() {
  const renamer = new ImageRenamer();

  console.log('🚀 开始处理现有图片文件...');

  // 1. 重命名图片文件
  const renameMap = await renamer.renameImages();

  if (renameMap.size === 0) {
    console.log('✅ 没有需要重命名的图片文件');
    return;
  }

  // 2. 更新 Markdown 文档中的引用
  await renamer.updateMarkdownReferences(renameMap);

  console.log('\n🎉 处理完成！');
  console.log(`📊 总计:`);
  console.log(`  重命名图片: ${renamer.stats.filesRenamed} 个`);
  console.log(`  更新文档: ${renamer.stats.documentsUpdated} 个`);
  console.log(`  错误: ${renamer.stats.errors} 个`);
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = ImageRenamer;