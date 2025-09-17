/**
 * 图片目录配置
 * 支持多种图片存储方式，保持灵活性
 */

export const imageConfig = {
  // 支持的图片目录名称
  supportedDirs: [
    'image',      // VS Code 插件默认
    'images',     // 常见命名
    'assets',     // 拷贝文档常用
    'img',        // 简写形式
    'pics',       // 图片简称
    'resources',  // 资源文件夹
    'media'       // 媒体文件夹
  ],

  // 支持的图片格式
  supportedFormats: [
    '.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.ico', '.bmp'
  ],

  // 图片目录命名模式（用于自动识别）
  patterns: [
    /^image$/i,      // image
    /^images?$/i,    // image 或 images
    /^assets?$/i,    // asset 或 assets
    /^img$/i,        // img
    /^pics?$/i,      // pic 或 pics
    /^resources?$/i, // resource 或 resources
    /^media$/i       // media
  ],

  // 推荐的目录名（仅作为建议，不强制）
  recommended: 'image',

  // 是否自动整理（默认关闭，不影响用户习惯）
  autoOrganize: false
}

/**
 * 判断是否为图片目录
 */
export function isImageDir(dirName) {
  return imageConfig.patterns.some(pattern => pattern.test(dirName))
}

/**
 * 判断是否为图片文件
 */
export function isImageFile(fileName) {
  const ext = fileName.toLowerCase().match(/\.[^.]+$/)?.[0]
  return ext && imageConfig.supportedFormats.includes(ext)
}