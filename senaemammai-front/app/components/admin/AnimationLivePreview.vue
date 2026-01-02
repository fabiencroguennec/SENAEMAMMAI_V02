<script setup lang="ts">
import { gsap } from 'gsap'
import { CustomEase } from 'gsap/CustomEase'

gsap.registerPlugin(CustomEase)

const props = defineProps<{
    modelValue: any // The full config object
    triggerStart?: string
    triggerEnd?: string
}>()

const emit = defineEmits<{
    (e: 'update:triggerStart', value: string): void
    (e: 'update:triggerEnd', value: string): void
}>()

const boxRef = ref<HTMLElement | null>(null)
const containerRef = ref<HTMLElement | null>(null)
let ctx: any = null
let tl: any = null
let isDraggingStart = false
let isDraggingEnd = false

// Helper: Calculate percentage from Y position
const calculatePercentage = (clientY: number) => {
    if (!containerRef.value) return 50
    const rect = containerRef.value.getBoundingClientRect()
    const relativeY = clientY - rect.top
    const percent = Math.max(0, Math.min(100, (relativeY / rect.height) * 100))
    return Math.round(percent)
}

// Mouse Handlers
const onMouseDownStart = (e: MouseEvent) => {
    e.preventDefault()
    isDraggingStart = true
    window.addEventListener('mousemove', onMoveStart)
    window.addEventListener('mouseup', onUpStart)
}

const onMoveStart = (e: MouseEvent) => {
    if (!isDraggingStart) return
    let percent = calculatePercentage(e.clientY)
    
    // Constraint removed per request

    const anchor = props.triggerStart?.split(' ')[0] || 'top'
    let value = percent // Always use top-down percentage
    
    emit('update:triggerStart', `${anchor} ${value}%`)
}

const onUpStart = () => {
    isDraggingStart = false
    window.removeEventListener('mousemove', onMoveStart)
    window.removeEventListener('mouseup', onUpStart)
}

const onMouseDownEnd = (e: MouseEvent) => {
    e.preventDefault()
    isDraggingEnd = true
    window.addEventListener('mousemove', onMoveEnd)
    window.addEventListener('mouseup', onUpEnd)
}

const onMoveEnd = (e: MouseEvent) => {
    if (!isDraggingEnd) return
    let percent = calculatePercentage(e.clientY)

    // Constraint removed per request

    const anchor = props.triggerEnd?.split(' ')[0] || 'bottom'
    
    let value = percent // Always use top-down percentage
    
    emit('update:triggerEnd', `${anchor} ${value}%`)
}

const onUpEnd = () => {
    isDraggingEnd = false
    window.removeEventListener('mousemove', onMoveEnd)
    window.removeEventListener('mouseup', onUpEnd)
}

// Parse trigger string "top 80%" -> percentage for CSS top
const getLinePosition = (val?: string) => {
    if (!val) return 50
    const parts = val.split(' ')
    if (parts.length < 2) return 50
    
    const anchor = parts[0]
    const percent = parseInt(parts[1]) || 0
    
    
    if (anchor === 'top') return percent
    if (anchor === 'bottom') return percent // Always visual top-down
    if (anchor === 'center') return 50 
    return 50
}

const runPreview = () => {
    if (!boxRef.value || !props.modelValue?.steps) return

    if (ctx) ctx.revert()

    ctx = gsap.context(() => {
        const steps = props.modelValue.steps
        
        // Define timeline
        tl = gsap.timeline({ repeat: -1, repeatDelay: 1 })
        
const getEase = (bezierStr: string) => {
             if (!bezierStr) return 'power2.out'
             // Create unique ID for the ease based on string to avoid collision/recreation overhead if possible, 
             // but here we just want it to work.
             // Convert "x1,y1,x2,y2" to "M0,0 C<x1>,<y1> <x2>,<y2> 1,1"
             const parts = bezierStr.split(',').map(s => parseFloat(s))
             if (parts.length === 4) {
                 const path = `M0,0 C${parts[0]},${parts[1]} ${parts[2]},${parts[3]} 1,1`
                 return CustomEase.create("customEase" + Date.now() + Math.random(), path)
             }
             return 'power2.out'
        }

        // 1. Reset (Start State)
        const startVars: any = { 
            y: steps.start?.y || 0,
            x: steps.start?.x || 0,
            opacity: steps.start?.opacity !== undefined ? steps.start.opacity : 1,
            scale: steps.start?.scale !== undefined ? steps.start.scale : 1,
            rotation: steps.start?.rotate || 0,
            filter: steps.start?.blur ? `blur(${steps.start.blur}px)` : 'blur(0px)',
            background: '#a855f7' // Primary-500
        }
        
        // Instant set
        tl.set(boxRef.value, startVars)
        
        // 2. Animate to Active
        const toActiveVars: any = {
            y: steps.active?.y || 0,
            x: steps.active?.x || 0,
            opacity: steps.active?.opacity !== undefined ? steps.active.opacity : 1,
            scale: steps.active?.scale !== undefined ? steps.active.scale : 1,
            rotation: steps.active?.rotate || 0,
            filter: steps.active?.blur !== undefined ? `blur(${steps.active.blur}px)` : 'blur(0px)',
            // Use config duration, default to 1s
            duration: props.modelValue.duration || 1,
            ease: getEase(props.modelValue.ease_in)
        }
        
        // Add label change simulation if needed, but simple motion is enough
        tl.to(boxRef.value, toActiveVars)

        // 3. Animate to End (if it exists)
        // Check if ANY property changes
        if (steps.end) {
             const toEndVars: any = {
                y: steps.end.y || 0,
                x: steps.end.x || 0,
                opacity: steps.end.opacity !== undefined ? steps.end.opacity : 1,
                scale: steps.end.scale !== undefined ? steps.end.scale : 1,
                rotation: steps.end.rotate || 0,
                filter: steps.end.blur !== undefined ? `blur(${steps.end.blur}px)` : 'blur(0px)',
                duration: props.modelValue.duration_out || props.modelValue.duration || 1,
                ease: getEase(props.modelValue.ease_out),
                delay: 0.5
            }
            tl.to(boxRef.value, toEndVars)
        } else {
            // Just hold active state a bit longer if no specific end
            tl.to({}, { duration: 1 }) 
        }

    }, boxRef.value)
}

// Watch deep changes to config
watch(() => props.modelValue, () => {
    runPreview()
}, { deep: true })

onMounted(() => {
    runPreview()
})

onUnmounted(() => {
    if (ctx) ctx.revert()
})
</script>

<template>
    <div class="w-full h-full bg-gray-950 border border-gray-700 rounded-lg relative overflow-hidden flex flex-col">
        <!-- Stage -->
        <div 
            ref="containerRef"
            class="flex-1 relative flex items-center justify-center bg-[linear-gradient(45deg,#171717_25%,transparent_25%,transparent_75%,#171717_75%,#171717),linear-gradient(45deg,#171717_25%,transparent_25%,transparent_75%,#171717_75%,#171717)] bg-[length:20px_20px] bg-[position:0_0,10px_10px] bg-gray-950 select-none"
        >
             
             <!-- Crosshairs -->
             <div class="absolute inset-0 flex items-center justify-center pointer-events-none opacity-20">
                 <div class="w-full h-px bg-primary-500/50"></div>
                 <div class="h-full w-px bg-primary-500/50 absolute"></div>
             </div>

             <!-- Animated Element -->
             <div 
                ref="boxRef" 
                class="w-16 h-16 bg-primary-500 rounded-lg shadow-2xl border border-white/20 flex items-center justify-center z-10"
             >
                <UIcon name="i-heroicons-cube" class="text-white w-8 h-8" />
             </div>
             
             <!-- Trigger Lines Overlay (Only if !Scrub) -->
             <div v-if="!modelValue?.scrub" class="absolute inset-0 z-20 overflow-hidden pointer-events-none">
                 <!-- Start Line (Green) -->
                 <div class="absolute w-full flex items-center justify-center transition-all duration-200 pointer-events-auto cursor-row-resize group"
                      :class="{ 'z-50': isDraggingStart, 'z-10': !isDraggingStart }"
                      :style="{ top: `${getLinePosition(props.triggerStart)}%` }"
                      @mousedown="onMouseDownStart"
                    >
                     <!-- Visual Line -->
                     <div class="w-full border-t-2 border-green-500 border-dashed" :class="{ 'border-solid': isDraggingStart }"></div>
                     
                     <!-- Tag -->
                     <span class="absolute left-1 text-[9px] font-bold text-green-400 bg-gray-950/80 px-1 rounded select-none" :class="getLinePosition(props.triggerStart) < 5 ? 'top-1' : '-top-4'">START</span>

                     <!-- Invisible Hit Area (Larger) -->
                     <div class="absolute -top-3 bottom-[-12px] w-full h-6 bg-transparent"></div>
                 </div>
                 
                 <!-- End Line (Red) -->
                 <div class="absolute w-full flex items-center justify-center transition-all duration-200 pointer-events-auto cursor-row-resize group"
                      :class="{ 'z-50': isDraggingEnd, 'z-10': !isDraggingEnd }"
                      :style="{ top: `${getLinePosition(props.triggerEnd)}%` }"
                      @mousedown="onMouseDownEnd"
                    >
                     <!-- Visual Line -->
                     <div class="w-full border-t-2 border-red-500 border-dashed" :class="{ 'border-solid': isDraggingEnd }"></div>

                     <!-- Tag -->
                     <span class="absolute right-1 text-[9px] font-bold text-red-400 bg-gray-950/80 px-1 rounded select-none" :class="getLinePosition(props.triggerEnd) > 95 ? '-top-4' : 'bottom-1'">END</span>

                     <!-- Invisible Hit Area (Larger) -->
                     <div class="absolute -top-3 bottom-[-12px] w-full h-6 bg-transparent"></div>
                 </div>
             </div>

        </div>
    </div>
</template>
