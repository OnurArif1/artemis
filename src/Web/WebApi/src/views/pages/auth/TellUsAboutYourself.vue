<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useI18n } from '@/composables/useI18n';
import { useAuthStore } from '@/stores/auth';
import request from '@/service/request';
import PartyService from '@/service/PartyService';
import { getEmailFromToken } from '@/utils/jwt';

const router = useRouter();
const { t } = useI18n();
const toast = useToast();
const authStore = useAuthStore();
const partyService = new PartyService(request);

const bio = ref('');
const saving = ref(false);

const saveProfile = async () => {
    // Get email from JWT token
    const token = authStore.token || localStorage.getItem('auth.token');
    const email = getEmailFromToken(token);
    
    if (!email) {
        toast.add({
            severity: 'error',
            summary: 'Hata',
            detail: 'Kullanıcı bilgileri bulunamadı. Lütfen tekrar giriş yapın.',
            life: 5000
        });
        return;
    }

    saving.value = true;
    try {
        // Full name güncellemiyoruz, email'i partyName olarak gönderiyoruz (backend zorunlu kılıyor)
        // Bio'yu güvenli bir şekilde gönderiyoruz
        const bioValue = bio.value ? bio.value.trim() : '';
        await partyService.updateProfile(email, email, bioValue || null);
        toast.add({
            severity: 'success',
            summary: 'Başarılı',
            detail: 'Profil bilgileriniz kaydedildi.',
            life: 3000
        });
        router.push({ name: 'selectPurposes' });
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || 'Profil bilgileri kaydedilirken bir hata oluştu.',
            life: 5000
        });
    } finally {
        saving.value = false;
    }
};

onMounted(() => {
    // Ensure auth store is hydrated from localStorage before making API calls
    authStore.hydrateFromStorage();
});
</script>

<template>
    <div class="tell-us-about-yourself-page">
        <!-- Animasyonlu arka plan -->
        <div class="page-background"></div>
        
        <!-- Animasyonlu gradient blobs -->
        <div class="animated-blob blob-1"></div>
        <div class="animated-blob blob-2"></div>
        <div class="animated-blob blob-3"></div>
        <div class="animated-blob blob-4"></div>
        
        <!-- Floating particles -->
        <div class="floating-particle particle-1"></div>
        <div class="floating-particle particle-2"></div>
        <div class="floating-particle particle-3"></div>
        <div class="floating-particle particle-4"></div>
        <div class="floating-particle particle-5"></div>
        <div class="floating-particle particle-6"></div>
    

        <div class="page-content">
            <!-- Beyaz kart -->
            <div class="main-card">
                <!-- Başlık çubuğu -->
                <div class="card-header">
                    <div class="flex items-center gap-3">
                        <div class="header-icon">
                            <i class="pi pi-user text-white text-xl"></i>
                        </div>
                        <div>
                            <h1 class="card-title">Bize kendinizden bahsedin</h1>
                            <p class="card-subtitle">Adım 2 / 2</p>
                        </div>
                    </div>
                </div>

                <!-- İçerik alanı -->
                <div class="content-area">
                    <!-- Form -->
                    <form @submit.prevent="saveProfile" class="form-container">
                        <!-- Bio alanı -->
                        <div class="form-group">
                            <label for="bio" class="form-label">
                                Bio
                            </label>
                            <textarea
                                id="bio"
                                v-model="bio"
                                rows="6"
                                placeholder="Kendiniz hakkında bir şeyler yazın..."
                                class="form-textarea"
                            ></textarea>
                        </div>

                        <!-- Devam Et butonu -->
                        <div class="button-container">
                            <button
                                type="submit"
                                :disabled="saving"
                                class="continue-button"
                            >
                                <span v-if="!saving">Devam Et</span>
                                <span v-else class="flex items-center justify-center gap-2">
                                    <i class="pi pi-spin pi-spinner"></i>
                                    Kaydediliyor...
                                </span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <Toast />
    </div>
</template>

<style scoped>
.tell-us-about-yourself-page {
    position: fixed;
    inset: 0;
    overflow: hidden;
}

.page-background {
    position: fixed;
    inset: 0;
    background: linear-gradient(135deg, #f3f0ff 0%, #ffffff 50%, #f3f0ff 100%);
    z-index: 0;
}

.progress-bar {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: rgba(229, 231, 235, 0.5);
    z-index: 10;
}

.progress-fill {
    height: 100%;
    background: linear-gradient(90deg, #6300FF, #5200CC);
    transition: width 0.3s ease;
}

.page-content {
    position: relative;
    z-index: 1;
    width: 100%;
    max-width: 800px;
    margin: 0 auto;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
    padding-top: 1.5rem;
}

.main-card {
    background: white;
    border-radius: 1.5rem;
    box-shadow: 0 10px 40px rgba(99, 0, 255, 0.1);
    overflow: hidden;
    border: 1px solid rgba(99, 0, 255, 0.1);
    width: 100%;
    max-height: 90vh;
    display: flex;
    flex-direction: column;
}

.card-header {
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.08), rgba(99, 0, 255, 0.03));
    padding: 1.25rem 1.5rem;
    border-bottom: 1px solid rgba(99, 0, 255, 0.1);
    flex-shrink: 0;
}

.header-icon {
    width: 2.5rem;
    height: 2.5rem;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    border-radius: 0.75rem;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 4px 12px rgba(99, 0, 255, 0.2);
}

.card-title {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1A1A1D;
    margin: 0;
}

.card-subtitle {
    color: #6b7280;
    font-size: 0.875rem;
    font-weight: 500;
    margin: 0.25rem 0 0 0;
}

@media (min-width: 640px) {
    .card-header {
        padding: 1.5rem 2rem;
    }
    .header-icon {
        width: 3rem;
        height: 3rem;
    }
    .card-title {
        font-size: 1.75rem;
    }
}

@media (min-width: 1024px) {
    .card-header {
        padding: 1.75rem 2.5rem;
    }
    .card-title {
        font-size: 2rem;
    }
}

.content-area {
    padding: 1.5rem;
    width: 100%;
    flex: 1;
    overflow-y: auto;
    overflow-x: hidden;
}

.content-area::-webkit-scrollbar {
    width: 6px;
}

.content-area::-webkit-scrollbar-track {
    background: transparent;
}

.content-area::-webkit-scrollbar-thumb {
    background: rgba(99, 0, 255, 0.2);
    border-radius: 3px;
}

.content-area::-webkit-scrollbar-thumb:hover {
    background: rgba(99, 0, 255, 0.3);
}

@media (min-width: 640px) {
    .content-area {
        padding: 2rem;
    }
}

@media (min-width: 1024px) {
    .content-area {
        padding: 2.5rem;
    }
}

.form-container {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
}

.form-group {
    display: flex;
    flex-direction: column;
}

.form-label {
    display: block;
    font-size: 0.9375rem;
    font-weight: 500;
    color: #374151;
    margin-bottom: 0.5rem;
}

.form-input,
.form-textarea {
    width: 100%;
    padding: 0.875rem 1rem;
    background: white;
    border: 1.5px solid #e5e7eb;
    border-radius: 0.75rem;
    font-size: 0.9375rem;
    color: #1A1A1D;
    transition: all 0.2s ease;
    font-family: inherit;
}

.form-input::placeholder,
.form-textarea::placeholder {
    color: #9ca3af;
}

.form-input:focus,
.form-textarea:focus {
    outline: none;
    border-color: #6300FF;
    box-shadow: 0 0 0 3px rgba(99, 0, 255, 0.1);
}

.form-textarea {
    resize: vertical;
    min-height: 120px;
    line-height: 1.5;
}

.button-container {
    display: flex;
    justify-content: center;
    padding-top: 0.5rem;
    flex-shrink: 0;
}

.continue-button {
    width: 100%;
    padding: 1rem 2rem;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    font-weight: 600;
    font-size: 1rem;
    border: none;
    border-radius: 0.75rem;
    box-shadow: 0 4px 12px rgba(99, 0, 255, 0.3);
    transition: all 0.3s ease;
    cursor: pointer;
    transform: translateY(0);
}

.continue-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(99, 0, 255, 0.4);
}

.continue-button:active:not(:disabled) {
    transform: translateY(0);
}

.continue-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
}

/* Animated Gradient Blobs - Fixed position */
.animated-blob {
    position: fixed;
    border-radius: 50%;
    filter: blur(80px);
    opacity: 0.3;
    animation: blob-animation 20s ease-in-out infinite;
    pointer-events: none;
    z-index: 0;
}

.blob-1 {
    width: 300px;
    height: 300px;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    top: -50px;
    left: -50px;
    animation-delay: 0s;
}

.blob-2 {
    width: 280px;
    height: 280px;
    background: linear-gradient(135deg, #5200CC, #4100AA);
    bottom: -30px;
    right: -30px;
    animation-delay: 5s;
}

.blob-3 {
    width: 250px;
    height: 250px;
    background: linear-gradient(135deg, #6300FF, rgba(99, 0, 255, 0.5));
    top: 50%;
    right: 5%;
    animation-delay: 10s;
}

.blob-4 {
    width: 240px;
    height: 240px;
    background: linear-gradient(135deg, rgba(82, 0, 204, 0.6), #6300FF);
    bottom: 20%;
    left: 3%;
    animation-delay: 15s;
}

@media (max-width: 768px) {
    .animated-blob {
        opacity: 0.2;
        filter: blur(60px);
    }
    
    .blob-1, .blob-2, .blob-3, .blob-4 {
        width: 200px;
        height: 200px;
    }
}

@keyframes blob-animation {
    0%, 100% {
        transform: translate(0, 0) scale(1);
    }
    25% {
        transform: translate(50px, -50px) scale(1.1);
    }
    50% {
        transform: translate(-30px, 30px) scale(0.9);
    }
    75% {
        transform: translate(30px, 50px) scale(1.05);
    }
}

/* Floating Particles - Fixed position */
.floating-particle {
    position: fixed;
    width: 8px;
    height: 8px;
    background: #6300FF;
    border-radius: 50%;
    opacity: 0.25;
    animation: float-particle 15s ease-in-out infinite;
    pointer-events: none;
    z-index: 0;
}

.particle-1 {
    top: 20%;
    left: 10%;
    animation-delay: 0s;
    width: 6px;
    height: 6px;
}

.particle-2 {
    top: 60%;
    left: 15%;
    animation-delay: 2s;
    width: 10px;
    height: 10px;
    background: #5200CC;
}

.particle-3 {
    top: 30%;
    right: 20%;
    animation-delay: 4s;
    width: 8px;
    height: 8px;
}

.particle-4 {
    bottom: 25%;
    right: 15%;
    animation-delay: 6s;
    width: 7px;
    height: 7px;
    background: #4100AA;
}

.particle-5 {
    top: 70%;
    left: 25%;
    animation-delay: 8s;
    width: 9px;
    height: 9px;
}

.particle-6 {
    bottom: 40%;
    left: 30%;
    animation-delay: 10s;
    width: 8px;
    height: 8px;
}

@media (max-width: 768px) {
    .floating-particle {
        display: none;
    }
}

@keyframes float-particle {
    0%, 100% {
        transform: translate(0, 0) scale(1);
        opacity: 0.25;
    }
    25% {
        transform: translate(30px, -40px) scale(1.2);
        opacity: 0.4;
    }
    50% {
        transform: translate(-20px, 20px) scale(0.8);
        opacity: 0.15;
    }
    75% {
        transform: translate(20px, 30px) scale(1.1);
        opacity: 0.35;
    }
}
</style>
