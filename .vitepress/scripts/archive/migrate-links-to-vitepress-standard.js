#!/usr/bin/env node

/**
 * 链接迁移脚本
 *
 * 将旧格式的 HTTP 完整链接转换为 VitePress 标准格式：
 * 1. 图片链接: http://localhost:5173/WTC-Docs/assets/xxx.png → /assets/xxx.png
 * 2. 文档链接: http://localhost:5173/WTC-Docs/工程-工具/xxx → 相对路径
 */

const fs = require('fs');
const path = require('path');

class LinkMigrator {
  constructor() {
    this.stats = {
      filesProcessed: 0,
      filesModified: 0,
      imageLinksConverted: 0,
      docLinksConverted: 0
    };
  }

  /**
   * 转换图片链接
   * http://localhost:5173/WTC-Docs/assets/image.png → /assets/image.png
   */
  convertImageLinks(content) {
    let modified = false;
    let newContent = content;

    // 匹配图片链接：![alt](http://localhost:5173/WTC-Docs/assets/...)
    const imagePattern = /!\[([^\]]*)\]\(http:\/\/localhost:5173\/WTC-Docs\/assets\/([^)]+)\)/g;

    const matches = [...content.matchAll(imagePattern)];
    if (matches.length > 0) {
      newContent = content.replace(imagePattern, (match, alt, imagePath) => {
        this.stats.imageLinksConverted++;
        console.log(`    🖼️  ${imagePath} → /assets/${imagePath}`);
        return `![${alt}](/assets/${imagePath})`;
      });
      modified = true;
    }

    return { newContent, modified };
  }

  /**
   * 转换文档链接为相对路径
   *
   * 需要根据当前文件路径计算相对路径
   */
  convertDocLinks(content, filePath) {
    let modified = false;
    let newContent = content;

    // 匹配文档链接：[text](http://localhost:5173/WTC-Docs/...)
    // 排除 assets 目录（已被图片转换处理）
    const docPattern = /\[([^\]]+)\]\(http:\/\/localhost:5173\/WTC-Docs\/([^)]+)\)/g;

    const matches = [...content.matchAll(docPattern)];
    const currentDir = path.dirname(filePath);
    const docsRoot = path.join(__dirname, '../..');

    for (const match of matches) {
      const [fullMatch, linkText, targetPath] = match;

      // 跳过 assets 链接（已被图片转换处理）
      if (targetPath.startsWith('assets/')) {
        continue;
      }

      // 计算相对路径
      const targetAbsolutePath = path.join(docsRoot, targetPath);
      let relativePath = path.relative(currentDir, targetAbsolutePath);

      // 处理 Windows 路径分隔符
      relativePath = relativePath.replace(/\\/g, '/');

      // 确保以 ./ 或 ../ 开头
      if (!relativePath.startsWith('../') && !relativePath.startsWith('./')) {
        relativePath = './' + relativePath;
      }

      // 移除 .md 扩展名（如果有）
      relativePath = relativePath.replace(/\.md$/, '');

      const newLink = `[${linkText}](${relativePath})`;
      newContent = newContent.replace(fullMatch, newLink);

      this.stats.docLinksConverted++;
      console.log(`    🔗 ${targetPath} → ${relativePath}`);
      modified = true;
    }

    return { newContent, modified };
  }

  /**
   * 处理单个 Markdown 文件
   */
  processFile(filePath) {
    const relativePath = path.relative(process.cwd(), filePath);

    // 跳过 node_modules 和构建目录
    if (relativePath.includes('node_modules') || relativePath.includes('.vitepress/dist')) {
      return false;
    }

    this.stats.filesProcessed++;

    let content = fs.readFileSync(filePath, 'utf8');
    let fileModified = false;

    // 1. 转换图片链接
    const imageResult = this.convertImageLinks(content);
    if (imageResult.modified) {
      content = imageResult.newContent;
      fileModified = true;
    }

    // 2. 转换文档链接
    const docResult = this.convertDocLinks(content, filePath);
    if (docResult.modified) {
      content = docResult.newContent;
      fileModified = true;
    }

    // 保存修改
    if (fileModified) {
      fs.writeFileSync(filePath, content);
      this.stats.filesModified++;
      console.log(`  ✓ Modified: ${relativePath}`);
      return true;
    }

    return false;
  }

  /**
   * 递归查找所有 Markdown 文件
   */
  findMarkdownFiles(dir, files = []) {
    try {
      const items = fs.readdirSync(dir);

      for (const item of items) {
        if (item.startsWith('.') || item === 'node_modules') {
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
    } catch (error) {
      console.warn(`Warning: Could not read directory ${dir}: ${error.message}`);
    }

    return files;
  }

  /**
   * 执行迁移
   */
  async migrate() {
    console.log('🚀 开始迁移链接格式到 VitePress 标准...\n');

    const docsRoot = path.join(__dirname, '../..');
    const files = this.findMarkdownFiles(docsRoot);

    console.log(`📁 找到 ${files.length} 个 Markdown 文件\n`);

    for (const file of files) {
      const relativePath = path.relative(process.cwd(), file);

      // 检查文件是否包含需要转换的链接
      const content = fs.readFileSync(file, 'utf8');
      if (content.includes('http://localhost:5173/WTC-Docs/')) {
        console.log(`📄 处理: ${relativePath}`);
        this.processFile(file);
      }
    }

    // 输出统计
    console.log('\n📊 迁移统计:');
    console.log(`  文件处理总数: ${this.stats.filesProcessed}`);
    console.log(`  文件修改数量: ${this.stats.filesModified}`);
    console.log(`  图片链接转换: ${this.stats.imageLinksConverted}`);
    console.log(`  文档链接转换: ${this.stats.docLinksConverted}`);
    console.log(`  总链接转换数: ${this.stats.imageLinksConverted + this.stats.docLinksConverted}`);

    if (this.stats.filesModified > 0) {
      console.log('\n✅ 迁移完成！');
      console.log('\n建议：');
      console.log('  1. 运行 npm run dev 验证链接是否正常');
      console.log('  2. 检查 git diff 确认修改正确');
      console.log('  3. 提交前测试构建: npm run build');
    } else {
      console.log('\n✓ 所有链接已经是标准格式，无需迁移');
    }
  }
}

// 主函数
async function main() {
  const migrator = new LinkMigrator();
  await migrator.migrate();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = LinkMigrator;
