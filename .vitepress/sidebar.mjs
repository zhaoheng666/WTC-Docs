import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

// 手动配置的部分 - 自定义链接和特殊文档
const manualSection = [
  {
    text: '简介',
    collapsed: false,
    items: [
      { text: '📚 概览', link: '/README' },
      // { text: '🚀 快速开始', link: '/快速开始' },
      { text: '🕐 最近更新', link: '/最近更新' },
      { text: '📋 工作规范', link: '/工作规范' },
      // { text: '📖 WTC-docs 技术文档', link: '/技术文档' },
      { text: '🎯 工作台', link: '/工作台' },
    ]
  },
  {
    text: '快速链接',
    collapsed: false,
    items: [
      { text: '📆Slots排期', link: 'https://docs.google.com/spreadsheets/d/1Zn_ULWSIoq_6Bxz3DvHDKed-KS_OrcqTtrSLHmHvR2E/edit?gid=1399784065#gid=1399784065' },
      { text: '📊程序排期', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=130371487#gid=130371487' },
      {
        text: '❗A版反馈',
        collapsed: true,
        items: [
          { text: '关卡', link: 'https://docs.google.com/spreadsheets/d/1mvgxECitMFnweyG6ZM5ibTDUpfzVWERw8SglejeZ61I/edit?gid=1594819754#gid=1594819754' },
          { text: '活动', link: 'https://docs.google.com/spreadsheets/d/1AsWdr5hPoVqk9FFArIaqWUrsnSoDlCRqhMiq-TPk-gQ/edit?gid=548726162#gid=548726162' },
        ]
      },
      {
        text: '✅ A版自测',
        collapsed: true,
        items: [
          { text: '关卡', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=846946624#gid=846946624' },
          { text: '活动', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=933143491#gid=933143491' },
          { text: '赛季', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=1921777137#gid=1921777137' },
        ]
      },
      {
        text: '☑️ 待办',
        collapsed: true,
        link: '/待办'
      }
    ]
  }
]

// 格式化标题：文档、目录命名<->显示名 - 映射
const specialCases = {
  'native': 'Native',
}

// 目录图标映射 - 为不同类型的目录添加个性化图标
const directoryIcons = {
  '活动': '🎯',
  '关卡': '🎰',
  'native': '📱',
  'Native': '📱',
  '工程-工具': '🔧',
  '其他': '📁',
  '成员': '👥',
  '故障排查': '🔍',
  '服务器': '🖥️',
  '需求': '📝',
  '需求分析': '📝',
  // Jenkins 相关
  'Jenkins': '⚙️',
  // VS Code 相关
  'vscode': '💻',
  // Apple 相关
  'AppleDevelop': '🍎',
  // Facebook 相关
  'FB': '🔵',
  '优化重构': '✨',
  '待办': '☑️'
}

// 文件图标映射 - 为不同类型的文件添加图标
const fileIcons = {
  // 默认 markdown 图标
  default: '📄',
  // 特殊文件
  'index': '🏠',
  '概览': '📖',
  // 可以根据文件名添加特殊图标
  'README': '📚',
  '技术文档': '⚡',
  '工作规范': '📏',
  // 更多文件类型
  '快速开始': '🚀',
  '最近更新': '🕐',
  'changelog': '📝',
  'tutorial': '🎓',
  'guide': '📘',
  // 常见文档类型
  'FAQ': '❓',
  'API': '🔌',
  'config': '⚙️',
  'setup': '🔧',
  'install': '📦',
}

// 自定义一级目录排序配置
// 数字越小，排序越靠前；未配置的目录按字母顺序排在最后
const directoryOrder = {
  '活动': 1,        // 活动 - 最优先显示
  '关卡': 2,        // 关卡
  'native': 3,      // native (小写)
  'Native': 3,      // native (大写)
  '工程-工具': 4,   // 工程工具
  '优化重构': 5,    // 优化重构
  '架构': 5.5,      // 架构图（插在优化重构与故障排查之间）
  '故障排查': 6,    // 故障排查
  '服务器': 7,      // 服务器
  '待办': 8,        // 待办
  '其他': 9,        // 其他
}

// 忽略列表配置
// 支持相对路径和文件名，用于在侧边栏中屏蔽特定文件或目录
const ignoreList = [
  // === 使用说明 ===
  // 1. 相对路径匹配（以 / 开头）
  //    - '/其他/测试文档.md'     // 忽略特定文件
  //    - '/临时目录/'            // 忽略整个目录（以 / 结尾）
  //
  // 2. 文件名匹配（不以 / 开头）
  //    - 'README.md'            // 忽略所有名为 README.md 的文件
  //    - 'draft-'               // 忽略所有以 draft- 开头的文件（前缀匹配）
  //    - '-temp.md'             // 忽略所有以 -temp.md 结尾的文件（后缀匹配）
  //    - 'TODO.md'              // 忽略所有名为 TODO.md 的文件
  //
  // === 实际配置 ===
  // 在下面添加需要忽略的文件或目录：
  '/其他/测试文档.md',
  'README.md',  // 已在文档中心显示
  '/隐藏/',
  // 已删除的文档
  'IMAGE_HANDLING.md',
  'SCRIPTS.md',
  '开发指南.md',
  // 已在文档中心显示
  '快速开始.md',
  '团队.md',
  '最近更新.md',
  '技术文档.md',
  '工作规范.md',
  '工作台.md',
  'CLAUDE.md'
]

// 检查文件或目录是否应该被忽略
function shouldIgnore(filePath, fileName) {
  // 标准化路径，使用正斜杠
  const normalizedPath = filePath.replace(/\\/g, '/')

  for (const pattern of ignoreList) {
    // 完整路径匹配（以 / 开头）
    if (pattern.startsWith('/')) {
      // 目录匹配
      if (pattern.endsWith('/')) {
        if (normalizedPath.startsWith(pattern) || ('/' + normalizedPath + '/').includes(pattern)) {
          return true
        }
      }
      // 文件匹配
      else if (normalizedPath === pattern || '/' + normalizedPath === pattern) {
        return true
      }
    }
    // 文件名匹配
    else {
      // 前缀匹配
      if (pattern.endsWith('-') || pattern.endsWith('_')) {
        if (fileName.startsWith(pattern)) {
          return true
        }
      }
      // 后缀匹配
      else if (pattern.startsWith('-') || pattern.startsWith('_')) {
        if (fileName.endsWith(pattern)) {
          return true
        }
      }
      // 完整文件名匹配
      else if (fileName === pattern) {
        return true
      }
    }
  }

  return false
}

// 递归扫描目录，生成完整的文档树
export function scanDirectory(dir, baseLink = '') {
  const docsDir = path.resolve(__dirname, '..', dir)

  if (!fs.existsSync(docsDir)) {
    return []
  }

  const files = fs.readdirSync(docsDir)

  // 分类文件和目录，并分别排序
  const directories = []
  const markdownFiles = []

  files.forEach(file => {
    // 跳过特殊文件和目录
    if (file.startsWith('.') || file === 'node_modules' || file === 'public') return

    const filePath = path.join(docsDir, file)
    const stat = fs.statSync(filePath)

    // 构建相对路径（用于忽略列表匹配）
    const relativePath = path.join(dir, file).replace(/\\/g, '/')

    if (stat.isDirectory()) {
      // 检查目录是否应该被忽略
      if (shouldIgnore(relativePath + '/', file)) {
        return
      }
      directories.push(file)
    } else if (file.endsWith('.md')) {
      // 检查文件是否应该被忽略
      if (shouldIgnore(relativePath, file)) {
        return
      }
      markdownFiles.push(file)
    }
  })

  // 对目录和文件分别排序
  directories.sort()
  markdownFiles.sort()

  const items = []

  // 先处理目录（文件夹优先）
  directories.forEach(file => {
    const filePath = path.join(docsDir, file)
    const relativePath = path.join(dir, file).replace(/\\/g, '/')

    // 递归处理子目录
    const subItems = scanDirectory(path.join(dir, file), `${baseLink}/${file}`)
    if (subItems.length > 0) {
      items.push({
        text: formatTitle(file, true), // true 表示这是目录
        collapsed: true, // 默认折叠子目录
        items: subItems
      })
    }
  })

  // 再处理Markdown文件
  markdownFiles.forEach(file => {
    const relativePath = path.join(dir, file).replace(/\\/g, '/')

    // 处理 Markdown 文件
    const name = file.replace('.md', '')
    // index.md 特殊处理 - 始终放在最前面
    if (name === 'index') {
      items.unshift({
        text: formatTitle('概览', false), // false 表示这是文件
        link: `${baseLink}/`
      })
    } else {
      items.push({
        text: formatTitle(name, false), // false 表示这是文件
        link: `${baseLink}/${name}`
      })
    }
  })

  return items
}

// 提取纯文本名称（去除图标）- 用于排序匹配
function extractTextFromTitle(titleWithIcon) {
  // 移除开头的 emoji 图标和空格
  // 包含以下 Unicode 范围：
  // - U+2600-U+27BF: Miscellaneous Symbols & Dingbats (☀️, ✨, etc.)
  // - U+1F300-U+1F9FF: Emoji 主要范围
  // - U+FE00-U+FEFF: 变体选择符
  return titleWithIcon.replace(/^[\u{2600}-\u{27BF}\u{1F300}-\u{1F9FF}][\u{FE00}-\u{FEFF}]?\s*/u, '')
}

// 格式化标题 - 添加图标并处理 specialCases
function formatTitle(name, isDirectory = false) {
  let displayName = name

  // 如果在 specialCases 中有定义，使用定义的值
  if (specialCases[name.toLowerCase()]) {
    displayName = specialCases[name.toLowerCase()]
  }

  // 添加图标
  if (isDirectory) {
    // 目录图标
    const icon = directoryIcons[displayName] || directoryIcons[name] || '📂'
    return `${icon} ${displayName}`
  } else {
    // 文件图标
    const icon = fileIcons[displayName] || fileIcons[name] || fileIcons.default
    return `${icon} ${displayName}`
  }
}

// 生成混合侧边栏配置
export function generateSidebar() {


  // 自动生成的部分 - 扫描根目录下的所有文档
  const autoSection = []

  // 扫描 docs 根目录，获取所有文档结构
  const rootItems = scanDirectory('', '')

  // 将扫描到的内容按目录分组
  const directories = []
  let memberDirectory = null
  const rootFiles = []

  rootItems.forEach(item => {
    if (item.items) {
      // 检查是否是成员目录（提取纯文本进行匹配）
      const textName = extractTextFromTitle(item.text)
      if (textName === '成员') {
        // 单独处理成员目录
        memberDirectory = item
      } else {
        // 其他目录
        directories.push(item)
      }
    } else if (item.link !== '/' && !item.link.startsWith('/index')) {
      // 是根目录下的文件（排除 index.md）
      rootFiles.push(item)
    }
  })

  // 对目录进行自定义排序
  const sortedDirectories = directories.sort((a, b) => {
    // 提取纯文本名称进行匹配
    const textA = extractTextFromTitle(a.text)
    const textB = extractTextFromTitle(b.text)

    const orderA = directoryOrder[textA] ?? 999
    const orderB = directoryOrder[textB] ?? 999

    if (orderA !== orderB) {
      return orderA - orderB  // 数字小的在前
    }
    // 如果都没有配置顺序，按字母顺序排序
    return textA.localeCompare(textB)
  })

  // 添加自动生成的文档树
  if (sortedDirectories.length > 0 || rootFiles.length > 0) {
    autoSection.push({
      text: '项目文档',
      collapsed: false,
      items: [
        ...sortedDirectories,
        ...rootFiles
      ]
    })
  }

  // 准备成员部分（作为独立的 section）
  const memberSection = memberDirectory ? [{
    text: '成员文档',
    collapsed: false,
    items: memberDirectory.items || []
  }] : []

  // 合并手动、自动和成员部分
  return [
    ...manualSection,
    ...autoSection,
    ...memberSection
  ]
}

// 为 VitePress 配置生成多路径侧边栏
export function generateMultiSidebar() {
  const sidebar = generateSidebar()

  // 返回统一的侧边栏配置
  // 所有路径都使用相同的侧边栏
  return {
    '/': sidebar
  }
}