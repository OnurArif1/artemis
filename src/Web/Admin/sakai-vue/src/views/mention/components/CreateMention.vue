<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import RoomService from '@/service/RoomService';

const roomService = new RoomService(request);

const props = defineProps({
    mention: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    roomId: null,
    messageId: null,
    commentId: null,
    topicId: null
};

const form = ref({ ...initial });
const loading = ref(false);

const roomOptions = ref([]);
const roomLoading = ref(false);

watch(
    () => props.mention,
    (newMention) => {
        if (newMention) {
            form.value = { ...newMention };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.mention?.id);

async function loadRooms() {
    roomLoading.value = true;
    try {
        const data = await roomService.getList({ pageIndex: 1, pageSize: 100 });
        roomOptions.value = (data.resultViewmodels || []).map(r => ({
            label: `${r.title || 'Room'} (ID: ${r.id})`,
            value: r.id
        }));
    } catch (err) {
        console.error('Room load error:', err);
    } finally {
        roomLoading.value = false;
    }
}

onMounted(() => {
    loadRooms();
});

function normalizeId(value) {
    return value && value > 0 ? value : null;
}

async function submit() {
    loading.value = true;
    try {
        // 0, null, undefined veya negatif değerleri null'a çevir (optional alanlar için)
        const payload = {
            id: isEditMode.value ? form.value.id : null,
            roomId: normalizeId(form.value.roomId),
            messageId: normalizeId(form.value.messageId),
            commentId: normalizeId(form.value.commentId),
            topicId: normalizeId(form.value.topicId)
        };

        console.log('Submitting Mention payload:', payload);

        if (isEditMode.value) {
            emit('updated', payload);
        } else {
            emit('created', payload);
        }
        form.value = { ...initial };
    } catch (err) {
        console.error('Mention submit error:', err);
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
                <label for="roomId">Room (Optional)</label>
                <Dropdown 
                    id="roomId" 
                    v-model="form.roomId" 
                    :options="roomOptions" 
                    optionLabel="label" 
                    optionValue="value"
                    placeholder="Select Room (Optional)"
                    :loading="roomLoading"
                    filter
                    class="w-full"
                    :showClear="true"
                />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="messageId">Message Id (Optional)</label>
                <InputNumber id="messageId" v-model="form.messageId" :min="1" :showButtons="true" class="w-full" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="commentId">Comment Id (Optional)</label>
                <InputNumber id="commentId" v-model="form.commentId" :min="1" :showButtons="true" class="w-full" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="topicId">Topic Id (Optional)</label>
                <InputNumber id="topicId" v-model="form.topicId" :min="1" :showButtons="true" class="w-full" />
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? 'Update' : 'Create'" />
            </div>
        </form>
    </div>
</template>

