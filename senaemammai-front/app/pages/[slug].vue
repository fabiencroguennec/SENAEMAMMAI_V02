<script setup lang="ts">
const route = useRoute()
const slug = computed(() => route.params.slug as string)

// Optional: Fetch page metadata for SEO (Head title, description)
const client = useSupabaseClient()

// Fetch Page Meta
const { data: page } = await useAsyncData('page-meta-' + slug.value, async () => {
    const { data } = await client.from('pages').select('*').eq('slug', slug.value).single()
    if (data) {
        useSeoMeta({
            title: data.seo_title || data.title,
            description: data.seo_description
        })
    }
    return data
}, { watch: [slug] })

// Fetch Sections for Schema (Lightweight, mainly for indexing)
const { data: sections } = await useAsyncData('page-sections-schema-' + slug.value, async () => {
    const { data } = await client.from('page_sections')
        .select('content_data, is_visible')
        .eq('page_slug', slug.value)
        .eq('is_visible', true)
        .order('order_index')
    return data
}, { watch: [slug] })

// Generate and Inject JSON-LD
const schema = usePageSchema(page.value, sections.value || [])
useHead({
    script: [
        {
            type: 'application/ld+json',
            innerHTML: computed(() => JSON.stringify(schema.value))
        }
    ]
})
</script>

<template>
  <div>
    <SectionBuilder :page-slug="slug" />
  </div>
</template>
