# Visual Builder Architecture - Senaemammai V02

## Concept

The "Visual Builder" allows an administrator to construct pages dynamically by defining "Sections" in the database. The frontend iterates through these records and eagerly loads the corresponding Vue components, applying animations based on configuration.

## Data Flow

1. **Database**: `page_sections` holds the content and order. `ui_config` holds the visual tweaks.
2. **API**: Nuxt fetches a joined query: `select *, ui_config(*) from page_sections where page_slug = 'home' order by order_index asc`.
3. **Frontend**: The `<SectionBuilder />` component acts as the looping engine.

## Component Structure

### 1. `SectionBuilder.vue` (The Engine)

This is a "smart" component that handles data fetching and dynamic rendering.

```vue
<!-- components/SectionBuilder.vue -->
<script setup lang="ts">
import { gsap } from 'gsap'

// Import your section components map
// In a real app, you might use defineAsyncComponent for performance
import HeroSection from './sections/HeroSection.vue'
import ProductGrid from './sections/ProductGrid.vue'
import SplitContent from './sections/SplitContent.vue'

const componentsMap: Record<string, any> = {
  HeroSection,
  ProductGrid,
  SplitContent
}

// Fetch data from Supabase
const client = useSupabaseClient()
const { data: sections } = await useAsyncData('page-sections', async () => {
  const { data } = await client
    .from('page_sections')
    .select(`
      *,
      ui_config (*)
    `)
    .eq('is_visible', true)
    .order('order_index')
  return data
})

// Animation Logic
const animateSection = (el: HTMLElement, config: any) => {
  if (!config || !config.animation_type) return

  switch (config.animation_type) {
    case 'fade-up':
      gsap.from(el, {
        y: 50,
        opacity: 0,
        duration: config.animation_speed || 1,
        scrollTrigger: {
          trigger: el,
          start: 'top 80%',
        }
      })
      break
    case 'parallax':
       // Simple parallax effect
       gsap.to(el, {
         yPercent: -20 * (config.parallax_intensity || 0.5),
         ease: 'none',
         scrollTrigger: {
           trigger: el,
           start: 'top bottom',
           end: 'bottom top',
           scrub: true
         }
       })
      break
  }
}

// Directive or Ref usage to trigger animation on mount
const onSectionMounted = (el: Element, section: any) => {
    if (section.ui_config) {
        animateSection(el as HTMLElement, section.ui_config)
    }
}
</script>

<template>
  <div class="visual-builder-root">
    <template v-for="section in sections" :key="section.id">
      <!-- Dynamic Component Injection -->
      <component
        :is="componentsMap[section.component_type]"
        v-if="componentsMap[section.component_type]"
        :data="section.content_data"
        :config="section.ui_config"
        class="section-wrapper"
        :class="getBackgroundClass(section.ui_config)"
        @vnode-mounted="(vnode) => onSectionMounted(vnode.el, section)"
      />
      <!-- Fallback for unknown components -->
      <div v-else class="p-4 bg-red-100 text-red-600">
        Unknown component: {{ section.component_type }}
      </div>
    </template>
  </div>
</template>
```

### 2. Dumb Components (The Sections)

Each section component should accept `data` and `config` props.

```vue
<!-- components/sections/HeroSection.vue -->
<script setup lang="ts">
defineProps<{
  data: {
    title: string
    subtitle: string
    imageUrl: string
    ctaText: string
  },
  config?: any
}>()
</script>

<template>
  <section class="relative h-screen flex items-center justify-center overflow-hidden">
    <!-- Background -->
    <img 
      v-if="data.imageUrl" 
      :src="data.imageUrl" 
      class="absolute inset-0 w-full h-full object-cover z-0"
    />
    
    <!-- Content -->
    <div class="relative z-10 text-center text-white p-8">
      <h1 class="text-5xl font-bold mb-4">{{ data.title }}</h1>
      <p class="text-xl mb-8">{{ data.subtitle }}</p>
      <button class="bg-primary hover:bg-primary-dark px-6 py-3 rounded-full">
        {{ data.ctaText }}
      </button>
    </div>
  </section>
</template>
```

## Scaling Strategy

1.  **Lazy Loading**: Use `defineAsyncComponent` in the `componentsMap` prevents loading all section JS at once.
2.  **Type Safety**: Create shared TypeScript interfaces for `PageSection` and `UiConfig` (generated from Supabase types).
3.  **HMR (Hot Module Replacement)**: Adding a new section component file requires adding it to the map. For fully dynamic rendering without a map, you'd need global registration, which is less tree-shakeable but easier for CMS-like usage.
