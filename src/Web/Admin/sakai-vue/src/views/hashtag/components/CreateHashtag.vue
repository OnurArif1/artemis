<script setup>
import { ref, watch, computed } from 'vue';

const props = defineProps({
    hashtag: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    hashtagName: ''
};

const form = ref({ ...initial });
const loading = ref(false);

watch(
    () => props.hashtag,
    (newHashtag) => {
        if (newHashtag) {
            form.value = { ...newHashtag };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.hashtag?.id);

async function submit() {
    if (!form.value.hashtagName || form.value.hashtagName.trim() === '') {
        return;
    }
    
    loading.value = true;
    try {
        if (isEditMode.value) {
            emit('updated', { ...form.value });
        } else {
            emit('created', { ...form.value });
        }
        form.value = { ...initial };
    } catch (err) {
        console.error('Hashtag submit error:', err);
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
                <label for="hashtagName">Name</label>
                <InputText id="hashtagName" v-model="form.hashtagName" type="text" />
                <Message v-if="!form.hashtagName" size="small" severity="error" variant="simple">
                    Name is required.
                </Message>
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? 'Update' : 'Create'" />
            </div>
        </form>
    </div>
</template>

