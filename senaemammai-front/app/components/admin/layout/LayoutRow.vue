<script setup lang="ts">
import draggable from 'vuedraggable'
import LayoutColumn from './LayoutColumn.vue'

const props = defineProps<{
    row: any
    index: number
}>()

const emit = defineEmits(['update', 'remove', 'preset', 'update:column'])

// Utils
const generateId = () => Date.now().toString(36) + Math.random().toString(36).substr(2)

// Grid Presets ... (unchanged)

// Delegating Logic to Parent (Source of Truth)
const applyPreset = (colSpans: number[]) => {
    emit('preset', colSpans)
}

const updateColumn = (colIndex: number, newCol: any) => {
    // Pure Pass-Through to Parent (Prevent Stale Prop Merge)
    emit('update:column', { index: colIndex, column: newCol })
}

const rowStyle = computed(() => {
    const s = props.row.settings || {}
    return {
        paddingTop: s.padding === 'none' ? '0' : s.padding === 'y-8' ? '2rem' : '4rem',
        paddingBottom: s.padding === 'none' ? '0' : s.padding === 'y-8' ? '2rem' : '4rem',
        gap: s.gap === '0' ? '0' : s.gap === '4' ? '1rem' : '2rem'
    }
})
// Grid Utilities for Tailwind JIT
const getSpanClass = (span: number) => {
    const classes: Record<number, string> = {
        1: 'md:col-span-1', 2: 'md:col-span-2', 3: 'md:col-span-3',
        4: 'md:col-span-4', 5: 'md:col-span-5', 6: 'md:col-span-6',
        7: 'md:col-span-7', 8: 'md:col-span-8', 9: 'md:col-span-9',
        10: 'md:col-span-10', 11: 'md:col-span-11', 12: 'md:col-span-12'
    }
    return classes[span] || 'md:col-span-12'
}
</script>

<template>
    <div class="border border-gray-700 rounded-xl bg-gray-900 overflow-hidden shadow-sm hover:shadow-md transition-shadow">
        <!-- Row Header / Controls -->
        <div class="bg-gray-800 border-b border-gray-700 p-2 flex items-center justify-between gap-4">
            <div class="flex items-center gap-2">
                <div class="drag-handle cursor-move text-gray-500 hover:text-white p-1 rounded hover:bg-gray-700">
                    <UIcon name="i-heroicons-bars-2" class="w-5 h-5 transform rotate-90" />
                </div>
                <span class="text-xs font-bold text-gray-500 uppercase tracking-wider">Rangée</span>
            </div>
            
            <!-- Grid Presets -->
            <div class="flex items-center gap-1 bg-gray-900 rounded p-1">
                 <UTooltip text="1 Colonne" :open-delay="500">
                    <button @click="applyPreset([12])" class="p-1 rounded hover:bg-gray-700 text-gray-500 hover:text-white" :class="row.columns.length === 1 ? 'text-primary-400 bg-gray-800' : ''">
                        <UIcon name="i-heroicons-stop" />
                    </button>
                 </UTooltip>
                 <UTooltip text="2 Colonnes (50/50)" :open-delay="500">
                    <button @click="applyPreset([6, 6])" class="p-1 rounded hover:bg-gray-700 text-gray-500 hover:text-white" :class="row.columns.length === 2 && row.columns[0].span === 6 ? 'text-primary-400 bg-gray-800' : ''">
                        <UIcon name="i-heroicons-view-columns" />
                    </button>
                 </UTooltip>
                 <UTooltip text="3 Colonnes (33/33/33)" :open-delay="500">
                    <button @click="applyPreset([4, 4, 4])" class="p-1 rounded hover:bg-gray-700 text-gray-500 hover:text-white" :class="row.columns.length === 3 ? 'text-primary-400 bg-gray-800' : ''">
                         <UIcon name="i-heroicons-table-cells" />
                    </button>
                 </UTooltip>
                 <UTooltip text="2 Colonnes (66/33)" :open-delay="500">
                    <button @click="applyPreset([8, 4])" class="p-1 rounded hover:bg-gray-700 text-gray-500 hover:text-white" :class="row.columns.length === 2 && row.columns[0].span === 8 ? 'text-primary-400 bg-gray-800' : ''">
                        <UIcon name="i-heroicons-camera" />
                    </button>
                 </UTooltip>
            </div>

            <!-- Settings & Delete -->
            <div class="flex items-center gap-1">
                 <UPopover mode="click">
                    <UButton color="gray" variant="ghost" icon="i-heroicons-adjustments-horizontal" size="xs" />
                    <template #panel>
                        <div class="p-4 space-y-4 w-64 bg-gray-900 border border-gray-700">
                            <h4 class="text-xs font-bold text-gray-400 uppercase">Style de la rangée</h4>
                            <UFormGroup label="Ecartement (Gap)">
                                <USelect 
                                    :model-value="row.settings.gap" 
                                    :options="['0', '4', '8']"
                                    @update:model-value="(v) => emit('update', { ...row, settings: { ...row.settings, gap: v } })"
                                    size="xs"
                                />
                            </UFormGroup>
                            <UFormGroup label="Padding Vertical">
                                <USelect 
                                    :model-value="row.settings.padding" 
                                    :options="['none', 'y-4', 'y-8', 'y-12']"
                                    @update:model-value="(v) => emit('update', { ...row, settings: { ...row.settings, padding: v } })"
                                    size="xs"
                                />
                            </UFormGroup>
                        </div>
                    </template>
                 </UPopover>

                 <UButton color="red" variant="ghost" icon="i-heroicons-trash" size="xs" @click="$emit('remove')" />
            </div>
        </div>

        <!-- Columns Grid -->
        <div class="p-2 bg-gray-950/50">
            <div class="grid grid-cols-12 gap-2 md:gap-4" :style="rowStyle">
                <LayoutColumn 
                    v-for="(col, i) in row.columns"
                    :key="col.id"
                    :col="col"
                    class="col-span-12"
                    :class="getSpanClass(col.span)"
                    @update="(v) => updateColumn(i, v)"
                />
            </div>
        </div>
    </div>
</template>
