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
        <!-- Mor degrade arka plan -->
        <div class="absolute inset-0 bg-gradient-to-br from-purple-600 via-purple-500 to-purple-700"></div>
        
        <div class="relative w-full max-w-4xl">
            <!-- Beyaz kart -->
            <div class="bg-white rounded-3xl shadow-2xl overflow-hidden">
                <!-- Başlık çubuğu (pembemsi-mor degrade) -->
                <div class="bg-gradient-to-r from-pink-500 via-purple-500 to-purple-600 px-8 py-6">
                    <div class="flex items-center gap-3 mb-2">
                        <i class="pi pi-heart text-white text-2xl"></i>
                        <h1 class="text-3xl font-bold text-white">İlgi Alanlarınız</h1>
                    </div>
                    <p class="text-white/90 text-sm font-light">Adım 1 / 2</p>
                </div>

                <!-- İçerik alanı -->
                <div class="p-8">
                    <!-- Talimat metni -->
                    <p class="text-gray-700 text-center mb-8 text-lg">
                        Benzer düşünen insanlarla eşleşmenize yardımcı olmak için en az 1 ilgi alanı seçin
                    </p>

                    <!-- Loading durumu -->
                    <div v-if="loading" class="flex justify-center items-center py-12">
                        <i class="pi pi-spin pi-spinner text-4xl text-purple-500"></i>
                    </div>

                    <!-- İlgi alanları grid -->
                    <div v-else class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 mb-8">
                        <button
                            v-for="interest in interests"
                            :key="interest.id"
                            @click="toggleInterest(interest.id)"
                            :class="[
                                'flex flex-col items-center justify-center p-4 rounded-xl border-2 transition-all duration-200 cursor-pointer',
                                isSelected(interest.id)
                                    ? 'bg-purple-100 border-purple-500 shadow-md transform scale-105'
                                    : 'bg-white border-gray-200 hover:border-purple-300 hover:shadow-sm'
                            ]"
                        >
                            <span class="text-3xl mb-2">{{ getEmoji(interest.name) }}</span>
                            <span :class="[
                                'text-sm font-medium text-center',
                                isSelected(interest.id) ? 'text-purple-700' : 'text-gray-700'
                            ]">
                                {{ t(`interest.${interest.name}`) }}
                            </span>
                        </button>
                    </div>

                    <!-- Kaydet butonu -->
                    <div class="flex justify-center">
                        <button
                            @click="saveInterests"
                            :disabled="selectedInterests.length === 0 || saving"
                            class="px-8 py-3 bg-gradient-to-r from-purple-600 to-purple-700 text-white font-semibold rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed transform hover:scale-105"
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
}
</style>
