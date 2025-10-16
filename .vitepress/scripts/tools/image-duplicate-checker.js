#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const crypto = require('crypto')

// 图片存放在 docs/assets/ (源码目录，非 public/)
const PUBLIC_ASSETS_DIR = path.join(__dirname, '../../assets')

console.log('=== 图片内容去重检查工具 ===')

if (!fs.existsSync(PUBLIC_ASSETS_DIR)) {
  console.log('❌ assets 目录不存在')
  process.exit(1)
}

// 获取所有图片文件
const imageFiles = fs.readdirSync(PUBLIC_ASSETS_DIR).filter(file =>
  /\.(png|jpg|jpeg|gif|webp|svg)$/i.test(file)
)

console.log(`📊 总图片数量: ${imageFiles.length}`)
console.log('🔍 正在计算内容哈希...')

// 计算每个图片的内容哈希
const hashToFiles = new Map() // hash -> [file1, file2, ...]
let processedCount = 0

for (const fileName of imageFiles) {
  try {
    const filePath = path.join(PUBLIC_ASSETS_DIR, fileName)
    const content = fs.readFileSync(filePath)
    const hash = crypto.createHash('md5').update(content).digest('hex')

    if (!hashToFiles.has(hash)) {
      hashToFiles.set(hash, [])
    }
    hashToFiles.get(hash).push(fileName)

    processedCount++
    if (processedCount % 50 === 0) {
      console.log(`  处理进度: ${processedCount}/${imageFiles.length}`)
    }
  } catch (error) {
    console.warn(`⚠️  无法读取文件 ${fileName}: ${error.message}`)
  }
}

console.log(`✅ 处理完成: ${processedCount}/${imageFiles.length}`)

// 查找重复内容的文件组
let duplicateGroups = []
let totalDuplicates = 0

for (const [hash, files] of hashToFiles) {
  if (files.length > 1) {
    duplicateGroups.push({ hash, files })
    totalDuplicates += files.length - 1 // 除了保留的一个，其余都是重复的
  }
}

console.log('')
console.log('📋 重复文件检查结果:')
console.log(`  唯一内容: ${hashToFiles.size}`)
console.log(`  重复组数: ${duplicateGroups.length}`)
console.log(`  可删除的重复文件: ${totalDuplicates}`)

if (duplicateGroups.length > 0) {
  console.log('')
  console.log('🔍 重复文件详情:')

  duplicateGroups.forEach((group, index) => {
    console.log(`\n${index + 1}. 内容哈希: ${group.hash.substring(0, 16)}...`)
    console.log(`   重复文件 (${group.files.length}个):`)

    // 按修改时间排序，显示最新的在前面
    const sortedFiles = group.files.map(fileName => {
      const filePath = path.join(PUBLIC_ASSETS_DIR, fileName)
      const stats = fs.statSync(filePath)
      return { fileName, mtime: stats.mtime, size: stats.size }
    }).sort((a, b) => b.mtime - a.mtime)

    sortedFiles.forEach((file, i) => {
      const status = i === 0 ? '(保留)' : '(可删除)'
      const sizeKB = (file.size / 1024).toFixed(1)
      console.log(`     - ${file.fileName} ${status} [${sizeKB}KB, ${file.mtime.toISOString().split('T')[0]}]`)
    })
  })

  // 如果用户传入 --delete 参数，执行删除
  if (process.argv.includes('--delete')) {
    console.log('')
    console.log('🗑️  开始删除重复文件...')

    let deletedCount = 0
    duplicateGroups.forEach(group => {
      // 按修改时间排序，保留最新的
      const sortedFiles = group.files.map(fileName => {
        const filePath = path.join(PUBLIC_ASSETS_DIR, fileName)
        const stats = fs.statSync(filePath)
        return { fileName, mtime: stats.mtime, path: filePath }
      }).sort((a, b) => b.mtime - a.mtime)

      // 删除除第一个（最新）之外的所有文件
      for (let i = 1; i < sortedFiles.length; i++) {
        try {
          fs.unlinkSync(sortedFiles[i].path)
          console.log(`  ✅ 删除: ${sortedFiles[i].fileName}`)
          deletedCount++
        } catch (error) {
          console.error(`  ❌ 删除失败: ${sortedFiles[i].fileName} - ${error.message}`)
        }
      }
    })

    console.log(`\n🎉 删除完成: ${deletedCount} 个重复文件被删除`)
    console.log(`💾 节省空间: ~${((imageFiles.length - (imageFiles.length - deletedCount)) / imageFiles.length * 100).toFixed(1)}%`)
  } else {
    console.log('')
    console.log('💡 如要删除重复文件，请运行:')
    console.log(`   node ${path.basename(__filename)} --delete`)
  }
} else {
  console.log('🎉 没有发现重复内容的图片文件！')
}

// 统计信息
const totalSize = imageFiles.reduce((sum, fileName) => {
  try {
    const filePath = path.join(PUBLIC_ASSETS_DIR, fileName)
    return sum + fs.statSync(filePath).size
  } catch (error) {
    return sum
  }
}, 0)

console.log('')
console.log('📊 统计信息:')
console.log(`  总文件数: ${imageFiles.length}`)
console.log(`  总大小: ${(totalSize / 1024 / 1024).toFixed(2)} MB`)
console.log(`  平均大小: ${(totalSize / imageFiles.length / 1024).toFixed(1)} KB`)