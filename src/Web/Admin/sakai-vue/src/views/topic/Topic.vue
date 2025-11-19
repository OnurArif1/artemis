<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import TopicHashtagMapService from '@/service/TopicHashtagMapService';
import { useToast } from 'primevue/usetoast';
import CreateTopicHashtagMap from './components/CreateTopic.vue';

const toast = useToast();
const maps = ref([]);
const mapService = new TopicHashtagMapService(request);
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
            pageSize: pageSize.value
        };
        if (filters.value.global.value) {
            const topicId = parseInt(filters.value.global.value);
            if (!isNaN(topicId)) {
                filter.topicId = topicId;
            }
        }
        const data = await mapService.getList(filter);
        maps.value = Array.isArray(data.resultViewModels) ? data.resultViewModels : (data?.resultViewModels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        console.error('TopicHashtagMap list load error:', err);
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
const selectedMap = ref(null);

function openCreate() {
    selectedMap.value = null;
    showFormDialog.value = true;
}

function openUpdate(map) {
    selectedMap.value = { ...map };
    showFormDialog.value = true;
}

function openDelete(map) {
    selectedMap.value = { ...map };
    showDeleteDialog.value = true;
}

async function onCreated(payload) {
    try {
        await mapService.create(payload);
        showFormDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'TopicHashtagMap Created', life: 3000 });
        await load();
    } catch (err) {
        console.error('TopicHashtagMap create error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to create TopicHashtagMap', life: 5000 });
    }
}

async function onUpdated(payload) {
    try {
        await mapService.update(payload);
        showFormDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'TopicHashtagMap Updated', life: 3000 });
        await load();
    } catch (err) {
        console.error('TopicHashtagMap update error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to update TopicHashtagMap', life: 5000 });
    }
}

function onDeleted(mapId) {
    (async () => {
        try {
            await mapService.delete(mapId);
            showDeleteDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'TopicHashtagMap Deleted', life: 3000 });
            await load();
        } catch (err) {
            console.error('TopicHashtagMap delete error:', err);
        }
    })();
}

async function confirmDelete() {
    try {
        await mapService.delete(selectedMap.value.id);
        showDeleteDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'TopicHashtagMap Deleted', life: 3000 });
        await load();
    } catch (err) {
        console.error('TopicHashtagMap delete error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to delete TopicHashtagMap', life: 5000 });
    }
}

function onCancel() {
    showFormDialog.value = false;
}
</script>

<template>
    <div>
        <DataTable :value="maps" paginator :rows="10" :first="(pageIndex - 1) * pageSize" :totalRecords="totalRecords" lazy :filters="filters" :rowsPerPageOptions="[5, 10, 20, 50]" @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <div class="relative w-64">
                        <InputText v-model="filters.global.value" placeholder="Search by TopicId" @input="onSearch" class="w-full pr-10" />
                        <i class="pi pi-search absolute top-1/2 -translate-y-1/2 right-3 text-surface-400 pointer-events-none" />
                    </div>
                    <Button icon="pi pi-plus" @click="openCreate" v-tooltip.bottom="'Yeni TopicHashtagMap oluştur'" />
                </div>
            </template>

            <Column field="id" header="Id" />
            <Column field="topicId" header="Topic Id" />
            <Column field="hashtagId" header="Hashtag Id" />

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

            <template #empty>No TopicHashtagMaps found.</template>
            <template #loading>Loading TopicHashtagMap data. Please wait.</template>
        </DataTable>

        <Dialog v-model:visible="showFormDialog" modal :closable="false" :header="selectedMap ? 'Update Map' : 'Create Map'" style="width: 500px">
            <CreateTopicHashtagMap :topicHashtagMap="selectedMap" @created="onCreated" @updated="onUpdated" @deleted="onDeleted" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showDeleteDialog" modal :closable="false" header="Delete Map" style="width: 400px">
            <div class="p-4 text-center">
                <p>
                    Are you sure you want to delete <b>{{ selectedMap?.id }}</b
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
