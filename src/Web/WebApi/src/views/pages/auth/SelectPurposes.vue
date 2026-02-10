<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useI18n } from '@/composables/useI18n';
import { useAuthStore } from '@/stores/auth';
import { getEmailFromToken } from '@/utils/jwt';
import request from '@/service/request';
import PartyPurposeService from '@/service/PartyPurposeService';

const router = useRouter();
const { t } = useI18n();
const toast = useToast();
const authStore = useAuthStore();
const partyPurposeService = new PartyPurposeService(request);

const purposes = [
    { id: 1, name: 'Socializing', label: 'Sosyalleşme' },
    { id: 2, name: 'Dating', label: 'Flört' },
    { id: 3, name: 'Networking', label: 'Ağ Kurma' },
    { id: 4, name: 'MakingFriends', label: 'Arkadaş Edinme' },
    { id: 5, name: 'Exploring', label: 'Keşfetme' }
];

const selectedPurposes = ref([]);
const saving = ref(false);

const togglePurpose = (purposeId) => {
    const index = selectedPurposes.value.indexOf(purposeId);
    if (index > -1) {
        selectedPurposes.value.splice(index, 1);
    } else {
        selectedPurposes.value.push(purposeId);
    }
};

const isSelected = (purposeId) => {
    return selectedPurposes.value.includes(purposeId);
};

const savePurposes = async () => {
    if (selectedPurposes.value.length === 0) {
        toast.add({
            severity: 'warn',
            summary: 'Uyarı',
            detail: 'En az bir amaç seçmelisiniz.',
            life: 3000
        });
        return;
    }

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
        await partyPurposeService.savePartyPurposes(email, selectedPurposes.value);
        toast.add({
            severity: 'success',
            summary: 'Başarılı',
            detail: 'Amaçlarınız kaydedildi.',
            life: 3000
        });
        router.push({ name: 'room' });
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || 'Amaçlar kaydedilirken bir hata oluştu.',
            life: 5000
        });
    } finally {
        saving.value = false;
    }
};

onMounted(() => {
    authStore.hydrateFromStorage();
});
</script>

<template>
    <div class="select-purposes-page min-h-screen flex items-center justify-center p-6">
        <!-- Pembe-mor degrade arka plan -->
        <div class="absolute inset-0 bg-gradient-to-br from-pink-500 via-purple-500 to-purple-600"></div>
        
        <!-- İlerleme çubuğu -->
        <div class="absolute top-0 left-0 right-0 h-1 bg-gray-300">
            <div class="h-full bg-gradient-to-r from-pink-500 to-purple-500" style="width: 100%"></div>
        </div>

        <div class="relative w-full max-w-2xl mt-8">
            <!-- Beyaz kart -->
            <div class="bg-white rounded-3xl shadow-2xl overflow-hidden">
                <!-- İçerik alanı -->
                <div class="p-8 md:p-12">
                    <!-- Başlık -->
                    <div class="flex items-center gap-3 mb-6">
                        <div class="w-10 h-10 rounded-full bg-gradient-to-r from-pink-500 to-purple-500 flex items-center justify-center">
                            <i class="pi pi-heart text-white text-xl"></i>
                        </div>
                        <h1 class="text-3xl font-bold text-gray-800">Seni buraya getiren ne?</h1>
                    </div>

                    <!-- Talimat metni -->
                    <p class="text-gray-600 mb-8 text-center">
                        Birden fazla seçebilirsiniz
                    </p>

                    <!-- Amaçlar listesi -->
                    <div class="space-y-3 mb-8">
                        <label
                            v-for="purpose in purposes"
                            :key="purpose.id"
                            :class="[
                                'flex items-center p-4 rounded-xl border-2 cursor-pointer transition-all duration-200',
                                isSelected(purpose.id)
                                    ? 'bg-purple-50 border-purple-500 shadow-md'
                                    : 'bg-white border-gray-200 hover:border-purple-300'
                            ]"
                        >
                            <input
                                type="checkbox"
                                :checked="isSelected(purpose.id)"
                                @change="togglePurpose(purpose.id)"
                                class="w-5 h-5 text-purple-600 border-gray-300 rounded focus:ring-purple-500 focus:ring-2 cursor-pointer"
                            />
                            <span :class="[
                                'ml-4 text-lg font-medium',
                                isSelected(purpose.id) ? 'text-purple-700' : 'text-gray-700'
                            ]">
                                {{ purpose.label }}
                            </span>
                            <i
                                v-if="isSelected(purpose.id)"
                                class="pi pi-check-circle ml-auto text-purple-500 text-2xl"
                            ></i>
                        </label>
                    </div>

                    <!-- Butonlar -->
                    <div class="flex gap-4">
                        <!-- Geri butonu -->
                        <button
                            @click="router.push({ name: 'tellUsAboutYourself' })"
                            class="flex-1 py-4 bg-white border-2 border-purple-500 text-purple-600 font-semibold rounded-xl shadow-md hover:shadow-lg transition-all duration-200 transform hover:scale-[1.02]"
                        >
                            Geri
                        </button>

                        <!-- Devam Et butonu -->
                        <button
                            @click="savePurposes"
                            :disabled="selectedPurposes.length === 0 || saving"
                            class="flex-1 py-4 bg-gradient-to-r from-pink-500 via-purple-500 to-purple-600 text-white font-semibold rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed transform hover:scale-[1.02]"
                        >
                            <span v-if="!saving">Devam Et</span>
                            <span v-else class="flex items-center justify-center gap-2">
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
.select-purposes-page {
    position: relative;
}
</style>
