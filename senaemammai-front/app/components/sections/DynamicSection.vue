<script setup lang="ts">
import TextModule from '~/components/modules/TextModule.vue'
import ImageModule from '~/components/modules/ImageModule.vue'
import GridModule from '~/components/modules/GridModule.vue'

const props = defineProps<{
  data: {
    title?: string
    description?: string
    modules?: Array<{
      id: string
      type: 'text' | 'image' | 'grid'
      data: any
      config: any
    }>,
    rows?: Array<{
        id: string
        settings: any
        columns: Array<{
            id: string
            span: number
            modules: Array<any>
        }>
    }>
  },
  config?: any
}>()

const componentsMap: Record<string, any> = {
    'text': TextModule,
    'image': ImageModule,
    'grid': GridModule
}

// Inline styles for Row settings (gap, padding)
const getRowStyle = (row: any) => {
    const s = row.settings || {}
    return {
        paddingTop: s.padding === 'none' ? '0' : s.padding === 'y-12' ? '3rem' : '2rem',
        paddingBottom: s.padding === 'none' ? '0' : s.padding === 'y-12' ? '3rem' : '2rem',
    }
}
const sectionRef = ref<HTMLElement | null>(null)
const bgVideoRef = ref<HTMLVideoElement | null>(null)
const bgImageRef = ref<HTMLElement | null>(null)
const bgWrapperRef = ref<HTMLElement | null>(null)
const moduleRefs = ref<Record<string, HTMLElement>>({})

const setModuleRef = (el: any, id: string) => {
    if (el) moduleRefs.value[id] = el
}

import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { CustomEase } from 'gsap/CustomEase'

gsap.registerPlugin(ScrollTrigger, CustomEase)

// GSAP Context for easy cleanup
let ctx: any = null

const initAnimations = () => {
    // Ensure section exists (Fixes TS 'null' error)
    if (!sectionRef.value) return

    // Clean up previous context
    // Clean up previous context and reset styles
    if (ctx) {
        ctx.revert()
        ctx = null
    }

    // If disabled, stop here.
    if (!props.config) return
    const isContentAnim = props.config.animation_type === 'timeline'
    const isBgAnim = props.config.background_animation_type === 'timeline'
    const isVideoScrub = props.config.background_type === 'video' && props.config.video_scroll_scrub
    const isParallax = props.config.background_type === 'image' && props.config.parallax_intensity > 0

    // Small delay to ensure DOM is ready and styles are reset
    // Then only init if something is enabled
    if (!isContentAnim && !isBgAnim && !isVideoScrub && !isParallax) return
    
    ctx = gsap.context(() => {
        // 1. Video Scroll Scrub
        if (props.config?.background_type === 'video' && props.config?.video_scroll_scrub && bgVideoRef.value) {
            const video = bgVideoRef.value
            
            const setupVideoScrub = () => {
                const sensitivity = props.config.video_scrub_sensitivity || 2
                const duration = video.duration || 10
                
                // Calculate Scroll Distance based on Sensitivity (Speed)
                // Sensitivity 1 = Plays full video over exactly the section visibility duration (Entrance to Exit)
                // Sensitivity < 1 (Slow) = Need MORE scroll to play full video
                // Sensitivity > 1 (Fast) = Need LESS scroll to play full video
                
                // Safety check for sectionRef
                if (!sectionRef.value) return 

                const sectionHeight = sectionRef.value.offsetHeight
                const windowHeight = window.innerHeight
                const naturalDistance = sectionHeight + windowHeight
                
                // Inverse logic: High Sensitivity = Short Distance (Fast)
                const scrollDistance = naturalDistance * (1 / sensitivity)
                
                gsap.fromTo(video, 
                    { currentTime: 0 },
                    {
                        currentTime: duration, // Always try to play full video
                        ease: 'none',
                        scrollTrigger: {
                            trigger: sectionRef.value,
                            start: 'top bottom', // Start when top enters viewport
                            end: `+=${scrollDistance}`, // End after Calculated Distance
                            scrub: true,
                        }
                    }
                )
            }

            if (video.readyState >= 1) setupVideoScrub()
            else video.onloadedmetadata = setupVideoScrub
        }

        // 2. Parallax Image
        if (props.config?.background_type === 'image' && props.config?.parallax_intensity > 0 && bgImageRef.value && sectionRef.value) {
            const intensity = props.config.parallax_intensity * 20
            
            gsap.fromTo(bgImageRef.value,
                { y: `-${intensity/2}px` },
                {
                    y: `${intensity}px`,
                    ease: 'none',
                    scrollTrigger: {
                        trigger: sectionRef.value,
                        start: 'top bottom',
                        end: 'bottom top',
                        scrub: true
                    }
                }
            )
        }

        // 3. New Scroll Timeline Animation
        if (props.config?.animation_type === 'timeline') {
            const tlConfig = props.config?.timeline_config
            console.log('🎬 Init Timeline:', { type: props.config.animation_type, hasConfig: !!tlConfig, config: tlConfig })
            
            if (tlConfig) {
                const steps = tlConfig.steps || {}
                // Determine trigger
                // Determine trigger
                const isScrub = tlConfig.scrub !== false // Default true
                const sensitivity = tlConfig.scrub_sensitivity || 1

                // SCRUB LOGIC OVERRIDE
                // If Scrub is active, we ignore manual triggers and use calculated defaults
                let triggerStart = tlConfig.trigger_start || 'top 80%'
                let triggerEnd = tlConfig.trigger_end || 'bottom 20%'

                if (isScrub) {
                    triggerStart = 'top bottom' // Start when section enters viewport
                    
                    if (sensitivity !== 1 && sectionRef.value) {
                         const h = sectionRef.value.offsetHeight
                         const dist = h / sensitivity
                         triggerEnd = `+=${dist}`
                    } else {
                         // Default Scrub: Play exactly while section is on screen (Top enter -> Bottom leave)
                         triggerEnd = 'bottom top'
                    }
                }

                const isWait = !isScrub && tlConfig.wait_for_end
                
                // --- SCRUB TIMELINE (Split into Entrance & Exit) ---
                if (isScrub) {
                    
                     const getEase = (bezierStr: string) => {
                        if (!bezierStr) return 'none' // Scrub usually works best with linear, but allow override
                         const parts = bezierStr.split(',').map(s => parseFloat(s))
                         if (parts.length === 4) {
                             const path = `M0,0 C${parts[0]},${parts[1]} ${parts[2]},${parts[3]} 1,1`
                             return CustomEase.create("customEase" + Date.now() + Math.random(), path)
                         }
                         return 'none'
                    }

                    // Calculate Distances based on sensitivity
                    // Standard: Entrance (100vh), Exit (Section Height)
                    const viewportH = window.innerHeight
                    const sectionH = sectionRef.value.offsetHeight
                    const distIn = viewportH / sensitivity
                    const distOut = sectionH / sensitivity

                    // 1. Entrance (Start -> Active)
                    // Scroll: Top enters viewport -> Top hits top of viewport
                    if (steps.start) {
                        const tlIn = gsap.timeline({
                            scrollTrigger: {
                                trigger: sectionRef.value,
                                start: 'top bottom', // Start when top enters viewport
                                end: `+=${distIn}`, // End at top-top (if sens=1)
                                scrub: true
                            }
                        })
                        
                        const fromVars: any = { 
                           y: steps.start.y || 0,
                           x: steps.start.x || 0,
                           opacity: steps.start.opacity !== undefined ? steps.start.opacity : 1,
                           scale: steps.start.scale !== undefined ? steps.start.scale : 1,
                           rotation: steps.start.rotate || 0
                        }
                        if (steps.start.blur) fromVars.filter = `blur(${steps.start.blur}px)`

                        const toVars: any = {
                           y: steps.active?.y || 0,
                           x: steps.active?.x || 0,
                           opacity: steps.active?.opacity !== undefined ? steps.active.opacity : 1,
                           scale: steps.active?.scale !== undefined ? steps.active.scale : 1,
                           rotation: steps.active?.rotate || 0,
                           ease: getEase(tlConfig.ease_in)
                        }
                        if (steps.active?.blur !== undefined) toVars.filter = `blur(${steps.active.blur}px)`

                        const contentTarget = sectionRef.value.querySelector('.container') || sectionRef.value
                        tlIn.fromTo(contentTarget, fromVars, toVars)
                    }

                    // 2. Exit (Active -> End)
                    // Scroll: Top hits top of viewport -> Bottom hits top of viewport
                    // Note: We chain the start trigger to "top bottom + distIn" to ensure continuity even with sensitivity
                    if (steps.end && steps.active) {
                         const tlOut = gsap.timeline({
                            scrollTrigger: {
                                trigger: sectionRef.value,
                                // Start exactly where Entrance ends
                                start: `top bottom+=${distIn}`, 
                                end: `+=${distOut}`,
                                scrub: true
                            }
                        })
                        
                        // We assume we are AT active state (visual continuity from tlIn)
                        // But to be safe in GSAP 'fromTo' is handy, OR just 'to' if we trust the state.
                        // 'fromTo' from Active ensures if user jumps scroll, it renders correctly from Active.
                        const startVars: any = {
                           y: steps.active?.y || 0,
                           x: steps.active?.x || 0,
                           opacity: steps.active?.opacity !== undefined ? steps.active.opacity : 1,
                           scale: steps.active?.scale !== undefined ? steps.active.scale : 1,
                           rotation: steps.active?.rotate || 0
                        }
                        if (steps.active?.blur !== undefined) startVars.filter = `blur(${steps.active.blur}px)`

                        const endVars: any = {
                          y: steps.end.y || 0,
                          x: steps.end.x || 0,
                          opacity: steps.end.opacity !== undefined ? steps.end.opacity : 1,
                          scale: steps.end.scale !== undefined ? steps.end.scale : 1,
                          rotation: steps.end.rotate || 0,
                          ease: getEase(tlConfig.ease_out)
                        }
                        if (steps.end.blur !== undefined) endVars.filter = `blur(${steps.end.blur}px)`
                        
                        const contentTarget = sectionRef.value.querySelector('.container') || sectionRef.value
                        tlOut.fromTo(contentTarget, startVars, endVars)
                    }

                } else if (!isWait) {
                    // --- NON-SCRUB SEQUENTIAL (Original) ---
                    const tl = gsap.timeline({
                        scrollTrigger: {
                            trigger: sectionRef.value,
                            start: triggerStart,
                            end: triggerEnd,
                            toggleActions: 'play reverse play reverse',
                            once: tlConfig.once_in,
                            fastScrollEnd: true
                        }
                    })
                    
                    // ... (Original Non-Scrub Logic helper)
                     const getEase = (bezierStr: string) => {
                        if (!bezierStr) return 'power2.out'
                         const parts = bezierStr.split(',').map(s => parseFloat(s))
                         if (parts.length === 4) {
                             const path = `M0,0 C${parts[0]},${parts[1]} ${parts[2]},${parts[3]} 1,1`
                             return CustomEase.create("customEase" + Date.now() + Math.random(), path)
                         }
                         return 'power2.out'
                    }

                    // 1. Entrance
                    if (steps.start) {
                       const fromVars: any = { 
                          y: steps.start.y || 0,
                          x: steps.start.x || 0,
                          opacity: steps.start.opacity !== undefined ? steps.start.opacity : 1,
                          scale: steps.start.scale !== undefined ? steps.start.scale : 1,
                          rotation: steps.start.rotate || 0
                       }
                       if (steps.start.blur) fromVars.filter = `blur(${steps.start.blur}px)`

                       const toVars: any = {
                          y: steps.active?.y || 0,
                          x: steps.active?.x || 0,
                          opacity: steps.active?.opacity !== undefined ? steps.active.opacity : 1,
                          scale: steps.active?.scale !== undefined ? steps.active.scale : 1,
                          rotation: steps.active?.rotate || 0,
                          duration: tlConfig.duration || 1,
                          ease: getEase(tlConfig.ease_in)
                      }
                      if (steps.active?.blur !== undefined) toVars.filter = `blur(${steps.active.blur}px)`

                       const contentTarget = sectionRef.value.querySelector('.container') || sectionRef.value
                       tl.fromTo(contentTarget, fromVars, toVars)
                    }

                    // 2. Exit
                    if (steps.end && steps.active) {
                        const endVars: any = {
                          y: steps.end.y || 0,
                          x: steps.end.x || 0,
                          opacity: steps.end.opacity !== undefined ? steps.end.opacity : 1,
                          scale: steps.end.scale !== undefined ? steps.end.scale : 1,
                          rotation: steps.end.rotate || 0,
                          duration: tlConfig.duration_out || tlConfig.duration || 1,
                          ease: getEase(tlConfig.ease_out)
                        }
                        if (steps.end.blur !== undefined) endVars.filter = `blur(${steps.end.blur}px)`
                        
                        const contentTarget = sectionRef.value.querySelector('.container') || sectionRef.value
                        tl.to(contentTarget, endVars)
                    }

                } else {
                    // --- SPLIT TIMELINE ("Wait for End") ---
                    // Timeline 1: Start -> Active (Trigger Start)
                    const contentTarget = sectionRef.value.querySelector('.container') || sectionRef.value
                    
                    // Helper reused
                    const getEaseInOut = (bezierStr: string) => {
                         if (!bezierStr) return 'power2.out'
                         const parts = bezierStr.split(',').map(s => parseFloat(s))
                         if (parts.length === 4) {
                             const path = `M0,0 C${parts[0]},${parts[1]} ${parts[2]},${parts[3]} 1,1`
                             return CustomEase.create("customEase" + Date.now() + Math.random(), path)
                         }
                         return 'power2.out'
                    }

                    if (steps.start) {
                        const tlIn = gsap.timeline({
                            scrollTrigger: {
                                trigger: sectionRef.value,
                                start: triggerStart,
                                toggleActions: tlConfig.once_in ? 'play none none none' : 'play reverse play reverse',
                                fastScrollEnd: true // Safety
                            }
                        })
                        
                        const fromVars: any = { 
                           y: steps.start.y || 0,
                           x: steps.start.x || 0,
                           opacity: steps.start.opacity !== undefined ? steps.start.opacity : 1,
                           scale: steps.start.scale !== undefined ? steps.start.scale : 1,
                           rotation: steps.start.rotate || 0
                        }
                        if (steps.start.blur) fromVars.filter = `blur(${steps.start.blur}px)`

                        const toVars: any = {
                           y: steps.active?.y || 0,
                           x: steps.active?.x || 0,
                           opacity: steps.active?.opacity !== undefined ? steps.active.opacity : 1,
                           scale: steps.active?.scale !== undefined ? steps.active.scale : 1,
                           rotation: steps.active?.rotate || 0,
                           duration: tlConfig.duration || 1,
                           ease: getEaseInOut(tlConfig.ease_in)
                        }
                        if (steps.active?.blur !== undefined) toVars.filter = `blur(${steps.active.blur}px)`

                        tlIn.fromTo(contentTarget, fromVars, toVars)
                    }

                    // Timeline 2: Active -> End (Trigger End)
                    if (steps.end && steps.active) {
                         const tlOut = gsap.timeline({
                            scrollTrigger: {
                                trigger: sectionRef.value,
                                start: triggerEnd, // Wait for END trigger to start exit
                                toggleActions: tlConfig.once_out ? 'play none none none' : 'play reverse play reverse'
                            }
                        })
                        
                        const endVars: any = {
                          y: steps.end.y || 0,
                          x: steps.end.x || 0,
                          opacity: steps.end.opacity !== undefined ? steps.end.opacity : 1,
                          scale: steps.end.scale !== undefined ? steps.end.scale : 1,
                          rotation: steps.end.rotate || 0,
                          duration: tlConfig.duration_out || tlConfig.duration || 1,
                          ease: getEaseInOut(tlConfig.ease_out)
                        }
                        if (steps.end.blur !== undefined) endVars.filter = `blur(${steps.end.blur}px)`
                        
                        // Just .to() because we assume we are at Active state from previous timeline
                        tlOut.to(contentTarget, endVars)
                    }
                }
            }
        }
        
        // 4. Background Timeline Animation
        if (props.config?.background_animation_type === 'timeline' && bgWrapperRef.value) {
             const bgTlConfig = props.config?.background_timeline_config
             if (bgTlConfig) {
                const steps = bgTlConfig.steps || {}
                const triggerStart = bgTlConfig.trigger_start || 'top 90%'
                let triggerEnd = bgTlConfig.trigger_end || 'bottom 10%'
                const isScrub = bgTlConfig.scrub !== false
                const sensitivity = bgTlConfig.scrub_sensitivity || 1

                if (isScrub && sensitivity !== 1 && sectionRef.value) {
                    const h = sectionRef.value.offsetHeight
                    const dist = h / sensitivity
                    triggerEnd = `+=${dist}`
                }

                const tl = gsap.timeline({
                    scrollTrigger: {
                        trigger: sectionRef.value, // Trigger is always the section itself
                        start: triggerStart,
                        end: triggerEnd,
                        scrub: isScrub ? 1 : false,
                        toggleActions: !isScrub ? 'play reverse play reverse' : undefined
                    }
                })

                // 1. Entrance (Start -> Active)
                if (steps.start) {
                    const fromVars: any = { 
                        y: steps.start.y || 0,
                        x: steps.start.x || 0,
                        opacity: steps.start.opacity !== undefined ? steps.start.opacity : 1,
                        scale: steps.start.scale !== undefined ? steps.start.scale : 1,
                        rotation: steps.start.rotate || 0
                    }
                    if (steps.start.blur) fromVars.filter = `blur(${steps.start.blur}px)`

                    const toVars: any = {
                        y: steps.active?.y || 0,
                        x: steps.active?.x || 0,
                        opacity: steps.active?.opacity !== undefined ? steps.active.opacity : 1,
                        scale: steps.active?.scale !== undefined ? steps.active.scale : 1,
                        rotation: steps.active?.rotate || 0,
                        ease: 'none'
                    }
                    if (steps.active?.blur !== undefined) toVars.filter = `blur(${steps.active.blur}px)`
                    
                    // Target the background wrapper
                    tl.fromTo(bgWrapperRef.value, fromVars, toVars)
                }

                // 2. Exit (Active -> End)
                if (steps.end && steps.active) {
                    const endVars: any = {
                        y: steps.end.y || 0,
                        x: steps.end.x || 0,
                        opacity: steps.end.opacity !== undefined ? steps.end.opacity : 1,
                        scale: steps.end.scale !== undefined ? steps.end.scale : 1,
                        rotation: steps.end.rotate || 0,
                        ease: 'none'
                    }
                    if (steps.end.blur !== undefined) endVars.filter = `blur(${steps.end.blur}px)`

                    tl.to(bgWrapperRef.value, endVars)
                }
             }
        }

        // 5. Per-Module Animations
        // Iterate through all tracked module refs
        Object.entries(moduleRefs.value).forEach(([id, el]) => {
            // Find the module config in data
            let module: any = null
            
            // Search in Rows
            if (props.data.rows) {
                for (const row of props.data.rows) {
                    for (const col of row.columns) {
                        const found = col.modules.find((m: any) => m.id === id)
                        if (found) module = found
                    }
                }
            }
            // Search in Flat List
            if (!module && props.data.modules) {
                 module = props.data.modules.find((m: any) => m.id === id)
            }

            if (module && module.config?.animation_type === 'timeline' && module.config?.timeline_config) {
                 const tlConfig = module.config.timeline_config
                 const steps = tlConfig.steps || {}
                 const triggerStart = tlConfig.trigger_start || 'top 85%'
                 let triggerEnd = tlConfig.trigger_end || 'bottom 20%'
                 const isScrub = tlConfig.scrub !== false
                 const sensitivity = tlConfig.scrub_sensitivity || 1

                 if (isScrub && sensitivity !== 1) {
                    const h = el.offsetHeight
                    const dist = h / sensitivity
                    triggerEnd = `+=${dist}`
                 }

                 const tl = gsap.timeline({
                    scrollTrigger: {
                        trigger: el, // Trigger is the module element itself
                        start: triggerStart,
                        end: triggerEnd,
                        scrub: isScrub ? 1 : false,
                        toggleActions: !isScrub ? 'play reverse play reverse' : undefined
                    }
                 })

                 // Same Animation Logic as Section Content
                 // 1. Entrance (Start -> Active)
                if (steps.start) {
                    const fromVars: any = { 
                        y: steps.start.y || 0,
                        x: steps.start.x || 0,
                        opacity: steps.start.opacity !== undefined ? steps.start.opacity : 1,
                        scale: steps.start.scale !== undefined ? steps.start.scale : 1,
                        rotation: steps.start.rotate || 0
                    }
                    if (steps.start.blur) fromVars.filter = `blur(${steps.start.blur}px)`

                    const toVars: any = {
                        y: steps.active?.y || 0,
                        x: steps.active?.x || 0,
                        opacity: steps.active?.opacity !== undefined ? steps.active.opacity : 1,
                        scale: steps.active?.scale !== undefined ? steps.active.scale : 1,
                        rotation: steps.active?.rotate || 0,
                        ease: 'none'
                    }
                    if (steps.active?.blur !== undefined) toVars.filter = `blur(${steps.active.blur}px)`
                    
                    tl.fromTo(el, fromVars, toVars)
                }

                // 2. Exit (Active -> End)
                if (steps.end && steps.active) {
                    const endVars: any = {
                        y: steps.end.y || 0,
                        x: steps.end.x || 0,
                        opacity: steps.end.opacity !== undefined ? steps.end.opacity : 1,
                        scale: steps.end.scale !== undefined ? steps.end.scale : 1,
                        rotation: steps.end.rotate || 0,
                        ease: 'none'
                    }
                    if (steps.end.blur !== undefined) endVars.filter = `blur(${steps.end.blur}px)`

                    tl.to(el, endVars)
                }
            }
        })

    }, sectionRef.value) // Scope to section
}

// Watch for everything that affects animations
watch(
    [
        () => props.config, 
        () => props.config?.video_scroll_scrub, 
        () => props.config?.video_scrub_sensitivity,
        bgVideoRef,
        bgImageRef
    ], 
    () => {
        // Debounce slightly to ensure DOM is ready
        // Re-run initAnimations whenever config changes
        setTimeout(() => initAnimations(), 50)
    },
    { deep: true, immediate: true }
)

onUnmounted(() => {
    if (ctx) ctx.revert()
})

// Styles
const sectionStyle = computed(() => {
    // 1. Solid Color
    if (props.config?.background_type === 'color') {
        return { backgroundColor: props.config.background_color?.replace('bg-', '') } 
    }
    
    // 2. Mesh Gradient
    if (props.config?.background_type === 'gradient' && props.config?.gradient_config) {
        try {
            const val = typeof props.config.gradient_config === 'string' 
                ? JSON.parse(props.config.gradient_config) 
                : props.config.gradient_config
            
            if (val.type === 'gradient' && val.gradient_stops) {
                 const stops = val.gradient_stops.map((stop: any) => {
                    return `radial-gradient(circle at ${stop.x}% ${stop.y}%, ${stop.color} 0%, transparent 50%)`
                }).join(', ')
                
                return {
                    backgroundColor: '#000000',
                    backgroundImage: stops
                }
            }
        } catch (e) {
            console.error('Invalid gradient config', e)
        }
    }
    
    return {}
})
</script>

<template>
  <section 
    ref="sectionRef"
    class="dynamic-section relative w-full overflow-hidden py-12 md:py-24"
  >
      <!-- BACKGROUNDS -->
      <!-- Wrapper: Always render to allow textures/overlays on top of CSS background-color -->
      <div ref="bgWrapperRef" class="absolute inset-0 z-0 overflow-hidden pointer-events-none">
          
          <!-- BASE BACKGROUND (Color / Gradient) -->
          <!-- Moved here so it animates with the timeline -->
          <div 
            class="absolute inset-0 w-full h-full"
            :class="[
                config?.background_type === 'color' && config?.background_color?.startsWith('bg-') ? config.background_color : ''
            ]"
            :style="sectionStyle"
          ></div>

          <!-- IMAGE -->
          <div 
             v-if="config?.background_type === 'image' && config?.background_value"
             ref="bgImageRef"
             class="absolute inset-0 w-full h-[120%] -top-[10%]"
          >
              <img 
                :src="config.background_value" 
                class="w-full h-full object-cover" 
                alt="Section Background" 
             />
          </div>

          <!-- VIDEO -->
          <div v-if="config?.background_type === 'video' && config?.background_value" class="absolute inset-0 w-full h-full">
            <video 
                ref="bgVideoRef"
                class="w-full h-full object-cover"
                :autoplay="!config.video_scroll_scrub"
                :loop="!config.video_scroll_scrub"
                muted
                playsinline
                :src="config.background_value"
            ></video>
          </div>

          <!-- OVERLAYS (Common to all types) -->
          <!-- Texture -->
          <div v-if="config?.overlay_texture && config.overlay_texture !== 'none'" class="absolute inset-0 z-[1] opacity-30" 
              :class="{
                  'bg-dots': config.overlay_texture === 'dots',
                  'bg-grid': config.overlay_texture === 'grid',
                  'bg-noise': config.overlay_texture === 'noise'
              }"
          ></div>
          
          <!-- Opacity / Dimmer -->
          <div class="absolute inset-0 z-[2] bg-black transition-opacity duration-300" :style="{ opacity: config?.overlay_opacity || 0 }"></div>
      </div>

      <div class="container mx-auto px-4 relative z-10">
          
          <!-- Section Header -->
          <div v-if="data.title || data.description" class="mb-12 md:mb-16">
              <h2 v-if="data.title" class="text-3xl md:text-4xl lg:text-5xl font-bold mb-4 text-gray-900 dark:text-white uppercase tracking-tight">
                  {{ data.title }}
              </h2>
              <p v-if="data.description" class="text-lg text-gray-600 dark:text-gray-400 max-w-3xl leading-relaxed">
                  {{ data.description }}
              </p>
          </div>

          <!-- NEW: Layout Rows (Grid System) -->
          <div v-if="data.rows && data.rows.length > 0" class="flex flex-col gap-0">
              <div v-for="row in data.rows" :key="row.id" :style="getRowStyle(row)">
                   <div class="grid grid-cols-12 gap-4 md:gap-8 lg:gap-12" :class="row.settings?.gap === '0' ? '!gap-0' : ''">
                       <div 
                            v-for="col in row.columns" 
                            :key="col.id" 
                            class="flex flex-col gap-8"
                            :style="{ gridColumn: `span ${col.span} / span ${col.span}` }"
                        >
                            <template v-for="module in col.modules" :key="module.id">
                                <div :ref="(el) => setModuleRef(el, module.id)">
                                    <component 
                                        :is="componentsMap[module.type]"
                                        v-if="componentsMap[module.type]"
                                        :data="module.data"
                                        :config="module.config"
                                    />
                                </div>
                            </template>
                       </div>
                   </div>
              </div>
          </div>

          <!-- LEGACY: Flat Modules List -->
          <div v-else-if="data.modules && data.modules.length > 0" class="flex flex-col gap-8 md:gap-16">
               <template v-for="module in data.modules" :key="module.id">
                   <div :ref="(el) => setModuleRef(el, module.id)" class="w-full">
                       <component 
                           :is="componentsMap[module.type]"
                           v-if="componentsMap[module.type]"
                           :data="module.data"
                           :config="module.config"
                       />
                   </div>
               </template>
          </div>
          <div v-else class="text-center text-gray-500 py-12 border-2 border-dashed border-gray-700/30 rounded-lg">
              <p>Section vide. Ajoutez des modules via l'admin.</p>
          </div>
      </div>
  </section>
</template>
