<script setup lang="ts">
import { googleFonts, getGoogleFontUrl } from '~/utils/fonts'

// Global SEO & JSON-LD Configuration
useHead({
  templateParams: {
    siteName: 'SENA E MAMMAI',
    separator: '|'
  },
  titleTemplate: '%s %separator %siteName',
})

useSchemaOrg([
  defineOrganization({
    name: 'SENA E MAMMAI',
    logo: '/logo.png',
    sameAs: [
      'https://instagram.com/senaemammai' 
    ]
  }),
  defineWebSite({
    name: 'SENA E MAMMAI',
  }),
  defineWebPage(),
])

// --- GLOBAL THEME INJECTION ---
const client = useSupabaseClient()
const { data: theme } = await useAsyncData('global-theme', async () => {
    const { data } = await client.from('site_appearance').select('*').eq('site_slug', 'main').single()
    return data
})

// React to Broadcast Channel from Admin
onMounted(() => {
    const bc = new BroadcastChannel('theme-updates')
    bc.onmessage = () => { refreshNuxtData('global-theme') }
})

// Computed Styles
const themeStyles = computed(() => {
    if (!theme.value) return ''
    const c = theme.value.colors || {}
    const t = theme.value.typography || {}
    
    // Resolve font families
    const fontHeading = googleFonts.find(f => f.name === t.font_heading)?.value || 'Inter, sans-serif'
    const fontBody = googleFonts.find(f => f.name === t.font_body)?.value || 'Inter, sans-serif'

    return `
      :root {
        --color-primary-500: ${c.primary || '#3b82f6'};
        --color-bg-950: ${c.background || '#020617'};
        --font-heading: ${fontHeading};
        --font-body: ${fontBody};
      }
      body {
        background-color: var(--color-bg-950);
        font-family: var(--font-body);
        color: ${c.text || '#f8fafc'};
      }
      h1, h2, h3, h4, h5, h6 {
        font-family: var(--font-heading);
        color: ${c.primary || '#ffffff'};
      }
      h1 { font-size: ${t.h1?.size || '3rem'}; font-weight: ${t.h1?.weight || '700'}; }
      h2 { font-size: ${t.h2?.size || '2.25rem'}; font-weight: ${t.h2?.weight || '600'}; }
      h3 { font-size: ${t.h3?.size || '1.5rem'}; font-weight: ${t.h3?.weight || '600'}; }
      p { font-size: ${t.p?.size || '1rem'}; font-weight: ${t.p?.weight || '400'}; }
    `
})

// Inject Fonts & CSS Variables
useHead(() => {
    const t = theme.value?.typography || {}
    const fontsToLoad = new Set([t.font_heading, t.font_body])
    
    const links = Array.from(fontsToLoad)
        .filter(f => f && googleFonts.some(gf => gf.name === f))
        .map(f => ({
            rel: 'stylesheet',
            href: getGoogleFontUrl(googleFonts.find(gf => gf.name === f)?.value || '')
        }))
        
    return {
        link: links as any,
        style: [
            { children: themeStyles.value }
        ]
    }
})
</script>

<template>
  <div>
    <NuxtRouteAnnouncer />
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </div>
</template>
