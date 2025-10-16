#!/usr/bin/env node

/**
 * 更新文档内容中的标题格式
 * 功能：
 * 1. 更新文档内容中 # Q3`25-Slots-xxx-程序 格式的标题
 * 2. 去掉前缀和后缀，保留核心内容
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 获取 docs 目录路径
const docsDir = path.resolve(__dirname, '../..');

console.log('🔄 文档内容标题更新脚本启动...');
console.log(`📁 处理目录: ${docsDir}`);

/**
 * 清理标题文本
 */
function cleanTitle(title) {
    // 去掉各种前缀模式
    const prefixPatterns = [
        /^#\s*Q\d+\s*`\d*-*Slots-*/i,              // # Q3`25-Slots-
        /^#\s*Q\d+\s+\d+\s+Slots\s+/i,             // # Q2 2024 Slots
        /^#\s*Q\d+\s+\d+\s+Slots\s*/i,             // # Q1 25 Slots
        /^#\s*Q\d+\s*\d*\s*Slots\s*/i,             // # Q3 2024 Slots, # Q4 Slots 等
        /^#\s*Q\d+\s+\d+\s+/i,                     // # Q1 2025, # Q2 2024 等（不含Slots的）
        /^#\s*Q\d+\s*/i,                           // # Q1, # Q2, # Q3, # Q4 等单独的季度前缀
    ];

    let cleanedTitle = title;

    // 应用前缀清理规则
    for (const pattern of prefixPatterns) {
        cleanedTitle = cleanedTitle.replace(pattern, '# ');
    }

    // 去掉后缀 "-程序", " 程序"
    cleanedTitle = cleanedTitle.replace(/[-\s]*程序\s*$/i, '');

    // 清理多余的空格和连字符
    cleanedTitle = cleanedTitle.replace(/\s+/g, ' ').replace(/[-\s]+$/g, '').replace(/^#\s*[-\s]+/g, '# ');

    return cleanedTitle;
}

/**
 * 处理单个文件
 */
function processFile(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const lines = content.split('\n');
        let hasChanges = false;

        // 处理每一行
        const processedLines = lines.map(line => {
            // 只处理以 # 开头的标题行，且包含需要清理的模式
            if (line.startsWith('#') && (/Q\d+.*程序/i.test(line) || /Q\d+\s+\d+\s+/i.test(line))) {
                const cleanedLine = cleanTitle(line);
                if (cleanedLine !== line) {
                    hasChanges = true;
                    return cleanedLine;
                }
            }
            return line;
        });

        // 如果有变化，写回文件
        if (hasChanges) {
            const newContent = processedLines.join('\n');
            fs.writeFileSync(filePath, newContent);
            return true;
        }

        return false;
    } catch (error) {
        console.error(`❌ 处理文件失败: ${filePath} - ${error.message}`);
        return false;
    }
}

/**
 * 扫描和处理文件
 */
function processFiles() {
    const processedFiles = [];

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
                } else if (item.isFile() && item.name.endsWith('.md')) {
                    if (processFile(fullPath)) {
                        const relativePath = path.relative(docsDir, fullPath);
                        processedFiles.push(relativePath);
                    }
                }
            }
        } catch (error) {
            console.warn(`⚠️  无法读取目录 ${dir}: ${error.message}`);
        }
    }

    scanDirectory(docsDir);
    return processedFiles;
}

/**
 * 主函数
 */
function main() {
    console.log('🔍 扫描需要更新标题的文件...');

    const processedFiles = processFiles();

    if (processedFiles.length === 0) {
        console.log('✅ 没有发现需要更新标题的文件');
        return;
    }

    console.log(`📋 已更新 ${processedFiles.length} 个文件的标题:`);
    processedFiles.forEach((file, index) => {
        console.log(`  ${index + 1}. ${file}`);
    });

    console.log('\n✅ 文档标题更新完成！');
}

// 执行主函数
try {
    main();
} catch (error) {
    console.error('❌ 脚本执行失败:', error.message);
    process.exit(1);
}