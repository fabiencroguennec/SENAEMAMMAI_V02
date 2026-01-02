<script setup lang="ts">
import draggable from 'vuedraggable'
import ModuleCard from './ModuleCard.vue'

const props = defineProps<{
    col: any
}>()

const emit = defineEmits(['update'])

// Update Modules List
const updateModules = (newModules: any[]) => {
    emit('update', { ...props.col, modules: newModules })
}

// Module Actions
const generateId = () => Date.now().toString(36) + Math.random().toString(36).substr(2)

const addModule = (type: 'text' | 'image' | 'grid') => {
    let data: any = {}
    if (type === 'text') data = { content: 'Nouveau contenu...', tag: 'p', align: 'left' }
    if (type === 'image') data = { src: '', fit: 'cover' }
    if (type === 'grid') data = { columns: { sm: 1, md: 2, lg: 3 }, items: [] }

    const newModule = {
        id: generateId(),
        type,
        data,
        config: { animation_type: 'none' }
    }
    
    updateModules([...(props.col.modules || []), newModule])
}

// Draggable Local Buffer to fix Cross-List Dragging
const localModules = ref([...(props.col.modules || [])])

// Sync Prop -> Local (Down)
watch(() => props.col.modules, (newVal) => {
   if (JSON.stringify(newVal) !== JSON.stringify(localModules.value)) {
       localModules.value = [...(newVal || [])]
   }
}, { deep: true })

// Sync Local -> Prop (Up)
// We use a function to emit, called by draggable @change or v-model setter
const syncUpdate = (val: any[]) => {
    localModules.value = val
    emit('update', { ...props.col, modules: val })
}

const modulesList = computed({
    get: () => localModules.value,
    set: (val) => syncUpdate(val)
})

// Clone to break reactivity chains during move
const cloneModule = (original: any) => {
    return JSON.parse(JSON.stringify(original))
}

const removeModule = (index: number) => {
    if(!confirm('Supprimer ce module ?')) return
    const newModules = [...localModules.value]
    newModules.splice(index, 1)
    syncUpdate(newModules)
}

// Module Update (Deep)
const updateModule = (index: number, updatedModule: any) => {
    const newModules = [...localModules.value]
    newModules[index] = updatedModule
    syncUpdate(newModules)
}
</script>

<template>
    <div class="h-full flex flex-col bg-gray-900/30 rounded-lg border border-dashed border-gray-800 hover:border-gray-700 transition-colors relative group">
        <!-- Visual Debug Header (Discreet) -->
        <div class="absolute -top-2 right-2 z-10">
             <span v-if="modulesList.length > 0" class="text-[9px] text-gray-400 font-bold bg-gray-900 border border-gray-700 px-1.5 py-0.5 rounded-md shadow-sm">{{ modulesList.length }}</span>
        </div>
        
        <!-- Draggable Area -->
        <draggable
            v-model="modulesList"
            :group="{ name: 'modules', pull: true, put: true }"
            item-key="id"
            class="flex-1 p-2 space-y-3 min-h-[100px]"
            ghost-class="opacity-50"
        >
            <template #item="{ element, index }">
                <ModuleCard 
                    :module="element" 
                    :index="index"
                    @update="(v) => updateModule(index, v)"
                    @remove="() => removeModule(index)"
                />
            </template>
        </draggable>

        <!-- Add Button (Bottom Overlay or Empty State) -->
        <div class="p-2 pt-0 flex justify-center opacity-50 group-hover:opacity-100 transition-opacity">
            <UPopover mode="click">
                <UButton size="2xs" color="gray" variant="soft" icon="i-heroicons-plus" label="Ajouter" />
                <template #panel>
                    <div class="p-2 grid grid-cols-1 gap-1 w-32 bg-gray-900 border border-gray-700">
                        <UButton size="xs" variant="ghost" color="white" icon="i-heroicons-document-text" label="Texte" @click="addModule('text')" />
                        <UButton size="xs" variant="ghost" color="white" icon="i-heroicons-photo" label="Image" @click="addModule('image')" />
                        <UButton size="xs" variant="ghost" color="white" icon="i-heroicons-squares-2x2" label="Grille" @click="addModule('grid')" />
                    </div>
                </template>
            </UPopover>
        </div>
        
    </div>
</template>
