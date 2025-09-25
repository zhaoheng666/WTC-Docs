#!/usr/bin/env node

const fs = require('fs')
const path = require('path')

// 获取环境配置
const isGitHubActions = process.env.GITHUB_ACTIONS === 'true'
const baseUrl = isGitHubActions
  ? 'https://zhaoheng666.github.io/WTC-Docs'
  : 'http://localhost:5173/WTC-Docs'

console.log(`📁 开始生成目录索引文件树...`)
console.log(`  • 环境: ${isGitHubActions ? 'GitHub Actions' : '本地开发'}`)
console.log(`  • 目标 URL: ${baseUrl}`)

// 需要处理的一级目录列表
const targetDirectories = [
  '活动',
  '关卡',
  '工程-工具',
  '故障排查',
  '服务器',
  '需求',
  '成员',
  '其他'
]

// 忽略的文件和目录
const ignoreList = [
  '.DS_Store',
  'node_modules',
  '.git',
  '.vitepress',
  'public',
  'index.md', // 不包含自身
  // 临时文件
  '.tmp',
  '~$',
]

// 检查是否应该忽略
function shouldIgnore(fileName) {
  return ignoreList.some(pattern => {
    if (pattern.includes('*')) {
      // 通配符匹配
      const regex = new RegExp(pattern.replace('*', '.*'))
      return regex.test(fileName)
    } else if (pattern.startsWith('~') || pattern.startsWith('.')) {
      // 前缀匹配
      return fileName.startsWith(pattern)
    } else {
      // 完全匹配
      return fileName === pattern
    }
  })
}

// 获取文件的显示名称
function getDisplayName(fileName) {
  if (fileName.endsWith('.md')) {
    return fileName.replace('.md', '')
  }
  return fileName
}

// URL安全编码 - 处理链接中的特殊字符
function encodeUrlPath(filePath) {
  // 将路径按 / 分割，对每个部分进行编码，然后重新组合
  return filePath.split('/').map(part => {
    // 保留常见的安全字符，编码其他特殊字符
    return encodeURIComponent(part)
      .replace(/!/g, '!')  // 恢复感叹号
      .replace(/'/g, "'")  // 恢复单引号
      .replace(/\(/g, '(') // 恢复左括号
      .replace(/\)/g, ')') // 恢复右括号
      .replace(/\*/g, '*') // 恢复星号
  }).join('/')
}

// 生成友好的文档树结构
function generateFileTree(dirPath, dirName, depth = 0) {
  const items = []

  try {
    const files = fs.readdirSync(dirPath).sort()

    // 分类处理：目录优先，然后是文件
    const directories = []
    const markdownFiles = []
    const otherFiles = []

    files.forEach(file => {
      if (shouldIgnore(file)) return

      const filePath = path.join(dirPath, file)
      const stat = fs.statSync(filePath)

      if (stat.isDirectory()) {
        directories.push(file)
      } else if (file.endsWith('.md')) {
        markdownFiles.push(file)
      } else {
        otherFiles.push(file)
      }
    })

    // 处理子目录
    directories.forEach(subDir => {
      const subPath = path.join(dirPath, subDir)
      const subItems = generateFileTree(subPath, subDir, depth + 1)

      if (subItems.length > 0) {
        items.push({
          type: 'directory',
          name: subDir,
          displayName: getDisplayName(subDir),
          items: subItems,
          depth
        })
      }
    })

    // 处理 Markdown 文件
    markdownFiles.forEach(file => {
      const displayName = getDisplayName(file)

      // 生成相对于当前目录的链接路径
      let relativePath
      if (depth === 0) {
        // 一级目录：直接使用文件名，进行URL编码
        relativePath = encodeUrlPath(displayName)
      } else {
        // 子目录：使用相对路径，进行URL编码
        const fullPath = path.relative(process.cwd(), path.join(dirPath, file))
          .replace(/\\/g, '/')
          .replace(/^docs\//, '')
          .replace(/\.md$/, '')
        relativePath = encodeUrlPath(fullPath)
      }

      items.push({
        type: 'file',
        name: file,
        displayName,
        link: relativePath,
        depth
      })
    })

    // 处理其他文件（如图片、PDF等）
    otherFiles.forEach(file => {
      const ext = path.extname(file).toLowerCase()
      const displayName = getDisplayName(file)

      let link = null
      if (['.pdf', '.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp'].includes(ext)) {
        // 资源文件使用完整 URL，进行URL编码
        const relativePath = path.relative(process.cwd(), path.join(dirPath, file))
          .replace(/\\/g, '/')
          .replace(/^docs\//, '/')
        link = `${baseUrl}${encodeUrlPath(relativePath)}`
      }

      items.push({
        type: 'resource',
        name: file,
        displayName,
        link,
        ext,
        depth
      })
    })

  } catch (error) {
    console.warn(`  ⚠️  读取目录失败: ${dirPath}`)
  }

  return items
}

// 生成 Markdown 内容
function generateMarkdownContent(dirName, fileTree) {
  let content = `# ${dirName}\n\n`
  content += `本目录包含与${dirName}相关的文档和资源。\n\n`

  if (fileTree.length === 0) {
    content += `> 📭 该目录暂时没有文档内容。\n\n`
    return content
  }

  content += `## 📋 目录结构\n\n`

  function renderItems(items, level = 0) {
    let result = ''

    items.forEach(item => {
      const indent = '  '.repeat(level)
      let line = ''

      if (item.type === 'directory') {
        // 目录 - 使用更明显的样式区分
        if (level === 0) {
          // 一级目录：使用标题样式
          line = `${indent}\n### 📁 ${item.displayName}\n\n`
          if (item.items && item.items.length > 0) {
            line += renderItems(item.items, level + 1)
          }
          line += '\n'
        } else {
          // 子目录：使用粗体和背景色
          line = `${indent}- **📂 ${item.displayName}**\n`
          if (item.items && item.items.length > 0) {
            line += renderItems(item.items, level + 1)
          }
        }
      } else if (item.type === 'file') {
        // Markdown 文件 - 使用更清晰的图标
        line = `${indent}- 📝 [${item.displayName}](${item.link})\n`
      } else if (item.type === 'resource') {
        // 资源文件
        const icon = getFileIcon(item.ext)
        if (item.link) {
          line = `${indent}- ${icon} [${item.displayName}](${item.link})\n`
        } else {
          line = `${indent}- ${icon} ${item.displayName}\n`
        }
      }

      result += line
    })

    return result
  }

  content += renderItems(fileTree)
  content += '\n---\n\n'
  content += `*📅 最后更新: ${new Date().toLocaleDateString('zh-CN')}*\n`
  content += `*🤖 此文件由构建系统自动生成*\n`

  return content
}

// 获取文件图标
function getFileIcon(ext) {
  const iconMap = {
    '.pdf': '📕',
    '.png': '🖼️',
    '.jpg': '🖼️',
    '.jpeg': '🖼️',
    '.gif': '🖼️',
    '.svg': '🎨',
    '.webp': '🖼️',
    '.drawio': '📊',
    '.json': '⚙️',
    '.js': '📄',
    '.css': '🎨',
    '.html': '🌐',
    '.txt': '📄',
    '.log': '📋',
    '.md': '📝'
  }

  return iconMap[ext] || '📎'
}

// 处理单个目录
function processDirectory(dirName) {
  const dirPath = path.join(process.cwd(), dirName)
  const indexPath = path.join(dirPath, 'index.md')

  if (!fs.existsSync(dirPath)) {
    console.log(`  ⏭️  跳过不存在的目录: ${dirName}`)
    return
  }

  console.log(`  🔍 处理目录: ${dirName}`)

  // 生成文件树
  const fileTree = generateFileTree(dirPath, dirName)

  // 生成 Markdown 内容
  const content = generateMarkdownContent(dirName, fileTree)

  // 写入 index.md
  try {
    fs.writeFileSync(indexPath, content, 'utf8')
    console.log(`  ✅ 已更新: ${dirName}/index.md (${fileTree.length} 项)`)
  } catch (error) {
    console.error(`  ❌ 写入失败: ${indexPath}`)
    console.error(`     错误: ${error.message}`)
  }
}

// 主函数
function main() {
  let processedCount = 0
  let successCount = 0

  targetDirectories.forEach(dirName => {
    try {
      processDirectory(dirName)
      processedCount++
      successCount++
    } catch (error) {
      console.error(`  ❌ 处理目录 ${dirName} 时出错: ${error.message}`)
      processedCount++
    }
  })

  console.log(`📁 目录索引生成完成`)
  console.log(`  • 处理目录: ${processedCount} 个`)
  console.log(`  • 成功生成: ${successCount} 个`)
  console.log(`  • 失败数量: ${processedCount - successCount} 个`)
}

// 执行
if (require.main === module) {
  main()
}

module.exports = { main }