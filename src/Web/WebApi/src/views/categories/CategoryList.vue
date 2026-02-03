<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from '@/composables/useI18n';
import { useToast } from 'primevue/usetoast';
import request from '@/service/request';
import CategoryService from '@/service/CategoryService';

const { t } = useI18n();
const toast = useToast();
const categoryService = new CategoryService(request);

const categories = ref([]);
const loading = ref(false);
const searchText = ref('');
const pageIndex = ref(1);
const pageSize = ref(20);
const totalRecords = ref(0);

const showFormDialog = ref(false);
const showDeleteDialog = ref(false);
const selectedCategory = ref(null);
const formData = ref({
    id: null,
    title: ''
});

async function loadCategories() {
    loading.value = true;
    try {
        const filter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value,
            title: searchText.value || undefined
        };
        const data = await categoryService.getList(filter);
        categories.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
        totalRecords.value = data?.count ?? 0;
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('category.listLoadError'),
            life: 5000
        });
    } finally {
        loading.value = false;
    }
}

function onSearch() {
    pageIndex.value = 1;
    loadCategories();
}

function clearSearch() {
    searchText.value = '';
    pageIndex.value = 1;
    loadCategories();
}

function onPage(event) {
    pageIndex.value = event.page + 1;
    pageSize.value = event.rows;
    loadCategories();
}

function openCreate() {
    selectedCategory.value = null;
    formData.value = {
        id: null,
        title: ''
    };
    showFormDialog.value = true;
}

function openUpdate(category) {
    selectedCategory.value = category;
    formData.value = {
        id: category.id,
        title: category.title
    };
    showFormDialog.value = true;
}

function openDelete(category) {
    selectedCategory.value = category;
    showDeleteDialog.value = true;
}

async function saveCategory() {
    if (!formData.value.title || formData.value.title.trim() === '') {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('category.titleRequired'),
            life: 3000
        });
        return;
    }

    loading.value = true;
    try {
        if (formData.value.id) {
            await categoryService.update({
                id: formData.value.id,
                title: formData.value.title.trim()
            });
            toast.add({
                severity: 'success',
                summary: t('common.success'),
                detail: t('category.updated'),
                life: 3000
            });
        } else {
            await categoryService.create({
                title: formData.value.title.trim()
            });
            toast.add({
                severity: 'success',
                summary: t('common.success'),
                detail: t('category.created'),
                life: 3000
            });
        }
        showFormDialog.value = false;
        await loadCategories();
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || (formData.value.id ? t('category.updateError') : t('category.createError')),
            life: 5000
        });
    } finally {
        loading.value = false;
    }
}

async function confirmDelete() {
    if (!selectedCategory.value) return;

    loading.value = true;
    try {
        await categoryService.delete(selectedCategory.value.id);
        toast.add({
            severity: 'success',
            summary: t('common.success'),
            detail: t('category.deleted'),
            life: 3000
        });
        showDeleteDialog.value = false;
        await loadCategories();
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('category.deleteError'),
            life: 5000
        });
    } finally {
        loading.value = false;
    }
}

function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('tr-TR', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
}

onMounted(() => {
    loadCategories();
});
</script>

<template>
    <div class="category-list-container">
        <div class="category-list-header">
            <h2 class="category-list-title">{{ t('category.list') }}</h2>
        </div>

        <div class="search-section">
            <div class="search-input-wrapper">
                <span class="p-input-icon-right w-full">
                    <InputText
                        v-model="searchText"
                        :placeholder="t('category.searchPlaceholder')"
                        class="w-full"
                        @keyup.enter="onSearch"
                    />
                    <i v-if="searchText" class="pi pi-times clear-icon" @click="clearSearch" />
                </span>
                <Button
                    :label="t('common.search')"
                    icon="pi pi-search"
                    @click="onSearch"
                    class="search-button"
                />
            </div>
            <div class="create-button-wrapper">
                <Button
                    :label="t('category.create')"
                    icon="pi pi-plus"
                    @click="openCreate"
                    class="create-button"
                />
            </div>
        </div>

        <DataTable
            :value="categories"
            :loading="loading"
            :paginator="true"
            :rows="pageSize"
            :totalRecords="totalRecords"
            :first="(pageIndex - 1) * pageSize"
            :rowsPerPageOptions="[10, 20, 50]"
            @page="onPage"
            class="category-table"
        >
            <Column field="title" :header="t('category.title')" :sortable="true" />
            <Column field="createDate" :header="t('category.createDate')" :sortable="true" style="min-width: 180px">
                <template #body="slotProps">
                    {{ formatDate(slotProps.data.createDate) }}
                </template>
            </Column>
            <Column :header="t('common.actions')" style="min-width: 150px">
                <template #body="slotProps">
                    <div class="action-buttons">
                        <Button
                            icon="pi pi-pencil"
                            severity="info"
                            text
                            rounded
                            @click="openUpdate(slotProps.data)"
                            v-tooltip.top="t('common.edit')"
                        />
                        <Button
                            icon="pi pi-trash"
                            severity="danger"
                            text
                            rounded
                            @click="openDelete(slotProps.data)"
                            v-tooltip.top="t('common.delete')"
                        />
                    </div>
                </template>
            </Column>
            <template #empty>
                <div class="empty-message">
                    {{ t('category.noCategories') }}
                </div>
            </template>
        </DataTable>

        <!-- Kategori Ekleme/Düzenleme Dialogu -->
        <Dialog
            v-model:visible="showFormDialog"
            :header="formData.id ? t('category.edit') : t('category.create')"
            modal
            :style="{ width: '500px' }"
            :closable="true"
        >
            <div class="form-content">
                <div class="form-field">
                    <label for="categoryTitle">{{ t('category.title') }} <span class="required">*</span></label>
                    <InputText
                        id="categoryTitle"
                        v-model="formData.title"
                        :placeholder="t('category.titlePlaceholder')"
                        class="w-full"
                    />
                </div>
            </div>

            <template #footer>
                <Button
                    :label="t('common.cancel')"
                    severity="secondary"
                    outlined
                    @click="showFormDialog = false"
                />
                <Button
                    :label="formData.id ? t('common.save') : t('common.create')"
                    icon="pi pi-check"
                    @click="saveCategory"
                    :loading="loading"
                />
            </template>
        </Dialog>

        <!-- Silme Onay Dialogu -->
        <Dialog
            v-model:visible="showDeleteDialog"
            :header="t('category.deleteConfirm')"
            modal
            :style="{ width: '400px' }"
            :closable="true"
        >
            <div class="delete-content">
                <i class="pi pi-exclamation-triangle delete-icon" />
                <p>{{ t('category.deleteMessage') }}: <strong>{{ selectedCategory?.title }}</strong></p>
            </div>

            <template #footer>
                <Button
                    :label="t('common.cancel')"
                    severity="secondary"
                    outlined
                    @click="showDeleteDialog = false"
                />
                <Button
                    :label="t('common.delete')"
                    severity="danger"
                    icon="pi pi-trash"
                    @click="confirmDelete"
                    :loading="loading"
                />
            </template>
        </Dialog>
    </div>
</template>

<style scoped lang="scss">
.category-list-container {
    padding: 2rem;
    max-width: 1200px;
    margin: 0 auto;
}

.category-list-header {
    margin-bottom: 2rem;
}

.category-list-title {
    font-size: 2rem;
    font-weight: 600;
    color: var(--text-color);
    margin: 0;
}

.search-section {
    display: grid;
    grid-template-columns: repeat(12, 1fr);
    gap: 1rem;
    margin-bottom: 1.5rem;
    align-items: center;
}

.search-input-wrapper {
    grid-column: span 3;
    display: flex;
    gap: 0.5rem;
    align-items: center;

    .p-input-icon-right {
        width: 100%;
        position: relative;

        .clear-icon {
            position: absolute;
            right: 0.75rem;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            color: var(--text-color-secondary);
            transition: color 0.2s;
            z-index: 10;

            &:hover {
                color: var(--text-color);
            }
        }
    }
}

.search-button {
    flex-shrink: 0;
}

.create-button-wrapper {
    grid-column: 10 / span 3;
    display: flex;
    justify-content: flex-end;
}

.create-button {
    min-width: 150px;
}

.category-table {
    background: var(--surface-card);
    border-radius: 8px;
    overflow: hidden;
}

.action-buttons {
    display: flex;
    gap: 0.5rem;
}

.empty-message {
    text-align: center;
    padding: 2rem;
    color: var(--text-color-secondary);
}

.form-content {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
    padding: 1rem 0;
}

.form-field {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;

    label {
        font-weight: 500;
        color: var(--text-color);
        font-size: 0.95rem;

        .required {
            color: var(--red-500);
        }
    }
}

.delete-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    text-align: center;

    .delete-icon {
        font-size: 3rem;
        color: var(--red-500);
    }

    p {
        margin: 0;
        color: var(--text-color);
        font-size: 1rem;
    }
}
</style>
