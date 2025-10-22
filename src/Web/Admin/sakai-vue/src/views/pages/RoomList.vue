<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import RoomService from '@/service/RoomService';

const rooms = ref([]);
const roomService = new RoomService(request);

async function load() {
    try {
        const data = await roomService.getList({ page: 1, size: 10 });
        rooms.value = Array.isArray(data) ? data : (data?.items ?? []);
    } catch (err) {
        console.error('Room list load error:', err);
    }
}

onMounted(load);
</script>

<template>
    <div>
        <DataTable :value="rooms" :paginator="true" :rows="10">
             <template #empty> No customers found. </template>
            <template #loading> Loading customers data. Please wait.</template>
            <Column field="id" header="Id" style="min-width: 12rem">
                <template #body="{ data }">
                    {{ data.id }}
                </template>
            </Column>
        </DataTable>
    </div>
</template>