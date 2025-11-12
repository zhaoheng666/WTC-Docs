<template>
  <div class="stats-container">
    <div class="section-divider"></div>
    
    <!-- 统计卡片 -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon">📚</div>
        <div class="stat-value">{{ stats.totalDocs }}</div>
        <div class="stat-label">文档总数</div>
      </div>
      
      <div class="stat-card contributors-card" @click="showContributors = !showContributors">
        <div class="stat-icon">👥</div>
        <div class="stat-value">{{ stats.contributors || 0 }}</div>
        <div class="stat-label">贡献者</div>
        <div v-if="stats.contributorsList && stats.contributorsList.length > 0" class="expand-hint">
          点击查看详情
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">🔄</div>
        <div class="stat-value">{{ todayUpdates }}</div>
        <div class="stat-label">今日更新</div>
      </div>
    </div>

    <!-- 贡献者列表 -->
    <div v-if="showContributors && stats.contributorsList && stats.contributorsList.length > 0" class="contributors-dropdown">
      <div class="contributors-list">
        <div v-for="contributor in stats.contributorsList" :key="contributor.name" class="contributor-item">
          <div class="contributor-avatar">
            {{ contributor.name.charAt(0).toUpperCase() }}
          </div>
          <div class="contributor-info">
            <div class="contributor-name">{{ contributor.name }}</div>
            <div class="contributor-meta">
              <span class="contributor-commits">{{ contributor.commits }} 次提交</span>
              <span class="dot">·</span>
              <span class="contributor-date">{{ formatDate(contributor.lastCommit) }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 最近更新时间线 -->
    <div class="timeline-section">
      <h2 class="timeline-title">
        🕐 最近更新
        <span class="update-time">{{ updateTimeText }}</span>
      </h2>
      
      <div v-if="!stats.commits || stats.commits.length === 0" class="no-data">
        暂无更新记录
      </div>
      
      <div v-else class="timeline">
        <div v-for="commit in stats.commits.slice(0, 10)" :key="commit.hash" class="timeline-item">
          <div class="timeline-date">{{ formatDate(commit.date) }}</div>
          <div class="timeline-content">
            <a v-if="getFileLink(commit.files[0])" :href="getFileLink(commit.files[0])" class="timeline-file-link">
              {{ getFileName(commit.files[0]) }}
            </a>
            <div v-else class="timeline-file">
              {{ getFileName(commit.files[0]) }}
            </div>
            <div class="timeline-meta">
              <span class="timeline-author">👤 {{ commit.author }}</span>
              <span class="timeline-message">{{ commit.message }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 分类分布 -->
    <div class="category-section">
      <h2>📊 分类分布</h2>
      <div class="category-container">
        <a v-for="[category, count] in sortedCategories"
           :key="category"
           :href="getCategoryLink(category)"
           class="category-card">
          <div class="category-header">
            <span class="category-name">{{ category }}</span>
            <span class="category-count">{{ count }}</span>
          </div>
          <div class="category-bar">
            <div class="category-fill" :style="{width: `${(count / stats.totalDocs) * 100}%`}"></div>
          </div>
        </a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const stats = ref({
  totalDocs: 0,
  categoryStats: {},
  contributors: 0,
  contributorsList: [],
  updateTime: null,
  commits: []
})

const loading = ref(true)
const showContributors = ref(false)

// 计算属性
const updateTimeText = computed(() => {
  if (!stats.value.updateTime) return '加载中...'
  const date = new Date(stats.value.updateTime)
  return `最后更新：${date.toLocaleString('zh-CN')}`
})

const sortedCategories = computed(() => {
  return Object.entries(stats.value.categoryStats || {})
    .sort((a, b) => b[1] - a[1])
})

const todayUpdates = computed(() => {
  // 优先使用后端计算的today updates，如果没有则降级计算
  if (stats.value.todayUpdates !== undefined) {
    return stats.value.todayUpdates
  }

  // 降级计算（兼容旧数据）
  if (!stats.value.commits) return 0
  const today = new Date().toDateString()
  return stats.value.commits.filter(c =>
    new Date(c.date).toDateString() === today
  ).length
})

// 方法
function formatDate(dateStr) {
  const date = new Date(dateStr)
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const day = date.getDate().toString().padStart(2, '0')
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${month}-${day} ${hours}:${minutes}`
}

function getFileName(filePath) {
  if (!filePath) return '未知文件'
  return filePath.split('/').pop().replace('.md', '')
}

function getFileLink(filePath) {
  if (!filePath || !filePath.endsWith('.md')) return null

  // 判断环境
  const isDev = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  const base = isDev ? 'http://localhost:5173/WTC-Docs/' : '/WTC-Docs/'

  // 移除 .md 后缀，构建 VitePress 路由
  const path = filePath.replace('.md', '')
  return base + path
}

function getCategoryLink(category) {
  // 判断环境
  const isDev = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  const base = isDev ? 'http://localhost:5173/WTC-Docs/' : '/WTC-Docs/'

  // 构建分类页面链接
  return base + category + '/'
}

// 加载数据
async function loadStats() {
  try {
    // 判断环境
    const isDev = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    
    if (isDev) {
      // 开发环境：从远程 GitHub Pages 加载
      const remoteUrl = 'https://zhaoheng666.github.io/WTC-Docs/stats.json?' + Date.now()
      console.log('📊 Loading stats from remote:', remoteUrl)
      
      const response = await fetch(remoteUrl)
      if (response.ok) {
        const data = await response.json()
        stats.value = data
        console.log('✅ Remote stats loaded successfully')
      } else {
        console.warn('⚠️ Failed to load remote stats, using default values')
        // 使用默认值
        stats.value = {
          totalDocs: 0,
          categoryStats: {},
          contributors: 0,
          contributorsList: [],
          commits: [],
          updateTime: null
        }
      }
    } else {
      // 生产环境：从本地加载（CI 生成的文件）
      const response = await fetch('/WTC-Docs/stats.json?' + Date.now())
      if (response.ok) {
        const data = await response.json()
        stats.value = data
      }
    }
  } catch (error) {
    console.error('Failed to load stats:', error)
    // 使用默认值
    stats.value = {
      totalDocs: 0,
      categoryStats: {},
      contributors: 0,
      contributorsList: [],
      commits: [],
      updateTime: null
    }
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadStats()
  // 每5分钟刷新一次
  setInterval(loadStats, 5 * 60 * 1000)
})
</script>

<style scoped>
.stats-container {
  max-width: 100%;
  padding: 0;
  padding-top: 1.5rem;
}

/* 统计卡片 */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.stat-card {
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  padding: 0.8rem 1rem;
  text-align: center;
  transition: all 0.3s ease;
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100px;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px -8px rgba(0, 0, 0, 0.1);
  border-color: var(--vp-c-brand);
}

.stat-icon {
  font-size: 1.5rem;
  margin-bottom: 0.2rem;
  line-height: 1;
}

.stat-value {
  font-size: 1.6rem;
  font-weight: 700;
  color: var(--vp-c-brand);
  margin: 0.2rem 0;
  line-height: 1.2;
}

.stat-label {
  color: var(--vp-c-text-2);
  font-size: 0.8rem;
  line-height: 1.2;
  margin-top: 0.2rem;
}

.contributors-card {
  cursor: pointer;
  position: relative;
}

.expand-hint {
  margin-top: 0.3rem;
  font-size: 0.65rem;
  color: var(--vp-c-brand);
  opacity: 0.7;
  line-height: 1;
}

/* 贡献者下拉列表 */
.contributors-dropdown {
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  margin-top: -0.5rem;
  margin-bottom: 1rem;
  padding: 0.5rem;
  animation: slideDown 0.3s ease;
}

.contributors-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 0.4rem;
}

.contributor-item {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.4rem 0.6rem;
  background: var(--vp-c-bg);
  border-radius: 6px;
  transition: all 0.2s ease;
}

.contributor-item:hover {
  background: var(--vp-c-bg-soft-up);
  transform: translateX(4px);
}

.contributor-avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--vp-c-brand), var(--vp-c-brand-light));
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 600;
  font-size: 0.75rem;
  flex-shrink: 0;
}

.contributor-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.1rem;
}

.contributor-name {
  font-weight: 600;
  color: var(--vp-c-text-1);
  font-size: 0.85rem;
  line-height: 1.2;
}

.contributor-meta {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.7rem;
  color: var(--vp-c-text-3);
  line-height: 1.2;
}

.contributor-commits {
  color: var(--vp-c-brand);
  font-weight: 500;
}

.contributor-date {
  white-space: nowrap;
}

.dot {
  color: var(--vp-c-text-3);
  opacity: 0.5;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 分类分布 */
.category-section {
  margin-bottom: 1.5rem;
}

.category-section h2 {
  font-size: 1.2rem;
  font-weight: 600;
  margin: 0 0 1rem 0;
}

.category-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 1rem;
}

.category-card {
  background: var(--vp-c-bg-soft);
  border-radius: 8px;
  padding: 1rem;
  transition: all 0.3s ease;
  text-decoration: none;
  color: inherit;
  display: block;
  cursor: pointer;
}

.category-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  border: 1px solid var(--vp-c-brand);
}

.category-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.category-name {
  font-weight: 500;
  color: var(--vp-c-text-1);
}

.category-count {
  font-weight: 600;
  color: var(--vp-c-brand);
  background: var(--vp-c-brand-soft);
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.85rem;
}

.category-bar {
  height: 8px;
  background: var(--vp-c-divider);
  border-radius: 4px;
  overflow: hidden;
}

.category-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--vp-c-brand), var(--vp-c-brand-light));
  border-radius: 4px;
  transition: width 0.5s ease;
}

/* 时间线 */
.timeline-section {
  margin-bottom: 1.5rem;
}


.timeline {
  position: relative;
  padding-left: 1.5rem;
}

.timeline::before {
  content: '';
  position: absolute;
  left: 8px;
  top: 0;
  bottom: 0;
  width: 2px;
  background: var(--vp-c-divider);
}

.timeline-item {
  position: relative;
  padding: 0.8rem 1rem;
  margin-bottom: 0.8rem;
  background: var(--vp-c-bg-soft);
  border-radius: 6px;
  transition: all 0.3s ease;
}

.timeline-item:hover {
  background: var(--vp-c-bg-soft-up);
  transform: translateX(4px);
}

.timeline-item::before {
  content: '';
  position: absolute;
  left: -19px;
  top: 1.2rem;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--vp-c-brand);
  border: 2px solid var(--vp-c-bg);
}

.timeline-date {
  color: var(--vp-c-text-3);
  font-size: 0.8rem;
  margin-bottom: 0.3rem;
}

.timeline-content {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.timeline-file {
  font-weight: 600;
  color: var(--vp-c-text-1);
  font-size: 1rem;
}

.timeline-file-link {
  font-weight: 600;
  color: var(--vp-c-brand);
  font-size: 1rem;
  text-decoration: none;
  transition: all 0.2s ease;
  display: inline-block;
}

.timeline-file-link:hover {
  color: var(--vp-c-brand-dark);
  text-decoration: underline;
  transform: translateX(2px);
}

.timeline-meta {
  display: flex;
  gap: 1rem;
  font-size: 0.85rem;
  color: var(--vp-c-text-2);
}

.no-data {
  text-align: center;
  padding: 2rem;
  color: var(--vp-c-text-3);
}

.timeline-title {
  font-size: 1.2rem;
  font-weight: 600;
  margin: 0 0 1rem 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.update-time {
  color: var(--vp-c-text-3);
  font-size: 0.75rem;
  font-weight: 400;
  margin-left: auto;
}

.section-divider {
  margin: 1.5rem 0;
  border-bottom: 1px solid var(--vp-c-divider);
}

/* 响应式 */
@media (max-width: 768px) {
  .stats-grid {
    grid-template-columns: repeat(1, 1fr);
  }
  
  .category-container {
    grid-template-columns: 1fr;
  }
}

@media (min-width: 769px) and (max-width: 1024px) {
  .stats-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
</style>