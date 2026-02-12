<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useI18n } from '@/composables/useI18n';
import { useAuthStore } from '@/stores/auth';
import { getEmailFromToken } from '@/utils/jwt';
import request from '@/service/request';
import InterestService from '@/service/InterestService';

const router = useRouter();
const { t } = useI18n();
const toast = useToast();
const authStore = useAuthStore();
const interestService = new InterestService(request);

const interests = ref([]);
const selectedInterests = ref([]);
const loading = ref(false);
const saving = ref(false);

// İlgi alanları için emoji eşleştirmeleri
const interestEmojis = {
    'Sports': '⚽',
    'Fitness': '💪',
    'Hiking': '🥾',
    'Coffee': '☕',
    'Food': '🍕',
    'Cooking': '🧑‍🍳',
    'Music': '🎵',
    'Concerts': '🎤',
    'Art': '🎨',
    'Photography': '📸',
    'Travel': '✈️',
    'Books': '📚',
    'Movies': '🎬',
    'Gaming': '🎮',
    'Tech': '💻',
    'Business': '💼',
    'Meditation': '🧘',
    'Yoga': '🧘‍♀️',
    'Dancing': '💃',
    'Languages': '🌍',
    'Volunteering': '🤝',
    'Nature': '🌲',
    'Animals': '🐾',
    'Outdoor': '🏕️'
};

const getEmoji = (interestName) => {
    return interestEmojis[interestName] || '⭐';
};

const toggleInterest = (interestId) => {
    const index = selectedInterests.value.indexOf(interestId);
    if (index > -1) {
        selectedInterests.value.splice(index, 1);
    } else {
        selectedInterests.value.push(interestId);
    }
};

const isSelected = (interestId) => {
    return selectedInterests.value.includes(interestId);
};

const loadInterests = async () => {
    loading.value = true;
    try {
        const data = await interestService.getList();
        console.log('Yüklenen ilgi alanları:', data);
        interests.value = Array.isArray(data) ? data : [];
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || 'İlgi alanları yüklenirken bir hata oluştu.',
            life: 5000
        });
    } finally {
        loading.value = false;
    }
};

const saveInterests = async () => {
    if (selectedInterests.value.length === 0) {
        toast.add({
            severity: 'warn',
            summary: 'Uyarı',
            detail: 'En az bir ilgi alanı seçmelisiniz.',
            life: 3000
        });
        return;
    }

    // Get email from JWT token
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
            detail: 'Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.',
            life: 5000
        });
        router.push({ name: 'login' });
        return;
    }

    saving.value = true;
    try {
        await interestService.savePartyInterests(email, selectedInterests.value);
        toast.add({
            severity: 'success',
            summary: 'Başarılı',
            detail: 'İlgi alanlarınız kaydedildi.',
            life: 3000
        });
        router.push({ name: 'tellUsAboutYourself' });
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || 'İlgi alanları kaydedilirken bir hata oluştu.',
            life: 5000
        });
    } finally {
        saving.value = false;
    }
};

onMounted(async () => {
    // Ensure auth store is hydrated from localStorage before making API calls
    authStore.hydrateFromStorage();
    
    // Small delay to ensure token is set
    await new Promise(resolve => setTimeout(resolve, 100));
    
    loadInterests();
});
</script>

<template>
    <div class="select-interests-page">
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
            <!-- Beyaz kart - Daha ferah -->
            <div class="main-card">
                <!-- Başlık çubuğu - Daha hafif -->
                <div class="card-header">
                    <div class="flex items-center gap-3">
                        <div class="header-icon">
                            <i class="pi pi-heart text-white text-xl"></i>
                        </div>
                        <div>
                            <h1 class="card-title">İlgi Alanlarınız</h1>
                            <p class="card-subtitle">Adım 1 / 2</p>
                        </div>
                    </div>
                </div>

                <!-- İçerik alanı - Responsive padding -->
                <div class="content-area">
                    <!-- Talimat metni -->
                    <p class="instruction-text">
                        Benzer düşünen insanlarla eşleşmenize yardımcı olmak için en az 1 ilgi alanı seçin
                    </p>

                    <!-- Loading durumu -->
                    <div v-if="loading" class="loading-container">
                        <div class="flex flex-col items-center gap-4">
                            <i class="pi pi-spin pi-spinner text-4xl text-electric-purple"></i>
                            <p class="text-gray-500">Yükleniyor...</p>
                        </div>
                    </div>

                    <!-- İlgi alanları grid - Responsive -->
                    <div v-else class="interests-grid">
                        <button
                            v-for="interest in interests"
                            :key="interest.id"
                            @click="toggleInterest(interest.id)"
                            :class="[
                                'interest-card',
                                isSelected(interest.id) ? 'interest-selected' : 'interest-default'
                            ]"
                        >
                            <span class="text-4xl mb-3">{{ getEmoji(interest.name) }}</span>
                            <span :class="[
                                'text-sm font-medium text-center leading-tight',
                                isSelected(interest.id) ? 'text-electric-purple' : 'text-gray-700'
                            ]">
                                {{ t(`interest.${interest.name}`) }}
                            </span>
                        </button>
                    </div>

                    <!-- Kaydet butonu -->
                    <div class="button-container">
                        <button
                            @click="saveInterests"
                            :disabled="selectedInterests.length === 0 || saving"
                            class="continue-button"
                        >
                            <span v-if="!saving">Devam Et</span>
                            <span v-else class="flex items-center gap-2">
                                <i class="pi pi-spin pi-spinner"></i>
                                Kaydediliyor...
                            </span>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <Toast />
    </div>
</template>

<style scoped>
.select-interests-page {
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

.page-content {
    position: relative;
    z-index: 1;
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
}

.content-area {
    padding: 1rem;
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    max-height: 100vh;
    overflow: hidden;
}

@media (min-width: 640px) {
    .page-content {
        padding: 1.5rem;
    }
    .content-area {
        padding: 1.5rem;
    }
}

@media (min-width: 1024px) {
    .page-content {
        padding: 2rem;
    }
    .content-area {
        padding: 2rem;
    }
}

.instruction-text {
    color: #6b7280;
    text-align: center;
    margin-bottom: 0.75rem;
    font-size: 0.8125rem;
    line-height: 1.4;
    max-width: 32rem;
    margin-left: auto;
    margin-right: auto;
    flex-shrink: 0;
}

@media (min-width: 640px) {
    .instruction-text {
        font-size: 0.875rem;
        margin-bottom: 1rem;
    }
}

.loading-container {
    display: flex;
    justify-content: center;
    align-items: center;
    flex: 1;
}

.interests-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 0.5rem;
    margin-bottom: 0.75rem;
    flex: 1;
    overflow: hidden;
    align-content: start;
}

@media (min-width: 640px) {
    .interests-grid {
        grid-template-columns: repeat(3, 1fr);
        gap: 0.75rem;
    }
}

@media (min-width: 768px) {
    .interests-grid {
        grid-template-columns: repeat(4, 1fr);
        gap: 0.75rem;
    }
}

@media (min-width: 1024px) {
    .interests-grid {
        grid-template-columns: repeat(5, 1fr);
        gap: 0.75rem;
    }
}

@media (min-width: 1280px) {
    .interests-grid {
        grid-template-columns: repeat(6, 1fr);
        gap: 0.75rem;
    }
}

.button-container {
    display: flex;
    justify-content: center;
    padding-top: 0.75rem;
    flex-shrink: 0;
}

.main-card {
    background: white;
    border-radius: 1.5rem;
    box-shadow: 0 10px 40px rgba(99, 0, 255, 0.1);
    overflow: hidden;
    border: 1px solid rgba(99, 0, 255, 0.1);
    width: 100%;
    height: 100%;
    max-height: 100vh;
    display: flex;
    flex-direction: column;
}

.card-header {
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.08), rgba(99, 0, 255, 0.03));
    padding: 1rem 1.25rem;
    border-bottom: 1px solid rgba(99, 0, 255, 0.1);
    flex-shrink: 0;
}

.header-icon {
    width: 2.25rem;
    height: 2.25rem;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    border-radius: 0.75rem;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 4px 12px rgba(99, 0, 255, 0.2);
}

.card-title {
    font-size: 1.25rem;
    font-weight: 700;
    color: #1A1A1D;
    margin: 0;
}

.card-subtitle {
    color: #6b7280;
    font-size: 0.8125rem;
    font-weight: 500;
    margin: 0.25rem 0 0 0;
}

@media (min-width: 640px) {
    .card-header {
        padding: 1.25rem 1.5rem;
    }
    .header-icon {
        width: 2.5rem;
        height: 2.5rem;
    }
    .card-title {
        font-size: 1.5rem;
    }
}

@media (min-width: 1024px) {
    .card-header {
        padding: 1.5rem 2rem;
    }
    .card-title {
        font-size: 1.75rem;
    }
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
    width: 6px;
    height: 6px;
    background: #5200CC;
}

@media (max-width: 768px) {
    .floating-particle {
        opacity: 0.15;
        display: none; /* Mobilde gizle */
    }
}

@keyframes float-particle {
    0%, 100% {
        transform: translate(0, 0) rotate(0deg);
        opacity: 0.3;
    }
    25% {
        transform: translate(30px, -40px) rotate(90deg);
        opacity: 0.5;
    }
    50% {
        transform: translate(-20px, -60px) rotate(180deg);
        opacity: 0.2;
    }
    75% {
        transform: translate(40px, -30px) rotate(270deg);
        opacity: 0.4;
    }
}

.interest-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 0.5rem 0.25rem;
    border-radius: 0.75rem;
    border: 2px solid #e5e7eb;
    background: white;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    cursor: pointer;
    min-height: 70px;
    max-height: 90px;
}

.interest-card span:first-child {
    font-size: 1.5rem;
    margin-bottom: 0.25rem;
    line-height: 1;
}

.interest-card span:last-child {
    font-size: 0.6875rem;
    line-height: 1.2;
    text-align: center;
    padding: 0 0.25rem;
}

@media (min-width: 640px) {
    .interest-card {
        padding: 0.75rem 0.5rem;
        min-height: 75px;
        max-height: 95px;
    }
    .interest-card span:first-child {
        font-size: 1.75rem;
        margin-bottom: 0.375rem;
    }
    .interest-card span:last-child {
        font-size: 0.75rem;
    }
}

@media (min-width: 768px) {
    .interest-card {
        padding: 0.875rem 0.75rem;
        min-height: 80px;
        max-height: 100px;
    }
    .interest-card span:first-child {
        font-size: 2rem;
        margin-bottom: 0.5rem;
    }
    .interest-card span:last-child {
        font-size: 0.8125rem;
    }
}

@media (min-width: 1024px) {
    .interest-card {
        padding: 1rem 0.75rem;
        min-height: 85px;
        max-height: 105px;
    }
    .interest-card span:first-child {
        font-size: 2.25rem;
        margin-bottom: 0.5rem;
    }
    .interest-card span:last-child {
        font-size: 0.875rem;
    }
}

.interest-card:hover {
    transform: translateY(-4px);
    border-color: rgba(99, 0, 255, 0.3);
    box-shadow: 0 4px 12px rgba(99, 0, 255, 0.1);
    background: #fafafa;
}

.interest-selected {
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.08), rgba(82, 0, 204, 0.05)) !important;
    border-color: #6300FF !important;
    box-shadow: 0 6px 20px rgba(99, 0, 255, 0.15) !important;
    transform: translateY(-2px) scale(1.02);
}

.interest-selected:hover {
    transform: translateY(-4px) scale(1.02) !important;
    box-shadow: 0 8px 25px rgba(99, 0, 255, 0.2) !important;
}

.interest-default {
    background: white;
}

.continue-button {
    padding: 1rem 3rem;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    font-weight: 600;
    font-size: 1rem;
    border-radius: 0.75rem;
    box-shadow: 0 4px 15px rgba(99, 0, 255, 0.3);
    transition: all 0.3s ease;
    border: none;
    cursor: pointer;
}

.continue-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 6px 25px rgba(99, 0, 255, 0.4);
    background: linear-gradient(135deg, #5200CC, #4100AA);
}

.continue-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
}
</style>
