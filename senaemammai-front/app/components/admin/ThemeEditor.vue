<script setup lang="ts">
import { watchDebounced } from '@vueuse/core'
import { googleFonts, getGoogleFontUrl } from '~/utils/fonts'

const client = useSupabaseClient()
const toast = useToast()

// Data Fetching
const { data: theme, refresh } = await useAsyncData('site-appearance', async () => {
    const { data } = await client
        .from('site_appearance')
        .select('*')
        .eq('site_slug', 'main')
        .single()
    return data
})

const form = reactive({
    colors: {
        primary: '#3b82f6',
        secondary: '#64748b',
        background: '#020617',
        text: '#f8fafc',
        accent: '#f59e0b'
    } as any,
    typography: {
        h1: { size: '3rem', weight: '700', family: 'Inter' },
        h2: { size: '2.25rem', weight: '600', family: 'Inter' },
        h3: { size: '1.5rem', weight: '600', family: 'Inter' },
        p: { size: '1rem', weight: '400', family: 'Inter' },
        font_heading: 'Inter',
        font_body: 'Inter'
    } as any
})

// Init
watchEffect(() => {
    if (theme.value) {
        if (theme.value.colors) form.colors = { ...form.colors, ...theme.value.colors }
        if (theme.value.typography) form.typography = { ...form.typography, ...theme.value.typography }
    }
})

// Dynamic Font Loading for Preview
useHead(() => {
    const fontsToLoad = new Set([
        form.typography.font_heading,
        form.typography.font_body,
        form.typography.h1?.family,
        form.typography.h2?.family,
        form.typography.h3?.family,
        form.typography.p?.family
    ])
    
    // Filter out undefined and standard fonts if needed, but getGoogleFontUrl handles basic names
    const links = Array.from(fontsToLoad)
        .filter(f => f && googleFonts.some(gf => gf.name === f))
        .map(f => ({
            rel: 'stylesheet',
            href: getGoogleFontUrl(googleFonts.find(gf => gf.name === f)?.value || '')
        }))
    
    return { link: links as any }
})

// Save Logic
const isSaving = ref(false)

const save = async () => {
    isSaving.value = true
    try {
        // Prepare data
        const payload = {
            site_slug: 'main', // Ensure ID match
            colors: form.colors,
            typography: form.typography,
            updated_at: new Date()
        }

        const { error } = await client
            .from('site_appearance')
            .upsert(payload, { onConflict: 'site_slug' })
        
        if (error) throw error
        
        // Broadcast Update for hydration
        const bc = new BroadcastChannel('theme-updates')
        bc.postMessage('refresh-theme')
        
        toast.add({ title: 'Thème sauvegardé', color: 'green', timeout: 1000 })
    } catch (e: any) {
        console.error(e)
        toast.add({ title: 'Erreur', description: e.message, color: 'red' })
    } finally {
        isSaving.value = false
    }
}

// Auto-save
watchDebounced(form, () => save(), { debounce: 1500, deep: true })

// Preview State
const activePreview = ref<'h1' | 'h2' | 'h3' | 'p'>('h1')
</script>

<template>
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        
        <!-- LEFT COLUMNS: CONTROLS -->
        <div class="lg:col-span-2 space-y-8">
            
            <!-- COLORS -->
            <div class="space-y-6 bg-gray-900/50 p-6 rounded-xl border border-gray-800">
                <h3 class="text-xl font-bold text-white flex items-center gap-2 border-b border-gray-800 pb-2">
                    <UIcon name="i-heroicons-swatch" class="text-primary-500" />
                    Couleurs
                </h3>
                
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div v-for="(color, key) in form.colors" :key="key" class="bg-gray-800 p-3 rounded-lg border border-gray-700 flex items-center justify-between group hover:border-gray-600 transition-colors">
                        <div>
                            <label class="block text-sm font-bold text-gray-300 capitalize mb-0.5">{{ key }}</label>
                            <span class="text-[10px] text-gray-500 font-mono bg-gray-900 px-1 py-0.5 rounded">{{ form.colors[key] }}</span>
                        </div>
                        <div class="relative w-10 h-10 flex-shrink-0 overflow-hidden rounded-full border border-gray-600 shadow-inner">
                             <input 
                                type="color" 
                                v-model="form.colors[key]"
                                class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10 scale-150"
                             />
                             <div class="w-full h-full" :style="{ backgroundColor: form.colors[key] }"></div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- TYPOGRAPHY GLOBAL -->
            <div class="space-y-6 bg-gray-900/50 p-6 rounded-xl border border-gray-800">
                 <h3 class="text-xl font-bold text-white flex items-center gap-2 border-b border-gray-800 pb-2">
                    <UIcon name="i-heroicons-globe-alt" class="text-primary-500" />
                    Familles de polices (Google Fonts)
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <UFormGroup label="Titres (Headings)" help="Pour h1, h2, h3">
                         <USelect 
                            v-model="form.typography.font_heading"
                            :options="googleFonts"
                            option-attribute="name"
                            value-attribute="name"
                            searchable
                            placeholder="Choisir une police..."
                         />
                    </UFormGroup>
                     <UFormGroup label="Corps (Body)" help="Pour le texte standard">
                         <USelect 
                            v-model="form.typography.font_body"
                            :options="googleFonts"
                            option-attribute="name"
                            value-attribute="name"
                            searchable
                            placeholder="Choisir une police..."
                         />
                    </UFormGroup>
                </div>
            </div>

            <!-- TYPOGRAPHY DETAILS -->
            <div class="space-y-6 bg-gray-900/50 p-6 rounded-xl border border-gray-800">
                <h3 class="text-xl font-bold text-white flex items-center gap-2 border-b border-gray-800 pb-2">
                    <UIcon name="i-heroicons-adjustments-horizontal" class="text-primary-500" />
                    Détails Typographie
                </h3>

                <div class="space-y-4">
                    <div 
                        v-for="tag in ['h1', 'h2', 'h3', 'p']" 
                        :key="tag" 
                        class="bg-gray-800 p-4 rounded-lg border border-gray-700 transition-all cursor-pointer"
                        :class="activePreview === tag ? 'ring-2 ring-primary-500 border-transparent bg-gray-800' : 'hover:border-gray-500'"
                        @click="activePreview = tag"
                    >
                        <div class="flex flex-col md:flex-row md:items-center gap-4">
                            <span class="text-lg font-bold text-gray-400 w-12 text-center uppercase bg-gray-900 rounded py-1">{{ tag }}</span>
                            
                            <div class="grid grid-cols-2 md:grid-cols-3 gap-2 flex-1">
                                <UFormGroup label="Taille" size="xs">
                                     <UInput v-if="form.typography[tag]" v-model="form.typography[tag].size" size="xs" placeholder="3rem" />
                                </UFormGroup>
                                <UFormGroup label="Graisse" size="xs">
                                     <USelect 
                                        v-if="form.typography[tag]" 
                                        v-model="form.typography[tag].weight"
                                        :options="['100', '300', '400', '500', '600', '700', '900']" 
                                        size="xs" 
                                    />
                                </UFormGroup>
                                <!-- Font Override (Optional) -->
                                <UFormGroup label="Police (Optionnel)" size="xs" class="col-span-2 md:col-span-1">
                                    <USelect 
                                        v-if="form.typography[tag]"
                                        v-model="form.typography[tag].family"
                                        :options="[{name: 'Défaut (Global)', value: undefined}, ...googleFonts.map(f => ({name: f.name, value: f.name}))]"
                                        option-attribute="name"
                                        value-attribute="value"
                                        size="xs"
                                        placeholder="Hériter"
                                     />
                                 </UFormGroup>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- RIGHT COLUMN: PREVIEW -->
        <div class="lg:col-span-1 sticky top-24">
            <div class="bg-white rounded-xl overflow-hidden shadow-2xl border border-gray-700">
                <div class="bg-gray-100 border-b border-gray-200 p-3 flex items-center justify-between">
                    <span class="text-xs font-bold text-gray-500 uppercase tracking-wider flex items-center gap-2">
                        <UIcon name="i-heroicons-eye" /> Aperçu en direct
                    </span>
                    <span class="px-2 py-0.5 bg-primary-100 text-primary-700 rounded text-[10px] font-bold uppercase">{{ activePreview }}</span>
                </div>
                
                <div 
                    class="p-8 min-h-[400px] flex flex-col justify-center transition-colors duration-500"
                    :style="{ backgroundColor: form.colors.background, color: form.colors.text }"
                >
                    <!-- Simulated Content -->
                    <div class="space-y-6">
                        <component 
                            :is="activePreview"
                            class="transition-all duration-300"
                            :style="{
                                fontSize: form.typography[activePreview]?.size,
                                fontWeight: form.typography[activePreview]?.weight,
                                fontFamily: googleFonts.find(f => f.name === (form.typography[activePreview]?.family || (activePreview === 'p' ? form.typography.font_body : form.typography.font_heading)))?.value || 'inherit',
                                color: activePreview.startsWith('h') ? form.colors.primary : form.colors.text
                            }"
                        >
                            {{ activePreview === 'p' ? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.' : 'The Quick Brown Fox' }}
                        </component>
                        
                        <div class="opacity-50 text-xs border-t border-dashed border-current pt-4 mt-8">
                             <p class="font-mono mb-2">Variables CSS générées :</p>
                             <ul class="space-y-1">
                                 <li>--color-primary: {{ form.colors.primary }}</li>
                                 <li>--font-heading: {{ form.typography.font_heading }}</li>
                                 <li>{{ activePreview }}: {{ form.typography[activePreview]?.size }}</li>
                             </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </div>
</template>
