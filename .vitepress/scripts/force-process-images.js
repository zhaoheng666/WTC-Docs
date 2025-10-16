#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const crypto = require('crypto')

// 图片存放在 docs/assets/ (源码目录，非 public/)
const PUBLIC_ASSETS_DIR = path.join(__dirname, '../../assets')

if (!fs.existsSync(PUBLIC_ASSETS_DIR)) {
  fs.mkdirSync(PUBLIC_ASSETS_DIR, { recursive: true })
}

// 处理指定文件的内嵌图片
async function processFile(filePath) {
  if (!fs.existsSync(filePath)) {
    console.log(`❌ 文件不存在: ${filePath}`)
    return
  }

  console.log(`📄 处理文件: ${filePath}`)
  let content = fs.readFileSync(filePath, 'utf8')
  let modified = false
  let processed = 0

  // 匹配引用式图片定义: [imageX]: <data:image/...>
  const base64Pattern = /\[([^\]]+)\]:\s*<data:image\/([^;]+);base64,([^>]+)>/g
  const matches = []
  let match

  while ((match = base64Pattern.exec(content)) !== null) {
    matches.push({
      fullMatch: match[0],
      imageId: match[1],
      format: match[2],
      base64Data: match[3]
    })
  }

  console.log(`🔍 发现 ${matches.length} 个内嵌图片`)

  for (const { fullMatch, imageId, format, base64Data } of matches) {
    try {
      // 生成唯一文件名
      const timestamp = Date.now().toString()
      const hash = crypto.createHash('md5').update(base64Data).digest('hex').substring(0, 8)
      const newFilename = `${timestamp}_${hash}.${format}`
      const newFilePath = path.join(PUBLIC_ASSETS_DIR, newFilename)

      // 保存图片文件
      const buffer = Buffer.from(base64Data, 'base64')
      fs.writeFileSync(newFilePath, buffer)

      console.log(`  ✅ 处理 ${imageId}: ${newFilename}`)

      // 替换内容中的图片引用
      const newReference = `[${imageId}]: http://localhost:5173/WTC-Docs/assets/${newFilename}`
      content = content.replace(fullMatch, newReference)
      modified = true
      processed++

    } catch (error) {
      console.error(`  ❌ 处理 ${imageId} 失败:`, error.message)
    }
  }

  if (modified) {
    fs.writeFileSync(filePath, content)
    console.log(`✅ 文件已更新，处理了 ${processed} 个图片`)
  } else {
    console.log(`ℹ️  文件无需修改`)
  }

  return processed
}

// 主函数
async function main() {
  const filePath = process.argv[2]
  if (!filePath) {
    console.log('用法: node force-process-images.js <markdown-file-path>')
    process.exit(1)
  }

  const totalProcessed = await processFile(filePath)
  console.log(`\n🎉 完成处理，共处理 ${totalProcessed} 个内嵌图片`)
}

main().catch(console.error)