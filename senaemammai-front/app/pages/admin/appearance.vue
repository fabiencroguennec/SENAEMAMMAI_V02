<script setup lang="ts">
import ThemeEditor from '~/components/admin/ThemeEditor.vue'

definePageMeta({
    layout: 'default'
})
</script>

<template>
    <div class="container mx-auto p-8 max-w-4xl">
        <h1 class="text-3xl font-bold mb-8">Apparence</h1>
        
        <div class="space-y-8">
            <div class="bg-white dark:bg-gray-900 p-6 rounded-xl border border-gray-200 dark:border-gray-800">
                <h2 class="text-xl font-bold mb-4">Thème Global</h2>
                <ThemeEditor />
            </div>
        </div>
    </div>
</template>
