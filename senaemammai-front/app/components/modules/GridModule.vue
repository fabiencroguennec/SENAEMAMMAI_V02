<script setup lang="ts">
const props = defineProps<{
    data: {
        items?: Array<{
            id: string
            type: 'product' | 'article' | 'image'
            src?: string
            images?: string[]
            title?: string
            subtitle?: string
            link?: string
            obj_id?: string
            // Slideshow Config
            autoplay?: boolean
            allows_arrows?: boolean // 'arrows' in DB
            transition?: 'fade' | 'slide'
            duration?: number
            stop_time?: number
            interval?: number // Legacy fallback
            ease?: string
            slide_direction?: string
            [key: string]: any
        }>
        columns?: {
            sm: number
            md: number
            lg: number
        }
        gap?: string
    },
    config: any
}>()

const getGridClass = () => {
    const cols = props.data.columns || { sm: 1, md: 2, lg: 3 }
    return `grid grid-cols-${cols.sm} md:grid-cols-${cols.md} lg:grid-cols-${cols.lg} ${props.data.gap || 'gap-8'}`
}

// Slideshow Logic
const activeIndices = ref<Record<string, number>>({})
const intervals: Record<string, NodeJS.Timeout> = {}

// Navigation
const nextSlide = (item: any, i: number) => {
    if (!item.images || item.images.length < 2) return
    const key = item.id || `item-${i}`
    const total = item.images.length
    activeIndices.value[key] = ((activeIndices.value[key] || 0) + 1) % total
    resetInterval(item, i)
}

const prevSlide = (item: any, i: number) => {
    if (!item.images || item.images.length < 2) return
    const key = item.id || `item-${i}`
    const total = item.images.length
    // Handle negative modulo javascript quirk
    activeIndices.value[key] = ((activeIndices.value[key] || 0) - 1 + total) % total
    resetInterval(item, i)
}

const resetInterval = (item: any, i: number) => {
    const key = item.id || `item-${i}`
    if (intervals[key]) clearInterval(intervals[key])
    if (item.autoplay !== false) {
        // Total Cycle Time = Stop Time + Animation Duration
        // Default: 3s Pause + 0.8s Anim
        const stopTime = item.stop_time ?? 3000
        const animDuration = item.duration || 800
        const totalDelay = stopTime + animDuration

        intervals[key] = setInterval(() => {
             const key = item.id || `item-${i}`
            if (activeIndices.value[key] === undefined) return
            const total = item.images!.length
            activeIndices.value[key] = ((activeIndices.value[key] || 0) + 1) % total
        }, totalDelay)
    }
}

// Initialize indices and start auto-cycle
onMounted(() => {
    resetAllIntervals()
})

const resetAllIntervals = () => {
    props.data.items?.forEach((item, i) => {
        const key = item.id || `item-${i}`
        // Initialize active index if missing, ensuring separate key space
        if (activeIndices.value[key] === undefined && item.images && item.images.length > 1) {
             activeIndices.value[key] = 0
        }
        
        // Reset/Start Interval
        if (item.images && item.images.length > 1) {
            resetInterval(item, i)
        }
    })
}

// Watch for deep data changes (e.g. timing config from editor) to restart intervals immediately
watch(() => props.data, () => {
   resetAllIntervals()
}, { deep: true })

onUnmounted(() => {
    Object.values(intervals).forEach(clearInterval)
})

const getActiveImage = (item: any, i: number) => {
    if (item.images && item.images.length > 0) {
        const key = item.id || `item-${i}`
        const index = activeIndices.value[key] || 0
        return item.images[index] || item.images[0]
    }
    return item.src || fallbackImage
}

const fallbackImage = 'https://placehold.co/600x400/1a1a1a/FFF?text=No+Image'

const getTransitionName = (item: any) => {
    if (item.transition === 'slide') {
        const dir = item.slide_direction || 'left'
        return `slide-${dir}`
    }
    return 'fade'
}
</script>

<template>
  <div class="w-full" :class="getGridClass()">
      <div 
        v-for="(item, i) in data.items || []" 
        :key="item.id || i"
        class="group relative overflow-hidden rounded-xl border border-gray-800 bg-gray-900/50 hover:border-gray-700 transition-all duration-300"
      >
          <!-- Image Container -->
          <div class="aspect-[4/3] w-full overflow-hidden bg-gray-950 relative">
              <!-- Animated Image Group -->
              <!-- mode="in-out" removed for SLIDE to allow simultaneous movement (push effect) -->
              <!-- mode="in-out" KEPT for FADE to avoid black background flash -->
              <transition-group 
                :name="getTransitionName(item)"
                :mode="item.transition === 'slide' ? undefined : 'in-out'"
                tag="div"
                class="absolute inset-0 w-full h-full"
              >
                  <img 
                    :key="getActiveImage(item, i)"
                    :src="getActiveImage(item, i)" 
                    class="h-full w-full object-cover absolute inset-0 transition-transform duration-700 group-hover:scale-105"
                    :style="{ 
                        '--transition-duration': (item.duration || 800) + 'ms',
                        '--transition-ease': `cubic-bezier(${item.ease || '0.25, 0.1, 0.25, 1.0'})`
                    }"
                    alt=""
                  />
              </transition-group>
              
              <!-- Navigation Arrows -->
              <template v-if="item.images && item.images.length > 1 && item.arrows">
                  <button 
                    @click.stop.prevent="prevSlide(item, i)"
                    class="absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/80 text-white rounded-full p-1.5 opacity-0 group-hover:opacity-100 transition-opacity z-20"
                  >
                      <UIcon name="i-heroicons-chevron-left" class="w-5 h-5" />
                  </button>
                  <button 
                    @click.stop.prevent="nextSlide(item, i)"
                    class="absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/80 text-white rounded-full p-1.5 opacity-0 group-hover:opacity-100 transition-opacity z-20"
                  >
                      <UIcon name="i-heroicons-chevron-right" class="w-5 h-5" />
                  </button>
              </template>

              <!-- Indicators -->
              <div v-if="item.images && item.images.length > 1" class="absolute bottom-2 left-0 right-0 z-20 flex justify-center gap-1.5 pointer-events-none">
                  <div 
                    v-for="(_, idx) in item.images" 
                    :key="idx" 
                    class="h-1 rounded-full transition-all duration-300" 
                    :class="activeIndices[item.id || `item-${i}`] === idx ? 'w-4 bg-white' : 'w-1 bg-white/40'"
                  ></div>
              </div>
          </div>

          <!-- Content Overlay for Image Type or Bottom Content for others -->
          <div class="p-4 relative z-10">
              <h3 class="text-lg font-bold text-white mb-1">{{ item.title || 'Sans titre' }}</h3>
              <p v-if="item.subtitle" class="text-sm text-gray-400">{{ item.subtitle }}</p>
              
              <!-- Link Overlay -->
              <a v-if="item.link" :href="item.link" class="absolute inset-0 z-20"></a>
          </div>
      </div>
  </div>
</template>

<style scoped>
/* FADE TRANSITION */
.fade-enter-active,
.fade-leave-active {
  transition: opacity var(--transition-duration, 800ms) ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* SLIDE LEFT (Default) - Enter Right, Exit Left */
/* Simulates a 'Push' effect when mode is undefined (simultaneous) */
.slide-left-enter-active,
.slide-left-leave-active {
  transition: transform var(--transition-duration, 600ms) var(--transition-ease, ease-in-out);
}
.slide-left-enter-from { transform: translateX(100%); z-index: 10; }
.slide-left-leave-to { transform: translateX(-100%); z-index: 10; }

/* SLIDE RIGHT - Enter Left, Exit Right */
.slide-right-enter-active,
.slide-right-leave-active {
  transition: transform var(--transition-duration, 600ms) var(--transition-ease, ease-in-out);
}
.slide-right-enter-from { transform: translateX(-100%); z-index: 10; }
.slide-right-leave-to { transform: translateX(100%); z-index: 10; }

/* SLIDE TOP - Enter Bottom, Exit Top */
.slide-top-enter-active,
.slide-top-leave-active {
  transition: transform var(--transition-duration, 600ms) var(--transition-ease, ease-in-out);
}
.slide-top-enter-from { transform: translateY(100%); z-index: 10; }
.slide-top-leave-to { transform: translateY(-100%); z-index: 10; }

/* SLIDE BOTTOM - Enter Top, Exit Bottom */
.slide-bottom-enter-active,
.slide-bottom-leave-active {
  transition: transform var(--transition-duration, 600ms) var(--transition-ease, ease-in-out);
}
.slide-bottom-enter-from { transform: translateY(-100%); z-index: 10; }
.slide-bottom-leave-to { transform: translateY(100%); z-index: 10; }
</style>
