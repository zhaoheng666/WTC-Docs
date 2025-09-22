#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const https = require('https');
const http = require('http');
const { URL } = require('url');

const BASE_URL = process.env.GITHUB_ACTIONS ? 'https://zhaoheng666.github.io/WTC-Docs' : 'http://localhost:5173/WTC-Docs';
const PUBLIC_ASSETS_DIR = path.join(__dirname, '../../public/assets');

class ImageProcessorV2 {
  constructor() {
    this.processedImages = new Set();
    this.ensureAssetsDirectory();
    this.stats = {
      filesModified: 0,
      imagesDownloaded: 0,
      imagesProcessed: 0,
      imagesCleaned: 0
    };
  }

  ensureAssetsDirectory() {
    if (!fs.existsSync(PUBLIC_ASSETS_DIR)) {
      fs.mkdirSync(PUBLIC_ASSETS_DIR, { recursive: true });
      console.log(`✓ Created assets directory: ${PUBLIC_ASSETS_DIR}`);
    }
  }

  // 生成基于文件路径和内容的唯一图片名
  generateUniqueImageName(mdFilePath, originalUrl) {
    const relativePath = path.relative(process.cwd(), mdFilePath);
    // 将路径转换为安全的文件名格式
    const safePath = relativePath
      .replace(/\//g, '_')
      .replace(/\\/g, '_')
      .replace(/\.md$/, '');

    // 从 URL 或路径中提取原始扩展名
    let ext = '.png';
    try {
      const urlPath = originalUrl.startsWith('http') ? new URL(originalUrl).pathname : originalUrl;
      const originalExt = path.extname(urlPath).toLowerCase();
      if (originalExt && ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'].includes(originalExt)) {
        ext = originalExt;
      }
    } catch (e) {}

    // 生成基于原始URL的唯一哈希
    const hash = crypto.createHash('md5').update(originalUrl).digest('hex').substring(0, 12);

    return `${safePath}_${hash}${ext}`;
  }

  async downloadImage(url, destPath) {
    return new Promise((resolve, reject) => {
      const protocol = url.startsWith('https') ? https : http;

      const options = {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': url
        }
      };

      protocol.get(url, options, (response) => {
        if (response.statusCode === 200) {
          const file = fs.createWriteStream(destPath);
          response.pipe(file);
          file.on('finish', () => {
            file.close();
            resolve();
          });
        } else {
          reject(new Error(`HTTP ${response.statusCode}`));
        }
      }).on('error', reject);
    });
  }

  async processGiteeImage(url, mdFilePath) {
    try {
      const filename = this.generateUniqueImageName(mdFilePath, url);
      const destPath = path.join(PUBLIC_ASSETS_DIR, filename);

      if (!fs.existsSync(destPath)) {
        console.log(`  ↓ Downloading Gitee image: ${url}`);
        await this.downloadImage(url, destPath);
        console.log(`  ✓ Downloaded as: ${filename}`);
        this.stats.imagesDownloaded++;
      }

      return `${BASE_URL}/assets/${filename}`;
    } catch (error) {
      console.error(`  ✗ Failed to download Gitee image: ${error.message}`);
      return url;
    }
  }

  processLocalImage(imagePath, mdFilePath) {
    const mdDir = path.dirname(mdFilePath);
    const absoluteImagePath = path.resolve(mdDir, imagePath);

    if (!fs.existsSync(absoluteImagePath)) {
      console.warn(`  ⚠ Image not found: ${imagePath}`);
      return imagePath;
    }

    const filename = this.generateUniqueImageName(mdFilePath, imagePath);
    const destPath = path.join(PUBLIC_ASSETS_DIR, filename);

    if (!fs.existsSync(destPath)) {
      fs.copyFileSync(absoluteImagePath, destPath);
      console.log(`  ✓ Copied local image as: ${filename}`);
      this.stats.imagesProcessed++;
    }

    return `${BASE_URL}/assets/${filename}`;
  }

  // 从图片文件名解析出对应的 MD 文件
  parseImageFileName(imageName) {
    // 格式: 成员_赵恒_CardSystem加载优化_abc123def456.png
    const match = imageName.match(/(.+)_[a-f0-9]{12}\.\w+$/);
    if (match) {
      const [, filePathPart] = match;
      // 将下划线转回路径分隔符，并添加 .md 扩展名
      const mdFile = filePathPart.replace(/_/g, '/') + '.md';
      return { mdFile };
    }
    return null;
  }

  async processMarkdownFile(filePath) {
    const relativePath = path.relative(process.cwd(), filePath);

    let content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    let modified = false;

    const imageRegex = /!\[([^\]]*)\]\(([^)]+)\)/g;
    const processedInThisFile = new Set(); // 记录本文件中处理的图片

    // 处理每一行
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      let lineModified = false;
      let newLine = line;

      let match;
      imageRegex.lastIndex = 0;

      while ((match = imageRegex.exec(line)) !== null) {
        const [fullMatch, altText, imageSrc] = match;

        // 跳过已处理的图片，但记录它们
        if (imageSrc.includes('/WTC-Docs/assets/')) {
          const imageName = imageSrc.split('/assets/')[1];
          if (imageName) {
            processedInThisFile.add(imageName);
          }
          continue;
        }

        let newSrc = imageSrc;

        // 处理 Gitee 图片
        if (imageSrc.includes('gitee.com')) {
          newSrc = await this.processGiteeImage(imageSrc, filePath);
          lineModified = true;
        }
        // 处理本地图片
        else if (!imageSrc.startsWith('http')) {
          newSrc = this.processLocalImage(imageSrc, filePath);
          lineModified = true;
        }

        if (newSrc !== imageSrc) {
          newLine = newLine.replace(fullMatch, `![${altText}](${newSrc})`);
          // 记录新处理的图片
          const imageName = newSrc.split('/assets/')[1];
          if (imageName) {
            processedInThisFile.add(imageName);
          }
        }
      }

      if (lineModified) {
        lines[i] = newLine;
        modified = true;
      }
    }

    // 清理属于本文件但不再被引用的图片
    const filePrefix = relativePath.replace(/\//g, '_').replace(/\.md$/, '_');
    const assetsFiles = fs.existsSync(PUBLIC_ASSETS_DIR)
      ? fs.readdirSync(PUBLIC_ASSETS_DIR)
      : [];

    for (const imageName of assetsFiles) {
      // 只处理属于当前文件的图片
      if (imageName.startsWith(filePrefix)) {
        if (!processedInThisFile.has(imageName)) {
          const imagePath = path.join(PUBLIC_ASSETS_DIR, imageName);
          fs.unlinkSync(imagePath);
          console.log(`  🗑️  Deleted unused image: ${imageName}`);
          this.stats.imagesCleaned++;
        }
      }
    }

    if (modified) {
      fs.writeFileSync(filePath, lines.join('\n'));
      console.log(`✓ Processed: ${relativePath}`);
      this.stats.filesModified++;
    } else if (this.stats.imagesCleaned > 0) {
      console.log(`✓ Cleaned unused images from: ${relativePath}`);
    }

    return modified || this.stats.imagesCleaned > 0;
  }

  async processChangedFiles() {
    // 获取变更的 MD 文件
    const { execSync } = require('child_process');

    try {
      // 获取所有变更的 MD 文件（包括暂存、未暂存和未跟踪）
      // 同时检测相对于 HEAD 的变更（用于 sync.sh 场景）
      const changedFiles = execSync(
        `(git diff --cached --name-only; git diff --name-only; git diff HEAD --name-only; git ls-files --others --exclude-standard) | grep "\\.md$" | sort -u || true`,
        { encoding: 'utf8' }
      ).trim().split('\n').filter(f => f);

      if (changedFiles.length === 0 || (changedFiles.length === 1 && !changedFiles[0])) {
        console.log('No markdown files changed.');
        return;
      }

      console.log(`Found ${changedFiles.length} changed markdown files.`);

      for (const file of changedFiles) {
        if (fs.existsSync(file)) {
          await this.processMarkdownFile(file);
        }
      }

      // 输出统计
      console.log('\n📊 Statistics:');
      console.log(`  Files modified: ${this.stats.filesModified}`);
      console.log(`  Images downloaded: ${this.stats.imagesDownloaded}`);
      console.log(`  Images processed: ${this.stats.imagesProcessed}`);
      console.log(`  Images cleaned: ${this.stats.imagesCleaned}`);

    } catch (error) {
      console.error('Error processing files:', error.message);
    }
  }
}

// 主函数
async function main() {
  const processor = new ImageProcessorV2();
  await processor.processChangedFiles();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = ImageProcessorV2;