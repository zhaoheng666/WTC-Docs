<template>
  <span class="animated-number">{{ displayValue }}</span>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'

const props = defineProps({
  value: {
    type: Number,
    required: true
  },
  duration: {
    type: Number,
    default: 1000
  },
  decimals: {
    type: Number,
    default: 0
  }
})

const displayValue = ref(0)

const animateValue = (start, end, duration) => {
  const startTime = Date.now()
  const endTime = startTime + duration
  
  const update = () => {
    const now = Date.now()
    const remaining = Math.max(endTime - now, 0)
    const progress = 1 - (remaining / duration)
    const currentValue = start + (end - start) * easeOutQuart(progress)
    
    displayValue.value = props.decimals > 0 
      ? currentValue.toFixed(props.decimals)
      : Math.round(currentValue)
    
    if (remaining > 0) {
      requestAnimationFrame(update)
    }
  }
  
  requestAnimationFrame(update)
}

// 缓动函数
const easeOutQuart = (t) => {
  return 1 - Math.pow(1 - t, 4)
}

onMounted(() => {
  animateValue(0, props.value, props.duration)
})

watch(() => props.value, (newVal, oldVal) => {
  animateValue(oldVal || 0, newVal, props.duration)
})
</script>

<style scoped>
.animated-number {
  display: inline-block;
  font-variant-numeric: tabular-nums;
}
</style>