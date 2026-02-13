<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useI18n } from '@/composables/useI18n';
import { useAuthStore } from '@/stores/auth';
import request from '@/service/request';
import PartyService from '@/service/PartyService';
import InterestService from '@/service/InterestService';
import { getEmailFromToken } from '@/utils/jwt';
import ProgressSpinner from 'primevue/progressspinner';
import Textarea from 'primevue/textarea';
import Button from 'primevue/button';

const router = useRouter();
const { t } = useI18n();
const toast = useToast();
const authStore = useAuthStore();
const partyService = new PartyService(request);
const interestService = new InterestService(request);

const loading = ref(true);
const userEmail = ref('');
const partyName = ref('');
const description = ref('');
const interests = ref([]);
const userInitial = ref('');

const isEditing = ref(false);
const editingDescription = ref('');

const loadProfile = async () => {
    loading.value = true;
    try {
        const token = authStore.token || localStorage.getItem('auth.token');
        if (!token) {
            toast.add({
                severity: 'error',
                summary: t('common.error'),
                detail: 'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.',
                life: 5000
            });
            router.push({ name: 'login' });
            return;
        }

        const email = getEmailFromToken(token);
        if (!email) {
            toast.add({
                severity: 'error',
                summary: t('common.error'),
                detail: 'Kullanıcı bilgileri bulunamadı.',
                life: 5000
            });
            return;
        }

        userEmail.value = email;
        userInitial.value = email.charAt(0).toUpperCase();

        // Party bilgilerini çek
        const lookupResult = await partyService.getLookup({
            searchText: email,
            partyLookupSearchType: 3 // Email ile arama
        });

        if (lookupResult && lookupResult.viewModels && lookupResult.viewModels.length > 0) {
            const party = lookupResult.viewModels.find((p) => 
                p.email?.toLowerCase() === email.toLowerCase() || 
                p.partyName?.toLowerCase() === email.toLowerCase()
            ) || lookupResult.viewModels[0];

            partyName.value = party.partyName || email;
            description.value = party.description || '';
        } else {
            partyName.value = email;
            description.value = '';
        }

        // İlgi alanlarını çek
        try {
            const interestsData = await interestService.getMyInterests();
            if (interestsData && Array.isArray(interestsData)) {
                interests.value = interestsData.map(i => i.name || i);
            } else if (interestsData?.viewModels) {
                interests.value = interestsData.viewModels.map(i => i.name || i);
            }
        } catch (err) {
            console.warn('İlgi alanları yüklenemedi:', err);
            interests.value = [];
        }
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || 'Profil bilgileri yüklenirken bir hata oluştu.',
            life: 5000
        });
    } finally {
        loading.value = false;
    }
};

const startEditing = () => {
    isEditing.value = true;
    editingDescription.value = description.value;
};

const cancelEditing = () => {
    isEditing.value = false;
    editingDescription.value = '';
};

const saveDescription = async () => {
    try {
        const token = authStore.token || localStorage.getItem('auth.token');
        const email = getEmailFromToken(token);
        
        if (!email) {
            toast.add({
                severity: 'error',
                summary: t('common.error'),
                detail: 'Kullanıcı bilgileri bulunamadı.',
                life: 5000
            });
            return;
        }

        await partyService.updateProfile(
            email,
            partyName.value || email,
            editingDescription.value.trim() || null
        );

        description.value = editingDescription.value.trim();
        isEditing.value = false;

        toast.add({
            severity: 'success',
            summary: t('common.success'),
            detail: 'Profil bilgileriniz güncellendi.',
            life: 3000
        });
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || 'Profil güncellenirken bir hata oluştu.',
            life: 5000
        });
    }
};

const onLogout = () => {
    authStore.clearToken();
    router.push({ name: 'login' });
};

onMounted(() => {
    loadProfile();
});
</script>

<template>
    <div class="profile-page">
        <div class="profile-container">
            <!-- Header -->
            <div class="profile-header">
                <div class="profile-avatar">
                    <span class="avatar-initial">{{ userInitial }}</span>
                </div>
                <h1 class="profile-name">{{ partyName || userEmail }}</h1>
                <p class="profile-email">{{ userEmail }}</p>
            </div>

            <!-- Loading State -->
            <div v-if="loading" class="loading-container">
                <ProgressSpinner />
                <span class="ml-2">{{ t('common.loading') }}</span>
            </div>

            <!-- Profile Content -->
            <div v-else class="profile-content">
                <!-- Description Section -->
                <div class="profile-section">
                    <div class="section-header">
                        <h2 class="section-title">
                            <i class="pi pi-info-circle"></i>
                            {{ t('profile.about') || 'Hakkımda' }}
                        </h2>
                        <Button
                            v-if="!isEditing"
                            icon="pi pi-pencil"
                            label="Düzenle"
                            text
                            size="small"
                            @click="startEditing"
                            class="edit-button"
                        />
                    </div>

                    <div v-if="!isEditing" class="section-content">
                        <p v-if="description" class="description-text">{{ description }}</p>
                        <p v-else class="description-placeholder">
                            {{ t('profile.noDescription') || 'Henüz bir açıklama eklenmemiş.' }}
                        </p>
                    </div>

                    <div v-else class="section-content editing">
                        <Textarea
                            v-model="editingDescription"
                            :placeholder="t('profile.descriptionPlaceholder') || 'Kendiniz hakkında bir şeyler yazın...'"
                            rows="5"
                            class="w-full"
                            :autoResize="true"
                        />
                        <div class="edit-actions">
                            <Button
                                label="İptal"
                                severity="secondary"
                                outlined
                                size="small"
                                @click="cancelEditing"
                            />
                            <Button
                                label="Kaydet"
                                icon="pi pi-check"
                                size="small"
                                @click="saveDescription"
                            />
                        </div>
                    </div>
                </div>

                <!-- Interests Section -->
                <div v-if="interests.length > 0" class="profile-section">
                    <h2 class="section-title">
                        <i class="pi pi-heart"></i>
                        {{ t('profile.interests') || 'İlgi Alanlarım' }}
                    </h2>
                    <div class="interests-container">
                        <span
                            v-for="(interest, index) in interests"
                            :key="index"
                            class="interest-tag"
                        >
                            {{ interest }}
                        </span>
                    </div>
                </div>

                <!-- Actions -->
                <div class="profile-actions">
                    <Button
                        label="Çıkış Yap"
                        icon="pi pi-sign-out"
                        severity="danger"
                        outlined
                        @click="onLogout"
                        class="logout-button"
                    />
                </div>
            </div>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.profile-page {
    min-height: calc(100vh - 200px);
    padding: 2rem;
    display: flex;
    justify-content: center;
    align-items: flex-start;
}

.profile-container {
    width: 100%;
    max-width: 800px;
    background: white;
    border-radius: 24px;
    padding: 3rem;
    box-shadow:
        0 4px 20px rgba(99, 0, 255, 0.08),
        0 2px 8px rgba(0, 0, 0, 0.04);
    border: 1.5px solid rgba(99, 0, 255, 0.1);
}

.profile-header {
    text-align: center;
    margin-bottom: 3rem;
    padding-bottom: 2rem;
    border-bottom: 2px solid rgba(99, 0, 255, 0.1);
}

.profile-avatar {
    width: 120px;
    height: 120px;
    margin: 0 auto 1.5rem;
    border-radius: 50%;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 8px 24px rgba(99, 0, 255, 0.3);
    border: 4px solid white;
}

.avatar-initial {
    font-size: 3rem;
    font-weight: 800;
    color: white;
    text-transform: uppercase;
}

.profile-name {
    font-size: 2rem;
    font-weight: 800;
    color: #1A1A1D;
    margin-bottom: 0.5rem;
    letter-spacing: -0.02em;
}

.profile-email {
    font-size: 1rem;
    color: #666;
    margin: 0;
}

.loading-container {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 4rem 0;
}

.profile-content {
    display: flex;
    flex-direction: column;
    gap: 2rem;
}

.profile-section {
    padding: 1.5rem;
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.02), rgba(255, 255, 255, 1));
    border-radius: 16px;
    border: 1px solid rgba(99, 0, 255, 0.1);
}

.section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
}

.section-title {
    font-size: 1.25rem;
    font-weight: 700;
    color: #1A1A1D;
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin: 0;

    i {
        color: #6300FF;
        font-size: 1.1rem;
    }
}

.edit-button {
    color: #6300FF;
    font-weight: 600;
}

.section-content {
    color: #374151;
    line-height: 1.6;

    &.editing {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
}

.description-text {
    margin: 0;
    white-space: pre-wrap;
}

.description-placeholder {
    margin: 0;
    color: #9ca3af;
    font-style: italic;
}

.edit-actions {
    display: flex;
    gap: 0.75rem;
    justify-content: flex-end;
}

.interests-container {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-top: 1rem;
}

.interest-tag {
    padding: 0.5rem 1rem;
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.1), rgba(99, 0, 255, 0.05));
    border: 1px solid rgba(99, 0, 255, 0.2);
    border-radius: 20px;
    color: #6300FF;
    font-weight: 600;
    font-size: 0.875rem;
    transition: all 0.3s;

    &:hover {
        background: linear-gradient(135deg, rgba(99, 0, 255, 0.15), rgba(99, 0, 255, 0.1));
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(99, 0, 255, 0.2);
    }
}

.profile-actions {
    display: flex;
    justify-content: center;
    padding-top: 1rem;
    border-top: 2px solid rgba(99, 0, 255, 0.1);
}

.logout-button {
    min-width: 200px;
}

:deep(.p-textarea) {
    border-radius: 12px;
    border: 1.5px solid #e5e7eb;
    transition: all 0.3s;

    &:focus {
        border-color: #6300FF;
        box-shadow: 0 0 0 3px rgba(99, 0, 255, 0.1);
    }
}

@media (max-width: 768px) {
    .profile-page {
        padding: 1rem;
    }

    .profile-container {
        padding: 2rem 1.5rem;
    }

    .profile-avatar {
        width: 100px;
        height: 100px;
    }

    .avatar-initial {
        font-size: 2.5rem;
    }

    .profile-name {
        font-size: 1.5rem;
    }
}
</style>
