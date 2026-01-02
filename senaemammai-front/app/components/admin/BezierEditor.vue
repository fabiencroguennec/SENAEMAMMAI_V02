<script setup lang="ts">
const props = defineProps<{
  modelValue: string // e.g. "0.25,0.1,0.25,1.0"
}>()

const emit = defineEmits(['update:modelValue'])

const svgRef = ref<HTMLElement | null>(null)
const draggingInfo = ref<{ point: 1 | 2 } | null>(null)

// Parse existing value or default to ease (0.25, 0.1, 0.25, 1.0)
const points = computed(() => {
  const val = props.modelValue || '0.25,0.1,0.25,1.0'
  // Remove cubic-bezier() wrapper if present just in case
  const clean = val.replace(/cubic-bezier\(|\)/g, '')
  const parts = clean.split(',').map(s => parseFloat(s.trim()))
  if (parts.length !== 4) return { x1: 0.25, y1: 0.1, x2: 0.25, y2: 1.0 }
  return { x1: parts[0], y1: parts[1], x2: parts[2], y2: parts[3] }
})

// Convert normalized (0-1) coordinates to SVG space (0-100)
// Note: Y is pushed fast from bottom (100) to top (0) in SVG, so ySVG = 100 - (yNorm * 100)
const width = 120
const height = 120
const padding = 20
const drawW = width - padding * 2
const drawH = height - padding * 2

const toSVG = (x: number, y: number) => ({
  x: padding + x * drawW,
  y: padding + drawH - y * drawH
})

const fromSVG = (x: number, y: number) => ({
  x: Math.max(0, Math.min(1, (x - padding) / drawW)),
  y: (padding + drawH - y) / drawH // Unbounded Y allowed for elasticity? Usually cubic-bezier Y can go outside 0-1, but let's clamp for simplicity first unless requested. CSS allows almost anything for Y. Let's start with flexible Y.
})

const p1 = computed(() => toSVG(points.value.x1, points.value.y1))
const p2 = computed(() => toSVG(points.value.x2, points.value.y2))
const start = toSVG(0, 0)
const end = toSVG(1, 1)

const pathD = computed(() => {
  return `M ${start.x} ${start.y} C ${p1.value.x} ${p1.value.y}, ${p2.value.x} ${p2.value.y}, ${end.x} ${end.y}`
})

const onPointerDown = (e: PointerEvent, pointIdx: 1 | 2) => {
  e.preventDefault()
  e.stopPropagation()
  draggingInfo.value = { point: pointIdx }
  window.addEventListener('pointermove', onPointerMove)
  window.addEventListener('pointerup', onPointerUp)
}

const onPointerMove = (e: PointerEvent) => {
  if (!svgRef.value || !draggingInfo.value) return

  const rect = svgRef.value.getBoundingClientRect()
  const ex = e.clientX - rect.left
  const ey = e.clientY - rect.top

  const norm = fromSVG(ex, ey)
  
  // X must be in [0, 1] for valid CSS cubic-bezier time
  const newX = Math.max(0, Math.min(1, norm.x))
  // Y can theoretically be anything, but let's limit to reasonable [-0.5, 1.5] for UI
  const newY = Number(norm.y.toFixed(3)) // Keep precision

  const current = { ...points.value }
  
  if (draggingInfo.value.point === 1) {
    current.x1 = Number(newX.toFixed(3))
    current.y1 = newY
  } else {
    current.x2 = Number(newX.toFixed(3))
    current.y2 = newY
  }

  emit('update:modelValue', `${current.x1},${current.y1},${current.x2},${current.y2}`)
}

const onPointerUp = () => {
  draggingInfo.value = null
  window.removeEventListener('pointermove', onPointerMove)
  window.removeEventListener('pointerup', onPointerUp)
}

const applyPreset = (preset: string) => {
    emit('update:modelValue', preset)
}

const presets = [
    { label: 'Linear', value: '0,0,1,1' },
    { label: 'Ease', value: '0.25,0.1,0.25,1.0' },
    { label: 'Ease In', value: '0.42,0,1,1' },
    { label: 'Ease Out', value: '0,0,0.58,1' },
    { label: 'Ease In Out', value: '0.42,0,0.58,1' },
    { label: 'Elastic', value: '0.5,-0.5,0.5,1.5' },
]

</script>

<template>
  <div class="flex flex-col gap-2">
      <div class="flex gap-4 items-start">
          <div 
            ref="svgRef" 
            class="relative bg-gray-900 border border-gray-700 rounded select-none cursor-crosshair shadow-inner shrink-0"
            :style="{ width: width + 'px', height: height + 'px' }"
          >
              <!-- Grid Lines -->
              <div class="absolute inset-0 pointer-events-none opacity-20">
                  <svg :width="width" :height="height">
                      <!-- 0 and 1 lines -->
                      <line :x1="padding" :y1="padding" :x2="width-padding" :y2="padding" stroke="white" stroke-dasharray="2,2" />
                      <line :x1="padding" :y1="height-padding" :x2="width-padding" :y2="height-padding" stroke="white" stroke-dasharray="2,2" />
                  </svg>
              </div>

              <svg :width="width" :height="height" class="overflow-visible">
                  <!-- Handles Lines -->
                  <line :x1="start.x" :y1="start.y" :x2="p1.x" :y2="p1.y" stroke="#666" stroke-width="1" />
                  <line :x1="end.x" :y1="end.y" :x2="p2.x" :y2="p2.y" stroke="#666" stroke-width="1" />
                  
                  <!-- Main Curve -->
                  <path :d="pathD" stroke="#3b82f6" stroke-width="3" fill="none" />

                  <!-- Control Points -->
                  <circle 
                    :cx="p1.x" :cy="p1.y" r="6" 
                    fill="#ec4899" 
                    class="cursor-grab transition-colors hover:fill-primary-400"
                    @pointerdown="(e) => onPointerDown(e, 1)"
                  />
                  <circle 
                    :cx="p2.x" :cy="p2.y" r="6" 
                    fill="#ec4899" 
                    class="cursor-grab transition-colors hover:fill-primary-400"
                    @pointerdown="(e) => onPointerDown(e, 2)"
                  />
              </svg>
          </div>

          <!-- Presets & Info -->
          <div class="flex-1 space-y-1">
              <div class="grid grid-cols-3 gap-1">
                  <button 
                    v-for="p in presets" :key="p.label" 
                    @click="applyPreset(p.value)"
                    class="px-1 py-0.5 text-[9px] bg-gray-800 hover:bg-gray-700 text-gray-300 rounded border border-gray-700 transition truncate"
                    :class="{ 'border-primary-500 text-white': modelValue === p.value }"
                    :title="p.label"
                  >
                      {{ p.label }}
                  </button>
              </div>
              <div class="text-[9px] font-mono text-gray-500 text-center break-all bg-gray-950/30 rounded px-1">
                  {{ modelValue }}
              </div>
          </div>
      </div>
  </div>
</template>
