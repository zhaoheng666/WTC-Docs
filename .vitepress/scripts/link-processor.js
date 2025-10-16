#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * 链接处理器 - 自动转换相对路径为 VitePress 根路径
 *
 * 目的：
 * 1. 检测文档中的相对路径链接 (./ ../)
 * 2. 自动转换为根路径格式 (/)
 * 3. 实现文档位置无关性（与图片 /assets/ 一致）
 *
 * 参考文档：
 * - docs/工程-工具/WTC-docs链接设计规范.md
 * - docs/工程-工具/ai-rules/docs/link-processing.md
 */

class LinkProcessor {
  constructor() {
    this.stats = {
      filesModified: 0,
      linksConverted: 0,
      linksSkipped: 0
    };

    this.docsRoot = path.join(__dirname, '../..');
  }

  /**
   * 判断链接是否需要转换
   * @param {string} link - 原始链接
   * @returns {boolean} - 是否需要转换
   */
  shouldConvertLink(link) {
    // 跳过以下类型的链接：

    // 1. 已经是完整 HTTP/HTTPS 链接
    if (link.startsWith('http://') || link.startsWith('https://')) {
      return false;
    }

    // 2. 锚点链接
    if (link.startsWith('#')) {
      return false;
    }

    // 3. 邮件链接
    if (link.startsWith('mailto:')) {
      return false;
    }

    // 4. data: URL（base64编码的图片等）
    if (link.startsWith('data:')) {
      return false;
    }

    // 5. 已经是根路径格式（以 / 开头）
    if (link.startsWith('/')) {
      return false;
    }

    // 6. 图片链接（由 image-processor.js 处理）
    if (/\.(png|jpe?g|gif|svg|webp)$/i.test(link)) {
      return false;
    }

    // 需要转换的：相对路径文档链接 (./ ../ 或无前缀)
    return true;
  }

  /**
   * 转换相对路径为根路径格式
   * @param {string} link - 原始链接
   * @param {string} mdFilePath - Markdown 文件路径
   * @returns {string} - 转换后的链接
   */
  convertRelativeLink(link, mdFilePath) {
    if (!this.shouldConvertLink(link)) {
      this.stats.linksSkipped++;
      return link;
    }

    // 先解码URL编码的链接
    let decodedLink = link;
    try {
      decodedLink = decodeURIComponent(link);
    } catch (e) {
      // 解码失败，使用原始链接
    }

    // 获取 MD 文件所在目录
    const mdDir = path.dirname(mdFilePath);

    // 解析相对路径为绝对路径
    const absolutePath = path.resolve(mdDir, decodedLink);

    // 计算相对于 docs 根目录的路径
    let targetPath = path.relative(this.docsRoot, absolutePath);

    // 移除 .md 扩展名（VitePress 自动处理）
    targetPath = targetPath.replace(/\.md$/, '');

    // 处理 Windows 路径分隔符
    targetPath = targetPath.replace(/\\/g, '/');

    // 构建根路径格式
    const rootPath = '/' + targetPath;

    this.stats.linksConverted++;
    return rootPath;
  }

  /**
   * 处理 Markdown 文件中的链接
   * @param {string} filePath - 文件路径
   * @returns {boolean} - 是否修改了文件
   */
  processMarkdownFile(filePath) {
    const relativePath = path.relative(process.cwd(), filePath);

    // 跳过自动生成的 index.md 文件（由 generate-directory-index.js 生成）
    if (path.basename(filePath) === 'index.md') {
      return false;
    }

    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;
    const conversions = [];

    // 正则匹配 Markdown 链接：[text](url)
    // 排除图片链接 ![text](url)
    const linkRegex = /(?<!!)\[([^\]]*)\]\(([^)]+)\)/g;

    let newContent = content.replace(linkRegex, (match, text, url) => {
      const newUrl = this.convertRelativeLink(url.trim(), filePath);

      if (newUrl !== url.trim()) {
        modified = true;
        conversions.push({ text, from: url.trim(), to: newUrl });
        return `[${text}](${newUrl})`;
      }

      return match;
    });

    // 处理引用式链接：[ref]: url
    const refLinkRegex = /^\[([^\]]+)\]:\s*(.+)$/gm;

    newContent = newContent.replace(refLinkRegex, (match, ref, url) => {
      // 去除可能的尖括号包裹
      const cleanUrl = url.replace(/^<(.+)>$/, '$1').trim();

      const newUrl = this.convertRelativeLink(cleanUrl, filePath);

      if (newUrl !== cleanUrl) {
        modified = true;
        conversions.push({ text: `[${ref}]`, from: cleanUrl, to: newUrl });
        return `[${ref}]: ${newUrl}`;
      }

      return match;
    });

    if (modified) {
      fs.writeFileSync(filePath, newContent);
      console.log(`  ✓ ${relativePath}`);

      // 显示转换详情
      conversions.forEach(({ text, from, to }) => {
        console.log(`    ${from} → ${to}`);
      });

      this.stats.filesModified++;
      return true;
    }

    return false;
  }

  /**
   * 处理所有变更的 Markdown 文件
   */
  processChangedFiles() {
    try {
      // 获取所有变更的 MD 文件（包括暂存、未暂存和未跟踪）
      // 禁用 Git 的路径引号，以便正确处理中文文件名
      const changedFiles = execSync(
        `(git -c core.quotePath=false diff --cached --name-only; git -c core.quotePath=false diff --name-only; git -c core.quotePath=false diff HEAD --name-only; git -c core.quotePath=false ls-files --others --exclude-standard) | grep "\\.md$" | sort -u || true`,
        { encoding: 'utf8' }
      ).trim().split('\n').filter(f => f);

      if (changedFiles.length === 0 || (changedFiles.length === 1 && !changedFiles[0])) {
        console.log('No changed markdown files.');
        this.printStats();
        return;
      }

      console.log(`Found ${changedFiles.length} changed markdown files.`);

      for (const file of changedFiles) {
        if (fs.existsSync(file)) {
          this.processMarkdownFile(file);
        }
      }

      // 输出统计
      this.printStats();

    } catch (error) {
      console.error('❌ Error processing files:', error.message);
      process.exit(1);
    }
  }

  /**
   * 打印统计信息
   */
  printStats() {
    console.log('\n📊 Statistics:');
    console.log(`  Files modified: ${this.stats.filesModified}`);
    console.log(`  Links converted: ${this.stats.linksConverted}`);
    console.log(`  Links skipped: ${this.stats.linksSkipped}`);
  }
}

// 主函数
function main() {
  const processor = new LinkProcessor();
  processor.processChangedFiles();
}

if (require.main === module) {
  main();
}

module.exports = LinkProcessor;
