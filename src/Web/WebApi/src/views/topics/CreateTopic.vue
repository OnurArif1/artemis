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
    type: 1,
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
    roomType: 1
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
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('category.listLoadError'),
            life: 5000
        });
    }
}

function getCurrentLocation() {
    if (!navigator.geolocation) {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('topic.geolocationNotSupported'),
            life: 3000
        });
        return;
    }

    navigator.geolocation.getCurrentPosition(
        (position) => {
            formData.value.locationX = parseFloat(position.coords.longitude.toFixed(6));
            formData.value.locationY = parseFloat(position.coords.latitude.toFixed(6));
        },
        () => {
            toast.add({
                severity: 'warn',
                summary: t('common.warning'),
                detail: t('topic.locationNotAvailable'),
                life: 3000
            });
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

        if (result && result.isSuccess === false) {
            throw new Error(result.exceptionMessage || t('topic.createError'));
        }

        const topicTitle = formData.value.title.trim();
        const topicList = await topicService.getList({
            pageIndex: 1,
            pageSize: 1000
        });
        
        const createdTopic = Array.isArray(topicList.resultViewModels)
            ? topicList.resultViewModels.find((t) => t.title === topicTitle)
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

        roomFormData.value = {
            title: '',
            locationX: formData.value.locationX || null,
            locationY: formData.value.locationY || null,
            roomType: 1
        };

        formData.value = {
            title: '',
            type: 1,
            locationX: null,
            locationY: null,
            categoryId: null
        };

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
    max-width: 1000px;
    margin: 0 auto;
    min-height: calc(100vh - 200px);
    display: flex;
    align-items: flex-start;
    justify-content: center;
}

.create-topic-card {
    position: relative;
    width: 100%;
    background: linear-gradient(
        145deg,
        color-mix(in srgb, var(--surface-card) 98%, var(--primary-color)) 0%,
        var(--surface-card) 50%,
        color-mix(in srgb, var(--surface-card) 95%, var(--primary-color)) 100%
    );
    border-radius: 24px;
    padding: 3rem;
    box-shadow:
        0 20px 60px rgba(0, 0, 0, 0.12),
        0 8px 24px rgba(0, 0, 0, 0.08),
        inset 0 1px 0 rgba(255, 255, 255, 0.6),
        inset 0 -1px 0 rgba(0, 0, 0, 0.02);
    border: 1.5px solid color-mix(in srgb, var(--primary-color) 12%, transparent);
    backdrop-filter: blur(20px) saturate(180%);
    animation: cardSlideIn 0.6s cubic-bezier(0.34, 1.56, 0.64, 1);
    overflow: hidden;
}

.create-topic-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(
        90deg,
        transparent 0%,
        var(--primary-color) 20%,
        color-mix(in srgb, var(--primary-color) 90%, #ff6b9d) 50%,
        var(--primary-color) 80%,
        transparent 100%
    );
    background-size: 300% 100%;
    animation: shimmer 4s ease-in-out infinite;
    opacity: 0.9;
    border-radius: 24px 24px 0 0;
}

.create-topic-card::after {
    content: '';
    position: absolute;
    top: -100%;
    left: -100%;
    width: 300%;
    height: 300%;
    background: radial-gradient(
        circle at center,
        color-mix(in srgb, var(--primary-color) 10%, transparent) 0%,
        transparent 70%
    );
    opacity: 0;
    transition: opacity 0.5s;
    pointer-events: none;
}

.create-topic-card:hover::after {
    opacity: 0.3;
}

@keyframes cardSlideIn {
    from {
        opacity: 0;
        transform: translateY(30px) scale(0.95);
    }
    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
}

@keyframes shimmer {
    0% {
        background-position: -200% 0;
    }
    100% {
        background-position: 200% 0;
    }
}

.create-topic-title {
    position: relative;
    font-size: 2rem;
    font-weight: 800;
    margin-bottom: 2.5rem;
    color: var(--text-color);
    background: linear-gradient(
        135deg,
        var(--text-color) 0%,
        color-mix(in srgb, var(--primary-color) 30%, var(--text-color)) 100%
    );
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    letter-spacing: -0.02em;
    z-index: 1;
}

.form-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 2rem;
    margin-bottom: 2.5rem;
}

.form-field {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    position: relative;
    z-index: 1;

    label {
        font-weight: 600;
        color: var(--text-color);
        font-size: 0.95rem;
        letter-spacing: 0.01em;
        display: flex;
        align-items: center;
        gap: 0.25rem;

        .required {
            color: var(--red-500);
            font-weight: 700;
            filter: drop-shadow(0 1px 2px color-mix(in srgb, var(--red-500) 40%, transparent));
        }
    }

    :deep(.p-inputtext),
    :deep(.p-inputnumber-input),
    :deep(.p-dropdown),
    :deep(.p-selectbutton) {
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        border-radius: 12px;
        border: 1.5px solid color-mix(in srgb, var(--primary-color) 15%, transparent);
        background: linear-gradient(
            135deg,
            color-mix(in srgb, var(--surface-0) 98%, var(--primary-color)) 0%,
            var(--surface-0) 100%
        );
        box-shadow:
            0 2px 8px rgba(0, 0, 0, 0.04),
            inset 0 1px 0 rgba(255, 255, 255, 0.5);
        padding: 0.75rem 1rem;
        font-size: 0.95rem;
    }

    :deep(.p-inputtext:focus),
    :deep(.p-inputnumber-input:focus),
    :deep(.p-dropdown:not(.p-disabled).p-focus),
    :deep(.p-selectbutton .p-button.p-highlight) {
        border-color: var(--primary-color);
        box-shadow:
            0 0 0 3px color-mix(in srgb, var(--primary-color) 20%, transparent),
            0 4px 16px color-mix(in srgb, var(--primary-color) 25%, rgba(0, 0, 0, 0.1)),
            inset 0 1px 0 rgba(255, 255, 255, 0.6);
        transform: translateY(-1px);
    }

    :deep(.p-selectbutton .p-button) {
        border-radius: 10px;
        border: 1.5px solid color-mix(in srgb, var(--primary-color) 20%, transparent);
        transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        font-weight: 500;
    }

    :deep(.p-selectbutton .p-button.p-highlight) {
        background: linear-gradient(
            135deg,
            var(--primary-color) 0%,
            color-mix(in srgb, var(--primary-color) 90%, #ff6b9d) 100%
        );
        box-shadow:
            0 4px 12px color-mix(in srgb, var(--primary-color) 35%, rgba(0, 0, 0, 0.2)),
            inset 0 1px 0 rgba(255, 255, 255, 0.3);
        transform: scale(1.05);
    }
}

.form-actions {
    display: flex;
    justify-content: flex-end;
    gap: 1rem;
    margin-top: 2.5rem;
    position: relative;
    z-index: 1;
}

.create-button {
    min-width: 180px;
    padding: 0.875rem 2rem;
    font-weight: 600;
    font-size: 1rem;
    border-radius: 12px;
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    position: relative;
    overflow: hidden;
    box-shadow:
        0 4px 16px color-mix(in srgb, var(--primary-color) 30%, rgba(0, 0, 0, 0.2)),
        inset 0 1px 0 rgba(255, 255, 255, 0.3);
}

.create-button::before {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 0;
    height: 0;
    border-radius: 50%;
    background: radial-gradient(
        circle,
        rgba(255, 255, 255, 0.4) 0%,
        transparent 70%
    );
    transform: translate(-50%, -50%);
    transition: width 0.6s, height 0.6s;
    opacity: 0;
}

.create-button:hover::before {
    width: 400px;
    height: 400px;
    opacity: 1;
}

.create-button:hover {
    transform: translateY(-3px) scale(1.02);
    box-shadow:
        0 8px 32px color-mix(in srgb, var(--primary-color) 40%, rgba(0, 0, 0, 0.3)),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
}

.create-button :deep(.p-button-icon) {
    transition: transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.create-button:hover :deep(.p-button-icon) {
    transform: scale(1.15) rotate(-5deg);
}

.room-section {
    display: flex;
    flex-direction: column;
    gap: 2rem;
    padding: 1.5rem 0;
    animation: sectionFadeIn 0.5s ease-out;
    position: relative;
    z-index: 1;
}

@keyframes sectionFadeIn {
    from {
        opacity: 0;
        transform: translateY(20px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.room-info {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1.25rem 1.5rem;
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 12%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 8%, var(--surface-0)) 100%
    );
    border-radius: 16px;
    color: var(--text-color);
    font-weight: 600;
    border: 1.5px solid color-mix(in srgb, var(--primary-color) 25%, transparent);
    box-shadow:
        0 4px 16px color-mix(in srgb, var(--primary-color) 20%, rgba(0, 0, 0, 0.1)),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
    backdrop-filter: blur(12px);

    i {
        color: var(--primary-color);
        font-size: 1.5rem;
        filter: drop-shadow(0 2px 4px color-mix(in srgb, var(--primary-color) 40%, transparent));
        animation: iconPulse 2s ease-in-out infinite;
    }
}

@keyframes iconPulse {
    0%, 100% {
        transform: scale(1);
    }
    50% {
        transform: scale(1.1);
    }
}

.room-actions {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
}

.create-room-button {
    min-width: 180px;
    padding: 0.875rem 2rem;
    font-weight: 600;
    font-size: 1rem;
    border-radius: 12px;
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    position: relative;
    overflow: hidden;
    box-shadow:
        0 4px 16px color-mix(in srgb, var(--primary-color) 30%, rgba(0, 0, 0, 0.2)),
        inset 0 1px 0 rgba(255, 255, 255, 0.3);
}

.create-room-button::before {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 0;
    height: 0;
    border-radius: 50%;
    background: radial-gradient(
        circle,
        rgba(255, 255, 255, 0.4) 0%,
        transparent 70%
    );
    transform: translate(-50%, -50%);
    transition: width 0.6s, height 0.6s;
    opacity: 0;
}

.create-room-button:hover::before {
    width: 400px;
    height: 400px;
    opacity: 1;
}

.create-room-button:hover {
    transform: translateY(-3px) scale(1.02);
    box-shadow:
        0 8px 32px color-mix(in srgb, var(--primary-color) 40%, rgba(0, 0, 0, 0.3)),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
}

.create-room-button :deep(.p-button-icon) {
    transition: transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.create-room-button:hover :deep(.p-button-icon) {
    transform: scale(1.15) rotate(-5deg);
}

.room-actions :deep(.p-button-outlined) {
    border-radius: 12px;
    font-weight: 600;
    padding: 0.875rem 2rem;
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.room-actions :deep(.p-button-outlined:hover) {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}
</style>
