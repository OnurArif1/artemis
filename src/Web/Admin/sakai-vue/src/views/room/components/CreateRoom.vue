<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import PartyService from '@/service/PartyService';
import CategoryService from '@/service/CategoryService';
import signalRService from '@/service/SignalRService';

const partyService = new PartyService(request);
const categoryService = new CategoryService(request);

const props = defineProps({
    room: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    topicId: null,
    partyId: null,
    categoryId: null,
    title: '',
    locationX: null,
    locationY: null,
    roomType: 1,
    lifeCycle: null,
    channelId: null,
    referenceId: null,
    upvote: null,
    downvote: null
};

const form = ref({ ...initial });
const loading = ref(false);

const partyOptions = ref([]);
const partyLoading = ref(false);
const categoryOptions = ref([]);
const categoryLoading = ref(false);

const roomTypeOptions = [
    { label: 'Public', value: 1 },
    { label: 'Private', value: 2 }
];

const isEditMode = computed(() => !!props.room?.id);

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

async function getCategoryLookup(filterText = '') {
    const filter = {
        searchText: filterText,
        categoryLookupSearchType: 1
    };

    try {
        categoryLoading.value = true;
        const response = await categoryService.getLookup(filter);
        categoryOptions.value = response?.viewModels.map((c) => ({
            label: c.title,
            value: c.categoryId || c.id
        }));
    } catch (error) {
        console.error('Category lookup error:', error);
    } finally {
        categoryLoading.value = false;
    }
}

function onCategoryFilter(event) {
    const filterValue = event.value?.trim() ?? '';
    if (filterValue.length >= 2) {
        getCategoryLookup(filterValue);
    } else if (!filterValue) {
        getCategoryLookup();
    }
}

onMounted(() => {
    getPartyLookup();
    getCategoryLookup();
});

watch(
    () => props.room,
    async (newRoom) => {
        if (newRoom) {
            form.value = { ...newRoom };
        } else {
            form.value = { ...initial };
            getPartyLookup();
            getCategoryLookup();
            
            // Yeni room oluşturulurken SignalR ConnectionId'yi al ve ekle
            try {
                // SignalR bağlantısı yoksa başlat
                if (!signalRService.isConnected()) {
                    await signalRService.startConnection();
                }
                
                // ConnectionId'yi al
                const connectionId = signalRService.getConnectionId();
                if (connectionId) {
                    form.value.channelId = connectionId;
                    console.log('📡 ChannelId form\'a eklendi:', connectionId);
                } else {
                    // ConnectionId henüz hazır değilse, biraz bekle ve tekrar dene
                    setTimeout(async () => {
                        const retryConnectionId = signalRService.getConnectionId();
                        if (retryConnectionId) {
                            form.value.channelId = retryConnectionId;
                            console.log('📡 ChannelId form\'a eklendi (retry):', retryConnectionId);
                        }
                    }, 500);
                }
            } catch (error) {
                console.error('SignalR ConnectionId alma hatası:', error);
            }
        }
    },
    { immediate: true }
);

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
        console.error('Room submit error:', err);
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
                <label for="title">Title</label>
                <InputText id="title" v-model="form.title" type="text" />
                <Message v-if="!form.title" size="small" severity="error" variant="simple"> Name is required. </Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="partyId">Party</label>
                <Dropdown id="partyId" v-model="form.partyId" :options="partyOptions" option-label="label" option-value="value" placeholder="Select a Party" :loading="partyLoading" filter @filter="onPartyFilter" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="categoryId">Category</label>
                <Dropdown id="categoryId" v-model="form.categoryId" :options="categoryOptions" option-label="label" option-value="value" placeholder="Select a Category" :loading="categoryLoading" filter @filter="onCategoryFilter" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="locationX">Location X</label>
                <InputText id="locationX" v-model="form.locationX" type="number" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="locationY">Location Y</label>
                <InputText id="locationY" v-model="form.locationY" type="number" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="roomType">Room Type</label>
                <Dropdown id="roomType" v-model="form.roomType" :options="roomTypeOptions" option-label="label" option-value="value" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="channelId">Channel ID (SignalR Connection ID)</label>
                <InputText id="channelId" v-model="form.channelId" type="text" placeholder="Otomatik olarak SignalR ConnectionId eklenecek" />
                <small class="text-500">SignalR bağlantı ID'si. Yeni room oluştururken otomatik olarak eklenir.</small>
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? 'Update' : 'Create'" />
            </div>
        </form>
    </div>
</template>
