<script setup>
import { ref, watch, onMounted } from 'vue';
import request from '@/service/request';
import PartyService from '@/service/PartyService';

const partyService = new PartyService(request);

const props = defineProps({
    room: {
        type: Object,
        default: null
    }
});

const initial = {
    partyId: null,
    roomId: props.room?.id || null
};

const emit = defineEmits(['addPartyToRoom', 'cancel']);
const form = ref({ ...initial });
const loading = ref(false);
const partyLoading = ref(false);
const partyOptions = ref([]);

async function getPartyLookup(filterText = '') {
    const filter = {
        searchText: filterText || '',
        partyLookupSearchType: filterText ? 1 : 0
    };

    try {
        partyLoading.value = true;
        const response = await partyService.getLookup(filter);

        partyOptions.value = response?.viewModels.map((p) => ({
            label: `${p.partyName}`,
            value: p.partyId
        }));
    } catch (error) {
        console.error('Party lookup error:', error);
        partyOptions.value = [];
    } finally {
        partyLoading.value = false;
    }
}

function onPartyFilter(event) {
    const filterValue = event.value?.trim() ?? '';
    getPartyLookup(filterValue);
}

onMounted(() => {
    getPartyLookup();
});

watch(
    () => props.room,
    (newRoom) => {
        if (newRoom) {
            form.value = { ...newRoom };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

async function submit() {
    loading.value = true;
    try {
        emit('addPartyToRoom', { ...form.value });
        form.value = { ...initial };
    } catch (err) {
        console.error('Add Party to Room submit error:', err);
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
                <label for="partyId">Party</label>
                <Dropdown id="partyId" v-model="form.partyId" :options="partyOptions" option-label="label" option-value="value" placeholder="Select a Party" :loading="partyLoading" filter @filter="onPartyFilter" />
            </div>
            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" label="Add Party To Room" />
            </div>
        </form>
    </div>
</template>
