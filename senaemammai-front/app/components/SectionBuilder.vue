<script setup lang="ts">
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import DynamicSection from './sections/DynamicSection.vue'

// Register GSAP Plugin
if (import.meta.client) {
  gsap.registerPlugin(ScrollTrigger)
}

// Component Map (All sections are Dynamic now)
const componentsMap: Record<string, any> = {
  DynamicSection,
  // Mapping legacy types to DynamicSection to prevent crash, 
  // though they might look empty if data structure differs.
  HeroSection: DynamicSection,
  ProductGrid: DynamicSection
}

const props = withDefaults(defineProps<{
  pageSlug?: string
}>(), {
  pageSlug: 'home'
})

// Fetch Data (Bypassing Nuxt Cache)
const client = useSupabaseClient()
const sections = ref<any[]>([])
const loading = ref(true)

const fetchSections = async () => {
    loading.value = true
    try {
        const { data, error } = await client
            .from('page_sections')
            .select(`
            *,
            ui_config (*)
            `)
            .eq('page_slug', props.pageSlug)
            .eq('is_visible', true)
            .order('order_index')
        
        if (error) throw error
        sections.value = data || []
        console.log('✅ Sections refreshed:', sections.value.length)
    } catch (e) {
        console.error('Error fetching sections:', e)
    } finally {
        loading.value = false
    }
}

// Watch for slug changes (Navigation)
watch(() => props.pageSlug, () => {
    fetchSections()
})

// Realtime Subscription & Cache Handling
onMounted(() => {
    // 1. Initial Fetch
    fetchSections()

    // 2. BroadcastChannel for instant local updates (Tab-to-Tab)
    const bc = new BroadcastChannel('app-updates')
    bc.onmessage = (event) => {
        if (event.data === 'refresh-sections') {
            console.log('⚡️ Received Broadcast Update request')
            fetchSections()
        }
    }

    // 3. Supabase Realtime (Server-to-Client)
    console.log('🔌 Subscribing to Supabase Realtime...')
    const channel = client.channel('public:page_sections')
        .on(
            'postgres_changes',
            { event: '*', schema: 'public', table: 'page_sections' },
            (payload) => {
                console.log('⚡️ Realtime Change detected (page_sections):', payload)
                fetchSections()
            }
        )
        .on(
            'postgres_changes',
            { event: '*', schema: 'public', table: 'ui_config' },
            (payload) => {
                console.log('⚡️ Realtime Change detected (ui_config):', payload)
                fetchSections()
            }
        )
        .subscribe((status) => {
            console.log('📡 Realtime Status:', status)
        })

    onUnmounted(() => {
        client.removeChannel(channel)
        bc.close()
    })
})

// Helper for Background Classes
const getBackgroundClass = (config: any) => {
    if (!config) return ''
    // If it looks like a tailwind class (e.g. bg-red-500), return it.
    // Otherwise handle custom logic or hex codes via style binding instead.
    if (config.background_color && config.background_color.startsWith('bg-')) {
        return config.background_color
    }
    return ''
}

// Helper for Inline Styles (Hex colors)
const getContainerStyle = (config: any) => {
    if (!config) return {}
    const style: any = {}
    if (config.background_color && !config.background_color.startsWith('bg-')) {
        style.backgroundColor = config.background_color
    }
    return style
}

// Animation Logic
const animateSection = (el: HTMLElement, config: any) => {
  if (!config || !el) return

  // 1. VIDEO SCROLL SCRUBBING
  if (config.video_scroll_scrub && config.background_type === 'video') {
      const video = el.querySelector('video.scrub-enabled') as HTMLVideoElement
      if (video) {
        // Wait for metadata to know duration
        const setupVideoScroll = () => {
             if (!video.duration) return
             gsap.timeline({
                 scrollTrigger: {
                     trigger: el,
                     start: 'top bottom',
                     end: 'bottom top',
                     scrub: true
                 }
             })
             .fromTo(video, 
                { currentTime: 0 }, 
                { currentTime: video.duration, ease: 'none' }
             )
        }

        if (video.readyState >= 1) {
            setupVideoScroll()
        } else {
            video.addEventListener('loadedmetadata', setupVideoScroll)
        }
      }
  }

  // Kill existing triggers to prevent duplicates on re-render
  // ScrollTrigger.getAll().forEach(t => t.kill()) // Careful, this kills ALL triggers

  if (config.animation_type === 'fade-up') {
      gsap.fromTo(el, 
        { y: 100, opacity: 0 },
        {
            y: 0,
            opacity: 1,
            duration: config.animation_speed || 1,
            ease: 'power2.out',
            scrollTrigger: {
                trigger: el,
                start: 'top 80%',
            }
        }
      )
  } else if (config.animation_type === 'parallax') {
       // Advanced Parallax
       const intensity = config.parallax_intensity !== undefined ? config.parallax_intensity : 0.2
       const scaleStart = config.parallax_scale_start !== undefined ? config.parallax_scale_start : 1
       const scaleEnd = config.parallax_scale_end !== undefined ? config.parallax_scale_end : 1
       const opacityMin = config.parallax_opacity_min !== undefined ? config.parallax_opacity_min : 1
       
       // Set initial state
       if (scaleStart !== 1) gsap.set(el, { scale: scaleStart })
       
       const tl = gsap.timeline({
         scrollTrigger: {
           trigger: el,
           start: 'top bottom', // Start when top of element hits bottom of viewport
           end: 'bottom top',   // End when bottom of element hits top of viewport
           scrub: true
         }
       })

       // 1. Y-Axis Parallax
       if (intensity !== 0) {
           tl.to(el, {
             yPercent: -50 * intensity, // Range from -50% to 50% height based on intensity
             ease: 'none'
           }, 0)
       }

       // 2. Scale Parallax
       if (scaleStart !== scaleEnd) {
           tl.fromTo(el, 
             { scale: scaleStart },
             { scale: scaleEnd, ease: 'none' }, 
             0
           )
       }

       // 3. Opacity Parallax (Fade out on scroll or fade in?)
       // Logic: Usually we want full opacity in center. 
       // For now, let's implement simple linear fade if requested.
       if (opacityMin < 1) {
            tl.fromTo(el,
                { opacity: opacityMin },
                { opacity: 1, ease: 'power1.inOut', duration: 0.5 }, // Fade in
                0
            ).to(el,
                { opacity: opacityMin, ease: 'power1.inOut', duration: 0.5 }, // Fade out
                0.5 // Start halfway
            )
       }
  }
}

const onSectionMounted = (el: Element, section: any) => {
    // We cast to HTMLElement safely
    const domEl = el as HTMLElement
    // Apply UI Config Animations
    if (section.ui_config) { 
      const config = resolveConfig(section)
      animateSection(domEl, config)
    }
}

const resolveConfig = (section: any) => {
    if (!section || !section.ui_config) return {}
    return Array.isArray(section.ui_config) ? section.ui_config[0] : section.ui_config
}

const getOverlayOpacity = (config: any) => {
    if (!config) return 1
    // If transparent, force 0 opacity
    if (config.background_color === 'bg-transparent') return 0
    
    if (config.overlay_opacity !== undefined && config.overlay_opacity !== null) {
        return config.overlay_opacity
    }
    // Smart Default
    if (config.background_type === 'image' || config.background_type === 'video') {
        return 0.5
    }
    return 1
}
</script>

<template>
  <div class="visual-builder-root w-full">
    <template v-if="sections && sections.length > 0">
        <template v-for="section in sections" :key="section.id">
        <!-- Logic: If component exists -->
        <template v-if="componentsMap[section.component_type]">
                 <div class="relative w-full section-container group/debug">
                     <!-- Background Layer -->
                     <div class="absolute inset-0 z-0 overflow-hidden pointer-events-none">
                         
                         <!-- Media Background -->
                         <template v-if="resolveConfig(section)?.background_type === 'image'">
                             <img 
                                :src="resolveConfig(section)?.background_value" 
                                class="w-full h-full object-cover"
                             />
                         </template>
                         <template v-else-if="resolveConfig(section)?.background_type === 'video'">
                             <video 
                                :muted="true"
                                :autoplay="!resolveConfig(section)?.video_scroll_scrub"
                                :loop="!resolveConfig(section)?.video_scroll_scrub"
                                playsinline
                                class="w-full h-full object-cover video-background"
                                :class="{ 'scrub-enabled': resolveConfig(section)?.video_scroll_scrub }"
                                :src="resolveConfig(section)?.background_value"
                             />
                         </template>
                         
                         <!-- Overlay Color/Gradient -->
                         <div 
                             class="absolute inset-0"
                             :class="getBackgroundClass(resolveConfig(section))"
                             :style="{
                                 ...getContainerStyle(resolveConfig(section)),
                                 opacity: getOverlayOpacity(resolveConfig(section))
                             }"
                         ></div>

                         <!-- Texture Overlay -->
                         <div 
                            v-if="resolveConfig(section)?.overlay_texture && resolveConfig(section)?.overlay_texture !== 'none'"
                            class="absolute inset-0 mix-blend-overlay opacity-30 pointer-events-none"
                            :class="`texture-${resolveConfig(section)?.overlay_texture}`"
                         ></div>
                     </div>
 
                     <!-- Content Layer -->
                     <div class="relative z-10 w-full">
                        <component
                            :is="componentsMap[section.component_type]"
                            :data="section.content_data"
                            :config="resolveConfig(section)"
                            class="section-wrapper w-full transition-all duration-300"
                            @vue:mounted="(vnode: any) => onSectionMounted(vnode.el, section)"
                        />

                     </div>
                </div>
        </template>
        
        <!-- Logic: Else (Fallback) -->
        <template v-else>
            <div class="p-12 text-center bg-gray-100 text-gray-500 border-2 border-dashed border-gray-300 m-4 rounded">
                <p class="font-mono text-sm">Unknown Component: <span class="font-bold text-gray-700">{{ section.component_type }}</span></p>
                <p class="text-xs mt-2">Check database `page_sections.component_type` vs `componentsMap`.</p>
            </div>
        </template>
        </template>
    </template>
    
    <!-- Empty State -->
    <div v-else class="min-h-screen flex items-center justify-center bg-gray-50">
        <div class="text-center">
            <h2 class="text-2xl font-bold text-gray-700 mb-2">Aucune section trouvée</h2>
            <p class="text-gray-500 mb-4">Ajoutez des entrées dans la table <code>page_sections</code> de Supabase.</p>
        </div>
    </div>
    
  </div>
</template>

<style scoped>
/* Textures */
.texture-noise {
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)' opacity='0.5'/%3E%3C/svg%3E");
}
.texture-dots {
    background-image: radial-gradient(#000 1px, transparent 1px);
    background-size: 20px 20px;
}
.texture-grid {
    background-image: linear-gradient(#000 1px, transparent 1px), linear-gradient(90deg, #000 1px, transparent 1px);
    background-size: 40px 40px;
}
.texture-lines {
    background: repeating-linear-gradient(45deg, #000, #000 2px, transparent 2px, transparent 10px);
}
</style>
