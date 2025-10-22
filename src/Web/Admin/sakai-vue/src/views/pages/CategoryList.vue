<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import CategoryService from '@/service/CategoryService';

const categories = ref([]);
const categoryService = new CategoryService(request);

async function load() {
    try {
        const data = await categoryService.getList({ page: 1, size: 10 });
        categories.value = Array.isArray(data) ? data : (data?.items ?? []);
    } catch (err) {
        console.error('Category list load error:', err);
    }
}

onMounted(load);
</script>

<template>
    <div>
        <DataTable :value="categories" :paginator="true" :rows="10">
            <template #empty> No categories found. </template>
            <template #loading> Loading categories data. Please wait.</template>
            <Column field="id" header="Id" style="min-width: 12rem">
                <template #body="{ data }">
                    {{ data.id }}
                </template>
            </Column>
        </DataTable>
    </div>
</template>
