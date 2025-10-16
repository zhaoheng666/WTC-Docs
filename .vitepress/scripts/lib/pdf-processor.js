#!/usr/bin/env node

/**
 * PDF 文件处理器
 * 功能：
 * 1. 扫描新增的 PDF 文件
 * 2. 将 PDF 文件复制到 public/pdf/ 目录
 * 3. 在其他/index.md 中自动添加链接
 * 4. 保持文件名一致性
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 获取 docs 目录路径
const docsDir = path.resolve(__dirname, '../..');
const publicPdfDir = path.join(docsDir, 'public', 'pdf');
const otherIndexPath = path.join(docsDir, '其他', 'index.md');

console.log('🔍 PDF 文件处理器启动...');
console.log(`📁 处理目录: ${docsDir}`);

/**
 * 确保 PDF 目录存在
 */
function ensurePdfDirectory() {
    if (!fs.existsSync(publicPdfDir)) {
        fs.mkdirSync(publicPdfDir, { recursive: true });
        console.log(`📁 创建 PDF 目录: ${publicPdfDir}`);
    }
}

/**
 * 清理文件名，移除或替换特殊字符
 */
function sanitizeFileName(filename) {
    const name = path.parse(filename).name;
    const ext = path.parse(filename).ext;

    // 替换特殊字符和空格
    const cleanName = name
        .replace(/[<>:"|?*]/g, '') // 移除 Windows 不支持的字符
        .replace(/\s+/g, '_')      // 空格替换为下划线
        .replace(/[()（）]/g, '')   // 移除括号
        .replace(/[-]+/g, '-')     // 多个连字符替换为单个
        .replace(/[_]+/g, '_')     // 多个下划线替换为单个
        .replace(/^[-_]+|[-_]+$/g, ''); // 移除开头和结尾的连字符、下划线

    return cleanName + ext;
}

/**
 * 获取所有 PDF 文件（包括新增的和已存在的）
 */
function getAllPdfFiles() {
    const pdfFiles = [];

    function scanDirectory(dir) {
        try {
            const items = fs.readdirSync(dir, { withFileTypes: true });

            for (const item of items) {
                const fullPath = path.join(dir, item.name);

                if (item.isDirectory()) {
                    // 跳过一些不需要扫描的目录
                    const skipDirs = ['.git', '.vitepress', 'node_modules', 'public'];
                    if (!skipDirs.includes(item.name)) {
                        scanDirectory(fullPath);
                    }
                } else if (item.isFile() && item.name.toLowerCase().endsWith('.pdf')) {
                    const relativePath = path.relative(docsDir, fullPath);
                    const cleanName = sanitizeFileName(item.name);
                    pdfFiles.push({
                        fullPath,
                        relativePath,
                        originalName: item.name,
                        cleanName: cleanName,
                        basename: path.basename(item.name, '.pdf')
                    });
                }
            }
        } catch (error) {
            console.warn(`⚠️  无法读取目录 ${dir}: ${error.message}`);
        }
    }

    scanDirectory(docsDir);
    return pdfFiles;
}

/**
 * 检查 PDF 是否需要处理（是否已存在于 public/pdf/ 中）
 */
function needsProcessing(pdfFile) {
    const targetPath = path.join(publicPdfDir, pdfFile.cleanName);

    if (!fs.existsSync(targetPath)) {
        return true; // 目标文件不存在，需要复制
    }

    // 比较文件修改时间和大小
    const sourceStats = fs.statSync(pdfFile.fullPath);
    const targetStats = fs.statSync(targetPath);

    return sourceStats.mtime > targetStats.mtime || sourceStats.size !== targetStats.size;
}

/**
 * 复制 PDF 文件到 public/pdf/ 目录并删除源文件
 */
function copyPdfFile(pdfFile) {
    const targetPath = path.join(publicPdfDir, pdfFile.cleanName);

    try {
        // 复制文件
        fs.copyFileSync(pdfFile.fullPath, targetPath);
        console.log(`📄 复制 PDF: ${pdfFile.relativePath} → public/pdf/${pdfFile.cleanName}`);

        // 删除源文件
        fs.unlinkSync(pdfFile.fullPath);
        console.log(`🗑️  删除源文件: ${pdfFile.relativePath}`);

        return true;
    } catch (error) {
        console.error(`❌ 处理失败: ${pdfFile.relativePath} - ${error.message}`);
        return false;
    }
}

/**
 * 读取其他/index.md 内容
 */
function readOtherIndexMd() {
    if (fs.existsSync(otherIndexPath)) {
        return fs.readFileSync(otherIndexPath, 'utf8');
    } else {
        return '# 其他分类\n\n## PDF 文档\n\n';
    }
}

/**
 * 确定 PDF 链接的基础路径
 */
function getPdfLinkBasePath() {
    // 检查是否在 GitHub Actions 环境
    if (process.env.GITHUB_ACTIONS) {
        return 'https://zhaoheng666.github.io/WTC-Docs/pdf';
    }

    // 检查是否有 VITE_BASE_URL 环境变量
    if (process.env.VITE_BASE_URL) {
        const baseUrl = process.env.VITE_BASE_URL;
        if (baseUrl.includes('localhost')) {
            return 'http://localhost:5173/WTC-Docs/pdf';
        } else {
            return 'https://zhaoheng666.github.io/WTC-Docs/pdf';
        }
    }

    // 默认使用本地 HTTP 链接（适合 dev 环境和编辑器兼容性）
    return 'http://localhost:5173/WTC-Docs/pdf';
}

/**
 * 更新其他/index.md 中的 PDF 链接
 */
function updateOtherIndexMd(pdfFiles) {
    let content = readOtherIndexMd();

    // 检查是否已有 PDF 文档部分
    const pdfSectionRegex = /## PDF 文档[\\s\\S]*?(?=\\n## |$)/;
    const existingPdfSection = content.match(pdfSectionRegex);

    // 获取 PDF 链接基础路径
    const basePath = getPdfLinkBasePath();

    // 生成新的 PDF 链接列表
    const pdfLinks = pdfFiles
        .sort((a, b) => a.basename.localeCompare(b.basename))
        .map(pdf => {
            // 使用清理后的文件名，无需再次编码（因为已经清理过特殊字符）
            return `- [${pdf.basename}](${basePath}/${pdf.cleanName})`;
        })
        .join('\n');

    const newPdfSection = `## PDF 文档\n\n${pdfLinks}\n`;

    if (existingPdfSection) {
        // 替换现有的 PDF 部分
        content = content.replace(pdfSectionRegex, newPdfSection);
    } else {
        // 添加新的 PDF 部分
        if (!content.includes('## PDF 文档')) {
            content = content.trim() + '\n\n' + newPdfSection;
        }
    }

    // 写入更新后的内容
    fs.writeFileSync(otherIndexPath, content);
    console.log(`📝 更新 PDF 链接: ${pdfFiles.length} 个文件 (使用路径: ${basePath})`);
}

/**
 * 主处理函数
 */
function processPdfFiles() {
    ensurePdfDirectory();

    // 获取所有 PDF 文件
    const allPdfFiles = getAllPdfFiles();
    console.log(`📊 发现 ${allPdfFiles.length} 个 PDF 文件`);

    if (allPdfFiles.length === 0) {
        console.log('✅ 没有找到 PDF 文件');
        return;
    }

    // 筛选需要处理的文件
    const pdfFilesToProcess = allPdfFiles.filter(needsProcessing);
    console.log(`📋 需要处理 ${pdfFilesToProcess.length} 个 PDF 文件`);

    let processedCount = 0;

    // 复制需要处理的 PDF 文件
    for (const pdfFile of pdfFilesToProcess) {
        if (copyPdfFile(pdfFile)) {
            processedCount++;
        }
    }

    // 更新 其他/index.md 链接（包含所有 PDF，不仅仅是新处理的）
    updateOtherIndexMd(allPdfFiles);

    // 输出统计信息
    console.log('\\n📊 处理统计:');
    console.log(`  • 发现 PDF 文件: ${allPdfFiles.length} 个`);
    console.log(`  • 新复制文件: ${processedCount} 个`);
    console.log(`  • 链接已更新: 其他/index.md`);

    if (processedCount > 0) {
        console.log('\\n✅ PDF 处理完成');
    } else {
        console.log('\\n✅ PDF 文件已是最新状态');
    }
}

// 执行主函数
try {
    processPdfFiles();
} catch (error) {
    console.error('❌ PDF 处理失败:', error.message);
    process.exit(1);
}