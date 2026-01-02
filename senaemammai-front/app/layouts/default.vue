<script setup lang="ts">
const isOpen = ref(false)
const { isBackendMode } = useBackendMode()
const router = useRouter()

const client = useSupabaseClient()

const siteUrl = ref('/')
onMounted(() => {
    siteUrl.value = window.location.origin
})

// Fetch pages for the menu
const { data: menuPages } = await useAsyncData('menu-pages', async () => {
    const { data } = await client
        .from('pages')
        .select('title, slug')
        .eq('is_published', true)
        .order('order_index')
    return data || []
})

const links = computed(() => {
    if (isBackendMode.value) {
        return [
            { label: 'Pages (Structure)', to: '/admin/pages', icon: 'i-heroicons-document-duplicate' },
            { label: 'Éditeur de Contenu', to: '/admin/editor', icon: 'i-heroicons-pencil-square' },
            { label: 'Apparence', to: '/admin/appearance', icon: 'i-heroicons-paint-brush' },
            { label: 'Médiathèque', to: '/admin/media', icon: 'i-heroicons-photo' },
            { label: 'Paramètres', to: '/admin/settings', icon: 'i-heroicons-cog-6-tooth' },
        ]
    }
    
    // Frontend Links (Dynamic)
    const dynamicLinks = (menuPages.value || []).map(p => ({
        label: p.title,
        to: p.slug === 'home' ? '/' : `/${p.slug}`,
        icon: 'i-heroicons-document-text' // Default icon for dynamic pages
    }))

    // Ensure Home is first if not present or just prepended (removing duplicates if necessary)
    // For simplicity, let's assume DB drives the menu, but if DB is empty, show defaults.
    if (dynamicLinks.length === 0) {
         return [
            { label: 'Accueil', to: '/', icon: 'i-heroicons-home' },
            { label: 'À propos', to: '/about', icon: 'i-heroicons-information-circle' },
        ]
    }

    return dynamicLinks
})

// Redirect to admin pages if mode is switched to true and we are on front
watch(isBackendMode, (newVal) => {
    if (newVal) {
        // If enabling backend mode, go to pages list if not already in admin
        if (!router.currentRoute.value.path.startsWith('/admin')) {
             router.push('/admin/pages')
        }
    } else {
        // If disabling, go home
        router.push('/')
    }
})
</script>

<template>
  <div class="min-h-screen bg-gray-50 text-gray-900 dark:bg-gray-900 dark:text-gray-100 flex flex-col">
    <!-- Header -->
    <header class="sticky top-0 z-50 bg-white/80 dark:bg-gray-900/80 backdrop-blur border-b border-gray-200 dark:border-gray-800">
      <div class="container mx-auto px-4 h-16 flex items-center justify-between">
        <!-- Logo -->
        <NuxtLink to="/" class="text-xl font-bold tracking-tight flex items-center gap-2">
            SENAEMAMMAI
            <UBadge v-if="isBackendMode" label="BACKEND" color="primary" variant="subtle" size="xs" />
        </NuxtLink>

        <!-- Hamburger Button -->
        <UButton 
          color="gray" 
          variant="ghost" 
          icon="i-heroicons-bars-3" 
          size="xl"
          @click="isOpen = true"
        />
      </div>
    </header>

    <!-- Slideover Menu -->
    <USlideover v-model="isOpen">
      <div class="p-6 flex flex-col h-full bg-white dark:bg-gray-900">
        <div class="flex items-center justify-between mb-8">
            <h2 class="text-2xl font-bold">{{ isBackendMode ? 'Menu Backend' : 'Menu' }}</h2>
            <div class="flex items-center gap-2">
                <UButton 
                    v-if="isBackendMode"
                    color="gray" 
                    variant="ghost" 
                    icon="i-heroicons-arrow-top-right-on-square" 
                    size="lg"
                    :to="siteUrl"
                    target="_blank"
                    tooltip="Voir le site"
                />
                <UButton 
                    color="gray" 
                    variant="ghost" 
                    icon="i-heroicons-x-mark" 
                    size="lg"
                    @click="isOpen = false"
                />
            </div>
        </div>

        <nav class="flex-1 space-y-2">
            <UButton
                v-for="link in links"
                :key="link.to"
                :to="link.to"
                block
                color="gray"
                variant="ghost"
                size="xl"
                class="justify-start nav-item"
                :icon="link.icon"
                active-class="bg-primary-50 text-primary-600 dark:bg-primary-900/10 dark:text-primary-400"
                @click="isOpen = false"
            >
                {{ link.label }}
            </UButton>
        </nav>

        <!-- Footer / Admin Toggle -->
        <div class="pt-6 border-t border-gray-200 dark:border-gray-800">
            <div class="flex items-center justify-between bg-gray-100 dark:bg-gray-800 p-4 rounded-xl">
                <div class="flex flex-col">
                    <span class="text-sm font-bold">Mode Édition</span>
                    <span class="text-xs text-gray-500">Accès Backend</span>
                </div>
                <UToggle v-model="isBackendMode" size="lg" />
            </div>
        </div>
      </div>
    </USlideover>

    <!-- Main Content -->
    <main class="flex-1">
      <slot />
    </main>
  </div>
</template>


