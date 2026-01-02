<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import AnimationPresetThumbnail from './AnimationPresetThumbnail.vue'
import AnimationLivePreview from './AnimationLivePreview.vue'
import BezierEditor from './BezierEditor.vue'

const props = defineProps<{
    modelValue: any
}>()

const emit = defineEmits(['update:modelValue'])

const client = useSupabaseClient()
const toast = useToast()

// Default Config Structure
const defaultConfig = {
    trigger_start: "top 0%", // Default: Element Top hits Viewport 0% (Top)
    trigger_end: "bottom 50%", // Default: Element Bottom hits Viewport 50% (Center)
    scrub: true,
    scrub_sensitivity: 1,
    duration: 1, // Default duration in seconds if scrub is false
    duration_out: 1, // NEW: Exit duration
    wait_for_end: true, // NEW: Wait for end trigger
    ease_in: "0.25,0.1,0.25,1.0", // NEW: Ease In
    ease_out: "0.25,0.1,0.25,1.0", // NEW: Ease Out
    once_in: false, // NEW: Play Once In
    once_out: false, // NEW: Play Once Out
    steps: {
        start: { y: 100, x: 0, opacity: 0, scale: 0.9, rotate: 0, blur: 0 },
        active: { y: 0, x: 0, opacity: 1, scale: 1, rotate: 0, blur: 0 },
        end: { y: -100, x: 0, opacity: 0, scale: 0.9, rotate: 0, blur: 0 }
    }
}

// Local State
const localConfig = ref<any>({ ...defaultConfig })
const presets = ref<any[]>([])
const selectedPreset = ref<string | null>(null)
const isLibraryOpen = ref(false)
const isSaveModalOpen = ref(false)
const newPresetName = ref('')
const isPreviewOpen = ref(true)

// Load Presets from DB
const fetchPresets = async () => {
    const { data } = await client
        .from('animation_presets')
        .select('id, name, config, is_system')
        .order('name', { ascending: true })
    
    if (data) presets.value = data
}

onMounted(() => {
    fetchPresets()
})

// Load from props
watch(() => props.modelValue, (val) => {
    if (val) {
        localConfig.value = JSON.parse(JSON.stringify(val))
        // Ensure steps exist
        if (!localConfig.value.steps) localConfig.value.steps = { ...defaultConfig.steps }
    }
}, { immediate: true, deep: true })

// Emit updates
const update = (forceRefresh = false) => {
    // If forceRefresh is needed, we might toggle a key or similar, but simplified:
    // We just emit fresh object. The watcher in DynamicSection handles deep reactivity?
    // User mentioned Play Once issue. We might need to force re-render on frontend.
    // We'll trust the prop watcher for now, but ensure 'show_debug' is separate.
    emit('update:modelValue', { ...localConfig.value })
}

// Interaction Handlers for Debug
const onInteractStart = () => {
    localConfig.value.show_debug = true
    update()
}
const onInteractEnd = () => {
    localConfig.value.show_debug = false
    update()
}

// Apply Preset
const applyPreset = (preset: any) => {
    if (preset) {
        selectedPreset.value = preset.id
        // Deep copy to break reference
        const config = JSON.parse(JSON.stringify(preset.config))
        localConfig.value = { ...defaultConfig, ...config } // Merge with default to ensure structural integrity
        update()
        toast.add({ title: 'Preset chargé', description: preset.name, color: 'green' })
    }
}

// Delete Preset
const deletePreset = async (preset: any) => {
    if (!confirm(`Supprimer le preset "${preset.name}" ?`)) return
    
    const { error } = await client.from('animation_presets').delete().eq('id', preset.id)
    if (!error) {
        toast.add({ title: 'Preset supprimé', color: 'gray' })
        fetchPresets()
    } else {
        toast.add({ title: 'Erreur', description: error.message, color: 'red' })
    }
}

// Save Preset
const savePreset = async () => {
    if (!newPresetName.value) return
    
    // cast to any to avoid strict type error since table is new
    const { error } = await (client as any).from('animation_presets').insert({
        name: newPresetName.value,
        config: localConfig.value,
        is_system: false
    })

    if (!error) {
        toast.add({ title: 'Preset sauvegardé', color: 'green' })
        isSaveModalOpen.value = false
        newPresetName.value = ''
        fetchPresets() // Refresh list
    } else {
        toast.add({ title: 'Erreur', description: error.message, color: 'red' })
    }
}

// Neutral Config for Reset
const neutralConfig = {
    trigger_start: "top 0%",
    trigger_end: "bottom 50%",
    scrub: true,
    scrub_sensitivity: 1,
    duration: 1,
    duration_out: 1,
    wait_for_end: true,
    ease_in: "0.25,0.1,0.25,1.0",
    ease_out: "0.25,0.1,0.25,1.0",
    once_in: false,
    once_out: false,
    steps: {
        start: { y: 0, x: 0, opacity: 1, scale: 1, rotate: 0, blur: 0 },
        active: { y: 0, x: 0, opacity: 1, scale: 1, rotate: 0, blur: 0 },
        end: { y: 0, x: 0, opacity: 1, scale: 1, rotate: 0, blur: 0 }
    }
}

// Reset
const resetConfig = () => {
    localConfig.value = JSON.parse(JSON.stringify(neutralConfig))
    selectedPreset.value = null
    update()
    toast.add({ title: 'Réinitialisé (Neutre)', color: 'gray' })
}

// Reset Single Step
const resetStep = (step: string) => {
    // cast step to keyof steps
    const key = step as 'start' | 'active' | 'end'
    if (localConfig.value.steps && localConfig.value.steps[key]) {
         localConfig.value.steps[key] = { ...neutralConfig.steps[key] }
         update()
         toast.add({ title: `Étape ${step} réinitialisée`, color: 'gray' })
    }
}

// Tabs for Keyframes
const tabs = [
    { label: 'Entrée (Start)', slot: 'start', icon: 'i-heroicons-arrow-right-start-on-rectangle' },
    { label: 'Active (Visible)', slot: 'active', icon: 'i-heroicons-eye' },
    { label: 'Sortie (End)', slot: 'end', icon: 'i-heroicons-arrow-right-end-on-rectangle' },
    { label: 'Paramètres', slot: 'settings', icon: 'i-heroicons-adjustments-horizontal' }
]
</script>

<template>
    <div class="animation-timeline-editor space-y-6">
        
        <!-- HEADER Toolbar -->
        <div class="flex items-center justify-between">
             <div class="flex items-center gap-2">
                 <h3 class="text-sm font-bold text-gray-400 uppercase tracking-wider">Éditeur d'Animation</h3>
                 <UButton 
                    :icon="isLibraryOpen ? 'i-heroicons-chevron-up' : 'i-heroicons-chevron-down'" 
                    :label="isLibraryOpen ? 'Masquer la bibliothèque' : 'Afficher la bibliothèque'"
                    size="2xs" 
                    color="gray" 
                    variant="ghost" 
                    class="ml-2"
                    @click="isLibraryOpen = !isLibraryOpen" 
                 />
             </div>
             
             <div class="flex gap-2">
                 <UButton icon="i-heroicons-bookmark" label="Sauvegarder" color="gray" variant="soft" size="xs" @click="isSaveModalOpen = true" />
                 <UButton icon="i-heroicons-arrow-path" label="Reset" color="red" variant="ghost" size="xs" @click="resetConfig" />
                 <div class="h-6 w-px bg-gray-700 mx-2"></div>
                 <div class="flex items-center gap-2">
                    <span class="text-xs text-gray-500 font-bold uppercase">Preview</span>
                    <UToggle v-model="isPreviewOpen" size="md" icon-on="i-heroicons-eye" icon-off="i-heroicons-eye-slash" />
                 </div>
             </div>
        </div>

        <!-- 1. PRESETS GALLERY (Collapsible) -->
        <div v-show="isLibraryOpen" class="space-y-2 animate-in fade-in slide-in-from-top-2">
            <h4 class="text-xs font-bold text-gray-500 uppercase flex items-center gap-2">
                 <UIcon name="i-heroicons-sparkles" class="text-yellow-500" />
                 Bibliothèque de Présélections
            </h4>
            <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-3 bg-gray-950/30 p-4 rounded-xl border border-dashed border-gray-800 max-h-48 overflow-y-auto custom-scrollbar">
                 <AnimationPresetThumbnail 
                    v-for="preset in presets"
                    :key="preset.id"
                    :preset="preset"
                    :selected="selectedPreset === preset.id"
                    @select="applyPreset"
                    @delete="deletePreset"
                 />
                 
                 <!-- Empty State -->
                 <div v-if="presets.length === 0" class="col-span-full text-center text-xs text-gray-500 py-4">
                     Aucun preset disponible.
                 </div>
            </div>
        </div>

        <!-- 2. MAIN SPLIT VIEW -->
        <div class="flex gap-6 items-stretch relative">
            
            <!-- LEFT: Editor Controls -->
            <div class="flex-1 min-w-0">
                <UTabs :items="tabs" class="w-full" :ui="{ list: { background: 'bg-gray-800', tab: { active: 'bg-primary-500 text-white', inactive: 'text-gray-400' } } }">
                    
                    <!-- DYNAMIC STEPS (Start, Active, End) -->
                    <template v-for="step in ['start', 'active', 'end']" :key="step" #[step]>
                        <div class="p-4 space-y-4 bg-gray-900/50 rounded-b-lg border border-t-0 border-gray-800 h-full relative group/pane">
                            <!-- Subtle Reset Button for this step -->
                            <div class="absolute top-2 right-2 opacity-0 group-hover/pane:opacity-100 transition-opacity">
                                <UTooltip text="Réinitialiser cette étape uniquement">
                                    <UButton 
                                        icon="i-heroicons-arrow-path" 
                                        size="xs" 
                                        color="red" 
                                        variant="ghost" 
                                        @click="resetStep(step)" 
                                    />
                                </UTooltip>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
                                
                                <!-- Transform Y -->
                                <UFormGroup label="Position Y (Vertical)">
                                    <div class="flex items-center gap-2">
                                        <UInput type="number" v-model.number="localConfig.steps[step].y" @update:model-value="update" size="xs" class="w-16">
                                            <template #trailing>px</template>
                                        </UInput>
                                        <URange v-model.number="localConfig.steps[step].y" :min="-500" :max="500" :step="10" @update:model-value="update" class="flex-1" />
                                    </div>
                                </UFormGroup>

                                <!-- Transform X -->
                                <UFormGroup label="Position X (Horizontal)">
                                    <div class="flex items-center gap-2">
                                        <UInput type="number" v-model.number="localConfig.steps[step].x" @update:model-value="update" size="xs" class="w-16">
                                            <template #trailing>px</template>
                                        </UInput>
                                        <URange v-model.number="localConfig.steps[step].x" :min="-500" :max="500" :step="10" @update:model-value="update" class="flex-1" />
                                    </div>
                                </UFormGroup>

                                <!-- Opacity -->
                                <UFormGroup label="Opacité">
                                    <div class="flex items-center gap-2">
                                        <UInput type="number" v-model.number="localConfig.steps[step].opacity" @update:model-value="update" size="xs" step="0.1" max="1" min="0" class="w-16" />
                                        <URange v-model.number="localConfig.steps[step].opacity" :min="0" :max="1" :step="0.1" @update:model-value="update" class="flex-1" />
                                    </div>
                                </UFormGroup>
                                
                                <!-- Scale -->
                                <UFormGroup label="Échelle (Scale)">
                                    <div class="flex items-center gap-2">
                                        <UInput type="number" v-model.number="localConfig.steps[step].scale" @update:model-value="update" size="xs" step="0.1" class="w-16" />
                                        <URange v-model.number="localConfig.steps[step].scale" :min="0" :max="3" :step="0.1" @update:model-value="update" class="flex-1" />
                                    </div>
                                </UFormGroup>

                                <!-- Blur -->
                                <UFormGroup label="Flou (Blur)">
                                    <div class="flex items-center gap-2">
                                        <UInput type="number" v-model.number="localConfig.steps[step].blur" @update:model-value="update" size="xs" class="w-16">
                                            <template #trailing>px</template>
                                        </UInput>
                                        <URange v-model.number="localConfig.steps[step].blur" :min="0" :max="20" :step="1" @update:model-value="update" class="flex-1" />
                                    </div>
                                </UFormGroup>

                                <!-- Rotate -->
                                <UFormGroup label="Rotation">
                                    <div class="flex items-center gap-2">
                                        <UInput type="number" v-model.number="localConfig.steps[step].rotate" @update:model-value="update" size="xs" class="w-16">
                                            <template #trailing>°</template>
                                        </UInput>
                                        <URange v-model.number="localConfig.steps[step].rotate" :min="-180" :max="180" :step="5" @update:model-value="update" class="flex-1" />
                                    </div>
                                </UFormGroup>

                            </div>
                        </div>
                    </template>

                    <!-- SETTINGS -->
                    <template #settings>
                        <div class="p-4 space-y-6 bg-gray-900/50 rounded-b-lg border border-t-0 border-gray-800 h-full">
                            
                            <!-- 1. Scrub Mode (Toggle) - ALWAYS FIRST/FIXED -->
                            <div class="bg-gray-800/50 p-3 rounded-lg border border-gray-700 space-y-3">
                                <UFormGroup label="Mode Scroll (Scrub)" help="Synchroniser l'animation avec le défilement">
                                    <div class="flex items-center justify-between">
                                        <UToggle v-model="localConfig.scrub" @update:model-value="update" size="md" />
                                        <UBadge size="xs" color="gray" v-if="localConfig.scrub">{{ localConfig.scrub_sensitivity || 1 }}x</UBadge>
                                    </div>
                                </UFormGroup>

                                <!-- Sensitivity (Only if Scrub) -->
                                <div v-if="localConfig.scrub" class="pt-2 animate-in fade-in space-y-2">
                                    <div class="flex justify-between text-[10px] text-gray-500 uppercase font-bold">
                                        <span>Lent</span>
                                        <span>Rapide</span>
                                    </div>
                                    <URange 
                                        v-model.number="localConfig.scrub_sensitivity" 
                                        :min="0.1" :max="5" :step="0.1" 
                                        @update:model-value="update" 
                                        size="xs"
                                    />
                                </div>
                            </div>

                            <!-- 2. Non-Scrub Settings (Organized) -->
                            <div v-if="!localConfig.scrub" class="space-y-4 animate-in fade-in">
                                
                                <!-- PART A: ENTRANCE -->
                                <div class="bg-gray-800/50 p-3 rounded-lg border border-gray-700 space-y-3">
                                    <h4 class="text-xs font-bold text-gray-400 uppercase flex items-center gap-2 border-b border-gray-700 pb-2">
                                        <UIcon name="i-heroicons-arrow-right-start-on-rectangle" class="text-green-400" />
                                        Entrée
                                    </h4>

                                    <!-- 1. Duration & Options (Top) -->
                                    <div class="space-y-2">
                                         <div class="flex items-center justify-between">
                                            <div class="text-[10px] text-gray-500 uppercase font-bold">Durée</div>
                                            <div class="flex items-center gap-2">
                                                <span class="text-[9px] text-gray-500 uppercase font-bold">Play Once</span>
                                                <UToggle v-model="localConfig.once_in" @update:model-value="update" size="xs" />
                                            </div>
                                         </div>
                                         
                                         <!-- Pro Slider Style -->
                                         <div class="flex items-center gap-3 bg-gray-950/30 p-2 rounded border border-gray-800">
                                            <div class="flex-1">
                                                <URange 
                                                   v-model.number="localConfig.duration" 
                                                   :min="0.1" :max="3" :step="0.1" 
                                                   @update:model-value="update"
                                                   @start="onInteractStart"
                                                   @end="onInteractEnd"
                                                   size="xs"
                                                />
                                            </div>
                                            <div class="w-10 text-right text-xs font-mono text-gray-400">
                                                {{ localConfig.duration }}s
                                            </div>
                                        </div>
                                    </div>

                                    <!-- 2. Bezier (Bottom) -->
                                    <div class="space-y-1">
                                        <label class="text-[10px] text-gray-500 uppercase font-bold">Courbe de Vitesse</label>
                                        <BezierEditor v-model="localConfig.ease_in" @update:model-value="update" />
                                    </div>
                                </div>

                                <!-- PART B: SEPARATOR / WAIT -->
                                <div class="flex items-center justify-between px-2 py-2 border-y border-dashed border-gray-700/50">
                                    <div class="flex items-center gap-2">
                                        <UIcon name="i-heroicons-clock" class="text-gray-500" />
                                        <span class="text-xs font-medium text-gray-300">Attendre Declencheur Fin</span>
                                    </div>
                                    <UToggle v-model="localConfig.wait_for_end" @update:model-value="update" size="md" />
                                </div>

                                <!-- PART C: EXIT -->
                                <div class="bg-gray-800/50 p-3 rounded-lg border border-gray-700 space-y-3 opacity-100 transition-opacity duration-200" :class="{ 'opacity-50 pointer-events-none': !localConfig.wait_for_end && false }"> 
                                    <h4 class="text-xs font-bold text-gray-400 uppercase flex items-center gap-2 border-b border-gray-700 pb-2">
                                        <UIcon name="i-heroicons-arrow-right-end-on-rectangle" class="text-red-400" />
                                        Sortie
                                    </h4>

                                     <!-- 1. Duration & Options (Top) -->
                                    <div class="space-y-2">
                                         <div class="flex items-center justify-between">
                                            <div class="text-[10px] text-gray-500 uppercase font-bold">Durée</div>
                                            <div class="flex items-center gap-2">
                                                <span class="text-[9px] text-gray-500 uppercase font-bold">Play Once</span>
                                                <UToggle v-model="localConfig.once_out" @update:model-value="update" size="xs" />
                                            </div>
                                         </div>
                                         
                                         <!-- Pro Slider Style -->
                                         <div class="flex items-center gap-3 bg-gray-950/30 p-2 rounded border border-gray-800">
                                            <div class="flex-1">
                                                <URange 
                                                   v-model.number="localConfig.duration_out" 
                                                   :min="0.1" :max="3" :step="0.1" 
                                                   @update:model-value="update"
                                                   @start="onInteractStart"
                                                   @end="onInteractEnd"
                                                   size="xs"
                                                />
                                            </div>
                                            <div class="w-10 text-right text-xs font-mono text-gray-400">
                                                {{ localConfig.duration_out }}s
                                            </div>
                                        </div>
                                    </div>

                                    <!-- 2. Bezier (Bottom) -->
                                    <div class="space-y-1">
                                        <label class="text-[10px] text-gray-500 uppercase font-bold">Courbe de Vitesse</label>
                                        <BezierEditor v-model="localConfig.ease_out" @update:model-value="update" />
                                    </div>
                                </div>

                            </div>
                            
                            <!-- 3. TRIGGERS (Simplified) - Only if !Scrub -->
                            <div v-if="!localConfig.scrub" class="grid grid-cols-1 gap-3 animate-in fade-in">
                                <label class="text-xs font-bold text-gray-500 uppercase border-b border-gray-800 pb-1 mb-1">
                                    Déclencheurs (Scroll)
                                </label>

                                <!-- Start Trigger -->
                                <div class="flex items-center gap-3 bg-gray-950/30 p-2 rounded border border-gray-800">
                                    <div class="w-16 shrink-0 text-xs font-bold text-green-400">START</div>
                                    <div class="flex-1">
                                        <URange 
                                           :model-value="parseInt(localConfig.trigger_start?.split(' ')[1] || '0')" 
                                           :min="0" :max="100" :step="1" 
                                           @update:model-value="(v) => { localConfig.trigger_start = `top ${v}%`; update() }"
                                           @start="onInteractStart"
                                           @end="onInteractEnd"
                                           size="xs" color="green"
                                        />
                                    </div>
                                    <div class="w-10 text-right text-xs font-mono text-gray-400">
                                        {{ localConfig.trigger_start?.split(' ')[1] || '0%' }}
                                    </div>
                                </div>

                                <!-- End Trigger -->
                                <div class="flex items-center gap-3 bg-gray-950/30 p-2 rounded border border-gray-800">
                                    <div class="w-16 shrink-0 text-xs font-bold text-red-400">END</div>
                                    <div class="flex-1">
                                        <URange 
                                           :model-value="parseInt(localConfig.trigger_end?.split(' ')[1] || '50')" 
                                           :min="0" :max="100" :step="1" 
                                           @update:model-value="(v) => { localConfig.trigger_end = `bottom ${v}%`; update() }"
                                           @start="onInteractStart"
                                           @end="onInteractEnd"
                                           size="xs" color="red"
                                        />
                                    </div>
                                    <div class="w-10 text-right text-xs font-mono text-gray-400">
                                        {{ localConfig.trigger_end?.split(' ')[1] || '50%' }}
                                    </div>
                                </div>
                                <p class="text-[9px] text-gray-600 italic text-center">Reference: Haut de la fenêtre (0%) -> Bas (100%)</p>
                            </div>

                        </div>
                    </template>
                </UTabs>
            </div>

             <!-- RIGHT: LIVE PREVIEW & VISUALIZER -->
             <div 
                 v-if="isPreviewOpen" 
                 class="w-72 shrink-0 animate-in fade-in slide-in-from-right-4 flex flex-col pb-[3.25rem] md:pb-0 gap-4"
             >
                  <!-- Animation Preview -->
                  <div class="flex-1 min-h-[200px]">
                      <AnimationLivePreview 
                        :model-value="localConfig" 
                        :trigger-start="localConfig.trigger_start"
                        :trigger-end="localConfig.trigger_end"
                        @update:trigger-start="(v) => { localConfig.trigger_start = v; update() }"
                        @update:trigger-end="(v) => { localConfig.trigger_end = v; update() }"
                        class="h-full w-full shadow-2xl border-gray-600 ring-1 ring-white/10" 
                      />
                  </div>
             </div>

        </div>

        <!-- Save Modal -->
        <UModal v-model="isSaveModalOpen">
            <div class="p-6 space-y-4 bg-gray-900 text-white">
                <h3 class="text-lg font-bold flex items-center gap-2">
                    <UIcon name="i-heroicons-bookmark" class="text-primary-400" />
                    Sauvegarder le Preset
                </h3>
                <UFormGroup label="Nom du preset">
                    <UInput v-model="newPresetName" placeholder="Ex: Zoom Lent + Fade" autofocus />
                </UFormGroup>
                <div class="flex justify-end gap-2 pt-4">
                    <UButton label="Annuler" color="gray" variant="ghost" @click="isSaveModalOpen = false" />
                    <UButton label="Sauvegarder" color="primary" @click="savePreset" />
                </div>
            </div>
        </UModal>
        
    </div>
</template>
