<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import TopicService from '@/service/TopicService';
import HashtagService from '@/service/HashtagService';

const topicService = new TopicService(request);
const hashtagService = new HashtagService(request);

const props = defineProps({
    topicHashtagMap: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    topicId: null,
    hashtagId: null
};

const form = ref({ ...initial });
const loading = ref(false);

const topicOptions = ref([]);
const topicLoading = ref(false);
const hashtagOptions = ref([]);
const hashtagLoading = ref(false);

watch(
    () => props.topicHashtagMap,
    (newMap) => {
        if (newMap) {
            form.value = { ...newMap };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.topicHashtagMap?.id);

async function loadTopics() {
    topicLoading.value = true;
    try {
        const data = await topicService.getLookup({});
        topicOptions.value = (data.viewModels || []).map(t => ({
            label: `${t.title || 'Topic'} (ID: ${t.topicId})`,
            value: t.topicId
        }));
    } catch (err) {
        console.error('Topic load error:', err);
    } finally {
        topicLoading.value = false;
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
    loadTopics();
    loadHashtags();
});

async function submit() {
    if (form.value.topicId === null || form.value.topicId === undefined || form.value.topicId <= 0) {
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
        console.error('TopicHashtagMap submit error:', err);
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
                <label for="topicId">Topic</label>
                <Dropdown 
                    id="topicId" 
                    v-model="form.topicId" 
                    :options="topicOptions" 
                    optionLabel="label" 
                    optionValue="value"
                    placeholder="Select Topic"
                    :loading="topicLoading"
                    filter
                    class="w-full"
                />
                <Message v-if="form.topicId === null || form.topicId === undefined || form.topicId <= 0" size="small" severity="error" variant="simple">
                    Topic is required.
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

