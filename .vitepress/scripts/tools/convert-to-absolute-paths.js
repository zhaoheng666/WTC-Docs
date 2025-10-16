#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * 将文档内部相对路径链接转换为根路径绝对引用
 *
 * 转换规则：
 * - [文本](./file) → [文本](/当前目录/file)
 * - [文本](../dir/file) → [文本](/上级目录/dir/file)
 * - 保持图片链接不变（已经是 /assets/ 格式）
 */

const DOCS_ROOT = path.join(__dirname, '../..');

class PathConverter {
  constructor() {
    this.stats = {
      filesProcessed: 0,
      linksConverted: 0,
      errors: []
    };
  }

  /**
   * 计算文件相对于 docs 根目录的路径
   */
  getRelativeToRoot(filePath) {
    const rel = path.relative(DOCS_ROOT, filePath);
    // 移除 .md 扩展名
    return '/' + rel.replace(/\.md$/, '');
  }

  /**
   * 解析相对路径链接，转换为绝对路径
   */
  resolveRelativeLink(currentFile, relativeLink) {
    // 如果已经是绝对路径（/ 或 http 开头），不处理
    if (relativeLink.startsWith('/') || relativeLink.startsWith('http')) {
      return null;
    }

    // 如果是锚点链接，不处理
    if (relativeLink.startsWith('#')) {
      return null;
    }

    // 计算当前文件所在目录
    const currentDir = path.dirname(currentFile);

    // 解析相对路径为绝对路径
    let absolutePath = path.resolve(currentDir, relativeLink);

    // 添加 .md 扩展名（如果链接没有扩展名）
    if (!path.extname(absolutePath)) {
      absolutePath += '.md';
    }

    // 检查文件是否存在
    if (!fs.existsSync(absolutePath)) {
      // 尝试不加 .md
      const withoutExt = absolutePath.replace(/\.md$/, '');
      if (fs.existsSync(withoutExt)) {
        absolutePath = withoutExt;
      } else {
        return null; // 文件不存在，保持原样
      }
    }

    // 转换为相对于 docs 根目录的路径
    let rootPath = path.relative(DOCS_ROOT, absolutePath);

    // 移除 .md 扩展名
    rootPath = rootPath.replace(/\.md$/, '');

    // 添加前导斜杠
    return '/' + rootPath;
  }

  /**
   * 处理单个 Markdown 文件
   */
  processFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;
    let convertedCount = 0;

    // 匹配 Markdown 链接: [文本](路径)
    // 排除图片: ![文本](路径)
    const linkRegex = /(?<!!)\[([^\]]+)\]\(([^)]+)\)/g;

    content = content.replace(linkRegex, (match, text, link) => {
      // 提取实际链接（移除可能的标题）
      const linkParts = link.split(/\s+/);
      const actualLink = linkParts[0];

      // 尝试转换相对路径
      const absolutePath = this.resolveRelativeLink(filePath, actualLink);

      if (absolutePath) {
        modified = true;
        convertedCount++;

        // 保持原有的链接标题（如果有）
        const title = linkParts.slice(1).join(' ');
        return title ? `[${text}](${absolutePath} ${title})` : `[${text}](${absolutePath})`;
      }

      return match;
    });

    if (modified) {
      fs.writeFileSync(filePath, content, 'utf8');
      this.stats.filesProcessed++;
      this.stats.linksConverted += convertedCount;
      console.log(`✓ ${path.relative(DOCS_ROOT, filePath)}: ${convertedCount} 个链接已转换`);
    }

    return modified;
  }

  /**
   * 递归处理目录
   */
  processDirectory(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      // 跳过特殊目录
      if (entry.isDirectory()) {
        if (['.vitepress', 'node_modules', '.git', 'public'].includes(entry.name)) {
          continue;
        }
        this.processDirectory(fullPath);
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        try {
          this.processFile(fullPath);
        } catch (error) {
          this.stats.errors.push({ file: fullPath, error: error.message });
          console.error(`✗ ${path.relative(DOCS_ROOT, fullPath)}: ${error.message}`);
        }
      }
    }
  }

  /**
   * 执行转换
   */
  run() {
    console.log('🔄 开始转换文档链接为根路径格式...\n');

    this.processDirectory(DOCS_ROOT);

    console.log('\n📊 转换统计：');
    console.log(`  处理文件数：${this.stats.filesProcessed}`);
    console.log(`  转换链接数：${this.stats.linksConverted}`);

    if (this.stats.errors.length > 0) {
      console.log(`\n⚠️  错误数：${this.stats.errors.length}`);
      this.stats.errors.forEach(({ file, error }) => {
        console.log(`  - ${path.relative(DOCS_ROOT, file)}: ${error}`);
      });
    }

    console.log('\n✅ 转换完成！');
  }
}

// 执行转换
const converter = new PathConverter();
converter.run();
