<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from '@/composables/useI18n';
import { useToast } from 'primevue/usetoast';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import TopicService from '@/service/TopicService';
import PartyService from '@/service/PartyService';

const { t } = useI18n();
const toast = useToast();
const roomService = new RoomService(request);
const topicService = new TopicService(request);
const partyService = new PartyService(request);

const formData = ref({
    title: '',
    topicId: null,
    locationX: null,
    locationY: null,
    roomType: 1 // Public
});

const topics = ref([]);
const loading = ref(false);
const showInviteSection = ref(false);
const createdRoomId = ref(null);
const selectedParty = ref(null); // Backward compatibility için
const selectedParties = ref([]); // Çoklu davet için
const partySearchValue = ref('');
const parties = ref([]);
const loadingParties = ref(false);

const roomTypeOptions = [
    { label: t('room.public'), value: 1 },
    { label: t('room.private'), value: 2 }
];

async function loadTopics() {
    try {
        const data = await topicService.getList({
            pageIndex: 1,
            pageSize: 1000
        });
        topics.value = Array.isArray(data.resultViewModels) ? data.resultViewModels : (data?.resultViewModels ?? []);
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('topic.listLoadError'),
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

let searchTimeout = null;

function onPartySearchInput(event) {
    const query = event.target.value;
    partySearchValue.value = query;
    
    if (searchTimeout) {
        clearTimeout(searchTimeout);
    }
    
    if (!query || query.trim().length < 2) {
        parties.value = [];
        return;
    }
    
    searchTimeout = setTimeout(() => {
        searchParties(query.trim());
    }, 300);
}

function selectParty(party) {
    // Eğer zaten seçili değilse ekle
    const isAlreadySelected = selectedParties.value.some(p => p.id === party.id);
    if (!isAlreadySelected) {
        selectedParties.value.push(party);
    }
    partySearchValue.value = '';
    parties.value = [];
}

function removeParty(partyId) {
    selectedParties.value = selectedParties.value.filter(p => p.id !== partyId);
}

async function searchParties(searchText) {
    if (!searchText || searchText.length < 2) {
        parties.value = [];
        return;
    }

    loadingParties.value = true;
    
    try {
        const data = await partyService.getLookup({
            SearchText: searchText,
            PartyLookupSearchType: 1
        });
        
        const viewModels = data?.ViewModels || data?.viewModels || [];
        parties.value = Array.isArray(viewModels) ? viewModels.map(vm => ({
            id: vm.PartyId ?? vm.partyId ?? vm.id ?? vm.Id,
            partyName: vm.PartyName ?? vm.partyName ?? ''
        })).filter(p => p.id && p.partyName) : [];
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('room.partySearchError'),
            life: 5000
        });
        parties.value = [];
    } finally {
        loadingParties.value = false;
    }
}

async function createRoom() {
    if (!formData.value.title || formData.value.title.trim() === '') {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('room.titlePlaceholder'),
            life: 3000
        });
        return;
    }

    if (!formData.value.topicId) {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('room.selectTopic'),
            life: 3000
        });
        return;
    }

    loading.value = true;
    try {
        await roomService.create({
            title: formData.value.title.trim(),
            topicId: formData.value.topicId,
            locationX: formData.value.locationX || 0,
            locationY: formData.value.locationY || 0,
            roomType: formData.value.roomType
        });

        // Oluşturulan room'un ID'sini bul
        const roomTitle = formData.value.title.trim();
        const roomList = await roomService.getList({
            pageIndex: 1,
            pageSize: 1000
        });
        
        const createdRoom = Array.isArray(roomList.resultViewModels) 
            ? roomList.resultViewModels.find(r => r.title === roomTitle)
            : null;
        
        if (createdRoom) {
            createdRoomId.value = createdRoom.id;
        }

        toast.add({
            severity: 'success',
            summary: t('common.success'),
            detail: t('room.createSuccess'),
            life: 3000
        });

        // Formu temizle
        formData.value = {
            title: '',
            topicId: null,
            locationX: null,
            locationY: null,
            roomType: 1
        };

        // Kişi davet etme bölümünü göster
        showInviteSection.value = true;
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('room.createError'),
            life: 5000
        });
    } finally {
        loading.value = false;
    }
}

function resetForm() {
    showInviteSection.value = false;
    createdRoomId.value = null;
    selectedParty.value = null;
    selectedParties.value = [];
    partySearchValue.value = '';
    parties.value = [];
    formData.value = {
        title: '',
        topicId: null,
        locationX: null,
        locationY: null,
        roomType: 1
    };
}

async function addPartyToRoom() {
    if (selectedParties.value.length === 0) {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('room.noPartySelected'),
            life: 3000
        });
        return;
    }

    if (!createdRoomId.value) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: 'Room ID bulunamadı',
            life: 3000
        });
        return;
    }

    try {
        const partyIds = selectedParties.value.map(p => p.id);
        
        await roomService.addPartiesToRoom(createdRoomId.value, partyIds);

        const partyCount = selectedParties.value.length;
        toast.add({
            severity: 'success',
            summary: t('common.success'),
            detail: partyCount === 1 
                ? t('room.partyAdded')
                : `${partyCount} ${t('room.partiesAdded') || 'kişi davet edildi'}`,
            life: 3000
        });

        // Seçimleri temizle ama dialog açık kalsın
        selectedParties.value = [];
        selectedParty.value = null;
        partySearchValue.value = '';
        parties.value = [];
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('room.partyAddError'),
            life: 5000
        });
    }
}

onMounted(() => {
    loadTopics();
    getCurrentLocation();
});
</script>

<template>
    <div class="create-room-container create-room-page">
        <div class="create-room-card">
            <h2 class="create-room-title">
                {{ showInviteSection ? t('room.invitePartyTitle') : t('room.createTitle') }}
            </h2>

            <!-- Room oluşturma formu -->
            <div v-if="!showInviteSection" class="form-grid">
                <div class="form-field">
                    <label for="title">{{ t('room.title') }} <span class="required">*</span></label>
                    <InputText
                        id="title"
                        v-model="formData.title"
                        :placeholder="t('room.titlePlaceholder')"
                        class="w-full"
                    />
                </div>

                <div class="form-field">
                    <label for="topic">{{ t('room.topic') }} <span class="required">*</span></label>
                    <Dropdown
                        id="topic"
                        v-model="formData.topicId"
                        :options="topics"
                        optionLabel="title"
                        optionValue="id"
                        :placeholder="t('room.selectTopic')"
                        filter
                        class="w-full"
                    />
                </div>

                <div class="form-field">
                    <label for="locationX">{{ t('room.locationX') }}</label>
                    <InputNumber
                        id="locationX"
                        v-model="formData.locationX"
                        :placeholder="t('room.locationX')"
                        class="w-full"
                        :minFractionDigits="0"
                        :maxFractionDigits="6"
                    />
                </div>

                <div class="form-field">
                    <label for="locationY">{{ t('room.locationY') }}</label>
                    <InputNumber
                        id="locationY"
                        v-model="formData.locationY"
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
                        v-model="formData.roomType"
                        :options="roomTypeOptions"
                        optionLabel="label"
                        optionValue="value"
                        class="w-full"
                    />
                </div>
            </div>

            <div v-if="!showInviteSection" class="form-actions">
                <Button
                    :label="t('common.create')"
                    icon="pi pi-check"
                    :loading="loading"
                    @click="createRoom"
                    class="create-button"
                />
            </div>

            <!-- Kişi davet etme bölümü -->
            <div v-if="showInviteSection" class="invite-section">
                <div class="invite-info">
                    <i class="pi pi-info-circle"></i>
                    <span>{{ t('room.inviteParty') }}</span>
                </div>

                <div class="party-select-section">
                    <label for="partySearch">{{ t('room.selectParty') || 'Kişi Seç' }}</label>
                    <div class="party-search-wrapper">
                        <InputText
                            id="partySearch"
                            v-model="partySearchValue"
                            :placeholder="t('room.searchParty') || 'Kişi ara...'"
                            class="w-full"
                            @input="onPartySearchInput"
                            autocomplete="off"
                            @keydown.enter.prevent="() => {}"
                        />
                        <div v-if="parties.length > 0 && partySearchValue && partySearchValue.length >= 2" class="party-dropdown">
                            <div
                                v-for="party in parties"
                                :key="party.id"
                                class="party-option"
                                :class="{ 'disabled': selectedParties.some(p => p.id === party.id) }"
                                @click="selectParty(party)"
                            >
                                <span>{{ party.partyName }}</span>
                                <i v-if="selectedParties.some(p => p.id === party.id)" class="pi pi-check" style="color: #6300FF; margin-left: auto;"></i>
                            </div>
                        </div>
                        <div v-if="loadingParties" class="party-loading">
                            <ProgressSpinner style="width: 20px; height: 20px" />
                        </div>
                    </div>

                    <!-- Seçili kişiler listesi -->
                    <div v-if="selectedParties.length > 0" class="selected-parties-container">
                        <label class="selected-parties-label">{{ t('room.selectedParties') || 'Seçili Kişiler' }} ({{ selectedParties.length }})</label>
                        <div class="selected-parties-list">
                            <div
                                v-for="party in selectedParties"
                                :key="party.id"
                                class="selected-party-tag"
                            >
                                <span class="party-tag-name">{{ party.partyName }}</span>
                                <Button
                                    icon="pi pi-times"
                                    severity="secondary"
                                    text
                                    rounded
                                    size="small"
                                    @click="removeParty(party.id)"
                                    class="party-tag-remove"
                                />
                            </div>
                        </div>
                    </div>

                    <div class="invite-actions">
                        <Button
                            :label="t('room.addParty') || 'Ekle'"
                            icon="pi pi-plus"
                            @click="addPartyToRoom"
                            :disabled="selectedParties.length === 0"
                            class="add-party-button"
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
    </div>
</template>

<style scoped lang="scss">
.create-room-container {
    padding: 2rem;
    max-width: 1000px;
    margin: 0 auto;
    min-height: calc(100vh - 200px);
    display: flex;
    align-items: flex-start;
    justify-content: center;
}

.create-room-card {
    position: relative;
    width: 100%;
    background: white;
    border-radius: 24px;
    padding: 3rem;
    box-shadow:
        0 4px 20px rgba(99, 0, 255, 0.08),
        0 2px 8px rgba(0, 0, 0, 0.04);
    border: 1.5px solid rgba(99, 0, 255, 0.1);
    animation: cardSlideIn 0.6s cubic-bezier(0.34, 1.56, 0.64, 1);
    overflow: hidden;
}

.create-room-card::before {
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

.create-room-card::after {
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

.create-room-card:hover::after {
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

.create-room-title {
    position: relative;
    font-size: 2rem;
    font-weight: 800;
    margin-bottom: 2.5rem;
    color: #1A1A1D;
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
        color: #374151;
        font-size: 0.95rem;
        letter-spacing: 0.01em;
        display: flex;
        align-items: center;
        gap: 0.25rem;

        .required {
            color: #ef4444;
            font-weight: 700;
        }
    }

    :deep(.p-inputtext),
    :deep(.p-inputnumber-input),
    :deep(.p-dropdown),
    :deep(.p-selectbutton) {
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        border-radius: 12px;
        border: 1.5px solid #e5e7eb;
        background: white;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
        padding: 0.75rem 1rem;
        font-size: 0.95rem;
        color: #374151;
    }

    :deep(.p-inputtext:focus),
    :deep(.p-inputnumber-input:focus),
    :deep(.p-dropdown:not(.p-disabled).p-focus),
    :deep(.p-selectbutton .p-button.p-highlight) {
        border-color: #6300FF;
        box-shadow:
            0 0 0 3px rgba(99, 0, 255, 0.1),
            0 2px 8px rgba(99, 0, 255, 0.15);
        transform: translateY(-1px);
        background: white;
    }

    :deep(.p-selectbutton .p-button) {
        border-radius: 10px;
        border: 1.5px solid #e5e7eb;
        background: white;
        color: #374151;
        transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        font-weight: 500;
    }

    :deep(.p-selectbutton .p-button.p-highlight) {
        background: linear-gradient(135deg, #6300FF, #5200CC);
        color: white;
        box-shadow: 0 4px 12px rgba(99, 0, 255, 0.3);
        transform: scale(1.05);
        border-color: #6300FF;
    }
    
    :deep(.p-selectbutton .p-button:not(.p-highlight):hover) {
        background: #f9fafb;
        border-color: #d1d5db;
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

.invite-section {
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

.invite-info {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1.25rem 1.5rem;
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.05), rgba(99, 0, 255, 0.02));
    border-radius: 16px;
    color: #374151;
    font-weight: 600;
    border: 1.5px solid rgba(99, 0, 255, 0.15);
    box-shadow: 0 2px 8px rgba(99, 0, 255, 0.08);

    i {
        color: #6300FF;
        font-size: 1.5rem;
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

.party-select-section {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;

    label {
        font-weight: 600;
        color: var(--text-color);
        font-size: 0.95rem;
        letter-spacing: 0.01em;
    }
}

.party-search-wrapper {
    position: relative;
}

.party-search-wrapper :deep(.p-inputtext) {
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    border-radius: 12px;
    border: 1.5px solid #e5e7eb;
    background: white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
    padding: 0.75rem 1rem;
    font-size: 0.95rem;
    color: #374151;
}

.party-search-wrapper :deep(.p-inputtext:focus) {
    border-color: #6300FF;
    box-shadow:
        0 0 0 3px rgba(99, 0, 255, 0.1),
        0 2px 8px rgba(99, 0, 255, 0.15);
    transform: translateY(-1px);
    background: white;
}

.party-dropdown {
    position: absolute;
    top: calc(100% + 8px);
    left: 0;
    right: 0;
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--surface-card) 98%, var(--primary-color)) 0%,
        var(--surface-card) 100%
    );
    border: 1.5px solid color-mix(in srgb, var(--primary-color) 20%, transparent);
    border-radius: 12px;
    box-shadow:
        0 8px 32px rgba(0, 0, 0, 0.15),
        0 2px 8px rgba(0, 0, 0, 0.1),
        inset 0 1px 0 rgba(255, 255, 255, 0.5);
    max-height: 250px;
    overflow-y: auto;
    z-index: 1000;
    backdrop-filter: blur(20px);
    animation: dropdownSlideIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes dropdownSlideIn {
    from {
        opacity: 0;
        transform: translateY(-10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.party-option {
    padding: 1rem 1.25rem;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    border-bottom: 1px solid color-mix(in srgb, var(--primary-color) 10%, transparent);
    color: var(--text-color);
    font-weight: 500;
    position: relative;
    overflow: hidden;
    display: flex;
    align-items: center;
    gap: 0.5rem;

    &::before {
        content: '';
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        width: 0;
        background: linear-gradient(
            90deg,
            color-mix(in srgb, var(--primary-color) 20%, transparent) 0%,
            transparent 100%
        );
        transition: width 0.3s;
    }

    &:last-child {
        border-bottom: none;
    }

    &.disabled {
        opacity: 0.5;
        cursor: not-allowed;
        background: rgba(99, 0, 255, 0.05);
    }

    &:not(.disabled):hover {
        background: linear-gradient(
            135deg,
            color-mix(in srgb, var(--primary-color) 15%, var(--surface-0)) 0%,
            color-mix(in srgb, var(--primary-color) 8%, var(--surface-0)) 100%
        );
        transform: translateX(4px);
        box-shadow: 0 2px 8px color-mix(in srgb, var(--primary-color) 15%, rgba(0, 0, 0, 0.1));
    }

    &:not(.disabled):hover::before {
        width: 4px;
    }
}

.party-loading {
    position: absolute;
    right: 1rem;
    top: 50%;
    transform: translateY(-50%);
    pointer-events: none;
    z-index: 10;
}

.selected-parties-container {
    margin-top: 1rem;
    animation: selectedPartySlideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.selected-parties-label {
    font-weight: 600;
    color: var(--text-color);
    font-size: 0.9rem;
    margin-bottom: 0.75rem;
    display: block;
}

.selected-parties-list {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
}

.selected-party-tag {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.625rem 1rem;
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 12%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 8%, var(--surface-0)) 100%
    );
    border-radius: 20px;
    border: 1.5px solid color-mix(in srgb, var(--primary-color) 25%, transparent);
    box-shadow:
        0 2px 8px color-mix(in srgb, var(--primary-color) 15%, rgba(0, 0, 0, 0.08)),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);

    &:hover {
        transform: translateY(-2px);
        box-shadow:
            0 4px 12px color-mix(in srgb, var(--primary-color) 20%, rgba(0, 0, 0, 0.12)),
            inset 0 1px 0 rgba(255, 255, 255, 0.5);
    }
}

.party-tag-name {
    color: var(--text-color);
    font-weight: 600;
    font-size: 0.875rem;
    white-space: nowrap;
}

.party-tag-remove {
    padding: 0.25rem !important;
    width: 1.5rem !important;
    height: 1.5rem !important;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);

    &:hover {
        transform: scale(1.15) rotate(90deg);
        color: #ef4444 !important;
    }
}

// Backward compatibility için eski stil
.selected-party {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1rem 1.25rem;
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 12%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 8%, var(--surface-0)) 100%
    );
    border-radius: 12px;
    margin-top: 0.5rem;
    border: 1.5px solid color-mix(in srgb, var(--primary-color) 25%, transparent);
    box-shadow:
        0 2px 8px color-mix(in srgb, var(--primary-color) 15%, rgba(0, 0, 0, 0.08)),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
    animation: selectedPartySlideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);

    span {
        color: var(--text-color);
        font-weight: 500;

        strong {
            color: var(--primary-color);
            font-weight: 700;
        }
    }

    :deep(.p-button) {
        transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    }

    :deep(.p-button:hover) {
        transform: scale(1.1) rotate(90deg);
    }
}

@keyframes selectedPartySlideIn {
    from {
        opacity: 0;
        transform: translateX(-20px);
    }
    to {
        opacity: 1;
        transform: translateX(0);
    }
}

.invite-actions {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
}

.add-party-button {
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

.add-party-button::before {
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

.add-party-button:hover::before {
    width: 400px;
    height: 400px;
    opacity: 1;
}

.add-party-button:hover:not(:disabled) {
    transform: translateY(-3px) scale(1.02);
    box-shadow:
        0 8px 32px color-mix(in srgb, var(--primary-color) 40%, rgba(0, 0, 0, 0.3)),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
}

.add-party-button :deep(.p-button-icon) {
    transition: transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.add-party-button:hover:not(:disabled) :deep(.p-button-icon) {
    transform: scale(1.15) rotate(-5deg);
}

.invite-actions :deep(.p-button-outlined) {
    border-radius: 12px;
    font-weight: 600;
    padding: 0.875rem 2rem;
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.invite-actions :deep(.p-button-outlined:hover) {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}
</style>
