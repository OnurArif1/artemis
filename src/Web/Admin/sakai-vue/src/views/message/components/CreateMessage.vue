<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import PartyService from '@/service/PartyService';
import { useI18n } from '@/composables/useI18n';

const { t } = useI18n();
const roomService = new RoomService(request);
const partyService = new PartyService(request);

const props = defineProps({
    message: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    roomId: 0,
    partyId: 0,
    upvote: 0,
    downvote: 0
};

const form = ref({ ...initial });
const loading = ref(false);

const roomOptions = ref([]);
const roomLoading = ref(false);
const partyOptions = ref([]);
const partyLoading = ref(false);

watch(
    () => props.message,
    (newMessage) => {
        if (newMessage) {
            form.value = { ...newMessage };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.message?.id);

async function loadRooms() {
    roomLoading.value = true;
    try {
        const data = await roomService.getList({ pageIndex: 1, pageSize: 100 });
        roomOptions.value = (data.resultViewmodels || []).map((r) => ({
            label: `${r.title || 'Room'} (ID: ${r.id})`,
            value: r.id
        }));
    } catch (err) {
        console.error('Room load error:', err);
    } finally {
        roomLoading.value = false;
    }
}

async function loadParties() {
    partyLoading.value = true;
    try {
        const data = await partyService.getList({ pageIndex: 1, pageSize: 100 });
        partyOptions.value = (data.resultViewmodels || []).map((p) => ({
            label: `${p.partyName || 'Party'} (ID: ${p.id})`,
            value: p.id
        }));
    } catch (err) {
        console.error('Party load error:', err);
    } finally {
        partyLoading.value = false;
    }
}

onMounted(() => {
    loadRooms();
    loadParties();
});

async function submit() {
    loading.value = true;
    try {
        const payload = {
            id: isEditMode.value ? form.value.id : null,
            roomId: form.value.roomId || 0,
            partyId: form.value.partyId || 0,
            upvote: form.value.upvote || 0,
            downvote: form.value.downvote || 0
        };

        console.log('Submitting Message payload:', payload);

        if (isEditMode.value) {
            emit('updated', payload);
        } else {
            emit('created', payload);
        }
        form.value = { ...initial };
    } catch (err) {
        console.error('Message submit error:', err);
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
                <label for="roomId">{{ t('message.room') }} <span class="text-red-500">*</span></label>
                <Dropdown id="roomId" v-model="form.roomId" :options="roomOptions" optionLabel="label" optionValue="value" :placeholder="t('message.selectRoom')" :loading="roomLoading" filter class="w-full" />
                <Message v-if="!form.roomId || form.roomId === 0" size="small" severity="error" variant="simple">{{ t('message.roomRequired') }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="partyId">{{ t('message.party') }} <span class="text-red-500">*</span></label>
                <Dropdown id="partyId" v-model="form.partyId" :options="partyOptions" optionLabel="label" optionValue="value" :placeholder="t('message.selectParty')" :loading="partyLoading" filter class="w-full" />
                <Message v-if="!form.partyId || form.partyId === 0" size="small" severity="error" variant="simple">{{ t('message.partyRequired') }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="upvote">{{ t('message.upvote') }}</label>
                <InputNumber id="upvote" v-model="form.upvote" :min="0" :showButtons="true" class="w-full" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="downvote">{{ t('message.downvote') }}</label>
                <InputNumber id="downvote" v-model="form.downvote" :min="0" :showButtons="true" class="w-full" />
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" :label="t('common.cancel')" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? t('common.update') : t('common.create')" />
            </div>
        </form>
    </div>
</template>
