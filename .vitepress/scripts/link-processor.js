#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// ⚠️ 链接处理器已弃用
//
// VitePress 原生支持相对路径链接，无需手动转换为完整 HTTP 链接。
// 请参考：docs/工程-工具/WTC-docs链接设计规范.md
//
// 此脚本保留用于向后兼容，但不再进行强制转换。
// 新文档请使用 VitePress 标准格式：
//   - 文档链接：[文档](./path/to/doc)
//   - 图片链接：![图片](/assets/image.png)

const BASE_URL = process.env.GITHUB_ACTIONS ? 'https://zhaoheng666.github.io/WTC-Docs' : 'http://localhost:5173/WTC-Docs';

class LinkProcessor {
  constructor() {
    this.stats = {
      filesModified: 0,
      linksConverted: 0,
      linksSkipped: 0
    };
  }

  /**
   * 判断链接是否需要转换
   * @param {string} link - 原始链接
   * @returns {boolean} - 是否需要转换
   *
   * ⚠️ 注意：此函数已弃用，不再进行强制转换
   * VitePress 原生支持相对路径，无需手动转换
   */
  shouldConvertLink(link) {
    // ⚠️ 不再进行任何转换
    // VitePress 会自动处理相对路径
    return false;

    /* 原有逻辑已禁用
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

    // 4. 已经是 WTC-Docs 路径的链接
    if (link.includes('/WTC-Docs/')) {
      return false;
    }

    // 5. data: URL（base64编码的图片等）
    if (link.startsWith('data:')) {
      return false;
    }

    // 其他相对路径都需要转换
    return true;
    */
  }

  /**
   * 转换相对路径为绝对 HTTP 链接
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

    // 获取 MD 文件相对于 docs 根目录的路径
    const docsRoot = path.join(__dirname, '../..');
    const mdDir = path.dirname(mdFilePath);
    const relativeToDocsRoot = path.relative(docsRoot, mdDir);

    // 解析相对路径
    let targetPath = decodedLink;

    // 处理 ./ 和 ../ 相对路径
    if (decodedLink.startsWith('./') || decodedLink.startsWith('../')) {
      // 从 MD 文件所在目录开始解析
      const absolutePath = path.resolve(mdDir, decodedLink);
      targetPath = path.relative(docsRoot, absolutePath);
    } else if (!decodedLink.startsWith('/')) {
      // 如果是不带前缀的相对路径，也从 MD 文件所在目录解析
      const absolutePath = path.resolve(mdDir, decodedLink);
      targetPath = path.relative(docsRoot, absolutePath);
    } else {
      // 以 / 开头的路径，去掉开头的 /
      targetPath = decodedLink.substring(1);
    }

    // 移除 .md 扩展名（VitePress 自动处理）
    targetPath = targetPath.replace(/\.md$/, '');

    // 处理 Windows 路径分隔符
    targetPath = targetPath.replace(/\\/g, '/');

    // 构建完整的 HTTP 链接
    const fullUrl = `${BASE_URL}/${targetPath}`;

    this.stats.linksConverted++;
    return fullUrl;
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
      console.log(`  ⏭ Skipping auto-generated index.md: ${relativePath}`);
      return false;
    }

    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;

    // 正则匹配 Markdown 链接：[text](url)
    // 支持多行文本，非贪婪匹配
    const linkRegex = /\[([^\]]*)\]\(([^)]+)\)/g;

    let newContent = content.replace(linkRegex, (match, text, url) => {
      const newUrl = this.convertRelativeLink(url, filePath);

      if (newUrl !== url) {
        modified = true;
        console.log(`  🔗 [${text}]: ${url} -> ${newUrl}`);
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
        console.log(`  🔗 [${ref}]: ${cleanUrl} -> ${newUrl}`);
        return `[${ref}]: ${newUrl}`;
      }

      return match;
    });

    if (modified) {
      fs.writeFileSync(filePath, newContent);
      console.log(`✓ Processed links in: ${relativePath}`);
      this.stats.filesModified++;
      return true;
    }

    return false;
  }

  /**
   * 处理所有变更的 Markdown 文件
   */
  processChangedFiles() {
    const { execSync } = require('child_process');

    try {
      // 获取所有变更的 MD 文件（包括暂存、未暂存和未跟踪）
      // 禁用 Git 的路径引号，以便正确处理中文文件名
      const changedFiles = execSync(
        `(git -c core.quotePath=false diff --cached --name-only; git -c core.quotePath=false diff --name-only; git -c core.quotePath=false diff HEAD --name-only; git -c core.quotePath=false ls-files --others --exclude-standard) | grep "\\.md$" | sort -u || true`,
        { encoding: 'utf8' }
      ).trim().split('\n').filter(f => f);

      if (changedFiles.length === 0 || (changedFiles.length === 1 && !changedFiles[0])) {
        console.log('No markdown files changed, skipping link processing.');

        // 输出统计
        this.printStats();
        return;
      }

      console.log(`\n🔗 Processing links in ${changedFiles.length} changed markdown files...`);

      for (const file of changedFiles) {
        if (fs.existsSync(file)) {
          console.log(`\n📄 Processing: ${file}`);
          this.processMarkdownFile(file);
        }
      }

      // 输出统计
      this.printStats();

    } catch (error) {
      console.error('Error processing files:', error.message);
      process.exit(1);
    }
  }

  /**
   * 打印统计信息
   */
  printStats() {
    console.log('\n📊 Link Processing Statistics:');
    console.log(`  Files modified: ${this.stats.filesModified}`);
    console.log(`  Links converted: ${this.stats.linksConverted}`);
    console.log(`  Links skipped: ${this.stats.linksSkipped}`);
  }
}

// 主函数
function main() {
  console.log('🚀 Starting link processor...\n');
  const processor = new LinkProcessor();
  processor.processChangedFiles();
}

if (require.main === module) {
  main();
}

module.exports = LinkProcessor;
