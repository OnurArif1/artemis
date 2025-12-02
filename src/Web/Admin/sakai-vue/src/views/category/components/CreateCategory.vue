<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from '@/composables/useI18n';

const { t } = useI18n();
const props = defineProps({
    category: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    title: ''
};

const form = ref({ ...initial });
const loading = ref(false);

watch(
    () => props.category,
    (newCategory) => {
        if (newCategory) {
            form.value = { ...newCategory };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.category?.id);

async function submit() {
    loading.value = true;
    try {
        if (isEditMode.value) {
            emit('updated', { ...form.value });
        } else {
            emit('created', { ...form.value });
        }
        form.value = { ...initial };
    } catch (err) {
        console.error('Category submit error:', err);
    } finally {
        loading.value = false;
    }
}

function cancel() {
    emit('cancel');
}
</script>

<template>
    <div>
        <form @submit.prevent="submit" class="card p-4">
            <div class="flex flex-col gap-2 mb-3">
                <label for="title">{{ t('category.titleLabel') }}</label>
                <InputText id="title" v-model="form.title" type="text" />
                <Message v-if="!form.title" size="small" severity="error" variant="simple">{{ t('category.titleRequired') }}</Message>
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" :label="t('common.cancel')" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? t('common.update') : t('common.create')" />
            </div>
        </form>
    </div>
</template>
