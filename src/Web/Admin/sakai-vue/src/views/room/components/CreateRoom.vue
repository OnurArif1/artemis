<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import PartyService from '@/service/PartyService';
import CategoryService from '@/service/CategoryService';

const partyService = new PartyService(request);
const categoryService = new CategoryService(request);

const props = defineProps({
    room: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel']);

const initial = {
    topicId: 1,
    partyId: null,
    categoryId: 1,
    title: '',
    locationX: 0,
    locationY: 0,
    roomType: 1,
    lifeCycle: 0,
    channelId: 0,
    referenceId: 'onurarifciftci',
    upvote: 0,
    downvote: 0
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

const isEditMode = computed(() => !!props.room?.id);

async function getPartyLookup(filterText = '') {
    const filter = {
        searchText: filterText,
        partyLooukpSearchType: 1
    };

    try {
        partyLoading.value = true;
        const response = await partyService.getLookup(filter);
        partyOptions.value = (response.viewModels || []).map((p) => ({
            label: p.partyName,
            value: p.partyId
        }));
    } catch (error) {
        console.error('Err:', error);
    } finally {
        partyLoading.value = false;
    }
}

function onPartyFilter(event) {
    const filterValue = event.value?.trim() ?? '';
    if (filterValue.length >= 2) {
        getPartyLookup(filterValue);
    } else if (!filterValue) {
        getPartyLookup();
    }
}

async function getCategoryLookup(filterText = '') {
    const filter = {
        searchText: filterText,
        categoryLookupSearchType: 1
    };

    try {
        categoryLoading.value = true;
        const response = await categoryService.getLookup(filter);
        categoryOptions.value = (response.viewModels || []).map((c) => ({
            label: c.title,
            value: c.categoryId
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
                <Message v-if="!form.partyId" size="small" severity="error" variant="simple"> Party is required. </Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="categoryId">Category</label>
                <Dropdown id="categoryId" v-model="form.categoryId" :options="categoryOptions" option-label="label" option-value="value" placeholder="Select a Category" :loading="categoryLoading" filter @filter="onCategoryFilter" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="locationX">Location X</label>
                <InputText id="locationX" v-model="form.locationX" type="number" />
            </div>
            =======
            <div class="flex flex-col gap-2 mb-3">
                <label for="locationX">Location X</label>
                <InputText id="locationX" v-model="form.locationX" type="number" />
            </div>
            >>>>>>> 5b9c5f5b (fix)

            <div class="flex flex-col gap-2 mb-3">
                <label for="locationY">Location Y</label>
                <InputText id="locationY" v-model="form.locationY" type="number" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="roomType">Room Type</label>
                <Dropdown id="roomType" v-model="form.roomType" :options="roomTypeOptions" option-label="label" option-value="value" />
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? 'Update' : 'Create'" />
            </div>
        </form>
    </div>
</template>
