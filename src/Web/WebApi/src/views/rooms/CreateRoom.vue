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
const selectedParty = ref(null);
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
        console.error('Topic yükleme hatası:', err);
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
    selectedParty.value = party;
    partySearchValue.value = party.partyName;
    parties.value = [];
}

async function searchParties(searchText) {
    if (!searchText || searchText.length < 2) {
        parties.value = [];
        return;
    }

    loadingParties.value = true;
    console.log('API çağrısı yapılıyor:', { SearchText: searchText, PartyLookupSearchType: 1 });
    
    try {
        const data = await partyService.getLookup({
            SearchText: searchText,
            PartyLookupSearchType: 1 // PartyName = 1
        });
        console.log('Arama sonuçları:', data);
        
        // API'den ViewModels (büyük V) veya viewModels (küçük v) dönebilir
        const viewModels = data?.ViewModels || data?.viewModels || [];
        parties.value = Array.isArray(viewModels) ? viewModels.map(vm => ({
            id: vm.PartyId ?? vm.partyId ?? vm.id ?? vm.Id,
            partyName: vm.PartyName ?? vm.partyName ?? ''
        })).filter(p => p.id && p.partyName) : [];
        
        console.log('Parse edilmiş parties:', parties.value);
    } catch (err) {
        console.error('Party arama hatası:', err);
        console.error('Hata detayı:', err?.response?.data);
        console.error('Hata response:', err?.response);
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
    if (!selectedParty.value) {
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
        await roomService.addPartyToRoom({
            roomId: createdRoomId.value,
            partyId: selectedParty.value.id
        });

        toast.add({
            severity: 'success',
            summary: t('common.success'),
            detail: t('room.partyAdded'),
            life: 3000
        });

        // Seçimi temizle ama dialog açık kalsın
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
    <div class="create-room-container">
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
                    <label for="partySearch">{{ t('room.selectParty') }}</label>
                    <div class="party-search-wrapper">
                        <InputText
                            id="partySearch"
                            v-model="partySearchValue"
                            :placeholder="t('room.searchParty')"
                            class="w-full"
                            @input="onPartySearchInput"
                            autocomplete="off"
                        />
                        <div v-if="parties.length > 0 && partySearchValue && partySearchValue.length >= 2" class="party-dropdown">
                            <div
                                v-for="party in parties"
                                :key="party.id"
                                class="party-option"
                                @click="selectParty(party)"
                            >
                                {{ party.partyName }}
                            </div>
                        </div>
                        <div v-if="loadingParties" class="party-loading">
                            <ProgressSpinner style="width: 20px; height: 20px" />
                        </div>
                    </div>

                    <div v-if="selectedParty" class="selected-party">
                        <span>{{ t('room.selectParty') }}: <strong>{{ selectedParty.partyName }}</strong></span>
                        <Button
                            icon="pi pi-times"
                            severity="secondary"
                            text
                            rounded
                            @click="selectedParty = null; partySearchValue = ''"
                        />
                    </div>

                    <div class="invite-actions">
                        <Button
                            :label="t('room.addParty')"
                            icon="pi pi-plus"
                            @click="addPartyToRoom"
                            :disabled="!selectedParty"
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
    max-width: 900px;
    margin: 0 auto;
}

.create-room-card {
    background: var(--surface-card);
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.create-room-title {
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

.invite-section {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
    padding: 1rem 0;
}

.invite-info {
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

.party-select-section {
    display: flex;
    flex-direction: column;
    gap: 1rem;

    label {
        font-weight: 500;
        color: var(--text-color);
    }
}

.invite-actions {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
}

.add-party-button {
    min-width: 150px;
}

.party-search-wrapper {
    position: relative;
}

.party-dropdown {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    background: var(--surface-card);
    border: 1px solid var(--surface-border);
    border-radius: 6px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    max-height: 200px;
    overflow-y: auto;
    z-index: 1000;
    margin-top: 4px;
}

.party-option {
    padding: 0.75rem 1rem;
    cursor: pointer;
    transition: background-color 0.2s;
    border-bottom: 1px solid var(--surface-border);

    &:last-child {
        border-bottom: none;
    }

    &:hover {
        background-color: var(--surface-hover);
    }
}

.party-loading {
    position: absolute;
    right: 0.75rem;
    top: 50%;
    transform: translateY(-50%);
    pointer-events: none;
}

.selected-party {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.75rem;
    background: var(--surface-100);
    border-radius: 6px;
    margin-top: 0.5rem;
}
</style>
