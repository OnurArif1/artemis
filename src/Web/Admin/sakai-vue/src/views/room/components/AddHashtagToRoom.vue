<script setup>
import { ref, watch, onMounted } from 'vue';
import request from '@/service/request';
import HashtagService from '@/service/HashtagService';

const hashtagService = new HashtagService(request);

const props = defineProps({
    room: {
        type: Object,
        default: null
    }
});

const initial = {
    hashtagId: null,
    roomId: props.room?.id || null
};

const emit = defineEmits(['addHashtagToRoom', 'cancel']);
const form = ref({ ...initial });
const loading = ref(false);
const hashtagLoading = ref(false);
const hashtagOptions = ref([]);

async function getHashtagLookup(filterText = '') {
    const filter = {
        searchText: filterText || ''
    };

    try {
        hashtagLoading.value = true;
        const response = await hashtagService.getLookup(filter);

        hashtagOptions.value = response?.viewModels.map((h) => ({
            label: `${h.hashtagName}`,
            value: h.hashtagId
        }));
    } catch (error) {
        console.error('Hashtag lookup error:', error);
        hashtagOptions.value = [];
    } finally {
        hashtagLoading.value = false;
    }
}

function onHashtagFilter(event) {
    const filterValue = event.value?.trim() ?? '';
    getHashtagLookup(filterValue);
}

onMounted(() => {
    getHashtagLookup();
});

watch(
    () => props.room,
    (newRoom) => {
        if (newRoom) {
            form.value = { ...newRoom };
            form.value.roomId = newRoom.id;
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

async function submit() {
    if (!form.value.hashtagId) {
        return;
    }
    
    loading.value = true;
    try {
        emit('addHashtagToRoom', { ...form.value });
        form.value = { ...initial, roomId: props.room?.id || null };
    } catch (err) {
        console.error('Add Hashtag to Room submit error:', err);
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
                <label for="hashtagId">Hashtag</label>
                <Dropdown id="hashtagId" v-model="form.hashtagId" :options="hashtagOptions" option-label="label" option-value="value" placeholder="Select a Hashtag" :loading="hashtagLoading" filter @filter="onHashtagFilter" class="w-full" />
            </div>
            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" label="Add Hashtag To Room" />
            </div>
        </form>
    </div>
</template>

