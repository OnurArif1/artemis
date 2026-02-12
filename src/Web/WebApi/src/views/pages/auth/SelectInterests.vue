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
    <div class="select-interests-page min-h-screen flex items-center justify-center p-6">
        <!-- Animasyonlu arka plan -->
        <div class="absolute inset-0 bg-gradient-to-br from-purple-50 via-white to-purple-50"></div>
        
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
        
        <div class="relative w-full max-w-5xl">
            <!-- Beyaz kart - Daha ferah -->
            <div class="bg-white rounded-3xl shadow-xl overflow-hidden border border-purple-100">
                <!-- Başlık çubuğu - Daha hafif -->
                <div class="bg-gradient-to-r from-electric-purple/10 via-purple-50 to-electric-purple/10 px-8 py-8 border-b border-purple-100">
                    <div class="flex items-center gap-3 mb-2">
                        <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-xl flex items-center justify-center shadow-lg">
                            <i class="pi pi-heart text-white text-xl"></i>
                        </div>
                        <div>
                            <h1 class="text-3xl font-bold text-dark-charcoal">İlgi Alanlarınız</h1>
                            <p class="text-gray-500 text-sm font-medium mt-1">Adım 1 / 2</p>
                        </div>
                    </div>
                </div>

                <!-- İçerik alanı - Daha geniş padding -->
                <div class="p-10">
                    <!-- Talimat metni -->
                    <p class="text-gray-600 text-center mb-10 text-base leading-relaxed max-w-2xl mx-auto">
                        Benzer düşünen insanlarla eşleşmenize yardımcı olmak için en az 1 ilgi alanı seçin
                    </p>

                    <!-- Loading durumu -->
                    <div v-if="loading" class="flex justify-center items-center py-16">
                        <div class="flex flex-col items-center gap-4">
                            <i class="pi pi-spin pi-spinner text-4xl text-electric-purple"></i>
                            <p class="text-gray-500">Yükleniyor...</p>
                        </div>
                    </div>

                    <!-- İlgi alanları grid - Daha ferah spacing -->
                    <div v-else class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-5 mb-10">
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
                    <div class="flex justify-center pt-4">
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
    position: relative;
    min-height: 100vh;
    overflow: hidden;
}

/* Animated Gradient Blobs */
.animated-blob {
    position: absolute;
    border-radius: 50%;
    filter: blur(80px);
    opacity: 0.4;
    animation: blob-animation 20s ease-in-out infinite;
}

.blob-1 {
    width: 400px;
    height: 400px;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    top: -100px;
    left: -100px;
    animation-delay: 0s;
}

.blob-2 {
    width: 350px;
    height: 350px;
    background: linear-gradient(135deg, #5200CC, #4100AA);
    bottom: -50px;
    right: -50px;
    animation-delay: 5s;
}

.blob-3 {
    width: 300px;
    height: 300px;
    background: linear-gradient(135deg, #6300FF, rgba(99, 0, 255, 0.5));
    top: 50%;
    right: 10%;
    animation-delay: 10s;
}

.blob-4 {
    width: 280px;
    height: 280px;
    background: linear-gradient(135deg, rgba(82, 0, 204, 0.6), #6300FF);
    bottom: 20%;
    left: 5%;
    animation-delay: 15s;
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

/* Floating Particles */
.floating-particle {
    position: absolute;
    width: 8px;
    height: 8px;
    background: #6300FF;
    border-radius: 50%;
    opacity: 0.3;
    animation: float-particle 15s ease-in-out infinite;
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
    padding: 1.5rem 1rem;
    border-radius: 1rem;
    border: 2px solid #e5e7eb;
    background: white;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    cursor: pointer;
    min-height: 120px;
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
