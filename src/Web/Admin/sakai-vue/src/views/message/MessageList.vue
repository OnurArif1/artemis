<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import MessageService from '@/service/MessageService';
import { useToast } from 'primevue/usetoast';
import CreateMessage from './components/CreateMessage.vue';

const toast = useToast();
const messages = ref([]);
const messageService = new MessageService(request);
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
            const roomId = parseInt(filters.value.global.value);
            if (!isNaN(roomId)) {
                filter.roomId = roomId;
            }
        }
        const data = await messageService.getList(filter);
        messages.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        console.error('Message list load error:', err);
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
const selectedMessage = ref(null);

function openCreate() {
    selectedMessage.value = null;
    showFormDialog.value = true;
}

function openUpdate(message) {
    selectedMessage.value = { ...message };
    showFormDialog.value = true;
}

function openDelete(message) {
    selectedMessage.value = { ...message };
    showDeleteDialog.value = true;
}

async function onCreated(payload) {
    try {
        await messageService.create(payload);
        showFormDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Message Created', life: 3000 });
        await load();
    } catch (err) {
        console.error('Message create error:', err);
        const errorMessage = err?.response?.data?.message || err?.response?.data?.Message || err?.message || 'Failed to create Message';
        toast.add({ severity: 'error', summary: 'Error', detail: errorMessage, life: 5000 });
    }
}

async function onUpdated(payload) {
    try {
        await messageService.update(payload);
        showFormDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Message Updated', life: 3000 });
        await load();
    } catch (err) {
        console.error('Message update error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to update Message', life: 5000 });
    }
}

function onDeleted(messageId) {
    (async () => {
        try {
            await messageService.delete(messageId);
            showDeleteDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Message Deleted', life: 3000 });
            await load();
        } catch (err) {
            console.error('Message delete error:', err);
        }
    })();
}

async function confirmDelete() {
    try {
        await messageService.delete(selectedMessage.value.id);
        showDeleteDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Message Deleted', life: 3000 });
        await load();
    } catch (err) {
        console.error('Message delete error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to delete Message', life: 5000 });
    }
}

function onCancel() {
    showFormDialog.value = false;
}
</script>

<template>
    <div>
        <DataTable :value="messages" paginator :rows="10" :first="(pageIndex - 1) * pageSize" :totalRecords="totalRecords" lazy :filters="filters" :rowsPerPageOptions="[5, 10, 20, 50]" @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <div class="relative w-64">
                        <InputText v-model="filters.global.value" placeholder="Search by RoomId" @input="onSearch" class="w-full pr-10" />
                        <i class="pi pi-search absolute top-1/2 -translate-y-1/2 right-3 text-surface-400 pointer-events-none" />
                    </div>
                    <Button icon="pi pi-plus" @click="openCreate" v-tooltip.bottom="'Yeni Message oluştur'" />
                </div>
            </template>

            <Column field="id" header="Id" />
            <Column field="roomId" header="Room Id" />
            <Column field="partyId" header="Party Id" />
            <Column field="content" header="Content" />
            <Column field="upvote" header="Upvote" />
            <Column field="downvote" header="Downvote" />
            <Column field="lastUpdateDate" header="Last Update Date" />
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

            <template #empty>No Messages found.</template>
            <template #loading>Loading Message data. Please wait.</template>
        </DataTable>

        <Dialog v-model:visible="showFormDialog" modal :closable="false" :header="selectedMessage ? 'Update Message' : 'Create Message'" style="width: 600px">
            <CreateMessage :message="selectedMessage" @created="onCreated" @updated="onUpdated" @deleted="onDeleted" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showDeleteDialog" modal :closable="false" header="Delete Message" style="width: 400px">
            <div class="p-4 text-center">
                <p>
                    Are you sure you want to delete Message <b>#{{ selectedMessage?.id }}</b
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
