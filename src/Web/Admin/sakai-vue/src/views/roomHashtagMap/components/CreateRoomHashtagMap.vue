<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import HashtagService from '@/service/HashtagService';

const roomService = new RoomService(request);
const hashtagService = new HashtagService(request);

const props = defineProps({
    roomHashtagMap: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    roomId: null,
    hashtagId: null
};

const form = ref({ ...initial });
const loading = ref(false);

const roomOptions = ref([]);
const roomLoading = ref(false);
const hashtagOptions = ref([]);
const hashtagLoading = ref(false);

watch(
    () => props.roomHashtagMap,
    (newMap) => {
        if (newMap) {
            form.value = { ...newMap };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.roomHashtagMap?.id);

async function loadRooms() {
    roomLoading.value = true;
    try {
        const data = await roomService.getList({ pageIndex: 1, pageSize: 100 });
        roomOptions.value = (data.resultViewmodels || []).map((r) => ({
            label: `${r.title} (ID: ${r.id})`,
            value: r.id
        }));
    } catch (err) {
        console.error('Room load error:', err);
    } finally {
        roomLoading.value = false;
    }
}

async function loadHashtags() {
    hashtagLoading.value = true;
    try {
        const data = await hashtagService.getLookup({});
        hashtagOptions.value = (data.viewModels || []).map((h) => ({
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
    loadRooms();
    loadHashtags();
});

async function submit() {
    if (form.value.roomId === null || form.value.roomId === undefined || form.value.roomId <= 0) {
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
        console.error('RoomHashtagMap submit error:', err);
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
                <label for="roomId">Room</label>
                <Dropdown id="roomId" v-model="form.roomId" :options="roomOptions" optionLabel="label" optionValue="value" placeholder="Select Room" :loading="roomLoading" filter class="w-full" />
                <Message v-if="form.roomId === null || form.roomId === undefined || form.roomId <= 0" size="small" severity="error" variant="simple"> Room is required. </Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="hashtagId">Hashtag</label>
                <Dropdown id="hashtagId" v-model="form.hashtagId" :options="hashtagOptions" optionLabel="label" optionValue="value" placeholder="Select Hashtag" :loading="hashtagLoading" filter class="w-full" />
                <Message v-if="form.hashtagId === null || form.hashtagId === undefined || form.hashtagId <= 0" size="small" severity="error" variant="simple"> Hashtag is required. </Message>
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? 'Update' : 'Create'" />
            </div>
        </form>
    </div>
</template>
