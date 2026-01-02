<script setup lang="ts">
import AdminImageUploader from '~/components/admin/ImageUploader.vue'
import AdminGridItemEditor from '~/components/admin/GridItemEditor.vue'
import AnimationTimelineEditor from '~/components/admin/AnimationTimelineEditor.vue'

const props = defineProps<{
    module: any
    index: number
}>()

const emit = defineEmits(['update', 'remove'])

// Local state for expansion
const isExpanded = ref(false)

// Local Module Data (to emit updates)
const localModule = computed({
    get: () => props.module,
    set: (val) => emit('update', val)
})

const updateData = (key: string, value: any) => {
    const newData = { ...localModule.value.data, [key]: value }
    emit('update', { ...localModule.value, data: newData })
}

const updateConfig = (key: string, value: any) => {
    const newConfig = { ...localModule.value.config, [key]: value }
    emit('update', { ...localModule.value, config: newConfig })
}

// Grid Helper
const updateGridItems = (items: any[]) => {
    updateData('items', items)
}

// Styles
const typeColors: any = {
    text: 'text-blue-400',
    image: 'text-purple-400',
    grid: 'text-green-400'
}

const typeIcons: any = {
    text: 'i-heroicons-document-text',
    image: 'i-heroicons-photo',
    grid: 'i-heroicons-squares-2x2'
}

// Animation Modal State
const showAnimationModal = ref(false)
const isAnimated = computed({
    get: () => props.module.config?.animation_type === 'timeline',
    set: (v) => updateConfig('animation_type', v ? 'timeline' : 'none')
})
</script>

<template>
    <div class="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden shadow-sm hover:shadow-md transition-shadow group">
        <!-- Card Header -->
        <div 
            class="bg-gray-900/50 p-3 flex items-center justify-between cursor-pointer select-none hover:bg-gray-800 transition-colors"
            @click="isExpanded = !isExpanded"
        >
            <div class="flex items-center gap-3">
                 <div class="drag-handle-module cursor-grab active:cursor-grabbing text-gray-500 hover:text-white p-1">
                    <UIcon name="i-heroicons-bars-2" class="w-4 h-4" />
                </div>
                <UIcon :name="typeIcons[module.type] || 'i-heroicons-cube'" :class="typeColors[module.type] || 'text-gray-400'" />
                <span class="text-xs font-bold uppercase text-gray-300">{{ module.type }}</span>
            </div>
            
            <div class="flex items-center gap-2">
                 <div class="text-xs text-gray-600 font-mono hidden group-hover:block transition-opacity">
                     {{ isExpanded ? 'Fermer' : 'Modifier' }}
                 </div>
                 <UIcon :name="isExpanded ? 'i-heroicons-chevron-up' : 'i-heroicons-chevron-down'" class="text-gray-500" />
                 <button @click.stop="$emit('remove')" class="text-gray-600 hover:text-red-400 p-1 ml-2 border-l border-gray-700 pl-3">
                      <UIcon name="i-heroicons-trash" class="w-4 h-4" />
                 </button>
            </div>
        </div>

        <!-- Editor Body -->
        <div v-show="isExpanded" class="p-4 border-t border-gray-700 bg-gray-800/50">
            <UTabs :items="[{ label: 'Contenu', slot: 'content' }, { label: 'Style', slot: 'style' }]" class="w-full">
                
                <!-- CONTENT TAB -->
                <template #content>
                    <div class="pt-4 space-y-4">
                        
                        <!-- TEXT -->
                        <template v-if="module.type === 'text'">
                            <UTextarea 
                                :model-value="module.data.content" 
                                @update:model-value="(v) => updateData('content', v)"
                                :rows="4"
                                placeholder="Votre texte ici..."
                            />
                            <div class="flex gap-4">
                                <USelect :model-value="module.data.tag" :options="['p', 'h1', 'h2', 'h3', 'div']" @update:model-value="(v) => updateData('tag', v)" size="xs" />
                                <USelect :model-value="module.data.align" :options="['left', 'center', 'right']" @update:model-value="(v) => updateData('align', v)" size="xs" />
                            </div>
                        </template>

                        <!-- IMAGE -->
                        <template v-if="module.type === 'image'">
                             <div class="flex gap-4">
                                 <div class="w-32 h-32 bg-gray-900 rounded-lg flex items-center justify-center relative group overflow-hidden border border-gray-700">
                                     <img v-if="module.data.src" :src="module.data.src" class="w-full h-full object-cover" draggable="false" />
                                     <div class="absolute inset-0 flex items-center justify-center bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity">
                                         <AdminImageUploader @uploaded="(url) => updateData('src', url)" />
                                     </div>
                                 </div>
                                 <div class="flex-1 space-y-2">
                                     <UInput :model-value="module.data.alt" @update:model-value="(v) => updateData('alt', v)" placeholder="Texte alternatif (SEO)" icon="i-heroicons-tag" />
                                 </div>
                             </div>
                        </template>

                        <!-- GRID -->
                        <template v-if="module.type === 'grid'">
                             <div class="space-y-4">
                                <!-- Quick Columns -->
                                <div class="flex gap-2 text-xs">
                                     <span>Colonnes:</span>
                                     <UInput type="number" :model-value="module.data.columns?.lg || 3" @update:model-value="(v) => updateData('columns', { ...module.data.columns, lg: parseInt(v) })" class="w-16" size="xs" />
                                </div>
                                
                                <!-- Items -->
                                <div class="space-y-2 max-h-60 overflow-y-auto custom-scrollbar p-1">
                                    <AdminGridItemEditor 
                                        v-for="(item, idx) in module.data.items || []"
                                        :key="idx"
                                        :item="item"
                                        :index="typeof idx === 'number' ? idx : parseInt(idx as string)"
                                        @update="(newItem) => {
                                            const newItems = [...(module.data.items || [])];
                                            const i = typeof idx === 'number' ? idx : parseInt(idx as string);
                                            newItems[i] = newItem;
                                            updateGridItems(newItems);
                                        }"
                                        @remove="() => {
                                            const newItems = [...(module.data.items || [])];
                                            const i = typeof idx === 'number' ? idx : parseInt(idx as string);
                                            newItems.splice(i, 1);
                                            updateGridItems(newItems);
                                        }"
                                    />
                                    <UButton size="xs" block variant="soft" icon="i-heroicons-plus" @click="() => updateGridItems([...(module.data.items || []), { type: 'image', title: 'Nouvel Item' }])">Ajouter un élément</UButton>
                                </div>
                             </div>
                        </template>

                    </div>
                </template>

                <!-- STYLE / ANIMATION TAB -->
                <template #style>
                     <div class="pt-4 space-y-4">
                          <!-- ANIMATION CONTROLS -->
                          <div class="bg-gray-900/50 p-3 rounded-lg border border-gray-700">
                               <div class="flex items-center justify-between mb-2">
                                   <div class="flex items-center gap-2">
                                       <UIcon name="i-heroicons-film" class="text-primary-400" />
                                       <span class="text-sm font-medium text-gray-300">Animation</span>
                                   </div>
                                   <div class="flex items-center gap-2">
                                        <UToggle v-model="isAnimated" />
                                        <UTooltip text="Paramètres d'animation" v-if="isAnimated">
                                            <UButton 
                                                icon="i-heroicons-cog-6-tooth" 
                                                size="xs" 
                                                color="gray" 
                                                variant="ghost" 
                                                @click="showAnimationModal = true" 
                                            />
                                        </UTooltip>
                                   </div>
                               </div>
                               <p v-if="!isAnimated" class="text-xs text-gray-500">Aucune animation active.</p>
                               <p v-else class="text-xs text-primary-400">Animation personnalisée active.</p>
                          </div>

                          <UFormGroup label="Classe CSS personnalisée">
                               <UInput 
                                   :model-value="module.config?.class" 
                                   @update:model-value="(v) => updateConfig('class', v)"
                                   placeholder="ex: my-custom-class"
                                   size="xs"
                               />
                          </UFormGroup>
                     </div>
                </template>
            </UTabs>

            <!-- ANIMATION MODAL -->
            <UModal v-model="showAnimationModal" :ui="{ width: 'sm:max-w-4xl' }">
                <div class="p-6 bg-gray-900 text-white">
                    <div class="flex items-center justify-between mb-6">
                        <h3 class="text-xl font-bold flex items-center gap-2">
                            <UIcon name="i-heroicons-film" class="text-primary-400" />
                            Animation du Module
                        </h3>
                        <UButton icon="i-heroicons-x-mark" color="gray" variant="ghost" @click="showAnimationModal = false" />
                    </div>
                    
                    <AnimationTimelineEditor 
                        v-if="module.config?.timeline_config"
                        :model-value="module.config.timeline_config"
                        @update:model-value="(v) => updateConfig('timeline_config', v)"
                    />
                    <div v-else class="text-center py-8">
                        <p class="text-gray-400 mb-4">Configuration manquante.</p>
                        <UButton @click="updateConfig('timeline_config', {})">Initialiser</UButton>
                    </div>
                </div>
            </UModal>

        </div>
    </div>
</template>
