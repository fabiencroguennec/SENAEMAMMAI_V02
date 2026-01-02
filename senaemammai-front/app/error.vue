<script setup lang="ts">
import type { NuxtError } from '#app'

const props = defineProps({
  error: Object as () => NuxtError
})

const handleError = () => clearError({ redirect: '/' })

const toast = useToast()

const copyErrorToClipboard = async () => {
  if (!props.error) return
  
  const errorDetails = `
Error: ${props.error.statusCode} - ${props.error.message}
Stack:
${props.error.stack || 'No stack trace available'}
  `.trim()

  try {
    await navigator.clipboard.writeText(errorDetails)
    toast.add({ title: 'Copié !', description: 'Les détails de l\'erreur sont dans le presse-papier.', color: 'green' })
  } catch (err) {
    // Fallback for older browsers or non-secure contexts
    const textArea = document.createElement("textarea")
    textArea.value = errorDetails
    document.body.appendChild(textArea)
    textArea.select()
    try {
      document.execCommand('copy')
      toast.add({ title: 'Copié !', description: 'Les détails de l\'erreur sont dans le presse-papier.', color: 'green' })
    } catch (e) {
      console.error('Copy failed', e)
      toast.add({ title: 'Erreur', description: 'Impossible de copier l\'erreur automatiquement.', color: 'red' })
    }
    document.body.removeChild(textArea)
  }
}
</script>

<template>
  <div class="min-h-screen flex flex-col items-center justify-center bg-gray-900 text-white p-6">
    <div class="max-w-3xl w-full bg-gray-800 rounded-lg shadow-2xl overflow-hidden border border-gray-700">
      
      <!-- Header -->
      <div class="bg-red-900/50 p-6 border-b border-red-900/50 flex items-center gap-4">
        <div class="bg-red-500 rounded-full p-3">
            <span class="text-3xl">⚠️</span>
        </div>
        <div>
            <h1 class="text-3xl font-bold text-red-100">Une erreur est survenue</h1>
            <p class="text-red-200 text-lg mt-1">{{ error?.statusCode }}</p>
        </div>
      </div>

      <!-- Content -->
      <div class="p-8">
        <p class="text-xl font-medium mb-6 text-gray-200">{{ error?.message }}</p>
        
        <!-- Stack Trace Box -->
        <div v-if="error?.stack" class="mb-8">
            <div class="flex justify-between items-center mb-2">
                <span class="text-sm text-gray-400 uppercase tracking-wider font-bold">Détails techniques</span>
            </div>
            <pre class="bg-black/50 p-4 rounded text-sm font-mono text-gray-400 overflow-x-auto whitespace-pre-wrap border border-gray-700 h-64 overflow-y-auto custom-scrollbar">{{ error?.stack }}</pre>
        </div>

        <!-- Actions -->
        <div class="flex flex-col sm:flex-row gap-4 pt-4 border-t border-gray-700">
          <UButton 
            size="xl"
            color="white"
            variant="solid" 
            @click="handleError"
            icon="i-heroicons-home"
          >
            Retour à l'accueil
          </UButton>

          <UButton 
            size="xl"
            color="primary"
            variant="soft" 
            @click="copyErrorToClipboard"
            icon="i-heroicons-clipboard"
            class="flex-1 justify-center"
          >
            Copier l'erreur
          </UButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 8px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: #1f2937; 
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #4b5563; 
  border-radius: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #6b7280; 
}
</style>
