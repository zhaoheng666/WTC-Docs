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
    // 忽略以 localhost 开头的链接
    /^http:\/\/localhost/,
    // 忽略 URL 编码的中文路径（暂时）
    /\/%E/
  ],

  // 主题配置
  themeConfig: {
    // 顶部导航栏
    nav: [
      { text: '首页', link: '/' },
      { text: 'Slots排期', link: 'https://docs.google.com/spreadsheets/d/1Zn_ULWSIoq_6Bxz3DvHDKed-KS_OrcqTtrSLHmHvR2E/edit?gid=1399784065#gid=1399784065' },
      { text: '关于', link: '/about' },
      {
        text: '更多',
        items: [
          { text: '发版记录', link: 'https://docs.google.com/document/d/1KmLcqFHg5FKiYZ0K7poLMHUl7054ZoXx7YEg3SRGtx0/edit?tab=t.0' },
        ]
      }
    ],

    // 侧边栏 - 自动生成目录结构
    sidebar: generateMultiSidebar(),

    // 搜索配置
    search: {
      provider: 'local',
      options: {
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
            tokenize: (text, fieldName) => {
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
      { icon: 'github', link: 'https://github.com/LuckyZen/WorldTourCasino' }
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