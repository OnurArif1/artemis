<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import HashtagService from '@/service/HashtagService';
import { useToast } from 'primevue/usetoast';
import CreateHashtag from './components/CreateHashtag.vue';

const toast = useToast();
const hashtags = ref([]);
const hashtagService = new HashtagService(request);
const pageIndex = ref(1);
const pageSize = ref(10);
const totalRecords = ref(0);
const filters = ref({
    global: { value: null }
});

async function load() {
    try {
        const filter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value,
            title: filters.value.global.value || ''
        };
        const data = await hashtagService.getList(filter);
        hashtags.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        console.error('Hashtag list load error:', err);
    }
}

onMounted(load);

function onSearch() {
    pageIndex.value = 1;
    load();
}

function onPage(event) {
    pageIndex.value = event.page + 1;
    pageSize.value = event.rows;
    load();
}

const showFormDialog = ref(false);
const showDeleteDialog = ref(false);
const selectedHashtag = ref(null);

function openCreate() {
    selectedHashtag.value = null;
    showFormDialog.value = true;
}

function openUpdate(hashtag) {
    selectedHashtag.value = { ...hashtag };
    showFormDialog.value = true;
}

function openDelete(hashtag) {
    selectedHashtag.value = { ...hashtag };
    showDeleteDialog.value = true;
}

async function onCreated(payload) {
    try {
        await hashtagService.create(payload);
        showFormDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Hashtag Created', life: 3000 });
        await load();
    } catch (err) {
        console.error('Hashtag create error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to create hashtag', life: 5000 });
    }
}

async function onUpdated(payload) {
    try {
        await hashtagService.update(payload);
        showFormDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Hashtag Updated', life: 3000 });
        await load();
    } catch (err) {
        console.error('Hashtag update error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to update hashtag', life: 5000 });
    }
}

function onDeleted(hashtagId) {
    (async () => {
        try {
            await hashtagService.delete(hashtagId);
            showDeleteDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Hashtag Deleted', life: 3000 });
            await load();
        } catch (err) {
            console.error('Hashtag delete error:', err);
        }
    })();
}

async function confirmDelete() {
    try {
        await hashtagService.delete(selectedHashtag.value.id);
        showDeleteDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Hashtag Deleted', life: 3000 });
        await load();
    } catch (err) {
        console.error('Hashtag delete error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to delete hashtag', life: 5000 });
    }
}

function onCancel() {
    showFormDialog.value = false;
}
</script>

<template>
    <div>
        <DataTable :value="hashtags" paginator :rows="10" :first="(pageIndex - 1) * pageSize" :totalRecords="totalRecords" lazy :filters="filters" :rowsPerPageOptions="[5, 10, 20, 50]" @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <div class="relative w-64">
                        <InputText v-model="filters.global.value" placeholder="Search by Title" @input="onSearch" class="w-full pr-10" />
                        <i class="pi pi-search absolute top-1/2 -translate-y-1/2 right-3 text-surface-400 pointer-events-none" />
                    </div>
                    <Button icon="pi pi-plus" @click="openCreate" v-tooltip.bottom="'Yeni hashtag oluştur'" />
                </div>
            </template>

            <Column field="id" header="Id" />
            <Column field="hashtagName" header="Name" />
            <Column field="createDate" header="Created At" />

            <Column header="Update">
                <template #body="{ data }">
                    <Button icon="pi pi-pencil" class="p-button-text p-button-sm" @click="openUpdate(data)" />
                </template>
            </Column>

            <Column header="Delete">
                <template #body="{ data }">
                    <Button icon="pi pi-trash" class="p-button-text p-button-sm" @click="openDelete(data)" />
                </template>
            </Column>

            <template #empty>No hashtags found.</template>
            <template #loading>Loading hashtags data. Please wait.</template>
        </DataTable>

        <Dialog v-model:visible="showFormDialog" modal :closable="false" :header="selectedHashtag ? 'Update Hashtag' : 'Create Hashtag'" style="width: 500px">
            <CreateHashtag :hashtag="selectedHashtag" @created="onCreated" @updated="onUpdated" @deleted="onDeleted" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showDeleteDialog" modal :closable="false" header="Delete Hashtag" style="width: 400px">
            <div class="p-4 text-center">
                <p>
                    Are you sure you want to delete <b>{{ selectedHashtag?.hashtagName }}</b
                    >?
                </p>
                <div class="flex justify-center gap-3 mt-4">
                    <Button label="Cancel" class="p-button-text" @click="showDeleteDialog = false" />
                    <Button label="Delete" severity="danger" @click="confirmDelete" />
                </div>
            </div>
        </Dialog>
    </div>
</template>
