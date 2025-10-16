#!/usr/bin/env node

/**
 * 批量重命名文件脚本
 * 功能：
 * 1. 去掉前缀如 "Q3`24-Slots-", "Q2 2024 Slots", "Q1 25 Slots" 等
 * 2. 去掉后缀 "-程序", " 程序"
 * 3. 清理文件名并规范化
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 获取 docs 目录路径
const docsDir = path.resolve(__dirname, '../..');

console.log('📝 文件重命名脚本启动...');
console.log(`📁 处理目录: ${docsDir}`);

/**
 * 清理文件名
 */
function cleanFileName(fileName) {
    const ext = path.extname(fileName);
    let baseName = path.basename(fileName, ext);

    // 去掉各种前缀模式
    const prefixPatterns = [
        /^Q\d+\s*`\d+-Slots-/i,                    // Q3`24-Slots-
        /^Q\d+\s+\d+\s+Slots\s+/i,                 // Q2 2024 Slots
        /^Q\d+\s+\d+\s+Slots\s*/i,                 // Q1 25 Slots
        /^Q\d+\s*\d*\s*Slots\s*/i,                 // Q3 2024 Slots, Q4 Slots 等
        /^Q\d+\s+\d+\s+/i,                         // Q1 2025, Q2 2024 等（不含Slots的）
        /^Q\d+\s*/i,                               // Q1, Q2, Q3, Q4 等单独的季度前缀
    ];

    // 应用前缀清理规则
    for (const pattern of prefixPatterns) {
        baseName = baseName.replace(pattern, '');
    }

    // 去掉后缀 "-程序", " 程序"
    baseName = baseName.replace(/[-\s]*程序\s*$/i, '');

    // 清理多余的空格和连字符
    baseName = baseName.replace(/\s+/g, ' ').replace(/[-\s]+$/g, '').replace(/^[-\s]+/g, '');

    // 如果清理后为空，使用原文件名（去掉扩展名）
    if (!baseName.trim()) {
        baseName = path.basename(fileName, ext);
    }

    return baseName + ext;
}

/**
 * 查找所有需要重命名的文件
 */
function findFilesToRename() {
    const filesToRename = [];

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
                } else if (item.isFile() && (item.name.endsWith('.md') || item.name.endsWith('.pdf'))) {
                    const originalName = item.name;
                    const cleanedName = cleanFileName(originalName);

                    // 如果文件名有变化，加入重命名列表
                    if (originalName !== cleanedName) {
                        const relativePath = path.relative(docsDir, fullPath);
                        filesToRename.push({
                            fullPath,
                            relativePath,
                            originalName,
                            cleanedName,
                            directory: path.dirname(fullPath)
                        });
                    }
                }
            }
        } catch (error) {
            console.warn(`⚠️  无法读取目录 ${dir}: ${error.message}`);
        }
    }

    scanDirectory(docsDir);
    return filesToRename;
}

/**
 * 执行文件重命名
 */
function renameFiles(files) {
    let successCount = 0;
    let failCount = 0;

    for (const file of files) {
        const newPath = path.join(file.directory, file.cleanedName);

        try {
            // 检查目标文件是否已存在
            if (fs.existsSync(newPath) && newPath !== file.fullPath) {
                console.warn(`⚠️  目标文件已存在，跳过: ${file.relativePath} -> ${file.cleanedName}`);
                continue;
            }

            // 执行重命名
            fs.renameSync(file.fullPath, newPath);
            console.log(`✅ 重命名: ${file.relativePath} -> ${file.cleanedName}`);
            successCount++;

        } catch (error) {
            console.error(`❌ 重命名失败: ${file.relativePath} - ${error.message}`);
            failCount++;
        }
    }

    return { successCount, failCount };
}

/**
 * 主函数
 */
function main() {
    console.log('🔍 扫描需要重命名的文件...');

    const filesToRename = findFilesToRename();

    if (filesToRename.length === 0) {
        console.log('✅ 没有发现需要重命名的文件');
        return;
    }

    console.log(`📋 发现 ${filesToRename.length} 个需要重命名的文件:`);
    filesToRename.forEach((file, index) => {
        console.log(`  ${index + 1}. ${file.originalName} -> ${file.cleanedName}`);
    });

    console.log('\n🔄 开始执行重命名...');
    const result = renameFiles(filesToRename);

    console.log('\n📊 重命名统计:');
    console.log(`  ✅ 成功: ${result.successCount} 个`);
    console.log(`  ❌ 失败: ${result.failCount} 个`);
    console.log(`  📁 总计: ${filesToRename.length} 个`);

    if (result.successCount > 0) {
        console.log('\n✅ 文件重命名完成！');
        console.log('💡 提示: 请检查文档中的内部链接是否需要更新');
    }
}

// 执行主函数
try {
    main();
} catch (error) {
    console.error('❌ 脚本执行失败:', error.message);
    process.exit(1);
}