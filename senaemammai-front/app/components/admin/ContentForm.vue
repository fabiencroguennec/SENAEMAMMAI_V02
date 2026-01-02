<script setup lang="ts">
const props = defineProps<{
    modelValue: any
    componentType: string
}>()

const emit = defineEmits(['update:modelValue'])

// Local copy of data to avoid direct mutation/reactivity loops
const localData = computed({
    get: () => props.modelValue || {},
    set: (val) => emit('update:modelValue', val)
})

// Update a specific field
const updateField = (key: string, value: any) => {
    const newData = { ...localData.value, [key]: value }
    emit('update:modelValue', newData)
}
</script>

<template>
    <div class="space-y-6">
        
        <!-- HERO SECTION FORM -->
        <template v-if="componentType === 'HeroSection'">
            <UFormGroup label="Titre Principal" help="Le texte le plus visible de la section.">
                <UInput 
                    :model-value="localData.title" 
                    @update:model-value="(v) => updateField('title', v)"
                    size="lg"
                    placeholder="Ex: Bienvenue chez Senaemammai"
                />
            </UFormGroup>

            <UFormGroup label="Sous-titre / Accroche" help="Une phrase courte descriptive.">
                <UTextarea 
                    :model-value="localData.subtitle" 
                    @update:model-value="(v) => updateField('subtitle', v)"
                    :rows="2"
                    placeholder="Ex: Agrotourisme en Sardaigne..."
                />
            </UFormGroup>

            <div class="grid grid-cols-2 gap-4">
                <UFormGroup label="Texte du Bouton (CTA)">
                    <UInput 
                        :model-value="localData.ctaText" 
                        @update:model-value="(v) => updateField('ctaText', v)"
                        placeholder="Ex: Réserver"
                        icon="i-heroicons-cursor-arrow-rays"
                    />
                </UFormGroup>
                
                <UFormGroup label="Lien du Bouton">
                    <UInput 
                        :model-value="localData.ctaLink" 
                        @update:model-value="(v) => updateField('ctaLink', v)"
                        placeholder="Ex: /reservation"
                        icon="i-heroicons-link"
                    />
                </UFormGroup>
            </div>
            
            <UFormGroup label="URL de l'image de fond" help="Utilisez l'uploader ci-dessus ou collez une URL.">
                <UInput 
                    :model-value="localData.imageUrl" 
                    @update:model-value="(v) => updateField('imageUrl', v)"
                    placeholder="https://..."
                    icon="i-heroicons-photo"
                />
            </UFormGroup>
        </template>

        <!-- PRODUCT GRID FORM -->
        <template v-else-if="componentType === 'ProductGrid'">
             <UFormGroup label="Titre de la section">
                <UInput 
                    :model-value="localData.title" 
                    @update:model-value="(v) => updateField('title', v)"
                    size="lg"
                    placeholder="Ex: Nos Produits Phares"
                />
            </UFormGroup>

            <UFormGroup label="Sous-titre">
                <UTextarea 
                    :model-value="localData.subtitle" 
                    @update:model-value="(v) => updateField('subtitle', v)"
                    :rows="2"
                    placeholder="Une brève description..."
                />
            </UFormGroup>

            <UFormGroup label="Nombre de produits à afficher">
                 <div class="flex items-center gap-4">
                    <URange 
                        :model-value="Number(localData.limit || 3)" 
                        @update:model-value="(v) => updateField('limit', v)"
                        :min="1" 
                        :max="12" 
                        :step="1" 
                        class="flex-1" 
                    />
                    <span class="font-mono bg-gray-800 px-2 py-1 rounded text-primary-400">{{ localData.limit || 3 }}</span>
                </div>
            </UFormGroup>
        </template>

        <!-- GENERIC / UNKNOWN COMPONENT FORM -->
        <template v-else>
             <UAlert
                icon="i-heroicons-code-bracket"
                color="gray"
                variant="soft"
                title="Composant Générique"
                description="Ce composant n'a pas de formulaire dédié. Utilisez l'éditeur JSON ci-dessous."
            />
            <UTextarea 
                :model-value="JSON.stringify(localData, null, 2)"
                @update:model-value="(v) => {
                    try { emit('update:modelValue', JSON.parse(v)) } catch(e) {}
                }"
                :rows="15"
                font-family="font-mono"
            />
        </template>

    </div>
</template>
