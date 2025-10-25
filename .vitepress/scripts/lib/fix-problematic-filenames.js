#!/usr/bin/env node

import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const docsDir = path.resolve(__dirname, '../../..')

// 温和的文件名修复配置
const CONFIG = {
  maxLength: 80,           // 最大文件名长度（比较宽松）
  ellipsis: '...',         // 省略符号
  dryRun: false           // 是否为预览模式
}

/**
 * 检查文件名是否有问题
 * @param {string} filename - 文件名
 * @returns {boolean} 是否有问题
 */
function hasProblematicChars(filename) {
  // 只检查真正有问题的字符
  const problematicPatterns = [
    /[<>:"|?*]/,           // Windows不支持的字符
    /\x00/,                // null字符
    /[\x01-\x1f]/,         // 控制字符
    /^\.+$/,               // 只有点的文件名
    /\s{2,}/,              // 连续空格
    /%[0-9A-F]{2}/i,       // 已经被URL编码的字符
    /%(?![0-9A-F]{2})/i,   // 单独的%字符（不是URL编码的一部分）
  ]

  return problematicPatterns.some(pattern => pattern.test(filename))
}

/**
 * 温和地修复文件名
 * @param {string} filename - 原始文件名
 * @returns {string} 修复后的文件名
 */
function fixFilename(filename) {
  const ext = path.extname(filename)
  const name = path.basename(filename, ext)

  let fixed = name

  // 1. 只移除真正有问题的字符
  fixed = fixed
    .replace(/[<>:"|?*\x00-\x1f]/g, '')     // 移除Windows不支持字符和控制字符
    .replace(/%(?![0-9A-F]{2})/gi, 'percent') // 单独的%字符替换为percent
    .replace(/\s{2,}/g, ' ')                // 多个空格 -> 单空格
    .replace(/^\.+/, '')                    // 移除开头的点
    .replace(/\.+$/, '')                    // 移除结尾的点
    .trim()

  // 2. 处理过长文件名（只有真的很长才处理）
  if (fixed.length > CONFIG.maxLength) {
    // 保留重要的前缀信息
    const prefixPatterns = [
      /^Q[1-4]\s*20\d{2}/i,              // Q1 2024 这种时间前缀
      /^20\d{2}/,                        // 2024 这种年份前缀
      /^[A-Z]{2,4}\s*20\d{2}/i,         // CV 2024 这种
    ]

    let prefix = ''
    for (const pattern of prefixPatterns) {
      const match = fixed.match(pattern)
      if (match) {
        prefix = match[0]
        break
      }
    }

    if (prefix) {
      // 保留前缀 + 部分内容 + 省略号
      const remainingLength = CONFIG.maxLength - prefix.length - CONFIG.ellipsis.length - 1
      const content = fixed.slice(prefix.length).trim()

      if (remainingLength > 10) {
        fixed = prefix + ' ' + content.slice(0, remainingLength) + CONFIG.ellipsis
      } else {
        fixed = prefix + CONFIG.ellipsis
      }
    } else {
      // 直接截断
      fixed = fixed.slice(0, CONFIG.maxLength - CONFIG.ellipsis.length) + CONFIG.ellipsis
    }
  }

  // 3. 确保不为空
  if (!fixed) {
    fixed = 'untitled'
  }

  return fixed + ext
}

/**
 * 扫描并处理目录中的文件
 * @param {string} dir - 目录路径
 * @param {string} relativePath - 相对路径（用于日志显示）
 */
function processDirectory(dir, relativePath = '') {
  if (!fs.existsSync(dir)) return

  const items = fs.readdirSync(dir)

  items.forEach(item => {
    // 跳过特殊目录和文件
    if (item.startsWith('.') || item === 'node_modules' || item === 'public') return

    const itemPath = path.join(dir, item)
    const stat = fs.statSync(itemPath)
    const currentRelative = path.join(relativePath, item)

    if (stat.isDirectory()) {
      // 检查目录名是否有问题
      if (hasProblematicChars(item) || item.length > CONFIG.maxLength) {
        const fixedName = fixFilename(item)
        if (fixedName !== item) {
          const newPath = path.join(dir, fixedName)
          console.log(`📁 ${currentRelative} -> ${path.join(relativePath, fixedName)}`)

          if (!CONFIG.dryRun) {
            if (fs.existsSync(newPath)) {
              console.log(`⚠️  目录 ${fixedName} 已存在，跳过重命名`)
            } else {
              fs.renameSync(itemPath, newPath)
              // 递归处理重命名后的目录
              processDirectory(newPath, path.join(relativePath, fixedName))
              return
            }
          }
        }
      }

      // 递归处理子目录
      processDirectory(itemPath, currentRelative)
    } else if (item.endsWith('.md')) {
      // 检查Markdown文件名是否有问题
      if (hasProblematicChars(item) || item.length > CONFIG.maxLength + 3) { // +3 for .md
        const fixedName = fixFilename(item)
        if (fixedName !== item) {
          const newPath = path.join(dir, fixedName)
          console.log(`📄 ${currentRelative} -> ${path.join(relativePath, fixedName)}`)

          if (!CONFIG.dryRun) {
            if (fs.existsSync(newPath)) {
              console.log(`⚠️  文件 ${fixedName} 已存在，跳过重命名`)
            } else {
              fs.renameSync(itemPath, newPath)
            }
          }
        }
      }
    }
  })
}

/**
 * 主函数
 */
function main() {
  const args = process.argv.slice(2)
  const isDryRun = args.includes('--dry-run') || args.includes('-d')

  CONFIG.dryRun = isDryRun

  console.log('🔧 温和的文件名修复工具')
  console.log(`📁 处理目录: ${docsDir}`)
  console.log(`⚙️  最大长度: ${CONFIG.maxLength}`)
  console.log(`⚙️  省略符号: "${CONFIG.ellipsis}"`)

  if (isDryRun) {
    console.log('👀 预览模式 - 不会实际修改文件')
  }

  console.log('\n只处理以下问题：')
  console.log('• Windows不支持的字符: < > : " | ? *')
  console.log('• 控制字符和null字符')
  console.log('• 连续多个空格')
  console.log('• 过长的文件名')
  console.log('• 已被URL编码的字符')
  console.log('• 单独的%字符（替换为percent）')

  console.log('\n保留所有中文字符和其他内容')
  console.log('\n开始处理...\n')

  // 排除的目录
  const excludeDirs = ['.vitepress', 'node_modules', 'public', '.git']

  let foundProblems = false

  const items = fs.readdirSync(docsDir)
  items.forEach(item => {
    if (excludeDirs.includes(item)) return

    const itemPath = path.join(docsDir, item)
    if (fs.statSync(itemPath).isDirectory()) {
      processDirectory(itemPath, item)
    } else if (item.endsWith('.md')) {
      if (hasProblematicChars(item) || item.length > CONFIG.maxLength + 3) {
        foundProblems = true
        const fixedName = fixFilename(item)
        console.log(`📄 ${item} -> ${fixedName}`)

        if (!CONFIG.dryRun) {
          if (fs.existsSync(path.join(docsDir, fixedName))) {
            console.log(`⚠️  文件 ${fixedName} 已存在，跳过重命名`)
          } else {
            fs.renameSync(itemPath, path.join(docsDir, fixedName))
          }
        }
      }
    }
  })

  if (!foundProblems) {
    console.log('✅ 没有发现有问题的文件名!')
  } else {
    console.log('\n✅ 处理完成!')

    if (isDryRun) {
      console.log('\n💡 要实际执行修复，请运行: node fix-problematic-filenames.js')
    } else {
      console.log('\n💡 建议运行构建命令测试修复效果')
    }
  }
}

// 如果是直接执行此脚本
if (import.meta.url === `file://${process.argv[1]}`) {
  main()
}

export { fixFilename, hasProblematicChars }