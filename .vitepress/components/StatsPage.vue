<template>
  <div class="stats-container">
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
        <div v-for="commit in stats.commits.slice(0, 30)" :key="commit.hash" class="timeline-item">
          <div class="timeline-date">{{ formatDate(commit.date) }}</div>
          <div class="timeline-content">
            <div class="timeline-file">
              {{ getFileName(commit.files[0]) }}
            </div>
            <div class="timeline-meta">
              <span class="timeline-author">👤 {{ commit.author }}</span>
              <span class="timeline-message">{{ commit.message }}</span>
            </div>
          </div>
        </div>
      </div>
      
      <div class="section-divider"></div>
    </div>

    <!-- 统计卡片 -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon">📚</div>
        <div class="stat-value">{{ stats.totalDocs }}</div>
        <div class="stat-label">文档总数</div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">👥</div>
        <div class="stat-value">{{ stats.contributors || 0 }}</div>
        <div class="stat-label">贡献者</div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon">🔄</div>
        <div class="stat-value">{{ todayUpdates }}</div>
        <div class="stat-label">今日更新</div>
      </div>
    </div>

    <!-- 分类分布 -->
    <div class="category-section">
      <h2>📊 分类分布</h2>
      <div class="category-container">
        <div v-for="[category, count] in sortedCategories" :key="category" class="category-card">
          <div class="category-header">
            <span class="category-name">{{ category }}</span>
            <span class="category-count">{{ count }}</span>
          </div>
          <div class="category-bar">
            <div class="category-fill" :style="{width: `${(count / stats.totalDocs) * 100}%`}"></div>
          </div>
        </div>
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
  updateTime: null,
  commits: []
})

const loading = ref(true)

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

// 加载数据
async function loadStats() {
  try {
    const response = await fetch('/WTC-Docs/stats.json?' + Date.now())
    if (response.ok) {
      const data = await response.json()
      stats.value = data
    }
  } catch (error) {
    console.error('Failed to load stats:', error)
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
  padding: 1.2rem;
  text-align: center;
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 20px -10px rgba(0, 0, 0, 0.1);
  border-color: var(--vp-c-brand);
}

.stat-icon {
  font-size: 1.8rem;
  margin-bottom: 0.3rem;
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: var(--vp-c-brand);
  margin: 0.3rem 0;
}

.stat-label {
  color: var(--vp-c-text-2);
  font-size: 0.85rem;
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
}

.category-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
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