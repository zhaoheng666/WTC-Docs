import { defineConfig } from 'vitepress'
import { generateMultiSidebar } from './sidebar.mjs'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "WorldTourCasino",
  description: "WorldTourCasino 项目文档",

  // GitHub Pages 部署配置
  base: '/WTC-Docs/',

  // 启用外观切换（深色模式）
  appearance: true,

  // 忽略死链接检查（对于一些动态链接）
  ignoreDeadLinks: [
    // 忽略 URL 编码的中文路径（暂时）
    /\/%E/,
    // 忽略 base URL 后的 /index 路径（VitePress 路由机制导致的误报）
    // 当链接到 http://localhost:5173/WTC-Docs/ 时，VitePress 会将其解析为 /WTC-Docs/index
    // 但实际文件是 index.md，死链检测器会误报为死链
    (url) => {
      const baseIndex = `${process.env.GITHUB_ACTIONS ? 'https://zhaoheng666.github.io' : 'http://localhost:5173'}/WTC-Docs/index`;
      return url === baseIndex || url === `${baseIndex}.html`;
    }
  ],

  // Vite 配置
  vite: {
    build: {
      rollupOptions: {
        onwarn(warning, warn) {
          // 忽略 public 目录资源被 import 的警告
          // 原因：我们的图片在 public/assets/ 目录，由 image-processor.js 统一管理
          // VitePress 会将 Markdown 中的图片引用转为 import，触发 Vite 警告
          // 实际上这不影响构建结果，且我们的设计已经优化过图片处理流程
          if (warning.message && (
            warning.message.includes('public directory') ||
            warning.message.includes('Instead of')
          )) {
            return
          }
          warn(warning)
        }
      }
    }
  },

  // Markdown 配置
  markdown: {
    // 配置语法高亮
    languages: [
      // VitePress 默认支持的语言已经很多，如果确实需要，可以安装额外的语言包
    ],
    // 代码块的默认语言
    defaultHighlightLang: 'bash',
    // 允许在 markdown 中使用 HTML
    html: true,
    // 配置图片处理
    image: {
      // 启用图片懒加载
      lazyLoading: false
    }
  },

  // 配置 head 标签，添加 CSP 以允许远程图片
  head: [
    // Favicon 配置 - 使用骰子图标
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/WTC-Docs/favicon.svg' }],
    // 允许加载远程图片
    [
      'meta',
      {
        'http-equiv': 'Content-Security-Policy',
        content: "default-src 'self' 'unsafe-inline' 'unsafe-eval' https: http: data: blob:; img-src 'self' https: http: data: blob:;"
      }
    ]
  ],

  // 主题配置
  themeConfig: {
    // 顶部导航栏
    nav: [
      { text: '首页', link: '/' },
      { text: '团队', link: '/团队' },
      { text: '程序总表', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=0#gid=0' },

      {
        text: '发版',
        items: [
          { text: '发版记录', link: 'https://docs.google.com/document/d/1KmLcqFHg5FKiYZ0K7poLMHUl7054ZoXx7YEg3SRGtx0/edit?tab=t.0' },
          { text: 'Jenkins', link: 'http://39.106.57.54:42453/view/debug/job/Classic_Debug_deploy/' },
          { text: 'JIRA', link: 'http://39.106.57.54:42456/browse' },
          { text: '测试平台', link: 'http://39.106.57.54:42457/' },
          { text: 'QA 工具', link: 'https://slots-team-test-server-v0.me2zengame.com/qa.html' },
        ]
      },
      {
        text: '更多',
        items: [
          { text: 'VitePress 文档', link: 'https://vitepress.qzxdp.cn/reference/frontmatter-config.html' },
          { text: 'ClaudeCode 配置教程', link: 'https://docs.google.com/document/d/1WM5ioMu8jgsq3OBVJfQd2pDH77qhQcjCEPbztwC-fkw/edit?tab=t.0#heading=h.o5dqq3slzr7v' },
          { text: 'BMAD-METHOD软件工程智能体', link: 'https://github.com/bmadcode/BMAD-METHOD' }
        ]
      }
    ],

    // 侧边栏 - 自动生成目录结构
    sidebar: generateMultiSidebar(),

    // 搜索配置
    search: {
      provider: 'local',
      options: {
        // 显示详细搜索结果（包含内容摘要）
        detailedView: true,
        // 搜索选项
        _render(src, env, md) {
          const html = md.render(src, env)
          if (env.frontmatter?.search === false) return ''
          return html
        },
        // 提取文本内容进行索引
        miniSearch: {
          options: {
            // 配置搜索字段权重
            boost: {
              title: 4,      // 标题权重最高
              text: 2,       // 正文内容权重
              titles: 1      // 其他标题权重
            },
            // 自定义分词器，改善中文搜索
            tokenize: (text) => {
              // 如果是空字符串，直接返回
              if (!text || typeof text !== 'string') return []

              // 转换为小写
              text = text.toLowerCase()

              // 检查是否支持 Intl.Segmenter（现代浏览器都支持）
              if (typeof Intl !== 'undefined' && Intl.Segmenter) {
                try {
                  // 使用 Intl.Segmenter 进行中文分词
                  const segmenter = new Intl.Segmenter('zh-CN', { granularity: 'word' })
                  const segments = segmenter.segment(text)
                  const tokens = []

                  for (const seg of segments) {
                    // 只保留词汇类的片段（过滤掉空格、标点等）
                    if (seg.isWordLike && seg.segment.trim()) {
                      const word = seg.segment.trim()
                      tokens.push(word)

                      // 对于较长的中文词汇，额外生成2字词组合
                      if (/[\u4e00-\u9fa5]/.test(word) && word.length >= 4) {
                        for (let i = 0; i <= word.length - 2; i++) {
                          tokens.push(word.substring(i, i + 2))
                        }
                      }
                    }
                  }

                  // 去重并返回
                  return [...new Set(tokens)]
                } catch (e) {
                  // 如果 Segmenter 失败，回退到基础方法
                  console.warn('Intl.Segmenter failed:', e)
                }
              }

              // 回退方案：基于标点和空格的简单分词
              const tokens = text
                .split(/[\s\-，。、；：！？【】（）《》""''「」『』〈〉〔〕［］｛｝\/\\\n\r\t,.!?;:()\[\]{}"'`~@#$%^&*+=|<>]+/)
                .filter(token => token && token.length > 0)

              // 对中文文本补充2字分词
              const finalTokens = []
              tokens.forEach(token => {
                finalTokens.push(token)
                // 如果是纯中文且长度>=3，生成2字组合
                if (/^[\u4e00-\u9fa5]+$/.test(token) && token.length >= 3) {
                  for (let i = 0; i <= token.length - 2; i++) {
                    finalTokens.push(token.substring(i, i + 2))
                  }
                }
              })

              return [...new Set(finalTokens)]
            }
          },
          searchOptions: {
            // 搜索时的配置
            boost: {
              title: 4,
              text: 2,
              titles: 1
            },
            fuzzy: 0.2,      // 模糊搜索
            prefix: true,    // 前缀匹配
            combineWith: 'OR' // 使用 OR 逻辑，提高召回率
          }
        },
        // 本地化配置
        locales: {
          root: {
            translations: {
              button: {
                buttonText: '搜索文档',
                buttonAriaLabel: '搜索文档'
              },
              modal: {
                noResultsText: '无法找到相关结果',
                resetButtonTitle: '清除查询条件',
                footer: {
                  selectText: '选择',
                  navigateText: '切换',
                  closeText: '关闭'
                }
              }
            }
          }
        }
      }
    },

    // 社交链接
    socialLinks: [
      { icon: 'github', link: 'https://github.com/zhaoheng666/WTC-Docs' }
    ],

    // 启用编辑链接
    editLink: {
      pattern: 'https://github.com/zhaoheng666/WTC-Docs/edit/main/:path',
      text: '在 GitHub 上编辑此页'
    },

    // 显示最后更新时间
    lastUpdated: {
      text: '最后更新于',
      formatOptions: {
        dateStyle: 'full',
        timeStyle: 'short'
      }
    },

    // 页脚 - 有侧边栏时不生效
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024-present WorldTourCasino'
    }
  }
})