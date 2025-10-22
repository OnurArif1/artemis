<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import CreateRoom from './components/CreateRoom.vue';

const rooms = ref([]);
const roomService = new RoomService(request);
const showCreate = ref(false);

async function load() {
    try {
        const data = await roomService.getList({ page: 1, size: 10 });
        rooms.value = Array.isArray(data) ? data : (data?.items ?? []);
    } catch (err) {
        console.error('Room list load error:', err);
    }
}

function openCreate() {
    showCreate.value = true;
}

function onCreated(payload) {
    // backend'e create isteği at, başarılıysa dialog kapatıp listeyi yenile
    (async () => {
        try {
            await roomService.create(payload);
            showCreate.value = false;
            await load();
        } catch (err) {
            console.error('Room create error:', err);
        }
    })();
}

function onCancel() {
    showCreate.value = false;
}

onMounted(load);
</script>

<template>
    <div>
        <div class="flex justify-end mb-3">
            <Button label="Create" icon="pi pi-plus" @click="openCreate" />
        </div>

        <DataTable :value="rooms" :paginator="true" :rows="10">
            <template #empty> No customers found. </template>
            <template #loading> Loading customers data. Please wait.</template>
            <Column field="id" header="Id" style="min-width: 12rem">
                <template #body="{ data }">
                    {{ data.id }}
                </template>
            </Column>
        </DataTable>

        <Dialog v-model:visible="showCreate" modal :closable="false" header="Create Room" style="width: 500px">
            <CreateRoom @created="onCreated" @cancel="onCancel" />
        </Dialog>
    </div>
</template>
