<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import AppSubscriptionTypePricesService from '@/service/AppSubscriptionTypePricesService';
import { useToast } from 'primevue/usetoast';
import CreateAppSubscriptionTypePrices from './components/CreateAppSubscriptionTypePrices.vue';
import { useI18n } from '@/composables/useI18n';

const { t } = useI18n();
const toast = useToast();
const appSubscriptionTypePrices = ref([]);
const appSubscriptionTypePricesService = new AppSubscriptionTypePricesService(request);
const pageIndex = ref(1);
const pageSize = ref(10);
const totalRecords = ref(0);
const filters = ref({
    global: { value: null }
});

const subscriptionTypeOptions = [
    { label: t('subscription.none') || 'None', value: 0 },
    { label: t('subscription.silver') || 'Silver', value: 1 },
    { label: t('subscription.gold') || 'Gold', value: 2 },
    { label: t('subscription.platinum') || 'Platinum', value: 3 }
];

const currencyTypeOptions = [
    { label: t('currency.none') || 'None', value: 0 },
    { label: t('currency.tl') || 'TL', value: 1 },
    { label: t('currency.eur') || 'EUR', value: 2 },
    { label: t('currency.dollar') || 'DOLLAR', value: 3 }
];

function getSubscriptionTypeLabel(value) {
    const option = subscriptionTypeOptions.find(opt => opt.value === value);
    return option ? option.label : value;
}

function getCurrencyTypeLabel(value) {
    const option = currencyTypeOptions.find(opt => opt.value === value);
    return option ? option.label : value;
}

function formatDate(date) {
    if (!date) return '-';
    return new Date(date).toLocaleDateString();
}

async function load() {
    try {
        const filter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value
        };
        const data = await appSubscriptionTypePricesService.getList(filter);
        appSubscriptionTypePrices.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        toast.add({ severity: 'error', summary: t('common.error'), detail: err.response?.data?.message || err.message || t('common.loadFailed'), life: 3000 });
    }
}

onMounted(load);

function onPage(event) {
    pageIndex.value = event.page + 1;
    pageSize.value = event.rows;
    load();
}

const showFormDialog = ref(false);
const showDeleteDialog = ref(false);
const selectedAppSubscriptionTypePrices = ref(null);

function openCreate() {
    selectedAppSubscriptionTypePrices.value = null;
    showFormDialog.value = true;
}

function openUpdate(appSubscriptionTypePrices) {
    selectedAppSubscriptionTypePrices.value = { ...appSubscriptionTypePrices };
    showFormDialog.value = true;
}

function openDelete(appSubscriptionTypePrices) {
    selectedAppSubscriptionTypePrices.value = { ...appSubscriptionTypePrices };
    showDeleteDialog.value = true;
}

function onCreated(payload) {
    (async () => {
        try {
            await appSubscriptionTypePricesService.create(payload);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: t('common.success'), detail: t('appSubscriptionTypePrices.created') || 'AppSubscriptionTypePrices Created', life: 3000 });
            await load();
        } catch (err) {
            toast.add({ severity: 'error', summary: t('common.error'), detail: err.response?.data?.message || err.message || t('appSubscriptionTypePrices.createFailed') || 'Failed to create AppSubscriptionTypePrices', life: 3000 });
        }
    })();
}

function onUpdated(payload) {
    (async () => {
        try {
            await appSubscriptionTypePricesService.update(payload);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: t('common.success'), detail: t('appSubscriptionTypePrices.updated') || 'AppSubscriptionTypePrices Updated', life: 3000 });
            await load();
        } catch (err) {
            toast.add({ severity: 'error', summary: t('common.error'), detail: err.response?.data?.message || err.message || t('appSubscriptionTypePrices.updateFailed') || 'Failed to update AppSubscriptionTypePrices', life: 3000 });
            console.error('AppSubscriptionTypePrices update error:', err);
        }
    })();
}

function onDeleted(appSubscriptionTypePricesId) {
    (async () => {
        try {
            await appSubscriptionTypePricesService.delete(appSubscriptionTypePricesId);
            showFormDialog.value = false;
            toast.add({ severity: 'success', summary: t('common.success'), detail: t('appSubscriptionTypePrices.deleted') || 'AppSubscriptionTypePrices Deleted', life: 3000 });
            await load();
        } catch (err) {
            console.error('AppSubscriptionTypePrices delete error:', err);
        }
    })();
}

async function confirmDelete() {
    try {
        await appSubscriptionTypePricesService.delete(selectedAppSubscriptionTypePrices.value.id);
        showDeleteDialog.value = false;
        toast.add({ severity: 'success', summary: 'Successful', detail: 'AppSubscriptionTypePrices Deleted', life: 3000 });
        await load();
    } catch (err) {
        console.error('AppSubscriptionTypePrices delete error:', err);
    }
}

function onCancel() {
    showFormDialog.value = false;
}
</script>

<template>
    <div>
        <DataTable :value="appSubscriptionTypePrices" paginator :rows="10" :first="(pageIndex - 1) * pageSize" :totalRecords="totalRecords" lazy :rowsPerPageOptions="[5, 10, 20, 50]" @page="onPage">
            <template #header>
                <div class="flex justify-between items-center mb-3">
                    <h2>{{ t('appSubscriptionTypePrices.title') || 'App Subscription Type Prices' }}</h2>
                    <Button icon="pi pi-plus" @click="openCreate" :v-tooltip.bottom="t('appSubscriptionTypePrices.create') || 'Create App Subscription Type Prices'" />
                </div>
            </template>
            <Column field="id" :header="t('appSubscriptionTypePrices.id') || 'Id'" />
            <Column :header="t('appSubscriptionTypePrices.subscriptionType') || 'Subscription Type'">
                <template #body="{ data }">
                    {{ getSubscriptionTypeLabel(data.subscriptionType) }}
                </template>
            </Column>
            <Column field="price" :header="t('appSubscriptionTypePrices.price') || 'Price'">
                <template #body="{ data }">
                    {{ data.price?.toFixed(2) || '0.00' }}
                </template>
            </Column>
            <Column :header="t('appSubscriptionTypePrices.priceCurrencyType') || 'Currency Type'">
                <template #body="{ data }">
                    {{ getCurrencyTypeLabel(data.priceCurrencyType) }}
                </template>
            </Column>
            <Column :header="t('appSubscriptionTypePrices.appSubscriptionPeriodType') || 'Period Type'">
                <template #body="{ data }">
                    {{ data.appSubscriptionPeriodType !== null && data.appSubscriptionPeriodType !== undefined ? (data.appSubscriptionPeriodType === 1 ? 'Monthly' : data.appSubscriptionPeriodType === 2 ? 'Yearly' : 'None') : '-' }}
                </template>
            </Column>
            <Column field="createDate" :header="t('appSubscriptionTypePrices.createDate') || 'Create Date'">
                <template #body="{ data }">
                    {{ formatDate(data.createDate) }}
                </template>
            </Column>
            <Column :header="t('appSubscriptionTypePrices.thruDate') || 'Thru Date'">
                <template #body="{ data }">
                    {{ formatDate(data.thruDate) }}
                </template>
            </Column>
            <Column :header="t('common.update')">
                <template #body="{ data }">
                    <Button icon="pi pi-pencil" class="p-button-text p-button-sm" @click="openUpdate(data)" />
                </template>
            </Column>
            <Column :header="t('common.delete')">
                <template #body="{ data }">
                    <Button icon="pi pi-trash" class="p-button-text p-button-sm" @click="openDelete(data)" />
                </template>
            </Column>
            <template #empty>{{ t('appSubscriptionTypePrices.noDataFound') || 'No App Subscription Type Prices found.' }}</template>
            <template #loading>{{ t('appSubscriptionTypePrices.loadingData') || 'Loading App Subscription Type Prices data. Please wait.' }}</template>
        </DataTable>

        <Dialog v-model:visible="showFormDialog" modal :closable="false" :header="selectedAppSubscriptionTypePrices ? (t('appSubscriptionTypePrices.updateAppSubscriptionTypePrices') || 'Update App Subscription Type Prices') : (t('appSubscriptionTypePrices.createAppSubscriptionTypePrices') || 'Create App Subscription Type Prices')" style="width: 500px">
            <CreateAppSubscriptionTypePrices :appSubscriptionTypePrices="selectedAppSubscriptionTypePrices" @created="onCreated" @updated="onUpdated" @deleted="onDeleted" @cancel="onCancel" />
        </Dialog>

        <Dialog v-model:visible="showDeleteDialog" modal :closable="false" :header="t('appSubscriptionTypePrices.deleteAppSubscriptionTypePrices') || 'Delete App Subscription Type Prices'" style="width: 400px">
            <div class="p-4 text-center">
                <p>
                    {{ t('common.areYouSureDelete') || 'Are you sure you want to delete' }} <b>ID: {{ selectedAppSubscriptionTypePrices?.id }}</b>?
                </p>
                <div class="flex justify-center gap-3 mt-4">
                    <Button :label="t('common.cancel')" class="p-button-text" @click="showDeleteDialog = false" />
                    <Button :label="t('common.delete')" severity="danger" @click="confirmDelete" />
                </div>
            </div>
        </Dialog>
    </div>
</template>
