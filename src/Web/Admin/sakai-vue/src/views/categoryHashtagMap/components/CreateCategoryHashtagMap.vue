<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import CategoryService from '@/service/CategoryService';
import HashtagService from '@/service/HashtagService';

const categoryService = new CategoryService(request);
const hashtagService = new HashtagService(request);

const props = defineProps({
    categoryHashtagMap: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    categoryId: null,
    hashtagId: null
};

const form = ref({ ...initial });
const loading = ref(false);

const categoryOptions = ref([]);
const categoryLoading = ref(false);
const hashtagOptions = ref([]);
const hashtagLoading = ref(false);

watch(
    () => props.categoryHashtagMap,
    (newMap) => {
        if (newMap) {
            form.value = { ...newMap };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.categoryHashtagMap?.id);

async function loadCategories() {
    categoryLoading.value = true;
    try {
        const data = await categoryService.getLookup({});
        categoryOptions.value = (data.viewModels || []).map(c => ({
            label: `${c.title} (ID: ${c.categoryId || c.id})`,
            value: c.categoryId || c.id
        }));
    } catch (err) {
        console.error('Category load error:', err);
    } finally {
        categoryLoading.value = false;
    }
}

async function loadHashtags() {
    hashtagLoading.value = true;
    try {
        const data = await hashtagService.getLookup({});
        hashtagOptions.value = (data.viewModels || []).map(h => ({
            label: `${h.hashtagName} (ID: ${h.hashtagId})`,
            value: h.hashtagId
        }));
    } catch (err) {
        console.error('Hashtag load error:', err);
    } finally {
        hashtagLoading.value = false;
    }
}

onMounted(() => {
    loadCategories();
    loadHashtags();
});

async function submit() {
    if (form.value.categoryId === null || form.value.categoryId === undefined || form.value.categoryId <= 0) {
        return;
    }
    if (form.value.hashtagId === null || form.value.hashtagId === undefined || form.value.hashtagId <= 0) {
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
        console.error('CategoryHashtagMap submit error:', err);
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
                <label for="categoryId">Category</label>
                <Dropdown 
                    id="categoryId" 
                    v-model="form.categoryId" 
                    :options="categoryOptions" 
                    optionLabel="label" 
                    optionValue="value"
                    placeholder="Select Category"
                    :loading="categoryLoading"
                    filter
                    class="w-full"
                />
                <Message v-if="form.categoryId === null || form.categoryId === undefined || form.categoryId <= 0" size="small" severity="error" variant="simple">
                    Category is required.
                </Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="hashtagId">Hashtag</label>
                <Dropdown 
                    id="hashtagId" 
                    v-model="form.hashtagId" 
                    :options="hashtagOptions" 
                    optionLabel="label" 
                    optionValue="value"
                    placeholder="Select Hashtag"
                    :loading="hashtagLoading"
                    filter
                    class="w-full"
                />
                <Message v-if="form.hashtagId === null || form.hashtagId === undefined || form.hashtagId <= 0" size="small" severity="error" variant="simple">
                    Hashtag is required.
                </Message>
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? 'Update' : 'Create'" />
            </div>
        </form>
    </div>
</template>

