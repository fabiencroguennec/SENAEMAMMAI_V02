<script setup lang="ts">
import ContentForm from '~/components/admin/ContentForm.vue'
import ModuleEditor from '~/components/admin/ModuleEditor.vue'
import LayoutBuilder from '~/components/admin/layout/LayoutBuilder.vue'
import AdminImageUploader from '~/components/admin/ImageUploader.vue'
import GradientBuilder from '~/components/admin/GradientBuilder.vue'
import AnimationTimelineEditor from '~/components/admin/AnimationTimelineEditor.vue'
import { watchDebounced } from '@vueuse/core'

const props = defineProps<{
    sectionId: string
}>()

const emit = defineEmits(['saved'])

const client = useSupabaseClient()
const toast = useToast()

// Define types
interface PageSection {
  id: string
  component_type: string
  content_data: any
  ui_config: any
}

// Fetch Section + Config
const { data: section, refresh } = await useAsyncData<PageSection | null>(`section-edit-${props.sectionId}`, async () => {
  const { data } = await client
    .from('page_sections')
    .select(`*, ui_config (*)`)
    .eq('id', props.sectionId)
    .single()
  return data as PageSection | null
})

// Local State
const form = reactive({
    content_data: {} as any,
    ui_config: {} as any
})

// Initialize form on load
watch(
    () => section.value?.id, // Only watch ID changes!
    (newId, oldId) => {
        if (!newId) return
        if (newId === oldId) return // Same ID, ignore
        
        // Full Init for new section
        const newVal = section.value
        if (!newVal) return

        console.log('🔄 Init Form for Section:', newId)
        form.content_data = newVal.content_data || {}
        
        // Config init
        const config = Array.isArray(newVal.ui_config) ? newVal.ui_config[0] : newVal.ui_config
        form.ui_config = config ? { ...config } : {}
        
        // Default to dark
        if (!form.ui_config.background_color) form.ui_config.background_color = 'bg-gray-950'
    },
    { immediate: true }
)

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
            .eq('id', props.sectionId)
        
        if (secError) throw secError

        // 2. Update/Upsert UI Config (Idempotent)
        const configData = {
           ...form.ui_config,
           section_id: props.sectionId
        }
        delete configData.created_at
        
        // If we have an ID, keep it to update that specific row. 
        // If not, remove it so Postgres generates a new one.
        if (!configData.id) delete configData.id
        
        console.log('💾 Saving UI Config:', configData)

        const { data: savedConfig, error: confError } = await client
            .from('ui_config')
            .upsert(configData, { onConflict: 'section_id' })
            .select() // Return the saved row to update local ID
            .single()
        
        if (confError) throw confError
        
        // Update local form ID and CACHE to avoid data loss on remouunt
        if (savedConfig) {
            form.ui_config.id = savedConfig.id
            
            // Critical: Update the cached 'section' object so useAsyncData doesn't return stale null config on next mount
            if (section.value) {
                // Handle the 1:1 or 1:many nature of the structure
                if (Array.isArray(section.value.ui_config)) {
                    section.value.ui_config = [savedConfig]
                } else {
                    section.value.ui_config = savedConfig
                }
            }
        }

        // Broadcast local update event
        const bc = new BroadcastChannel('app-updates')
        bc.postMessage('refresh-sections')
        // bc.close() - Keep open to ensure delivery
        
        lastSaved.value = new Date()
        emit('saved')
        
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
    form.content_data.imageUrl = url
    toast.add({ title: 'Image ajoutée', description: 'Le champ imageUrl a été rempli.', color: 'green' })
}

// Helper for Inline Styles (Hex colors) - Duplicated from SectionBuilder (should be shared later)
const getContainerStyle = (config: any) => {
    if (!config) return {}
    const style: any = {}
    if (config.background_color && !config.background_color.startsWith('bg-')) {
        style.backgroundColor = config.background_color
    }
    return style
}

const tabs = [
    { label: 'Contenu', icon: 'i-heroicons-document-text', slot: 'content' },
    { label: 'Arrière-plan', icon: 'i-heroicons-photo', slot: 'background' },
    { label: 'Animation', icon: 'i-heroicons-film', slot: 'animation' }
]

// Gradient Helper Logic
const getGradientState = (config: any) => {
    if (config.background_type === 'gradient' && config.gradient_config) {
        // Now using proper JSONB column, no need to parse if it's already an object
        // But handle potential string if coming from raw query without typing
        return typeof config.gradient_config === 'string' 
            ? JSON.parse(config.gradient_config) 
            : config.gradient_config
    }
    // Default fallback to solid
    return {
        type: 'solid',
        color: config.background_color || '#000000',
        gradient_stops: [
             { id: 1, x: 20, y: 30, color: '#4f46e5' },
             { id: 2, x: 80, y: 70, color: '#e11d48' }
        ]
    }
}

const updateGradientState = (config: any, val: any) => {
    if (val.type === 'solid') {
        config.background_type = 'color'
        config.background_color = val.color
        // config.gradient_config = null // Optional: clear it
    } else {
        config.background_type = 'gradient'
        config.gradient_config = val // Store object directly
    }
}

// Ensure Timeline Config exists if type is timeline
watch(() => form.ui_config.animation_type, (val) => {
    if (val === 'timeline' && !form.ui_config.timeline_config) {
        console.log('✨ Initializing empty content timeline config')
        form.ui_config.timeline_config = {
             trigger_start: "top 80%",
             trigger_end: "bottom 20%",
             scrub: true,
             steps: {
                 start: { y: 100, opacity: 0, scale: 1 },
                 active: { y: 0, opacity: 1, scale: 1 },
                 end: { y: -100, opacity: 0, scale: 1 }
             }
        }
    }
})

// Ensure Background Timeline Config exists
watch(() => form.ui_config.background_animation_type, (val) => {
    if (val === 'timeline' && !form.ui_config.background_timeline_config) {
        console.log('✨ Initializing empty background timeline config')
        form.ui_config.background_timeline_config = {
             trigger_start: "top 90%",
             trigger_end: "bottom 10%",
             scrub: true,
             steps: {
                 start: { y: 0, opacity: 1, scale: 1.1 }, // Example: slight zoom
                 active: { y: 0, opacity: 1, scale: 1 },
                 end: { y: 0, opacity: 1, scale: 1 }
             }
        }
    }
})
</script>

<template>
  <div class="bg-gray-900/50 rounded-b-xl border-t border-gray-800">
      
      <!-- Save Status Bar (Mini) -->
      <div class="flex justify-end px-4 py-2 border-b border-gray-800 bg-gray-900/30">
          <div v-if="isSaving" class="flex items-center gap-2 text-primary-400 text-xs font-medium uppercase tracking-wider">
                <UIcon name="i-heroicons-arrow-path" class="animate-spin" />
                Sauvegarde...
            </div>
            <div v-else-if="lastSaved" class="text-xs text-gray-500 flex items-center gap-1 font-medium uppercase tracking-wider">
                <UIcon name="i-heroicons-check" class="text-green-500" />
                Synchro {{ lastSaved.toLocaleTimeString() }}
            </div>
            <div v-else class="text-xs text-gray-600 italic">
                Modifiez pour sauvegarder
            </div>
      </div>

      <div v-if="section" class="p-6">
        <UTabs :items="tabs" class="w-full" :ui="{ list: { background: 'bg-gray-900', tab: { active: 'bg-primary-500 text-white' } } }">
            
            <!-- CONTENU TAB -->
            <template #content="{ item }">
                <div class="space-y-6 pt-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
                    
                    <!-- Image Uploader Helper (Only for Fixed Sections) -->
                    <div v-if="section.component_type !== 'DynamicSection'" class="bg-gray-800/50 rounded-lg p-4 border border-gray-700/50 flex items-center justify-between">
                         <div class="flex items-center gap-3">
                            <UIcon name="i-heroicons-photo" class="text-xl text-gray-400" />
                            <div class="text-xs text-gray-400">
                                glisser-déposez une image ici
                            </div>
                         </div>
                         <div class="w-48">
                              <AdminImageUploader @uploaded="handleImageAutoUpdate" />
                         </div>
                    </div>

                    <!-- SECTION HEADER (Title & Description) -->
                    <!-- Hidden for Dynamic Section as requested -->
                    <div v-if="section.component_type !== 'DynamicSection'" class="pb-6 border-b border-gray-800 space-y-2">
                        <input 
                            v-model="form.content_data.title"
                            type="text"
                            placeholder="Titre de la section..."
                            class="w-full bg-transparent text-3xl font-bold text-white placeholder-gray-800 focus:outline-none focus:placeholder-gray-700 transition-colors"
                        />
                        <textarea 
                            v-model="form.content_data.description"
                            placeholder="Une courte description pour cette section..."
                            :rows="1"
                            class="w-full bg-transparent text-gray-500 text-sm focus:outline-none focus:text-gray-300 transition-colors resize-none field-sizing-content"
                            style="field-sizing: content;" 
                        ></textarea>
                    </div>

                    <!-- DYNAMIC EDITOR vs FIXED FORM -->
                    <div v-if="section.component_type === 'DynamicSection'">
                        <!-- Ensure content_data is initialized -->
                        <LayoutBuilder 
                             :model-value="form.content_data"
                             @update:model-value="(v) => form.content_data = v"
                        />
                    </div>
                    <div v-else>
                         <ContentForm 
                            v-model="form.content_data" 
                            :component-type="section.component_type" 
                        />
                    </div>
                </div>
            </template>

            <!-- ATMOSPHERE (Background) TAB -->
            <template #background="{ item }">
                <div class="space-y-6 pt-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
                    
                    <!-- Background Type Selector -->
                    <UFormGroup label="Type d'arrière-plan">
                         <div class="grid grid-cols-3 gap-3">
                             <UButton 
                                :color="form.ui_config.background_type === 'color' ? 'primary' : 'gray'"
                                variant="soft"
                                icon="i-heroicons-swatch" 
                                label="Couleur"
                                @click="form.ui_config.background_type = 'color'" 
                             />
                             <UButton 
                                :color="form.ui_config.background_type === 'image' ? 'primary' : 'gray'" 
                                variant="soft"
                                icon="i-heroicons-photo" 
                                label="Image"
                                @click="form.ui_config.background_type = 'image'" 
                             />
                             <UButton 
                                :color="form.ui_config.background_type === 'video' ? 'primary' : 'gray'" 
                                variant="soft"
                                icon="i-heroicons-film" 
                                label="Vidéo"
                                @click="form.ui_config.background_type = 'video'" 
                             />
                         </div>
                    </UFormGroup>
            
                    <!-- Color/Gradient Settings -->
                    <div v-if="form.ui_config.background_type === 'color' || form.ui_config.background_type === 'gradient'" class="space-y-4 bg-gray-900 p-4 rounded-xl border border-gray-800">
                        <GradientBuilder 
                            :model-value="getGradientState(form.ui_config)"
                            @update:model-value="(v) => updateGradientState(form.ui_config, v)"
                        />
                    </div>
            
                    <!-- Image Settings -->
                    <div v-if="form.ui_config.background_type === 'image'" class="space-y-4 bg-gray-900 p-4 rounded-xl border border-gray-800">
                         <UFormGroup label="Image Source">
                             <AdminImageUploader mini @uploaded="(url) => form.ui_config.background_value = url" />
                             <img v-if="form.ui_config.background_value" :src="form.ui_config.background_value" class="mt-4 h-64 w-full rounded-lg object-contain bg-black border border-gray-700" />
                         </UFormGroup>
                         
                         <div class="grid grid-cols-2 gap-4">
                             <UFormGroup label="Intensité Parallax">
                                  <URange v-model="form.ui_config.parallax_intensity" :min="0" :max="10" :step="1" />
                                  <div class="flex justify-between text-[10px] text-gray-500 mt-1 uppercase"><span>Statique</span><span>Profond</span></div>
                             </UFormGroup>
                             <!-- Texture moved to Common -->
                         </div>
                    </div>
            
                    <!-- Video Settings -->
                     <div v-if="form.ui_config.background_type === 'video'" class="space-y-4 bg-gray-900 p-4 rounded-xl border border-gray-800">
                         <UFormGroup label="Fichier Vidéo (MP4)">
                             <AdminImageUploader mini @uploaded="(url) => form.ui_config.background_value = url" />
                             <video v-if="form.ui_config.background_value" :src="form.ui_config.background_value" class="mt-4 h-64 w-full rounded-lg object-contain bg-black border border-gray-700" controls />
                         </UFormGroup>
                         <UFormGroup label="Effets de lecture">
                              <div class="space-y-4">
                                  <div class="flex items-center gap-2">
                                    <UCheckbox v-model="form.ui_config.video_scroll_scrub" label="Scroll Scrubbing" />
                                    <UTooltip text="La vidéo avance ou recule en suivant le défilement de la page.">
                                        <UIcon name="i-heroicons-information-circle" class="text-gray-500" />
                                    </UTooltip>
                                  </div>
                                  
                                  <div v-if="form.ui_config.video_scroll_scrub" class="bg-gray-800 p-3 rounded text-xs space-y-2 animate-in fade-in slide-in-from-top-1">
                                      <div class="flex justify-between items-center mb-1">
                                          <span class="text-gray-400">Vitesse de défilement (Frames)</span>
                                          <UBadge size="xs" color="gray">{{ form.ui_config.video_scrub_sensitivity || 2 }}x</UBadge>
                                      </div>
                                      <URange 
                                        v-model="form.ui_config.video_scrub_sensitivity" 
                                        :min="0.1" 
                                        :max="5" 
                                        :step="0.1" 
                                        :default="2"
                                      />
                                      <div class="flex justify-between text-[9px] text-gray-500 uppercase">
                                          <span>Lent</span>
                                          <span>Rapide</span>
                                      </div>
                                  </div>
                              </div>
                         </UFormGroup>
                    </div>
                    
                    <!-- Common Overlay -->
                    <div v-if="form.ui_config.background_type !== 'color'" class="pt-4 border-t border-gray-800">
                        <UFormGroup label="Opacité de l'Overlay (Assombrissement)">
                              <URange v-model="form.ui_config.overlay_opacity" :min="0" :max="1" :step="0.1" />
                              <div class="flex justify-between text-[10px] text-gray-400 mt-1">
                                  <span>Transparent</span>
                                  <span>{{ Math.round((form.ui_config.overlay_opacity || 0) * 100) }}%</span>
                                  <span>Noir</span>
                              </div>
                        </UFormGroup>
                    </div>

                    <!-- Texture Overlay (Any type) -->
                    <div class="pt-4 border-t border-gray-800">
                         <UFormGroup label="Texture de superposition">
                             <USelect v-model="form.ui_config.overlay_texture" :options="['none', 'dots', 'grid', 'noise']" />
                         </UFormGroup>
                    </div>

                    <!-- Animation Settings (Moved to new tab) -->

                    <!-- Animation Settings (Moved to new tab) -->  
                </div>
            </template>

            <!-- JSON TAB -->
            <template #json="{ item }">
                 <div class="grid grid-cols-2 gap-4 h-[300px] mt-4 font-mono text-[10px]">
                    <UTextarea 
                        :model-value="JSON.stringify(form.content_data, null, 2)"
                        @update:model-value="(v) => { try { form.content_data = JSON.parse(v) } catch(e){} }"
                        class="bg-gray-950 border-gray-800"
                        variant="none"
                        placeholder="Content JSON"
                    />
                    <UTextarea 
                        :model-value="JSON.stringify(form.ui_config, null, 2)"
                        @update:model-value="(v) => { try { form.ui_config = JSON.parse(v) } catch(e){} }"
                        class="bg-gray-950 border-gray-800"
                        variant="none"
                        placeholder="Config JSON"
                    />
                 </div>
            </template>

            <!-- ANIMATION TAB -->
            <template #animation="{ item }">
                <div class="space-y-6 pt-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
                    
                    <!-- Content Animation -->
                    <div class="bg-gray-900 rounded-xl border border-gray-800 p-4 space-y-4">
                        <div class="flex items-center justify-between border-b border-gray-800 pb-2">
                            <h4 class="text-sm font-bold text-gray-300 uppercase">Animation de Contenu</h4>
                            <div class="flex items-center gap-2">
                                <label class="text-xs text-gray-400">Activer</label>
                                <UToggle 
                                    :model-value="form.ui_config.animation_type === 'timeline'"
                                    @update:model-value="(v) => form.ui_config.animation_type = v ? 'timeline' : 'none'"
                                />
                            </div>
                        </div>
                        
                        <div v-if="form.ui_config.animation_type === 'timeline'" class="animate-in fade-in slide-in-from-top-2">
                             <AnimationTimelineEditor 
                                :model-value="form.ui_config.timeline_config"
                                @update:model-value="(v) => form.ui_config.timeline_config = v"
                             />
                        </div>
                        <div v-else class="text-xs text-gray-600 italic text-center py-2">
                            Aucune animation active sur le contenu.
                        </div>
                    </div>

                    <!-- Background Animation -->
                    <div class="bg-gray-900 rounded-xl border border-gray-800 p-4 space-y-4">
                        <div class="flex items-center justify-between border-b border-gray-800 pb-2">
                            <h4 class="text-sm font-bold text-gray-300 uppercase">Animation d'Arrière-plan</h4>
                            <div class="flex items-center gap-2">
                                <label class="text-xs text-gray-400">Activer</label>
                                <UToggle 
                                    :model-value="form.ui_config.background_animation_type === 'timeline'"
                                    @update:model-value="(v) => form.ui_config.background_animation_type = v ? 'timeline' : 'none'"
                                />
                            </div>
                        </div>

                        <div v-if="form.ui_config.background_animation_type === 'timeline'" class="animate-in fade-in slide-in-from-top-2">
                             <AnimationTimelineEditor 
                                :model-value="form.ui_config.background_timeline_config"
                                @update:model-value="(v) => form.ui_config.background_timeline_config = v"
                             />
                        </div>
                        <div v-else class="text-xs text-gray-600 italic text-center py-2">
                            Aucune animation active sur l'arrière-plan.
                        </div>
                    </div>

                </div>
            </template>
        </UTabs>
        
      </div>
      
      <div v-else class="flex justify-center py-10">
          <UIcon name="i-heroicons-arrow-path" class="animate-spin text-xl text-primary-500" />
      </div>
  </div>
</template>
