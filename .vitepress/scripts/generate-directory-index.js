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
function generateFileTree(dirPath, dirName, depth = 0, rootDirPath = null) {
  const items = []

  // 第一层调用时，记录根目录路径
  if (depth === 0 && rootDirPath === null) {
    rootDirPath = dirPath
  }

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
      const subItems = generateFileTree(subPath, subDir, depth + 1, rootDirPath)

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

      // 生成相对于根目录（index.md 所在目录）的链接路径
      let relativePath
      if (depth === 0) {
        // 一级目录：直接使用文件名，进行URL编码
        relativePath = encodeUrlPath(displayName)
      } else {
        // 子目录：生成相对于根目录的相对路径，进行URL编码
        const fullPath = path.relative(rootDirPath, path.join(dirPath, file))
          .replace(/\\/g, '/')
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

// 生成目录结构内容
function generateDirectoryStructure(fileTree) {
  if (fileTree.length === 0) {
    return `> 📭 该目录暂时没有文档内容。\n\n`
  }

  function renderItems(items, level = 0) {
    let result = ''
    let hasDirectories = false
    let directories = []
    let files = []
    let resources = []

    // 分类所有项目
    items.forEach(item => {
      if (item.type === 'directory') {
        directories.push(item)
        hasDirectories = true
      } else if (item.type === 'file') {
        files.push(item)
      } else if (item.type === 'resource') {
        resources.push(item)
      }
    })

    // 先渲染所有目录
    directories.forEach(item => {
      const indent = '  '.repeat(level)
      let line = ''

      if (level === 0) {
        // 一级目录：使用标题样式
        line = `${indent}\n#### 📁 ${item.displayName}\n\n`
        if (item.items && item.items.length > 0) {
          line += renderItems(item.items, level + 1)
        }
        line += '\n'
      } else {
        // 子目录：使用粗体样式
        line = `${indent}- **📂 ${item.displayName}**\n`
        if (item.items && item.items.length > 0) {
          line += renderItems(item.items, level + 1)
        }
      }

      result += line
    })

    // 如果有目录，并且还有文件，添加分隔
    if (hasDirectories && (files.length > 0 || resources.length > 0) && level === 0) {
      result += '\n#### 📝 其他\n\n'
    }

    // 然后渲染所有文件
    files.forEach(item => {
      const indent = '  '.repeat(level)
      const line = `${indent}- 📝 [${item.displayName}](${item.link})\n`
      result += line
    })

    // 最后渲染所有资源文件
    resources.forEach(item => {
      const indent = '  '.repeat(level)
      const icon = getFileIcon(item.ext)
      let line = ''

      if (item.link) {
        line = `${indent}- ${icon} [${item.displayName}](${item.link})\n`
      } else {
        line = `${indent}- ${icon} ${item.displayName}\n`
      }

      result += line
    })

    return result
  }

  return renderItems(fileTree)
}

// 更新或创建 index.md 文件
function updateIndexFile(indexPath, dirName, fileTree) {
  const newDirectoryStructure = generateDirectoryStructure(fileTree)

  if (fs.existsSync(indexPath)) {
    // 文件已存在，只更新目录结构部分
    const content = fs.readFileSync(indexPath, 'utf8')

    // 查找目录结构标记
    const structureStart = content.indexOf('## 📋 目录结构')
    const structureEndMarker = '\n---\n'
    const structureEnd = content.indexOf(structureEndMarker, structureStart)

    if (structureStart !== -1) {
      // 替换目录结构部分
      let updatedContent
      if (structureEnd !== -1) {
        // 保留 --- 之后的内容
        const beforeStructure = content.substring(0, structureStart)
        const afterStructure = content.substring(structureEnd)
        updatedContent = `${beforeStructure}## 📋 目录结构\n\n${newDirectoryStructure}\n${afterStructure}`
      } else {
        // 没有找到结束标记，只替换到文件末尾
        const beforeStructure = content.substring(0, structureStart)
        updatedContent = `${beforeStructure}## 📋 目录结构\n\n${newDirectoryStructure}\n\n---\n\n*📅 最后更新: ${new Date().toLocaleDateString('zh-CN')}*\n*🤖 此文件由构建系统自动生成*\n`
      }

      return updatedContent
    } else {
      // 没有找到目录结构标记，在现有内容后添加
      return `${content}\n\n## 📋 目录结构\n\n${newDirectoryStructure}\n\n---\n\n*📅 最后更新: ${new Date().toLocaleDateString('zh-CN')}*\n*🤖 此文件由构建系统自动生成*\n`
    }
  } else {
    // 文件不存在，创建新文件
    return `# ${dirName}\n\n本目录包含与${dirName}相关的文档和资源。\n\n## 📋 目录结构\n\n${newDirectoryStructure}\n\n---\n\n*📅 最后更新: ${new Date().toLocaleDateString('zh-CN')}*\n*🤖 此文件由构建系统自动生成*\n`
  }
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

  // 更新或创建 index.md 文件
  const content = updateIndexFile(indexPath, dirName, fileTree)

  // 写入 index.md
  try {
    const fileExisted = fs.existsSync(indexPath)
    fs.writeFileSync(indexPath, content, 'utf8')
    const action = fileExisted ? '更新' : '创建'
    console.log(`  ✅ 已${action}: ${dirName}/index.md (${fileTree.length} 项)`)
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