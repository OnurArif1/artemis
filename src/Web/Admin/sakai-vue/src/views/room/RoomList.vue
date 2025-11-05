<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import CreateRoom from './components/CreateRoom.vue';
import { useToast } from 'primevue/usetoast';

const toast = useToast();
const rooms = ref([]);
const roomService = new RoomService(request);
const showCreate = ref(false);
const selectedRoom = ref(null);
const pageIndex = ref(1);
const pageSize = ref(10);
const totalRecords = ref(0);

async function load() {
    try {
        const roomFilter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value,
            title: filters.value.global.value || ''
        };

        const data = await roomService.getList(roomFilter);
        rooms.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
        totalRecords.value = data?.count;
    } catch (err) {
        console.error('Room list load error:', err);
    }
}

function openCreate() {
    showCreate.value = true;
    selectedRoom.value = null;
}

function openUpdate(room) {
    selectedRoom.value = { ...room };
    showCreate.value = true;
}

function onCreated(payload) {
    (async () => {
        try {
            const data = {
                topicId: payload.topicId || null,
                partyId: payload.partyId,
                categoryId: payload.categoryId || null,
                title: payload.title,
                locationX: payload.locationX || 0,
                locationY: payload.locationY || 0,
                roomType: payload.roomType || 1,
                lifeCycle: payload.lifeCycle || 0,
                channelId: payload.channelId || 0,
                referenceId: payload.referenceId || '',
                upvote: payload.upvote || 0,
                downvote: payload.downvote || 0
            };

            await roomService.create(data);
            showCreate.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Room Created', life: 3000 });
            await load();
        } catch (err) {
            console.error('Room create error:', err);
        }
    })();
}

function onUpdated(payload) {
    (async () => {
        try {
            const data = {
                id: payload.id,
                topicId: payload.topicId || null,
                partyId: payload.partyId,
                categoryId: payload.categoryId || null,
                title: payload.title,
                locationX: payload.locationX || 0,
                locationY: payload.locationY || 0,
                roomType: payload.roomType || 1,
                lifeCycle: payload.lifeCycle || 0,
                channelId: payload.channelId || 0,
                referenceId: payload.referenceId || '',
                upvote: payload.upvote || 0,
                downvote: payload.downvote || 0
            };

            await roomService.update(data);
            showCreate.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Room Updated', life: 3000 });
            await load();
        } catch (err) {
            console.error('Room update error:', err);
        }
    })();
}

function onCancel() {
    showCreate.value = false;
}

function onPage(event) {
    pageIndex.value = event.page + 1;
    pageSize.value = event.rows;
    load();
}

function formatDate(dateString) {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString('tr-TR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    });
}

const filters = ref({
    global: { value: null }
});

function onSearch() {
    pageIndex.value = 1;
    load();
}

const getSeverity = (status) => {
    switch (status) {
        case 2:
            return 'danger';
        case 1:
            return 'success';
    }
};

onMounted(load);
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
            <Column field="locationX" header="LocationX" />
            <Column field="locationY" header="LocationY" />
            <Column field="roomType" header="RoomType">
                <template #body="{ data }">
                    <Tag :value="data.roomType === 1 ? 'Public' : 'Private'" :severity="getSeverity(data.roomType)" />
                </template>
            </Column>
            <Column field="lifeCycle" header="LifeCycle" />
            <Column field="upvote" header="Upvote" />
            <Column field="downvote" header="Downvote" />
            <Column field="createDate" header="CreateDate">
                <template #body="{ data }">
                    <Tag :value="formatDate(data.createDate)" severity="success" />
                </template>
            </Column>
            <Column header="Actions">
                <template #body="{ data }">
                    <Button icon="pi pi-pencil" class="p-button-text p-button-sm" @click="openUpdate(data)" />
                </template>
            </Column>
            <template #empty> No room data found. </template>
            <template #loading> Loading room data. Please wait.</template>
        </DataTable>

        <Dialog v-model:visible="showCreate" modal :closable="false" :header="selectedRoom ? 'Update Room' : 'Create Room'" style="width: 500px">
            <CreateRoom :room="selectedRoom" @created="onCreated" @updated="onUpdated" @cancel="onCancel" />
        </Dialog>
    </div>
</template>
