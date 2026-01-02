<script setup lang="ts">
const client = useSupabaseClient()
const toast = useToast()

// Define Page interface
interface Page {
    id: string
    title: string
    slug: string
    is_published: boolean
    order_index: number
    created_at: string
}

const columns = [
  { key: 'title', label: 'Titre' },
  { key: 'slug', label: 'Slug (URL)' },
  { key: 'status', label: 'État' },
  { key: 'actions', label: 'Actions' }
]

const { data: pages, refresh } = await useAsyncData<Page[]>('admin-pages-list', async () => {
    const { data } = await client
        .from('pages')
        .select('*')
        .order('order_index')
    return data as Page[]
})

// CRUD State
const isModalOpen = ref(false)
const state = reactive({
    title: '',
    slug: '',
    is_published: true
})

// Form Handling
const openCreateModal = () => {
    state.title = ''
    state.slug = ''
    state.is_published = true
    isModalOpen.value = true
}

const createPage = async () => {
    console.log('📝 createPage called', state)
    if (!state.title || !state.slug) {
        console.warn('Missing title or slug')
        return
    }

    try {
        console.log('🚀 Inserting into DB...')
        const { data, error } = await client.from('pages').insert({
            title: state.title,
            slug: state.slug.toLowerCase().replace(/\s+/g, '-'), // Basic slugify
            is_published: state.is_published
        }).select()
        
        console.log('✅ DB result:', { data, error })

        if (error) throw error

        toast.add({ title: 'Succès', description: 'Page créée avec succès.' })
        isModalOpen.value = false
        refresh()
    } catch (e: any) {
        console.error('💥 Create Page failed:', e)
        toast.add({ title: 'Erreur', description: e.message || 'Erreur inconnue', color: 'red' })
    }
}

const deletePage = async (id: string) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette page ?')) return

    try {
        const { error } = await client.from('pages').delete().eq('id', id)
        if (error) throw error
        refresh()
        toast.add({ title: 'Supprimée', description: 'Page supprimée.' })
    } catch (e: any) {
         toast.add({ title: 'Erreur', description: e.message, color: 'red' })
    }
}

const navigateToEditor = (slug: string) => {
    navigateTo(`/admin/editor?slug=${slug}`)
}
</script>

<template>
    <div class="container mx-auto p-8 max-w-5xl">
        <div class="flex items-center justify-between mb-8">
             <div>
                <h1 class="text-3xl font-bold mb-2">Structure du Site</h1>
                <p class="text-gray-500">Gérez les pages et leur organisation.</p>
            </div>
            <UButton icon="i-heroicons-plus" size="lg" color="primary" @click="openCreateModal">
                Nouvelle Page
            </UButton>
        </div>
        
        <!-- Pages Table -->
        <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden shadow-sm">
             <UTable :rows="pages || []" :columns="columns">
                 <template #title-data="{ row }">
                     <span class="font-bold text-gray-900 dark:text-white">{{ row.title }}</span>
                 </template>
                 
                 <template #slug-data="{ row }">
                     <UBadge color="gray" variant="soft" size="xs">/{{ row.slug }}</UBadge>
                 </template>

                 <template #status-data="{ row }">
                     <UBadge :color="row.is_published ? 'green' : 'orange'" variant="subtle" size="xs">
                         {{ row.is_published ? 'Publiée' : 'Brouillon' }}
                     </UBadge>
                 </template>

                 <template #actions-data="{ row }">
                     <div class="flex gap-2 justify-end">
                         <UButton size="xs" color="gray" variant="ghost" icon="i-heroicons-pencil-square" @click="navigateToEditor(row.slug)">
                             Éditer le contenu
                         </UButton>
                          <UButton size="xs" color="red" variant="ghost" icon="i-heroicons-trash" @click="deletePage(row.id)" />
                     </div>
                 </template>
             </UTable>

             <div v-if="!pages?.length" class="p-8 text-center text-gray-500">
                 Aucune page trouvée.
             </div>
        </div>

        <!-- Create Modal -->
        <UModal v-model="isModalOpen">
            <div class="p-6 space-y-4">
                <h3 class="text-lg font-bold">Créer une nouvelle page</h3>
                
                <UFormGroup label="Titre de la page">
                    <UInput v-model="state.title" placeholder="Ex: Contact, Services..." autofocus />
                </UFormGroup>
                
                <UFormGroup label="Slug (URL)" help="Identifiant unique pour l'URL (ex: contact)">
                    <UInput v-model="state.slug" placeholder="contact" />
                </UFormGroup>

                 <UFormGroup>
                    <UCheckbox v-model="state.is_published" label="Publier immédiatement" />
                </UFormGroup>

                <div class="flex justify-end gap-2 pt-4">
                    <UButton color="gray" variant="ghost" @click="isModalOpen = false">Annuler</UButton>
                    <UButton color="primary" @click="createPage">Créer</UButton>
                </div>
            </div>
        </UModal>
    </div>
</template>
