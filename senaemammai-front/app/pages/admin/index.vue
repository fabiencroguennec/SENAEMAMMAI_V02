<script setup lang="ts">
definePageMeta({
    middleware: [
        function (to, from) {
            return navigateTo('/admin/pages')
        }
    ]
})
</script>
<template>
    <div>Redirecting...</div>
</template>
