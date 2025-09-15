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