<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import MentionService from '@/service/MentionService';
import { useToast } from 'primevue/usetoast';
import CreateMention from './components/CreateMention.vue';

const toast = useToast();
const mentions = ref([]);
const mentionService = new MentionService(request);
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
        const data = await mentionService.getList(filter);
        mentions.value = Array.isArray(data.resultViewModels) ? data.resultViewModels : (data?.resultViewModels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        console.error('Mention list load error:', err);
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
const selectedMention = ref(null);

function openCreate() {
    selectedMention.value = null;
    showFormDialog.value = true;
}

function openUpdate(mention) {
    selectedMention.value = { ...mention };
    showFormDialog.value = true;
}

function openDelete(mention) {
    selectedMention.value = { ...mention };
    showDeleteDialog.value = true;
}

async function onCreated(payload) {
    try {
        await mentionService.create(payload);
        showFormDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Mention Created', life: 3000 });
        await load();
    } catch (err) {
        console.error('Mention create error:', err);
        const errorMessage = err?.response?.data?.message || err?.response?.data?.Message || err?.message || 'Failed to create Mention';
        toast.add({ severity: 'error', summary: 'Error', detail: errorMessage, life: 5000 });
    }
}

async function onUpdated(payload) {
    try {
        await mentionService.update(payload);
        showFormDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Mention Updated', life: 3000 });
        await load();
    } catch (err) {
        console.error('Mention update error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to update Mention', life: 5000 });
    }
}

function onDeleted(mentionId) {
    (async () => {
        try {
            await mentionService.delete(mentionId);
            showDeleteDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Mention Deleted', life: 3000 });
            await load();
        } catch (err) {
            console.error('Mention delete error:', err);
        }
    })();
}

async function confirmDelete() {
    try {
        await mentionService.delete(selectedMention.value.id);
        showDeleteDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Mention Deleted', life: 3000 });
        await load();
    } catch (err) {
        console.error('Mention delete error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err?.response?.data?.message || err?.message || 'Failed to delete Mention', life: 5000 });
    }
}

function onCancel() {
    showFormDialog.value = false;
}
</script>

<template>
    <div>
        <DataTable :value="mentions" paginator :rows="10" :first="(pageIndex - 1) * pageSize" :totalRecords="totalRecords" lazy :filters="filters" :rowsPerPageOptions="[5, 10, 20, 50]" @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <div class="relative w-64">
                        <InputText v-model="filters.global.value" placeholder="Search by RoomId" @input="onSearch" class="w-full pr-10" />
                        <i class="pi pi-search absolute top-1/2 -translate-y-1/2 right-3 text-surface-400 pointer-events-none" />
                    </div>
                    <Button icon="pi pi-plus" @click="openCreate" v-tooltip.bottom="'Yeni Mention oluştur'" />
                </div>
            </template>

            <Column field="id" header="Id" />
            <Column field="roomId" header="Room Id" />
            <Column field="messageId" header="Message Id" />
            <Column field="commentId" header="Comment Id" />
            <Column field="topicId" header="Topic Id" />
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

            <template #empty>No Mentions found.</template>
            <template #loading>Loading Mention data. Please wait.</template>
        </DataTable>

        <Dialog v-model:visible="showFormDialog" modal :closable="false" :header="selectedMention ? 'Update Mention' : 'Create Mention'" style="width: 600px">
            <CreateMention :mention="selectedMention" @created="onCreated" @updated="onUpdated" @deleted="onDeleted" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showDeleteDialog" modal :closable="false" header="Delete Mention" style="width: 400px">
            <div class="p-4 text-center">
                <p>
                    Are you sure you want to delete <b>{{ selectedMention?.id }}</b>?
                </p>
                <div class="flex justify-center gap-3 mt-4">
                    <Button label="Cancel" class="p-button-text" @click="showDeleteDialog = false" />
                    <Button label="Delete" severity="danger" @click="confirmDelete" />
                </div>
            </div>
        </Dialog>
    </div>
</template>

