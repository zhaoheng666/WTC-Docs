<template>
  <div class="dashboard-container">
    <!-- 头部信息 -->
    <div class="dashboard-header">
      <h1 class="dashboard-title">
        <span class="icon">📊</span>
        文档统计仪表板
      </h1>
      <div class="update-time">
        <span class="icon">🕐</span>
        最后更新: {{ updateTime }}
      </div>
    </div>

    <!-- 统计卡片 -->
    <div class="stats-grid">
      <div class="stat-card" v-for="stat in mainStats" :key="stat.label">
        <div class="stat-icon">{{ stat.icon }}</div>
        <div class="stat-content">
          <div class="stat-value">
            <AnimatedNumber :value="stat.value" />
            <span class="stat-unit">{{ stat.unit }}</span>
          </div>
          <div class="stat-label">{{ stat.label }}</div>
        </div>
        <div class="stat-trend" :class="stat.trend > 0 ? 'up' : 'down'" v-if="stat.trend">
          <span>{{ stat.trend > 0 ? '↑' : '↓' }} {{ Math.abs(stat.trend) }}%</span>
        </div>
      </div>
    </div>

    <!-- 分类统计图表 -->
    <div class="chart-section">
      <h2 class="section-title">📂 分类文档分布</h2>
      <div class="category-chart">
        <div class="chart-bars">
          <div 
            v-for="cat in categoryStats" 
            :key="cat.name"
            class="bar-container"
          >
            <div class="bar-label">{{ cat.name }}</div>
            <div class="bar-wrapper">
              <div 
                class="bar-fill"
                :style="{ 
                  width: (cat.count / maxCategoryCount * 100) + '%',
                  background: cat.color 
                }"
              >
                <span class="bar-value">{{ cat.count }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 最近更新时间线 -->
    <div class="timeline-section">
      <h2 class="section-title">🕒 最近更新</h2>
      <div class="timeline">
        <div 
          v-for="(item, index) in recentFiles" 
          :key="index"
          class="timeline-item"
          :class="{ 'new': item.isNew }"
        >
          <div class="timeline-marker">
            <span class="pulse"></span>
          </div>
          <div class="timeline-content">
            <div class="timeline-time">{{ item.time }}</div>
            <a :href="item.link" class="timeline-title">
              {{ item.title }}
              <span v-if="item.isNew" class="new-badge">NEW</span>
            </a>
            <div class="timeline-path">{{ item.path }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 贡献者排行 -->
    <div class="contributors-section">
      <h2 class="section-title">👥 贡献者排行榜</h2>
      <div class="contributors-list">
        <div 
          v-for="(contributor, index) in contributors" 
          :key="contributor.name"
          class="contributor-item"
        >
          <div class="contributor-rank">#{{ index + 1 }}</div>
          <div class="contributor-avatar">
            {{ contributor.name.substring(0, 2).toUpperCase() }}
          </div>
          <div class="contributor-info">
            <div class="contributor-name">{{ contributor.name }}</div>
            <div class="contributor-stats">
              <span class="commits">{{ contributor.commits }} 次提交</span>
              <span class="percentage">{{ contributor.percentage }}%</span>
            </div>
          </div>
          <div class="contributor-bar">
            <div 
              class="bar-progress"
              :style="{ width: contributor.percentage + '%' }"
            ></div>
          </div>
        </div>
      </div>
    </div>

    <!-- 7天活跃度热力图 -->
    <div class="activity-section">
      <h2 class="section-title">📈 近7天活跃度</h2>
      <div class="activity-heatmap">
        <div 
          v-for="day in weekActivity" 
          :key="day.date"
          class="day-block"
          :class="getActivityLevel(day.commits)"
        >
          <div class="day-name">{{ day.name }}</div>
          <div class="day-commits">{{ day.commits }}</div>
          <div class="day-date">{{ day.date.split('-').slice(1).join('/') }}</div>
        </div>
      </div>
    </div>

    <!-- 增长趋势 -->
    <div class="trend-section">
      <h2 class="section-title">📊 文档增长趋势</h2>
      <div class="trend-cards">
        <div class="trend-card">
          <div class="trend-period">今日新增</div>
          <div class="trend-value">{{ growth.today }}</div>
          <div class="trend-icon">📝</div>
        </div>
        <div class="trend-card">
          <div class="trend-period">本周新增</div>
          <div class="trend-value">{{ growth.week }}</div>
          <div class="trend-icon">📚</div>
        </div>
        <div class="trend-card">
          <div class="trend-period">本月新增</div>
          <div class="trend-value">{{ growth.month }}</div>
          <div class="trend-icon">📖</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import AnimatedNumber from './AnimatedNumber.vue'

// 模拟数据 - 实际应从统计脚本生成的 JSON 读取
const updateTime = ref('2025-09-17 10:30:00')

const mainStats = ref([
  { icon: '📄', label: '文档总数', value: 12, unit: '个', trend: 8 },
  { icon: '📁', label: '目录总数', value: 17, unit: '个', trend: 5 },
  { icon: '👥', label: '贡献者', value: 3, unit: '人', trend: 0 },
  { icon: '🔄', label: '总提交', value: 41, unit: '次', trend: 12 }
])

const categoryStats = ref([
  { name: '关卡', count: 1, color: '#7c3aed' },
  { name: '活动', count: 0, color: '#ec4899' },
  { name: 'Native', count: 0, color: '#f59e0b' },
  { name: '协议', count: 1, color: '#10b981' },
  { name: '工具', count: 2, color: '#3b82f6' },
  { name: '其他', count: 4, color: '#6b7280' }
])

const recentFiles = ref([
  { time: '10:30', title: '统计仪表板', path: '/统计仪表板.md', link: '/统计仪表板', isNew: true },
  { time: '09:58', title: 'README', path: '/README.md', link: '/README', isNew: false },
  { time: '02:23', title: '首页', path: '/index.md', link: '/', isNew: false },
  { time: '昨天', title: '协议首页', path: '/协议/index.md', link: '/协议/', isNew: false },
  { time: '昨天', title: '快速开始', path: '/其他/隐藏/快速开始.md', link: '/其他/隐藏/快速开始', isNew: false }
])

const contributors = ref([
  { name: 'zhaoheng', commits: 40, percentage: 100 }
])

const weekActivity = ref([
  { name: '周一', date: '2025-09-11', commits: 0 },
  { name: '周二', date: '2025-09-12', commits: 0 },
  { name: '周三', date: '2025-09-13', commits: 0 },
  { name: '周四', date: '2025-09-14', commits: 0 },
  { name: '周五', date: '2025-09-15', commits: 21 },
  { name: '周六', date: '2025-09-16', commits: 18 },
  { name: '周日', date: '2025-09-17', commits: 2 }
])

const growth = ref({
  today: 1,
  week: 7,
  month: 12
})

const maxCategoryCount = computed(() => {
  return Math.max(...categoryStats.value.map(c => c.count), 1)
})

const getActivityLevel = (commits) => {
  if (commits === 0) return 'level-0'
  if (commits <= 5) return 'level-1'
  if (commits <= 10) return 'level-2'
  if (commits <= 20) return 'level-3'
  return 'level-4'
}

onMounted(() => {
  // 可以在这里加载实际数据
  loadDashboardData()
})

const loadDashboardData = async () => {
  try {
    const response = await fetch('/stats.json')
    if (response.ok) {
      const data = await response.json()
      
      // 更新时间
      updateTime.value = data.updateTime
      
      // 更新主要统计
      mainStats.value = [
        { icon: '📄', label: '文档总数', value: data.totalDocs, unit: '个', trend: 8 },
        { icon: '📁', label: '目录总数', value: data.totalDirs, unit: '个', trend: 5 },
        { icon: '👥', label: '贡献者', value: data.totalContributors, unit: '人', trend: 0 },
        { icon: '🔄', label: '总提交', value: data.totalCommits, unit: '次', trend: 12 }
      ]
      
      // 更新分类统计
      if (data.categoryStats) {
        categoryStats.value = data.categoryStats
      }
      
      // 更新增长数据
      if (data.growth) {
        growth.value = data.growth
      }
    }
  } catch (error) {
    console.log('使用默认数据')
  }
}
</script>

<style scoped>
.dashboard-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 2px solid var(--vp-c-divider);
}

.dashboard-title {
  font-size: 2rem;
  font-weight: bold;
  display: flex;
  align-items: center;
  gap: 10px;
}

.update-time {
  color: var(--vp-c-text-2);
  display: flex;
  align-items: center;
  gap: 5px;
}

/* 统计卡片网格 */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 40px;
}

.stat-card {
  background: var(--vp-c-bg-soft);
  border-radius: 12px;
  padding: 20px;
  position: relative;
  overflow: hidden;
  transition: transform 0.3s, box-shadow 0.3s;
  border: 1px solid var(--vp-c-divider);
}

.stat-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}

.stat-icon {
  font-size: 2rem;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 2rem;
  font-weight: bold;
  color: var(--vp-c-brand);
  display: flex;
  align-items: baseline;
  gap: 5px;
}

.stat-unit {
  font-size: 1rem;
  color: var(--vp-c-text-2);
}

.stat-label {
  color: var(--vp-c-text-2);
  margin-top: 5px;
}

.stat-trend {
  position: absolute;
  top: 20px;
  right: 20px;
  padding: 4px 8px;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

.stat-trend.up {
  background: rgba(16, 185, 129, 0.1);
  color: #10b981;
}

.stat-trend.down {
  background: rgba(239, 68, 68, 0.1);
  color: #ef4444;
}

/* 分类图表 */
.chart-section, .timeline-section, .contributors-section, 
.activity-section, .trend-section {
  margin-bottom: 40px;
}

.section-title {
  font-size: 1.5rem;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.chart-bars {
  background: var(--vp-c-bg-soft);
  border-radius: 12px;
  padding: 20px;
  border: 1px solid var(--vp-c-divider);
}

.bar-container {
  margin-bottom: 15px;
}

.bar-label {
  font-size: 0.9rem;
  margin-bottom: 5px;
  color: var(--vp-c-text-2);
}

.bar-wrapper {
  background: var(--vp-c-bg);
  border-radius: 20px;
  height: 30px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding-right: 10px;
  transition: width 1s ease-out;
  animation: slideIn 1s ease-out;
}

.bar-value {
  color: white;
  font-weight: bold;
  font-size: 0.875rem;
}

/* 时间线 */
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

.timeline-item.new {
  border-color: var(--vp-c-brand);
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

.timeline-item.new .timeline-marker {
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

.new-badge {
  background: var(--vp-c-brand);
  color: white;
  padding: 2px 6px;
  border-radius: 10px;
  font-size: 0.75rem;
  font-weight: bold;
}

.timeline-path {
  font-size: 0.875rem;
  color: var(--vp-c-text-3);
  margin-top: 5px;
}

/* 贡献者列表 */
.contributors-list {
  background: var(--vp-c-bg-soft);
  border-radius: 12px;
  padding: 20px;
  border: 1px solid var(--vp-c-divider);
}

.contributor-item {
  display: grid;
  grid-template-columns: 30px 50px 1fr 200px;
  gap: 15px;
  align-items: center;
  padding: 15px 0;
  border-bottom: 1px solid var(--vp-c-divider);
}

.contributor-item:last-child {
  border-bottom: none;
}

.contributor-rank {
  font-weight: bold;
  color: var(--vp-c-text-2);
}

.contributor-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--vp-c-brand), var(--vp-c-brand-dark));
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
}

.contributor-name {
  font-weight: 500;
}

.contributor-stats {
  display: flex;
  gap: 15px;
  font-size: 0.875rem;
  color: var(--vp-c-text-2);
}

.contributor-bar {
  background: var(--vp-c-bg);
  border-radius: 20px;
  height: 8px;
  overflow: hidden;
}

.bar-progress {
  height: 100%;
  background: linear-gradient(90deg, var(--vp-c-brand), var(--vp-c-brand-dark));
  border-radius: 20px;
  transition: width 1s ease-out;
}

/* 活跃度热力图 */
.activity-heatmap {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
}

.day-block {
  background: var(--vp-c-bg-soft);
  border-radius: 8px;
  padding: 15px;
  text-align: center;
  border: 1px solid var(--vp-c-divider);
  transition: transform 0.3s;
}

.day-block:hover {
  transform: scale(1.05);
}

.day-block.level-0 { background: var(--vp-c-bg-soft); }
.day-block.level-1 { background: rgba(var(--vp-c-brand-rgb), 0.2); }
.day-block.level-2 { background: rgba(var(--vp-c-brand-rgb), 0.4); }
.day-block.level-3 { background: rgba(var(--vp-c-brand-rgb), 0.6); }
.day-block.level-4 { background: rgba(var(--vp-c-brand-rgb), 0.8); color: white; }

.day-name {
  font-weight: 500;
  margin-bottom: 5px;
}

.day-commits {
  font-size: 1.5rem;
  font-weight: bold;
  color: var(--vp-c-brand);
}

.day-date {
  font-size: 0.75rem;
  color: var(--vp-c-text-3);
  margin-top: 5px;
}

/* 增长趋势卡片 */
.trend-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}

.trend-card {
  background: linear-gradient(135deg, var(--vp-c-bg-soft), var(--vp-c-bg));
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  border: 1px solid var(--vp-c-divider);
  position: relative;
  overflow: hidden;
}

.trend-period {
  color: var(--vp-c-text-2);
  margin-bottom: 10px;
}

.trend-value {
  font-size: 2rem;
  font-weight: bold;
  color: var(--vp-c-brand);
}

.trend-icon {
  position: absolute;
  right: 10px;
  top: 10px;
  font-size: 2rem;
  opacity: 0.2;
}

/* 动画 */
@keyframes slideIn {
  from {
    width: 0;
  }
}

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
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .activity-heatmap {
    grid-template-columns: repeat(4, 1fr);
  }
  
  .contributor-item {
    grid-template-columns: 30px 40px 1fr;
  }
  
  .contributor-bar {
    display: none;
  }
}
</style>