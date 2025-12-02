<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import CreateRoom from './components/CreateRoom.vue';
import { useToast } from 'primevue/usetoast';
import AddPartyToRoom from './components/AddPartyToRoom.vue';
import Chat from '@/views/chat/Chat.vue';

const toast = useToast();
const rooms = ref([]);
const roomService = new RoomService(request);
const pageIndex = ref(1);
const pageSize = ref(10);
const totalRecords = ref(0);

const filters = ref({
    global: { value: null }
});

const showFormDialog = ref(false);
const showAddPartyDialog = ref(false);
const showDeleteDialog = ref(false);
const showChatDialog = ref(false);
const selectedRoom = ref(null);

async function load() {
    try {
        const roomFilter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value,
            title: filters.value.global.value || ''
        };

        const data = await roomService.getList(roomFilter);
        rooms.value = Array.isArray(data.resultViewModels) ? data.resultViewModels : (data?.resultViewModels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        console.error('Room list load error:', err);
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

function openCreate() {
    selectedRoom.value = null;
    showFormDialog.value = true;
}

function openUpdate(room) {
    selectedRoom.value = { ...room };
    showFormDialog.value = true;
}

function openAddPartyToRoom(room) {
    selectedRoom.value = { ...room };
    showAddPartyDialog.value = true;
}

function openDelete(room) {
    selectedRoom.value = { ...room };
    showDeleteDialog.value = true;
}

function onCreated(payload) {
    (async () => {
        try {
            const data = {
                topicId: payload.topicId,
                title: payload.title,
                roomType: payload.roomType,
                partyId: payload.partyId || null,
                categoryId: payload.categoryId || null,
                locationX: payload.locationX ?? null,
                locationY: payload.locationY ?? null,
                lifeCycle: payload.lifeCycle ?? null,
                channelId: payload.channelId || null,
                referenceId: payload.referenceId || null,
                upvote: payload.upvote ?? null,
                downvote: payload.downvote ?? null
            };
            await roomService.create(data);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Room Created', life: 3000 });
            await load();
        } catch (err) {
            console.error('Room create error:', err);
            toast.add({ severity: 'error', summary: 'Error', detail: err.response?.data?.message || err.message || 'Room creation failed', life: 3000 });
        }
    })();
}

function onAddPartyToRoom(payload) {
    (async () => {
        try {
            const data = {
                roomId: payload.id,
                partyId: payload.partyId
            };

            await roomService.addPartyToRoom(data);
            showAddPartyDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Party Added to Room', life: 3000 });
            await load();
        } catch (err) {
            toast.add({ severity: 'error', summary: 'Error', detail: err.response?.data?.message || err.message || 'Add Party to Room failed', life: 3000 });
        }
    })();
}

function onUpdated(payload) {
    (async () => {
        try {
            const data = {
                id: payload.id,
                topicId: payload.topicId,
                title: payload.title,
                roomType: payload.roomType,
                partyId: payload.partyId || null,
                categoryId: payload.categoryId || null,
                locationX: payload.locationX ?? null,
                locationY: payload.locationY ?? null,
                lifeCycle: payload.lifeCycle ?? null,
                channelId: payload.channelId || null,
                referenceId: payload.referenceId || null,
                upvote: payload.upvote ?? null,
                downvote: payload.downvote ?? null
            };
            await roomService.update(data);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Room Updated', life: 3000 });
            await load();
        } catch (err) {
            toast.add({ severity: 'error', summary: 'Error', detail: err.response?.data?.message || err.message || 'Room update failed', life: 3000 });
        }
    })();
}

async function confirmDelete() {
    try {
        await roomService.delete(selectedRoom.value.id);
        showDeleteDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'Room Deleted', life: 3000 });
        await load();
    } catch (err) {
        console.error('Room delete error:', err);
        toast.add({ severity: 'error', summary: 'Error', detail: err.response?.data?.message || err.message || 'Room delete failed', life: 3000 });
    }
}

function onCancel() {
    showFormDialog.value = false;
}

function openChat(room) {
    selectedRoom.value = room;
    showChatDialog.value = true;
}

function formatDate(dateString) {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString('tr-TR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    });
}

const getSeverity = (status) => {
    switch (status) {
        case 2:
            return 'danger';
        case 1:
            return 'success';
    }
};
</script>

<template>
    <div>
        <DataTable :value="rooms" paginator :rows="10" :first="(pageIndex - 1) * pageSize" :totalRecords="totalRecords" lazy :filters="filters" :rowsPerPageOptions="[5, 10, 20, 50]" @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <div class="relative w-64">
                        <InputText v-model="filters.global.value" placeholder="Search by Title" @input="onSearch" class="w-full pr-10" />
                        <i class="pi pi-search absolute top-1/2 -translate-y-1/2 right-3 text-surface-400 pointer-events-none" />
                    </div>
                    <Button icon="pi pi-plus" @click="openCreate" v-tooltip.bottom="'Add New Room'" />
                </div>
            </template>
            <Column field="id" header="Id" />
            <Column field="title" header="Title" />
            <Column field="topicTitle" header="Topic">
                <template #body="{ data }">
                    <span v-if="data.topicTitle" class="text-sm">{{ data.topicTitle }}</span>
                    <span v-else class="text-300 text-sm">-</span>
                </template>
            </Column>
            <Column field="roomType" header="RoomType">
                <template #body="{ data }">
                    <Tag :value="data.roomType === 1 ? 'Public' : 'Private'" :severity="getSeverity(data.roomType)" />
                </template>
            </Column>
            <Column field="channelId" header="Channel ID">
                <template #body="{ data }">
                    <span v-if="data.channelId" class="text-sm font-mono">{{ data.channelId }}</span>
                    <span v-else class="text-300 text-sm">-</span>
                </template>
            </Column>
            <Column field="createDate" header="CreateDate">
                <template #body="{ data }">
                    <Tag :value="formatDate(data.createDate)" severity="success" />
                </template>
            </Column>
            <Column field="parties" header="Parties">
                <template #body="{ data }">
                    <div v-if="data.parties && data.parties.length > 0" class="flex flex-wrap gap-1">
                        <Tag v-for="party in data.parties" :key="party.id" :value="party.partyName" severity="info" class="mr-1" />
                    </div>
                    <span v-else class="text-300 text-sm">-</span>
                </template>
            </Column>
            <Column header="Operation">
                <template #body="{ data }">
                    <Button icon="pi pi-pencil" class="p-button-text p-button-sm" @click="openUpdate(data)" v-tooltip.bottom="'Update'" />
                    <Button icon="pi pi-trash" class="p-button-text p-button-sm" @click="openDelete(data)" v-tooltip.bottom="'Delete'" />
                    <Button icon="pi pi-plus" class="p-button-text p-button-sm" @click="openAddPartyToRoom(data)" v-tooltip.bottom="'AddPartyToRoom'" />
                    <Button v-if="data.channelId" icon="pi pi-comments" class="p-button-text p-button-sm" @click="openChat(data)" v-tooltip.bottom="'Open Chat'" />
                </template>
            </Column>

            <template #empty>No room data found.</template>
            <template #loading>Loading room data. Please wait.</template>
        </DataTable>

        <Dialog v-model:visible="showFormDialog" modal :closable="false" :header="selectedRoom ? 'Update Room' : 'Create Room'" style="width: 500px">
            <CreateRoom :room="selectedRoom" @created="onCreated" @updated="onUpdated" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showAddPartyDialog" modal :closable="false" header="Add Party To Room" style="width: 500px">
            <AddPartyToRoom :room="selectedRoom" @addPartyToRoom="onAddPartyToRoom" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showDeleteDialog" modal :closable="false" header="Delete Room" style="width: 400px">
            <div class="p-4 text-center">
                <p>
                    Are you sure you want to delete <b>{{ selectedRoom?.title }}</b
                    >?
                </p>
                <div class="flex justify-center gap-3 mt-4">
                    <Button label="Cancel" class="p-button-text" @click="showDeleteDialog = false" />
                    <Button label="Delete" severity="danger" @click="confirmDelete" />
                </div>
            </div>
        </Dialog>

        <Dialog v-model:visible="showChatDialog" modal :closable="true" :header="`Chat - ${selectedRoom?.title || 'Room'}`" :style="{ width: '800px', height: '600px' }" :maximizable="true">
            <Chat v-if="selectedRoom" :roomIdProp="selectedRoom.id" />
        </Dialog>
    </div>
</template>
