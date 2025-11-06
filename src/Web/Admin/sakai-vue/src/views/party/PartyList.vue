<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import PartyService from '@/service/PartyService';
import { useToast } from 'primevue/usetoast';
import CreateParty from './components/CreateParty.vue';

const toast = useToast();
const parties = ref([]);
const partyService = new PartyService(request);
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
        const data = await partyService.getList(filter);
        parties.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        console.error('Party list load error:', err);
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
const selectedParty = ref(null);

function openCreate() {
    selectedParty.value = null;
    showFormDialog.value = true;
}

function openUpdate(party) {
    selectedParty.value = { ...party };
    showFormDialog.value = true;
}

function openDelete(party) {
    selectedParty.value = { ...party };
    showDeleteDialog.value = true;
}

function onCreated(payload) {
    (async () => {
        try {
            await partyService.create(payload);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Party Created', life: 3000 });
            await load();
        } catch (err) {
            console.error('Party create error:', err);
        }
    })();
}

function onUpdated(payload) {
    (async () => {
        try {
            await partyService.update(payload);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Party Updated', life: 3000 });
            await load();
        } catch (err) {
            console.error('Party update error:', err);
        }
    })();
}

function onDeleted(partyId) {
    (async () => {
        try {
            await partyService.delete(partyId);
            showDeleteDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Party Deleted', life: 3000 });
            await load();
        } catch (err) {
            console.error('Party delete error:', err);
        }
    })();
}

async function confirmDelete() {
    try {
        await partyService.delete(selectedParty.value.id);
        showDeleteDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Party Deleted', life: 3000 });
        await load();
    } catch (err) {
        console.error('Party delete error:', err);
    }
}

function onCancel() {
    showFormDialog.value = false;
}
</script>

<template>
    <div>
        <DataTable :value="parties" paginator :rows="10" :first="(pageIndex - 1) * pageSize" :totalRecords="totalRecords" lazy :filters="filters" :rowsPerPageOptions="[5, 10, 20, 50]" @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <div class="relative w-64">
                        <InputText v-model="filters.global.value" placeholder="Search by Title" @input="onSearch" class="w-full pr-10" />
                        <i class="pi pi-search absolute top-1/2 -translate-y-1/2 right-3 text-surface-400 pointer-events-none" />
                    </div>
                    <Button icon="pi pi-plus" @click="openCreate" v-tooltip.bottom="'Yeni party oluştur'" />
                </div>
            </template>

            <Column field="id" header="Id" />
            <Column field="partyName" header="Name" />
            <Column field="partyType" header="Type" />
            <Column field="deviceId" header="DeviceId" />
            <Column field="isBanned" header="Banned" />

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

            <template #empty>No parties found.</template>
            <template #loading>Loading parties data. Please wait.</template>
        </DataTable>

        <Dialog v-model:visible="showFormDialog" modal :closable="false" :header="selectedParty ? 'Update Party' : 'Create Party'" style="width: 500px">
            <CreateParty :party="selectedParty" @created="onCreated" @updated="onUpdated" @deleted="onDeleted" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showDeleteDialog" modal :closable="false" header="Delete Party" style="width: 400px">
            <div class="p-4 text-center">
                <p>
                    Are you sure you want to delete <b>{{ selectedParty?.partyName }}</b
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
