<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from '@/composables/useI18n';
import { useToast } from 'primevue/usetoast';
import request from '@/service/request';
import TopicService from '@/service/TopicService';
import RoomService from '@/service/RoomService';
import CategoryService from '@/service/CategoryService';

const { t } = useI18n();
const toast = useToast();
const topicService = new TopicService(request);
const roomService = new RoomService(request);
const categoryService = new CategoryService(request);

const formData = ref({
    title: '',
    type: 1, // Public
    locationX: null,
    locationY: null,
    categoryId: null
});

const categories = ref([]);
const loading = ref(false);
const showRoomSection = ref(false);
const createdTopicId = ref(null);
const roomFormData = ref({
    title: '',
    locationX: null,
    locationY: null,
    roomType: 1 // Public
});

const topicTypeOptions = [
    { label: t('topic.public'), value: 1 },
    { label: t('topic.private'), value: 2 }
];

const roomTypeOptions = [
    { label: t('room.public'), value: 1 },
    { label: t('room.private'), value: 2 }
];

async function loadCategories() {
    try {
        const data = await categoryService.getList({
            pageIndex: 1,
            pageSize: 1000
        });
        categories.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
    } catch (err) {
        console.error('Category yükleme hatası:', err);
    }
}

function getCurrentLocation() {
    if (!navigator.geolocation) {
        console.warn('Geolocation desteklenmiyor');
        return;
    }

    navigator.geolocation.getCurrentPosition(
        (position) => {
            // longitude -> locationX, latitude -> locationY
            formData.value.locationX = parseFloat(position.coords.longitude.toFixed(6));
            formData.value.locationY = parseFloat(position.coords.latitude.toFixed(6));
        },
        (error) => {
            console.warn('Konum alınamadı:', error.message);
        },
        {
            enableHighAccuracy: true,
            timeout: 5000,
            maximumAge: 0
        }
    );
}

async function createTopic() {
    if (!formData.value.title || formData.value.title.trim() === '') {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('topic.titleRequired'),
            life: 3000
        });
        return;
    }

    loading.value = true;
    try {
        const result = await topicService.create({
            title: formData.value.title.trim(),
            type: formData.value.type,
            locationX: formData.value.locationX || 0,
            locationY: formData.value.locationY || 0,
            categoryId: formData.value.categoryId || 0
        });

        // API'den dönen result kontrolü
        if (result && result.isSuccess === false) {
            throw new Error(result.exceptionMessage || t('topic.createError'));
        }

        // Oluşturulan topic'in ID'sini bul
        const topicTitle = formData.value.title.trim();
        const topicList = await topicService.getList({
            pageIndex: 1,
            pageSize: 1000
        });
        
        const createdTopic = Array.isArray(topicList.resultViewModels) 
            ? topicList.resultViewModels.find(t => t.title === topicTitle)
            : null;
        
        if (createdTopic) {
            createdTopicId.value = createdTopic.id;
        }

        toast.add({
            severity: 'success',
            summary: t('common.success'),
            detail: t('topic.createSuccess'),
            life: 3000
        });

        // Topic koordinatlarını room formuna kopyala
        roomFormData.value = {
            title: '',
            locationX: formData.value.locationX || null,
            locationY: formData.value.locationY || null,
            roomType: 1
        };

        // Formu temizle
        formData.value = {
            title: '',
            type: 1,
            locationX: null,
            locationY: null,
            categoryId: null
        };

        // Room bağlama bölümünü göster
        showRoomSection.value = true;
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.exceptionMessage || err?.response?.data?.message || err?.message || t('topic.createError'),
            life: 5000
        });
    } finally {
        loading.value = false;
    }
}

function resetForm() {
    showRoomSection.value = false;
    createdTopicId.value = null;
    roomFormData.value = {
        title: '',
        locationX: null,
        locationY: null,
        roomType: 1
    };
    formData.value = {
        title: '',
        type: 1,
        locationX: null,
        locationY: null,
        categoryId: null
    };
}

async function createRoomForTopic() {
    if (!roomFormData.value.title || roomFormData.value.title.trim() === '') {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('room.titlePlaceholder'),
            life: 3000
        });
        return;
    }

    if (!createdTopicId.value) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: 'Topic ID bulunamadı',
            life: 3000
        });
        return;
    }

    loading.value = true;
    try {
        await roomService.create({
            title: roomFormData.value.title.trim(),
            topicId: createdTopicId.value,
            locationX: roomFormData.value.locationX || 0,
            locationY: roomFormData.value.locationY || 0,
            roomType: roomFormData.value.roomType
        });

        toast.add({
            severity: 'success',
            summary: t('common.success'),
            detail: t('topic.roomCreated'),
            life: 3000
        });

        // Formu en başa döndür
        resetForm();
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('topic.roomCreateError'),
            life: 5000
        });
    } finally {
        loading.value = false;
    }
}

onMounted(() => {
    loadCategories();
    getCurrentLocation();
});
</script>

<template>
    <div class="create-topic-container">
        <div class="create-topic-card">
            <h2 class="create-topic-title">
                {{ showRoomSection ? t('topic.addRoom') : t('topic.createTitle') }}
            </h2>

            <!-- Topic oluşturma formu -->
            <div v-if="!showRoomSection" class="form-grid">
                <div class="form-field">
                    <label for="title">{{ t('topic.title') }} <span class="required">*</span></label>
                    <InputText
                        id="title"
                        v-model="formData.title"
                        :placeholder="t('topic.titlePlaceholder')"
                        class="w-full"
                    />
                </div>

                <div class="form-field">
                    <label for="category">{{ t('topic.category') }}</label>
                    <Dropdown
                        id="category"
                        v-model="formData.categoryId"
                        :options="categories"
                        optionLabel="title"
                        optionValue="id"
                        :placeholder="t('topic.selectCategory')"
                        filter
                        class="w-full"
                    />
                </div>

                <div class="form-field">
                    <label for="locationX">{{ t('topic.locationX') }}</label>
                    <InputNumber
                        id="locationX"
                        v-model="formData.locationX"
                        :placeholder="t('topic.locationX')"
                        class="w-full"
                        :minFractionDigits="0"
                        :maxFractionDigits="6"
                    />
                </div>

                <div class="form-field">
                    <label for="locationY">{{ t('topic.locationY') }}</label>
                    <InputNumber
                        id="locationY"
                        v-model="formData.locationY"
                        :placeholder="t('topic.locationY')"
                        class="w-full"
                        :minFractionDigits="0"
                        :maxFractionDigits="6"
                    />
                </div>

                <div class="form-field">
                    <label for="topicType">{{ t('topic.type') }}</label>
                    <SelectButton
                        id="topicType"
                        v-model="formData.type"
                        :options="topicTypeOptions"
                        optionLabel="label"
                        optionValue="value"
                        class="w-full"
                    />
                </div>
            </div>

            <div v-if="!showRoomSection" class="form-actions">
                <Button
                    :label="t('common.create')"
                    icon="pi pi-check"
                    :loading="loading"
                    @click="createTopic"
                    class="create-button"
                />
            </div>

            <!-- Room bağlama bölümü -->
            <div v-if="showRoomSection" class="room-section">
                <div class="room-info">
                    <i class="pi pi-info-circle"></i>
                    <span>{{ t('topic.addRoomMessage') }}</span>
                </div>

                <div class="form-grid">
                    <div class="form-field">
                        <label for="roomTitle">{{ t('room.title') }} <span class="required">*</span></label>
                        <InputText
                            id="roomTitle"
                            v-model="roomFormData.title"
                            :placeholder="t('room.titlePlaceholder')"
                            class="w-full"
                        />
                    </div>

                    <div class="form-field">
                        <label for="roomLocationX">{{ t('room.locationX') }}</label>
                        <InputNumber
                            id="roomLocationX"
                            v-model="roomFormData.locationX"
                            :placeholder="t('room.locationX')"
                            class="w-full"
                            :minFractionDigits="0"
                            :maxFractionDigits="6"
                        />
                    </div>

                    <div class="form-field">
                        <label for="roomLocationY">{{ t('room.locationY') }}</label>
                        <InputNumber
                            id="roomLocationY"
                            v-model="roomFormData.locationY"
                            :placeholder="t('room.locationY')"
                            class="w-full"
                            :minFractionDigits="0"
                            :maxFractionDigits="6"
                        />
                    </div>

                    <div class="form-field">
                        <label for="roomType">{{ t('room.roomType') }}</label>
                        <SelectButton
                            id="roomType"
                            v-model="roomFormData.roomType"
                            :options="roomTypeOptions"
                            optionLabel="label"
                            optionValue="value"
                            class="w-full"
                        />
                    </div>
                </div>

                <div class="room-actions">
                    <Button
                        :label="t('topic.createRoom')"
                        icon="pi pi-plus"
                        @click="createRoomForTopic"
                        :loading="loading"
                        class="create-room-button"
                    />
                    <Button
                        :label="t('common.cancel')"
                        severity="secondary"
                        outlined
                        @click="resetForm"
                    />
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped lang="scss">
.create-topic-container {
    padding: 2rem;
    max-width: 900px;
    margin: 0 auto;
}

.create-topic-card {
    background: var(--surface-card);
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.create-topic-title {
    font-size: 1.75rem;
    font-weight: 600;
    margin-bottom: 2rem;
    color: var(--text-color);
}

.form-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
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

.form-actions {
    display: flex;
    justify-content: flex-end;
    gap: 1rem;
    margin-top: 2rem;
}

.create-button {
    min-width: 150px;
}

.room-section {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
    padding: 1rem 0;
}

.room-info {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 1rem;
    background: var(--surface-100);
    border-radius: 8px;
    color: var(--text-color);
    font-weight: 500;

    i {
        color: var(--primary-color);
        font-size: 1.2rem;
    }
}

.room-actions {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
}

.create-room-button {
    min-width: 150px;
}
</style>
