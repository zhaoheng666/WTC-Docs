<template>
  <div class="dashboard-container">
    <!-- 最近更新时间线 -->
    <div class="timeline-section">
      <h2 class="section-title">🕒 最近更新</h2>
      <div class="timeline">
        <div 
          v-for="(item, index) in recentUpdates" 
          :key="index"
          class="timeline-item"
        >
          <div class="timeline-marker">
            <span class="pulse"></span>
          </div>
          <div class="timeline-content">
            <div class="timeline-time">{{ item.date }}</div>
            <a :href="item.path" class="timeline-title">
              {{ item.file }}
            </a>
            <div class="timeline-message">{{ item.message }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 最近更新数据
const recentUpdates = ref([])

onMounted(() => {
  // 加载实际数据
  loadDashboardData()
})

const loadDashboardData = async () => {
  try {
    // 获取基础 URL - 兼容开发和生产环境
    const base = import.meta.env.BASE_URL || '/'
    const statsPath = `${base}stats.json`.replace('//', '/')
    
    console.log('Loading stats from:', statsPath)
    
    const response = await fetch(statsPath)
    if (response.ok) {
      const data = await response.json()
      if (data && data.recentUpdates) {
        recentUpdates.value = data.recentUpdates
        console.log('Stats loaded successfully:', data.recentUpdates.length, 'items')
      }
    } else {
      throw new Error(`Failed to fetch: ${response.status}`)
    }
  } catch (error) {
    console.log('加载数据失败，使用默认数据:', error)
    // 默认数据
    recentUpdates.value = [
      { date: '09-17', file: 'index', path: '/活动/index.md', message: 'docs: 更新 index' },
      { date: '09-17', file: 'README', path: '/README.md', message: 'docs: 更新 README' },
      { date: '09-17', file: 'index', path: '/index.md', message: 'docs: 更新 index' }
    ]
  }
}
</script>

<style scoped>
.dashboard-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

/* 时间线 */
.timeline-section {
  margin-bottom: 40px;
}

.section-title {
  font-size: 1.5rem;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.timeline {
  position: relative;
  padding-left: 30px;
}

.timeline::before {
  content: '';
  position: absolute;
  left: 10px;
  top: 0;
  bottom: 0;
  width: 2px;
  background: var(--vp-c-divider);
}

.timeline-item {
  position: relative;
  padding: 15px;
  margin-bottom: 20px;
  background: var(--vp-c-bg-soft);
  border-radius: 8px;
  border: 1px solid var(--vp-c-divider);
  transition: transform 0.3s;
}

.timeline-item:hover {
  transform: translateX(5px);
}

.timeline-marker {
  position: absolute;
  left: -24px;
  top: 20px;
  width: 12px;
  height: 12px;
  background: var(--vp-c-brand);
  border-radius: 50%;
  border: 2px solid var(--vp-c-bg);
}

.timeline-marker .pulse {
  display: block;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

.timeline-time {
  font-size: 0.875rem;
  color: var(--vp-c-text-3);
  margin-bottom: 5px;
}

.timeline-title {
  font-weight: 500;
  color: var(--vp-c-brand);
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 5px;
}

.timeline-title:hover {
  text-decoration: underline;
}

.timeline-message {
  font-size: 0.875rem;
  color: var(--vp-c-text-2);
  margin-top: 5px;
}

/* 动画 */
@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(var(--vp-c-brand-rgb), 0.7);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(var(--vp-c-brand-rgb), 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(var(--vp-c-brand-rgb), 0);
  }
}

/* 响应式 */
@media (max-width: 768px) {
  .timeline {
    padding-left: 20px;
  }
  
  .timeline-marker {
    left: -14px;
  }
}
</style>