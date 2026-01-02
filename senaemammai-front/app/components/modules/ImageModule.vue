<script setup lang="ts">
import { useParallax, type ParallaxConfig } from '~/composables/useParallax'

const props = defineProps<{
    data: {
        src: string
        alt?: string
        height?: string // e.g. 'h-64' or 'h-auto'
        fit?: 'cover' | 'contain'
    },
    config: ParallaxConfig
}>()

const el = ref<HTMLElement | null>(null)
const { animateElement } = useParallax()

onMounted(() => {
    if (el.value) animateElement(el.value, props.config)
})

watch(() => props.config, (newConfig) => {
    if (el.value) animateElement(el.value, newConfig)
}, { deep: true })
</script>

<template>
    <div 
        ref="el" 
        class="module-image w-full flex transition-all duration-500"
        :class="[
            data.align === 'left' ? 'justify-start' : data.align === 'right' ? 'justify-end' : 'justify-center'
        ]"
    >
        <div 
            class="relative overflow-hidden transition-all duration-500"
            :class="[
                data.radius ? `rounded-${data.radius}` : 'rounded-lg',
                data.shadow ? `shadow-${data.shadow}` : ''
            ]"
            :style="{
                width: data.width ? `${data.width}%` : '100%',
                maxWidth: '100%',
                filter: `
                    blur(${data.effects?.blur || 0}px) 
                    grayscale(${data.effects?.grayscale || 0}%) 
                    opacity(${data.effects?.opacity !== undefined ? data.effects.opacity : 1})
                `
            }"
        >
            <NuxtImg 
                :src="data.src" 
                :alt="data.alt || ''"
                class="w-full h-auto object-cover block"
                :class="data.aspect_ratio || 'aspect-video'"
            />
            
            <!-- Overlay Effect (Optional) -->
            <div v-if="data.effects?.overlay" class="absolute inset-0 bg-black/20 pointer-events-none"></div>
        </div>
    </div>
</template>
