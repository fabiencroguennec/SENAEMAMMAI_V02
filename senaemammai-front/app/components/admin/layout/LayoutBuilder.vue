<script setup lang="ts">
import draggable from 'vuedraggable'
import LayoutRow from './LayoutRow.vue'

const props = defineProps<{
    modelValue: any
}>()

const emit = defineEmits(['update:modelValue'])

// Simple ID Generator
const generateId = () => Date.now().toString(36) + Math.random().toString(36).substr(2)

// Local State for Immediate UI Updates and Stability
const localRows = ref<any[]>([])
const initialized = ref(false)

onMounted(() => {
    console.log('🏁 [LayoutBuilder] MOUNTED. ID:', generateId())
})

onUnmounted(() => {
    console.log('👋 [LayoutBuilder] UNMOUNTED.')
})

// Sync Props -> Local (only if different to prevent loops)
// Sync Props -> Local (Only on Init or Section Change)
// Helper to emit updates
const emitUpdate = (rows: any[]) => {
    emit('update:modelValue', {
        ...props.modelValue,
        rows: rows,
        modules: undefined // Clear legacy
    })
}

const initializeLocalRows = (val: any) => {
    const rows = val?.rows || []
    localRows.value = rows
    
    // Handling Legacy Migration
    if ((!val?.rows || val.rows.length === 0) && val?.modules?.length > 0) {
        console.log('🔄 Migrating Legacy Modules')
        const migratedRow = {
             id: generateId(),
             settings: { gap: '4', padding: 'y-8' },
             columns: [{ id: generateId(), span: 12, modules: [...val.modules] }]
        }
        localRows.value = [migratedRow]
        emitUpdate(localRows.value)
    }
    initialized.value = true
}

// Sync Props -> Local (Only on Init or Section Change)
watch(() => props.modelValue, (val) => {
    // If NOT initialized, load data.
    if (!initialized.value) {
        console.log('🚀 [LayoutBuilder] Initializing Local State from Props')
        initializeLocalRows(val)
        return
    }
    // If initialized, we IGNORE prop updates.
}, { immediate: true, deep: true })



// Layout Accessor
const layout = computed({
    get: () => localRows.value,
    set: (val) => {
        localRows.value = val
        emitUpdate(val)
    }
})

const addRow = () => {
    const newRow = {
        id: generateId(),
        settings: { gap: '4', padding: 'y-4' },
        columns: [
             { id: generateId(), span: 12, modules: [] } // span 12 default
        ]
    }
    layout.value = [...layout.value, newRow]
}

const updateRow = (index: number, newRow: any) => {
    const newLayout = [...layout.value]
    newLayout[index] = newRow
    layout.value = newLayout
}

const removeRow = (index: number) => {
    if(!confirm('Supprimer cette rangée ?')) return
    const newLayout = [...layout.value]
    newLayout.splice(index, 1)
    layout.value = newLayout
}

const handlePreset = (rowIndex: number, colSpans: number[]) => {
    console.log(`🚀 [LayoutBuilder] Applying Preset: ${colSpans.join('/')} to Row ${rowIndex}`)
    
    // ATOMIC UPDATE on Local State (Source of Truth)
    const row = JSON.parse(JSON.stringify(localRows.value[rowIndex]))
    
    // 1. Map existing modules to new columns structure
    const existingCols = row.columns || []
    
    // Create new columns
    const newColumns = colSpans.map((span, i) => {
        const existingCol = existingCols[i]
        const mods = existingCol ? (existingCol.modules || []) : []
        console.log(`   - New Col ${i} gets ${mods.length} modules from Old Col ${i}`)
        return {
            id: generateId(),
            span: span,
            modules: mods
        }
    })
    
    // 2. Handle Overflow (3 -> 2 cols)
    let overflowModules: any[] = []
    if (existingCols.length > newColumns.length) {
        for (let i = newColumns.length; i < existingCols.length; i++) {
             const cols = existingCols[i]?.modules || []
             if (cols.length > 0) {
                 console.log(`   - ⚠️ Overflow found in Old Col ${i}: ${cols.length} modules moving to last column.`)
                 overflowModules = [...overflowModules, ...cols]
             }
        }
    }
    
    if (overflowModules.length > 0 && newColumns.length > 0) {
        const lastIndex = newColumns.length - 1
        // Safety initialization
        if (!newColumns[lastIndex].modules) newColumns[lastIndex].modules = []
        newColumns[lastIndex].modules = [...newColumns[lastIndex].modules, ...overflowModules]
        console.log(`   - ✅ Appended ${overflowModules.length} overflow modules to Col ${lastIndex}`)
    }
    
    // 3. Safety Check
    const oldTotal = existingCols.reduce((acc: number, c: any) => acc + (c?.modules?.length || 0), 0)
    const newTotal = newColumns.reduce((acc: number, c: any) => acc + (c?.modules?.length || 0), 0)
    
    console.log(`   - 📊 Count Check: Old=${oldTotal} vs New=${newTotal}`)
    
    if (oldTotal !== newTotal) {
        console.error('FATAL ERROR: Module count mismatch during layout change!', oldTotal, 'vs', newTotal)
        alert('Erreur critique: Risque de perte de données. Annulation.')
        return
    }

    // 4. Update Local State
    const newLayout = [...localRows.value]
    newLayout[rowIndex] = { ...row, columns: newColumns }
    layout.value = newLayout
}

const handleColumnUpdate = (rowIndex: number, payload: { index: number, column: any }) => {
    // ATOMIC Column Update
    const newLayout = [...localRows.value]
    const row = { ...newLayout[rowIndex] }
    const columns = [...row.columns]
    
    // Update specific column
    columns[payload.index] = payload.column
    
    // Save back
    row.columns = columns
    newLayout[rowIndex] = row
    
    // Commit
    layout.value = newLayout
}
</script>

<template>
    <div class="space-y-8 relative">
        <!-- Render Rows -->
        <draggable 
            v-model="layout" 
            item-key="id"
            handle=".drag-handle"
            class="space-y-6"
            :animation="200"
            ghost-class="opacity-50"
        >
            <template #item="{ element, index }">
                <LayoutRow 
                    :row="element" 
                    :index="index"
                    @update="(v) => updateRow(index, v)"
                    @remove="() => removeRow(index)"
                    @preset="(cols) => handlePreset(index, cols)"
                    @update:column="(p) => handleColumnUpdate(index, p)"
                />
            </template>
        </draggable>
        
        <!-- Empty State / Add Row -->
        <div v-if="layout.length === 0" class="text-center py-12 border-2 border-dashed border-gray-800 rounded-xl">
            <p class="text-gray-500 mb-4">La section est vide.</p>
            <UButton size="lg" icon="i-heroicons-plus" color="primary" @click="addRow">Ajouter une rangée</UButton>
        </div>
        
        <div v-else class="text-center pt-4">
             <UButton size="sm" icon="i-heroicons-plus" color="gray" variant="ghost" @click="addRow">Ajouter une rangée</UButton>
        </div>
    </div>
</template>
