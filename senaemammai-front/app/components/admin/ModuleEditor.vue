<script setup lang="ts">
import AdminImageUploader from '~/components/admin/ImageUploader.vue'
import AdminGridItemEditor from '~/components/admin/GridItemEditor.vue'

// Simple UID generator to avoid dependency issues
const generateId = () => {
    return Date.now().toString(36) + Math.random().toString(36).substr(2)
}

const props = defineProps<{
    modelValue: Array<any>
}>()

const emit = defineEmits(['update:modelValue'])

const modules = computed({
    get: () => props.modelValue || [],
    set: (val) => emit('update:modelValue', val)
})

const addModule = (type: 'text' | 'image' | 'grid') => {
    let data: any = {}
    
    if (type === 'text') {
        data = { content: 'Nouveau texte', tag: 'p', align: 'left', color: '#ffffff' }
    } else if (type === 'image') {
        data = { src: '', alt: '', fit: 'cover' }
    } else if (type === 'grid') {
        data = { 
            columns: { sm: 1, md: 2, lg: 3 }, 
            gap: 'gap-8',
            items: [
                { title: 'Item 1', subtitle: 'Description...', type: 'image' },
                { title: 'Item 2', subtitle: 'Description...', type: 'image' },
                { title: 'Item 3', subtitle: 'Description...', type: 'image' }
            ]
        }
    }

    const newModule = {
        id: generateId(),
        type,
        data,
        config: {
            animation_type: 'none',
            parallax_intensity: 0.2
        }
    }
    modules.value = [...modules.value, newModule]
}

const removeModule = (index: number) => {
    const newModules = [...modules.value]
    newModules.splice(index, 1)
    modules.value = newModules
}

const moveModule = (index: number, direction: 'up' | 'down') => {
    if (direction === 'up' && index === 0) return
    if (direction === 'down' && index === modules.value.length - 1) return

    const newModules = [...modules.value]
    const targetIndex = direction === 'up' ? index - 1 : index + 1
    const temp = newModules[index]
    newModules[index] = newModules[targetIndex]
    newModules[targetIndex] = temp
    modules.value = newModules
}

const updateModuleData = (index: number, key: string, value: any) => {
    const newModules = [...modules.value]
    newModules[index] = {
        ...newModules[index],
        data: {
            ...newModules[index].data,
            [key]: value
        }
    }
    modules.value = newModules
}

const updateModuleConfig = (index: number, key: string, value: any) => {
    const newModules = [...modules.value]
    newModules[index] = {
        ...newModules[index],
        config: {
            ...newModules[index].config,
            [key]: value
        }
    }
    modules.value = newModules
}

// Stats for Timeline UI
const activeTimelineStep = ref<'start' | 'center' | 'end'>('center')

const getTimelineValue = (index: number, step: string, key: string, defaultValue = 0) => {
    const mod = modules.value[index]
    if (!mod.config.timeline) return defaultValue
    if (!mod.config.timeline[step]) return defaultValue
    return mod.config.timeline[step][key] !== undefined ? mod.config.timeline[step][key] : defaultValue
}

const updateTimelineValue = (index: number, step: string, key: string, value: any) => {
    const newModules = [...modules.value]
    const mod = newModules[index]
    
    // Ensure structure exists
    if (!mod.config.timeline) {
        mod.config.timeline = { enabled: true, start: {}, center: {}, end: {} }
    }
    if (!mod.config.timeline[step]) {
        mod.config.timeline[step] = {}
    }

    mod.config.timeline[step][key] = value
    newModules[index] = mod
    modules.value = newModules
}

const resetTimelineStep = (index: number, step: string) => {
    const newModules = [...modules.value]
    if (newModules[index].config.timeline && newModules[index].config.timeline[step]) {
        newModules[index].config.timeline[step] = {} // Reset to empty (defaults)
    }
    modules.value = newModules
}
const collapsedModules = ref<Record<string, boolean>>({})

const toggleCollapse = (id: string) => {
    collapsedModules.value[id] = !collapsedModules.value[id]
}
</script>

<template>
    <div class="space-y-6">
        <!-- List of Modules -->
        <div class="space-y-4">
            <div 
                v-for="(mod, index) in modules" 
                :key="mod.id"
                class="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden"
            >
                <!-- Module Header -->
                <div 
                    class="bg-gray-900/50 p-3 flex items-center justify-between border-b border-gray-700 cursor-pointer select-none hover:bg-gray-800 transition-colors"
                    @click="toggleCollapse(mod.id)"
                >
                    <div class="flex items-center gap-3">
                         <div 
                            class="w-6 h-6 rounded-full flex items-center justify-center transition-transform duration-300 bg-gray-800"
                            :class="collapsedModules[mod.id] ? '-rotate-90' : 'rotate-0'"
                        >
                            <UIcon name="i-heroicons-chevron-down" class="w-4 h-4 text-gray-400" />
                        </div>

                        <UIcon :name="mod.type === 'text' ? 'i-heroicons-document-text' : 'i-heroicons-photo'" class="text-primary-400" />
                        <span class="text-sm font-bold uppercase text-gray-300">{{ mod.type }}</span>
                    </div>
                    
                    <div class="flex items-center gap-2">
                         <div class="flex items-center bg-gray-950 rounded p-1 mr-2" @click.stop>
                            <button @click="moveModule(index, 'up')" :disabled="index === 0" class="p-1 text-gray-500 hover:text-white disabled:opacity-20"><UIcon name="i-heroicons-chevron-up" class="w-3 h-3" /></button>
                            <button @click="moveModule(index, 'down')" :disabled="index === modules.length - 1" class="p-1 text-gray-500 hover:text-white disabled:opacity-20"><UIcon name="i-heroicons-chevron-down" class="w-3 h-3" /></button>
                        </div>
                        <button @click.stop="removeModule(index)" class="text-red-400 hover:text-red-300 p-1 bg-gray-950/50 rounded hover:bg-red-500/10 transition-colors">
                            <UIcon name="i-heroicons-trash" />
                        </button>
                    </div>
                </div>

                <!-- Unified Module Editor (Tabs for ALL types) -->
                <div class="p-4" v-show="!collapsedModules[mod.id]">
                     <UTabs :items="[{ label: 'Contenu', icon: 'i-heroicons-squares-2x2', slot: 'content' }, { label: 'Style & Animation', icon: 'i-heroicons-paint-brush', slot: 'animation' }]" class="w-full">
                        
                        <!-- TAB: CONTENT -->
                        <template #content>
                            <div class="pt-6 space-y-6">
                                
                                <!-- === GRID CONTENT === -->
                                <template v-if="mod.type === 'grid'">
                                    <!-- Grid Config -->
                                    <div class="grid grid-cols-3 gap-4 bg-gray-900/50 p-4 rounded-lg border border-gray-700/50">
                                        <UFormGroup label="Colonnes (LG)" size="xs">
                                            <UInput type="number" :model-value="mod.data.columns?.lg || 3" @update:model-value="(v) => updateModuleData(index, 'columns', { ...mod.data.columns, lg: parseInt(v) })" />
                                        </UFormGroup>
                                        <UFormGroup label="Colonnes (MD)" size="xs">
                                            <UInput type="number" :model-value="mod.data.columns?.md || 2" @update:model-value="(v) => updateModuleData(index, 'columns', { ...mod.data.columns, md: parseInt(v) })" />
                                        </UFormGroup>
                                        <UFormGroup label="Colonnes (SM)" size="xs">
                                            <UInput type="number" :model-value="mod.data.columns?.sm || 1" @update:model-value="(v) => updateModuleData(index, 'columns', { ...mod.data.columns, sm: parseInt(v) })" />
                                        </UFormGroup>
                                    </div>

                                    <!-- Items List -->
                                    <div class="space-y-4">
                                        <div class="flex justify-between items-center px-1">
                                            <h5 class="text-xs font-bold text-gray-400 uppercase tracking-wider">Éléments de la grille ({{ mod.data.items?.length || 0 }})</h5>
                                            <UButton size="xs" icon="i-heroicons-plus" color="primary" variant="soft" @click="() => {
                                                const items = [...(mod.data.items || [])];
                                                items.push({ title: 'Nouvel élément', type: 'image', autoplay: true });
                                                updateModuleData(index, 'items', items);
                                            }">Ajouter un élément</UButton>
                                        </div>
                                        
                                        <div class="space-y-4 max-h-[600px] overflow-y-auto pr-2 custom-scrollbar p-1">
                                            <AdminGridItemEditor 
                                                v-for="(item, iIndex) in mod.data.items || []" 
                                                :key="iIndex"
                                                :item="item"
                                                :index="iIndex"
                                                @update="(newItem) => {
                                                    const items = [...mod.data.items];
                                                    items[iIndex] = newItem;
                                                    updateModuleData(index, 'items', items);
                                                }"
                                                @remove="() => {
                                                    const items = [...mod.data.items];
                                                    items.splice(iIndex, 1);
                                                    updateModuleData(index, 'items', items);
                                                }"
                                            />
                                            <div v-if="(!mod.data.items || mod.data.items.length === 0)" class="text-center py-12 text-gray-500 border-2 border-dashed border-gray-800 rounded-xl">
                                                <UIcon name="i-heroicons-photo" class="text-2xl mb-2 opacity-50" />
                                                <p class="text-xs italic">La grille est vide.</p>
                                            </div>
                                        </div>
                                    </div>
                                </template>

                                <!-- === TEXT CONTENT === -->
                                <template v-if="mod.type === 'text'">
                                    <UTextarea 
                                        :model-value="mod.data.content" 
                                        @update:model-value="(v) => updateModuleData(index, 'content', v)"
                                        label="Contenu Texte"
                                        :rows="6"
                                    />
                                    <div class="grid grid-cols-2 gap-4">
                                        <UFormGroup label="Balise HTML">
                                            <USelect 
                                                :model-value="mod.data.tag" 
                                                :options="['h1', 'h2', 'h3', 'p', 'div']"
                                                @update:model-value="(v) => updateModuleData(index, 'tag', v)"
                                            />
                                        </UFormGroup>
                                        <UFormGroup label="Alignement">
                                            <USelect 
                                                :model-value="mod.data.align" 
                                                :options="['left', 'center', 'right']"
                                                @update:model-value="(v) => updateModuleData(index, 'align', v)"
                                            />
                                        </UFormGroup>
                                    </div>
                                </template>

                                <!-- === IMAGE CONTENT === -->
                                <template v-if="mod.type === 'image'">
                                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                                        <!-- Left: Preview & Upload -->
                                        <div class="space-y-4">
                                            <div class="bg-gray-900 p-4 rounded-xl text-center relative group border border-gray-800">
                                                <img v-if="mod.data.src" :src="mod.data.src" class="h-48 mx-auto object-contain mb-2 bg-gray-950/50 rounded-lg" />
                                                <div class="absolute inset-0 flex items-center justify-center bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity rounded-xl cursor-pointer">
                                                    <AdminImageUploader @uploaded="(url) => updateModuleData(index, 'src', url)" />
                                                </div>
                                                <div v-if="!mod.data.src" class="text-gray-500 text-sm py-8">Aucune image sélectionnée</div>
                                            </div>
                                            <UInput :model-value="mod.data.alt" @update:model-value="(v) => updateModuleData(index, 'alt', v)" placeholder="Description (Alt Text)" icon="i-heroicons-identification" />
                                        </div>

                                        <!-- Right: Settings -->
                                        <div class="space-y-6">
                                            <!-- Disposition -->
                                            <div class="space-y-3">
                                                <h5 class="text-xs font-bold text-gray-500 uppercase border-b border-gray-800 pb-2">Disposition</h5>
                                                
                                                <div class="flex items-center justify-between">
                                                    <span class="text-sm text-gray-400">Alignement</span>
                                                    <div class="flex bg-gray-900 p-1 rounded-lg gap-1">
                                                        <button v-for="align in ['left', 'center', 'right']" :key="align" @click="updateModuleData(index, 'align', align)"
                                                            class="p-2 rounded hover:bg-gray-700 text-gray-500 transition-colors" :class="mod.data.align === align ? 'bg-primary-600 text-white' : ''">
                                                            <UIcon :name="align === 'left' ? 'i-heroicons-bars-3-bottom-left' : align === 'right' ? 'i-heroicons-bars-3-bottom-right' : 'i-heroicons-bars-3'" class="w-5 h-5" />
                                                        </button>
                                                    </div>
                                                </div>

                                                <div class="space-y-2">
                                                    <div class="flex justify-between text-xs text-gray-400">
                                                        <span>Largeur</span>
                                                        <span class="font-mono">{{ mod.data.width || 100 }}%</span>
                                                    </div>
                                                    <URange :min="10" :max="100" :step="5" :model-value="mod.data.width ?? 100" @update:model-value="(v) => updateModuleData(index, 'width', v)" />
                                                </div>
                                            </div>

                                            <!-- Style -->
                                            <div class="space-y-3">
                                                <h5 class="text-xs font-bold text-gray-500 uppercase border-b border-gray-800 pb-2">Style</h5>
                                                
                                                <div class="grid grid-cols-2 gap-4">
                                                    <UFormGroup label="Arrondi" size="xs">
                                                        <USelect :model-value="mod.data.radius || 'none'" :options="['none', 'md', 'xl', 'full']" @update:model-value="(v) => updateModuleData(index, 'radius', v)" />
                                                    </UFormGroup>
                                                    <UFormGroup label="Ombre" size="xs">
                                                        <USelect :model-value="mod.data.shadow || 'none'" :options="['none', 'md', 'xl', '2xl']" @update:model-value="(v) => updateModuleData(index, 'shadow', v)" />
                                                    </UFormGroup>
                                                </div>

                                                <!-- Filters -->
                                                <div class="bg-gray-900/50 p-3 rounded-lg space-y-3">
                                                    <div class="space-y-1">
                                                         <div class="flex justify-between text-[10px] text-gray-400"><span>Opacité</span> <span>{{ mod.data.effects?.opacity ?? 1 }}</span></div>
                                                         <URange :min="0" :max="1" :step="0.1" :model-value="mod.data.effects?.opacity ?? 1" @update:model-value="(v) => updateModuleData(index, 'effects', { ...(mod.data.effects || {}), opacity: v })" size="2xs" />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </template>
                            </div>
                        </template>

                        <!-- TAB: ANIMATION (Generic for ALL types) -->
                        <template #animation>
                             <div class="pt-6 max-w-lg mx-auto">
                                <div class="space-y-6">
                                    <div class="bg-gray-900 p-4 rounded-xl border border-gray-800 space-y-4">
                                        <h4 class="text-sm font-bold text-gray-300">Animation d'apparition (Module)</h4>
                                        <!-- Type Selector -->
                                        <div class="flex items-center justify-between">
                                            <span class="text-xs text-gray-400">Type</span>
                                            <USelect 
                                                size="sm"
                                                :model-value="mod.config.animation_type" 
                                                :options="['none', 'fade-up', 'fade-down', 'fade-in', 'zoom-in', 'zoom-out', 'parallax', 'scroll-timeline']"
                                                @update:model-value="(v) => updateModuleConfig(index, 'animation_type', v)"
                                                class="w-40"
                                            />
                                        </div>

                                        <!-- Standard Animation Config -->
                                        <template v-if="mod.config.animation_type !== 'none' && mod.config.animation_type !== 'parallax' && mod.config.animation_type !== 'scroll-timeline'">
                                            <div class="grid grid-cols-2 gap-4 pt-2">
                                                <div class="space-y-1">
                                                    <span class="text-[10px] text-gray-500 font-bold uppercase">Durée ({{ mod.config.duration || 1 }}s)</span>
                                                    <URange :min="0.2" :max="3" :step="0.1" :model-value="mod.config.duration || 1" @update:model-value="(v) => updateModuleConfig(index, 'duration', v)" size="sm" />
                                                </div>
                                                <div class="space-y-1">
                                                    <span class="text-[10px] text-gray-500 font-bold uppercase">Délai ({{ mod.config.delay || 0 }}s)</span>
                                                    <URange :min="0" :max="2" :step="0.1" :model-value="mod.config.delay || 0" @update:model-value="(v) => updateModuleConfig(index, 'delay', v)" size="sm" />
                                                </div>
                                            </div>
                                        </template>
                                        
                                        <!-- Note for Parallax/Timeline -->
                                        <div v-if="mod.config.animation_type === 'parallax' || mod.config.animation_type === 'scroll-timeline'" class="text-xs text-gray-500 italic pt-2">
                                            Ces animations avancées sont gérées par le défilement.
                                        </div>
                                    </div>

                                    <!-- Timeline Editors for Scroll-Timeline -->
                                    <template v-if="mod.config.animation_type === 'scroll-timeline'">
                                        <!-- ... (Reuse timeline editor) ... -->
                                        <div class="bg-gray-950 rounded p-3 space-y-4 border border-gray-800">
                                            <div class="flex items-center justify-between px-2 pt-2 relative">
                                                <div class="absolute top-1/2 left-4 right-4 h-0.5 bg-gray-800 -z-0"></div>
                                                <button v-for="step in ['start', 'center', 'end']" :key="step" @click="activeTimelineStep = step" class="relative z-10 flex flex-col items-center gap-1 group">
                                                    <div class="w-3 h-3 rounded-full border-2 transition-all duration-300" :class="activeTimelineStep === step ? 'bg-primary-500 border-primary-500 scale-125' : 'bg-gray-900 border-gray-600 group-hover:border-gray-400'"></div>
                                                    <span class="text-[9px] uppercase font-bold tracking-wider" :class="activeTimelineStep === step ? 'text-primary-400' : 'text-gray-600'">{{ step === 'start' ? 'Avant' : step === 'center' ? 'Pendant' : 'Après' }}</span>
                                                </button>
                                            </div>
                                            <div class="bg-gray-900 rounded p-3 space-y-4">
                                                <div class="grid grid-cols-2 gap-x-4 gap-y-4">
                                                    <div class="space-y-1">
                                                        <div class="flex justify-between text-[10px] text-gray-400"><span>Echelle</span> <span>{{ getTimelineValue(index, activeTimelineStep, 'scale') }}x</span></div>
                                                        <URange :min="0" :max="2" :step="0.1" :model-value="getTimelineValue(index, activeTimelineStep, 'scale', 1)" @update:model-value="(v) => updateTimelineValue(index, activeTimelineStep, 'scale', v)" size="2xs" />
                                                    </div>
                                                    <div class="space-y-1">
                                                        <div class="flex justify-between text-[10px] text-gray-400"><span>Opacité</span> <span>{{ getTimelineValue(index, activeTimelineStep, 'opacity') }}</span></div>
                                                        <URange :min="0" :max="1" :step="0.1" :model-value="getTimelineValue(index, activeTimelineStep, 'opacity', 1)" @update:model-value="(v) => updateTimelineValue(index, activeTimelineStep, 'opacity', v)" size="2xs" />
                                                    </div>
                                                    <div class="space-y-1">
                                                        <div class="flex justify-between text-[10px] text-gray-400"><span>Flou</span> <span>{{ getTimelineValue(index, activeTimelineStep, 'blur') }}px</span></div>
                                                        <URange :min="0" :max="20" :step="1" :model-value="getTimelineValue(index, activeTimelineStep, 'blur', 0)" @update:model-value="(v) => updateTimelineValue(index, activeTimelineStep, 'blur', v)" size="2xs" />
                                                    </div>
                                                    <div class="space-y-1">
                                                        <div class="flex justify-between text-[10px] text-gray-400"><span>Rotation</span> <span>{{ getTimelineValue(index, activeTimelineStep, 'rotate') }}°</span></div>
                                                        <URange :min="-180" :max="180" :step="5" :model-value="getTimelineValue(index, activeTimelineStep, 'rotate', 0)" @update:model-value="(v) => updateTimelineValue(index, activeTimelineStep, 'rotate', v)" size="2xs" />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </template>
                                </div>
                             </div>
                        </template>
                     </UTabs>
                </div>
            </div>
        </div>

        <!-- Add Actions (Redesigned) -->
        <div class="grid grid-cols-3 gap-4">
            <button @click="addModule('text')" class="group flex flex-col items-center justify-center gap-3 p-6 rounded-xl border border-gray-800 bg-gray-900/30 hover:bg-gray-800 hover:border-primary-500/50 transition-all duration-300">
                <div class="w-12 h-12 rounded-full bg-gray-800 flex items-center justify-center group-hover:scale-110 transition-transform group-hover:bg-primary-900/20 group-hover:text-primary-400">
                    <UIcon name="i-heroicons-document-text" class="text-2xl" />
                </div>
                <span class="text-xs font-bold uppercase tracking-widest text-gray-400 group-hover:text-white">Texte</span>
            </button>
            <button @click="addModule('image')" class="group flex flex-col items-center justify-center gap-3 p-6 rounded-xl border border-gray-800 bg-gray-900/30 hover:bg-gray-800 hover:border-primary-500/50 transition-all duration-300">
                <div class="w-12 h-12 rounded-full bg-gray-800 flex items-center justify-center group-hover:scale-110 transition-transform group-hover:bg-primary-900/20 group-hover:text-primary-400">
                    <UIcon name="i-heroicons-photo" class="text-2xl" />
                </div>
                <span class="text-xs font-bold uppercase tracking-widest text-gray-400 group-hover:text-white">Image</span>
            </button>
            <button @click="addModule('grid')" class="group flex flex-col items-center justify-center gap-3 p-6 rounded-xl border border-gray-800 bg-gray-900/30 hover:bg-gray-800 hover:border-primary-500/50 transition-all duration-300">
                <div class="w-12 h-12 rounded-full bg-gray-800 flex items-center justify-center group-hover:scale-110 transition-transform group-hover:bg-primary-900/20 group-hover:text-primary-400">
                    <UIcon name="i-heroicons-squares-2x2" class="text-2xl" />
                </div>
                <span class="text-xs font-bold uppercase tracking-widest text-gray-400 group-hover:text-white">Grille</span>
            </button>
        </div>
    </div>
</template>
