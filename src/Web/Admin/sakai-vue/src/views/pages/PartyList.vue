<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import PartyService from '@/service/PartyService';

const parties = ref([]);
const partyService = new PartyService(request);

async function load() {
    try {
        const data = await partyService.getList({ page: 1, size: 10 });
        parties.value = Array.isArray(data) ? data : (data?.items ?? []);
    } catch (err) {
        console.error('Party list load error:', err);
    }
}

onMounted(load);
</script>

<template>
    <div>
        <DataTable :value="parties" :paginator="true" :rows="10">
            <template #empty> No parties found. </template>
            <template #loading> Loading parties data. Please wait.</template>
            <Column field="id" header="Id" style="min-width: 12rem">
                <template #body="{ data }">
                    {{ data.id }}
                </template>
            </Column>
        </DataTable>
    </div>
</template>
