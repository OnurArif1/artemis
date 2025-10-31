<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import CategoryService from '@/service/CategoryService';
import { useToast } from 'primevue/usetoast';
import CreateCategory from './components/CreateCategory.vue';

const toast = useToast();
const categories = ref([]);
const categoryService = new CategoryService(request);
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
        const data = await categoryService.getList(filter);
        categories.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        console.error('Category list load error:', err);
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

const showCreate = ref(false)
const selectedCategory = ref(null)

function openCreate() {
    showCreate.value = true;
    selectedCategory.value = null;
}

function openUpdate(category) {
    selectedCategory.value = { ...category };
    showCreate.value = true;
}

function onCreated(payload) {
    (async () => {
        try {
            await categoryService.create(payload);
            showCreate.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Category Created' });
            await load();
        } catch (err) {
            console.error('Category create error:', err);
        }
    })();
}

function onUpdated(payload) {
    (async () => {
        try {
            await categoryService.update(payload);
            showCreate.value = false;
            toast.add({ severity: 'success', summary: 'Successful', detail: 'Category Updated' });
            await load();
        } catch (err) {
            console.error('Category update error:', err);
        }
    })();
}

function onCancel() {
    showCreate.value = false;
}
</script>

<template>
    <div>
        <DataTable :value="categories" paginator :rows="10"
                    :first="(pageIndex - 1) * pageSize"
                    :totalRecords="totalRecords" lazy :filters="filters"
                    :rowsPerPageOptions="[5, 10, 20, 50]"
                    @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <div class="relative w-64">
                        <InputText
                            v-model="filters.global.value"
                            placeholder="Search by Title"
                            @input="onSearch"
                            class="w-full pr-10"
                        />
                        <i class="pi pi-search absolute top-1/2 -translate-y-1/2 right-3 text-surface-400 pointer-events-none" />
                    </div>
                    <Button
                        icon="pi pi-plus"
                        @click="openCreate"
                        v-tooltip.bottom="'Yeni kategori oluştur'"
                    />
                </div>
            </template>
            <Column field="id" header="Id"/>
            <Column field="title" header="Title"/>
            <Column header="Actions">
                <template #body="{ data }">
                    <Button icon="pi pi-pencil" class="p-button-text p-button-sm" @click="openUpdate(data)" />
                </template>
            </Column>
            <template #empty> No categories found. </template>
            <template #loading> Loading categories data. Please wait.</template>
        </DataTable>

        <Dialog v-model:visible="showCreate" modal :closable="false" :header="selectedCategory ? 'Update Category' : 'Create Category'" style="width: 500px">
            <CreateCategory
                :category="selectedCategory"
                @created="onCreated"
                @updated="onUpdated"
                @cancel="onCancel"
            />
        </Dialog>
    </div>
</template>
