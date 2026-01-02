<script setup lang="ts">
const props = defineProps<{
    modelValue: {
        type: 'solid' | 'gradient',
        color?: string,
        gradient_stops?: Array<{ id: number, x: number, y: number, color: string }>
    }
}>()

const emit = defineEmits(['update:modelValue'])

const localConfig = ref({
    type: 'solid',
    color: '#000000',
    gradient_stops: [
        { id: 1, x: 50, y: 50, color: '#4f46e5' }
    ],
    ...props.modelValue
})

// Sync back to parent
watch(localConfig, (val) => {
    emit('update:modelValue', val)
}, { deep: true })

// Presets
const solidPresets = [
    { label: 'Blanc', value: '#ffffff', class: 'bg-white border border-gray-200' },
    { label: 'Noir', value: '#000000', class: 'bg-black border border-gray-800' },
    { label: 'Zinc 900', value: '#18181b', class: 'bg-zinc-900 border border-zinc-700' },
    { label: 'Zinc 950', value: '#09090b', class: 'bg-zinc-950 border border-zinc-700' },
    { label: 'Primary', value: 'var(--color-primary-500)', class: 'bg-primary-500' },
]

// Gradient Logic
const containerRef = ref<HTMLElement | null>(null)
const draggingStop = ref<number | null>(null)
const selectedStopId = ref<number | null>(null)

const addStop = (e: MouseEvent) => {
    if (localConfig.value.gradient_stops.length >= 5) return
    if (draggingStop.value !== null) return // Just finished dragging
    
    const rect = (e.target as HTMLElement).getBoundingClientRect()
    const x = Math.round(((e.clientX - rect.left) / rect.width) * 100)
    const y = Math.round(((e.clientY - rect.top) / rect.height) * 100)
    
    const newId = Date.now()
    localConfig.value.gradient_stops.push({
        id: newId,
        x,
        y,
        color: '#ffffff'
    })
    selectedStopId.value = newId
}

const removeStop = (id: number) => {
    localConfig.value.gradient_stops = localConfig.value.gradient_stops.filter(s => s.id !== id)
    if (selectedStopId.value === id) selectedStopId.value = null
}

const onMouseDown = (id: number, e: MouseEvent) => {
    e.stopPropagation()
    draggingStop.value = id
    selectedStopId.value = id
    
    const moveHandler = (moveEvent: MouseEvent) => {
        if (!draggingStop.value || !containerRef.value) return
        const rect = containerRef.value.getBoundingClientRect()
        let x = ((moveEvent.clientX - rect.left) / rect.width) * 100
        let y = ((moveEvent.clientY - rect.top) / rect.height) * 100
        
        // Clamp
        x = Math.max(0, Math.min(100, x))
        y = Math.max(0, Math.min(100, y))
        
        const stop = localConfig.value.gradient_stops.find(s => s.id === draggingStop.value)
        if (stop) {
            stop.x = Math.round(x)
            stop.y = Math.round(y)
        }
    }
    
    const upHandler = () => {
        draggingStop.value = null
        window.removeEventListener('mousemove', moveHandler)
        window.removeEventListener('mouseup', upHandler)
    }
    
    window.addEventListener('mousemove', moveHandler)
    window.addEventListener('mouseup', upHandler)
}

const computedGradient = computed(() => {
    if (localConfig.value.type === 'solid') return {}
    
    // Base bg
    const stops = localConfig.value.gradient_stops.map(stop => {
        return `radial-gradient(circle at ${stop.x}% ${stop.y}%, ${stop.color} 0%, transparent 50%)`
    }).join(', ')
    
    return {
        backgroundColor: '#000000', // Base fallback
        backgroundImage: stops
    }
})
</script>

<template>
<div class="space-y-4">
    <!-- Mode Switcher -->
    <div class="flex bg-gray-900 p-1 rounded-lg border border-gray-800">
        <button 
            class="flex-1 text-xs py-1.5 rounded-md transition-colors"
            :class="localConfig.type === 'solid' ? 'bg-gray-700 text-white shadow' : 'text-gray-400 hover:text-gray-200'"
            @click="localConfig.type = 'solid'"
        >
            Uni (Solide)
        </button>
        <button 
            class="flex-1 text-xs py-1.5 rounded-md transition-colors"
            :class="localConfig.type === 'gradient' ? 'bg-gray-700 text-white shadow' : 'text-gray-400 hover:text-gray-200'"
            @click="localConfig.type = 'gradient'"
        >
            Gradient (Mesh)
        </button>
    </div>

    <!-- SOLID EDITOR -->
    <div v-if="localConfig.type === 'solid'" class="space-y-4 animate-in fade-in">
        <div class="grid grid-cols-5 gap-2">
            <button 
                v-for="preset in solidPresets" 
                :key="preset.value"
                class="w-full aspect-square rounded-full shadow-sm hover:scale-110 transition-transform"
                :class="preset.class"
                :title="preset.label"
                @click="localConfig.color = preset.value"
            ></button>
        </div>
        <div class="flex items-center gap-2 bg-gray-900 border border-gray-800 rounded p-2">
            <input type="color" v-model="localConfig.color" class="w-8 h-8 rounded cursor-pointer bg-transparent border-none p-0" />
            <input type="text" v-model="localConfig.color" class="bg-transparent text-sm text-white focus:outline-none w-full" placeholder="#000000" />
        </div>
    </div>

    <!-- GRADIENT EDITOR -->
    <div v-else class="space-y-4 animate-in fade-in">
        <div class="flex justify-between items-center text-xs text-gray-500">
            <span>Points: {{ localConfig.gradient_stops.length }}/5</span>
            <span>Cliquez pour ajouter, glissez pour déplacer</span>
        </div>

        <!-- Canvas -->
        <div 
            ref="containerRef"
            class="w-full h-48 rounded-xl border border-gray-700 relative overflow-hidden cursor-crosshair shadow-inner group"
            :style="computedGradient"
            @click="addStop"
        >
            <div 
                v-for="(stop, index) in localConfig.gradient_stops"
                :key="stop.id"
                class="absolute w-6 h-6 -ml-3 -mt-3 rounded-full border-2 border-white shadow-xl cursor-move flex items-center justify-center group/point transition-transform hover:scale-125 z-10"
                :class="selectedStopId === stop.id ? 'ring-2 ring-white scale-125' : ''"
                :style="{ left: stop.x + '%', top: stop.y + '%' }"
                @mousedown="(e) => onMouseDown(stop.id, e)"
                @click.stop="selectedStopId = stop.id"
            >
                <div class="w-full h-full rounded-full" :style="{ backgroundColor: stop.color }"></div>
                
                <!-- Remove Button (Hover) -->
                <button 
                    class="absolute -top-6 bg-red-500 text-white rounded-full p-0.5 opacity-0 group-hover/point:opacity-100 transition-opacity"
                    @click.stop="removeStop(stop.id)"
                >
                    <UIcon name="i-heroicons-x-mark" class="w-3 h-3" />
                </button>
            </div>
        </div>

        <!-- Stop List -->
        <div class="space-y-2">
            <div 
                v-for="(stop, index) in localConfig.gradient_stops" 
                :key="stop.id" 
                class="flex items-center gap-2 p-2 rounded border transition-all duration-200"
                :class="selectedStopId === stop.id ? 'bg-gray-800 border-primary-500 ring-1 ring-primary-500' : 'bg-gray-900/50 border-gray-800 hover:border-gray-700'"
                @click="selectedStopId = stop.id"
            >
                <div class="w-6 h-6 rounded-full border border-gray-700 overflow-hidden relative">
                    <input type="color" v-model="stop.color" class="absolute inset-[-4px] w-[200%] h-[200%] cursor-pointer" />
                </div>
                <div class="flex-1 grid grid-cols-2 gap-2 text-[10px] text-gray-400">
                    <div class="flex items-center gap-1">X: <input v-model.number="stop.x" type="number" class="bg-transparent w-8 border-b border-gray-700 text-white focus:outline-none text-center" />%</div>
                    <div class="flex items-center gap-1">Y: <input v-model.number="stop.y" type="number" class="bg-transparent w-8 border-b border-gray-700 text-white focus:outline-none text-center" />%</div>
                </div>
                <UButton icon="i-heroicons-trash" color="gray" variant="ghost" size="2xs" @click.stop="removeStop(stop.id)" />
            </div>
        </div>
    </div>
</div>
</template>
