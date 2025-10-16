#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const https = require('https');
const http = require('http');
const { URL } = require('url');

// 使用 VitePress 标准格式：/assets/ 绝对路径
// VitePress 会根据 config.mjs 中的 base 配置自动处理完整 URL
const ASSETS_URL_PATH = '/assets';
// 图片存放在 docs/assets/ (源码目录，非 public/)
const PUBLIC_ASSETS_DIR = path.join(__dirname, '../../assets');

class ImageProcessorV2 {
  constructor() {
    this.processedImages = new Set();
    this.imageRegistry = new Map(); // 用于跟踪图片和文件的关联关系
    this.imageContentCache = new Map(); // 内容哈希缓存 imageName -> contentHash
    this.ensureAssetsDirectory();
    this.stats = {
      filesModified: 0,
      imagesDownloaded: 0,
      imagesProcessed: 0,
      embeddedImagesExtracted: 0,
      imagesCleaned: 0
    };
  }

  ensureAssetsDirectory() {
    if (!fs.existsSync(PUBLIC_ASSETS_DIR)) {
      fs.mkdirSync(PUBLIC_ASSETS_DIR, { recursive: true });
      console.log(`✓ Created assets directory: ${PUBLIC_ASSETS_DIR}`);
    }
  }

  // 生成简洁的两段式唯一图片名
  generateUniqueImageName(mdFilePath, originalUrl, imageId = null) {
    // 从 URL 或路径中提取原始扩展名
    let ext = '.png';
    try {
      const urlPath = originalUrl.startsWith('http') ? new URL(originalUrl).pathname : originalUrl;
      const originalExt = path.extname(urlPath).toLowerCase();
      if (originalExt && ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'].includes(originalExt)) {
        ext = originalExt;
      }
    } catch (e) {}

    // 生成基于URL内容的唯一标识符（不依赖文件路径，确保相同图片得到相同名称）
    const contentKey = originalUrl + (imageId ? '|' + imageId : '');
    const fullHash = crypto.createHash('md5').update(contentKey).digest('hex');

    // 检查是否已经为这个内容生成过文件名
    if (this.imageRegistry.has(contentKey)) {
      return this.imageRegistry.get(contentKey);
    }

    // 生成两段式命名：时间戳(13位) + hash(8位)
    const timestamp = Date.now().toString();
    const shortHash = fullHash.substring(0, 8);
    const filename = `${timestamp}_${shortHash}${ext}`;

    // 记录映射关系
    this.imageRegistry.set(contentKey, filename);

    return filename;
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

      return `${ASSETS_URL_PATH}/${filename}`;
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

    return `${ASSETS_URL_PATH}/${filename}`;
  }

  // 处理内置图片（base64编码）
  processEmbeddedImage(imageId, dataUrl, mdFilePath) {
    try {
      // 解析 data URL
      const dataUrlMatch = dataUrl.match(/^data:image\/([^;]+);base64,(.+)$/);
      if (!dataUrlMatch) {
        console.warn(`  ⚠ Invalid data URL for ${imageId}`);
        return dataUrl;
      }

      const mimeType = dataUrlMatch[1];
      const base64Data = dataUrlMatch[2];

      // 使用 data URL 作为原始 URL 来生成文件名
      const filename = this.generateUniqueImageName(mdFilePath, dataUrl, imageId);
      const destPath = path.join(PUBLIC_ASSETS_DIR, filename);

      if (!fs.existsSync(destPath)) {
        const imageBuffer = Buffer.from(base64Data, 'base64');
        fs.writeFileSync(destPath, imageBuffer);
        const sizeKB = Math.round(imageBuffer.length / 1024);
        console.log(`  ✓ Extracted embedded image as: ${filename} (${sizeKB}KB)`);
        this.stats.embeddedImagesExtracted++;
      }

      return `${ASSETS_URL_PATH}/${filename}`;
    } catch (error) {
      console.error(`  ✗ Failed to process embedded image ${imageId}:`, error.message);
      return dataUrl;
    }
  }

  // 从图片文件名解析出对应的 MD 文件（新的两段式命名无法直接解析出文件路径）
  parseImageFileName(imageName) {
    // 新格式: 1758255105402_e3252339.png
    // 由于新格式不包含文件路径信息，我们需要通过其他方式关联文件
    // 这个函数现在主要用于验证是否为有效的图片文件名格式
    const match = imageName.match(/^(\d{13})_([a-f0-9]{8})\.\w+$/);
    if (match) {
      const [, timestamp, hash] = match;
      return { timestamp, hash, valid: true };
    }
    return { valid: false };
  }

  async processMarkdownFile(filePath) {
    const relativePath = path.relative(process.cwd(), filePath);

    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;

    const processedInThisFile = new Set(); // 记录本文件中处理的图片

    // 首先处理内置图片引用 [imageX]: <data:image/...>
    const embeddedImagePattern = /\[([^\]]+)\]:\s*<(data:image\/[^;]+;base64,[^>]+)>/g;
    const imageReferences = new Map(); // 存储 imageId -> URL 的映射

    // 先收集所有匹配项，避免在循环中修改content导致正则匹配问题
    const embeddedMatches = [];
    let embeddedMatch;
    while ((embeddedMatch = embeddedImagePattern.exec(content)) !== null) {
      embeddedMatches.push([...embeddedMatch]);
    }

    // 然后处理所有匹配项
    for (const [fullMatch, imageId, dataUrl] of embeddedMatches) {
      console.log(`  🔍 Found embedded image reference: ${imageId}`);
      const newSrc = this.processEmbeddedImage(imageId, dataUrl, filePath);

      if (newSrc !== dataUrl) {
        // 存储映射关系，稍后处理引用
        imageReferences.set(imageId, newSrc);

        // 删除原有的引用定义行
        content = content.replace(fullMatch, '');
        modified = true;

        // 记录处理的图片
        const imageName = newSrc.split('/assets/')[1];
        if (imageName) {
          processedInThisFile.add(imageName);
        }
      }
    }

    // 处理引用式图片 ![][imageX] -> ![](URL)
    for (const [imageId, newSrc] of imageReferences) {
      const referencePattern = new RegExp(`!\\[\\]\\[${imageId}\\]`, 'g');
      const inlineImage = `![${imageId}](${newSrc})`;
      content = content.replace(referencePattern, inlineImage);
      console.log(`  ✓ Converted reference-style image: ${imageId} -> inline`);
    }

    // 然后处理常规的图片引用 ![alt](src)
    const lines = content.split('\n');
    const imageRegex = /!\[([^\]]*)\]\(([^)]+)\)/g;

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
        // 支持新旧两种格式：/assets/xxx 和 http://.../assets/xxx
        if (imageSrc.includes('/assets/') || imageSrc.startsWith('/assets/')) {
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

    // 如果有行级修改，更新内容
    if (lines.join('\n') !== content.split('\n').join('\n')) {
      content = lines.join('\n');
      modified = true;
    }

    // 记录本文件中处理的图片
    for (const imageName of processedInThisFile) {
      this.processedImages.add(imageName);
    }

    // 记录已处理图片（用于统计）

    if (modified) {
      fs.writeFileSync(filePath, content);
      console.log(`✓ Processed: ${relativePath}`);
      this.stats.filesModified++;
    } else if (this.stats.imagesCleaned > 0) {
      console.log(`✓ Cleaned unused images from: ${relativePath}`);
    }

    return modified || this.stats.imagesCleaned > 0;
  }

  // 智能图片清理 - 基于内容去重 + 有限扫描
  cleanUnusedImages(changedFiles = []) {
    if (!fs.existsSync(PUBLIC_ASSETS_DIR)) {
      return;
    }

    console.log('🧹 检查未使用的图片...');

    // 策略1：如果只有少量文件变更，使用增量检查
    if (changedFiles.length > 0 && changedFiles.length <= 10) {
      this.incrementalCleanup(changedFiles);
      return;
    }

    // 策略2：基于内容哈希的去重清理
    this.contentBasedCleanup();
  }

  // 增量清理：只检查变更文件相关的图片
  incrementalCleanup(changedFiles) {
    console.log(`  Using incremental cleanup for ${changedFiles.length} files`);

    // 收集所有图片文件及其内容哈希
    const allImages = fs.readdirSync(PUBLIC_ASSETS_DIR).filter(file =>
      /\.(png|jpg|jpeg|gif|webp|svg)$/i.test(file)
    );

    // 构建内容哈希映射
    const contentToImages = new Map(); // contentHash -> [imageName1, imageName2]

    allImages.forEach(imageName => {
      try {
        const imagePath = path.join(PUBLIC_ASSETS_DIR, imageName);
        const content = fs.readFileSync(imagePath);
        const contentHash = crypto.createHash('md5').update(content).digest('hex');

        if (!contentToImages.has(contentHash)) {
          contentToImages.set(contentHash, []);
        }
        contentToImages.get(contentHash).push(imageName);
      } catch (error) {
        console.warn(`  ⚠️  Could not read ${imageName}: ${error.message}`);
      }
    });

    // 找出有重复内容的图片组，保留最新的
    let duplicatesRemoved = 0;
    for (const [contentHash, imageNames] of contentToImages) {
      if (imageNames.length > 1) {
        // 按修改时间排序，保留最新的
        imageNames.sort((a, b) => {
          const statA = fs.statSync(path.join(PUBLIC_ASSETS_DIR, a));
          const statB = fs.statSync(path.join(PUBLIC_ASSETS_DIR, b));
          return statB.mtime - statA.mtime;
        });

        // 删除除第一个（最新）之外的所有重复文件
        for (let i = 1; i < imageNames.length; i++) {
          try {
            fs.unlinkSync(path.join(PUBLIC_ASSETS_DIR, imageNames[i]));
            console.log(`  ✓ Deleted duplicate: ${imageNames[i]} (same as ${imageNames[0]})`);
            duplicatesRemoved++;
            this.stats.imagesCleaned++;
          } catch (error) {
            console.error(`  ✗ Failed to delete ${imageNames[i]}: ${error.message}`);
          }
        }
      }
    }

    if (duplicatesRemoved === 0) {
      console.log('  ✓ No duplicate images found');
    } else {
      console.log(`  ✓ Removed ${duplicatesRemoved} duplicate images`);
    }
  }

  // 基于内容的清理：去重 + 智能检查
  contentBasedCleanup() {
    console.log('  Using content-based cleanup');

    // 1. 获取所有图片及其内容哈希
    const allImages = fs.readdirSync(PUBLIC_ASSETS_DIR).filter(file =>
      /\.(png|jpg|jpeg|gif|webp|svg)$/i.test(file)
    );

    if (allImages.length === 0) {
      console.log('  ✓ No images to clean');
      return;
    }

    const contentToImages = new Map();
    const imageToContent = new Map();

    // 计算所有图片的内容哈希
    allImages.forEach(imageName => {
      try {
        const imagePath = path.join(PUBLIC_ASSETS_DIR, imageName);
        const content = fs.readFileSync(imagePath);
        const contentHash = crypto.createHash('md5').update(content).digest('hex');

        imageToContent.set(imageName, contentHash);

        if (!contentToImages.has(contentHash)) {
          contentToImages.set(contentHash, []);
        }
        contentToImages.get(contentHash).push(imageName);
      } catch (error) {
        console.warn(`  ⚠️  Could not read ${imageName}: ${error.message}`);
      }
    });

    // 2. 处理重复内容的图片（去重）
    let duplicatesRemoved = 0;
    for (const [contentHash, imageNames] of contentToImages) {
      if (imageNames.length > 1) {
        // 按文件名排序，保留字典序最小的（通常是最早的）
        imageNames.sort();

        // 删除重复的图片
        for (let i = 1; i < imageNames.length; i++) {
          try {
            fs.unlinkSync(path.join(PUBLIC_ASSETS_DIR, imageNames[i]));
            console.log(`  ✓ Deleted duplicate: ${imageNames[i]} (same content as ${imageNames[0]})`);
            duplicatesRemoved++;
            this.stats.imagesCleaned++;
          } catch (error) {
            console.error(`  ✗ Failed to delete ${imageNames[i]}: ${error.message}`);
          }
        }
      }
    }

    // 3. 对于小项目，可以做一个快速的使用检查
    const remainingImages = allImages.filter(img =>
      fs.existsSync(path.join(PUBLIC_ASSETS_DIR, img))
    );

    if (remainingImages.length <= 50) {
      // 只有50个以下的图片时，做一个快速检查
      this.quickUsageCheck(remainingImages);
    }

    if (duplicatesRemoved === 0) {
      console.log('  ✓ No duplicate images found');
    } else {
      console.log(`  ✓ Removed ${duplicatesRemoved} duplicate images`);
    }
  }

  // 快速使用检查（仅针对小量图片）
  quickUsageCheck(images) {
    if (images.length === 0) return;

    console.log(`  🔍 Quick usage check for ${images.length} images...`);

    // 使用 grep 快速搜索图片引用（比逐个读取文件快）
    const { execSync } = require('child_process');

    let unusedCount = 0;
    images.forEach(imageName => {
      try {
        // 使用 grep 在所有 .md 文件中搜索图片名
        const grepResult = execSync(
          `grep -r "${imageName}" --include="*.md" . || true`,
          { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] }
        );

        if (!grepResult.trim()) {
          // 如果没有找到引用，删除这个图片
          fs.unlinkSync(path.join(PUBLIC_ASSETS_DIR, imageName));
          console.log(`  ✓ Deleted unused: ${imageName}`);
          unusedCount++;
          this.stats.imagesCleaned++;
        }
      } catch (error) {
        // grep 没找到或其他错误，保留图片（安全起见）
      }
    });

    if (unusedCount > 0) {
      console.log(`  ✓ Removed ${unusedCount} unused images`);
    }
  }

  // 递归查找所有 Markdown 文件
  findMarkdownFiles(dir, files = []) {
    try {
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
    } catch (error) {
      console.warn(`Warning: Could not read directory ${dir}: ${error.message}`);
    }

    return files;
  }

  async processChangedFiles() {
    // 获取变更的 MD 文件
    const { execSync } = require('child_process');

    try {
      // 获取所有变更的 MD 文件（包括暂存、未暂存和未跟踪）
      // 同时检测相对于 HEAD 的变更（用于 sync.sh 场景）
      // 禁用 Git 的路径引号，以便正确处理中文文件名
      const changedFiles = execSync(
        `(git -c core.quotePath=false diff --cached --name-only; git -c core.quotePath=false diff --name-only; git -c core.quotePath=false diff HEAD --name-only; git -c core.quotePath=false ls-files --others --exclude-standard) | grep "\\.md$" | sort -u || true`,
        { encoding: 'utf8' }
      ).trim().split('\n').filter(f => f);

      if (changedFiles.length === 0 || (changedFiles.length === 1 && !changedFiles[0])) {
        console.log('No markdown files changed.');

        // 即使没有文件变更，也执行清理检查
        this.cleanUnusedImages([]);

        // 输出统计
        console.log('\n📊 Statistics:');
        console.log(`  Files modified: ${this.stats.filesModified}`);
        console.log(`  Images downloaded: ${this.stats.imagesDownloaded}`);
        console.log(`  Images processed: ${this.stats.imagesProcessed}`);
        console.log(`  Embedded images extracted: ${this.stats.embeddedImagesExtracted}`);
        console.log(`  Images cleaned: ${this.stats.imagesCleaned}`);
        return;
      }

      console.log(`Found ${changedFiles.length} changed markdown files.`);

      for (const file of changedFiles) {
        if (fs.existsSync(file)) {
          await this.processMarkdownFile(file);
        }
      }

      // 处理完所有文件后，执行智能清理（传入变更文件列表）
      this.cleanUnusedImages(changedFiles);

      // 输出统计
      console.log('\n📊 Statistics:');
      console.log(`  Files modified: ${this.stats.filesModified}`);
      console.log(`  Images downloaded: ${this.stats.imagesDownloaded}`);
      console.log(`  Images processed: ${this.stats.imagesProcessed}`);
      console.log(`  Embedded images extracted: ${this.stats.embeddedImagesExtracted}`);
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