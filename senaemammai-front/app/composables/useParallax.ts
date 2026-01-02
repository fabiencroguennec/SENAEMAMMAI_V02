import { gsap } from 'gsap'

// Enhanced Parallax & Scroll Timeline Config
export interface ScrollTimelineState {
    opacity?: number
    blur?: number
    scale?: number
    x?: number
    y?: number
    rotate?: number
    radius?: string // string map to px? or just number
    grayscale?: number
}

export interface ParallaxConfig {
    animation_type: 'none' | 'fade-up' | 'fade-down' | 'fade-in' | 'zoom-in' | 'zoom-out' | 'parallax' | 'scroll-timeline' // Added scroll-timeline
    // Classic props...
    parallax_intensity?: number
    // ...
    duration?: number
    delay?: number
    // Timeline props
    timeline?: {
        enabled: boolean
        start: ScrollTimelineState
        center: ScrollTimelineState
        end: ScrollTimelineState
    }
}

export const useParallax = () => {

    const animateElement = (el: HTMLElement, config: ParallaxConfig) => {
        if (!el || !config) return

        // Cleanup existing triggers (GSAP context recommended but manual kill works for now)
        // Note: In Nuxt context/lifecycle, ideally we use cleanups. 
        // For now we assume overwrite.

        if (config.animation_type === 'none') {
            gsap.set(el, { clearProps: 'all' })
            return
        }

        // ... Existing Standard Animations (fade-up, etc.) ...
        // (Simplified for brevity, keep existing logic or merged)
        const duration = config.duration || 1
        const delay = config.delay || 0

        if (['fade-up', 'fade-down', 'fade-in', 'zoom-in', 'zoom-out'].includes(config.animation_type)) {
            const vars: any = {
                duration: duration,
                delay: delay,
                opacity: 1,
                scale: 1,
                y: 0,
                ease: 'power2.out',
                scrollTrigger: { trigger: el, start: 'top 85%' }
            }

            let fromVars: any = { opacity: 0 }
            if (config.animation_type === 'fade-up') fromVars.y = 50
            if (config.animation_type === 'fade-down') fromVars.y = -50
            if (config.animation_type === 'zoom-in') fromVars.scale = 0.9
            if (config.animation_type === 'zoom-out') fromVars.scale = 1.1

            gsap.fromTo(el, fromVars, vars)
            return
        }

        if (config.animation_type === 'parallax') {
            // ... Keep existing parallax logic ...
            const intensity = config.parallax_intensity !== undefined ? config.parallax_intensity : 0.2
            const tl = gsap.timeline({
                scrollTrigger: {
                    trigger: el,
                    start: 'top bottom',
                    end: 'bottom top',
                    scrub: true
                }
            })
            if (intensity !== 0) tl.to(el, { yPercent: -50 * intensity, ease: 'none' }, 0)
            return
        }

        // NEW: Scroll Timeline Logic
        if (config.animation_type === 'scroll-timeline' && config.timeline?.enabled) {
            const { start, center, end } = config.timeline

            const tl = gsap.timeline({
                scrollTrigger: {
                    trigger: el,
                    start: 'top bottom', // Start animating when entering
                    end: 'bottom top',   // End animating when leaving
                    scrub: true
                }
            })

            // Helper to map visual state to CSS/GSAP vars
            const mapState = (s: ScrollTimelineState) => ({
                opacity: s.opacity ?? 1,
                scale: s.scale ?? 1,
                xPercent: s.x ?? 0,
                yPercent: s.y ?? 0,
                rotation: s.rotate ?? 0,
                filter: `blur(${s.blur ?? 0}px) grayscale(${s.grayscale ?? 0}%)`
            })

            // Phase 1: Start -> Center (0 to 0.5)
            // We set the initial state immediately
            tl.fromTo(el, mapState(start), {
                ...mapState(center),
                ease: 'none',
                duration: 0.5 // Relative to scrub timeline
            }, 0)

            // Phase 2: Center -> End (0.5 to 1)
            tl.to(el, {
                ...mapState(end),
                ease: 'none',
                duration: 0.5
            }, 0.5)
        }
    }

    return { animateElement }
}
