<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import TopicService from '@/service/TopicService';
import CreateTopic from './components/CreateTopic.vue';
import { useToast } from 'primevue/usetoast';
import { useI18n } from '@/composables/useI18n';

const { t, locale } = useI18n();
const toast = useToast();
const topics = ref([]);
const topicService = new TopicService(request);
const pageIndex = ref(1);
const pageSize = ref(10);
const totalRecords = ref(0);

const filters = ref({
    global: { value: null }
});

const showFormDialog = ref(false);
const showDeleteDialog = ref(false);
const selectedTopic = ref(null);

async function load() {
    try {
        const topicFilter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value
        };

        const data = await topicService.getList(topicFilter);
        topics.value = Array.isArray(data.resultViewModels) ? data.resultViewModels : (data?.resultViewModels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        console.error('Topic list load error:', err);
        toast.add({ severity: 'error', summary: t('common.error'), detail: err?.response?.data?.message || err?.message || t('topic.failedToLoad'), life: 5000 });
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
    selectedTopic.value = null;
    showFormDialog.value = true;
}

function openUpdate(topic) {
    selectedTopic.value = { ...topic };
    showFormDialog.value = true;
}

function openDelete(topic) {
    selectedTopic.value = { ...topic };
    showDeleteDialog.value = true;
}

function onCreated(payload) {
    (async () => {
        try {
            const data = {
                partyId: payload.partyId,
                title: payload.title,
                type: payload.type || 1,
                locationX: payload.locationX || 0,
                locationY: payload.locationY || 0,
                categoryId: payload.categoryId || 1,
                mentionId: payload.mentionId || null,
                upvote: payload.upvote || 0,
                downvote: payload.downvote || 0,
                lastUpdateDate: new Date().toISOString(),
                createDate: new Date().toISOString()
            };
            await topicService.create(data);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: t('common.success'), detail: t('topic.created'), life: 3000 });
            await load();
        } catch (err) {
            console.error('Topic create error:', err);
            toast.add({ severity: 'error', summary: t('common.error'), detail: err?.response?.data?.message || err?.message || t('topic.failedToCreate'), life: 5000 });
        }
    })();
}

function onUpdated(payload) {
    (async () => {
        try {
            const data = {
                id: payload.id,
                partyId: payload.partyId,
                title: payload.title,
                type: payload.type || 1,
                locationX: payload.locationX || 0,
                locationY: payload.locationY || 0,
                categoryId: payload.categoryId || 1,
                mentionId: payload.mentionId || null,
                upvote: payload.upvote || 0,
                downvote: payload.downvote || 0,
                lastUpdateDate: new Date().toISOString(),
                createDate: payload.createDate || new Date().toISOString()
            };
            await topicService.update(data);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: t('common.success'), detail: t('topic.updated'), life: 3000 });
            await load();
        } catch (err) {
            console.error('Topic update error:', err);
            toast.add({ severity: 'error', summary: t('common.error'), detail: err?.response?.data?.message || err?.message || t('topic.failedToUpdate'), life: 5000 });
        }
    })();
}

function onDeleted(topicId) {
    (async () => {
        try {
            await topicService.delete(topicId);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: t('common.success'), detail: t('topic.deleted'), life: 3000 });
            await load();
        } catch (err) {
            console.error('Topic delete error:', err);
            toast.add({ severity: 'error', summary: t('common.error'), detail: err?.response?.data?.message || err?.message || t('topic.failedToDelete'), life: 5000 });
        }
    })();
}

async function confirmDelete() {
    try {
        await topicService.delete(selectedTopic.value.id);
        showDeleteDialog.value = false;
        toast.add({ severity: 'success', summary: t('common.success'), detail: t('topic.deleted'), life: 3000 });
        await load();
    } catch (err) {
        console.error('Topic delete error:', err);
        toast.add({ severity: 'error', summary: t('common.error'), detail: err?.response?.data?.message || err?.message || t('topic.failedToDelete'), life: 5000 });
    }
}

function onCancel() {
    showFormDialog.value = false;
}

function formatDate(dateString) {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString(locale.value === 'tr' ? 'tr-TR' : 'en-US', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

const getSeverity = (type) => {
    switch (type) {
        case 2:
            return 'danger';
        case 1:
            return 'success';
        case 0:
            return 'info';
        default:
            return 'info';
    }
};

const getTypeLabel = (type) => {
    switch (type) {
        case 0:
            return t('topic.typeNone');
        case 1:
            return t('common.public');
        case 2:
            return t('common.private');
        default:
            return t('topic.typeUnknown');
    }
};
</script>

<template>
    <div>
        <DataTable :value="topics" paginator :rows="10" :first="(pageIndex - 1) * pageSize" :totalRecords="totalRecords" lazy :filters="filters" :rowsPerPageOptions="[5, 10, 20, 50]" @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <div class="relative w-64">
                        <InputText v-model="filters.global.value" :placeholder="t('common.searchByTitle')" @input="onSearch" class="w-full pr-10" />
                        <i class="pi pi-search absolute top-1/2 -translate-y-1/2 right-3 text-surface-400 pointer-events-none" />
                    </div>
                    <Button icon="pi pi-plus" @click="openCreate" :v-tooltip.bottom="t('topic.create')" />
                </div>
            </template>
            <Column field="id" :header="t('topic.id')" />
            <Column field="title" :header="t('topic.titleLabel')" />
            <Column field="partyName" :header="t('topic.party')">
                <template #body="{ data }">
                    <span v-if="data.partyName" class="text-sm">{{ data.partyName }}</span>
                    <span v-else class="text-300 text-sm">-</span>
                </template>
            </Column>
            <Column field="type" :header="t('topic.type')">
                <template #body="{ data }">
                    <Tag :value="getTypeLabel(data.type)" :severity="getSeverity(data.type)" />
                </template>
            </Column>
            <Column field="categoryName" :header="t('topic.category')">
                <template #body="{ data }">
                    <span v-if="data.categoryName" class="text-sm">{{ data.categoryName }}</span>
                    <span v-else class="text-300 text-sm">-</span>
                </template>
            </Column>
            <Column field="createDate" :header="t('topic.createDate')">
                <template #body="{ data }">
                    <Tag :value="formatDate(data.createDate)" severity="success" />
                </template>
            </Column>
            <Column field="lastUpdateDate" :header="t('topic.lastUpdate')">
                <template #body="{ data }">
                    <Tag :value="formatDate(data.lastUpdateDate)" severity="info" />
                </template>
            </Column>

            <Column :header="t('common.operations')">
                <template #body="{ data }">
                    <Button icon="pi pi-pencil" class="p-button-text p-button-sm" @click="openUpdate(data)" :v-tooltip.bottom="t('common.update')" />
                    <Button icon="pi pi-trash" class="p-button-text p-button-sm" @click="openDelete(data)" :v-tooltip.bottom="t('common.delete')" />
                </template>
            </Column>

            <template #empty>{{ t('topic.noTopicData') }}</template>
            <template #loading>{{ t('topic.loadingTopicData') }}</template>
        </DataTable>

        <Dialog v-model:visible="showFormDialog" modal :closable="false" :header="selectedTopic ? t('topic.updateTopic') : t('topic.createTopic')" style="width: 500px">
            <CreateTopic :topic="selectedTopic" @created="onCreated" @updated="onUpdated" @deleted="onDeleted" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showDeleteDialog" modal :closable="false" :header="t('topic.deleteTopic')" style="width: 400px">
            <div class="p-4 text-center">
                <p>
                    {{ t('common.areYouSureDelete') }} <b>{{ selectedTopic?.title }}</b>?
                </p>
                <div class="flex justify-center gap-3 mt-4">
                    <Button :label="t('common.cancel')" class="p-button-text" @click="showDeleteDialog = false" />
                    <Button :label="t('common.delete')" severity="danger" @click="confirmDelete" />
                </div>
            </div>
        </Dialog>
    </div>
</template>
