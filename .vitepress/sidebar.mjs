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
      { text: '🚀 快速开始', link: '/快速开始' },
      { text: '🕐 最近更新', link: '/最近更新' },
    ]
  },
  {
    text: '快速链接',
    collapsed: false,
    items: [
      { text: 'Slots排期', link: 'https://docs.google.com/spreadsheets/d/1Zn_ULWSIoq_6Bxz3DvHDKed-KS_OrcqTtrSLHmHvR2E/edit?gid=1399784065#gid=1399784065' },
      { text: '程序排期', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=130371487#gid=130371487' },
      {
        text: 'A版反馈',
        collapsed: true,
        items: [
          { text: '关卡', link: 'https://docs.google.com/spreadsheets/d/1mvgxECitMFnweyG6ZM5ibTDUpfzVWERw8SglejeZ61I/edit?gid=1594819754#gid=1594819754' },
          { text: '活动', link: 'https://docs.google.com/spreadsheets/d/1AsWdr5hPoVqk9FFArIaqWUrsnSoDlCRqhMiq-TPk-gQ/edit?gid=548726162#gid=548726162' },
        ]
      },
      {
        text: 'A版自测',
        collapsed: true,
        items: [
          { text: '关卡', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=846946624#gid=846946624' },
          { text: '活动', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=933143491#gid=933143491' },
          { text: '赛季', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=1921777137#gid=1921777137' },
        ]
      }
    ]
  }
]

// 格式化标题：文档、目录命名<->显示名 - 映射
const specialCases = {
  'native': 'Native',
}

// 自定义一级目录排序配置
// 数字越小，排序越靠前；未配置的目录按字母顺序排在最后
const directoryOrder = {
  '活动': 1,    // 活动 - 最优先显示
  '关卡': 2,    // 关卡
  'Native': 3,  // native
  '协议': 4,    // 协议
  '工具': 5,    // 工具
  '其他': 6,    // 其他
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

  const items = []
  const files = fs.readdirSync(docsDir).sort()

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

      // 递归处理子目录
      const subItems = scanDirectory(path.join(dir, file), `${baseLink}/${file}`)
      if (subItems.length > 0) {
        items.push({
          text: formatTitle(file),
          collapsed: true, // 默认折叠子目录
          items: subItems
        })
      }
    } else if (file.endsWith('.md')) {
      // 检查文件是否应该被忽略
      if (shouldIgnore(relativePath, file)) {
        return
      }

      // 处理 Markdown 文件
      const name = file.replace('.md', '')
      // index.md 特殊处理
      if (name === 'index') {
        items.unshift({
          text: '概览',
          link: `${baseLink}/`
        })
      } else {
        items.push({
          text: formatTitle(name),
          link: `${baseLink}/${name}`
        })
      }
    }
  })

  return items
}

// 格式化标题 - 仅做 specialCases 替换
function formatTitle(name) {
  // 如果在 specialCases 中有定义，使用定义的值
  if (specialCases[name.toLowerCase()]) {
    return specialCases[name.toLowerCase()]
  }
  // 否则直接返回原始名称
  return name
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
      // 检查是否是成员目录
      if (item.text === '成员') {
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
    const orderA = directoryOrder[a.text] ?? 999
    const orderB = directoryOrder[b.text] ?? 999

    if (orderA !== orderB) {
      return orderA - orderB  // 数字小的在前
    }
    // 如果都没有配置顺序，按字母顺序排序
    return a.text.localeCompare(b.text)
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