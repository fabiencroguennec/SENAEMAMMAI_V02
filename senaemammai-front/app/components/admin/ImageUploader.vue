<script setup lang="ts">
const props = defineProps({
  bucket: {
    type: String,
    default: 'images'
  },
  path: {
    type: String,
    default: 'uploads'
  },
  accept: {
    type: String,
    default: 'image/*'
  },
  mini: {
    type: Boolean,
    default: false
  }
})

const client = useSupabaseClient()
const uploading = ref(false)
const toast = useToast()
const emit = defineEmits(['uploaded'])

const handleFileUpload = async (event: any) => {
    const file = event.target.files[0]
    if (!file) return

    uploading.value = true
    try {
        const fileExt = file.name.split('.').pop()
        const fileName = `${Math.random().toString(36).substring(2, 15)}.${fileExt}`
        const filePath = `${props.path}/${fileName}`

        const { error: uploadError } = await client.storage
            .from(props.bucket)
            .upload(filePath, file)

        if (uploadError) throw uploadError

        const { data: { publicUrl } } = client.storage
            .from(props.bucket)
            .getPublicUrl(filePath)

        emit('uploaded', publicUrl)
        toast.add({ title: 'Succès', description: 'Image téléversée avec succès', color: 'green' })
    } catch (error: any) {
        toast.add({ title: 'Erreur', description: error.message, color: 'red' })
    } finally {
        uploading.value = false
    }
}

</script>

<template>
  <div 
    class="border-2 border-dashed border-gray-700 bg-gray-800/50 rounded-lg text-center hover:bg-gray-800 hover:border-primary-500 transition-all cursor-pointer relative group"
    :class="mini ? 'p-2' : 'p-6'"
  >
    <input 
        type="file" 
        class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
        :accept="accept"
        @change="handleFileUpload"
        :disabled="uploading"
    />
    
    <div v-if="uploading" class="flex flex-col items-center justify-center py-2">
         <UIcon name="i-heroicons-arrow-path" class="animate-spin text-primary-400" :class="mini ? 'text-xl' : 'text-3xl'" />
         <span class="text-xs text-gray-300 mt-1" v-if="!mini">Envoi...</span>
    </div>
    
    <div v-else class="flex flex-col items-center justify-center pointer-events-none">
        <div class="bg-gray-700 rounded-full group-hover:bg-gray-600 transition-colors" :class="mini ? 'p-1.5 mb-1' : 'p-3 mb-3'">
            <UIcon name="i-heroicons-cloud-arrow-up" class="text-gray-300 group-hover:text-white" :class="mini ? 'text-sm' : 'text-2xl'" />
        </div>
        <span class="font-medium text-gray-300 group-hover:text-white transition-colors" :class="mini ? 'text-xs' : 'text-sm'">
            {{ mini ? 'Changer' : 'Glissez une image ici' }}
        </span>
        <span v-if="!mini" class="text-[10px] text-gray-500 mt-1 uppercase tracking-wide">Max 2MB</span>
    </div>
  </div>
</template>
