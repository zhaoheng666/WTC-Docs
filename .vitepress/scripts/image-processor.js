#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const https = require('https');
const http = require('http');
const { URL } = require('url');

const BASE_URL = process.env.GITHUB_ACTIONS ? 'https://zhaoheng666.github.io/WTC-Docs' : 'http://localhost:5173/WTC-Docs';
const PUBLIC_ASSETS_DIR = path.join(__dirname, '../../public/assets');
const IMAGE_MANIFEST = path.join(__dirname, '../../public/image-manifest.json');

class ImageProcessor {
  constructor() {
    this.imageMap = this.loadImageManifest();
    this.processedImages = new Set();
    this.ensureAssetsDirectory();
  }

  ensureAssetsDirectory() {
    if (!fs.existsSync(PUBLIC_ASSETS_DIR)) {
      fs.mkdirSync(PUBLIC_ASSETS_DIR, { recursive: true });
      console.log(`✓ Created assets directory: ${PUBLIC_ASSETS_DIR}`);
    }
  }

  loadImageManifest() {
    if (fs.existsSync(IMAGE_MANIFEST)) {
      try {
        return JSON.parse(fs.readFileSync(IMAGE_MANIFEST, 'utf8'));
      } catch (e) {
        console.warn('⚠ Failed to load image manifest, creating new one');
      }
    }
    return {};
  }

  saveImageManifest() {
    fs.writeFileSync(IMAGE_MANIFEST, JSON.stringify(this.imageMap, null, 2));
  }

  generateImageId(imagePath, content = null) {
    const timestamp = Date.now();
    const hash = crypto.createHash('md5');
    
    if (content) {
      hash.update(content);
    } else {
      hash.update(imagePath);
    }
    
    const shortHash = hash.digest('hex').substring(0, 8);
    return `${timestamp}_${shortHash}`;
  }

  getImageExtension(url) {
    const parsedUrl = new URL(url, 'http://example.com');
    const pathname = parsedUrl.pathname;
    const ext = path.extname(pathname).toLowerCase();
    return ext || '.png';
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
            resolve(true);
          });
        } else if (response.statusCode === 302 || response.statusCode === 301) {
          const redirectUrl = response.headers.location;
          this.downloadImage(redirectUrl, destPath).then(resolve).catch(reject);
        } else {
          reject(new Error(`Failed to download: ${response.statusCode}`));
        }
      }).on('error', reject);
    });
  }

  async processGiteeImage(url) {
    try {
      const imageId = this.generateImageId(url);
      const ext = this.getImageExtension(url);
      const filename = `${imageId}${ext}`;
      const destPath = path.join(PUBLIC_ASSETS_DIR, filename);
      
      if (!fs.existsSync(destPath)) {
        console.log(`  ↓ Downloading Gitee image: ${url}`);
        await this.downloadImage(url, destPath);
        console.log(`  ✓ Downloaded to: ${filename}`);
      }
      
      this.imageMap[url] = filename;
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

    const imageContent = fs.readFileSync(absoluteImagePath);
    const imageId = this.generateImageId(imagePath, imageContent);
    const ext = path.extname(imagePath);
    const filename = `${imageId}${ext}`;
    const destPath = path.join(PUBLIC_ASSETS_DIR, filename);
    
    if (!fs.existsSync(destPath)) {
      fs.copyFileSync(absoluteImagePath, destPath);
      console.log(`  ✓ Copied local image to: ${filename}`);
    }
    
    this.imageMap[imagePath] = filename;
    return `${BASE_URL}/assets/${filename}`;
  }

  async processMarkdownFile(filePath) {
    const relativePath = path.relative(process.cwd(), filePath);
    
    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;
    
    const imageRegex = /!\[([^\]]*)\]\(([^)]+)\)/g;
    const replacements = [];
    
    let match;
    while ((match = imageRegex.exec(content)) !== null) {
      const [fullMatch, altText, imageSrc] = match;
      let newImageSrc = imageSrc;
      
      // Skip already processed images
      if (imageSrc.includes('/assets/') || imageSrc.includes('localhost:5173') || imageSrc.includes('github.io')) {
        continue;
      }
      
      if (imageSrc.includes('gitee.com')) {
        newImageSrc = await this.processGiteeImage(imageSrc);
        modified = true;
      } else if (!imageSrc.startsWith('http') && !imageSrc.startsWith('//')) {
        newImageSrc = this.processLocalImage(imageSrc, filePath);
        modified = true;
      }
      
      if (newImageSrc !== imageSrc) {
        replacements.push({
          original: fullMatch,
          replacement: `![${altText}](${newImageSrc})`
        });
      }
    }
    
    if (modified) {
      console.log(`📄 Processing: ${relativePath}`);
      for (const { original, replacement } of replacements) {
        content = content.replace(original, replacement);
      }
      
      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`  ✓ Updated ${replacements.length} image references`);
    }
    
    return modified;
  }

  async processAllMarkdownFiles(directory = null) {
    const docsDir = directory || path.join(__dirname, '../..');
    let processedCount = 0;
    let modifiedCount = 0;
    
    const processDir = async (dir) => {
      const items = fs.readdirSync(dir);
      
      for (const item of items) {
        const itemPath = path.join(dir, item);
        
        // 跳过符号链接
        if (fs.lstatSync(itemPath).isSymbolicLink()) {
          continue;
        }
        
        const stat = fs.statSync(itemPath);
        
        if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
          await processDir(itemPath);
        } else if (stat.isFile() && item.endsWith('.md')) {
          processedCount++;
          const modified = await this.processMarkdownFile(itemPath);
          if (modified) modifiedCount++;
        }
      }
    };
    
    console.log('🚀 Starting image processing...\n');
    await processDir(docsDir);
    
    this.saveImageManifest();
    
    console.log('\n' + '='.repeat(50));
    console.log(`✅ Processing complete!`);
    console.log(`   Files scanned: ${processedCount}`);
    console.log(`   Files modified: ${modifiedCount}`);
    console.log(`   Images processed: ${Object.keys(this.imageMap).length}`);
    console.log('='.repeat(50));
    
    // 删除临时 manifest 文件
    if (fs.existsSync(IMAGE_MANIFEST)) {
      fs.unlinkSync(IMAGE_MANIFEST);
      console.log('   Cleaned up temporary manifest file');
    }
  }

  async cleanUnusedImages() {
    console.log('\n🧹 Cleaning unused images...');
    
    const usedImages = new Set();
    const docsDir = path.join(__dirname, '../..');
    
    const scanDir = (dir) => {
      const items = fs.readdirSync(dir);
      
      for (const item of items) {
        const itemPath = path.join(dir, item);
        
        // 跳过符号链接
        if (fs.lstatSync(itemPath).isSymbolicLink()) {
          continue;
        }
        
        const stat = fs.statSync(itemPath);
        
        if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
          scanDir(itemPath);
        } else if (stat.isFile() && item.endsWith('.md')) {
          const content = fs.readFileSync(itemPath, 'utf8');
          const imageRegex = /!\[([^\]]*)\]\(([^)]+)\)/g;
          
          let match;
          while ((match = imageRegex.exec(content)) !== null) {
            const imageSrc = match[2];
            if (imageSrc.includes('/assets/')) {
              const filename = path.basename(imageSrc);
              usedImages.add(filename);
            }
          }
        }
      }
    };
    
    scanDir(docsDir);
    
    const assetFiles = fs.readdirSync(PUBLIC_ASSETS_DIR);
    let removedCount = 0;
    
    for (const file of assetFiles) {
      if (!usedImages.has(file) && !file.startsWith('.')) {
        const filePath = path.join(PUBLIC_ASSETS_DIR, file);
        fs.unlinkSync(filePath);
        removedCount++;
        console.log(`  ✗ Removed unused: ${file}`);
      }
    }
    
    console.log(`  ✓ Cleaned ${removedCount} unused images`);
  }
}

async function main() {
  const processor = new ImageProcessor();
  const args = process.argv.slice(2);
  
  try {
    if (args.includes('--clean')) {
      await processor.cleanUnusedImages();
    } else if (args.includes('--file')) {
      const fileIndex = args.indexOf('--file');
      const filePath = args[fileIndex + 1];
      if (filePath) {
        await processor.processMarkdownFile(path.resolve(filePath));
        processor.saveImageManifest();
      }
    } else {
      await processor.processAllMarkdownFiles();
    }
  } finally {
    // 清理临时 manifest 文件（单文件处理和清理模式也要清理）
    if (fs.existsSync(IMAGE_MANIFEST) && !args.includes('--keep-manifest')) {
      fs.unlinkSync(IMAGE_MANIFEST);
      if (args.includes('--file') || args.includes('--clean')) {
        console.log('Cleaned up temporary manifest file');
      }
    }
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = ImageProcessor;