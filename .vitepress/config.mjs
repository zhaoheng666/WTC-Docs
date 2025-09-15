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
      { text: '首页', link: '/README' },
      { text: 'Slots排期', link: 'https://docs.google.com/spreadsheets/d/1Zn_ULWSIoq_6Bxz3DvHDKed-KS_OrcqTtrSLHmHvR2E/edit?gid=1399784065#gid=1399784065' },
      { text: '程序排期', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=130371487#gid=130371487' },
      { text: '程序总表', link: 'https://docs.google.com/spreadsheets/d/1XSZKSkupKyU-kauAxyFjorZVFDZflCHkLxZ6Ytilbvc/edit?gid=0#gid=0' },
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
            tokenize: (text) => {
              // 使用标点符号分词
              const tokens = text.split(/[\s\-，。、；：！？【】（）《》""''\/\\\n\r\t]+/)
              
              // 对每个分词结果进一步处理
              const allTokens = []
              
              tokens.forEach(token => {
                if (!token) return
                
                // 保留完整的词
                allTokens.push(token)
                
                // 对中文文本进行额外处理
                const chineseMatch = token.match(/[\u4e00-\u9fa5]+/)
                if (chineseMatch) {
                  const chineseText = chineseMatch[0]
                  // 只对较长的中文词组进行分词
                  if (chineseText.length > 2) {
                    // 添加2字词和3字词（不使用滑动窗口，避免过度匹配）
                    // 例如"迟到打卡"会分为："迟到打卡"、"迟到"、"打卡"
                    if (chineseText.length === 3) {
                      allTokens.push(chineseText.substring(0, 2)) // 前两字
                      allTokens.push(chineseText.substring(1, 3)) // 后两字
                    } else if (chineseText.length === 4) {
                      allTokens.push(chineseText.substring(0, 2)) // 前两字
                      allTokens.push(chineseText.substring(2, 4)) // 后两字
                    }
                  }
                }
              })

              return allTokens.filter(token => token && token.length > 0)
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

    // 页脚
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024-present WorldTourCasino'
    }
  }
})