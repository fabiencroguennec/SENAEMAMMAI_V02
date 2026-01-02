<script setup lang="ts">
import SectionEditor from '~/components/admin/SectionEditor.vue'

definePageMeta({
  // middleware: 'auth' // Enable when auth is ready
  layout: 'default'
})

// Define types
interface PageSection {
  id: string
  component_type: string
  order_index: number
  is_visible: boolean
  content_data: {
    title?: string
    description?: string
    admin_label?: string
    [key: string]: any
  }
  ui_config?: any
}

interface Page {
    id: string
    title: string
    slug: string
    seo_title?: string
    seo_description?: string
    is_published: boolean
}

const client = useSupabaseClient()
const route = useRoute()
const toast = useToast()

// Determine current page slug from query or default to 'home'
const currentSlug = computed(() => (route.query.slug as string) || 'home')

// Fetch Page Details
const { data: pageConfig, refresh: refreshPage } = await useAsyncData<Page>(
  () => `admin-page-${currentSlug.value}`,
  async () => {
    const { data } = await client
        .from('pages')
        .select('*')
        .eq('slug', currentSlug.value)
        .single()
    return data as Page
  },
  { watch: [currentSlug] }
)

const { data: sections, refresh } = await useAsyncData<PageSection[]>(
  () => `admin-sections-${currentSlug.value}`, 
  async () => {
  const { data } = await client
    .from('page_sections')
    .select('*')
    .eq('page_slug', currentSlug.value)
    .order('order_index')
  return data as PageSection[]
}, 
{ watch: [currentSlug] } // Re-fetch when slug changes
)

// Accordion State
const expandedSectionId = ref<string | null>(null)

const toggleExpand = (id: string) => {
    if (expandedSectionId.value === id) {
        expandedSectionId.value = null
    } else {
        expandedSectionId.value = id
    }
}

const moveSection = async (section: any, direction: 'up' | 'down') => {
    if (!sections.value) return
    const index = sections.value.findIndex(s => s.id === section.id)
    if (index === -1) return
    
    // Calculate target index
    const siblingIndex = direction === 'up' ? index - 1 : index + 1
    if (siblingIndex < 0 || siblingIndex >= sections.value.length) return

    // 1. Snapshot for rollback
    const originalSections = [...sections.value]
    
    // 2. Optimistic Swap (Local Only)
    const sibling = sections.value[siblingIndex]
    
    // Swap positions in the array
    sections.value[index] = sibling
    sections.value[siblingIndex] = section
    
    // Swap order_index values locally to maintain consistency if verified later
    const tempOrder = section.order_index
    section.order_index = sibling.order_index
    sibling.order_index = tempOrder

    // Force reactivity update for Array mutation
    triggerRef(sections)

    // 3. Persist to DB
    try {
        await client.from('page_sections').upsert([
            { id: section.id, order_index: section.order_index },
            { id: sibling.id, order_index: sibling.order_index }
        ])
    } catch (e) {
        // Revert on error
        console.error('Reordering failed', e)
        sections.value = originalSections
        const toast = useToast()
        toast.add({ title: 'Erreur', description: 'Impossible de déplacer la section.', color: 'red' })
    }
    // No refresh() needed, we are already consistent!
}

const persistVisibility = async (section: any) => {
    // Force reactivity update for deep mutation
    triggerRef(sections)
    
    try {
        await client
            .from('page_sections')
            .update({ is_visible: section.is_visible })
            .eq('id', section.id)
    } catch(e) {
        console.error(e)
        // Revert UI if DB fails
        section.is_visible = !section.is_visible
        triggerRef(sections)
    }
}

// Auto-save for inline edits in the list
const updateSection = async (section: any) => {
    try {
        await client
            .from('page_sections')
            .update({ 
                content_data: section.content_data 
            })
            .eq('id', section.id)
            
        // Optional: Toast or silent save
    } catch (e) {
        console.error('Failed to update section', e)
    }
}

const addSection = async () => {
    try {
        const newOrder = sections.value && sections.value.length > 0 
            ? Math.max(...sections.value.map(s => s.order_index)) + 1 
            : 0

        const { data, error } = await client
            .from('page_sections')
            .insert({
                page_slug: currentSlug.value,
                component_type: 'DynamicSection',
                order_index: newOrder,
                content_data: { title: '', modules: [] },
                is_visible: false // Default to hidden
            })
            .select()
            .single()

        if (error) throw error
        
        // Refresh list
        await refresh()
        if (data) expandedSectionId.value = data.id // Auto expand
        
        const toast = useToast()
        toast.add({ title: 'Section créée', color: 'green' })
    } catch (e: any) {
        const toast = useToast()
        toast.add({ title: 'Erreur', description: e.message, color: 'red' })
    }
}

const removeSection = async (id: string) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette section ? Cette action est irréversible.')) return

    try {
        const { error } = await client
            .from('page_sections')
            .delete()
            .eq('id', id)
        
        if (error) throw error
        
        await refresh()
        const toast = useToast()
        toast.add({ title: 'Section supprimée', color: 'green' })
    } catch (e: any) {
         const toast = useToast()
        toast.add({ title: 'Erreur', description: e.message, color: 'red' })
    }
}

const updatePage = async () => {
    if (!pageConfig.value) return
    try {
        const { error } = await client
            .from('pages')
            .update({
                title: pageConfig.value.title,
                seo_title: pageConfig.value.seo_title,
                seo_description: pageConfig.value.seo_description,
                is_published: pageConfig.value.is_published
            })
            .eq('id', pageConfig.value.id)

        if (error) throw error
        toast.add({ title: 'Page mise à jour', color: 'green' })
    } catch(e: any) {
        toast.add({ title: 'Erreur', description: e.message, color: 'red' })
    }
}
</script>

<template>
  <div class="min-h-screen bg-gray-950 text-gray-100 p-4 md:p-8">
    <div class="max-w-6xl mx-auto">
        


        <UTabs :items="[{ label: 'Sections', icon: 'i-heroicons-squares-plus', slot: 'sections'}, { label: 'Paramètres Page', icon: 'i-heroicons-cog-6-tooth', slot: 'settings' }]" class="w-full">
            
            <!-- TAB: SECTIONS -->
            <template #sections>
                <div class="space-y-4 py-8">
                    <div v-if="!sections || sections.length === 0" class="p-12 text-center text-gray-500 border border-dashed border-gray-800 rounded-xl">
                        <UIcon name="i-heroicons-squares-2x2" class="text-4xl mb-4 opacity-50" />
                        <p>Aucune section. Ajoutez-en via la base de données.</p>
                    </div>
                    
                    <div 
                        v-for="(section, index) in sections" 
                        :key="section.id"
                        class="bg-gray-900 rounded-xl border transition-all duration-300 overflow-hidden"
                        :class="expandedSectionId === section.id ? 'border-primary-500/50 shadow-xl shadow-primary-900/10' : 'border-gray-800 hover:border-gray-700'"
                    >
                        <!-- HEADER (Always Visible) -->
                        <div 
                            class="p-4 flex items-center justify-between cursor-pointer select-none"
                            @click="toggleExpand(section.id)"
                        >
                            <div class="flex items-center gap-4">
                                <!-- Reorder Handles -->
                                <div class="flex flex-col gap-0.5" @click.stop>
                                    <button 
                                        class="text-gray-600 hover:text-white disabled:opacity-20 transition-colors"
                                        :disabled="index === 0"
                                        @click="moveSection(section, 'up')"
                                    >
                                        <UIcon name="i-heroicons-chevron-up" class="w-4 h-4" />
                                    </button>
                                    <button 
                                        class="text-gray-600 hover:text-white disabled:opacity-20 transition-colors"
                                        :disabled="index === sections.length - 1"
                                        @click="moveSection(section, 'down')"
                                    >
                                        <UIcon name="i-heroicons-chevron-down" class="w-4 h-4" />
                                    </button>
                                </div>
                                
                                <!-- Info -->
                                <div class="flex-1 min-w-0 pr-4" @click.stop>
                                    <div class="flex items-center gap-3 mb-1">
                                        <textarea 
                                            v-model="section.content_data.admin_label"
                                            @change="updateSection(section)"
                                            placeholder="Nom de la section (Admin)"
                                            rows="1"
                                            style="field-sizing: content; min-height: 1.5em;"
                                            class="bg-transparent font-bold text-gray-200 text-sm uppercase tracking-wider focus:outline-none focus:text-primary-400 placeholder-gray-700 transition-colors w-full resize-none overflow-hidden"
                                        ></textarea>
                                        <div v-if="!section.is_visible" class="shrink-0 px-1.5 py-0.5 rounded bg-red-500/10 text-red-400 text-[10px] font-bold">CACHÉ</div>
                                    </div>
                                    <input 
                                        v-model="section.content_data.title"
                                        @change="updateSection(section)"
                                        placeholder="Titre affiché sur le site..."
                                        class="bg-transparent text-xs text-gray-500 font-mono focus:outline-none focus:text-gray-300 w-full placeholder-gray-800"
                                    />
                                </div>
                            </div>

                            <div class="flex items-center gap-3">
                                <UToggle 
                                    v-model="section.is_visible" 
                                    @change="persistVisibility(section)"
                                    @click.stop
                                    size="sm"
                                    color="green"
                                    class="mr-2"
                                />
                                
                                <button 
                                    class="text-gray-600 hover:text-red-400 p-1 transition-colors"
                                    @click.stop="removeSection(section.id)"
                                    title="Supprimer la section"
                                >
                                    <UIcon name="i-heroicons-trash" class="w-5 h-5" />
                                </button>
                                
                                <div 
                                    class="w-8 h-8 rounded-full flex items-center justify-center transition-transform duration-300"
                                    :class="expandedSectionId === section.id ? 'rotate-180 bg-gray-800/50 text-white' : 'text-gray-500'"
                                >
                                    <UIcon name="i-heroicons-chevron-down" />
                                </div>
                            </div>
                        </div>

                        <!-- BODY (Expandable Editor) -->
                        <div v-if="expandedSectionId === section.id" class="border-t border-gray-800">
                            <SectionEditor 
                                :section-id="section.id" 
                                @saved="refresh"
                            />
                        </div>
                    </div>
                </div>

                <div class="mt-6">
                    <UButton 
                        block
                        size="xl" 
                        color="gray" 
                        variant="ghost"
                        icon="i-heroicons-plus-circle"
                        class="w-full justify-center py-6 border-2 border-dashed border-gray-800 hover:border-primary-500 hover:text-primary-400 hover:bg-gray-900 transition-all group"
                        @click="addSection"
                    >
                        <span class="group-hover:translate-y-px transition-transform">Ajouter une section</span>
                    </UButton>
                </div>

            </template>
            
            <!-- TAB: SETTINGS -->
            <template #settings>
                 <div class="py-12 max-w-2xl mx-auto space-y-8" v-if="pageConfig">
                     
                     <div class="space-y-4">
                        <UFormGroup label="Titre de la page" help="Le titre affiché dans le menu et en haut de page.">
                            <UInput v-model="pageConfig.title" size="lg" />
                        </UFormGroup>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                             <UFormGroup label="Slug (URL)" help="L'identifiant dans l'URL.">
                                <UInput v-model="pageConfig.slug" disabled color="gray" />
                            </UFormGroup>
                            <UFormGroup label="Statut">
                                <div class="flex items-center justify-between p-2 border border-gray-700 rounded bg-gray-900">
                                    <span class="text-sm font-medium">{{ pageConfig.is_published ? 'Publié' : 'Brouillon' }}</span>
                                    <UToggle v-model="pageConfig.is_published" />
                                </div>
                            </UFormGroup>
                        </div>
                     </div>

                     <div class="space-y-4 pt-8 border-t border-gray-800">
                        <h3 class="text-lg font-bold text-gray-300">Référencement (SEO)</h3>
                        <UFormGroup label="Titre SEO (Meta Title)" help="Si vide, le titre de la page sera utilisé.">
                            <UInput v-model="pageConfig.seo_title" icon="i-heroicons-globe-alt" />
                        </UFormGroup>

                        <UFormGroup label="Description SEO (Meta Description)">
                            <UTextarea v-model="pageConfig.seo_description" rows="3" placeholder="Une courte description pour les moteurs de recherche..." />
                        </UFormGroup>
                     </div>

                     <div class="pt-8">
                         <UButton size="xl" color="primary" block @click="updatePage">
                             Enregistrer les paramètres
                         </UButton>
                     </div>

                     <!-- AI / SEO Preview -->
                     <div class="pt-8 border-t border-gray-800">
                        <div class="flex items-center justify-between mb-4">
                            <h3 class="text-lg font-bold text-gray-300 flex items-center gap-2">
                                <UIcon name="i-heroicons-cpu-chip" class="text-primary-500" />
                                Données Structurées (AI & SEO)
                            </h3>
                            <UBadge color="gray" variant="subtle" size="xs">Généré automatiquement</UBadge>
                        </div>
                        
                        <div class="bg-gray-900 rounded-lg border border-gray-800 p-4 font-mono text-xs text-gray-400 overflow-x-auto">
                            <pre>{{ JSON.stringify(usePageSchema(pageConfig, sections).value, null, 2) }}</pre>
                        </div>
                        <p class="text-xs text-gray-500 mt-2">Ce code JSON-LD est injecté automatiquement dans l'en-tête de la page pour les moteurs de recherche et les assistants AI.</p>
                     </div>

                 </div>
                 <div v-else class="py-12 text-center text-gray-500">
                     Chargement des paramètres...
                 </div>
            </template>

        </UTabs>
    </div>
  </div>
</template>
