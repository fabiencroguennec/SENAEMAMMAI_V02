<script setup lang="ts">
const props = defineProps<{
    item: any
    index: number
}>()

const emit = defineEmits(['update', 'remove'])

const activeTab = ref('content')

const updateField = (field: string, value: any) => {
    const newItem = { ...props.item, [field]: value }
    emit('update', newItem)
}

const addImage = (url: string) => {
    const images = [...(props.item.images || [])]
    images.push(url)
    updateField('images', images)
    // Sync src
    updateField('src', images[0])
}

const removeImage = (idx: number) => {
    const images = [...(props.item.images || [])]
    images.splice(idx, 1)
    updateField('images', images)
    updateField('src', images.length > 0 ? images[0] : '')
}
</script>

<template>
    <div class="bg-gray-950/30 rounded-lg border border-gray-800 overflow-hidden">
        <!-- Header -->
        <div class="bg-gray-900 border-b border-gray-800 px-3 py-2 flex justify-between items-center">
            <span class="font-bold text-gray-300 text-xs text-white">#{{ index + 1 }} - {{ item.title || 'Sans titre' }}</span>
            <button @click="onRemove" class="text-red-400 hover:text-red-300 p-1 bg-red-500/10 rounded">
                <UIcon name="i-heroicons-trash" class="w-4 h-4" />
            </button>
        </div>

        <!-- Tabs Navigation -->
        <div class="flex border-b border-gray-800 bg-gray-900/50">
            <button 
                @click="activeTab = 'content'"
                class="flex-1 py-2 text-xs font-medium text-center transition-colors border-r border-gray-800 last:border-r-0"
                :class="activeTab === 'content' ? 'text-primary-400 bg-gray-800' : 'text-gray-500 hover:text-gray-300'"
            >
                Contenu
            </button>
            <button 
                @click="activeTab = 'animation'"
                class="flex-1 py-2 text-xs font-medium text-center transition-colors"
                :class="activeTab === 'animation' ? 'text-primary-400 bg-gray-800' : 'text-gray-500 hover:text-gray-300'"
            >
                Animation
            </button>
        </div>

        <!-- TAB: CONTENT -->
        <div v-if="activeTab === 'content'" class="p-4 space-y-4">
            <div class="grid grid-cols-2 gap-2">
                <UFormGroup label="Titre" size="xs">
                    <UInput placeholder="Titre..." :model-value="item.title" @update:model-value="(v) => updateField('title', v)" />
                </UFormGroup>
                <UFormGroup label="Sous-titre" size="xs">
                    <UInput placeholder="Description..." :model-value="item.subtitle" @update:model-value="(v) => updateField('subtitle', v)" />
                </UFormGroup>
            </div>

            <div class="space-y-3">
                <div class="flex items-center justify-between border-b border-gray-800 pb-2">
                    <label class="text-xs font-bold text-gray-500 uppercase">Média & Galerie</label>
                    <div class="scale-75 origin-right">
                        <AdminImageUploader @uploaded="addImage" />
                    </div>
                </div>

                <!-- Gallery -->
                <div v-if="item.images && item.images.length > 0" class="grid grid-cols-4 gap-3">
                    <div v-for="(img, i) in item.images" :key="i" class="relative group aspect-square rounded-lg border border-gray-700 overflow-hidden bg-gray-900">
                        <img :src="img" class="w-full h-full object-cover" />
                        <div class="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                            <button @click="removeImage(i)" class="text-white hover:text-red-400">
                                <UIcon name="i-heroicons-trash" class="w-5 h-5" />
                            </button>
                        </div>
                    </div>
                </div>
                <div v-else-if="item.src" class="w-24 h-24 relative group rounded-lg overflow-hidden border border-gray-700">
                    <img :src="item.src" class="w-full h-full object-cover" />
                    <button @click="updateField('src', '')" class="absolute top-1 right-1 bg-red-500 p-1 rounded-full text-white opacity-0 group-hover:opacity-100">
                        <UIcon name="i-heroicons-x-mark" class="w-3 h-3" />
                    </button>
                </div>
                <div v-else class="text-center py-8 text-gray-600 text-xs italic border border-dashed border-gray-800 rounded bg-gray-900/20">
                    Aucune image. Ajoutez-en via le bouton d'upload.
                </div>
            </div>
        </div>

        <!-- TAB: ANIMATION -->
        <!-- TAB: ANIMATION -->
        <div v-if="activeTab === 'animation'" class="p-4">
             <div v-if="!item.images || item.images.length <= 1" class="text-center text-gray-500 text-xs py-4">
                 Ajoutez plusieurs images pour débloquer les options de diaporama.
             </div>
             <div v-else class="space-y-4">
                 
                 <!-- MAIN TOGGLES -->
                 <div class="flex gap-2">
                     <div class="flex-1 flex items-center justify-between bg-gray-900 px-2 py-1.5 rounded border border-gray-800">
                         <span class="text-[10px] text-gray-400 uppercase font-bold">Autoplay</span>
                         <UToggle size="sm" :model-value="item.autoplay ?? true" @update:model-value="(v) => updateField('autoplay', v)" />
                     </div>
                     <div class="flex-1 flex items-center justify-between bg-gray-900 px-2 py-1.5 rounded border border-gray-800">
                         <span class="text-[10px] text-gray-400 uppercase font-bold">Flèches</span>
                         <UToggle size="sm" :model-value="item.arrows ?? false" @update:model-value="(v) => updateField('arrows', v)" />
                     </div>
                 </div>

                 <div class="p-3 bg-gray-900/50 rounded-lg border border-gray-800 space-y-4">
                     <!-- TRANSITION TYPE -->
                     <div class="flex items-center justify-between">
                         <label class="text-[10px] uppercase font-bold text-gray-500">Effet</label>
                         <div class="flex bg-gray-900 rounded p-0.5 border border-gray-700">
                             <button 
                                v-for="t in [{l:'Fondu', v:'fade'}, {l:'Slide', v:'slide'}]" :key="t.v"
                                @click="updateField('transition', t.v)"
                                class="px-3 py-1 text-[10px] rounded transition-colors"
                                :class="(item.transition || 'fade') === t.v ? 'bg-primary-600 text-white' : 'text-gray-400 hover:text-gray-300'"
                             >
                                {{ t.l }}
                             </button>
                         </div>
                     </div>

                     <hr class="border-gray-800" />

                     <!-- TIMING CONTROLS -->
                     <div class="grid grid-cols-2 gap-4">
                        <div class="space-y-1">
                            <div class="flex justify-between">
                                <label class="text-[10px] text-gray-400">Vitesse Anim.</label>
                                <span class="text-[10px] font-mono text-primary-400">{{ (item.duration || 800) }}ms</span>
                            </div>
                            <URange 
                                :model-value="item.duration || 800" 
                                @update:model-value="(v) => updateField('duration', v)"
                                :min="200" :max="3000" :step="100" size="xs"
                            />
                        </div>
                        <div class="space-y-1">
                            <div class="flex justify-between">
                                <label class="text-[10px] text-gray-400">Temps d'Arrêt</label>
                                <span class="text-[10px] font-mono text-primary-400">{{ (item.stop_time ?? 3000) }}ms</span>
                            </div>
                            <URange 
                                :model-value="item.stop_time ?? 3000" 
                                @update:model-value="(v) => updateField('stop_time', v)"
                                :min="0" :max="10000" :step="500" size="xs"
                            />
                        </div>
                     </div>

                     <!-- EASING EDITOR -->
                     <div class="space-y-2">
                        <label class="text-[10px] uppercase font-bold text-gray-500">Courbe d'Accélération (Easing)</label>
                        <AdminBezierEditor 
                            :model-value="item.ease || '0.25,0.1,0.25,1.0'"
                            @update:model-value="(v) => updateField('ease', v)"
                        />
                     </div>

                     <!-- SLIDE DIRECTION -->
                     <div v-if="item.transition === 'slide'" class="space-y-1 pt-2 border-t border-gray-800">
                         <label class="text-[10px] text-gray-400">Direction du Slide</label>
                         <div class="grid grid-cols-4 gap-1">
                             <button
                                v-for="dir in ['left', 'right', 'top', 'bottom']"
                                :key="dir"
                                @click="updateField('slide_direction', dir)"
                                class="py-1 text-[10px] border border-gray-700 rounded hover:bg-gray-800 transition-colors capitalize"
                                :class="(item.slide_direction || 'left') === dir ? 'bg-primary-500/20 border-primary-500 text-white' : 'text-gray-500'"
                             >
                                 {{ {left:'Gauche', right:'Droite', top:'Haut', bottom:'Bas'}[dir] }}
                             </button>
                         </div>
                     </div>
                 </div>
             </div>
        </div>
    </div>
</template>
