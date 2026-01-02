// nuxt.config.ts
export default defineNuxtConfig({
  modules: [
    '@nuxt/image',
    '@nuxt/ui',
    '@nuxtjs/supabase',
    'nuxt-schema-org'
  ],
  site: {
    url: 'https://senaemammai.com',
    name: 'SENA E MAMMAI',
    description: 'Artisanat et Créations Uniques',
    defaultLocale: 'fr',
  },
  image: {
    domains: ['images.unsplash.com']
  },
  supabase: {
    redirect: false, // Set to true later if you want strictly protected routes by default
  },
  // We don't need a specific module for GSAP, we can import it directly in components.
  css: ['~/assets/css/main.css'],
  compatibilityDate: '2025-12-21',
  devServer: {
    port: 3001,
    host: '0.0.0.0'
  },
  ssr: true,

})