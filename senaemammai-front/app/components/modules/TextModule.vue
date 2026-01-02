<script setup lang="ts">
import { useParallax, type ParallaxConfig } from '~/composables/useParallax'

const props = defineProps<{
    data: {
        content: string
        tag: 'h1' | 'h2' | 'h3' | 'p' | 'div'
        align: 'left' | 'center' | 'right'
        color: string
        fontSize?: string
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
    <component 
        :is="data.tag || 'p'"
        ref="el"
        class="module-text transition-colors duration-300"
        :class="[
            data.align === 'center' ? 'text-center' : data.align === 'right' ? 'text-right' : 'text-left',
            data.fontSize // Add specific Tailwind classes if passed, or handle via style
        ]"
        :style="{ color: data.color }"
    >
        {{ data.content }}
    </component>
</template>
