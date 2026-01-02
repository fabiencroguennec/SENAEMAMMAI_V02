<script setup lang="ts">
import ContentForm from '~/components/admin/ContentForm.vue'
import AdminImageUploader from '~/components/admin/ImageUploader.vue'
import { watchDebounced } from '@vueuse/core'

const route = useRoute()
const router = useRouter()
const client = useSupabaseClient()
const toast = useToast()

const sectionId = route.params.id as string

// Fetch Section + Config
const { data: section, refresh } = await useAsyncData(`section-${sectionId}`, async () => {
  const { data } = await client
    .from('page_sections')
    .select(`*, ui_config (*)`)
    .eq('id', sectionId)
    .single()
  return data
})

// Local State
const form = reactive({
    content_data: {} as any,
    ui_config: {} as any
})

// Initialize form on load
watchEffect(() => {
    if (section.value) {
        form.content_data = section.value.content_data || {}
        
        // Handle array vs object for ui_config relation
        const config = Array.isArray(section.value.ui_config) ? section.value.ui_config[0] : section.value.ui_config
        
        // If config doesn't exist, init empty
        form.ui_config = config ? { ...config } : {}
        
        // Validation: Ensure defaults
        if (!form.ui_config.background_color) form.ui_config.background_color = 'bg-white'
    }
})

// Auto-save logic
const isSaving = ref(false)
const lastSaved = ref<Date | null>(null)

const save = async (silent = false) => {
    isSaving.value = true
    try {
        // 1. Update Section Content
        const { error: secError } = await client
            .from('page_sections')
            .update({ content_data: form.content_data })
            .eq('id', sectionId)
        
        if (secError) throw secError

        // 2. Update/Upsert UI Config (Idempotent)
        // Ensure we have a config object
        const configData = {
           ...form.ui_config,
           section_id: sectionId
        }
        delete configData.created_at
        delete configData.id

        // Upsert based on section_id unique constraint
        const { error: confError } = await client
            .from('ui_config')
            .upsert(configData, { onConflict: 'section_id' })

        if (confError) throw confError

        // Broadcast local update event
        const bc = new BroadcastChannel('app-updates')
        bc.postMessage('refresh-sections')
        bc.close()
        
        lastSaved.value = new Date()
        if (!silent) toast.add({ title: 'Sauvegardé', color: 'green', timeout: 1000 })
    } catch (e: any) {
        toast.add({ title: 'Erreur', description: e.message, color: 'red' })
    } finally {
        isSaving.value = false
    }
}

// Watch for changes (Debounce 1000ms)
watchDebounced(
    form,
    () => { save(true) },
    { debounce: 1000, deep: true }
)

const handleImageAutoUpdate = (url: string) => {
    // Smartly assign the image URL to the content
    form.content_data.imageUrl = url
    toast.add({ title: 'Image ajoutée', description: 'Le champ imageUrl a été rempli.', color: 'green' })
}

const tabs = [
    { label: 'Contenu', icon: 'i-heroicons-document-text', slot: 'content' },
    { label: 'Apparence', icon: 'i-heroicons-paint-brush', slot: 'design' },
    { label: 'Avancé (JSON)', icon: 'i-heroicons-code-bracket', slot: 'json' }
]
</script>

<template>
  <div class="min-h-screen bg-gray-950 text-gray-100 flex flex-col">
      <!-- Top Bar -->
      <div v-if="section" class="border-b border-gray-800 bg-gray-900 px-6 py-4 flex items-center justify-between sticky top-0 z-50">
           <div class="flex items-center gap-4">
                <UButton to="/admin" color="gray" variant="ghost" icon="i-heroicons-arrow-left">Retour</UButton>
                <div>
                     <h1 class="text-xl font-bold text-white flex items-center gap-2">
                        <span class="px-2 py-0.5 rounded bg-primary-500/20 text-primary-400 text-xs uppercase tracking-widest">{{ section.component_type }}</span>
                        <span class="text-gray-400 text-sm font-normal">#{{ section.id }}</span>
                     </h1>
                </div>
            </div>
            
            <div class="flex items-center gap-6">
                 <!-- Save Status -->
                 <div v-if="isSaving" class="flex items-center gap-2 text-primary-400 text-xs font-medium uppercase tracking-wider">
                    <UIcon name="i-heroicons-arrow-path" class="animate-spin" />
                    Sauvegarde...
                </div>
                <div v-else-if="lastSaved" class="text-xs text-gray-500 flex items-center gap-1 font-medium uppercase tracking-wider">
                    <UIcon name="i-heroicons-check" class="text-green-500" />
                    Synchro {{ lastSaved.toLocaleTimeString() }}
                </div>

                <div class="h-6 w-px bg-gray-800"></div>

                <UButton size="sm" color="white" variant="solid" icon="i-heroicons-eye" to="/" target="_blank">
                    Voir le site
                </UButton>
            </div>
      </div>

      <!-- Main Content -->
      <div v-if="section" class="flex-1 container mx-auto p-6 max-w-5xl">
        
        <UTabs :items="tabs" class="w-full" :ui="{ list: { background: 'bg-gray-900', tab: { active: 'bg-primary-500 text-white' } } }">
            
            <!-- CONTENU TAB -->
            <template #content="{ item }">
                <div class="space-y-6 pt-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
                    
                    <!-- Image Uploader Access -->
                    <div class="bg-gray-900 rounded-lg p-4 border border-gray-800 flex items-center justify-between">
                         <div class="flex items-center gap-3">
                            <div class="bg-gray-800 p-2 rounded-full">
                                <UIcon name="i-heroicons-photo" class="text-xl text-gray-400" />
                            </div>
                            <div>
                                <h3 class="text-sm font-bold text-gray-200">Médiathèque</h3>
                                <p class="text-xs text-gray-500">Uploader une nouvelle image pour cette section</p>
                            </div>
                         </div>
                         <div class="w-64">
                              <AdminImageUploader @uploaded="handleImageAutoUpdate" />
                         </div>
                    </div>

                    <!-- Smart Form -->
                    <div class="bg-gray-900 rounded-xl p-8 border border-gray-800 shadow-xl">
                        <ContentForm 
                            v-model="form.content_data" 
                            :component-type="section.component_type" 
                        />
                    </div>
                </div>
            </template>

            <!-- APPARENCE TAB -->
            <template #design="{ item }">
                 <div class="grid grid-cols-1 md:grid-cols-2 gap-8 pt-6">
                    
                    <!-- Colors -->
                    <div class="bg-gray-900 p-6 rounded-xl border border-gray-800">
                        <h3 class="text-sm font-bold text-gray-400 uppercase tracking-widest mb-4">Fond & Couleurs</h3>
                        <div class="space-y-4">
                             <label class="text-sm text-gray-300">Couleur d'arrière-plan</label>
                             <div class="grid grid-cols-5 gap-3">
                                <button 
                                    v-for="color in [
                                        { class: 'bg-white', label: 'Blanc' },
                                        { class: 'bg-gray-50', label: 'Gris Très Clair' },
                                        { class: 'bg-gray-100', label: 'Gris Clair' },
                                        { class: 'bg-gray-900', label: 'Sombre' },
                                        { class: 'bg-gray-950', label: 'Très Sombre' },
                                        { class: 'bg-primary-50', label: 'Accent Clair' },
                                        { class: 'bg-primary-900', label: 'Accent Sombre' },
                                        { class: 'bg-stone-50', label: 'Pierre' },
                                        { class: 'bg-amber-50', label: 'Chaud' },
                                        { class: 'transparent', label: 'Transparent' }
                                    ]" 
                                    :key="color.class"
                                    @click="form.ui_config.background_color = color.class"
                                    class="w-8 h-8 rounded-full border border-gray-600 hover:scale-110 transition-transform relative"
                                    :class="[
                                        color.class === 'transparent' ? 'bg-transparent border-dashed' : color.class,
                                        form.ui_config.background_color === color.class ? 'ring-2 ring-primary-500 ring-offset-2 ring-offset-gray-900' : ''
                                    ]"
                                    :title="color.label"
                                >
                                </button>
                             </div>
                             
                             <div class="pt-4 border-t border-gray-800">
                                 <label class="text-sm text-gray-300">Opacité image de fond (Overlay)</label>
                                 <p class="text-xs text-gray-500 italic mt-1">Nécessite le support du composant</p>
                             </div>
                        </div>
                    </div>

                    <!-- Animations -->
                    <div class="bg-gray-900 p-6 rounded-xl border border-gray-800">
                        <h3 class="text-sm font-bold text-gray-400 uppercase tracking-widest mb-4">Animations</h3>
                        <UFormGroup label="Effet d'apparition" class="mb-4">
                            <div class="grid grid-cols-3 gap-2">
                                <button 
                                    v-for="anim in ['none', 'fade-up', 'zoom-in']" 
                                    :key="anim"
                                    @click="form.ui_config.animation_type = anim"
                                    class="px-3 py-2 text-xs rounded border border-gray-700 hover:bg-gray-800 transition-colors capitalize"
                                    :class="form.ui_config.animation_type === anim ? 'bg-primary-900 border-primary-500 text-white' : 'text-gray-400'"
                                >
                                    {{ anim }}
                                </button>
                            </div>
                        </UFormGroup>
                        
                        <UFormGroup label="Effet Parallax (Scroll)" class="mb-4">
                             <div class="flex items-center justify-between bg-gray-800 p-2 rounded border border-gray-700 cursor-pointer"
                                  @click="form.ui_config.animation_type = (form.ui_config.animation_type === 'parallax' ? 'none' : 'parallax')"
                             >
                                <span class="text-sm text-gray-300">Activer Parallax</span>
                                <UToggle :model-value="form.ui_config.animation_type === 'parallax'" />
                             </div>
                        </UFormGroup>

                        <div v-if="form.ui_config.animation_type === 'parallax' || form.ui_config.animation_type === 'fade-up'" class="mt-4">
                             <UFormGroup label="Intensité / Vitesse">
                                <URange v-model.number="form.ui_config.animation_speed" :min="0.5" :max="2" :step="0.1" />
                             </UFormGroup>
                        </div>
                    </div>

                 </div>
            </template>

            <!-- JSON TAB -->
            <template #json="{ item }">
                 <div class="bg-gray-900 p-4 rounded-xl border border-gray-800 mt-6 font-mono text-xs">
                     <p class="mb-4 text-orange-400">⚠️ Zone Expert : Modification directe des données brutes.</p>
                     <div class="grid grid-cols-2 gap-4 h-[500px]">
                        <div class="flex flex-col">
                            <label class="mb-2 text-gray-500">Content Data</label>
                            <UTextarea 
                                :model-value="JSON.stringify(form.content_data, null, 2)"
                                @update:model-value="(v) => { try { form.content_data = JSON.parse(v) } catch(e){} }"
                                class="flex-1 bg-gray-950 font-mono"
                                :rows="20"
                            />
                        </div>
                         <div class="flex flex-col">
                            <label class="mb-2 text-gray-500">UI Config</label>
                            <UTextarea 
                                :model-value="JSON.stringify(form.ui_config, null, 2)"
                                @update:model-value="(v) => { try { form.ui_config = JSON.parse(v) } catch(e){} }"
                                class="flex-1 bg-gray-950 font-mono"
                                :rows="20"
                            />
                        </div>
                     </div>
                 </div>
            </template>
        </UTabs>
        
      </div>
      
      <div v-else class="flex justify-center pt-20 h-screen items-center">
          <UIcon name="i-heroicons-arrow-path" class="animate-spin text-4xl text-primary-500" />
      </div>
  </div>
</template>
