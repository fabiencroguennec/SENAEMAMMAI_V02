<script setup lang="ts">
import { gsap } from 'gsap'

const props = defineProps<{
    preset: {
        id: string
        name: string
        config: any
        is_system?: boolean
    },
    selected?: boolean
}>()

const emit = defineEmits(['select', 'delete'])

const boxRef = ref<HTMLElement | null>(null)
let ctx: any = null
let tl: any = null

const playAnimation = () => {
    if (!boxRef.value || !props.preset.config?.steps) return
    
    // Clean previous
    if (ctx) ctx.revert()
    
    ctx = gsap.context(() => {
        const steps = props.preset.config.steps
        
        // Create a Timeline that simulates the scroll timeline
        // But auto-playing for preview
        tl = gsap.timeline({ repeat: -1, repeatDelay: 1, yoyo: true })
        
        // Setup initial state
        const startVars: any = { 
            y: steps.start?.y || 0,
            x: steps.start?.x || 0,
            opacity: steps.start?.opacity !== undefined ? steps.start.opacity : 1,
            scale: steps.start?.scale !== undefined ? steps.start.scale : 1,
            rotation: steps.start?.rotate || 0,
            duration: 0 // Immediate set
        }
        if (steps.start?.blur) startVars.filter = `blur(${steps.start.blur}px)`
        
        // Set start
        tl.set(boxRef.value, startVars)

        // Animate to Active
        const toActiveVars: any = {
            y: steps.active?.y || 0,
            x: steps.active?.x || 0,
            opacity: steps.active?.opacity !== undefined ? steps.active.opacity : 1,
            scale: steps.active?.scale !== undefined ? steps.active.scale : 1,
            rotation: steps.active?.rotate || 0,
            duration: 0.8,
            ease: 'power2.out'
        }
        if (steps.active?.blur !== undefined) toActiveVars.filter = `blur(${steps.active.blur}px)`
        
        tl.to(boxRef.value, toActiveVars)

        // Animate to End (if differs from active significantly, or just hold)
        // For preview, usually Start -> Active is the most important part for entrance
        // If it's an exit animation, Active -> End is important.
        
        // Heuristic: If End vars exist and are different, append them
        if (steps.end && (steps.end.opacity !== steps.active?.opacity || steps.end.y !== steps.active?.y)) {
             const toEndVars: any = {
                y: steps.end.y || 0,
                x: steps.end.x || 0,
                opacity: steps.end.opacity !== undefined ? steps.end.opacity : 1,
                scale: steps.end.scale !== undefined ? steps.end.scale : 1,
                rotation: steps.end.rotate || 0,
                duration: 0.8,
                ease: 'power2.in',
                delay: 0.5 // Hold active for a bit
            }
            if (steps.end.blur !== undefined) toEndVars.filter = `blur(${steps.end.blur}px)`
            tl.to(boxRef.value, toEndVars)
        }

    }, boxRef.value)
}

onMounted(() => {
    // Play on mount
    playAnimation()
})

onUnmounted(() => {
    if (ctx) ctx.revert()
})

// Replay on hover
const onMouseEnter = () => {
    if (tl) tl.play(0)
}
</script>

<template>
    <div 
        class="relative group cursor-pointer border rounded-lg overflow-hidden transition-all bg-gray-900"
        :class="selected ? 'border-primary-500 ring-1 ring-primary-500' : 'border-gray-700 hover:border-gray-500'"
        @click="$emit('select', preset)"
        @mouseenter="onMouseEnter"
    >
        <!-- Thumbnail Stage -->
        <div class="h-20 w-full flex items-center justify-center bg-gray-950/50 overflow-hidden relative">
            <!-- Grid Background -->
            <div class="absolute inset-0 opacity-20 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:10px_10px]"></div>
            
            <!-- Animated Box -->
            <div ref="boxRef" class="w-8 h-8 bg-primary-500 rounded shadow-lg flex items-center justify-center text-[10px] text-white font-bold">
                A
            </div>
        </div>

        <!-- Label -->
        <div class="p-2 border-t border-gray-800 bg-gray-900 flex items-center justify-between">
            <span class="text-xs font-medium text-gray-300 truncate pr-2">{{ preset.name }}</span>
        </div>
        
        <!-- Delete Button (Hover) -->
        <button 
            v-if="!preset.is_system"
            @click.stop="$emit('delete', preset)"
            class="absolute top-1 right-1 p-1 rounded bg-red-500 text-white opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-600 z-10"
            title="Supprimer le preset"
        >
            <UIcon name="i-heroicons-trash" class="w-3 h-3" />
        </button>
    </div>
</template>
